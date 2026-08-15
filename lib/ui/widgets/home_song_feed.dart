import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../player/player_controller.dart';
import 'song_list_tile.dart';

class HomeSongFeed extends StatelessWidget {
  const HomeSongFeed({
    super.key,
    required this.songs,
    required this.isLoadingMore,
  });

  final List<MediaItem> songs;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final playerController = Get.find<PlayerController>();

    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep the music going',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${songs.length} songs ready for you',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: scheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'DISCOVER',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Play all',
                      onPressed: () => playerController.playPlayListSong(songs, 0),
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.secondary,
                        foregroundColor: scheme.onSecondary,
                        minimumSize: const Size(38, 38),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 21),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.onSurface.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.045),
                  scheme.secondary.withValues(alpha: theme.brightness == Brightness.dark ? 0.06 : 0.025),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.07),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 5),
              itemCount: songs.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 78,
                endIndent: 16,
                color: scheme.onSurface.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                if (index >= songs.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  );
                }

                final song = songs[index];
                return Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  child: SongListTile(
                    key: ValueKey('home-song-${song.id}'),
                    song: song,
                    onTap: () => playerController.pushSongToQueue(song),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
