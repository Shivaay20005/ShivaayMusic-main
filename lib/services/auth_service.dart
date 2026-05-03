import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  StreamSubscription<DocumentSnapshot>? _userStatusSubscription; 

  final Rx<User?> _firebaseUser = Rx<User?>(null);
  
  // UI State Flag to prevent Black Screen
  final RxBool isInitializing = false.obs;
  
  User? get currentUser => _firebaseUser.value;
  bool get isAuthenticated => _firebaseUser.value != null;
  
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
    
    // Initialize GoogleSignIn only on Mobile platforms
    if (!Platform.isWindows) {
       _googleSignIn = GoogleSignIn();
    }
    
    Get.put(CloudService()); // Register CloudService
    _firebaseUser.value = _auth.currentUser;
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser.value = user;
      if (user != null) {
        _saveUserDataToHive(user);
        _loadUserDataFromHive();
        // Auto-Sync User Data structure (Metadata only)
        _syncUserToFirestore(user); 
        _listenToUserStatus(user.uid); 
        
        // Note: Full Data Restore is now MANUAL via Settings -> Backup & Restore
        // We removed auto-restore to prevent Login Black Screen issues.
        
        // HOWEVER: We silent-sync lightweight stuff like Favorites & Search History
        Future.delayed(const Duration(seconds: 3), () async {
          try {
            if (Get.isRegistered<CloudService>()) {
               final cloud = Get.find<CloudService>();
               await cloud.restoreFavorites();
               await cloud.restoreSearchHistory();
               
               // Update UI if user is on library screen
               if (Get.isRegistered<PlayerController>()) {
                  Get.find<PlayerController>().update(); // Triggers UI redraw for heart icons
               }
            }
          } catch (e) {
             debugPrint("Silent Sync Error: $e");
          }
        });

        // Explicit navigation removed to let main.dart Obx handle routing.
        // This avoids double-navigation black screen issues.
        
      } else {
        _clearUserDataFromHive();
        userName.value = '';
        userEmail.value = '';
      }
    });
    
    // Load saved user data on init
    _loadUserDataFromHive();
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
      debugPrint("❌ Google Sign-In Error: $e");
      if (e.toString().contains("network_error")) {
        return {'success': false, 'message': 'Network error. Check your connection.'};
      }
      return {
        'success': false,
        'message': 'Error: $e', // Show actual error temporarily for debugging
      };
    }
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
  void _clearUserDataFromHive() {
    final box = Hive.box('AppPrefs');
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
