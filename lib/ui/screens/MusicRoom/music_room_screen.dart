import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'music_room_controller.dart';
import '../../player/player_controller.dart';
import '../../navigator.dart'; // Added missing import
import '../../../services/room_chat_service.dart';
import '../../../models/chat_message.dart';

class MusicRoomScreen extends StatelessWidget {
  const MusicRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicRoomController>();
    final chatService = Get.find<RoomChatService>();
    final playerController = Get.find<PlayerController>();

    return PopScope(
      canPop: true, // Allow back navigation without leaving room
      onPopInvokedWithResult: (didPop, result) async {
        // Just go back, room stays alive in background service
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Returning to reliable Auto-System
        appBar: AppBar(
          centerTitle: true,
          title: Obx(() => GestureDetector(
                onTap: () => _showParticipantsSheet(context, controller),
                child: Column(
                  children: [
                    Text(
                      controller.isHost ? 'Music Room & Chat (Host)' : 'Music Room & Chat',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Ionicons.peopleOutline, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Participants: ${controller.participants.length}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          actions: [
            // Restoring the backup Chat Button
            IconButton(
              icon: const Icon(Ionicons.chatbubbleEllipses, color: Colors.blueAccent),
              tooltip: 'Full Screen Chat',
              onPressed: () => Get.toNamed(ScreenNavigationSetup.musicRoomChat, id: ScreenNavigationSetup.id),
            ),
            Obx(() => IconButton(
                  icon: Icon(
                    controller.isHost ? Ionicons.closeCircle : Ionicons.exit,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _showLeaveDialog(context, controller),
                )),
          ],
        ),
        body: Stack(
          children: [
            Obx(() => Padding(
              padding: EdgeInsets.only(bottom: playerController.currentSong.value != null ? 180 : 110),
              child: Column(
                children: [
                  _buildRoomCodeSection(context, controller),
                  // Chat Area (Expanded)
                  Expanded(
                    child: _buildMessagesList(context, controller, chatService),
                  ),
                ],
              ),
            )),
            
            // THE USER FAVORITE STACK INPUT (Platform Optimized)
            Obx(() {
              final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
              final isPlaying = playerController.currentSong.value != null;
              final miniPlayerHeight = playerController.playerPanelMinHeight.value;
              final isDesktop = GetPlatform.isDesktop;
              
              // HEAVILY TUNED OFFSETS
              // Windows: 10px from bottom (Clean Desktop look)
              // Android: 95px/160px (Floating touch-friendly look)
              final double bottomPosition = isKeyboardOpen 
                  ? 10.0 
                  : (isPlaying 
                      ? (miniPlayerHeight + (isDesktop ? 10.0 : 65.0)) 
                      : (isDesktop ? 10.0 : 95.0));

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                bottom: bottomPosition,
                left: isDesktop ? 24 : 12, // More width on desktop
                right: isDesktop ? 24 : 12,
                child: _buildLaptopStyleInput(context, controller, playerController),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLaptopStyleInput(
      BuildContext context, MusicRoomController controller, PlayerController playerController) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.messageController,
                focusNode: controller.messageFocusNode,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: const Icon(Ionicons.send, color: Colors.white, size: 20),
              onPressed: controller.sendMessage,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRoomCodeSection(BuildContext context, MusicRoomController controller) {
    return Obx(() {
      final room = controller.currentRoom;
      if (room == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Code',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  room.roomCode,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
              ],
            ),
            IconButton.filled(
              onPressed: controller.copyRoomCode,
              icon: const Icon(Ionicons.copyOutline),
              tooltip: 'Copy Code',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessagesList(
    BuildContext context,
    MusicRoomController controller,
    RoomChatService chatService,
  ) {
    return Column(
      children: [
        // Chat Header (Quick focus trigger)
        GestureDetector(
          onTap: () => controller.messageFocusNode.requestFocus(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Ionicons.chatbubbles, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Chat Area (Tap to type)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const Spacer(),
                const Icon(Ionicons.chatbubbleEllipses, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
        
        // Messages List
        Expanded(
          child: Obx(() {
            if (chatService.isLoading.value && chatService.messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (chatService.messages.isEmpty) {
              return const Center(
                child: Text(
                  'No messages yet. Start chatting!',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              controller: controller.chatScrollController,
              physics: const AlwaysScrollableScrollPhysics(), // Smooth butter scrolling
              // Base padding to clear the 95px floating input
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100.0, 
              ),
              itemCount: chatService.messages.length,
              itemBuilder: (context, index) {
                final message = chatService.messages[index];
                return _buildMessageBubble(context, message, controller);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    MusicRoomController controller,
  ) {
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
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showParticipantsSheet(BuildContext context, MusicRoomController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Ionicons.people, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 15),
                    Obx(() => Text(
                      'Live Participants (${controller.participants.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Ionicons.closeCircle_outline),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Obx(() {
                  final sortedList = controller.participants.toList()
                    ..sort((a,b) => a.joinedAt.compareTo(b.joinedAt));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final p = sortedList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: p.isHost ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundImage: p.photoUrl != null ? CachedNetworkImageProvider(p.photoUrl!) : null,
                            child: p.photoUrl == null ? Text(p.userName[0].toUpperCase()) : null,
                          ),
                          title: Text(
                            p.userName,
                            style: TextStyle(fontWeight: p.isHost ? FontWeight.bold : FontWeight.w500),
                          ),
                          subtitle: Text(p.isHost ? 'Room Host' : 'Listener', style: const TextStyle(fontSize: 12)),
                          trailing: p.isHost 
                            ? const Icon(Ionicons.ribbon, color: Colors.orange, size: 20)
                            : Text(
                                '${p.joinedAt.hour}:${p.joinedAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaveDialog(BuildContext context, MusicRoomController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(controller.isHost ? 'Close Room?' : 'Leave Room?'),
        content: Text(controller.isHost ? 'This will close the room for all.' : 'Are you sure you want to leave?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (controller.isHost) {
                await controller.closeRoom();
              } else {
                await controller.leaveRoom();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(controller.isHost ? 'Close' : 'Leave'),
          ),
        ],
      ),
    );
  }
}
