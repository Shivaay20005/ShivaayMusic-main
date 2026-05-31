// ignore_for_file: avoid_print
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  
  // Open and clear AppPrefs box
  var box = await Hive.openBox('AppPrefs');
  
  print('Current AppPrefs keys: ${box.keys.toList()}');
  print('streamingQuality value: ${box.get('streamingQuality')}');
  print('skipSilenceEnabled value: ${box.get('skipSilenceEnabled')}');
  
  // Set default values
  await box.put('streamingQuality', 2); // AudioQuality.High
  await box.put('skipSilenceEnabled', false);
  
  print('\nAfter setting defaults:');
  print('streamingQuality value: ${box.get('streamingQuality')}');
  print('skipSilenceEnabled value: ${box.get('skipSilenceEnabled')}');
  
  await box.close();
  print('\nDone! You can now run the app.');
}
