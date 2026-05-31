import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

import 'package:shivaaymusic/models/music_room.dart';
import 'package:shivaaymusic/services/music_room_service.dart';
import 'package:shivaaymusic/services/room_chat_service.dart';
import 'package:shivaaymusic/ui/player/player_controller.dart';
import 'package:shivaaymusic/ui/navigator.dart';
import 'package:shivaaymusic/utils/helper.dart';

class MusicRoomController extends GetxController with WidgetsBindingObserver {
  final MusicRoomService _roomService = Get.find<MusicRoomService>();
  final RoomChatService _chatService = Get.find<RoomChatService>();
  
  PlayerController? _playerController;

  final TextEditingController messageController = TextEditingController();
  final ScrollController chatScrollController = ScrollController();
  final FocusNode messageFocusNode = FocusNode();

  final RxBool isCreatingRoom = false.obs;
  final RxBool isJoiningRoom = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool showParticipants = false.obs;
  final RxDouble keyboardHeightManual = 0.0.obs;
  late StreamSubscription<bool> _keyboardSubscription;
  final RxBool isPlaybackSyncEnabled = true.obs;
  final RxBool isPlayerCollapsed = false.obs;
  final RxBool isMessageInputVisible = false.obs; // For Android FAB toggle

  // Getters for room service observables
  MusicRoom? get currentRoom => _roomService.currentRoom.value;
  List<RoomParticipant> get participants => _roomService.participants;
  bool get isHost => _roomService.isHost.value;
  bool get isInRoom => _roomService.isInRoom.value;

  @override
  void onInit() {
    super.onInit();
    
    // Track app lifecycle (to detect clear from recents)
    WidgetsBinding.instance.addObserver(this);
    
    // Get player controller if registered
    if (Get.isRegistered<PlayerController>()) {
      _playerController = Get.find<PlayerController>();
    }

    // Keep track of keyboard height for manual UI adjustments
    _keyboardSubscription = KeyboardVisibilityController().onChange.listen((bool visible) {
      if (visible) {
        Future.delayed(const Duration(milliseconds: 100), () {
           // On some Androids, mediaQuery must be fetched after a small delay for accuracy
           keyboardHeightManual.value = Get.mediaQuery.viewInsets.bottom;
        });
      } else {
        keyboardHeightManual.value = 0.0;
      }
    });

    // Listen to room changes to start/stop chat and set player modes
    ever(_roomService.currentRoom, (MusicRoom? room) {
      if (room != null) {
        _chatService.listenToMessages(room.roomId);
        _setPlayerRoomMode(true);
      } else {
        _chatService.stopListening();
        _setPlayerRoomMode(false);
        
        // AUTO-EXIT: Direct bahar fekh do jab room khatam ho jaye
        printINFO('Room session ended. Redirecting to Home...');
        try {
          // Check all possible room-related routes in the nested Navigator
          final currentRoute = Get.currentRoute;
          if (currentRoute.toLowerCase().contains('room')) {
             // Use the nested navigation ID to reset to home
             Get.offAllNamed(
               ScreenNavigationSetup.homeScreen, 
               id: ScreenNavigationSetup.id
             );
          }
        } catch (e) {
          debugPrint('Redirect error: $e');
        }
      }
    });

    // PREVENT AUTOMATIC MUSIC SYNC (User preference: Chat Only Mode)
    /*
    // Listen to playback state changes from room (for participants)
    ever(_roomService.currentRoom, (MusicRoom? room) {
      if (room != null && !isHost && isPlaybackSyncEnabled.value) {
        _syncPlayerWithRoom(room.playbackState);
      }
    });
    */

    // Auto-scroll chat to bottom when new messages arrive
    ever(_chatService.messages, (_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (chatScrollController.hasClients) {
          chatScrollController.animateTo(
            chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    chatScrollController.dispose();
    messageFocusNode.dispose();
    _keyboardSubscription.cancel();
    
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    
    super.onClose();
  }

  // Detect when app is "Cleared from Recents"
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Emergency leave room before app dies
      _roomService.leaveRoom();
    }
  }

  /// Create a new room
  Future<void> createRoom({int maxParticipants = 10}) async {
    try {
      printINFO('Starting room creation process...');
      isCreatingRoom.value = true;
      
      final result = await _roomService.createRoom(
        maxParticipants: maxParticipants,
      );

      printINFO('Room service creation result: ${result['success']}');
      isCreatingRoom.value = false;

      if (result['success']) {
        printINFO('Room created successfully, closing dialog...');
        Get.back(); // Close create dialog
        
        final roomCode = result['roomCode'];
        
        if (roomCode == null || roomCode.toString().isEmpty) {
          printERROR('Room code is missing in result!');
          Get.snackbar(
            'Error',
            'Room created but code is missing. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        
        printINFO('Navigating to room with code: $roomCode');
        // Navigate to room screen immediately
        Get.toNamed(ScreenNavigationSetup.musicRoom, id: ScreenNavigationSetup.id);
        
        // Show room code dialog briefly after entering room
        Future.delayed(const Duration(milliseconds: 500), () {
          _showRoomCodeDialog(roomCode, autoClose: true);
        });
      } else {
        printERROR('Room creation failed: ${result['message']}');
        Get.snackbar(
          'Error',
          result['message'],
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      printERROR('Unexpected error in createRoom: $e');
      isCreatingRoom.value = false;
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Show room code dialog with copy functionality
  void _showRoomCodeDialog(String roomCode, {bool autoClose = false}) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Room Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              autoClose 
                  ? 'You\'re now in the room! Share this code:' 
                  : 'Share this code with your friends:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // Room Code Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    roomCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Room Code',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Copy Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: roomCode));
                  Get.snackbar(
                    'Copied!',
                    'Room code copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            // Auto-close indicator
            if (autoClose)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Tap outside to close',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Got it!'),
          ),
        ],
      ),
      barrierDismissible: autoClose, // Allow tap outside to close if auto-closing
    );
    
    // Auto-close after 3 seconds if enabled
    if (autoClose) {
      Future.delayed(const Duration(seconds: 3), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      });
    }
  }

