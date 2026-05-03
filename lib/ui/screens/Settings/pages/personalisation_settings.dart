import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/utils/lang_mapping.dart';
import '../../../widgets/cust_switch.dart';
import '../settings_screen_controller.dart';
import '/ui/utils/theme_controller.dart';
import '../../../widgets/shortcuts_dialog.dart';

class PersonalisationSettingsPage extends StatelessWidget {
  const PersonalisationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();
    final isDesktop = GetPlatform.isDesktop;

    return Scaffold(
      appBar: AppBar(
        title: Text('personalisation'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Theme Section
          _buildSectionHeader(context, "Theme & Appearance"),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("themeMode".tr),
            subtitle: Obx(
              () => Text(
                  settingsController.themeModetype.value == ThemeType.dynamic
                      ? "dynamic".tr
                      : settingsController.themeModetype.value == ThemeType.system
                          ? "systemDefault".tr
                          : settingsController.themeModetype.value == ThemeType.dark
                              ? "dark".tr
                              : settingsController.themeModetype.value == ThemeType.automatic
                                  ? "Automatic (Time based)"
                                  : "light".tr,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const ThemeSelectorDialog(),
            ),
          ),
          const Divider(),

          // Language Section
          _buildSectionHeader(context, "Language"),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("language".tr),
            subtitle: Text("languageDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => DropdownButton(
                menuMaxHeight: Get.height - 250,
                dropdownColor: Theme.of(context).cardColor,
                underline: const SizedBox.shrink(),
                style: Theme.of(context).textTheme.titleSmall,
                value: settingsController.currentAppLanguageCode.value,
                items: langMap.entries
                    .map((lang) => DropdownMenuItem(
                          value: lang.key,
                          child: Text(lang.value),
                        ))
                    .whereType<DropdownMenuItem<String>>()
                    .toList(),
                onChanged: settingsController.setAppLanguage,
              ),
            ),
          ),
          const Divider(),

          // UI Preferences
          _buildSectionHeader(context, "UI Preferences"),
          if (!isDesktop)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("playerUi".tr),
              subtitle: Text("playerUiDes".tr,
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: Obx(
                () => DropdownButton(
                  dropdownColor: Theme.of(context).cardColor,
                  underline: const SizedBox.shrink(),
                  value: settingsController.playerUi.value,
                  items: [
                    DropdownMenuItem(value: 0, child: Text("standard".tr)),
                    DropdownMenuItem(value: 1, child: Text("gesture".tr)),
                  ],
                  onChanged: settingsController.setPlayerUi,
                ),
              ),
            ),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("disableTransitionAnimation".tr),
            subtitle: Text("disableTransitionAnimationDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => CustSwitch(
                value: settingsController.isTransitionAnimationDisabled.isTrue,
                onChanged: settingsController.disableTransitionAnimation,
              ),
            ),
          ),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("enableSlidableAction".tr),
            subtitle: Text("enableSlidableActionDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => CustSwitch(
                value: settingsController.slidableActionEnabled.isTrue,
                onChanged: settingsController.toggleSlidableAction,
              ),
            ),
          ),

          if (isDesktop) ...[
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: const Icon(Icons.keyboard),
              title: const Text("Keyboard Shortcuts"),
              subtitle: Text(
                "View available hotkeys",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const ShortcutsDialog(),
                );
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

// Dialog needs to be accessible here or imported
class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-use logic from original file or keep it there if exported.
    // For simplicity assuming it's refactored or reused.
    // Ideally this should be a separate widget file if multiple files use it.
    // I will assume it's available or re-implement simple version.
    final settingsController = Get.find<SettingsScreenController>();
    return AlertDialog(
      title: Text("themeMode".tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeType.values.map((e) {
            String title = "";
            switch (e) {
              case ThemeType.system:
                title = "systemDefault".tr;
                break;
              case ThemeType.dark:
                title = "dark".tr;
                break;
              case ThemeType.light:
                title = "light".tr;
                break;
              case ThemeType.dynamic:
                title = "dynamic".tr;
                break;
              case ThemeType.automatic:
                title = "Automatic";
                break;
            }
            return RadioListTile(
              title: Text(title),
              value: e,
              // ignore: deprecated_member_use
              groupValue: settingsController.themeModetype.value,
              // ignore: deprecated_member_use
              onChanged: (val) {
                settingsController.onThemeChange(val);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("cancel".tr),
        ),
      ],
    );
  }
}
