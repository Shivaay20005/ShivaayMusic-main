import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
// import 'package:home_widget/home_widget.dart';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart';
// ignore: depend_on_referenced_packages
import 'package:rxdart/rxdart.dart';

import '/models/album.dart';
import '../models/playlist.dart';
import '/services/equalizer.dart';
import '/services/booster_service.dart';
import '/services/stream_service.dart';
import '/models/sm_streaming_data.dart';
import '/ui/player/player_controller.dart';
import '/services/background_task.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/helper.dart';
import '/models/media_Item_builder.dart';
import '/services/utils.dart';
// import '/services/listening_stats_service.dart';
import '../ui/screens/Settings/settings_screen_controller.dart';
import '../ui/screens/Library/library_controller.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () {
      final handler = MyAudioHandler();
      // AudioService invokes this builder before initAudioService completes.
      // Register the concrete handler immediately so constructor callbacks can
      // never observe an empty GetX registry during that initialization window.
      if (!Get.isRegistered<AudioHandler>()) {
        Get.put<AudioHandler>(handler, permanent: true);
      }
      return handler;
    },
    config: const AudioServiceConfig(
      androidNotificationIcon: 'drawable/ic_shivaay_logo',
      androidNotificationChannelId: 'com.shivaay20005.shivaaymusicflutter.channel.audio',
      androidNotificationChannelName: 'ShivaayMusic Notification',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
      androidResumeOnClick: false,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with GetxServiceMixin {
  // ignore: prefer_typing_uninitialized_variables
  late final _cacheDir;
  late AudioPlayer _player;
  late MediaLibrary _mediaLibrary;
  // ignore: prefer_typing_uninitialized_variables
  dynamic currentIndex;
  int currentShuffleIndex = 0;
  late String? currentSongUrl;
  bool isPlayingUsingLockCachingSource = false;
  bool loopModeEnabled = false;
  bool queueLoopModeEnabled = false;
  bool shuffleModeEnabled = false;
  bool loudnessNormalizationEnabled = false;
  // var networkErrorPause = false;
  bool isSongLoading = true;
  bool _isPrefetching = false;
  int? _lastPrefetchedIndex;
  // Guards the end-of-track trigger: positionStream emits several times while
  // the position stays at the end, which used to call skipToNext repeatedly.
  bool _isAdvancing = false;
  // Guards the 403/expired-URL recovery so the error handler cannot re-enter.
  bool _isRecoveringFromError = false;
  // Last song id that already got an automatic fresh-URL retry.
  String? _recoveredSongId;
  // Position bookkeeping used to tell a genuinely stalled buffer (position
  // frozen) from just_audio keeping `processingState == buffering` while the
  // audio actually keeps playing.
  Duration _lastObservedPosition = Duration.zero;
  DateTime? _lastPositionAdvanceAt;
  final _initCompleter = Completer<void>();

  // list of shuffled queue songs ids
  List<String> shuffledQueue = [];

  final _playList =
      ConcatenatingAudioSource(children: [], useLazyPreparation: false);

  MyAudioHandler() {
    if (GetPlatform.isWindows || GetPlatform.isLinux) {
      JustAudioMediaKit.title = 'ShivaayMusic';
      JustAudioMediaKit.protocolWhitelist = const ['http', 'https', 'file'];
    }
    _mediaLibrary = MediaLibrary();
    _player = AudioPlayer(
        audioLoadConfiguration: const AudioLoadConfiguration(
            androidLoadControl: AndroidLoadControl(
      minBufferDuration: Duration(seconds: 50),
      maxBufferDuration: Duration(seconds: 120),
      bufferForPlaybackDuration: Duration(milliseconds: 50),
      bufferForPlaybackAfterRebufferDuration: Duration(seconds: 2),
    )));
    _addEmptyList();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToPlaybackForNextSong();
    _init();
    _listenForDurationChanges();
    if (GetPlatform.isAndroid) {
      _listenSessionIdStream();
    }
    
    // Start Listening Stats Timer
    /* 
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_player.playing) {
        final item = mediaItem.value;
        if (item != null) {
          try {
             // Record 10 seconds of listening time
             Get.find<ListeningStatsService>().recordListeningTime(item.id, 10);
          } catch (e) {
             // Service might not be ready or GetX error in background isolate
          }
        }
      }
    }); 
    */
  }

  Future<void> _init() async {
    try {
      // `_cacheDir` is `late final` and is used by checkNGetUrl() and
      // _createAudioSource(). Resolve it inside _init so the completer cannot
      // complete before the field is assigned.
      await _createCacheDir();

      if (!Hive.isBoxOpen("AppPrefs")) {
        String applicationDataDirectoryPath;
        if (GetPlatform.isDesktop) {
          applicationDataDirectoryPath = "${(await getApplicationSupportDirectory()).path}/db";
        } else {
          applicationDataDirectoryPath = (await getApplicationDocumentsDirectory()).path;
        }
        await Hive.initFlutter(applicationDataDirectoryPath);
        await Hive.openBox("AppPrefs");
        await Hive.openBox("SongsCache");
        await Hive.openBox("SongDownloads");
        await Hive.openBox('SongsUrlCache');
      }
      
      final appPrefsBox = Hive.box("AppPrefs");
      _player.setSkipSilenceEnabled(appPrefsBox.get("skipSilenceEnabled") ?? false);
      loopModeEnabled = appPrefsBox.get("isLoopModeEnabled") ?? false;
      shuffleModeEnabled = appPrefsBox.get("isShuffleModeEnabled") ?? false;
      queueLoopModeEnabled = appPrefsBox.get("queueLoopModeEnabled") ?? false;
      loudnessNormalizationEnabled = appPrefsBox.get("loudnessNormalizationEnabled") ?? false;

      // Do NOT call restoreSession() here: it uses checkNGetUrl(), which awaits
      // _initCompleter, and that completer only completes after _init returns.
      // That circular wait stalled startup for the full 30s timeout whenever a
      // saved session existed. Session restore is handled by
      // PlayerController._restorePrevSession() once the app is ready.
    } catch (e) {
      printERROR("AudioHandler Init Error: $e");
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }
  }

  Future<void> _createCacheDir() async {
    if (GetPlatform.isWeb) return;
    _cacheDir = (await getTemporaryDirectory()).path;
    if (!Directory("$_cacheDir/cachedSongs/").existsSync()) {
      Directory("$_cacheDir/cachedSongs/").createSync(recursive: true);
    }
  }

  /// True when the playback position advanced within the last two seconds.
  ///
  /// just_audio can keep `processingState == buffering` while the stream is
  /// already audible, and only emits a playback event when the state changes.
  /// AudioService renders `loading`/`buffering` as a spinner, which is what made
  /// the Android media notification show a loading arc for a song that was
  /// playing. A moving position is proof that audio is flowing, so those states
  /// are reported as `ready` while it advances. A real stall freezes the
  /// position, so the spinner comes back within two seconds.
  bool get _isPositionProgressing {
    final lastAdvance = _lastPositionAdvanceAt;
    return lastAdvance != null &&
        DateTime.now().difference(lastAdvance) <
            const Duration(seconds: 2);
  }

  /// The processing state to publish to AudioService.
  AudioProcessingState get _audioServiceProcessingState {
    if (isSongLoading) return AudioProcessingState.loading;
    final state = _player.processingState;
    if (_isPositionProgressing &&
        (state == ProcessingState.loading ||
            state == ProcessingState.buffering)) {
      return AudioProcessingState.ready;
    }
    return const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[state]!;
  }

  /// Records position progress and clears a stale spinner in the notification.
  void _trackPlaybackProgress(Duration position) {
    // Any position change (including a backward seek) proves the player is
    // running; an unchanged position means it is paused or genuinely stalled.
    if (position != _lastObservedPosition) {
      _lastObservedPosition = position;
      _lastPositionAdvanceAt = DateTime.now();
      // A moving position while the player reports `playing` proves the track is
      // audible, so a stuck loading flag must not keep the notification in its
      // loading state.
      if (_player.playing) isSongLoading = false;
    }

    if (!_player.playing || isSongLoading) return;
    final published = playbackState.value.processingState;
    if (published != AudioProcessingState.loading &&
        published != AudioProcessingState.buffering) {
      return;
    }

    // The media notification is still showing a spinner even though the song is
    // audibly playing. Re-publish now instead of waiting for a playback event
    // that may not arrive until the track ends.
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.ready,
      playing: true,
      updatePosition: position,
      bufferedPosition: _player.bufferedPosition,
    ));
  }

  /// Publishes the player's *current* processing state.
  ///
  /// The playback event listener is the only place that translates
  /// `isSongLoading` into a processing state, so when loading finished while the
  /// player was buffering (no new playback event is emitted until the buffer
  /// fills or the track ends) the published state stayed `loading` and the
  /// spinner stayed on screen for the whole song.
  void _emitCurrentProcessingState() {
    try {
      playbackState.add(playbackState.value.copyWith(
        processingState: _audioServiceProcessingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
      ));
    } catch (e) {
      printERROR("Failed to publish playback state: $e");
    }
  }

  void _addEmptyList() {
    try {
      _player.setAudioSource(_playList);
    } catch (r) {
      printERROR(r.toString());
    }
  }

  void _listenSessionIdStream() {
    _player.androidAudioSessionIdStream.listen((int? id) {
      if (id != null) {
        EqualizerService.initAudioEffect(id);
        BoosterService.initEffects(id);
      }
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _audioServiceProcessingState,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[_player.loopMode]!,
        shuffleMode: (shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: currentIndex,
      ));

      //print("set ${playbackState.value.queueIndex},${event.currentIndex}");
    }, onError: (Object e, StackTrace st) async {
      // 403 / expired media URLs arrive as PlayerException, so the recovery
      // path must run for both branches (it previously only ran for the
      // "unknown error" branch, which is why songs stayed stuck on load).
      if (e is PlayerException) {
        printERROR('Error code: ${e.code}');
        printERROR('Error message: ${e.message}');
      } else {
        printERROR('An error occurred: $e');
      }

      final curPos = _player.position;
      try {
        await _player.stop();
      } catch (_) {
        // Player may already be disposed/stopped; recovery below still applies.
      }

      if (isPlayingUsingLockCachingSource &&
          e.toString().contains("Connection closed while receiving data")) {
        await _player.seek(curPos, index: 0);
        await _player.play();
        return;
      }

      if (_isRecoveringFromError) return;
      final index = currentIndex;
      if (index == null || index < 0 || index >= queue.value.length) return;
      final songId = queue.value[index].id;

      // Only one automatic URL refresh per song; otherwise a dead video would
      // loop forever between the error handler and playByIndex.
      if (_recoveredSongId == songId) {
        _reportPlaybackFailure("Unable to play this song");
        return;
      }

      _isRecoveringFromError = true;
      _recoveredSongId = songId;
      try {
        await customAction("playByIndex", {'index': index, 'newUrl': true});
        if (curPos > const Duration(seconds: 2) && index == currentIndex) {
          // The recovery can fail (for example while YouTube is rate limiting
          // us), in which case there is no loaded source to seek in.
          try {
            await _player.seek(curPos);
          } catch (_) {
            // Nothing to resume; the failure snackbar is already shown.
          }
        }
      } finally {
        _isRecoveringFromError = false;
      }
    });
  }

  void _listenToPlaybackForNextSong() {
    final playerDurationOffset = GetPlatform.isWindows
        ? 200
        : GetPlatform.isLinux
            ? 700
            : 0;
    _player.positionStream.listen((value) async {
      _trackPlaybackProgress(value);
      if (_player.duration != null && _player.duration?.inSeconds != 0) {
        final duration = _player.duration;
        if (duration != null &&
            !_isAdvancing &&
            value.inMilliseconds >=
                (duration.inMilliseconds - playerDurationOffset)) {
          _isAdvancing = true;
          await _triggerNext();
        }

        // Smart Pre-fetch logic
        try {
          final appPrefsBox = Hive.box("AppPrefs");
          final isSmartPrefetchEnabled =
              appPrefsBox.get("isSmartPrefetchEnabled") ?? true;
          if (isSmartPrefetchEnabled && duration != null && value.inSeconds > 0) {
            final remaining = duration.inSeconds - value.inSeconds;
            // Warm the next track a bit earlier (45s / 75%) so the URL is
            // already cached before the user skips or the track ends.
            if ((remaining <= 45 ||
                    value.inSeconds > duration.inSeconds * 0.75) &&
                _lastPrefetchedIndex != currentIndex) {
              _prefetchNextSong();
            }
          }
        } catch (e) {
          // Silently ignore settings check errors
        }
      }
    });
  }

  Future<void> _prefetchNextSong() async {
    if (_isPrefetching || currentIndex == null) return;
    // A rate-limited connection does not need more requests.
    if (StreamProvider.isCoolingDown) return;

    final nextIndex = _peekNextSongIndex();
    if (nextIndex == currentIndex ||
        nextIndex < 0 ||
        nextIndex >= queue.value.length) return;

    _isPrefetching = true;

    try {
      final nextSong = queue.value[nextIndex];
      printINFO("Smart Pre-fetch: Warming up next song -> ${nextSong.title}");

      // This will fetch the URL and put it into Hive SongsUrlCache
      final streamInfo = await checkNGetUrl(nextSong.id);
      // Mark this track as attempted even on failure. The position stream
      // fires several times per second; clearing the marker here would retry
      // the same failing extraction on every tick and hammer YouTube.
      final index = currentIndex;
      if (index is int) _lastPrefetchedIndex = index;
      if (!streamInfo.playable) return;
      // The URL is now in the Hive cache, so the real playback path
      // (`playByIndex`) starts instantly. Do not append the source to
      // `_playList`: `playByIndex` clears the playlist anyway, and an extra
      // source would let just_audio auto-advance at the same moment
      // `_triggerNext()` runs, restarting the next song.
    } catch (e) {
      final index = currentIndex;
      if (index is int) _lastPrefetchedIndex = index;
      printERROR("Smart Pre-fetch error: $e");
    } finally {
      _isPrefetching = false;
    }
  }

  /// Fire-and-forget warm-up of the surrounding tracks' stream URLs right when
  /// a song starts playing. This moves the YouTube round-trip off the critical
  /// path for the following song and makes a skip (or "previous") instant.
  ///
  /// The next track is always warmed; the one after it and the previous track
  /// are warmed only when smart pre-fetch is enabled, so a user who turned it
  /// off does not pay for extra network traffic.
  void _prefetchUpcoming() {
    final startIndex = currentIndex;
    if (startIndex is! int) return;
    // While YouTube is rate limiting this connection, extra warm-up requests
    // only extend the block. Resume automatically once the cooldown expires.
    if (StreamProvider.isCoolingDown) return;

    var smartPrefetch = true;
    try {
      smartPrefetch =
          Hive.box("AppPrefs").get("isSmartPrefetchEnabled") ?? true;
    } catch (_) {
      // Fall back to the default when preferences are not ready yet.
    }

    final targets = <int>[
      _queueIndexAtOffset(1),
      if (smartPrefetch) _queueIndexAtOffset(2),
      if (smartPrefetch) _queueIndexAtOffset(-1),
    ];

    final ids = <String>[];
    for (final index in targets) {
      if (index < 0 ||
          index >= queue.value.length ||
          index == startIndex) {
        continue;
      }
      final id = queue.value[index].id;
      if (!ids.contains(id)) ids.add(id);
    }
    if (ids.isEmpty) return;

    // Mark the attempt immediately so a position tick cannot start a duplicate
    // fetch for the same next track while this one is in flight.
    _lastPrefetchedIndex = startIndex;
    unawaited(() async {
      for (final id in ids) {
        // A `429` in the middle of the warm-up pauses the rest of it.
        if (StreamProvider.isCoolingDown) break;
        try {
          // `checkNGetUrl` returns from the Hive cache when a still-valid URL
          // exists, so re-warming the previous track costs nothing.
          await checkNGetUrl(id);
        } catch (e) {
          // The real playback path retries when the track actually starts.
          printERROR("Pre-fetch warm-up error: $e");
        }
      }
    }());
  }

  Future<void> _triggerNext() async {
    try {
      if (loopModeEnabled) {
        await _player.seek(Duration.zero);
        if (!_player.playing) {
          _player.play();
        }
        return;
      }

      // At the end of a non-looping queue just stop. Previously this fell
      // through to skipToNext(), which paused and then re-fired every time the
      // position stream emitted at the end of the track.
      final current = currentIndex;
      final atEndOfQueue = !shuffleModeEnabled &&
          !queueLoopModeEnabled &&
          current is int &&
          queue.value.isNotEmpty &&
          current >= queue.value.length - 1;
      if (atEndOfQueue) {
        await _player.pause();
        return;
      }

      await skipToNext();
    } finally {
      // Re-arm after the player has moved away from the end position.
      await Future.delayed(const Duration(milliseconds: 1500));
      _isAdvancing = false;
    }
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) async {
      final currQueue = queue.value;
      if (currentIndex == null || currQueue.isEmpty || duration == null) return;
      final currentSong = queue.value[currentIndex];
      if (currentSong.duration == null || currentIndex == 0) {
        final newMediaItem = currentSong.copyWith(duration: duration);
        mediaItem.add(newMediaItem);
      }
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // notify system
    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);

    if (shuffleModeEnabled) {
      final mediaItemsIds = mediaItems.toList().map((item) => item.id).toList();
      // Guard against a stale shuffle cursor after the queue was replaced:
      // both sublist() and replaceRange() throw if the index is out of range.
      final start =
          currentShuffleIndex.clamp(0, shuffledQueue.length).toInt();
      final notPlayedshuffledQueue = start < shuffledQueue.length
          ? shuffledQueue.toList().sublist(start + 1)
          : <String>[];
      notPlayedshuffledQueue.addAll(mediaItemsIds);
      notPlayedshuffledQueue.shuffle();
      shuffledQueue.replaceRange(start, shuffledQueue.length, notPlayedshuffledQueue);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    final playingId = mediaItem.value?.id;
    final newQueue = List<MediaItem>.from(queue);
    this.queue.add(newQueue);

    // The queue is often replaced asynchronously (e.g. by the radio/watch
    // playlist request that runs in parallel with playback). Keep pointing at
    // the song that is actually playing instead of whatever now sits at index 0.
    if (playingId != null) {
      final newIndex = newQueue.indexWhere((item) => item.id == playingId);
      if (newIndex >= 0 && newIndex != currentIndex) {
        currentIndex = newIndex;
        playbackState
            .add(playbackState.value.copyWith(queueIndex: currentIndex));
      }
    }

    // The queue is known now, so warm the following track immediately.
    _prefetchUpcoming();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    if (shuffleModeEnabled) {
      shuffledQueue.add(mediaItem.id);
    }

    // notify system
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }

  AudioSource _createAudioSource(MediaItem mediaItem) {
    final url = mediaItem.extras!['url'] as String;
    bool cacheEnabled = false;
    try {
      cacheEnabled = Get.find<SettingsScreenController>().cacheSongs.isTrue;
    } catch (e) {
      cacheEnabled = false;
    }

    if (!GetPlatform.isWeb && (url.contains('/cache') ||
        (cacheEnabled &&
            url.contains("http")))) {
      printINFO("Playing Using LockCaching");
      isPlayingUsingLockCachingSource = true;
      // ignore: experimental_member_use
      return LockCachingAudioSource(
        Uri.parse(url),
        cacheFile: File("$_cacheDir/cachedSongs/${mediaItem.id}.mp3"),
        tag: mediaItem,
      );
    }

    printINFO("Playing Using AudioSource.uri");
    isPlayingUsingLockCachingSource = false;
    return AudioSource.uri(
      Uri.tryParse(url)!,
      tag: mediaItem,
    );
  }

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> removeQueueItem(MediaItem mediaItem_) async {
    if (shuffleModeEnabled) {
      final id = mediaItem_.id;
      final itemIndex = shuffledQueue.indexOf(id);
      if (currentShuffleIndex > itemIndex) {
        currentShuffleIndex -= 1;
      }
      shuffledQueue.remove(id);
    }

    final currentQueue = queue.value;
    final currentSong = mediaItem.value;
    final itemIndex = currentQueue.indexOf(mediaItem_);
    final index = currentIndex;
    if (itemIndex >= 0 && index is int && index > itemIndex) {
      currentIndex = index - 1;
    }
    currentQueue.remove(mediaItem_);
    queue.add(currentQueue);
    mediaItem.add(currentSong);
  }

  @override
  Future<void> play() async {
    await _initCompleter.future;
    if (currentSongUrl == null ||
        (GetPlatform.isDesktop &&
            (_player.duration == null ||
                _player.duration?.inMilliseconds == 0))) {
      final index = currentIndex;
      // `currentIndex` is dynamic and can still be null on a cold start; the
      // old code forwarded it to playByIndex and crashed on the int cast.
      if (index is! int || index < 0 || index >= queue.value.length) return;
      await customAction("playByIndex", {'index': index});
      return;
    }
    // Workaround for network error pause in case of PlayingUsingLockCachingSource
    // if (isPlayingUsingLockCachingSource && networkErrorPause) {
    //   await _player.play();
    //   Future.delayed(const Duration(seconds: 2)).then((value) {
    //     if (_player.playing) {
    //       networkErrorPause = false;
    //     }
    //   });
    //   await _player.play();
    //   return;
    // }
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await customAction("playByIndex", {'index': index});
  }

  int _getNextSongIndex() {
    final current = currentIndex;
    if (current == null) return -1;
    if (shuffleModeEnabled) {
      if (shuffledQueue.isEmpty) return current;
      if (currentShuffleIndex + 1 >= shuffledQueue.length) {
        shuffledQueue.shuffle();
        currentShuffleIndex = 0;
      } else {
        currentShuffleIndex += 1;
      }
      return queue.value
          .indexWhere((item) => item.id == shuffledQueue[currentShuffleIndex]);
    }

    if (queue.value.length > current + 1) {
      return current + 1;
    } else if (queueLoopModeEnabled) {
      return 0;
    } else {
      return current;
    }
  }

  /// Same as [_getNextSongIndex] but never mutates the shuffle cursor. Used by
  /// the prefetcher: asking for the next song must not consume it.
  int _peekNextSongIndex() {
    final current = currentIndex;
    if (current == null) return -1;
    if (shuffleModeEnabled) {
      if (shuffledQueue.isEmpty) return -1;
      final nextShuffleIndex = currentShuffleIndex + 1 >= shuffledQueue.length
          ? 0
          : currentShuffleIndex + 1;
      return queue.value
          .indexWhere((item) => item.id == shuffledQueue[nextShuffleIndex]);
    }

    if (queue.value.length > current + 1) {
      return current + 1;
    } else if (queueLoopModeEnabled) {
      return 0;
    } else {
      return -1;
    }
  }

  /// Queue index [offset] tracks away from the current one, without touching
  /// any playback or shuffle cursor. Used by the prefetcher to warm the two
  /// tracks ahead and the previous one.
  int _queueIndexAtOffset(int offset) {
    final current = currentIndex;
    if (current is! int) return -1;
    if (queue.value.isEmpty) return -1;

    if (shuffleModeEnabled) {
      if (shuffledQueue.isEmpty) return -1;
      // Dart's `%` is always non-negative for a positive divisor, so a
      // negative offset wraps to the end of the shuffled queue.
      final target = (currentShuffleIndex + offset) % shuffledQueue.length;
      return queue.value
          .indexWhere((item) => item.id == shuffledQueue[target]);
    }

    final target = current + offset;
    if (queueLoopModeEnabled) {
      return target % queue.value.length;
    }
    if (target < 0 || target >= queue.value.length) return -1;
    return target;
  }

  int _getPrevSongIndex() {
    final current = currentIndex;
    if (current == null) return -1;
    if (shuffleModeEnabled) {
      if (shuffledQueue.isEmpty) return current;
      if (currentShuffleIndex - 1 < 0) {
        shuffledQueue.shuffle();
        currentShuffleIndex = shuffledQueue.length - 1;
      } else {
        currentShuffleIndex -= 1;
      }
      return queue.value
          .indexWhere((item) => item.id == shuffledQueue[currentShuffleIndex]);
    }

    if (current - 1 >= 0) {
      return current - 1;
    } else {
      return current;
    }
  }

  @override
  Future<void> skipToNext() async {
    final index = _getNextSongIndex();
    if (index >= 0 && index != currentIndex) {
      if (_player.position != Duration.zero) _player.seek(Duration.zero);
      await customAction("playByIndex", {'index': index});
    } else {
      _player.seek(Duration.zero);
      _player.pause();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inMilliseconds > 5000) {
      _player.seek(Duration.zero);
      return;
    }
    _player.seek(Duration.zero);
    final index = _getPrevSongIndex();
    if (index != currentIndex) {
      await customAction("playByIndex", {'index': index});
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (repeatMode == AudioServiceRepeatMode.none) {
      loopModeEnabled = false;
    } else {
      loopModeEnabled = true;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      shuffleModeEnabled = false;
      shuffledQueue.clear();
    } else {
      final index = currentIndex;
      _shuffleCmd(index is int ? index : 0);
      shuffleModeEnabled = true;
    }
  }

  /// Central error path: stops the loading spinner, publishes an error state
  /// and shows a snackbar with a Retry action. Without the finally/clear in the
  /// callers an exception used to leave [isSongLoading] stuck at true forever.
  void _reportPlaybackFailure(String message) {
    isSongLoading = false;
    currentSongUrl = null;
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.error,
      errorCode: 404,
      errorMessage: message,
    ));
    try {
      Get.find<PlayerController>().notifyPlayError(message);
    } catch (e) {
      printERROR("PlayerController not found: $e");
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    await _initCompleter.future;
    switch (name) {

      case 'dispose':
        await _player.dispose();
        await stop();
        break;

      case 'retryCurrentSong':
        final index = currentIndex;
        if (index == null || index < 0 || index >= queue.value.length) return;
        _recoveredSongId = null;
        await customAction("playByIndex", {'index': index, 'newUrl': true});
        break;

      case 'playByIndex':
        final songIndex = (extras!['index'] as num).toInt();
        if (songIndex < 0 || songIndex >= queue.value.length) {
          printERROR("playByIndex: invalid index $songIndex");
          return;
        }
        currentIndex = songIndex;
        final isNewUrlReq = extras['newUrl'] ?? false;
        final bool restoreSession = extras['restoreSession'] ?? false;
        final currentSong = queue.value[songIndex];
        // A user-initiated play re-arms the automatic URL recovery.
        if (!isNewUrlReq) _recoveredSongId = null;
        isSongLoading = true;
        _lastObservedPosition = Duration.zero;
        _lastPositionAdvanceAt = null;
        playbackState.add(playbackState.value
            .copyWith(processingState: AudioProcessingState.loading));

        try {
          if (_playList.children.isNotEmpty) {
            await _playList.clear();
          }

          mediaItem.add(currentSong);
          var streamInfo =
              await checkNGetUrl(currentSong.id, generateNewUrl: isNewUrlReq);

          // A cached URL can expire between two songs (403). Retry once with a
          // freshly generated URL before surfacing an error. Never retry while
          // YouTube is rate limiting us: a second round of requests is exactly
          // what turns a short block into a long one.
          if (!streamInfo.playable &&
              !isNewUrlReq &&
              !StreamProvider.isCoolingDown) {
            streamInfo =
                await checkNGetUrl(currentSong.id, generateNewUrl: true);
          }
          if (songIndex != currentIndex) return;

          final audio = streamInfo.audio;
          if (!streamInfo.playable || audio == null) {
            currentSongUrl = null;
            _reportPlaybackFailure(streamInfo.statusMSG);
            return;
          }

          currentSongUrl = currentSong.extras!['url'] = audio.url;
          playbackState
              .add(playbackState.value.copyWith(queueIndex: currentIndex));
          await _playList.add(_createAudioSource(currentSong));

          if (loudnessNormalizationEnabled && GetPlatform.isAndroid) {
            _normalizeVolume(audio.loudnessDb);
          }

          if (restoreSession) {
            final position = (extras['position'] as num?)?.toInt() ?? 0;
            // Load without starting playback so the player panel can show the
            // restored track paused. This works on desktop too (media_kit
            // backend), which previously skipped the load entirely.
            await _player.load();
            if (position > 0) {
              await _player.seek(Duration(milliseconds: position));
            }
          } else {
            await _player.play();
          }

          // Warm the next track's URL while this one is playing.
          _prefetchUpcoming();
        } catch (e, st) {
          printERROR("playByIndex failed: $e\n$st");
          _reportPlaybackFailure("Unable to play this song");
        } finally {
          isSongLoading = false;
          // Publish the real state now: while the player is buffering no new
          // playback event is emitted, so the spinner used to stay on screen
          // for the whole song. Keep an error state published by
          // _reportPlaybackFailure intact.
          if (playbackState.value.processingState !=
              AudioProcessingState.error) {
            _emitCurrentProcessingState();
          }
        }
        break;

      case 'checkWithCacheDb':
        if (isPlayingUsingLockCachingSource) {
          final song = extras!['mediaItem'] as MediaItem;
          final songsCacheBox = Hive.box("SongsCache");
          if (!songsCacheBox.containsKey(song.id) &&
              await File("$_cacheDir/cachedSongs/${song.id}.mp3").exists()) {
            song.extras!['url'] = currentSongUrl;
            song.extras!['date'] = DateTime.now().millisecondsSinceEpoch;
            final dbStreamData = Hive.box("SongsUrlCache").get(song.id);
            final jsonData = MediaItemBuilder.toJson(song);
            jsonData['duration'] = _player.duration?.inSeconds ?? 0;
            // playbility status and info
            jsonData['streamInfo'] = dbStreamData != null
                ? [
                    true,
                    dbStreamData[
                        Hive.box('AppPrefs').get('streamingQuality') == 0
                            ? 'lowQualityAudio'
                            : "highQualityAudio"]
                  ]
                : null;
            songsCacheBox.put(song.id, jsonData);
            LibrarySongsController? librarySongsController;
            try {
              librarySongsController = Get.find<LibrarySongsController>();
            } catch (e) {
              printERROR("LibrarySongsController not found");
            }
            if (librarySongsController != null && !librarySongsController.isClosed) {
              librarySongsController.librarySongsList.value =
                  librarySongsController.librarySongsList.toList() + [song];
            }
          }
        }
        break;

      case 'setSourceNPlay':
        final currMed = (extras!['mediaItem'] as MediaItem);
        isSongLoading = true;
        currentIndex = 0;
        _isAdvancing = false;
        _recoveredSongId = null;
        _lastObservedPosition = Duration.zero;
        _lastPositionAdvanceAt = null;
        playbackState.add(playbackState.value
            .copyWith(processingState: AudioProcessingState.loading));
        try {
          await _playList.clear();
          mediaItem.add(currMed);
          queue.add([currMed]);

          var streamInfo = await checkNGetUrl(currMed.id);
          // Skip the extra round-trip while YouTube is rate limiting us.
          if (!streamInfo.playable && !StreamProvider.isCoolingDown) {
            streamInfo =
                await checkNGetUrl(currMed.id, generateNewUrl: true);
          }
          final audio = streamInfo.audio;
          if (!streamInfo.playable || audio == null) {
            currentSongUrl = null;
            _reportPlaybackFailure(streamInfo.statusMSG);
            return;
          }
          currentSongUrl = currMed.extras!['url'] = audio.url;

          await _playList.add(_createAudioSource(currMed));

          // Normalize audio
          if (loudnessNormalizationEnabled && GetPlatform.isAndroid) {
            _normalizeVolume(audio.loudnessDb);
          }

          await _player.play();
          _prefetchUpcoming();
        } catch (e, st) {
          printERROR("setSourceNPlay failed: $e\n$st");
          _reportPlaybackFailure("Unable to play this song");
        } finally {
          isSongLoading = false;
          // Publish the real state now: while the player is buffering no new
          // playback event is emitted, so the spinner used to stay on screen
          // for the whole song. Keep an error state published by
          // _reportPlaybackFailure intact.
          if (playbackState.value.processingState !=
              AudioProcessingState.error) {
            _emitCurrentProcessingState();
          }
        }
        break;

      case 'toggleSkipSilence':
        final enable = (extras!['enable'] as bool);
        await _player.setSkipSilenceEnabled(enable);
        break;

      case 'toggleLoudnessNormalization':
        loudnessNormalizationEnabled = (extras!['enable'] as bool);
        if (!loudnessNormalizationEnabled) {
          _player.setVolume(1.0);
          return;
        }

        if (loudnessNormalizationEnabled) {
          try {
            final currentSongId = (queue.value[currentIndex]).id;
            if (Hive.box("SongsUrlCache").containsKey(currentSongId)) {
              final songJson = Hive.box("SongsUrlCache").get(currentSongId);
              _normalizeVolume((songJson)["highQualityAudio"]["loudnessDb"]);
              return;
            }

            if (Hive.box("SongDownloads").containsKey(currentSongId)) {
              final streamInfo =
                  (Hive.box("SongDownloads").get(currentSongId))["streamInfo"];

              _normalizeVolume(
                  streamInfo == null ? 0 : streamInfo[1]["loudnessDb"]);
            }
          } catch (e) {
            printERROR(e);
          }
        }
        break;

      case 'shuffleQueue':
        final currentQueue = queue.value;
        final shuffleIndex = currentIndex;
        if (shuffleIndex is! int ||
            shuffleIndex < 0 ||
            shuffleIndex >= currentQueue.length) {
          break;
        }
        final currentItem = currentQueue[shuffleIndex];
        currentQueue.remove(currentItem);
        currentQueue.shuffle();
        currentQueue.insert(0, currentItem);
        queue.add(currentQueue);
        mediaItem.add(currentItem);
        currentIndex = 0;
        break;

      case 'reorderQueue':
        final currentQueue = queue.value;
        final reorderIndex = currentIndex;
        if (reorderIndex is! int ||
            reorderIndex < 0 ||
            reorderIndex >= currentQueue.length) {
          break;
        }
        final oldIndex = (extras!['oldIndex'] as num).toInt();
        final newIndex = (extras['newIndex'] as num).toInt();
        if (oldIndex < 0 || oldIndex >= currentQueue.length) break;
        final currentItem = currentQueue[reorderIndex];
        final item = currentQueue.removeAt(oldIndex);
        currentQueue.insert(newIndex.clamp(0, currentQueue.length).toInt(), item);
        currentIndex = currentQueue.indexOf(currentItem);
        queue.add(currentQueue);
        mediaItem.add(currentItem);
        break;

      case 'addPlayNextItem':
        final song = extras!['mediaItem'] as MediaItem;
        final currentQueue = queue.value;
        final addIndex = currentIndex;
        final insertAt = addIndex is int ? addIndex + 1 : 0;
        currentQueue.insert(insertAt.clamp(0, currentQueue.length).toInt(), song);
        queue.add(currentQueue);
        if (shuffleModeEnabled) {
          final shuffleInsertAt =
              (currentShuffleIndex + 1).clamp(0, shuffledQueue.length).toInt();
          shuffledQueue.insert(shuffleInsertAt, song.id);
        }
        break;

      case 'openEqualizer':
        EqualizerService.openEqualizer(_player.androidAudioSessionId!);
        break;

      case 'saveSession':
        await saveSessionData();
        break;

      case 'setVolume':
        _player.setVolume(extras!['value'] / 100);
        break;

      case 'shuffleCmd':
        final songIndex = extras!['index'];
        _shuffleCmd(songIndex is int ? songIndex : 0);
        break;

      case 'upadateMediaItemInAudioService':
        //added to update media item from player controller
        final songIndex = extras!['index'];
        if (songIndex is! int ||
            songIndex < 0 ||
            songIndex >= queue.value.length) {
          break;
        }
        currentIndex = songIndex;
        mediaItem.add(queue.value[songIndex]);
        break;

      case 'toggleQueueLoopMode':
        queueLoopModeEnabled = extras!['enable'];
        break;

      case 'toggleBooster':
        final enable = extras!['enable'] as bool;
        BoosterService.setEnabled(enable);
        break;

      case 'updateBoosterLevels':
        final bass = (extras!['bass'] as double).toInt();
        final virt = (extras['virt'] as double).toInt();
        final gain = (extras['gain'] as double).toInt(); // 0 to 2000
        BoosterService.setBassLevel(bass);
        BoosterService.setVirtualizerLevel(virt);
        BoosterService.setLoudnessGain(gain);
        break;

      case 'setPitch':
        final pitch = extras!['pitch'] as double;
        _player.setPitch(pitch);
        break;

      case 'clearQueue':
        if (queue.value.isEmpty) break;

        // Move current song to the top if we have a valid index
        final keepIndex = currentIndex;
        if (keepIndex is int && keepIndex >= 0 && keepIndex < queue.value.length) {
            customAction("reorderQueue", {'oldIndex': keepIndex, 'newIndex': 0});
        }
        
        final newQueue = queue.value;
        if (newQueue.length > 1) {
             newQueue.removeRange(1, newQueue.length);
        }
        queue.add(newQueue);
        
        if (shuffleModeEnabled) {
          shuffledQueue.clear();
          if (newQueue.isNotEmpty) {
             shuffledQueue.add(newQueue[0].id);
          }
          currentShuffleIndex = 0;
        }
        // Safely reset index
        currentIndex = newQueue.isNotEmpty ? 0 : 0;
        break;
      default:
        break;
    }
  }

  void _shuffleCmd(int index) {
    if (queue.value.isEmpty) return;
    final safeIndex =
        (index < 0 || index >= queue.value.length) ? 0 : index;
    final queueIds = queue.value.toList().map((item) => item.id).toList();
    final currentSongId = queueIds.removeAt(safeIndex);
    queueIds.shuffle();
    queueIds.insert(0, currentSongId);
    shuffledQueue.replaceRange(0, shuffledQueue.length, queueIds);
    currentShuffleIndex = 0;
  }

  void _normalizeVolume(double currentLoudnessDb) {
    // youtube_explode_dart v3 no longer provides loudnessDb (passed as 0).
    // Skip normalization instead of attenuating every song to ~56% volume.
    if (currentLoudnessDb == 0) return;
    double loudnessDifference = -5 - currentLoudnessDb;

    // Converted loudness difference to a volume multiplier
    // We use a factor to convert dB difference to a linear scale
    // 10^(difference / 20) converts dB difference to a linear volume factor
    final volumeAdjustment = pow(10.0, loudnessDifference / 20.0);
    printINFO(
        "loudness:$currentLoudnessDb Normalized volume: $volumeAdjustment");
    _player.setVolume(volumeAdjustment.toDouble().clamp(0, 1.0));
  }

  Future<void> saveSessionData() async {
    try {
      if (Get.find<SettingsScreenController>().restorePlaybackSession.isFalse) {
        return;
      }
    } catch (e) {
      printERROR("SettingsScreenController not found during saveSessionData");
      // Continue anyway as defaults might be okay or check Hive directly if critical
    }
    final currQueue = queue.value;
    if (currQueue.isNotEmpty) {
      final queueData =
          currQueue.map((e) => MediaItemBuilder.toJson(e)).toList();
      final currIndex = currentIndex ?? 0;
      final position = _player.position.inMilliseconds;
      final prevSessionData = await Hive.openBox("prevSessionData");
      await prevSessionData.clear();
      await prevSessionData.putAll(
          {"queue": queueData, "position": position, "index": currIndex});
      await prevSessionData.close();
      printINFO("Saved session data");
    }
  }

  Future<void> restoreSession() async {
    try {
      final prevSessionBox = await Hive.openBox("prevSessionData");
      if (prevSessionBox.isEmpty) return;

      final List<dynamic>? queueData = prevSessionBox.get("queue");
      final int? index = prevSessionBox.get("index");
      final int? position = prevSessionBox.get("position");

      if (queueData != null && queueData.isNotEmpty) {
        final List<MediaItem> restoredQueue = queueData
            .map((e) => MediaItemBuilder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        queue.add(restoredQueue);
        currentIndex = index ?? 0;
        
        if (currentIndex < restoredQueue.length) {
          final item = restoredQueue[currentIndex];
          mediaItem.add(item);
          
          // Prepare the player without auto-playing
          final streamInfo = await checkNGetUrl(item.id);
          if (streamInfo.playable) {
            currentSongUrl = item.extras!['url'] = streamInfo.audio!.url;
            if (_playList.children.isNotEmpty) await _playList.clear();
            await _playList.add(_createAudioSource(item));
            
            if (position != null) {
              await _player.seek(Duration(milliseconds: position));
            }

            // Update playback state to show controls in notification
            playbackState.add(playbackState.value.copyWith(
              controls: [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
              ],
              androidCompactActionIndices: const [0, 1, 2],
              systemActions: const {
                MediaAction.seek,
              },
              processingState: AudioProcessingState.ready,
              playing: false,
              updatePosition: _player.position,
              queueIndex: currentIndex,
            ));
          }
        }
        printINFO("Restored session data successfully");
      }
      await prevSessionBox.close();
    } catch (e) {
      printERROR("Error restoring session: $e");
    }
  }

  /// Android Auto
  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    return _mediaLibrary.getByRootId(parentMediaId);
  }

  @override
  ValueStream<Map<String, dynamic>> subscribeToChildren(String parentMediaId) {
    return Stream.fromFuture(
            _mediaLibrary.getByRootId(parentMediaId).then((items) => items))
        .map((_) => <String, dynamic>{})
        .shareValue();
  }

  // only for Android Auto
  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    customEvent.add({
      'eventType': 'playFromMediaId',
      'songId': mediaId,
      'libraryId': extras!['libraryId'],
    });
  }

  @override
  Future<void> onTaskRemoved() async {
    bool stopForegroundService = true;
    try {
      stopForegroundService =
        Get.find<SettingsScreenController>().stopPlyabackOnSwipeAway.value;
    } catch (e) {
      stopForegroundService = true;
    }

    if (stopForegroundService) {
       await stop();
       await super.onTaskRemoved();
       saveSessionData();
       return;
    }

    // For Resumption: Just save data and call super
    // androidStopForegroundOnPause: true will handle the swipe-ability
    saveSessionData();
    await super.onTaskRemoved();
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Fired specifically when swiped from Quick Settings (if possible)
    mediaItem.add(null);
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
      controls: [],
    ));
    await stop();
    await saveSessionData();
    await super.onNotificationDeleted();
  }

  @override
  Future<void> stop() async {
    printINFO("Stopping Audio Service and clearing notification...");
    // 1. Stop the player
    await _player.stop();
    
    // 2. Explicitly clear media item to remove it from carousel
    mediaItem.add(null);

    // 3. Update playback state to IDLE with NO controls
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
      controls: [], 
      systemActions: const {},
    ));

    // 4. Small delay to let OS update
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 5. Final stop
    await super.stop();
  }

