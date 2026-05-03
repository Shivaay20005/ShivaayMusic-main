import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'music_room_controller.dart';
import '../../../services/room_chat_service.dart';
import '../../../models/chat_message.dart';

class RoomChatScreen extends StatelessWidget {
  const RoomChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicRoomController>();
    final chatService = Get.find<RoomChatService>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Room Chat'),
        leading: IconButton(
          icon: const Icon(Ionicons.chevron_back),
          onPressed: () => Get.back(id: 1),
        ),
      ),
      bottomNavigationBar: _buildMessageInput(context, controller),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Obx(() {
              if (chatService.isLoading.value && chatService.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (chatService.messages.isEmpty) {
                return const Center(
                  child: Text('No messages yet. Start chatting!'),
                );
              }

              return ListView.builder(
                controller: controller.chatScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatService.messages.length,
                itemBuilder: (context, index) {
                  final message = chatService.messages[index];
                  return _buildMessageBubble(context, message);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, MusicRoomController controller) {
    return Material(
      elevation: 24, // High elevation to ensure visibility
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => controller.sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Ionicons.send, color: Colors.white, size: 20),
                  onPressed: controller.sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: message.userPhotoUrl != null
                ? CachedNetworkImageProvider(message.userPhotoUrl!)
                : null,
            child: message.userPhotoUrl == null
                ? Text(message.userName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(message.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
