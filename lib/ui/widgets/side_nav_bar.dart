import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shivaaymusic/ui/screens/Home/home_screen_controller.dart';
import 'custom_sidebar.dart';

class SideNavBar extends StatelessWidget {
  const SideNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileOrTabScreen = size.width < 480;
    final homeScreenController = Get.find<HomeScreenController>();
    return Align(
      alignment: Alignment.topCenter,
      child: isMobileOrTabScreen
          ? SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: IntrinsicHeight(
                child: Obx(
                  () => NavigationRail(
                    useIndicator: !isMobileOrTabScreen,
                    selectedIndex:
                        homeScreenController.tabIndex.value, //_selectedIndex,
                    onDestinationSelected:
                        homeScreenController.onSideBarTabSelected,
                    minWidth: 60,
                    leading: SizedBox(height: size.height < 750 ? 30 : 60),
                    minExtendedWidth: 250,
                    extended: !isMobileOrTabScreen,
                    labelType: isMobileOrTabScreen
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.none,
                    //backgroundColor: Colors.green,
                    destinations: <NavigationRailDestination>[
                      railDestination(
                          "home".tr, isMobileOrTabScreen, Icons.home),
                      railDestination(
                          "songs".tr, isMobileOrTabScreen, Icons.art_track),
                      railDestination(
                          (GetPlatform.isAndroid || GetPlatform.isIOS) ? "explore".tr : "playlists".tr, 
                          isMobileOrTabScreen,
                          (GetPlatform.isAndroid || GetPlatform.isIOS) ? Icons.explore : Icons.featured_play_list),
                      railDestination(
                          "albums".tr, isMobileOrTabScreen, Icons.album),
                      railDestination(
                          "artists".tr, isMobileOrTabScreen, Icons.people),
                      //railDestination("Settings")
                      const NavigationRailDestination(
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        icon: Icon(Icons.settings),
                        label: SizedBox.shrink(),
                        selectedIcon: Icon(Icons.settings),
                      )
                    ],
                  ),
                ),
              ))
          : Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: CustomSideBarAnimated(
                onTap: homeScreenController.onSideBarTabSelected,
                sideBarColor: Theme.of(context).cardColor,
                animatedContainerColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.black,
                hoverColor: Theme.of(context).hoverColor,
                splashColor: Theme.of(context).splashColor,
                highlightColor: Theme.of(context).highlightColor,
                unSelectedTextColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                unselectedIconColor: Theme.of(context).iconTheme.color ?? Colors.grey,
                selectedIconColor: Colors.white,
                widthSwitch: 800,
                mainLogoImage: 'assets/icons/icon.png',
                mainLogoSize: const Size(60, 60),
                mainLogoTitle: 'ShivaayMusic',
                sidebarItems: [
                  SideBarItem(
                    iconSelected: Ionicons.home,
                    iconUnselected: Ionicons.home_outline,
                    text: 'home'.tr,
                  ),
                  SideBarItem(
                    iconSelected: Ionicons.musical_notes,
                    iconUnselected: Ionicons.musical_notes_outline,
                    text: 'songs'.tr,
                  ),
                  SideBarItem(
                    iconSelected: (GetPlatform.isAndroid || GetPlatform.isIOS) 
                        ? Ionicons.compass 
                        : Ionicons.list,
                    iconUnselected: (GetPlatform.isAndroid || GetPlatform.isIOS) 
                        ? Ionicons.compass_outline 
                        : Ionicons.list_outline,
                    text: (GetPlatform.isAndroid || GetPlatform.isIOS) 
                        ? "explore".tr 
                        : 'playlists'.tr,
                  ),
                  SideBarItem(
                    iconSelected: Ionicons.disc,
                    iconUnselected: Ionicons.disc_outline,
                    text: 'albums'.tr,
                  ),
                  SideBarItem(
                    iconSelected: Ionicons.person,
                    iconUnselected: Ionicons.person_outline,
                    text: 'artists'.tr,
                  ),
                  SideBarItem(
                    iconSelected: Ionicons.download,
                    iconUnselected: Ionicons.download_outline,
                    text: 'downloads'.tr,
                  ),
                  SideBarItem(
                    iconSelected: Ionicons.people,
                    iconUnselected: Ionicons.people_outline,
                    text: 'Music Room',
                  ),
                  SideBarItem(
                    iconSelected: Ionicons.settings,
                    iconUnselected: Ionicons.settings_outline,
                    text: 'settings'.tr,
                  ),
                ],
              ),
            ),
    );
  }

  NavigationRailDestination railDestination(
      String label, bool isMobileOrTabScreen, IconData icon) {
    return isMobileOrTabScreen
        ? NavigationRailDestination(
            icon: const SizedBox.shrink(),
            label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: isMobileOrTabScreen
                    ? RotatedBox(quarterTurns: -1, child: Text(label))
                    : Text(label)),
          )
        : NavigationRailDestination(
            icon: Icon(icon),
            label: Text(label),
            padding: const EdgeInsets.only(left: 10),
            indicatorShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
            indicatorColor: Colors.amber);
  }
}
