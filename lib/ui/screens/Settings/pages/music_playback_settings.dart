import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/utils/theme_controller.dart';
import 'package:shivaaymusic/utils/helper.dart';
import 'package:shivaaymusic/services/music_service.dart';
import '../../../widgets/cust_switch.dart';
import '../settings_screen_controller.dart';
import '/ui/player/player_controller.dart';

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
                title: Text("skipSilence".tr),
                subtitle: Text("skipSilenceDes".tr,
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: Obx(
                  () => CustSwitch(
                      value: settingsController.skipSilenceEnabled.value,
                      onChanged: settingsController.toggleSkipSilence),
                )),
          ],

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
