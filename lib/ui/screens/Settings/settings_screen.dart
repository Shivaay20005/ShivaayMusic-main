import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'settings_screen_controller.dart';
import 'pages/personalisation_settings.dart';
import 'pages/content_settings.dart';
import 'pages/music_playback_settings.dart';
import 'pages/download_settings.dart';
import 'pages/backup_restore_settings.dart';
import 'pages/privacy_settings.dart';
import 'pages/about_settings.dart';
import 'pages/profile_settings.dart';
import 'package:shivaaymusic/ui/navigator.dart';
import 'package:shivaaymusic/utils/helper.dart';
import 'package:shivaaymusic/services/music_room_service.dart';
import '/services/privacy_service.dart';
// import '../Stats/stats_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.isBottomNavActive = false});
  final bool isBottomNavActive;

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();
    final privacyService = Get.find<PrivacyService>();
    // On Android/iOS, the parent scaffold already shows the custom AppHeaderBar.
    final topPadding = (GetPlatform.isAndroid || GetPlatform.isIOS) 
        ? 15.0 
        : (context.isLandscape ? 30.0 : 25.0);
        
    return Scaffold(
      body: Padding(
        padding: isBottomNavActive
            ? EdgeInsets.only(left: 20, top: topPadding, right: 15)
            : EdgeInsets.only(top: topPadding, left: 15, right: 15),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Obx(() {
                final isIncognito = privacyService.isIncognitoMode.value;
                final colorScheme = Theme.of(context).colorScheme;
                final badgeBg = Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: 0.18),
                  colorScheme.surface,
                );
                final badgeFg = ThemeData.estimateBrightnessForColor(badgeBg) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "settings".tr,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isIncognito) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: badgeFg.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_off_rounded,
                              color: badgeFg,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '🕵🏻‍♂️',
                              style: TextStyle(
                                color: badgeFg,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 250),
                children: [
                  // Update Banner
                  Obx(
                    () => settingsController.isNewVersionAvailable.value
                        ? _buildUpdateBanner(context)
                        : const SizedBox.shrink(),
                  ),
                  
                  // Create Music Room Tile (NEW - at the top)
                  _buildSettingsTile(
                    context,
                    title: "Create Music Room",
                    icon: Icons.people,
                    onTap: () {
                      // Navigate to Music Room (Active) or Lobby
                      final roomService = Get.find<MusicRoomService>();
                      if (roomService.isInRoom.value) {
                        Get.toNamed(ScreenNavigationSetup.musicRoom, id: ScreenNavigationSetup.id);
                      } else {
                        Get.toNamed(ScreenNavigationSetup.musicRoomLobby, id: ScreenNavigationSetup.id);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  
                  // Profile Tile
                  _buildSettingsTile(
                    context,
                    title: "Profile", // Translatable if needed
                    icon: Icons.person,
                    onTap: () => Get.to(() => const ProfileSettingsPage()),
                  ),
                  const SizedBox(height: 10),

                  // Listening Stats Tile
                  /*
                  _buildSettingsTile(
                    context,
                    title: "listeningStats".tr,
                    icon: Icons.bar_chart_rounded,
                    onTap: () => Get.to(() => const StatsScreen()),
                  ),
                  const SizedBox(height: 10),
                  */

                  // Appearance Tile
                  _buildSettingsTile(
                    context,
                    title: "personalisation".tr, // "Appearance" or mapped
                    icon: Icons.palette,
                    onTap: () => Get.to(() => const PersonalisationSettingsPage()),
                  ),
                  const SizedBox(height: 10),

                  // Content Tile
                  _buildSettingsTile(
                    context,
                    title: "content".tr,
                    icon: Icons.library_music,
                    onTap: () => Get.to(() => const ContentSettingsPage()),
                  ),
                  const SizedBox(height: 10),

                  // Player and Audio Tile
                  _buildSettingsTile(
                    context,
                    title: "music&Playback".tr, // "Player and Audio"
                    icon: Icons.music_note,
                    onTap: () => Get.to(() => const MusicPlaybackSettingsPage()),
                  ),
                  const SizedBox(height: 10),

                  // Download Tile
                  _buildSettingsTile(
                    context,
                    title: "download".tr,
                    icon: Icons.download,
                    onTap: () => Get.to(() => const DownloadSettingsPage()),
                  ),
                  const SizedBox(height: 10),

                  // Backup & Restore Tile
                  _buildSettingsTile(
                    context,
                    title: "${"backup".tr} & ${"restore".tr}",
                    icon: Icons.history, // Or restore icon
                    onTap: () => Get.to(() => const BackupRestoreSettingsPage()),
                  ),
                  const SizedBox(height: 10),

                  // Privacy & Security Tile
                  _buildSettingsTile(
                    context,
                    title: "Privacy & Security",
                    icon: Icons.security,
                    onTap: () => Get.to(() => const PrivacySettingsPage()),
                  ),
                  const SizedBox(height: 10),

                  // About Tile
                  _buildSettingsTile(
                    context,
                    title: "about".tr,
                    icon: Icons.info,
                    onTap: () => Get.to(() => const AboutSettingsPage()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsTile(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    // Custom Tile Style to match user request (Dark Card, Bold Text)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine background color based on theme
    // User image shows a distinct dark card color on a dark background.
    final tileColor = isDark 
        ? Colors.grey[900]?.withValues(alpha: 0.6) // Dark mode card
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3); // Light mode card
        
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                // Icon color: White in dark mode (high contrast), Dark Grey in light mode
                color: isDark ? Colors.white70 : Colors.grey[850],
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900, // Extra Bold
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded, // Chevron right ^
                color: Theme.of(context).disabledColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => launchUrlSafe('https://github.com/shivaay20005/ShivaayMusic-Windows-release/releases/latest'),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.system_update, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Tap to download the latest version',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