// Work around used [useNewInstanceOfExplode = false] to Fix Connection closed before full header was received issue
  Future<SMStreamingData> checkNGetUrl(String songId,
      {bool generateNewUrl = false, bool offlineReplacementUrl = false}) async {
    await _initCompleter.future;
    printINFO("Requested id : $songId");

    final songDownloadsBox = Hive.box("SongDownloads");
    final songsCacheBox = await Hive.openBox("SongsCache");
    final cachedFilePath = "$_cacheDir/cachedSongs/$songId.mp3";

    // Only trust the SongsCache entry when the cached file still exists.
    // Android may wipe the temporary cache directory at any time; a missing
    // file used to be handed to just_audio as a dead file:// URL.
    var hasCachedSong = false;
    if (!offlineReplacementUrl && songsCacheBox.containsKey(songId)) {
      hasCachedSong = await File(cachedFilePath).exists();
      if (!hasCachedSong) {
        printERROR("Cached song file missing for $songId, refetching online");
        await songsCacheBox.delete(songId);
      }
    }

    if (hasCachedSong) {
      printINFO("Got Song from cachedbox ($songId)");
      // if contains stream Info
      final cacheEntry = songsCacheBox.get(songId);
      final streamInfo =
          cacheEntry is Map ? cacheEntry["streamInfo"] : null;
      Audio? cacheAudioPlaceholder;
      if (streamInfo is List &&
          streamInfo.length > 1 &&
          streamInfo[1] is Map) {
        final audioJson = Map<String, dynamic>.from(streamInfo[1] as Map);
        audioJson['url'] = "file://$cachedFilePath";
        cacheAudioPlaceholder = Audio.fromJson(audioJson);
      } else {
        cacheAudioPlaceholder = Audio(
            audioCodec: Codec.mp4a,
            bitrate: 0,
            loudnessDb: 0,
            duration: 0,
            size: 0,
            url: "file://$cachedFilePath",
            itag: 0);
      }

      return SMStreamingData(
          playable: true,
          statusMSG: "OK",
          lowQualityAudio: cacheAudioPlaceholder,
          highQualityAudio: cacheAudioPlaceholder);
    } else if (!offlineReplacementUrl && songDownloadsBox.containsKey(songId)) {
      final songEntry = songDownloadsBox.get(songId);
      final song = songEntry is Map ? songEntry : const <String, dynamic>{};
      final streamInfoJson = song["streamInfo"];
      Audio? audio;
      final rawPath = song['url'];
      final path = rawPath is String ? rawPath : "";
      if (streamInfoJson is List &&
          streamInfoJson.length > 1 &&
          streamInfoJson[1] is Map) {
        audio = Audio.fromJson(streamInfoJson[1]);
      } else {
        audio = Audio(
            itag: 140,
            audioCodec: Codec.mp4a,
            bitrate: 0,
            duration: 0,
            loudnessDb: 0,
            url: path,
            size: 0);
      }

      final streamInfo = SMStreamingData(
          playable: true,
          statusMSG: "OK",
          highQualityAudio: audio,
          lowQualityAudio: audio);

      if (path.contains(
          "${Get.find<SettingsScreenController>().supportDirPath}/Music")) {
        return streamInfo;
      }
      // check file access and if file exist in storage (status check only in background)
      final status = await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted ||
          await Permission.audio.isGranted;
      if (status && await File(path).exists()) {
        return streamInfo;
      }
      //in case file doesnot found in storage, song will be played online
      return checkNGetUrl(songId, offlineReplacementUrl: true);
    } else {
      //check if song stream url is cached and allocate url accordingly
      final songsUrlCacheBox = Hive.box("SongsUrlCache");
      final qualityIndex = Hive.box('AppPrefs').get('streamingQuality') ?? 1;
      SMStreamingData? streamInfo;
      if (songsUrlCacheBox.containsKey(songId) && !generateNewUrl) {
        final cached = songsUrlCacheBox.get(songId);
        if (cached is Map) {
          final low = cached['lowQualityAudio'];
          final high = cached['highQualityAudio'];
          // Validate the URL that will actually be played, not whichever one
          // happens to be stored first: a fresh low-quality URL used to hide an
          // expired high-quality one (or the reverse), and the dead URL was
          // then handed to the player, which failed with a 403.
          final preferred = (qualityIndex as num).toInt() == 0 ? low : high;
          final cachedUrl = preferred is Map ? preferred['url'] : null;
          if (cachedUrl is String && !isExpired(url: cachedUrl)) {
            printINFO("Got cached Url ($songId)");
            try {
              streamInfo = SMStreamingData.fromJson(cached);
            } catch (e) {
              printERROR("Invalid cached stream info for $songId: $e");
            }
          }
        }
      }

      if (streamInfo == null) {
        try {
          // Resolve on the main isolate. `Isolate.run` used to spawn a fresh
          // isolate (and re-initialise the binary messenger through a platform
          // channel) for every song, and a fresh isolate can never share the
          // extraction client's connection pool, so each track paid for a new
          // TLS handshake. The extraction itself is network-bound; the JSON it
          // parses is small, so doing it here is safe and much faster.
          final streamInfoJson = await getStreamInfo(songId);
          streamInfo = SMStreamingData.fromJson(streamInfoJson);
          if (streamInfo.playable) songsUrlCacheBox.put(songId, streamInfoJson);
        } catch (e, st) {
          printERROR("Failed to resolve stream for $songId: $e\n$st");
          return SMStreamingData(
              playable: false, statusMSG: "Unable to load this song");
        }
      }

      final resolved = streamInfo;
      if (resolved == null) {
        return SMStreamingData(
            playable: false, statusMSG: "Unable to load this song");
      }
      resolved.setQualityIndex((qualityIndex as num).toInt());
      return resolved;
    }
  }
}

