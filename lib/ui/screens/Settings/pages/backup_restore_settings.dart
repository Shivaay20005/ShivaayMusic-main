import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/utils/theme_controller.dart';
import '../../../widgets/backup_dialog.dart';
import '../../../widgets/restore_dialog.dart';
import '../../../widgets/snackbar.dart';
import '../settings_screen_controller.dart';

class BackupRestoreSettingsPage extends StatelessWidget {
  const BackupRestoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();

    return Scaffold(
      appBar: AppBar(
        title: Text("${"backup".tr} & ${"restore".tr}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 20),
          _buildSectionHeader(context, "Data Management"),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("backup".tr),
            subtitle: Text("backupDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.cloud_upload_outlined),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const BackupDialog(),
            ),
          ),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("restore".tr),
            subtitle: Text("restoreDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.cloud_download_outlined),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const RestoreDialog(),
            ),
          ),
          
          const Divider(),
          _buildSectionHeader(context, "Reset"),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("Reset App Settings", style: TextStyle(color: Colors.red)),
            subtitle: Text("Resets all settings to default.",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Reset App Settings"),
                  content: const Text("Reset the App Settings Completely?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("No")),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          settingsController.resetAppSettingsToDefault();
                          ScaffoldMessenger.of(context).showSnackBar(snackbar(
                              context, "App settings reset successfully",
                              size: SanckBarSize.MEDIUM));
                        },
                        child: const Text("Yes",
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
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
  
  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            const Text(
              "Keep your data safe by backing up regularly. You can restore your playlists and settings on any device.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
