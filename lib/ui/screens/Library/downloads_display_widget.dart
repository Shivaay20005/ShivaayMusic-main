import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '/models/media_Item_builder.dart';
import '/ui/widgets/list_widget.dart';
import 'package:audio_service/audio_service.dart';

class DownloadsDisplayWidget extends StatelessWidget {
  const DownloadsDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine Top Padding based on Platform
    final topPadding = GetPlatform.isDesktop 
        ? 30.0 
        : (GetPlatform.isAndroid || GetPlatform.isIOS) ? 15.0 : 35.0;

    // Fetch Downloads from Hive Box
    // "SongDownloads" box contains cached/downloaded items explicitly downloaded by user.
    if (!Hive.isBoxOpen("SongDownloads")) {
       return const Center(child: CircularProgressIndicator());
    }
    final downloadBox = Hive.box("SongDownloads");
    
    final List<MediaItem> downloads = downloadBox.values
        .map((e) {
          try {
            return MediaItemBuilder.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<MediaItem>()
        .toList();

    return Padding(
      padding: EdgeInsets.only(left: 5, top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: Text(
                "downloads".tr, // Ensure 'downloads' key exists in translation or use fallback
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          downloads.isNotEmpty
              ? ListWidget(
                  downloads,
                  "Downloads",
                  true, // isLibraryItem
                  isPlaylistOrAlbum: false,
                )
              : Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 60, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 10),
                        Text(
                          "noOfflineSong".tr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
