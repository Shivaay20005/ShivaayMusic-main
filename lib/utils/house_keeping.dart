import 'dart:io';

import 'package:get/get.dart';
import '/models/media_Item_builder.dart';
import '/ui/screens/Library/library_controller.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../services/utils.dart';
import 'helper.dart';

void startHouseKeeping() {
  removeExpiredSongsUrlFromDb();
}

Future<void> removeExpiredSongsUrlFromDb() async {
  try {
    final songsUrlCacheBox = Hive.box("SongsUrlCache");
    final songsUrlCacheKeysList =
        songsUrlCacheBox.keys.whereType<String>().toList();
    for (var i = 0; i < songsUrlCacheKeysList.length; i++) {
      final songUrlKey = songsUrlCacheKeysList[i];
      final entry = songsUrlCacheBox.get(songUrlKey);
      // `checkNGetUrl` stores the map returned by `smStreamingData`, so the
      // audio lives under `highQualityAudio` / `lowQualityAudio`. The old code
      // read `entry[1]`, which is always null for a map, so every cached URL
      // was deleted on the first visit to the library screen — the cache was
      // empty at every cold start and each song paid for a fresh extraction.
      dynamic audio;
      if (entry is Map) {
        audio = entry['highQualityAudio'] ?? entry['lowQualityAudio'];
      } else if (entry is List && entry.length > 1) {
        // Older builds stored a list whose second element was the audio map.
        audio = entry[1];
      }
      final url = audio is Map ? audio['url'] : null;
      if (url is! String || isExpired(url: url)) {
        await songsUrlCacheBox.delete(songUrlKey);
      }
    }
  } catch (e) {
    printERROR("Error in removeExpiredSongsUrlFromDb: $e");
  } finally {
    removeDeletedOfflineSongsFromDb();
  }
}

Future<void> removeDeletedOfflineSongsFromDb() async {
  final supportDir = (await getApplicationSupportDirectory()).path;
  try {
    final songDownloadsBox = Hive.box("SongDownloads");
    final downloadedSongs = songDownloadsBox.values.toList();
    final LibrarySongsController librarySongsController =
        Get.find<LibrarySongsController>();
    for (var i = 0; i < downloadedSongs.length; i++) {
      final songKey = downloadedSongs[i]['videoId'];
      final songUrl = downloadedSongs[i]['url'];
      if (await File(songUrl).exists() == false) {
        await songDownloadsBox.delete(songKey);
        await librarySongsController.removeSong(
            MediaItemBuilder.fromJson(downloadedSongs[i]), true);
        final thumbNailPath = "$supportDir/thumbnails/$songKey.png";
        if (await File(thumbNailPath).exists()) {
          await File(thumbNailPath).delete();
        }
      }
    }
  } catch (e) {
    printERROR("Error in removeDeletedOfflineSongsFromDb: $e");
  }
}
