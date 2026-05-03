import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/utils/theme_controller.dart';
import '../../../widgets/cust_switch.dart';
import '../settings_screen_controller.dart';
import '../../../widgets/export_file_dialog.dart';
import '../../Home/home_screen_controller.dart';
import '../../Library/library_combined.dart';

class DownloadSettingsPage extends StatelessWidget {
  const DownloadSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('download'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader(context, "Preferences"),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("autoDownFavSong".tr),
            subtitle: Text("autoDownFavSongDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => CustSwitch(
                  value: settingsController.autoDownloadFavoriteSongEnabled.value,
                  onChanged: settingsController.toggleAutoDownloadFavoriteSong),
            ),
          ),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("downloadingFormat".tr),
            subtitle: Text("downloadingFormatDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => DropdownButton(
                dropdownColor: Theme.of(context).cardColor,
                underline: const SizedBox.shrink(),
                value: settingsController.downloadingFormat.value,
                items: const [
                  DropdownMenuItem(value: "opus", child: Text("Opus/Ogg")),
                  DropdownMenuItem(
                    value: "m4a",
                    child: Text("M4a"),
                  ),
                ],
                onChanged: settingsController.changeDownloadingFormat,
              ),
            ),
          ),
          
          // View Downloads - Android only
          if (GetPlatform.isAndroid)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("viewDownloads".tr),
              subtitle: Text(
                "viewDownloadsDes".tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final homeScreenController = Get.find<HomeScreenController>();
                if (settingsController.isBottomNavBarEnabled.isTrue) {
                  homeScreenController.onBottonBarTabSelected(2);
                  // Switch to Songs tab (index 1) in CombinedLibrary
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (Get.isRegistered<CombinedLibraryController>()) {
                      Get.find<CombinedLibraryController>().tabController.animateTo(1);
                    }
                  });
                } else {
                  homeScreenController.onSideBarTabSelected(1);
                }
                // Navigate back to home/library screen
                Get.until((route) =>
                    Get.currentRoute == '/homeScreen' || Get.currentRoute == '/');
              },
            ),
          
          const Divider(),

          _buildSectionHeader(context, "Storage Location"),
          ListTile(
            trailing: TextButton(
              child: Text(
                "reset".tr,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontSize: 15),
              ),
              onPressed: () {
                settingsController.resetDownloadLocation();
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("downloadLocation".tr),
            subtitle: Obx(() => Text(
                settingsController.isCurrentPathsupportDownDir
                    ? "In App storage directory"
                    : settingsController.downloadLocationPath.value,
                style: Theme.of(context).textTheme.bodyMedium)),
            onTap: () async {
              settingsController.setDownloadLocation();
            },
          ),
          
          if (GetPlatform.isAndroid) ...[
             const Divider(),
             _buildSectionHeader(context, "Export"),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("exportDowloadedFiles".tr),
              subtitle: Text(
                "exportDowloadedFilesDes".tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.import_export),
              onTap: () => showDialog(
                context: context,
                builder: (context) => const ExportFileDialog(),
              ).whenComplete(() => Get.delete<ExportFileDialogController>()),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("exportedFileLocation".tr),
              subtitle: Obx(() => Text(
                  settingsController.exportLocationPath.value,
                  style: Theme.of(context).textTheme.bodyMedium)),
              trailing: const Icon(Icons.folder_open),
              onTap: () async {
                settingsController.setExportedLocation();
              },
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
