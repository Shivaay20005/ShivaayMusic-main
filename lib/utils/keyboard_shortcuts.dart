import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../ui/player/player_controller.dart';
import '../ui/screens/Search/search_screen.dart';
import '../ui/screens/Settings/settings_screen.dart';
import '../services/downloader.dart';
import '../ui/widgets/sleep_timer_bottom_sheet.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  
  const KeyboardShortcuts({
    super.key, 
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!GetPlatform.isDesktop) return child;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          return _handleKeyEvent(event);
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  KeyEventResult _handleKeyEvent(KeyDownEvent event) {
    // Check if text input is active to avoid keyboard conflicts (e.g. typing 'm' causing mute)
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode != null && focusNode.context != null) {
      final isEditable = focusNode.context!.widget is EditableText ||
          focusNode.context!.findAncestorWidgetOfExactType<EditableText>() !=
              null;
      if (isEditable) {
        return KeyEventResult.ignored;
      }
    }

    final playerController = Get.find<PlayerController>();
    
    // Helper for modifiers
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;

    // ⏯️ Play/Pause (Space)
    if (event.logicalKey == LogicalKeyboardKey.space && !isCtrl) {
      playerController.playPause();
      return KeyEventResult.handled;
    }

    // ⏩ Seek Forward (Right Arrow)
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final current = playerController.progressBarStatus.value.current;
      final duration = playerController.progressBarStatus.value.total;
      final skip = isCtrl ? 30 : 10;
      final newPos = current + Duration(seconds: skip);
      playerController.seek(newPos > duration ? duration : newPos);
      return KeyEventResult.handled;
    }

    // ⏪ Seek Backward (Left Arrow)
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final current = playerController.progressBarStatus.value.current;
      final skip = isCtrl ? 30 : 10;
      final newPos = current - Duration(seconds: skip);
      playerController.seek(newPos.isNegative ? Duration.zero : newPos);
      return KeyEventResult.handled;
    }

    // 🔊 Volume Up (Up Arrow)
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final current = playerController.volume.value;
      // Ctrl+Up = 25, Normal = 10 (Volume is 0-100)
      final step = isCtrl ? 25 : 10;
      final newVol = (current + step).clamp(0, 100);
      playerController.setVolume(newVol);
      return KeyEventResult.handled;
    }

    // 🔉 Volume Down (Down Arrow)
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final current = playerController.volume.value;
      final step = isCtrl ? 25 : 10;
      final newVol = (current - step).clamp(0, 100);
      playerController.setVolume(newVol);
      return KeyEventResult.handled;
    }

    // 🔇 Mute (M)
    if (event.logicalKey == LogicalKeyboardKey.keyM && !isCtrl) {
      playerController.mute();
      return KeyEventResult.handled;
    }

    // ⏭️ Next Song (Ctrl+N or Alt+Right)
    if ((event.logicalKey == LogicalKeyboardKey.keyN && isCtrl) || 
        (event.logicalKey == LogicalKeyboardKey.arrowRight && isAlt)) {
      playerController.next();
      return KeyEventResult.handled;
    }

    //⏮️ Prev Song (Ctrl+P or Alt+Left)
    if ((event.logicalKey == LogicalKeyboardKey.keyP && isCtrl) || 
        (event.logicalKey == LogicalKeyboardKey.arrowLeft && isAlt)) {
      playerController.prev();
      return KeyEventResult.handled;
    }

    // 🔀 Shuffle (Ctrl+S)
    if (event.logicalKey == LogicalKeyboardKey.keyS && isCtrl && !isShift) {
      playerController.toggleShuffleMode();
      return KeyEventResult.handled;
    }

    // 🔁 Loop Mode (Ctrl+L)
    if (event.logicalKey == LogicalKeyboardKey.keyL && isCtrl) {
      playerController.toggleLoopMode();
      return KeyEventResult.handled;
    }
    
    // 📝 Toggle Lyrics (L or Ctrl+Y)
    if (event.logicalKey == LogicalKeyboardKey.keyL && !isCtrl) {
      playerController.showLyrics();
      return KeyEventResult.handled;
    }

    // ⬇️ Download Song (Ctrl+Shift+D)
    if (event.logicalKey == LogicalKeyboardKey.keyD && isCtrl && isShift) {
      if (playerController.currentSong.value != null) {
        Get.find<Downloader>().download(playerController.currentSong.value);
      }
      return KeyEventResult.handled;
    }
    
    //  Sleep Timer (Ctrl+T)
    if (event.logicalKey == LogicalKeyboardKey.keyT && isCtrl) {
      showModalBottomSheet(
        context: Get.context!,
        backgroundColor: Colors.transparent,
        builder: (context) => const SleepTimerBottomSheet(),
      );
      return KeyEventResult.handled;
    }
    
    // 📤 Share Song (Ctrl+Shift+S)
    if (event.logicalKey == LogicalKeyboardKey.keyS && isCtrl && isShift) {
      final song = playerController.currentSong.value;
      if (song != null) {
        Share.share("Check out this song: ${song.title} by ${song.artist}\nhttps://music.youtube.com/watch?v=${song.id}");
      }
      return KeyEventResult.handled;
    }

    // 🔼 Expand/Collapse Player (Ctrl+Up/Down)
    if (isCtrl && (event.logicalKey == LogicalKeyboardKey.arrowUp)) {
      playerController.playerPanelController.open();
      return KeyEventResult.handled;
    }
    if (isCtrl && (event.logicalKey == LogicalKeyboardKey.arrowDown)) {
      playerController.playerPanelController.close();
      return KeyEventResult.handled;
    }

    // ❤️ Like/Heart (Ctrl+D or Ctrl+H)
    if ((event.logicalKey == LogicalKeyboardKey.keyD && isCtrl && !isShift) || 
        (event.logicalKey == LogicalKeyboardKey.keyH && isCtrl)) {
      playerController.toggleFavourite();
      return KeyEventResult.handled;
    }
    
    // 🔍 Search (Ctrl+F)
    if (event.logicalKey == LogicalKeyboardKey.keyF && isCtrl) {
      Get.to(() => const SearchScreen());
      return KeyEventResult.handled;
    }

    // ⚙️ Settings (Ctrl+,)
    if (event.logicalKey == LogicalKeyboardKey.comma && isCtrl) {
      Get.to(() => const SettingsScreen(isBottomNavActive: false)); 
      return KeyEventResult.handled;
    }
    
    // ❌ Close/Back (Esc)
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (playerController.playerPanelController.isPanelOpen) {
        playerController.playerPanelController.close();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }
}
