import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/listening_stat.dart';

class ListeningStatsService extends GetxService {
  late Box<ListeningStatDay> _box;
  final String _boxName = "ListeningStats";

  Future<ListeningStatsService> init() async {
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(ListeningStatDayAdapter());
    }
    _box = await Hive.openBox<ListeningStatDay>(_boxName);
    return this;
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Records listening time for a specific song
  Future<void> recordListeningTime(String songId, int seconds) async {
    if (seconds <= 0) return;
    
    final today = DateTime.now();
    final key = _getDateKey(today);

    ListeningStatDay dayStat = _box.get(key) ?? 
        ListeningStatDay(date: key, songStats: {});

    dayStat.totalSeconds += seconds;
    
    // Update song specific stats
    final currentSongTime = dayStat.songStats[songId] ?? 0;
    dayStat.songStats[songId] = currentSongTime + seconds;

    await dayStat.save();
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