class UrlError extends Error {
  String message() => 'Unable to fetch url';
}


// for Android Auto
class MediaLibrary {
  static const albumsRootId = 'albums';
  static const songsRootId = 'songs';
  static const favoritesRootId = "LIBFAV";
  static const playlistsRootId = 'playlists';

  Future<List<MediaItem>> getByRootId(String id) async {
    switch (id) {
      case AudioService.browsableRootId:
        return Future.value(getRoot());
      case songsRootId:
        return getLibSongs("SongDownloads");
      case favoritesRootId:
        return getLibSongs("LIBFAV");
      case albumsRootId:
        return getAlbums();
      case playlistsRootId:
        return getPlaylists();
      case AudioService.recentRootId:
        return getLibSongs("LIBRP");
      default:
        return getLibSongs(id);
    }
  }

  List<MediaItem> getRoot() {
    return [
      MediaItem(
        id: songsRootId,
        title: "songs".tr,
        playable: false,
      ),
      MediaItem(
        id: favoritesRootId,
        title: "favorites".tr,
        playable: false,
      ),
      MediaItem(
        id: albumsRootId,
        title: "albums".tr,
        playable: false,
      ),
      MediaItem(
        id: playlistsRootId,
        title: "playlists".tr,
        playable: false,
      ),
    ];
  }

  Future<List<MediaItem>> getAlbums() async {
    final box = await Hive.openBox("LibraryAlbums");
    final albums =
        box.values.map((item) => Album.fromJson(item).toMediaItem()).toList();
    await box.close();
    return albums;
  }

  Future<List<MediaItem>> getPlaylists() async {
    final box = await Hive.openBox("LibraryPlaylists");
    final playlists = [
      ...LibraryPlaylistsController.initPlst.map((e) => e.toMediaItem()),
      ...(box.values
          .map((item) => Playlist.fromJson(item).toMediaItem())
          .toList())
    ];
    await box.close();
    return playlists;
  }

  Future<List<MediaItem>> getLibSongs(String libId) async {
    Box<dynamic> box;
    try {
      box = await Hive.openBox(libId);
    } catch (e) {
      box = await Hive.openBox(libId);
    }
    final songs = box.values.toList().map((e) {
      final song = MediaItemBuilder.fromJson(e);
      return MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        artUri: song.artUri,
        extras: {"libraryId": libId},
        playable: true,
      );
    }).toList();

    if (!libId.contains("SongDownloads")) {
      await box.close();
    }

    if (libId == "LIBRP" || libId == "LIBFAV") {
      return songs.reversed.toList();
    }

    return songs;
  }
}
