import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat message in a music room
class ChatMessage {
  final String messageId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.messageId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String messageId) {
    return ChatMessage(
      messageId: messageId,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      text: json['text'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  ChatMessage copyWith({
    String? messageId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? text,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool isFromUser(String userId) => this.userId == userId;
}
