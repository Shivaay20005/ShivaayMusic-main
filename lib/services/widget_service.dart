import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WidgetService extends GetxController {
  static const androidPlatform = MethodChannel('com.shivaay20005.shivaaymusicflutter/widget');
  static const iosPlatform = MethodChannel('com.shivaay20005.shivaaymusicflutter/iosWidget');

  /// Send song information to the widget
  Future<void> updateWidget({
    String? songTitle,
    String? songArtist,
    String? albumArtUrl,
    bool isPlaying = false,
    double progress = 0.0,
    int duration = 0,
    int currentTime = 0,
  }) async {
    try {
      final Map<String, dynamic> args = {
        'songTitle': songTitle,
        'songArtist': songArtist,
        'albumArtUrl': albumArtUrl,
        'isPlaying': isPlaying,
        'progress': progress,
        'duration': duration,
        'currentTime': currentTime,
      };

      if (Platform.isAndroid) {
        await androidPlatform.invokeMethod('updateWidget', args);
      } else if (Platform.isIOS) {
        await iosPlatform.invokeMethod('updateWidget', args);
      }
    } on PlatformException catch (e) {
      // Handle platform exception
      debugPrint("Failed to update widget: '${e.message}'.");
    }
  }

  /// Notify widget that playback has started
  Future<void> notifyPlay() async {
    try {
      if (Platform.isAndroid) {
        await androidPlatform.invokeMethod('notifyPlay');
      } else if (Platform.isIOS) {
        await iosPlatform.invokeMethod('notifyPlay');
      }
    } on PlatformException catch (e) {
      // Handle platform exception
      debugPrint("Failed to notify play: '${e.message}'.");
    }
  }

  /// Notify widget that playback has paused
  Future<void> notifyPause() async {
    try {
      if (Platform.isAndroid) {
        await androidPlatform.invokeMethod('notifyPause');
      } else if (Platform.isIOS) {
        await iosPlatform.invokeMethod('notifyPause');
      }
    } on PlatformException catch (e) {
      // Handle platform exception
      debugPrint("Failed to notify pause: '${e.message}'.");
    }
  }
}