  /// Join an existing room
  Future<void> joinRoom(String roomCode) async {
    if (roomCode.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a room code',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isJoiningRoom.value = true;

    // Remove 'SHIVAAY-' prefix if user entered it
    String cleanCode = roomCode.trim().toUpperCase();
    // Clean up the code - remove any spaces or special characters
    cleanCode = cleanCode.replaceAll(RegExp(r'[^0-9]'), '');

    final result = await _roomService.joinRoom(cleanCode);

    isJoiningRoom.value = false;

    if (result['success']) {
      Get.back(); // Close dialog
      Get.toNamed(ScreenNavigationSetup.musicRoom, id: ScreenNavigationSetup.id); // Navigate to room screen
      
      Get.snackbar(
        'Joined Room',
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    await _roomService.leaveRoom();
    // Simple back navigation - works reliably
    try {
      if (Get.isDialogOpen == true) Get.back();
      Get.back();
    } catch (e) {
      // Fallback: Force navigate to home if back fails
      Get.offAllNamed('/homeScreen');
    }
  }


  /// Close the room (host only)
  Future<void> closeRoom() async {
    await _roomService.closeRoom();
    // Simple back navigation - works reliably
    try {
      if (Get.isDialogOpen == true) Get.back();
      Get.back();
    } catch (e) {
      // Fallback: Force navigate to home if back fails
      Get.offAllNamed('/homeScreen');
    }
  }

  /// Copy room code to clipboard
  void copyRoomCode() {
    if (currentRoom != null) {
      Clipboard.setData(ClipboardData(text: currentRoom!.roomCode));
      Get.snackbar(
        'Copied',
        'Room code copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Send a chat message
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isSendingMessage.value = true;

    final result = await _chatService.sendMessage(text);

    isSendingMessage.value = false;

    if (result['success']) {
      messageController.clear();
    } else {
      Get.snackbar(
        'Error',
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle participants list visibility
  void toggleParticipants() {
    showParticipants.value = !showParticipants.value;
  }

  /// Toggle playback synchronization
  void togglePlaybackSync() {
    isPlaybackSyncEnabled.value = !isPlaybackSyncEnabled.value;
    if (isPlaybackSyncEnabled.value && _roomService.currentRoom.value != null) {
      _syncPlayerWithRoom(_roomService.currentRoom.value!.playbackState);
    }
  }

  /// Toggle player collapse/expand
  void togglePlayerCollapse() {
    isPlayerCollapsed.value = !isPlayerCollapsed.value;
  }

  /// Set room mode state in player controller
  void _setPlayerRoomMode(bool enabled) {
    if (_playerController == null) return;
    
    _playerController!.isInRoomMode.value = enabled;
    if (enabled) {
      _playerController!.isRoomHost.value = isHost;
      _playerController!.roomService = _roomService;
    } else {
      _playerController!.isRoomHost.value = false;
      _playerController!.roomService = null;
    }
  }

  /// Sync local player with room playback state (for participants)
  Future<void> _syncPlayerWithRoom(RoomPlaybackState state) async {
    if (_playerController == null || isHost) return;

    try {
      final audioHandler = Get.find<AudioHandler>();
      bool songChanged = false;

      // 1. Sync current song (Keep everyone on the same track)
      if (state.currentSong != null) {
        final currentMediaItem = audioHandler.mediaItem.value;
        
        if (currentMediaItem?.id != state.currentSong!.id) {
          // Different song - load it
          await audioHandler.playMediaItem(state.currentSong!);
          songChanged = true;
          // If playback sync is disabled, we must pause after loading
          if (!isPlaybackSyncEnabled.value) {
            await audioHandler.pause();
          }
        }
      }

      // 2. Playback Sync (Only if enabled by participant)
      if (!isPlaybackSyncEnabled.value) return;

      // Calculate projected position based on time passed since last update
      Duration projectedPosition = state.position;
      if (state.isPlaying) {
        final elapsedTime = DateTime.now().difference(state.lastUpdateTime);
        projectedPosition += elapsedTime;
      }

      // Sync position (with tolerance to avoid constant seeking)
      final currentPosition = audioHandler.playbackState.value.position;
      final diff = (currentPosition - projectedPosition).abs();
      
      if (diff > const Duration(seconds: 3)) {
        await audioHandler.seek(projectedPosition);
      }

      // Sync play/pause state
      if (state.isPlaying || songChanged) {
        if (!audioHandler.playbackState.value.playing) {
          await audioHandler.play();
        }
      } else {
        if (audioHandler.playbackState.value.playing) {
          await audioHandler.pause();
        }
      }
    } catch (e) {
      debugPrint('Error syncing player: $e');
    }
  }

  /// Host controls - Play
  Future<void> hostPlay() async {
    if (!isHost || _playerController == null) return;
    await _playerController!.play();
  }

  /// Host controls - Pause
  Future<void> hostPause() async {
    if (!isHost || _playerController == null) return;
    await _playerController!.pause();
  }

  /// Host controls - Next
  Future<void> hostNext() async {
    if (!isHost || _playerController == null) return;
    await _playerController!.skipToNext();
  }

  /// Host controls - Previous
  Future<void> hostPrevious() async {
    if (!isHost || _playerController == null) return;
    await _playerController!.skipToPrevious();
  }

  /// Host controls - Seek
  Future<void> hostSeek(Duration position) async {
    if (!isHost) return;
    
    try {
      final audioHandler = Get.find<AudioHandler>();
      await audioHandler.seek(position);
      
      // Update room state
      await _roomService.updatePlaybackState(position: position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }
}
