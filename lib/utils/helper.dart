import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shivaaymusic/ui/navigator.dart';
import 'package:shivaaymusic/ui/widgets/sort_widget.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MyInAppBrowser extends InAppBrowser {
  @override
  void onLoadStart(url) {
    debugPrint("InAppBrowser started loading: $url");
  }

  @override
  void onLoadStop(url) {
    debugPrint("InAppBrowser stopped loading: $url");
  }
}

Future<void> launchUrlSafe(String url) async {
  if (url.isEmpty) return;
  final Uri uri = Uri.parse(url);
  
  // No try-catch fallback! If native plugin is missing, it will throw a visible error.
  if (uri.scheme == 'http' || uri.scheme == 'https') {
    final browser = MyInAppBrowser();
    await browser.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(url)),
      settings: InAppBrowserClassSettings(
        browserSettings: InAppBrowserSettings(
          hideUrlBar: false,
        ),
      ),
    );
  } else {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

void printERROR(dynamic text, {String tag = "ShivaayMusic"}) {
  if (kReleaseMode) return;
  debugPrint("\x1B[31m[$tag]: $text\x1B[0m");
}

void printWarning(dynamic text, {String tag = 'ShivaayMusic'}) {
  if (kReleaseMode) return;
  debugPrint("\x1B[33m[$tag]: $text\x1B[34m");
}

void printINFO(dynamic text, {String tag = 'ShivaayMusic'}) {
  if (kReleaseMode) return;
  debugPrint("\x1B[32m[$tag]: $text\x1B[34m");
}

String? getCurrentRouteName() {
  String? currentPath;
  Get.nestedKey(ScreenNavigationSetup.id)?.currentState?.popUntil((route) {
    currentPath = route.settings.name;
    return true;
  });
  return currentPath;
}

void sortSongsNVideos(
  List songlist,
  SortType sortType,
  bool isAscending,
) {
  Comparator compareFunction;

  switch (sortType) {
    case SortType.Date:
      compareFunction = (a, b) {
        if (a.extras!['date'] == null || b.extras!['date'] == null) {
          return 0.compareTo(0);
        }
        return a.extras!['date'].compareTo(b.extras!['date']);
      };
      break;
    case SortType.Duration:
      compareFunction = (a, b) =>
          (a.duration ?? Duration.zero).compareTo(b.duration ?? Duration.zero);
    case SortType.Name:
    default:
      compareFunction =
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
      break;
  }

  songlist.sort(compareFunction);

  if (!isAscending) {
    List reversed = songlist.reversed.toList();
    songlist.clear();
    songlist.addAll(reversed);
  }
}

void sortAlbumNSingles(
  List albumList,
  SortType sortType,
  bool isAscending,
) {
  Comparator compareFunction;

  switch (sortType) {
    case SortType.Date:
      compareFunction =
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
      break;
    case SortType.Name:
    default:
      compareFunction = (a, b) {
        if (a.year == null || b.year == null) {
          return 0.compareTo(0);
        }
        return a.year!.compareTo(b.year!);
      };
      break;
  }

  albumList.sort(compareFunction);

  if (!isAscending) {
    List reversed = albumList.reversed.toList();
    albumList.clear();
    albumList.addAll(reversed);
  }
}

void sortPlayLists(
  List playlists,
  SortType sortType,
  bool isAscending,
) {
  Comparator compareFunction;
  int titleSort(a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());

  switch (sortType) {
    case SortType.RecentlyPlayed:
      compareFunction = (a, b) {
        DateTime? alp = a.lastPlayed;
        DateTime? blp = b.lastPlayed;
        if (alp == null && blp == null) {
          return titleSort(a, b);
        }
        if (alp == null) {
          return 1;
        }
        if (blp == null) {
          return -1;
        }
        return blp.compareTo(alp);
      };
      break;
    case SortType.Name:
    default:
      compareFunction = titleSort;
      break;
  }

  playlists.sort(compareFunction);

  if (!isAscending) {
    List reversed = playlists.reversed.toList();
    playlists.clear();
    playlists.addAll(reversed);
  }
}

void sortArtist(
  List artistList,
  SortType sortType,
  bool isAscending,
) {
  Comparator compareFunction;

  switch (sortType) {
    case SortType.Name:
    default:
      compareFunction =
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
      break;
  }

  artistList.sort(compareFunction);

  if (!isAscending) {
    List reversed = artistList.reversed.toList();
    artistList.clear();
    artistList.addAll(reversed);
  }
}

Future<bool> newVersionCheck(String currentVersion) async {
  try {
    final tags = (await Dio()
            .get("https://api.github.com/repos/Shivaay20005/ShivaayMusic/tags"))
        .data;
    final availableVersion = tags[0]['name'] as String;
    
    // Remove "v" or "V" prefix if present
    String cleanCurrent = currentVersion.replaceAll(RegExp(r'[vV]'), '');
    String cleanAvailable = availableVersion.replaceAll(RegExp(r'[vV]'), '');
    
    List currentVersion_ = cleanCurrent.split(".");
    List availableVersion_ = cleanAvailable.split(".");
    
    if (int.parse(availableVersion_[0]) > int.parse(currentVersion_[0])) {
      return true;
    } else if (int.parse(availableVersion_[1]) >
            int.parse(currentVersion_[1]) &&
        int.parse(availableVersion_[0]) == int.parse(currentVersion_[0])) {
      return true;
    } else if (int.parse(availableVersion_[2]) >
            int.parse(currentVersion_[2]) &&
        int.parse(availableVersion_[0]) == int.parse(currentVersion_[0]) &&
        int.parse(availableVersion_[1]) == int.parse(currentVersion_[1])) {
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

String getTimeString(Duration time) {
  final minutes = time.inMinutes.remainder(Duration.minutesPerHour).toString();
  final seconds = time.inSeconds
      .remainder(Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');
  return time.inHours > 0
      ? "${time.inHours}:${minutes.padLeft(2, "0")}:$seconds"
      : "$minutes:$seconds";
}
