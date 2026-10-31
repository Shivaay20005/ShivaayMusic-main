import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/ui/screens/Home/home_screen_controller.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
      if (isKeyboardOpen) return const SizedBox.shrink();

      final surfaceColor = Color.alphaBlend(
        scheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06),
        scheme.surface,
      );

      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.32 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: 'home'.tr,
                      index: 0,
                    ),
                    _buildNavItem(
                      context,
                      icon: (GetPlatform.isAndroid || GetPlatform.isIOS)
                          ? Icons.explore_outlined
                          : Icons.library_music_outlined,
                      selectedIcon: (GetPlatform.isAndroid || GetPlatform.isIOS)
                          ? Icons.explore_rounded
                          : Icons.library_music_rounded,
                      label: (GetPlatform.isAndroid || GetPlatform.isIOS)
                          ? 'explore'.tr
                          : 'library'.tr,
                      index: 2,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings_rounded,
                      label: 'settings'.tr,
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: 'search'.tr,
              child: GestureDetector(
                onTap: () => homeScreenController.onBottonBarTabSelected(1),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: homeScreenController.tabIndex.value == 1
                        ? scheme.secondary
                        : surfaceColor.withValues(alpha: 0.96),
                    border: Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.32 : 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 28,
                    color: homeScreenController.tabIndex.value == 1
                        ? scheme.onSecondary
                        : theme.iconTheme.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final homeScreenController = Get.find<HomeScreenController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSelected = homeScreenController.tabIndex.value == index;
    final displayLabel = modifyNgetlabel(label);

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () => homeScreenController.onBottonBarTabSelected(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.secondary.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(21),
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.0 : 0.96,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? selectedIcon : icon,
                    size: 24,
                    color: isSelected ? scheme.secondary : theme.iconTheme.color?.withValues(alpha: 0.72),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: isSelected ? scheme.secondary : theme.iconTheme.color?.withValues(alpha: 0.72),
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String modifyNgetlabel(String label) {
    if (label.length > 9) {
      return '${label.substring(0, 8)}..';
    }
    return label;
  }
}
