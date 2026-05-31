import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import '/services/auth_service.dart';
import '/services/privacy_service.dart';
import '../settings_screen_controller.dart';
import '/ui/widgets/snackbar.dart';
import '../../Auth/login_screen.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final privacyService = Get.find<PrivacyService>();
    final settingsController = Get.find<SettingsScreenController>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Avatar
                    // Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: authService.userPhoto.value.isNotEmpty
                          ? NetworkImage(authService.userPhoto.value)
                          : null,
                      child: authService.userPhoto.value.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  authService.userName.value.isNotEmpty
                                      ? authService.userName.value
                                      : 'User',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            authService.userName.value.isNotEmpty
                                ? authService.userName.value
                                : 'User',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (authService.isVerified.value)
                          const Padding(
                            padding: EdgeInsets.only(left: 6.0),
                            child: Icon(Icons.verified, color: Colors.blue, size: 22),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditNameDialog(context, authService),
                          tooltip: "Edit Name",
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Text(
                      authService.userEmail.value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Incognito Mode
            Obx(() {
              final isIncognito = privacyService.isIncognitoMode.value;
              final activeSurface = Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.35),
                colorScheme.surface,
              );
              final activeOnColor = ThemeData.estimateBrightnessForColor(activeSurface) ==
                      Brightness.dark
                  ? Colors.white
                  : Colors.black;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: isIncognito
                      ? LinearGradient(
                          colors: [
                            Color.alphaBlend(
                              colorScheme.primary.withValues(alpha: 0.75),
                              colorScheme.surface,
                            ),
                            Color.alphaBlend(
                              colorScheme.secondary.withValues(alpha: 0.45),
                              colorScheme.surface,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isIncognito ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isIncognito
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isIncognito ? Icons.visibility_off : Icons.visibility,
                      key: ValueKey(isIncognito),
                      color: isIncognito
                          ? activeOnColor
                          : colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    'Incognito Mode',
                    style: TextStyle(
                      color: isIncognito ? activeOnColor : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isIncognito
                        ? 'Active: history will not be saved'
                        : 'Hide your listening activity from history',
                    style: TextStyle(
                      color: isIncognito
                          ? activeOnColor.withValues(alpha: 0.78)
                          : null,
                    ),
                  ),
                  trailing: Switch(
                    value: isIncognito,
                    onChanged: settingsController.toggleIncognitoMode,
                    activeThumbColor: colorScheme.primary,
                    activeTrackColor:
                        colorScheme.primaryContainer.withValues(alpha: 0.85),
                  ),
                ),
              );
            }),

            
            // Logout Button
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).cardColor,
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Stop music before logging out
                          try {
                            if (Get.isRegistered<AudioHandler>()) {
                              await Get.find<AudioHandler>().stop();
                            }
                          } catch (e) {
                            debugPrint("Error stopping music: $e");
                          }
                          await authService.signOut();
                          showCustomSnackbar(
                            title: "Logged Out",
                            message: "You have been logged out successfully",
                          );
                          Get.offAll(() => const LoginScreen());
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  void _showEditNameDialog(BuildContext context, AuthService authService) {
    final TextEditingController nameController = TextEditingController(text: authService.userName.value);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Display Name",
            hintText: "Enter your name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final result = await authService.updateUserName(nameController.text.trim());
                if (context.mounted) Navigator.pop(context);
                if (result['success']) {
                  showCustomSnackbar(
                    title: "Success",
                    message: result['message'],
                  );
                } else {
                  showCustomSnackbar(
                    title: "Error",
                    message: result['message'],
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
