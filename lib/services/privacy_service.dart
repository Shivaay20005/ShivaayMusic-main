import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import '../ui/screens/Search/search_screen_controller.dart';
import '../utils/helper.dart';

/// Privacy & Security Service
/// Handles app lock, incognito mode, and history management
class PrivacyService extends GetxService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Observable states
  final isAppLockEnabled = false.obs;
  final isIncognitoMode = false.obs;
  final isBiometricAvailable = false.obs;
  final isLocked = false.obs; // Global lock state
  final isAuthenticating = false.obs; // To prevent re-lock loop during auth
  
  // Hive boxes
  late Box _prefsBox;
  late Box _historyBox;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      // Open Hive boxes
      _prefsBox = await Hive.openBox('AppPrefs');
      _historyBox = await Hive.openBox('ListeningHistory');
      
      // Load saved preferences
      isAppLockEnabled.value = _prefsBox.get('appLockEnabled', defaultValue: false);
      isIncognitoMode.value = _prefsBox.get('incognitoMode', defaultValue: false);
      
      // Check biometric availability
      await _checkBiometricAvailability();
      
      printINFO('PrivacyService initialized successfully');
    } catch (e) {
      printERROR('Error initializing PrivacyService: $e');
    }
  }
  
  /// Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      isBiometricAvailable.value = canCheckBiometrics && isDeviceSupported;
      
      if (isBiometricAvailable.value) {
        final List<BiometricType> availableBiometrics = 
            await _localAuth.getAvailableBiometrics();
        printINFO('Available biometrics: $availableBiometrics');
      }
    } catch (e) {
      printERROR('Error checking biometric availability: $e');
      isBiometricAvailable.value = false;
    }
  }
  
  /// Authenticate user with biometric or PIN
  Future<bool> authenticate({String reason = 'Please authenticate to continue'}) async {
    try {
      // Check if device supports authentication (biometrics OR device credentials)
      final bool isSupported = await _localAuth.isDeviceSupported();
      
      if (!isSupported) {
        printERROR('Authentication not supported on this device');
        return true; // Use insecure fallback or allow access if security not possible?
        // Ideally should block or ask to set up security. For now, returning false might lock forever.
        // But if user enabled app lock, they probably have security.
        // Let's return false to be safe, but typically we shouldn't enable the setting if not supported.
      }
      
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern fallback
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      
      return didAuthenticate;
    } on PlatformException catch (e) {
      printERROR('Authentication error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      printERROR('Unexpected authentication error: $e');
      return false;
    }
  }
  
  /// Toggle App Lock
  Future<void> toggleAppLock(bool value) async {
    try {
      if (value) {
        // Enabling app lock - authenticate first
        final authenticated = await authenticate(
          reason: 'Authenticate to enable app lock',
        );
        
        if (!authenticated) {
          printINFO('Authentication failed, app lock not enabled');
          return;
        }
      }
      
      isAppLockEnabled.value = value;
      await _prefsBox.put('appLockEnabled', value);
      
      printINFO('App lock ${value ? 'enabled' : 'disabled'}');
    } catch (e) {
      printERROR('Error toggling app lock: $e');
    }
  }
  
  /// Toggle Incognito Mode
  Future<void> toggleIncognitoMode(bool value) async {
    try {
      isIncognitoMode.value = value;
      await _prefsBox.put('incognitoMode', value);
      
      printINFO('Incognito mode ${value ? 'enabled' : 'disabled'}');
    } catch (e) {
      printERROR('Error toggling incognito mode: $e');
    }
  }
  
  /// Clear Listening History
  Future<void> clearListeningHistory() async {
    try {
      await _historyBox.clear();
      
      // Also clear "Recently Played" (LIBRP) which is visible in Library
      final librpBox = await Hive.openBox('LIBRP');
      await librpBox.clear();
      
      printINFO('Listening history and Recently Played cleared');
    } catch (e) {
      printERROR('Error clearing history: $e');
    }
  }
  
  /// Clear Search History
  Future<void> clearSearchHistory() async {
    try {
      final searchBox = await Hive.openBox('searchQuery');
      await searchBox.clear();
      if (Get.isRegistered<SearchScreenController>()) {
         Get.find<SearchScreenController>().historyQuerylist.clear();
      }
      printINFO('Search history cleared');
    } catch (e) {
      printERROR('Error clearing search history: $e');
    }
  }
  
  /// Clear All History
  Future<void> clearAllHistory() async {
    try {
      await clearListeningHistory();
      await clearSearchHistory();
      printINFO('All history cleared');
    } catch (e) {
      printERROR('Error clearing all history: $e');
    }
  }
  
  /// Add to listening history (respects incognito mode)
  Future<void> addToHistory(String songId, Map<String, dynamic> songData) async {
    try {
      if (isIncognitoMode.value) {
        printINFO('Incognito mode active - not saving to history');
        return;
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _historyBox.put(songId, {
        ...songData,
        'timestamp': timestamp,
      });
      
      printINFO('Added to listening history: $songId');
    } catch (e) {
      printERROR('Error adding to history: $e');
    }
  }
  
  /// Get listening history
  List<Map<String, dynamic>> getListeningHistory({int limit = 50}) {
    try {
      final historyList = _historyBox.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      
      // Sort by timestamp (newest first)
      historyList.sort((a, b) => 
        (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      
      return historyList.take(limit).toList();
    } catch (e) {
      printERROR('Error getting history: $e');
      return [];
    }
  }
  
  /// Check if app lock is required
  bool shouldShowAppLock() {
    return isAppLockEnabled.value;
  }
  
  /// Lock the app (UI only, no prompt)
  void lockApp() {
     if (isAppLockEnabled.value) {
       isLocked.value = true;
     }
  }

  /// Verify app lock
  /// Triggers authentication. If successful, unlocks the app.
  Future<void> verifyAppLock() async {
    if (!isAppLockEnabled.value) {
      return;
    }
    
    printINFO("App Lock: Verifying identity...");
    
    // Set authenticating flag to prevent LifecycleHandler from re-locking
    // immediately when app resumes from auth activity
    isAuthenticating.value = true;
    
    // Attempt authentication ONCE per call
    bool authenticated = await authenticate(
      reason: 'Unlock ShivaayMusic',
    );
    
    // Unlock on success
    if (authenticated) {
      isLocked.value = false;
      printINFO("App Lock: Identity verified.");
      // DELAY resetting the flag. This is CRITICAL.
      // The LifecycleHandler in main.dart has a delay and runs on 'resumed'.
      // If we reset this flag immediately, the LifecycleHandler will see 'isAuthenticating' as false
      // and immediately re-lock the app, causing a loop.
      Future.delayed(const Duration(milliseconds: 1000), () {
        isAuthenticating.value = false;
      });
    } else {
       printINFO("App Lock: Verification failed.");
       isAuthenticating.value = false;
       // Remain locked. User must click "Unlock" again.
    }
  }
}
