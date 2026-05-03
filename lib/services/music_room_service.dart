import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shivaaymusic/models/music_room.dart';
import 'package:shivaaymusic/ui/navigator.dart';
import 'package:shivaaymusic/utils/helper.dart';

/// Service for managing music rooms - creation, joining, synchronization
class MusicRoomService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current room state
  final Rx<MusicRoom?> currentRoom = Rx<MusicRoom?>(null);
  final RxList<RoomParticipant> participants = <RoomParticipant>[].obs;
  final RxBool isHost = false.obs;
  final RxBool isInRoom = false.obs;

  StreamSubscription? _roomSubscription;
  StreamSubscription? _participantsSubscription;

  User? get _currentUser => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    // Check immediately if user is already available
    if (_currentUser != null) {
      _checkActiveRoom();
    }
    // Also listen to auth changes for cases where session is restored later
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _checkActiveRoom();
      }
    });
  }

  /// Check if user is currently a participant in any active room
  Future<void> _checkActiveRoom() async {
    if (_currentUser == null) return;
    
    // If already in a room, don't check again
    if (isInRoom.value) return;

    try {
      final query = await _firestore
          .collection('music_rooms')
          .where('participantIds', arrayContains: _currentUser!.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final roomId = query.docs.first.id;
        printINFO('Resuming existing room session: $roomId');
        await _joinRoomLocally(roomId);
      }
    } catch (e) {
      printERROR('Error checking active room: $e');
    }
  }

  @override
  void onClose() {
    _roomSubscription?.cancel();
    _participantsSubscription?.cancel();
    super.onClose();
  }

  /// Generate a unique 6-digit room code
  String _generateRoomCode() {
    final random = Random();
    // Generate 6-digit number (100000 to 999999)
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  /// Create a new music room
  Future<Map<String, dynamic>> createRoom({int maxParticipants = 10}) async {
    try {
      if (_currentUser == null) {
        return {
          'success': false,
          'message': 'You must be logged in to create a room',
        };
      }

      // Generate unique room code
      String roomCode = _generateRoomCode();
      
      // Check if code already exists (very unlikely but possible)
      final existingRoom = await _firestore
          .collection('music_rooms')
          .where('roomCode', isEqualTo: roomCode)
          .limit(1)
          .get();

      if (existingRoom.docs.isNotEmpty) {
        // Regenerate if collision occurs
        roomCode = _generateRoomCode();
      }

      printINFO('Generating roomId...');
      final roomId = _firestore.collection('music_rooms').doc().id;
      final now = DateTime.now();

      // Create room document
      final roomData = MusicRoom(
        roomId: roomId,
        roomCode: roomCode,
        hostId: _currentUser!.uid,
        hostName: _currentUser!.displayName ?? 'Unknown',
        createdAt: now,
        maxParticipants: maxParticipants,
        playbackState: RoomPlaybackState(
          isPlaying: false,
          position: Duration.zero,
          lastUpdateTime: now,
          queue: [],
        ),
        participants: [],
        participantIds: [_currentUser!.uid],
      );

      printINFO('Setting room document in Firestore...');
      await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .set(roomData.toJson());

      // Add host as first participant
      final hostParticipant = RoomParticipant(
        userId: _currentUser!.uid,
        userName: _currentUser!.displayName ?? 'Unknown',
        photoUrl: _currentUser!.photoURL,
        joinedAt: now,
        isHost: true,
        lastSeen: now,
      );

      printINFO('Updating participant document in Firestore...');
      await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(_currentUser!.uid)
          .set(hostParticipant.toJson());

      // Join the room locally
      printINFO('Joining room locally...');
      await _joinRoomLocally(roomId);

      printINFO('Room created: $roomCode');

      return {
        'success': true,
        'message': 'Room created successfully!',
        'roomCode': roomCode,
        'roomId': roomId,
      };
    } catch (e) {
      printERROR('Error creating room: $e');
      return {
        'success': false,
        'message': 'Failed to create room: $e',
      };
    }
  }

  /// Join an existing room by code
  Future<Map<String, dynamic>> joinRoom(String roomCode) async {
    try {
      if (_currentUser == null) {
        return {
          'success': false,
          'message': 'You must be logged in to join a room',
        };
      }

      // Find room by code
      final roomQuery = await _firestore
          .collection('music_rooms')
          .where('roomCode', isEqualTo: roomCode.toUpperCase())
          .limit(1)
          .get();

      if (roomQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Room not found. Please check the code.',
        };
      }

      final roomDoc = roomQuery.docs.first;
      final roomId = roomDoc.id;
      final roomData = MusicRoom.fromJson(roomDoc.data(), roomId);

      // Check if room is full
      final participantsSnapshot = await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .collection('participants')
          .get();

      if (participantsSnapshot.docs.length >= roomData.maxParticipants) {
        return {
          'success': false,
          'message': 'Room is full. Cannot join.',
        };
      }

      // Add user as participant
      final participant = RoomParticipant(
        userId: _currentUser!.uid,
        userName: _currentUser!.displayName ?? 'Unknown',
        photoUrl: _currentUser!.photoURL,
        joinedAt: DateTime.now(),
        isHost: false,
        lastSeen: DateTime.now(),
      );

      await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(_currentUser!.uid)
          .set(participant.toJson());

      // Update participantIds list in room document
      await _firestore.collection('music_rooms').doc(roomId).update({
        'participantIds': FieldValue.arrayUnion([_currentUser!.uid]),
      });

      // Join the room locally
      await _joinRoomLocally(roomId);

      printINFO('Joined room: $roomCode');

      return {
        'success': true,
        'message': 'Joined room successfully!',
        'roomId': roomId,
      };
    } catch (e) {
      printERROR('Error joining room: $e');
      return {
        'success': false,
        'message': 'Failed to join room: $e',
      };
    }
  }

  /// Internal method to set up room listeners after joining
  Future<void> _joinRoomLocally(String roomId) async {
    // Cancel existing subscriptions
    await _roomSubscription?.cancel();
    await _participantsSubscription?.cancel();

    // Listen to room updates
    _roomSubscription = _firestore
        .collection('music_rooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final room = MusicRoom.fromJson(snapshot.data()!, roomId);
        currentRoom.value = room.copyWith(participants: participants);
        isHost.value = room.hostId == _currentUser?.uid;
        isInRoom.value = true;
      } else {
        // Room was deleted
        _handleRoomClosed();
      }
    }, onError: (error) {
      printERROR('Room listener error: $error');
    });

    // Listen to participants updates
    _participantsSubscription = _firestore
        .collection('music_rooms')
        .doc(roomId)
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      participants.value = snapshot.docs
          .map((doc) => RoomParticipant.fromJson(doc.data()))
          .toList();
      
      // Update current room with participants
      if (currentRoom.value != null) {
        currentRoom.value = currentRoom.value!.copyWith(
          participants: participants,
        );
      }
    }, onError: (error) {
      printERROR('Participants listener error: $error');
    });

    // Update presence & start liveness monitoring (for auto-migration)
    _startPresenceUpdates(roomId);
    _startHostLivenessCheck(roomId);
  }

  /// Update user's last seen timestamp periodically
  Timer? _presenceTimer;
  void _startPresenceUpdates(String roomId) {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_currentUser != null && isInRoom.value && currentRoom.value != null) {
        try {
          await _firestore
              .collection('music_rooms')
              .doc(roomId)
              .collection('participants')
              .doc(_currentUser!.uid)
              .update({'lastSeen': Timestamp.now()});
        } catch (e) {
          // Document might not exist if room was closed or user left
          debugPrint('Presence update failed (expected if room closed): $e');
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    try {
      if (currentRoom.value == null || _currentUser == null) return;

      final roomId = currentRoom.value!.roomId;
      final wasHost = isHost.value;

      // Remove participant from Firestore immediately
      await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .collection('participants')
          .doc(_currentUser!.uid)
          .delete();

      // Remove from participantIds list
      await _firestore.collection('music_rooms').doc(roomId).update({
        'participantIds': FieldValue.arrayRemove([_currentUser!.uid]),
      });

      if (wasHost) {
        await _promoteNextHost(roomId);
      }

      _cleanupRoom();
      
      if (!wasHost || participants.where((p) => p.userId != _currentUser!.uid).isNotEmpty) {
        Get.snackbar(
          'Left Room',
          'You have left the music room',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      printERROR('Error leaving room: $e');
    }
  }

  /// Promote the oldest participant to Host role
  Future<void> _promoteNextHost(String roomId) async {
    try {
      // Filter out CURRENT user (who is leaving) and sort by joinedAt for seniority
      final remainingParticipants = participants
          .where((p) => p.userId != _currentUser?.uid)
          .toList()
        ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

      if (remainingParticipants.isNotEmpty) {
        final newHost = remainingParticipants.first;
        
        printINFO('Promoting senior member ${newHost.userName} to Host');

        // 1. Update Room Doc
        await _firestore.collection('music_rooms').doc(roomId).update({
          'hostId': newHost.userId,
          'hostName': newHost.userName,
        });

        // 2. Update Participant Doc
        await _firestore
            .collection('music_rooms')
            .doc(roomId)
            .collection('participants')
            .doc(newHost.userId)
            .update({'isHost': true});
      } else {
        // Absolutely no one left
        await closeRoom();
      }
    } catch (e) {
      printERROR('Failed to promote next host: $e');
    }
  }

  /// Monitors Host's "Last Seen" and triggers migration if Host seems disconnected
  Timer? _livenessTimer;
  void _startHostLivenessCheck(String roomId) {
    _livenessTimer?.cancel();
    _livenessTimer = Timer.periodic(const Duration(seconds: 45), (timer) async {
      if (!isInRoom.value || currentRoom.value == null) return;

      final currentHost = participants.firstWhereOrNull((p) => p.isHost);
      
      // If I am NOT the host, check if the current host is timed out
      if (currentHost != null && currentHost.userId != _currentUser?.uid) {
        final lastSeen = currentHost.lastSeen;
        final secondsSinceSeen = DateTime.now().difference(lastSeen).inSeconds;

        // If host hasn't checked in for 70 seconds, they likely crashed/killed app
        if (secondsSinceSeen > 70) {
          printINFO('Host ${currentHost.userName} timed out. Checking migration eligibility...');
          
          // Seniority Check: Only the FIRST eligible participant performs the promotion
          // to avoid multiple participants trying to update concurrently.
          final sortedParticipants = participants.toList()
            ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
            
          // Get the oldest participant who IS NOT the dead host
          final nextInLine = sortedParticipants.firstWhereOrNull((p) => p.userId != currentHost.userId);

          if (nextInLine?.userId == _currentUser?.uid) {
            printINFO('I am the next in line! Triggering automated host migration.');
            
            // Delete the dead host's participant entry
            await _firestore
                .collection('music_rooms')
                .doc(roomId)
                .collection('participants')
                .doc(currentHost.userId)
                .delete();
            
            // Remove from participantIds list
            await _firestore.collection('music_rooms').doc(roomId).update({
              'participantIds': FieldValue.arrayRemove([currentHost.userId]),
            });

            // Promote self (or next)
            await _promoteNextHost(roomId);
          }
        }
      }
    });
  }

  /// Close the room (host only)
  Future<void> closeRoom() async {
    try {
      if (currentRoom.value == null) return;

      final roomId = currentRoom.value!.roomId;
      
      printINFO('Closing room: $roomId');

      // Delete all messages first
      final messagesSnapshot = await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all participants
      final participantsSnapshot = await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .collection('participants')
          .get();

      for (var doc in participantsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete room document - This will trigger _handleRoomClosed for all participants
      await _firestore.collection('music_rooms').doc(roomId).delete();

      printINFO('Room closed successfully');
      
      // Clean up locally for host
      _cleanupRoom();
      
      Get.snackbar(
        'Room Closed',
        'The music room has been closed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      printERROR('Error closing room: $e');
      Get.snackbar(
        'Error',
        'Failed to close room: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Handle room being closed by host
  void _handleRoomClosed() {
    printINFO('Room document deleted. Performing forced cleanup and exit...');
    _cleanupRoom();
    
    // FORCED REDIRECTION: Ensure everyone is kicked out to Home
    try {
      // First close any open dialogs
      if (Get.isDialogOpen == true) Get.back();
      
      // Force nested navigator back to home from any room-related route
      Get.offAllNamed(
        ScreenNavigationSetup.homeScreen,
        id: ScreenNavigationSetup.id
      );
      
      printINFO('Forced exit successful');
    } catch (e) {
      printERROR('Error during forced exit: $e');
      // Final fallback
      Get.offAllNamed('/homeScreen');
    }
    
    Get.snackbar(
      'Room Closed',
      'The room session has ended',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Clean up local room state
  void _cleanupRoom() {
    _roomSubscription?.cancel();
    _participantsSubscription?.cancel();
    _presenceTimer?.cancel();
    _livenessTimer?.cancel();
    
    currentRoom.value = null;
    participants.clear();
    isHost.value = false;
    isInRoom.value = false;
  }

  /// Update playback state (host only)
  Future<void> updatePlaybackState({
    MediaItem? currentSong,
    bool? isPlaying,
    Duration? position,
    List<MediaItem>? queue,
  }) async {
    try {
      if (!isHost.value || currentRoom.value == null) return;

      final roomId = currentRoom.value!.roomId;
      final currentState = currentRoom.value!.playbackState;

      final newState = RoomPlaybackState(
        currentSong: currentSong ?? currentState.currentSong,
        isPlaying: isPlaying ?? currentState.isPlaying,
        position: position ?? currentState.position,
        lastUpdateTime: DateTime.now(),
        queue: queue ?? currentState.queue,
      );

      await _firestore
          .collection('music_rooms')
          .doc(roomId)
          .update({'playbackState': newState.toJson()});

      debugPrint('Playback state updated');
    } catch (e) {
      printERROR('Error updating playback state: $e');
    }
  }

  /// Get current playback state
  RoomPlaybackState? get playbackState => currentRoom.value?.playbackState;
}
