import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/ui/screens/Home/home_screen_controller.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    return Obx(() {
      final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
      if (isKeyboardOpen) return const SizedBox.shrink();
      
      return Container(
        margin: EdgeInsets.only(
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
        ),
        child: Row(
          children: [
            // Pill-shaped menu
            Expanded(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'home'.tr,
                      index: 0,
                    ),
                    _buildNavItem(
                      context,
                      icon: (GetPlatform.isAndroid || GetPlatform.isIOS)
                          ? Icons.explore_outlined
                          : Icons.library_music,
                      selectedIcon: (GetPlatform.isAndroid || GetPlatform.isIOS)
                          ? Icons.explore
                          : null,
                      label: (GetPlatform.isAndroid || GetPlatform.isIOS)
                          ? "explore".tr
                          : 'library'.tr,
                      index: 2,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'settings'.tr,
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Circular Search button
            GestureDetector(
              onTap: () => homeScreenController.onBottonBarTabSelected(1),
              child: Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: homeScreenController.tabIndex.value == 1
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Icon(
                  Icons.search,
                  size: 28,
                  color: homeScreenController.tabIndex.value == 1
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).iconTheme.color,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNavItem(BuildContext context,
      {required IconData icon,
      IconData? selectedIcon,
      required String label,
      required int index}) {
    final homeScreenController = Get.find<HomeScreenController>();
    final isSelected = homeScreenController.tabIndex.value == index;
    final displayLabel = modifyNgetlabel(label);

    return GestureDetector(
      onTap: () => homeScreenController.onBottonBarTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (selectedIcon ?? icon) : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(height: 4),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).iconTheme.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String modifyNgetlabel(String label) {
    if (label.length > 9) {
      return "${label.substring(0, 8)}..";
    }
    return label;
  }
}
