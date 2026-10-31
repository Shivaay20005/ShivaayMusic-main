import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/utils/theme_controller.dart';
import 'package:shivaaymusic/utils/helper.dart';
import 'package:shivaaymusic/services/music_service.dart';
import 'package:shivaaymusic/services/app_logs.dart';
import '../../../widgets/cust_switch.dart';
import '../settings_screen_controller.dart';
import '/ui/player/player_controller.dart';
import 'package:shivaaymusic/services/audio_booster_controller.dart';

class MusicPlaybackSettingsPage extends StatelessWidget {
  const MusicPlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();
    final isDesktop = GetPlatform.isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: Text('music&Playback'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader(context, "Audio Quality"),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("streamingQuality".tr),
            subtitle: Text("streamingQualityDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => DropdownButton(
                dropdownColor: Theme.of(context).cardColor,
                underline: const SizedBox.shrink(),
                value: settingsController.streamingQuality.value,
                items: [
                  DropdownMenuItem(value: AudioQuality.Low, child: Text("low".tr)),
                  DropdownMenuItem(
                    value: AudioQuality.High,
                    child: Text("high".tr),
                  ),
                ],
                onChanged: settingsController.setStreamingQuality,
              ),
            ),
          ),
          
          if (GetPlatform.isAndroid)
            ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text("loudnessNormalization".tr),
                subtitle: Text("loudnessNormalizationDes".tr,
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: Obx(
                  () => CustSwitch(
                      value: settingsController.loudnessNormalizationEnabled.value,
                      onChanged: settingsController.toggleLoudnessNormalization),
                )),

          if (!isDesktop) ...[
             const Divider(),
             _buildSectionHeader(context, "Playback Optimization"),
            ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text("cacheSongs".tr),
                subtitle: Text("cacheSongsDes".tr,
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: Obx(
                  () => CustSwitch(
                      value: settingsController.cacheSongs.value,
                      onChanged: settingsController.toggleCachingSongsValue),
                )),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text("Clear Cache"),
              subtitle: Obx(() => Text("Used Space: ${settingsController.cacheSize.value}",
                  style: Theme.of(context).textTheme.bodyMedium)),
              trailing: const Icon(Icons.delete_outline),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Clear Cache"),
                    content: const Text("This will delete all cached song data to free up space. Downloads will NOT be affected."),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          settingsController.clearCache();
                          Get.back();
                        },
                        child: const Text("Clear", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text("skipSilence".tr),
                subtitle: Text("skipSilenceDes".tr,
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: Obx(
                  () => CustSwitch(
                      value: settingsController.skipSilenceEnabled.value,
                      onChanged: settingsController.toggleSkipSilence),
                )),
            ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Text("Smart Pre-fetch"),
                subtitle: Text("Automatically buffers the next 1-2 songs for gapless playback in weak network areas.",
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: Obx(
                  () => CustSwitch(
                      value: settingsController.isSmartPrefetchEnabled.value,
                      onChanged: settingsController.toggleSmartPrefetch),
                )),
          ],

          const Divider(),
          _buildSectionHeader(context, "Audio Booster"),
          Obx(() {
            final booster = Get.find<AudioBoosterController>();
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: const Text("Enable Booster"),
                  subtitle: Text("Unleash the full power of your speakers. Use with caution!",
                      style: Theme.of(context).textTheme.bodyMedium),
                  trailing: CustSwitch(
                    value: booster.isBoosterEnabled.value,
                    onChanged: booster.toggleBooster,
                  ),
                ),
                if (booster.isBoosterEnabled.value) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Bass Boost"),
                            Text("${(booster.bassBoostLevel.value / 10).toStringAsFixed(0)}%"),
                          ],
                        ),
                        Slider(
                          value: booster.bassBoostLevel.value,
                          min: 0,
                          max: 1000,
                          activeColor: Colors.blueAccent,
                          onChanged: booster.setBassBoost,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Virtualizer (Surround)"),
                            Text("${(booster.virtualizerLevel.value / 10).toStringAsFixed(0)}%"),
                          ],
                        ),
                        Slider(
                          value: booster.virtualizerLevel.value,
                          min: 0,
                          max: 1000,
                          activeColor: Colors.deepPurpleAccent,
                          onChanged: booster.setVirtualizer,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Extra Gain (Loudness)"),
                            Text("${(100 + (booster.loudnessGain.value / 2)).toStringAsFixed(0)}%"),
                          ],
                        ),
                        Slider(
                          value: booster.loudnessGain.value,
                          min: 0,
                          max: 400,
                          activeColor: Colors.redAccent,
                          onChanged: booster.setLoudnessGain,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Pitch Control"),
                            Text("${booster.pitch.value.toStringAsFixed(2)}x"),
                          ],
                        ),
                        Slider(
                          value: booster.pitch.value,
                          min: 0.5,
                          max: 2.0,
                          activeColor: Colors.tealAccent,
                          onChanged: booster.setPitch,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              booster.resetToDefault();
                            },
                            icon: const Icon(Icons.restore),
                            label: const Text("Reset to Default"),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),

          const Divider(),
          _buildSectionHeader(context, "Player Behavior"),
          if (isDesktop)
            ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text("backgroundPlay".tr),
                subtitle: Text("backgroundPlayDes".tr,
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: Obx(
                  () => CustSwitch(
                      value: settingsController.backgroundPlayEnabled.value,
                      onChanged: settingsController.toggleBackgroundPlay),
                )),
                
          ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("keepScreenOnWhilePlaying".tr),
              subtitle: Text("keepScreenOnWhilePlayingDes".tr,
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: Obx(
                () => CustSwitch(
                    value: settingsController.keepScreenAwake.value,
                    onChanged: settingsController.toggleKeepScreenAwake),
              )),
          
          ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("restoreLastPlaybackSession".tr),
              subtitle: Text("restoreLastPlaybackSessionDes".tr,
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: Obx(
                () => CustSwitch(
                    value: settingsController.restorePlaybackSession.value,
                    onChanged: settingsController.toggleRestorePlaybackSession),
              )),
          ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text("Show video option in player"),
              subtitle: const Text(
                "Keep this off for audio-only playback. Turn it on to show the Song/Video switch.",
              ),
              trailing: Obx(
                () => CustSwitch(
                  value: settingsController.showVideoOption.value,
                  onChanged: settingsController.toggleShowVideoOption,
                ),
              )),

          ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("stopMusicOnTaskClear".tr),
              subtitle: Text("stopMusicOnTaskClearDes".tr,
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: Obx(
                () => CustSwitch(
                    value: settingsController.stopPlyabackOnSwipeAway.value, // Note: Variable has typo 'Plyaback' in controller
                    onChanged: settingsController.toggleStopPlyabackOnSwipeAway),
              )),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("autoOpenPlayer".tr),
            subtitle: Text("autoOpenPlayerDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => CustSwitch(
                  value: settingsController.autoOpenPlayer.value,
                  onChanged: settingsController.toggleAutoOpenPlayer),
            ),
          ),
          
          if (!isDesktop)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("equalizer".tr),
              subtitle: Text("equalizerDes".tr,
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: const Icon(Icons.graphic_eq),
              onTap: () async {
                try {
                  await Get.find<PlayerController>().openEqualizer();
                } catch (e) {
                  printERROR(e);
                }
              },
            ),

          if (GetPlatform.isAndroid) ...[
             const Divider(),
             _buildSectionHeader(context, "System Integration"),
            Obx(
              () => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text("ignoreBatOpt".tr),
                onTap: settingsController.isIgnoringBatteryOptimizations.isFalse
                    ? settingsController.enableIgnoringBatteryOptimizations
                    : null,
                subtitle: RichText(
                  text: TextSpan(
                    text:
                        "${"status".tr}: ${settingsController.isIgnoringBatteryOptimizations.isTrue ? "enabled".tr : "disabled".tr}\n",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                          text: "Allow this for error-free music streaming. This ensures the app keeps running and doesn't crash even if 10-15 apps are open in the background.",
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                trailing: settingsController.isIgnoringBatteryOptimizations.isTrue
                           ? const Icon(Icons.check_circle, color: Colors.green)
                           : const Icon(Icons.warning, color: Colors.orange),
              ),
            ),
          ],

          // Diagnostics: the only way to see what playback actually did.
          // Android hides this app's logcat from every other app, and the
          // print* helpers are compiled out of release builds, so the log file
          // is what a bug report can be built from.
          const Divider(),
          _buildSectionHeader(context, "Diagnostics"),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("Share logs"),
            subtitle: Text(
                "Attaches app_logs.txt (playback, extraction and network "
                "decisions) to any app — Telegram, email, Drive.",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.share_outlined),
            onTap: () async {
              final shared = await AppLogs.share();
              Get.snackbar(
                "Logs",
                shared
                    ? "Log file attached — pick where to send it."
                    : "No log file yet. Play a song first, then try again.",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("Clear logs"),
            subtitle: Text("Deletes the current log file.",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.delete_outline),
            onTap: () async {
              await AppLogs.clear();
              Get.snackbar(
                "Logs",
                "Log file cleared.",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final settingsController = Get.find<SettingsScreenController>();
    final isDynamic = settingsController.themeModetype.value == ThemeType.dynamic;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDynamic 
                  ? Colors.white 
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.blueAccent 
                      : Colors.black87),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
