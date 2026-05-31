import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../player_controller.dart';
import '../../../services/downloader.dart';
import 'albumart_lyrics.dart';
import 'backgroud_image.dart';
import 'lyrics_switch.dart';
import 'player_control.dart';

/// Standard player widget
///
/// This widget is used to display the player in the standard mode
///
/// It contains the album art image, lyrics switch, album art with lyrics and player controls
/// and is used in the [Player] widget
class StandardPlayer extends StatelessWidget {
  const StandardPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final PlayerController playerController = Get.find<PlayerController>();

    double playerArtImageSize =
        size.width - 60; //((size.height < 750) ? 90 : 60);
    //playerArtImageSize = playerArtImageSize > 350 ? 350 : playerArtImageSize;
    final spaceAvailableForArtImage =
        size.height - (70 + Get.mediaQuery.padding.bottom + 330);
    playerArtImageSize = playerArtImageSize > spaceAvailableForArtImage
        ? spaceAvailableForArtImage
        : playerArtImageSize;
    return Stack(
      children: [
        /// Stack first child
        /// Album art image in background covering the whole screen
        BackgroudImage(
          key: Key("${playerController.currentSong.value?.id}_background"),
          cacheHeight: 200,
        ),

        /// Stack child
        /// Blur effect on background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Stack(
            children: [
              /// opacity effect on background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ),
                ),
              ),

              /// used to hide queue header when player is minimized
              /// gradient to used here
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 65 + Get.mediaQuery.padding.bottom + 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.4),
                        Theme.of(context).primaryColor.withValues(alpha: 0),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0, 0.5, 0.8, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// Stack child
        /// Player content in landscape mode
        Padding(
          padding: const EdgeInsets.only(left: 25, right: 25),
          child: (context.isLandscape)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Album art with lyrics in .45  of width
                    SizedBox(
                      width: size.width * .45,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 90.0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: AlbumArtNLyrics(
                              playerArtImageSize: size.width * .29,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Player controls in .48 of width
                    SizedBox(
                        width: size.width * .48,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 10.0,
                              right: 10,
                              bottom: Get.mediaQuery.padding.bottom),
                          child: const PlayerControlWidget(),
                        ))
                  ],
                )
              :

              /// Player content in portrait mode
              Column(
                  children: [
                    /// Work as top padding depending on the lyrics visibility and screen size
                    Obx(
                      () => playerController.showLyricsflag.value
                          ? SizedBox(
                              height: size.height < 750 ? 60 : 90,
                            )
                          : SizedBox(
                              height: size.height < 750 ? 110 : 140,
                            ),
                    ),

                    /// Contains the lyrics switch and album art with lyrics
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LyricsSwitch(),
                        ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: AlbumArtNLyrics(
                                playerArtImageSize: playerArtImageSize)),
                      ],
                    ),

                    /// Action buttons (Sleep Timer, Download)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Row(
                          children: [
                            // Sleep Timer button
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: GetX<PlayerController>(
                                    builder: (controller) {
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(30),
                                        onTap: () {
                                          showModalBottomSheet(
                                            constraints: const BoxConstraints(maxWidth: 500),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
                                            ),
                                            isScrollControlled: true,
                                            context: controller.homeScaffoldkey.currentState!.context,
                                            barrierColor: Colors.transparent.withAlpha(100),
                                            builder: (context) => const SleepTimerBottomSheet(),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                controller.isSleepTimerActive.isTrue
                                                    ? Icons.timer
                                                    : Icons.timer_outlined,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  "Sleep Timer".tr,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Download button with progress indicator
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: GetX<PlayerController>(
                                    builder: (controller) {
                                      final currentSong = controller.currentSong.value;
                                      final disabled = currentSong == null;

                                      if (disabled) {
                                        return AbsorbPointer(
                                          absorbing: true,
                                          child: Opacity(
                                            opacity: 0.5,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.download, size: 20),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      "Download".tr,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      final downloader = Get.find<Downloader>();
                                      final isDownloaded = Hive.box("SongDownloads")
                                          .containsKey(currentSong.id);
                                      final isDownloading =
                                          downloader.songQueue.contains(currentSong);
                                      
                                      // Get download progress percentage
                                      final downloadProgress = downloader.songDownloadingProgress.value;
                                      final showProgress = isDownloading && downloadProgress > 0;

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(30),
                                        onTap: () {
                                          if (!isDownloaded && !isDownloading) {
                                            downloader.download(currentSong);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Icon with progress badge
                                              Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Icon(
                                                    isDownloaded
                                                        ? Icons.download_done
                                                        : isDownloading
                                                            ? Icons.downloading
                                                            : Icons.download,
                                                    size: 20,
                                                  ),
                                                  // Download progress percentage badge
                                                  if (showProgress)
                                                    Positioned(
                                                      right: -12,
                                                      top: -12,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green,
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(
                                                            color: Colors.white,
                                                            width: 2,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black.withValues(alpha: 0.3),
                                                              blurRadius: 4,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        constraints: const BoxConstraints(
                                                          minWidth: 32,
                                                          minHeight: 20,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            '$downloadProgress%',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              height: 1.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  isDownloaded
                                                      ? "Downloaded".tr
                                                      : isDownloading
                                                          ? "Downloading".tr
                                                          : "Download".tr,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
                  
                  /// Extra space container
                    Expanded(child: Container()),

                    /// Contains the player controls
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: 80 + Get.mediaQuery.padding.bottom),
                      child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: const PlayerControlWidget()),
                    )
                  ],
                ),
        ),

        /// Stack child
        /// Contains [Minimize button], Playing from [Album name], [More button] for current song context
        Padding(
            padding: EdgeInsets.only(
                top: Get.mediaQuery.padding.top + 20, left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Minimize button
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 28,
                  ),
                  onPressed: playerController.playerPanelController.close,
                ),

                /// Playing from [Album name]
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 5, right: 5),
                    child: Obx(
                      () => Column(
                        children: [
                          Text(playerController.playinfrom.value.typeString,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          Obx(
                            () => Text(
                              "\"${playerController.playinfrom.value.nameString}\"",
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                /// More button for current song context
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 25,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      constraints: const BoxConstraints(maxWidth: 500),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(10.0)),
                      ),
                      isScrollControlled: true,
                      context: playerController
                          .homeScaffoldkey.currentState!.context,
                      barrierColor: Colors.transparent.withAlpha(100),
                      builder: (context) => SongInfoBottomSheet(
                        playerController.currentSong.value!,
                        calledFromPlayer: true,
                      ),
                    ).whenComplete(() => Get.delete<SongInfoController>());
                  },
                ),
              ],
            ),
          )
      ],
    );
  }
}
