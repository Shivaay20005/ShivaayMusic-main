import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/screens/Settings/settings_screen_controller.dart';
import '/ui/widgets/piped_sync_widget.dart';
import '../../widgets/create_playlist_dialog.dart';
import 'library.dart';

class CombinedLibrary extends StatelessWidget {
  const CombinedLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final tabCon = Get.put(CombinedLibraryController());
    final settingscrnController = Get.find<SettingsScreenController>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
        actions: [
          Obx(() => (settingscrnController.isLinkedWithPiped.isTrue)
              ? const PipedSyncWidget(
                  padding: EdgeInsets.only(right: 10))
              : const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 40,
              width: 50,
              child: FittedBox(
                child: FloatingActionButton.extended(
                    elevation: 0,
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) =>
                              const CreateNRenamePlaylistPopup());
                    },
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.add,
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          splashFactory: NoSplash.splashFactory,
          controller: tabCon.tabController,
          tabs: [
            Tab(text: "playlists".tr),
            Tab(text: "songs".tr),
            Tab(text: "albums".tr),
            Tab(text: "artists".tr),
          ],
        ),
        title: Text('library'.tr, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: TabBarView(
        controller: tabCon.tabController,
        children: const [
          PlaylistNAlbumLibraryWidget(
              isAlbumContent: false, isBottomNavActive: true),
          SongsLibraryWidget(
            isBottomNavActive: true,
          ),
          PlaylistNAlbumLibraryWidget(isBottomNavActive: true),
          LibraryArtistWidget(isBottomNavActive: true),
        ],
      ),
    );
  }
}

class CombinedLibraryController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(vsync: this, length: 4, initialIndex: 1);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
