import 'dart:async';

import 'package:get/get.dart';
import 'package:shivaaymusic/utils/helper.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../ui/player/player_controller.dart';

class WindowsAudioService extends GetxService {
  late SMTCWindows smtc;
  final playerController = Get.find<PlayerController>();
  final List<StreamSubscription> _subscriptions = [];
  bool _smtcEnabled = false;

  @override
  void onInit() {
    _initService();
    super.onInit();
  }

  Future<void> _ensureSmtcEnabled() async {
    if (_smtcEnabled) return;
    try {
      await smtc.enableSmtc();
      _smtcEnabled = true;
    } catch (e) {
      printERROR("SMTC enable error: $e");
    }
  }

  void _setPlaybackStatus(PlaybackStatus status) {
    if (!_smtcEnabled) return;
    try {
      smtc.setPlaybackStatus(status);
    } catch (e) {
      printERROR("SMTC status error: $e");
    }
  }

  void _initService() {
    smtc = SMTCWindows(
      enabled: false,
    );
    try {
      _subscriptions.add(smtc.buttonPressStream.listen((event) async {
        await _ensureSmtcEnabled();
        switch (event) {
          case PressedButton.play:
            playerController.play();
            _setPlaybackStatus(PlaybackStatus.Playing);
            break;
          case PressedButton.pause:
            playerController.pause();
            _setPlaybackStatus(PlaybackStatus.Paused);
            break;
          case PressedButton.next:
            playerController.next();
            break;
          case PressedButton.previous:
            playerController.prev();
            break;

          default:
            break;
        }
      }));
    } catch (e) {
      printERROR("Error: $e");
    }

    _subscriptions.add(playerController.buttonState.listen((state) {
      switch (state) {
        case PlayButtonState.playing:
          _setPlaybackStatus(PlaybackStatus.Playing);
          break;
        case PlayButtonState.paused:
          _setPlaybackStatus(PlaybackStatus.Paused);
          break;
        case PlayButtonState.loading:
          _setPlaybackStatus(PlaybackStatus.Paused);
          break;
      }
    }));

    _subscriptions.add(playerController.progressBarStatus.listen((status) {
      if (!_smtcEnabled) return;
      try {
        smtc.setPosition(status.current);
      } catch (e) {
        // Position updates are best-effort; ignore transient SMTC errors.
      }
    }));

    _subscriptions.add(playerController.currentSong.listen((song) async {
      if (song == null) return;
      await _ensureSmtcEnabled();
      if (!_smtcEnabled) return;
      try {
        await smtc.updateMetadata(
          MusicMetadata(
            title: song.title,
            album: song.album,
            albumArtist: song.artist,
            artist: song.artist,
            thumbnail: song.artUri?.toString() ?? "",
          ),
        );
        final total = playerController.progressBarStatus.value.total;
        if (total > Duration.zero) {
          smtc.setEndTime(total);
        }
      } catch (e) {
        printERROR("SMTC metadata error: $e");
      }
    }));
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    try {
      smtc.clearMetadata();
      smtc.disableSmtc();
      smtc.dispose();
    } catch (e) {
      printERROR("SMTC dispose error: $e");
    }
    _smtcEnabled = false;
    super.onClose();
  }
}
