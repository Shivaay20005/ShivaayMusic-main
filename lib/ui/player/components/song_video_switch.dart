import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/ui/utils/theme_controller.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../player_controller.dart';

class SongVideoSwitch extends StatelessWidget {
  const SongVideoSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: ToggleSwitch(
          minWidth: 90.0,
          cornerRadius: 20.0,
          activeBgColors: [
            [Theme.of(context).primaryColor.withLightness(0.4)],
            [Theme.of(context).primaryColor.withLightness(0.4)]
          ],
          activeFgColor: Colors.white,
          inactiveBgColor: Theme.of(context).colorScheme.secondary,
          inactiveFgColor: Colors.white,
          initialLabelIndex: playerController.isVideoMode.value ? 1 : 0,
          totalSwitches: 2,
          labels: ['Song'.tr, 'Video'.tr],
          radiusStyle: true,
          onToggle: (index) {
            if ((index == 1 && !playerController.isVideoMode.value) || 
                (index == 0 && playerController.isVideoMode.value)) {
              playerController.toggleVideoMode();
            }
          },
        ),
      ),
    );
  }
}
