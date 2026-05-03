import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/chat_message.dart';
import '../utils/helper.dart';

/// Service for handling real-time chat in music rooms
class RoomChatService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription? _messagesSubscription;
  String? _currentRoomId;

  User? get _currentUser => _auth.currentUser;

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    super.onClose();
  }

  /// Start listening to messages for a specific room
  void listenToMessages(String roomId) {
    _currentRoomId = roomId;
    _messagesSubscription?.cancel();

    isLoading.value = true;

    _messagesSubscription = _firestore
        .collection('music_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(50) // Load last 50 messages
        .snapshots()
        .listen(
      (snapshot) {
        messages.value = snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data(), doc.id))
            .toList();
        isLoading.value = false;
      },
      onError: (error) {
        printERROR('Chat listener error: $error');
        isLoading.value = false;
      },
    );
  }

  /// Send a chat message
  Future<Map<String, dynamic>> sendMessage(String text) async {
    try {
      if (_currentUser == null) {
        return {
          'success': false,
          'message': 'You must be logged in to send messages',
        };
      }

      if (_currentRoomId == null) {
        return {
          'success': false,
          'message': 'Not in a room',
        };
      }

      if (text.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Message cannot be empty',
        };
      }

      final messageData = {
        'userId': _currentUser!.uid,
        'userName': _currentUser!.displayName ?? 'Unknown',
        'userPhotoUrl': _currentUser!.photoURL,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('music_rooms')
          .doc(_currentRoomId)
          .collection('messages')
          .add(messageData);

      return {
        'success': true,
        'message': 'Message sent',
      };
    } catch (e) {
      printERROR('Error sending message: $e');
      return {
        'success': false,
        'message': 'Failed to send message: $e',
      };
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    try {
      if (_currentRoomId == null || messages.isEmpty) return;

      isLoading.value = true;

      final oldestMessage = messages.first;
      final snapshot = await _firestore
          .collection('music_rooms')
          .doc(_currentRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .endBefore([oldestMessage.timestamp])
          .limit(20)
          .get();

      final olderMessages = snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data(), doc.id))
          .toList();

      messages.insertAll(0, olderMessages);
      isLoading.value = false;
    } catch (e) {
      printERROR('Error loading more messages: $e');
      isLoading.value = false;
    }
  }

  /// Stop listening to messages
  void stopListening() {
    _messagesSubscription?.cancel();
    _currentRoomId = null;
    messages.clear();
  }

  /// Clear all messages (for cleanup)
  void clearMessages() {
    messages.clear();
  }
}
