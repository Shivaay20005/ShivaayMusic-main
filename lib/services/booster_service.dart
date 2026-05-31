import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BoosterService {
  static const _channel = MethodChannel('com.shivaay20005.shivaaymusic/booster');

  static void initEffects(int sessionId) {
    if (!Platform.isAndroid) return;
    try {
      _channel.invokeMethod('init', {'sessionId': sessionId});
    } catch (e) {
      debugPrint("Error initializing native booster: $e");
    }
  }

  static void setEnabled(bool enabled) {
    if (!Platform.isAndroid) return;
    try {
      _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } catch (e) {
      debugPrint("Error setting booster state: $e");
    }
  }

  static void setBassLevel(int level) {
    if (!Platform.isAndroid) return;
    try {
      // level is 0 to 1000
      _channel.invokeMethod('setBass', {'level': level});
    } catch (e) {
      debugPrint("Error setting bass level: $e");
    }
  }

  static void setVirtualizerLevel(int level) {
    if (!Platform.isAndroid) return;
    try {
      // level is 0 to 1000
      _channel.invokeMethod('setVirtualizer', {'level': level});
    } catch (e) {
      debugPrint("Error setting virtualizer level: $e");
    }
  }

  static void setLoudnessGain(int gainInMilliBels) {
    if (!Platform.isAndroid) return;
    try {
      // 0 to 2000 mB
      _channel.invokeMethod('setGain', {'gain': gainInMilliBels});
    } catch (e) {
      debugPrint("Error setting loudness gain: $e");
    }
  }
  
  static void dispose() {
    // Optional
  }
}
