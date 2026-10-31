import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
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

/// Clients are tried in this order, one per request.
///
/// All three answer with plain `url` fields (no `signatureCipher`, no SABR),
/// which is the only kind this app can hand to just_audio without a JS
/// signature solver. Verified against the live endpoint: IOS and WEB now
/// return SABR-only formats, so they are deliberately not in this list.
const _clients = <YoutubeApiClient>[
  _visionOsClient,
  YoutubeApiClient.androidVr,
  YoutubeApiClient.androidSdkless,
];

/// User agent of each client, keyed by the `c=` value YouTube bakes into the
/// media URL. Used when re-checking a URL that a specific client minted.
final Map<String, String> _clientUserAgents = {
  for (final client in _clients)
    (client.payload['context']['client']['clientName'] as String):
        (client.payload['context']['client']['userAgent'] as String?) ?? '',
};

/// Thrown when YouTube answers `429` or its "sorry" bot page.
///
/// This is deliberately an [Error] and not an [Exception]: youtube_explode's
/// internal `retry()` only catches `Exception`, so an Error stops its
/// five-attempt loop on the first refusal. Without that, a single rate-limited
/// request was repeated three times for every client in the chain — nine
/// requests per song — which is exactly how a short block turns into a long one.
class _RateLimitedError extends Error {
  final String request;
  _RateLimitedError(this.request);

  @override
  String toString() => 'YouTube rate limited $request';
}

