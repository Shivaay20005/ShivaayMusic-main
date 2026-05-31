import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/utils/theme_controller.dart';
import '../../../widgets/cust_switch.dart';
import '../settings_screen_controller.dart';
import '../../../widgets/snackbar.dart';

class ContentSettingsPage extends StatelessWidget {
  const ContentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('content'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader(context, "Discovery"),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("setDiscoverContent".tr),
            subtitle: Obx(() => Text(
                settingsController.discoverContentType.value == "QP"
                    ? "quickpicks".tr
                    : settingsController.discoverContentType.value == "TMV"
                        ? "topmusicvideos".tr
                        : settingsController.discoverContentType.value == "TR"
                            ? "trending".tr
                            : "basedOnLast".tr,
                style: Theme.of(context).textTheme.bodyMedium)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const DiscoverContentSelectorDialog(),
            ),
          ),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("homeContentCount".tr),
            subtitle: Text("homeContentCountDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: Obx(
              () => DropdownButton(
                dropdownColor: Theme.of(context).cardColor,
                underline: const SizedBox.shrink(),
                value: settingsController.noOfHomeScreenContent.value,
                items: ([3, 5, 7, 9, 11])
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text("$e")))
                    .toList(),
                onChanged: settingsController.setContentNumber,
              ),
            ),
          ),
          const Divider(),

          _buildSectionHeader(context, "Data & Storage"),
          ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text("cacheHomeScreenData".tr),
              subtitle: Text("cacheHomeScreenDataDes".tr,
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: Obx(
                () => CustSwitch(
                    value: settingsController.cacheHomeScreenData.value,
                    onChanged: settingsController.toggleCacheHomeScreenData),
              )),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("clearImgCache".tr),
            subtitle: Text(
              "clearImgCacheDes".tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.delete_outline),
            onTap: () {
              settingsController.clearImagesCache().then((value) =>
                  ScaffoldMessenger.of(Get.context!).showSnackBar(
                      snackbar(Get.context!, "clearImgCacheAlert".tr,
                          size: SanckBarSize.BIG)));
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

class DiscoverContentSelectorDialog extends StatelessWidget {
  const DiscoverContentSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();
    return AlertDialog(
      title: Text("setDiscoverContent".tr),
      content: SingleChildScrollView(
        child: Column(
          children: [
            RadioListTile(
              title: Text("quickpicks".tr),
              value: "QP",
              // ignore: deprecated_member_use
              groupValue: settingsController.discoverContentType.value,
              // ignore: deprecated_member_use
              onChanged: (val) {
                settingsController.onContentChange(val);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text("topmusicvideos".tr),
              value: "TMV",
              // ignore: deprecated_member_use
              groupValue: settingsController.discoverContentType.value,
              // ignore: deprecated_member_use
              onChanged: (val) {
                settingsController.onContentChange(val);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text("trending".tr),
              value: "TR",
              // ignore: deprecated_member_use
              groupValue: settingsController.discoverContentType.value,
              // ignore: deprecated_member_use
              onChanged: (val) {
                settingsController.onContentChange(val);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text("basedOnLast".tr),
              value: "BOLI",
              // ignore: deprecated_member_use
              groupValue: settingsController.discoverContentType.value,
              // ignore: deprecated_member_use
              onChanged: (val) {
                settingsController.onContentChange(val);
                Navigator.pop(context);
              },
            ),
          ],
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
