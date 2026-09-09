import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/listening_stat.dart';

class ListeningStatsService extends GetxService {
  late Box<ListeningStatDay> _box;
  final String _boxName = "ListeningStats";
  bool _isInitialized = false;

  Future<ListeningStatsService> init() async {
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(ListeningStatDayAdapter());
    }
    _box = await Hive.openBox<ListeningStatDay>(_boxName);
    _isInitialized = true;
    return this;
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Records listening time and keeps enough track information to render a
  /// useful stats screen without making another network request.
  Future<void> recordListeningTime(
    String songId,
    int seconds, {
    String? title,
    String? artist,
    String? artworkUrl,
  }) async {
    if (!_isInitialized || songId.isEmpty || seconds <= 0) return;

    final today = DateTime.now();
    final key = _getDateKey(today);
    final dayStat = _box.get(key) ??
        ListeningStatDay(date: key, songStats: <String, int>{});

    dayStat.totalSeconds += seconds;

    // Update song-specific stats. Always put the value into the box: a newly
    // created HiveObject is not attached to a box yet, so calling save() on it
    // drops the first listening entry with a HiveError.
    dayStat.songStats[songId] = (dayStat.songStats[songId] ?? 0) + seconds;
    if (title != null || artist != null || artworkUrl != null) {
      final existing = dayStat.songMetadata[songId] ?? <String, String>{};
      dayStat.songMetadata[songId] = {
        'title': title?.trim().isNotEmpty == true
            ? title!.trim()
            : (existing['title'] ?? songId),
        'artist': artist?.trim().isNotEmpty == true
            ? artist!.trim()
            : (existing['artist'] ?? 'Unknown artist'),
        'artworkUrl': artworkUrl?.trim().isNotEmpty == true
            ? artworkUrl!.trim()
            : (existing['artworkUrl'] ?? ''),
      };
    }
    await _box.put(key, dayStat);
  }

  /// Get stats for a specific day
  ListeningStatDay? getDayStats(DateTime date) {
    return _box.get(_getDateKey(date));
  }

  /// Get stats for the last N days (inclusive)
  List<ListeningStatDay> getRecentStats(int days) {
    final List<ListeningStatDay> stats = [];
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final stat = getDayStats(date);
      if (stat != null) {
        stats.add(stat);
      }
    }
    return stats;
  }

  /// Get total listening time in seconds for a date range
  int getTotalTimeInRange(DateTime start, DateTime end) {
    int total = 0;
    final days = end.difference(start).inDays + 1;
    
    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final stat = getDayStats(date);
      if (stat != null) {
        total += stat.totalSeconds;
      }
    }
    return total;
  }

  /// Daily totals in chronological order, including zero-listening days.
  List<int> getDailyTotals(int days) {
    final now = DateTime.now();
    return List<int>.generate(days, (index) {
      final date = now.subtract(Duration(days: days - index - 1));
      return getDayStats(date)?.totalSeconds ?? 0;
    });
  }

  /// Returns the newest stored display information for a song.
  Map<String, String> getSongMetadata(
    String songId,
    DateTime start,
    DateTime end,
  ) {
    final days = end.difference(start).inDays + 1;
    for (int i = days - 1; i >= 0; i--) {
      final stat = getDayStats(start.add(Duration(days: i)));
      final metadata = stat?.songMetadata[songId];
      if (metadata != null) return metadata;
    }
    return {
      'title': songId,
      'artist': 'Unknown artist',
      'artworkUrl': '',
    };
  }

  /// Get top songs for a date range
  /// Returns Map<SongId, Seconds> sorted by duration descending
  List<MapEntry<String, int>> getTopSongs(DateTime start, DateTime end, {int limit = 10}) {
    final Map<String, int> aggregatedSongs = {};
    final days = end.difference(start).inDays + 1;

    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final stat = getDayStats(date);
      if (stat != null) {
        stat.songStats.forEach((songId, seconds) {
          aggregatedSongs[songId] = (aggregatedSongs[songId] ?? 0) + seconds;
        });
      }
    }

    final sortedEntries = aggregatedSongs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.length > limit) {
      return sortedEntries.sublist(0, limit);
    }
    return sortedEntries;
  }
}
