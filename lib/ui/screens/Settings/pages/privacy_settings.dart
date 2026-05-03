import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../settings_screen_controller.dart';
import '../../../../services/privacy_service.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsScreenController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy & Security", style: Theme.of(context).textTheme.titleMedium),
        centerTitle: true,
      ),
      body: Obx(() {
        final privacyService = Get.isRegistered<PrivacyService>() ? Get.find<PrivacyService>() : null;
        if (privacyService == null) {
          return const Center(child: Text("Privacy Service not available"));
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // App Lock
            ListTile(
              title: const Text("App Lock", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Require authentication to open the app"),
              trailing: Switch(
                value: privacyService.isAppLockEnabled.value,
                onChanged: (val) => controller.toggleAppLock(val),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(),

            // Incognito Mode
            ListTile(
              title: const Text("Incognito Mode", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Don't save listening history"),
              trailing: Switch(
                value: privacyService.isIncognitoMode.value,
                onChanged: (val) => controller.toggleIncognitoMode(val),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(),

            // Data Management
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Text(
                "Data Management",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            ListTile(
              title: const Text("Clear Listening History"),
              leading: const Icon(Icons.history),
              onTap: () => _confirmAction(context, controller.clearListeningHistory),
            ),
            
            ListTile(
              title: const Text("Clear Search & Play History"),
              leading: const Icon(Icons.delete_outline),
              onTap: () => _confirmAction(context, controller.clearAllHistory),
            ),
          ],
        );
      }),
    );
  }

  void _confirmAction(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
