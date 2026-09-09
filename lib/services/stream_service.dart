import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Apple Vision Pro (VISIONOS) Innertube client.
///
/// Why this exists: since mid-2026 YouTube enforces PO-Tokens / JS signature
/// challenges on the classic extraction clients (IOS / ANDROID / ANDROID_VR /
/// TVHTML5) and answers their media URLs with `403`, which is exactly why
/// songs suddenly stopped playing (loading -> "refresh the page" error).
/// The VISIONOS client is still served without a PO-Token, the same client
/// yt-dlp switched to. Keeping it here (instead of waiting for library
/// updates) lets us react quickly the next time YouTube rotates clients —
/// just update the payload below.
///
/// References: Hexer10/youtube_explode_dart issues #386, #389, #390.
const _visionOsClient = YoutubeApiClient({
  'context': {
    'client': {
      'clientName': 'VISIONOS',
      'clientVersion': '1.02',
      'deviceMake': 'Apple',
      'deviceModel': 'RealityDevice17,1',
      'userAgent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
      'osName': 'visionOS',
      'osVersion': '26.5.23O471',
      'hl': 'en',
      'timeZone': 'UTC',
      'utcOffsetMinutes': 0,
    },
  },
}, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final List<VideoFormat>? videoFormats; // Add this
  final String statusMSG;
  StreamProvider(
      {required this.playable, this.audioFormats, this.videoFormats, this.statusMSG = ""});

  static Future<StreamProvider> fetch(String videoId) async {
    final yt = YoutubeExplode();

    try {
      // Client fallback chain. The first working client wins:
      // 1. VISIONOS  – no PO-Token / JS challenge required (see note above).
      // 2. androidSdkless – audio streams occasionally still work and gives
      //    us audio-only formats if YouTube rotates again.
      // 3. tv – last resort, works for some restricted videos.
      final res = await yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [
          _visionOsClient,
          YoutubeApiClient.androidSdkless,
          YoutubeApiClient.tv,
        ],
      );
      final audio = res.audioOnly;
      final muxed = res.muxed; // Get audio+video streams
      final videoOnly = res.videoOnly;

      final List<VideoFormat> availableVideoFormats = [];

      // Add muxed streams (has both audio and video)
      availableVideoFormats.addAll(muxed.map((e) => VideoFormat(
          quality: e.videoQuality.name,
          url: e.url.toString(),
          hasAudio: true)));

      // Add video-only streams if no muxed streams are found
      if (availableVideoFormats.isEmpty) {
        availableVideoFormats.addAll(videoOnly.map((e) => VideoFormat(
            quality: e.videoQuality.name,
            url: e.url.toString(),
            hasAudio: false)));
      }

      return StreamProvider(
          playable: true,
          statusMSG: "OK",
          audioFormats: audio
              .map((e) => Audio(
                  itag: e.tag,
                  audioCodec:
                      e.audioCodec.contains('mp') ? Codec.mp4a : Codec.opus,
                  bitrate: e.bitrate.bitsPerSecond,
                  // youtube_explode_dart v3 no longer exposes per-stream
                  // duration / loudness values, so keep sane defaults.
                  // (Duration comes from the MediaItem metadata anyway.)
                  duration: 0,
                  loudnessDb: 0,
                  url: e.url.toString(),
                  size: e.size.totalBytes))
              .toList(),
          videoFormats: availableVideoFormats);
    } catch (e) {
      if (e is SocketException) {
        return StreamProvider(
          playable: false,
          statusMSG: "networkError",
        );
      } else if (e is VideoRequiresPurchaseException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Song requires purchase",
        );
      } else if (e is VideoUnavailableException) {
        return StreamProvider(
          playable: false,
          statusMSG: "Song is unavailable",
        );
      } else if (e is VideoUnplayableException) {
        return StreamProvider(
          playable: false,
          statusMSG: _friendlyMessage(e, fallback: "Song is unplayable"),
        );
      } else if (e is YoutubeExplodeException) {
        return StreamProvider(
          playable: false,
          statusMSG: _friendlyMessage(e, fallback: "Unknown error occurred"),
        );
      } else {
        return StreamProvider(
          playable: false,
          statusMSG: "Unknown error occurred",
        );
      }
    } finally {
      yt.close();
    }
  }

  /// Extracts the short human-readable reason from a youtube_explode error
  /// (e.g. "Reason: Sign in to confirm you're not a bot") so the snackbar
  /// shows a clean message instead of a multi-line stack dump.
  static String _friendlyMessage(YoutubeExplodeException e,
      {required String fallback}) {
    final message = e.message;
    final idx = message.lastIndexOf('Reason:');
    if (idx != -1) {
      final reason = message.substring(idx + 7).trim();
      if (reason.isNotEmpty) return reason;
    }
    final firstLine =
        message.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return firstLine.isNotEmpty ? firstLine.trim() : fallback;
  }

  Audio? get highestQualityAudio =>
      audioFormats?.lastWhere((item) => item.itag == 251 || item.itag == 140,
          orElse: () => audioFormats!.first);

  Audio? get highestBitrateMp4aAudio =>
      audioFormats?.lastWhere((item) => item.itag == 140 || item.itag == 139,
          orElse: () => audioFormats!.first);

  Audio? get highestBitrateOpusAudio =>
      audioFormats?.lastWhere((item) => item.itag == 251 || item.itag == 250,
          orElse: () => audioFormats!.first);

  Audio? get lowQualityAudio =>
      audioFormats?.lastWhere((item) => item.itag == 249 || item.itag == 139,
          orElse: () => audioFormats!.first);

  VideoFormat? get highestQualityVideo {
    if (videoFormats == null || videoFormats!.isEmpty) return null;

    // Prefer 360p or 480p for faster loading, fallback to lowest quality
    final preferred = videoFormats!.where((v) => v.quality.contains('360') || v.quality.contains('480')).toList();
    if (preferred.isNotEmpty) {
      return preferred.last; // Last is usually the better of the preferred if sorted by lowest to highest
    }
    return videoFormats!.first;
  }

  Map<String, dynamic> get smStreamingData {
    return {
      "playable": playable,
      "statusMSG": statusMSG,
      "lowQualityAudio": lowQualityAudio?.toJson(),
      "highQualityAudio": highestQualityAudio?.toJson(),
      "highestQualityVideoUrl": highestQualityVideo?.url,
      "videoHasAudio": highestQualityVideo?.hasAudio ?? false
    };
  }
}

class Audio {
  final int itag;
  final Codec audioCodec;
  final int bitrate;
  final int duration;
  final double loudnessDb;
  final String url;
  final int size;

  Audio({
    required this.itag,
    required this.audioCodec,
    required this.bitrate,
    required this.duration,
    required this.loudnessDb,
    required this.url,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        "itag": itag,
        "audioCodec": audioCodec.toString(),
        "bitrate": bitrate,
        "loudnessDb": loudnessDb,
        "url": url,
        "approxDurationMs": duration,
        "size": size
      };

  factory Audio.fromJson(json) => Audio(
      audioCodec: (json["audioCodec"] as String).contains("mp4a")
          ? Codec.mp4a
          : Codec.opus,
      itag: json['itag'],
      duration: json["approxDurationMs"] ?? 0,
      bitrate: json["bitrate"] ?? 0,
      loudnessDb: (json['loudnessDb'])?.toDouble() ?? 0.0,
      url: json['url'],
      size: json["size"] ?? 0);
}

enum Codec { mp4a, opus }

class VideoFormat {
  final String quality;
  final String url;
  final bool hasAudio;
  VideoFormat({required this.quality, required this.url, required this.hasAudio});
}