/// HTTP client shared by every extraction.
///
/// Besides aborting the retry storm above, it sends the media check (the
/// `HEAD` youtube_explode performs on the first stream URL) with the user
/// agent of the client that minted that URL. googlevideo compares the client
/// baked into the URL (`c=`) with the headers of the follow-up request and can
/// refuse a mismatch.
class _ExtractionHttpClient extends YoutubeHttpClient {
  _ExtractionHttpClient();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await super.send(request);
    if (response.statusCode == 429 ||
        request.url.path.startsWith('/sorry/')) {
      // Release the socket without waiting for the (small) error body.
      unawaited(response.stream.drain<void>().catchError((_) {}));
      throw _RateLimitedError('${request.method} ${request.url}');
    }
    return response;
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    final userAgent = _clientUserAgents[url.queryParameters['c']];
    return super.head(url, headers: {
      ...?headers,
      if (userAgent != null && userAgent.isNotEmpty)
        'User-Agent': userAgent,
    });
  }
}

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final List<VideoFormat>? videoFormats; // Add this
  final String statusMSG;
  StreamProvider(
      {required this.playable, this.audioFormats, this.videoFormats, this.statusMSG = ""});

  /// One long-lived extraction client for the whole process.
  ///
  /// Building a `YoutubeExplode` per request also built a fresh `http.Client`,
  /// so every song paid for a new TLS handshake with YouTube and the sockets
  /// were closed as soon as the URL was extracted. Reusing the client keeps the
  /// connection pool warm, which is a large part of why a player that talks to
  /// Innertube directly starts the next song noticeably faster.
  static YoutubeExplode? _client;

  static YoutubeExplode get _yt =>
      _client ??= YoutubeExplode(httpClient: _ExtractionHttpClient());

  /// Requests that are already running, so a pre-fetch and the playback path
  /// never resolve the same track twice.
  static final Map<String, Future<StreamProvider>> _inFlight = {};

  /// Clients that YouTube refused, and until when (app-wide).
  static final Map<String, DateTime> _standDownUntil = {};

  /// Distinct tracks each client has refused since it last served one.
  ///
  /// A single refusal is usually about the track, not the identity, so a client
  /// is only stood down app-wide after refusing several different tracks.
  static final Map<String, Set<String>> _refusalsByClient = {};

  /// Set after a `429`. While it is in the future, pre-fetching is paused so a
  /// blocked connection is not hammered with even more requests.
  static DateTime? _cooldownUntil;

  static bool get isCoolingDown =>
      _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);

  static String _clientKey(YoutubeApiClient client) {
    final c = client.payload['context']['client'];
    return '${c['clientName']}@${c['clientVersion']}';
  }

  static bool _isStoodDown(YoutubeApiClient client) {
    final key = _clientKey(client);
    final until = _standDownUntil[key];
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _standDownUntil.remove(key);
    return false;
  }

  static void _served(YoutubeApiClient client) {
    _refusalsByClient.remove(_clientKey(client));
    _cooldownUntil = null;
  }

  static void _refused(String videoId, YoutubeApiClient client) {
    final key = _clientKey(client);
    final tracks = _refusalsByClient.putIfAbsent(key, () => <String>{});
    tracks.add(videoId);
    if (tracks.length >= 3) {
      tracks.clear();
      _standDownUntil[key] = DateTime.now().add(const Duration(minutes: 10));
    }
  }

  /// Resolves [videoId] once, even if several callers ask for it at the same
  /// time (for example the pre-fetcher and the playback path).
  static Future<StreamProvider> fetch(String videoId) {
    final running = _inFlight[videoId];
    if (running != null) return running;

    final future =
        _resolve(videoId).whenComplete(() => _inFlight.remove(videoId));
    _inFlight[videoId] = future;
    return future;
  }

  static Future<StreamProvider> _resolve(String videoId) async {
    final candidates =
        _clients.where((client) => !_isStoodDown(client)).toList();
    if (candidates.isEmpty) {
      // Everything is stood down. Probe only the most reliable identity so a
      // listener who waited out the block can play again without restarting,
      // without re-forming the storm.
      candidates.add(_clients.first);
    }

    Object? lastError;
    var sawRateLimit = false;

    for (var i = 0; i < candidates.length; i++) {
      final client = candidates[i];
      StreamProvider? provider;
      var refusalRecorded = false;

      try {
        final res = await _yt.videos.streamsClient
            .getManifest(
              videoId,
              ytClients: [client],
              // The library only needs the watch page to run its JS challenge
              // solver, and this app never installs one. Fetching it anyway meant
              // every song waited for a full watch page (hundreds of KB) before the
              // small `youtubei/v1/player` request was even sent. Skipping it
              // removes that round-trip; the player response already contains the
              // stream URLs.
              requireWatchPage: false,
            )
            // A hung connection used to leave the player on its loading spinner
            // forever, because `package:http` has no timeout of its own. Fifteen
            // seconds is far longer than a healthy player request and short
            // enough that the next identity can still be tried.
            .timeout(const Duration(seconds: 15));
        provider = _fromManifest(res);
      } on VideoRequiresPurchaseException {
        return StreamProvider(
          playable: false,
          statusMSG: "Song requires purchase",
        );
      } on TimeoutException catch (e) {
        lastError = e;
        _refused(videoId, client);
        refusalRecorded = true;
      } on _RateLimitedError catch (e) {
        sawRateLimit = true;
        lastError = e;
        _refused(videoId, client);
        refusalRecorded = true;
        // Pause pre-fetching for a minute: the block is about the connection,
        // so extra requests only make it last longer.
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 60));
      } on SocketException catch (e) {
        // The network itself is down; another identity cannot help.
        lastError = e;
        break;
      } on YoutubeExplodeException catch (e) {
        lastError = e;
        _refused(videoId, client);
        refusalRecorded = true;
      } catch (e) {
        lastError = e;
        _refused(videoId, client);
        refusalRecorded = true;
      }

      if (provider != null) {
        _served(client);
        return provider;
      }
      // The request succeeded but the client answered without any audio the
      // player can use (SABR-only formats). Count that as a refusal so the
      // identity is rotated out instead of being tried first on every song.
      if (!refusalRecorded) _refused(videoId, client);

      // A short pause between identities. Firing all three in the same
      // millisecond is what YouTube reads as a burst.
      if (i < candidates.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    if (sawRateLimit) {
      return StreamProvider(
        playable: false,
        statusMSG:
            "YouTube is rate limiting this connection. Please wait a minute and try again.",
      );
    }
    if (lastError is SocketException || lastError is TimeoutException) {
      return StreamProvider(
        playable: false,
        statusMSG:
            "Could not reach YouTube. Check your connection and try again.",
      );
    }
    if (lastError is YoutubeExplodeException) {
      return StreamProvider(
        playable: false,
        statusMSG: _friendlyMessage(lastError, fallback: "Unknown error occurred"),
      );
    }
    return StreamProvider(
      playable: false,
      statusMSG: "Unknown error occurred",
    );
  }

  /// Builds the playable result, or null when the client returned no usable
  /// audio (some clients now answer with SABR-only formats).
  static StreamProvider? _fromManifest(StreamManifest res) {
    final audio = res.audioOnly;
    if (audio.isEmpty) return null;

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

  Audio? get highestQualityAudio {
    final formats = audioFormats;
    if (formats == null || formats.isEmpty) return null;
    return formats.lastWhere((item) => item.itag == 251 || item.itag == 140,
        orElse: () => formats.last);
  }

  Audio? get highestBitrateMp4aAudio {
    final formats = audioFormats;
    if (formats == null || formats.isEmpty) return null;
    return formats.lastWhere((item) => item.itag == 140 || item.itag == 139,
        orElse: () => formats.last);
  }

  Audio? get highestBitrateOpusAudio {
    final formats = audioFormats;
    if (formats == null || formats.isEmpty) return null;
    return formats.lastWhere((item) => item.itag == 251 || item.itag == 250,
        orElse: () => formats.last);
  }

  Audio? get lowQualityAudio {
    final formats = audioFormats;
    if (formats == null || formats.isEmpty) return null;
    return formats.lastWhere((item) => item.itag == 249 || item.itag == 139,
        orElse: () => formats.last);
  }

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

  factory Audio.fromJson(dynamic json) {
    final map = json is Map ? json : const <String, dynamic>{};
    final codec = map['audioCodec']?.toString() ?? '';
    return Audio(
      audioCodec: codec.contains('mp4a') ? Codec.mp4a : Codec.opus,
      itag: (map['itag'] as num?)?.toInt() ?? 0,
      duration: (map['approxDurationMs'] as num?)?.toInt() ?? 0,
      bitrate: (map['bitrate'] as num?)?.toInt() ?? 0,
      loudnessDb: (map['loudnessDb'] as num?)?.toDouble() ?? 0.0,
      url: map['url']?.toString() ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
    );
  }
}

enum Codec { mp4a, opus }

class VideoFormat {
  final String quality;
  final String url;
  final bool hasAudio;
  VideoFormat({required this.quality, required this.url, required this.hasAudio});
}
