import 'dart:io';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:audio_service/audio_service.dart';

class AudioBoosterController extends GetxController {
  final _box = Hive.box('AppPrefs');
  final _audioHandler = Get.find<AudioHandler>();
  
  var isBoosterEnabled = false.obs;
  var bassBoostLevel = 0.0.obs; // 0 to 1000 for Android
  var virtualizerLevel = 0.0.obs; // 0 to 1000
  var loudnessGain = 0.0.obs; // 0 to 200 (milliBels)
  var pitch = 1.0.obs; // 0.5 to 2.0

  @override
  void onInit() {
    super.onInit();
    // Use a small delay to ensure Hive and AudioHandler are ready
    Future.delayed(const Duration(milliseconds: 500), () {
      loadSettings();
    });
  }

  void loadSettings() {
    isBoosterEnabled.value = _box.get('booster_enabled', defaultValue: false);
    bassBoostLevel.value = _box.get('bass_boost_level', defaultValue: 0.0);
    virtualizerLevel.value = _box.get('virtualizer_level', defaultValue: 0.0);
    loudnessGain.value = _box.get('loudness_gain', defaultValue: 0.0);
    pitch.value = _box.get('audio_pitch', defaultValue: 1.0);
    
    if (isBoosterEnabled.value) {
      applyEffects();
    }
  }

  void toggleBooster(bool value) {
    isBoosterEnabled.value = value;
    _box.put('booster_enabled', value);
    _audioHandler.customAction('toggleBooster', {'enable': value});
    applyEffects();
  }

  void setBassBoost(double value) {
    bassBoostLevel.value = value;
    _box.put('bass_boost_level', value);
    if (isBoosterEnabled.value) applyEffects();
  }

  void setVirtualizer(double value) {
    virtualizerLevel.value = value;
    _box.put('virtualizer_level', value);
    if (isBoosterEnabled.value) applyEffects();
  }

  void setLoudnessGain(double value) {
    loudnessGain.value = value;
    _box.put('loudness_gain', value);
    if (isBoosterEnabled.value) applyEffects();
  }

  void setPitch(double value) {
    pitch.value = value;
    _box.put('audio_pitch', value);
    if (isBoosterEnabled.value) applyEffects();
  }

  void resetToDefault() {
    bassBoostLevel.value = 0.0;
    _box.put('bass_boost_level', 0.0);
    
    virtualizerLevel.value = 0.0;
    _box.put('virtualizer_level', 0.0);
    
    loudnessGain.value = 0.0;
    _box.put('loudness_gain', 0.0);
    
    pitch.value = 1.0;
    _box.put('audio_pitch', 1.0);
    
    if (isBoosterEnabled.value) applyEffects();
  }

  void applyEffects() {
    if (Platform.isAndroid) {
      _applyAndroidEffects();
    } else if (Platform.isWindows) {
      _applyWindowsEffects();
    }
  }

  void _applyAndroidEffects() {
    try {
      _audioHandler.customAction('updateBoosterLevels', {
        'bass': bassBoostLevel.value,
        'virt': virtualizerLevel.value,
        'gain': loudnessGain.value * 10, // Convert to milliBels (up to 2000)
      });
      
      _audioHandler.customAction('setPitch', {'pitch': pitch.value});
    } catch (e) {
      // debugPrint("Error applying Android effects: $e");
    }
  }

  void _applyWindowsEffects() {
    try {
      // For Windows, we will use the volume property as a simple booster for now
      // until we implement native libmpv filters.
      final baseVolume = _box.get('volume', defaultValue: 100);
      final boostFactor = 1.0 + (loudnessGain.value / 200); // Up to 2x boost
      _audioHandler.customAction('setVolume', {'value': (baseVolume * boostFactor).toInt()});
    } catch (e) {
      // debugPrint("Error applying Windows effects: $e");
    }
  }
}
