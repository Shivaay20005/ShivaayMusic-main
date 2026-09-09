import 'package:hive/hive.dart';

part 'listening_stat.g.dart';

@HiveType(typeId: 20)
class ListeningStatDay extends HiveObject {
  @HiveField(0)
  final String date; // Format: YYYY-MM-DD

  @HiveField(1)
  int totalSeconds;

  @HiveField(2)
  Map<String, int> songStats; // songId -> seconds listened

  @HiveField(3)
  Map<String, Map<String, String>> songMetadata;

  ListeningStatDay({
    required this.date,
    this.totalSeconds = 0,
    Map<String, int>? songStats,
    Map<String, Map<String, String>>? songMetadata,
  })  : songStats = songStats ?? {},
        songMetadata = songMetadata ?? {};
}
