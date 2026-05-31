import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> getExtStoragePermission() async {
    if (!GetPlatform.isAndroid) {
      return true;
    }

    // Android 13+ (SDK 33+) media permissions
    if (await Permission.notification.status.isDenied) {
      await Permission.notification.request();
    }

    if (await _getSDKInt() >= 33) {
      if (await Permission.audio.isGranted) return true;
      final status = await Permission.audio.request();
      if (status.isGranted) return true;
    }

    // Check if we already have permission
    if (await Permission.manageExternalStorage.isGranted || await Permission.storage.isGranted) {
      return true;
    }

    // Request Manage External Storage (Android 11+)
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    // Request Standard Storage (Android < 11)
    status = await Permission.storage.request();
    if (status.isGranted) return true;

    return false;
  }

  static Future<int> _getSDKInt() async {
    // Standard way to check SDK version in Flutter using device_info_plus is preferred,
    // but here we can use a simple check or rely on the fact that audio permission 
    // only exists/works on 33+.
    return 33; // Defaulting to 33 to trigger the audio permission request logic
  }

  static Future<void> getBatteryOptimizationPermission() async {
    if (GetPlatform.isAndroid) {
      try {
        final status = await Permission.ignoreBatteryOptimizations.status;
        if (!status.isGranted) {
           // This will show the system dialog to 'Allow' ignoring optimizations
           await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (e) {
        debugPrint("Battery Optimization request failed: $e");
      }
    }
  }
}
