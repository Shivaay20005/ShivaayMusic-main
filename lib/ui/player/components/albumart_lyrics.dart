import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
                  child: Obx(() {
                    if (playerController.isVideoMode.value) {
                      if (playerController.isVideoInitializing.value) {
                        return SizedBox(
                          height: widget.playerArtImageSize,
                          width: widget.playerArtImageSize,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final videoId = playerController.videoModeId.value;
                      final url = "https://m.youtube.com/watch?v=$videoId";
                      
                      return SizedBox(
                        height: widget.playerArtImageSize,
                        width: widget.playerArtImageSize,
                        child: InAppWebView(
                          initialUrlRequest: URLRequest(url: WebUri(url)),
                          initialSettings: InAppWebViewSettings(
                            mediaPlaybackRequiresUserGesture: false,
                            allowsInlineMediaPlayback: true,
                            transparentBackground: true,
                            disableContextMenu: true,
                            supportZoom: false,
                          ),
                          onProgressChanged: (controller, progress) async {
                            if (progress > 10) {
                              await controller.evaluateJavascript(source: """
                                if (!document.getElementById('aggressive-css')) {
                                    var style = document.createElement('style');
                                    style.id = 'aggressive-css';
                                    style.innerHTML = `
                                      ytm-header-bar, ytm-item-section-renderer, ytm-pivot-bar-renderer, ytm-app-promo-renderer, .page-container, ytm-single-column-watch-next-results-renderer, dialog, .consent-bump,
                                      .ytp-chrome-top, .ytp-watermark, .ytp-youtube-button, .ytp-unmute-box, .ytp-spinner, .ytp-ce-element, a[href*="youtube.com/watch"], .icon-youtube, .ytm-watermark {
                                          display: none !important;
                                          opacity: 0 !important;
                                          pointer-events: none !important;
                                      }
                                      
                                      html, body, ytm-app, ytm-watch, .player-container, .player-size, #player-control-container, ytm-custom-control, .html5-video-player {
                                          width: 100vw !important;
                                          height: 100vh !important;
                                          max-width: 100% !important;
                                          max-height: 100% !important;
                                          margin: 0 !important;
                                          padding: 0 !important;
                                          background-color: transparent !important;
                                      }
                                      
                                      video {
                                          width: 100vw !important;
                                          height: 100vh !important;
                                          object-fit: cover !important;
                                          border-radius: 10px !important;
                                          background-color: black !important;
                                      }
                                      body { overflow: hidden !important; }
                                      
                                      .shivaay-watermark {
                                          position: fixed !important;
                                          top: 10px !important;
                                          right: 15px !important;
                                          color: rgba(255, 255, 255, 0.6) !important;
                                          font-size: 14px !important;
                                          font-family: sans-serif !important;
                                          font-weight: 800 !important;
                                          z-index: 2147483647 !important;
                                          pointer-events: none !important;
                                      }
                                    `;
                                    document.documentElement.appendChild(style);
                                }
                              """);
                            }
                          },
                          onLoadStop: (controller, url) async {
                            await controller.evaluateJavascript(source: """
                              if (!document.querySelector('.shivaay-watermark')) {
                                  var wm = document.createElement('div');
                                  wm.className = 'shivaay-watermark';
                                  wm.innerText = 'SHIVAAY MUSIC';
                                  document.body.appendChild(wm);
                              }
                            
                              setInterval(function() {
                                var vid = document.querySelector('video');
                                if (vid) {
                                    if (vid.muted) vid.muted = false; // Force unmute
                                }
                                
                                var unmuteBtn = document.querySelector('.ytp-unmute-box') || document.querySelector('.ytp-unmute');
                                if (unmuteBtn) {
                                    unmuteBtn.click();
                                    unmuteBtn.style.display = 'none';
                                }
                                
                                var skipBtn = document.querySelector('.ytp-ad-skip-button') || document.querySelector('.ytp-ad-skip-button-modern');
                                if (skipBtn) skipBtn.click();
                                
                                var adPlayer = document.querySelector('.ad-showing');
                                if (adPlayer && vid) {
                                    if (vid.duration > 0 && vid.currentTime < vid.duration - 1) {
                                        vid.currentTime = vid.duration; // Instantly skip
                                    }
                                }
                              }, 1000);
                            """);
                          },
                        ),
                      );
                    } else {
                      return ImageWidget(
                        size: widget.playerArtImageSize,
                        song: playerController.currentSong.value!,
                        isPlayerArtImage: true,
                      );
                    }
                  }),
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
