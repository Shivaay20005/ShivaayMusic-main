import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/like_animation_overlay.dart';
import '/ui/player/components/lyrics_widget.dart';
import '/ui/player/player_controller.dart';
import '../../widgets/image_widget.dart';
import '../../widgets/sleep_timer_bottom_sheet.dart';
import '../../widgets/songinfo_bottom_sheet.dart';

class AlbumArtNLyrics extends StatefulWidget {
  const AlbumArtNLyrics({super.key, required this.playerArtImageSize});
  final double playerArtImageSize;

  @override
  State<AlbumArtNLyrics> createState() => _AlbumArtNLyricsState();
}

class _AlbumArtNLyricsState extends State<AlbumArtNLyrics> {
  final GlobalKey<LikeAnimationOverlayState> _likeKey = GlobalKey();
  final PlayerController playerController = Get.find<PlayerController>();
  Worker? _favWorker;

  @override
  void initState() {
    super.initState();
    // Trigger animation when song becomes favorite (from any source)
    _favWorker = ever(playerController.isCurrentSongFav, (bool isFav) {
      if (isFav && mounted) {
        // Trigger animation programmatically without user tap details
        // We'll simulate a center tap or just spawn a heart
        // Since handleDoubleTap needs details, we might need to modify LikeAnimationOverlay 
        // OR just pass dummy details.
         _likeKey.currentState?.handleDoubleTap(TapDownDetails(
           globalPosition: Offset.zero, 
           localPosition: Offset(widget.playerArtImageSize / 2, widget.playerArtImageSize / 2),
           kind: null
         ));
      }
    });
  }

  @override
  void dispose() {
    _favWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final size = MediaQuery.of(context).size;
    //double playerArtImageSize = size.width - ((size.height < 750) ? 90 : 60);
    return Obx(() => playerController.currentSong.value != null
        ? Stack(
            children: [
              GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                    constraints: const BoxConstraints(maxWidth: 500),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(10.0)),
                    ),
                    isScrollControlled: true,
                    context:
                        playerController.homeScaffoldkey.currentState!.context,
                    barrierColor: Colors.transparent.withAlpha(100),
                    builder: (context) => SongInfoBottomSheet(
                      playerController.currentSong.value!,
                      calledFromPlayer: true,
                    ),
                  ).whenComplete(() => Get.delete<SongInfoController>());
                },
                onTap: () {
                  playerController.showLyrics();
                },
                onDoubleTapDown: (details) {
                  _likeKey.currentState?.handleDoubleTap(details);
                  playerController.toggleFavourite();
                },
                onDoubleTap: () {
                  // This empty callback is required for GestureDetector to wait for double tap
                },
                onHorizontalDragEnd: (DragEndDetails details) {
                  if (playerController.showLyricsflag.isTrue) return;
                  if (details.primaryVelocity! < 0) {
                    playerController.next();
                  } else if (details.primaryVelocity! > 0) {
                    playerController.prev();
                  }
                },
                child: LikeAnimationOverlay(
                  key: _likeKey,
                  child: ImageWidget(
                    size: widget.playerArtImageSize,
                    song: playerController.currentSong.value!,
                    isPlayerArtImage: true,
                  ),
                ),
              ),
              Obx(() => playerController.showLyricsflag.isTrue
                  ? InkWell(
                      onTap: () {
                        playerController.showLyrics();
                      },
                      child: Container(
                        height: widget.playerArtImageSize,
                        width: widget.playerArtImageSize,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Stack(
                          children: [
                            LyricsWidget(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: widget.playerArtImageSize / 3.5)),
                            IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.90),
                                      Colors.transparent,
                                      Colors.transparent,
                                      Colors.transparent,
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.90)
                                    ],
                                    stops: const [0, 0.2, 0.5, 0.8, 1],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              if (playerController.isSleepTimerActive.isTrue)
                SizedBox(
                  width: widget.playerArtImageSize,
                  height: widget.playerArtImageSize,
                  //color: Colors.green,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 50,
                        width: 60,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(width: 1.3, color: Colors.white),
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withAlpha(150)),
                        child: IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              constraints: const BoxConstraints(maxWidth: 500),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(10.0)),
                              ),
                              isScrollControlled: true,
                              context: playerController
                                  .homeScaffoldkey.currentState!.context,
                              barrierColor: Colors.transparent.withAlpha(100),
                              builder: (context) =>
                                  const SleepTimerBottomSheet(),
                            );
                          },
                          icon: const Icon(
                            Icons.timer,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          )
        : Container());
  }
}
