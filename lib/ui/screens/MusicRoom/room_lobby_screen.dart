import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';

import 'music_room_controller.dart';

class RoomLobbyScreen extends StatelessWidget {
  const RoomLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicRoomController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Room'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Ionicons.musicalNotes,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Listen Together',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                'Create or join a room to listen to music\nwith friends in real-time',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),
              
              // Create Room Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateRoomDialog(context, controller),
                  icon: const Icon(Ionicons.addCircleOutline),
                  label: const Text('Create Room'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Join Room Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _showJoinRoomDialog(context, controller),
                  icon: const Icon(Ionicons.enterOutline),
                  label: const Text('Join Room'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context, MusicRoomController controller) {
    int selectedMaxParticipants = 10;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Music Room'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Maximum Participants'),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 5, label: Text('5')),
                    ButtonSegment(value: 10, label: Text('10')),
                    ButtonSegment(value: 20, label: Text('20')),
                  ],
                  selected: {selectedMaxParticipants},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      selectedMaxParticipants = newSelection.first;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isCreatingRoom.value
                    ? null
                    : () {
                        controller.createRoom(
                          maxParticipants: selectedMaxParticipants,
                        );
                      },
                child: controller.isCreatingRoom.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              )),
        ],
      ),
    );
  }

  void _showJoinRoomDialog(BuildContext context, MusicRoomController controller) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Music Room'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Room Code',
            hintText: 'Enter 6-digit room code',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isJoiningRoom.value
                    ? null
                    : () {
                        controller.joinRoom(codeController.text);
                      },
                child: controller.isJoiningRoom.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join'),
              )),
        ],
      ),
    ).then((_) => codeController.dispose());
  }
}
