import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/playling_from.dart';
import '/ui/widgets/songinfo_bottom_sheet.dart';
import '/utils/helper.dart';
import '../ui/widgets/loader.dart';
import '/services/music_service.dart';
import '/ui/player/player_controller.dart';
import '../ui/navigator.dart';
import '../ui/widgets/snackbar.dart';

class AppLinksController extends GetxController with ProcessLink {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void onInit() {
    initDeepLinks();
    super.onInit();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      await filterLinks(appLink);
    }

    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      await filterLinks(uri);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}

mixin ProcessLink {
  Future<void> filterLinks(Uri uri) async {
    final playerController = Get.find<PlayerController>();
    if (playerController.playerPanelController.isPanelOpen) {
      playerController.playerPanelController.close();
    }

    if (Get.isRegistered<SongInfoController>()) {
      Navigator.of(Get.context!).pop();
    }

    // Handle custom domain links
    if (uri.host == "shivaaymusic.com" ||
        uri.host == "www.shivaaymusic.com" ||
        uri.host == "shivaaymusic.dpdns.org") {
      printINFO("Custom domain link: ${uri.pathSegments}");
      
      if (uri.pathSegments.isNotEmpty) {
        final firstSegment = uri.pathSegments[0];
        
        // Handle song links (direct video ID or /track/ or /watch?v=)
        if (firstSegment.length == 11) { 
          await playSong(firstSegment);
          return;
        }
        
        if (firstSegment == "track" && uri.pathSegments.length > 1) {
            await playSong(uri.pathSegments[1]);
            return;
        }

        if (firstSegment == "watch") {
           final v = uri.queryParameters['v'];
           if (v != null && v.length == 11) {
             await playSong(v);
             return;
           }
        }
        
        // Handle playlist links
        if (firstSegment == "playlist" && uri.pathSegments.length > 1) {
          final playlistId = uri.pathSegments[1];
          await openPlaylistOrAlbum(playlistId);
          return;
        }
        
        // Handle artist links
        if (firstSegment == "artist" && uri.pathSegments.length > 1) {
          final artistId = uri.pathSegments[1];
          await openArtist(artistId);
          return;
        }
      }
    }

    if (uri.host == "youtube.com" ||
        uri.host == "music.youtube.com" ||
        uri.host == "youtu.be" ||
        uri.host == "www.youtube.com" ||
        uri.host == "m.youtube.com" ||
        uri.scheme == "shivaaymusic") {
      printINFO(
          "pathsegmet: ${uri.pathSegments} params:${uri.queryParameters}");
      
      // Handle custom scheme
      if (uri.scheme == "shivaaymusic") {
        if (uri.pathSegments.isNotEmpty) {
          final path = uri.pathSegments[0];
          if (path == "song" && uri.queryParameters.containsKey("id")) {
            final songId = uri.queryParameters['id']!;
            await playSong(songId);
            return;
          } else if (path == "playlist" && uri.queryParameters.containsKey("id")) {
            final playlistId = uri.queryParameters['id']!;
            await openPlaylistOrAlbum(playlistId);
            return;
          } else if (path == "artist" && uri.queryParameters.containsKey("id")) {
            final artistId = uri.queryParameters['id']!;
            await openArtist(artistId);
            return;
          }
        }
      }
      
      if (uri.pathSegments[0] == "playlist" &&
          uri.queryParameters.containsKey("list")) {
        final browseId = uri.queryParameters['list'];
        await openPlaylistOrAlbum(browseId!);
      } else if (uri.pathSegments[0] == "shorts") {
        ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
            Get.context!, "notaSongVideo".tr,
            size: SanckBarSize.MEDIUM));
      } else if (uri.pathSegments[0] == "watch") {
        final songId = uri.queryParameters['v'];
        await playSong(songId!);
      } else if (uri.pathSegments[0] == "channel") {
        final browseId = uri.pathSegments[1];
        await openArtist(browseId);
      } else if ((uri.queryParameters.isEmpty || uri.query.contains("si=")) &&
          uri.host == "youtu.be") {
        final songId = uri.pathSegments[0];
        await playSong(songId);
      } else if (uri.scheme == "shivaaymusic") {
        // Handle custom scheme with path segments
        if (uri.pathSegments.isNotEmpty) {
          final firstSegment = uri.pathSegments[0];
          if (firstSegment.length == 11) { // YouTube video ID is 11 characters
            await playSong(firstSegment);
          }
        }
      }
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
          Get.context!, "notaValidLink".tr,
          size: SanckBarSize.MEDIUM));
    }
  }

  Future<void> openPlaylistOrAlbum(String browseId) async {
    if (browseId.contains("OLAK5uy")) {
      Get.toNamed(ScreenNavigationSetup.albumScreen,
          id: ScreenNavigationSetup.id, arguments: (null, browseId));
    } else {
      Get.toNamed(ScreenNavigationSetup.playlistScreen,
          id: ScreenNavigationSetup.id, arguments: [null, browseId]);
    }
  }

  Future<void> openArtist(String channelId) async {
    await Get.toNamed(ScreenNavigationSetup.artistScreen,
        id: ScreenNavigationSetup.id, arguments: [true, channelId]);
  }

  Future<void> playSong(String songId) async {
    showDialog(
        context: Get.context!,
        builder: (context) => const Center(
                child: LoadingIndicator(
              strokeWidth: 5,
            )),
        barrierDismissible: false);
    final result = await Get.find<MusicServices>().getSongWithId(songId);
    Navigator.of(Get.context!).pop();
    if (result[0]) {
      Get.find<PlayerController>().playPlayListSong(List.from(result[1]), 0,
          playfrom: PlaylingFrom(type: PlaylingFromType.SELECTION));
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
          Get.context!, "notaSongVideo".tr,
          size: SanckBarSize.MEDIUM));
    }
  }
}
