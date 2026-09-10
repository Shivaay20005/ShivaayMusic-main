import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/utils/helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../settings_screen_controller.dart';
import 'admin_alert_page.dart';
import '/services/auth_service.dart';
import '/ui/utils/theme_controller.dart';

class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({super.key});

  @override
  State<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  int _tapCount = 0;
  Timer? _resetTimer;

  void _handleVersionTap(BuildContext context) {
    setState(() {
      _tapCount++;
    });

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _tapCount = 0;
      });
    });

    if (_tapCount >= 10) {
      _tapCount = 0;
      _tapCount = 0;
      _resetTimer?.cancel();
      // Check if user is the admin before showing dialog
      final authService = Get.find<AuthService>(); // Ensure AuthService is available
      if (authService.userEmail.value.toLowerCase() == 'shivaay20005@gmail.com') {
         _showAdminAccessDialog(context);
      } else {
         Get.snackbar("Restricted", "This feature is only for the Administrator.", 
          backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('about'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildAppHeader(context, settingsController),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("Website"),
            subtitle: Text("Visit our official website",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.public, color: Colors.blueAccent),
            onTap: () => launchUrlSafe('https://shivaaymusic.netlify.app/'),
          ),
           ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("GitHub"),
            subtitle: Text("View source code & contribute",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.code, color: Colors.black),
            onTap: () => launchUrlSafe('https://github.com/Shivaay20005/ShivaayMusic'),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("Changelog"),
            subtitle: Text("See what's new in this version",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.history, color: Colors.purple),
            onTap: () => launchUrlSafe('https://github.com/Shivaay20005/ShivaayMusic/blob/main/CHANGELOG.txt'),
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("Check for Updates"),
            subtitle: Text("Current: ${settingsController.currentVersion.value}",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.system_update, color: Colors.green),
            onTap: () => launchUrlSafe(latestReleaseUrl),
          ),
          
          

          const Divider(),
          _buildSectionHeader(context, "Community & Support"),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("joinTg".tr),
            subtitle: Text("joinTgDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.telegram, color: Colors.blue),
            onTap: () => launchUrlSafe('https://t.me/ShivaayMusic'),
          ),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("bugs".tr),
            subtitle: Text("bugsDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.bug_report, color: Colors.redAccent),
            onTap: () => launchUrlSafe('https://github.com/Shivaay20005/ShivaayMusic/issues'),
          ),
          
           ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: const Text("Donate"),
            subtitle: Text("Support the developer",
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.coffee, color: Colors.orange),
            onTap: () => launchUrlSafe('https://www.buymeacoffee.com/shivaay20005'),
          ),
          
          const Divider(),
          _buildSectionHeader(context, "Legal"),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("privacyPolicy".tr),
            subtitle: Text("privacyPolicyDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.policy),
            onTap: () => launchUrlSafe('https://shivaaymusic.netlify.app/privacy.html'),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("termsAndCondition".tr),
            subtitle: Text("termsAndConditionDes".tr,
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.description),
            onTap: () => launchUrlSafe('https://shivaaymusic.netlify.app/terms.html'),
          ),
          
          const SizedBox(height: 20),
          Center(
            child: Text(
              "Made with ❤️ by Shivaay ",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppHeader(BuildContext context, SettingsScreenController controller) {
    return Column(
      children: [
        Image.asset(
          'assets/icons/icon.png',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 16),
        Text(
          'ShivaayMusic',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _handleVersionTap(context),
          child: Obx(() => Text(
            controller.currentVersion.value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final settingsController = Get.find<SettingsScreenController>();
    final isDynamic = settingsController.themeModetype.value == ThemeType.dynamic;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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

  void _showAdminAccessDialog(BuildContext context) {


    final passController = TextEditingController();
    Get.defaultDialog(
      title: "Admin Access",
      content: TextField(
        controller: passController,
        obscureText: true,
        decoration: const InputDecoration(labelText: "Password"),
      ),
      textConfirm: "Verify",
      onConfirm: () async {
        Get.back(); // Close input dialog
        
        // Show loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()), 
          barrierDismissible: false
        );

        try {
          // Fetch password from Cloud (settings/admin)
          final doc = await FirebaseFirestore.instance
              .collection('settings')
              .doc('admin')
              .get();

          Get.back(); // Close loading

          if (!doc.exists) {
            // Fallback: If doc doesn't exist but email matches, allow access (Emergency/First run)
             Get.to(() => const AdminAlertPage());
            return;
          }

          final String? cloudPass = doc.data()?['password'];

          if (cloudPass != null && passController.text == cloudPass) {
             Get.to(() => const AdminAlertPage());
          } else {
             Get.snackbar("Access Denied", "Incorrect Password", backgroundColor: Colors.red, colorText: Colors.white);
          }
        } catch (e) {
          if (Get.isDialogOpen ?? false) Get.back();
          

          // FAILSAFE: If permission is denied/insufficient BUT email matches the hardcoded admin email, allow access.
          // This allows the admin to access the panel even if Firestore rules are broken/restrictive.
          Get.snackbar("Error", "Verification Failed: $e");
        }
      },
      onCancel: () {},
    );
  }
}
