import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigator.dart';
import 'image_widget.dart';

class ContentListItem extends StatelessWidget {
  const ContentListItem({
    super.key,
    required this.content,
    this.isLibraryItem = false,
  });

  /// Content will be of Type class Album or Playlist.
  final dynamic content;
  final bool isLibraryItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAlbum = content.runtimeType.toString() == 'Album';

    return SizedBox(
      width: 138,
      height: 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: scheme.secondary.withValues(alpha: 0.12),
        highlightColor: scheme.secondary.withValues(alpha: 0.06),
        onTap: () {
          if (isAlbum) {
            Get.toNamed(
              ScreenNavigationSetup.albumScreen,
              id: ScreenNavigationSetup.id,
              arguments: (content, content.browseId),
            );
            return;
          }
          Get.toNamed(
            ScreenNavigationSetup.playlistScreen,
            id: ScreenNavigationSetup.id,
            arguments: [content, content.playlistId],
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArtwork(context, isAlbum),
              const SizedBox(height: 9),
              Text(
                content.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAlbum
                    ? isLibraryItem
                        ? ''
                        : '${content.artists[0]['name'] ?? ''} | ${content.year ?? ''}'
                    : isLibraryItem
                        ? ''
                        : content.description ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(BuildContext context, bool isAlbum) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final artwork = isAlbum
        ? ImageWidget(
            size: 130,
            album: content,
          )
        : (content.isCloudPlaylist ||
                !(content.playlistId == 'LIBRP' ||
                    content.playlistId == 'LIBFAV' ||
                    content.playlistId == 'SongsCache' ||
                    content.playlistId == 'SongDownloads'))
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ImageWidget(
                    size: 130,
                    playlist: content,
                  ),
                  if (content.isPipedPlaylist) _buildBadge(context, 'P'),
                  if (!content.isCloudPlaylist) _buildBadge(context, 'L'),
                ],
              )
            : Container(
                color: scheme.secondary,
                child: Center(
                  child: Icon(
                    content.playlistId == 'LIBRP'
                        ? Icons.history_rounded
                        : content.playlistId == 'LIBFAV'
                            ? Icons.favorite_rounded
                            : content.playlistId == 'SongsCache'
                                ? Icons.flight_rounded
                                : Icons.download_rounded,
                    color: scheme.onSecondary,
                    size: 40,
                  ),
                ),
              );

    return Container(
      height: 130,
      width: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: artwork,
    );
  }

  Widget _buildBadge(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.secondary,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: scheme.onSecondary.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
