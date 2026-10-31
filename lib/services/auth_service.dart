import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:audio_service/audio_service.dart';
import '../ui/player/player_controller.dart';

import 'dart:async';
import 'dart:io';

import 'package:shivaaymusic/services/cloud_service.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Duration _authRequestTimeout = Duration(seconds: 20);
  
  // Native GoogleSignIn plugin (Only for Android/iOS)
  // On Windows, we use FirebaseAuth directly.
  late final GoogleSignIn _googleSignIn; 
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userStatusSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _lastHandledUid;

  final Rx<User?> _firebaseUser = Rx<User?>(null);

  // Keeps the root auth gate on a stable loading frame while Firebase restores its session.
  final RxBool isInitializing = true.obs;
  
  User? get currentUser => _firebaseUser.value;
  bool get isAuthenticated => _firebaseUser.value != null;

  /// Whether this device still has a signed-in account cached.
  ///
  /// Firebase's persisted session can take a while to come back on a cold
  /// start, especially with a slow connection or Play Services. The cached uid
  /// is proof that the user signed in here before, so the app keeps them in
  /// instead of showing the login screen and asking again.
  bool get hasSavedSession {
    final uid = _cachedAuthUid;
    return uid != null && uid.isNotEmpty;
  }

  /// Signed in either live or from the cached session.
  bool get isSignedIn => isAuthenticated || hasSavedSession;

  /// Uid of the last signed-in account cached on this device.
  ///
  /// `userId` is the key versions before 1.0.9 wrote, so it is used as a
  /// fallback to keep upgrades from briefly showing the login screen.
  String? get _cachedAuthUid {
    final box = Hive.box('AppPrefs');
    final uid = box.get('lastAuthUid') ?? box.get('userId');
    return uid?.toString();
  }
  
  // Observable user data
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhoto = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isAdmin = false.obs; // New Admiral flag
  final RxBool isVerified = false.obs; // Blue Tick badge flag

  @override
  void onInit() {
    super.onInit();

    if (!Platform.isWindows) {
      _googleSignIn = GoogleSignIn(
        // This is the type-3 client generated in android/app/google-services.json.
        serverClientId: "468199347944-u8k8m980b3u9vrun3cb038k1ph36rt8s.apps.googleusercontent.com",
      );
    }

    Get.put(CloudService(), permanent: true);
    _loadUserDataFromHive();

    // A cached uid means the user signed in on this device before. It lets the
    // app keep the loading gate up while Firebase restores the persisted
    // session instead of flashing the login screen on a cold start. `userId` is
    // the key older versions wrote, so upgrades keep working.
    final cachedUid = _cachedAuthUid;
    final restoredUser = _auth.currentUser;
    _firebaseUser.value = restoredUser;

    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);

    if (restoredUser != null) {
      _handleAuthState(restoredUser);
    } else {
      // Never hold the app on a loading screen while Firebase restores its
      // session, and never drop a cached session just because the restore is
      // slow. With a cached uid the app opens straight into Home with the
      // cached profile; the restore is confirmed quietly in the background.
      isInitializing.value = false;
      if (cachedUid != null && cachedUid.isNotEmpty) {
        _confirmSessionRestore();
      }
    }
  }

  /// Handles every Firebase auth state event.
  ///
  /// On a cold start Firebase can emit `null` before it has read the persisted
  /// session from disk, which used to clear the cached profile and show the
  /// login screen even though the user was still signed in. A `null` is now
  /// confirmed against [FirebaseAuth.currentUser] before the app logs out.
  void _onAuthStateChanged(User? user) {
    if (user != null) {
      _handleAuthState(user);
      return;
    }

    final cachedUid = _cachedAuthUid;
    if (cachedUid == null || cachedUid.isEmpty) {
      _handleAuthState(null);
      return;
    }
    _confirmSessionRestore();
  }

  bool _confirmingRestore = false;

  /// Waits in the background for Firebase to hand back the persisted session.
  ///
  /// This no longer clears anything on failure: the cached session stays in
  /// place, because a slow restore is not a sign-out. Only [signOut] (or a
  /// banned account) removes the cached uid, so the login screen cannot come
  /// back on its own.
  Future<void> _confirmSessionRestore() async {
    if (_confirmingRestore) return;
    _confirmingRestore = true;

    for (var attempt = 0; attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final user = _auth.currentUser;
      if (user != null) {
        _confirmingRestore = false;
        _handleAuthState(user);
        return;
      }
    }

    _confirmingRestore = false;
  }

  void _handleAuthState(User? user) {
    if (user == null) {
      _lastHandledUid = null;
      _userStatusSubscription?.cancel();
      _firebaseUser.value = null;
      _clearUserDataFromHive();
      isInitializing.value = false;
      return;
    }

    if (_lastHandledUid == user.uid && isInitializing.isFalse) return;
    final prefs = Hive.box('AppPrefs');
    final previousDataUid = prefs.get('cloudUserId')?.toString();
    final switchedAccount = previousDataUid != null && previousDataUid != user.uid;
    prefs.put('cloudUserId', user.uid);
    _lastHandledUid = user.uid;
    _firebaseUser.value = user;
    final localClear = switchedAccount
        ? _clearAccountOwnedData()
        : Future<void>.value();
    _saveUserDataToHive(user);
    _loadUserDataFromHive();
    _listenToUserStatus(user.uid);
    isInitializing.value = false;

    // Never block auth routing on Firestore. Restore only after Home has mounted.
    unawaited(_syncUserToFirestore(user));
    unawaited(_restoreUserDataWhenReady(user.uid, localClear));
  }

  Future<void> _restoreUserDataWhenReady(
    String uid,
    Future<void> localClear,
  ) async {
    await localClear;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_auth.currentUser?.uid != uid || !Get.isRegistered<CloudService>()) return;

    try {
      await Get.find<CloudService>().restoreAllDataFromCloud();
      if (Get.isRegistered<PlayerController>()) {
        Get.find<PlayerController>().update();
      }
    } catch (e) {
      debugPrint('Deferred cloud restore failed: $e');
    }
  }

  // Monitor User Status (Ban)
  void _listenToUserStatus(String uid) {
    _userStatusSubscription?.cancel();
    _userStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          if (data['isBanned'] == true) {
            signOut();
            Get.snackbar("Account Banned", "Your account has been banned by the administrator.",
                backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError,
                duration: const Duration(seconds: 5),
                snackPosition: SnackPosition.BOTTOM,
                isDismissible: false);
          }
          // Sync isAdmin status: Check Firestore field OR Hardcoded Master Email (Case-Insensitive)
          isAdmin.value = data['isAdmin'] == true || userEmail.value.toLowerCase() == "shivaay20005@gmail.com";
          
          // Sync isVerified status
          isVerified.value = data['isVerified'] == true;
        }
      }
    }, onError: (e) {
      debugPrint("Error listening to user status: $e");
    });
  }

  // Sync User Data to Firestore for Admin Panel Analytics
  Future<void> _syncUserToFirestore(User user) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Update Name, Email, Photo, Last Login
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? userName.value,
        'photoUrl': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
        // Master Admin Email auto-promotion (Case-Insensitive)
        if (user.email?.toLowerCase() == "shivaay20005@gmail.com") ...{
          'isAdmin': true,
          'isVerified': true,
        },
      }, SetOptions(merge: true));
      
      // Ensure default values for critical Admin flags if new doc
      final docSnap = await userDoc.get();
      if (!docSnap.exists || !docSnap.data()!.containsKey('isBanned')) {
         await userDoc.update({'isBanned': false});
      }
    } catch (e) {
      // Silent fail, don't block app usage if stats fail
      debugPrint("Firestore Sync Error: $e");
    }
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      isLoading.value = true;
      
      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(_authRequestTimeout);
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Save user data
      _firebaseUser.value = userCredential.user; // Manually update state
      _saveUserDataToHive(userCredential.user!, name: name);
      
      isLoading.value = false;
      
      return {
        'success': true,
        'message': 'Account created successfully!',
      };
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password is too weak. Please use a stronger password.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network issue detected. Please check your internet and try again.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please wait a moment and try again.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      isLoading.value = false;
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(_authRequestTimeout);
      
      _firebaseUser.value = userCredential.user; // Manually update state immediately
      _saveUserDataToHive(userCredential.user!);
      
      isLoading.value = false;

      return {
        'success': true,
        'message': 'Login successful!',
      };
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please try again.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network issue detected. Please check your internet and try again.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please wait a moment and try again.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } on TimeoutException {
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Login timed out. Please retry on a stable connection.',
      };
    } catch (e) {
      isLoading.value = false;
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      isLoading.value = true;
      UserCredential userCredential;

      if (Platform.isWindows) {
        // Windows: Use direct Firebase Auth provider (opens browser)
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        userCredential = await _auth.signInWithProvider(googleProvider);
      } else {
        // Mobile: Use native google_sign_in plugin
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          isLoading.value = false;
          return {
            'success': false,
            'message': 'Sign in canceled',
          };
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential)
            .timeout(_authRequestTimeout);
      }
      
      // Save user data
      _firebaseUser.value = userCredential.user; // Manually update state
      _saveUserDataToHive(userCredential.user!);
      
      isLoading.value = false;
      
      return {
        'success': true,
        'message': 'Signed in successfully with Google!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with this email using a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials. Please try again.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google Sign-In is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network issue detected. Please check your internet and try again.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } on TimeoutException {
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Google sign-in timed out. Please retry.',
      };
    } catch (e) {
      isLoading.value = false;
      // Detailed error logging for debugging
      debugPrint("❌ CRITICAL Google Sign-In Error: $e");
      
      String errorMsg = e.toString();
      if (errorMsg.contains("12500")) {
        errorMsg = "Error 12500: Internal error or missing Support Email in Firebase Console.";
      } else if (errorMsg.contains("10")) {
        errorMsg = "Error 10: SHA-1 mismatch. Check if the certificate registered in Firebase matches your build.";
      } else if (errorMsg.contains("network_error")) {
        errorMsg = "Network error. Check your connection.";
      }
      
      return {
        'success': false,
        'message': errorMsg,
      };
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _userStatusSubscription?.cancel();
    super.onClose();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _userStatusSubscription?.cancel();
      if (!Platform.isWindows) {
        await _googleSignIn.signOut();  // Sign out from Google (Mobile only)
      }
      
      // Stop music and clear queue
      if (Get.isRegistered<AudioHandler>()) {
        await Get.find<AudioHandler>().stop();
      }
      if (Get.isRegistered<PlayerController>()) {
        Get.find<PlayerController>().clearQueue();
      }
      
      // Forget the cached session before Firebase emits its sign-out event so
      // the listener shows LoginScreen immediately instead of waiting for the
      // restore-confirmation grace period.
      Hive.box('AppPrefs').delete('lastAuthUid');
      Hive.box('AppPrefs').delete('userId');
      await _auth.signOut();
      _clearUserDataFromHive();
    } catch (e) {
      // Log error silently without exposing to user
      _clearUserDataFromHive();
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Save user data to Hive for offline access
  void _saveUserDataToHive(User user, {String? name}) {
    final box = Hive.box('AppPrefs');
    box.put('lastAuthUid', user.uid);
    box.put('userId', user.uid);
    box.put('userEmail', user.email ?? '');
    box.put('userName', name ?? user.displayName ?? '');
    box.put('userPhoto', user.photoURL ?? '');
    
    userName.value = name ?? user.displayName ?? '';
    userEmail.value = user.email ?? '';
    userPhoto.value = user.photoURL ?? '';
  }

  /// Load user data from Hive
  void _loadUserDataFromHive() {
    final box = Hive.box('AppPrefs');
    userName.value = box.get('userName', defaultValue: '');
    userEmail.value = box.get('userEmail', defaultValue: '');
    userPhoto.value = box.get('userPhoto', defaultValue: '');
  }

  /// Clear user data from Hive
  Future<void> _clearAccountOwnedData() async {
    const boxNames = [
      'LIBFAV',
      'LIBRP',
      'LibraryArtists',
      'LibraryPlaylists',
      'searchQuery',
      'ListeningHistory',
      'ListeningStats',
      'ListeningStatsMetadata',
    ];
    for (final name in boxNames) {
      final box = Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
      await box.clear();
    }
  }

  void _clearUserDataFromHive() {
    final box = Hive.box('AppPrefs');
    box.delete('lastAuthUid');
    box.delete('userId');
    box.delete('userEmail');
    box.delete('userName');
    box.delete('userPhoto');
    userName.value = '';
    userEmail.value = '';
    userPhoto.value = '';
    isAdmin.value = false;
    isVerified.value = false;
  }

  /// Update user profile name
  Future<Map<String, dynamic>> updateUserName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently logged in',
        };
      }
      
      await user.updateDisplayName(newName);
      _saveUserDataToHive(user, name: newName);
      return {
        'success': true,
        'message': 'Name updated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update name: $e',
      };
    }
  }
}
