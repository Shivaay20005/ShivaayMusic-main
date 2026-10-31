import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shivaaymusic/services/app_logs.dart';
import 'package:shivaaymusic/ui/navigator.dart';
import 'package:shivaaymusic/ui/widgets/sort_widget.dart';

const _androidReleaseUrl =
    'https://github.com/Shivaay20005/ShivaayMusic/releases/latest';
const _windowsReleaseUrl =
    'https://github.com/Shivaay20005/ShivaayMusic-Windows-release/releases/latest';

/// Returns the public download page appropriate for the current platform.
String get latestReleaseUrl =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
        ? _windowsReleaseUrl
        : _androidReleaseUrl;

/// Opens links in the user's default browser or registered external app.
///
/// GitHub's release redirects and file downloads do not work reliably inside
/// an embedded WebView. Keeping all network links external also lets Chrome,
/// Edge, Firefox, or the user's chosen browser handle downloads normally.
Future<void> launchUrlSafe(String url) async {
  final value = url.trim();
  if (value.isEmpty) return;

  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) {
    throw FormatException('Invalid URL', value);
  }

  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw StateError('Could not open $uri in an external application');
  }
}

// `print*` helpers now persist every line to AppLogs as well.
//
// The console output is still debug-only (it costs a jank-free but useless
// syscall in release), but the file keeps working in release builds. That is
// what makes "songs do not play" reportable without adb, Shizuku or a bug
// report: Settings -> Music & Playback -> Diagnostics -> Share logs.
void printERROR(dynamic text, {String tag = "ShivaayMusic"}) {
  AppLogs.write('E/$tag', text);
  if (kReleaseMode) return;
  debugPrint("\x1B[31m[$tag]: $text\x1B[0m");
}

void printWarning(dynamic text, {String tag = 'ShivaayMusic'}) {
  AppLogs.write('W/$tag', text);
  if (kReleaseMode) return;
  debugPrint("\x1B[33m[$tag]: $text\x1B[34m");
}

void printINFO(dynamic text, {String tag = 'ShivaayMusic'}) {
  AppLogs.write('I/$tag', text);
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

/// Repositories whose latest published version decides whether an update is
/// advertised. The first entry is the original download repository that every
/// installed copy already polls; the second is the build repository so a new
/// release is still detected if the legacy sync has not run yet.
List<String> get _versionCheckRepos => [
      'Shivaay20005/ShivaayMusic',
      'Shivaay20005/ShivaayMusic-main',
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
        'Shivaay20005/ShivaayMusic-Windows-release',
    ];

/// Parses `1.0.8`, `v1.0.8`, `V1.0.8+13` (and similar) into comparable parts.
List<int> _parseVersionParts(String raw) {
  final withoutPrefix = raw.trim().replaceFirst(RegExp(r'^[vV]'), '');
  final core = withoutPrefix.split('+').first;
  return core
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}

/// Returns true when [available] is a newer version than [current].
///
/// This replaces the previous hand-written comparison, which crashed on
/// short tags (for example `1.0`), treated `1.0.10` as older than `1.0.9`, and
/// relied on the first tag returned by the API instead of the highest one.
bool isVersionNewer(String current, String available) {
  final currentParts = _parseVersionParts(current);
  final availableParts = _parseVersionParts(available);
  final length = currentParts.length > availableParts.length
      ? currentParts.length
      : availableParts.length;

  for (var i = 0; i < length; i++) {
    final currentPart = i < currentParts.length ? currentParts[i] : 0;
    final availablePart = i < availableParts.length ? availableParts[i] : 0;
    if (availablePart != currentPart) {
      return availablePart > currentPart;
    }
  }
  return false;
}

/// Reads the newest published version from one repository.
///
/// The releases endpoint is preferred because it is ordered and points at the
/// build that is actually downloadable. The tags endpoint is a fallback for
/// repositories that have tags but no releases yet. The tags list is scanned
/// in full so a re-pushed older tag cannot hide the newest one.
Future<String?> _latestVersionFromRepo(String repo) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: const {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'ShivaayMusic-App',
    },
  ));

  try {
    final response =
        await dio.get('https://api.github.com/repos/$repo/releases/latest');
    final data = response.data;
    if (data is Map && data['tag_name'] is String) {
      final tag = data['tag_name'] as String;
      if (RegExp(r'^[vV]?\d').hasMatch(tag)) return tag;
    }
  } catch (_) {
    // No release yet (or rate limited); fall back to the tags endpoint.
  }

  try {
    final response =
        await dio.get('https://api.github.com/repos/$repo/tags?per_page=100');
    final data = response.data;
    if (data is List) {
      String? newest;
      for (final tag in data) {
        if (tag is! Map || tag['name'] is! String) continue;
        final name = tag['name'] as String;
        if (!RegExp(r'^[vV]?\d').hasMatch(name)) continue;
        if (newest == null || isVersionNewer(newest, name)) newest = name;
      }
      return newest;
    }
  } catch (_) {
    // Network/permission errors are non-fatal: do not advertise an update.
  }

  return null;
}

Future<bool> newVersionCheck(String currentVersion) async {
  try {
    // Query the repositories concurrently so a slow/unreachable host cannot
    // stack up its timeout on top of the others.
    final candidates = await Future.wait(
        _versionCheckRepos.map((repo) => _latestVersionFromRepo(repo)));

    String? newest;
    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (newest == null || isVersionNewer(newest, candidate)) {
        newest = candidate;
      }
    }

    if (newest == null) return false;
    return isVersionNewer(currentVersion, newest);
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
