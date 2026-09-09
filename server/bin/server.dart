// ShivaayMusic website backend.
//
// Endpoints:
//   GET /healthcheck            -> service status
//   GET /api/search?q=<query>   -> list of songs (id/title/author/thumb/duration)
//   GET /api/stream/<videoId>   -> fresh playable audio stream URL (cached ~5.5h)
//   GET /api/proxy/<videoId>    -> same, but bytes are piped through this server
//                                  (use when the browser IP differs from the
//                                  server IP and YouTube answers 403)
//
// No YouTube API key is used anywhere — stream URLs are extracted with
// youtube_explode_dart using the logged-out VISIONOS client, exactly like the
// ShivaayMusic app fix.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Apple Vision Pro (VISIONOS) Innertube client — currently served by YouTube
/// without PO-Token / JS challenges (same payload the app uses).
/// If YouTube rotates clients again, update only this payload.
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

/// Fallback chain if VISIONOS ever starts failing.
const _clients = [
  _visionOsClient,
  YoutubeApiClient.androidSdkless,
  YoutubeApiClient.tv,
];

final _yt = YoutubeExplode();

/// stream URLs stay valid ~6h; cache for 5.5h per videoId.
const _cacheTtl = Duration(minutes: 330);
final Map<String, ({DateTime expiresAt, Map<String, Object?> payload})>
    _streamCache = {};

Response _json(Object body, {int status = 200}) => Response(status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'});

Middleware _cors() => createMiddleware(requestHandler: (request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      return null;
    }, responseHandler: (response) {
      return response.change(headers: _corsHeaders);
    });

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, OPTIONS',
  'access-control-allow-headers': 'content-type',
};

Future<Response> _health(Request request) => Future.value(_json({
      'status': 'ok',
      'service': 'shivaaymusic-server',
      'time': DateTime.now().toUtc().toIso8601String(),
    }));

Future<Response> _search(Request request) async {
  final query = (request.url.queryParameters['q'] ?? '').trim();
  if (query.isEmpty) {
    return _json({'error': "missing query parameter 'q'"}, status: 400);
  }
  try {
    final results = await _yt.search.search(query);
    final items = results
        .take(20)
        .map((v) => {
              'id': v.id.value,
              'title': v.title,
              'author': v.author,
              'duration': v.duration?.inSeconds,
              'thumbnail': v.thumbnails.mediumResUrl,
              'isLive': v.isLive,
            })
        .toList();
    return _json({'query': query, 'results': items});
  } catch (e) {
    return _json({'error': 'search failed: $e'}, status: 502);
  }
}

/// Resolves (and caches) the best audio stream URL for [videoId].
Future<Map<String, Object?>> _bestAudio(String videoId) async {
  final cached = _streamCache[videoId];
  if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
    return {...cached.payload, 'cached': true};
  }

  final manifest =
      await _yt.videos.streamsClient.getManifest(videoId, ytClients: _clients);

  final audios = manifest.audioOnly.toList()
    ..sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

  if (audios.isEmpty) {
    throw StateError('No audio streams available for this video.');
  }

  // Prefer the usual music itags (251 = opus ~160kbps, 140 = m4a ~128kbps).
  final best = audios.firstWhere(
    (a) => a.tag == 251 || a.tag == 140,
    orElse: () => audios.first,
  );

  final payload = <String, Object?>{
    'id': videoId,
    'url': best.url.toString(),
    'itag': best.tag,
    'codec': best.audioCodec,
    'bitrateKbps': (best.bitrate.bitsPerSecond / 1000).round(),
    'sizeBytes': best.size.totalBytes,
    'cached': false,
  };
  _streamCache[videoId] = (
    expiresAt: DateTime.now().add(_cacheTtl),
    payload: payload
  );
  return payload;
}

Future<Response> _stream(Request request, String videoId) async {
  try {
    return _json(await _bestAudio(videoId));
  } catch (e) {
    return _json({'error': 'could not resolve stream: $e'}, status: 502);
  }
}

final _proxyHttp = HttpClient()..autoUncompress = false;

const _proxyForwardHeaders = {
  'content-type',
  'content-length',
  'content-range',
  'accept-ranges',
};

Future<Response> _proxy(Request request, String videoId) async {
  try {
    final info = await _bestAudio(videoId);
    final upstream =
        await _proxyHttp.getUrl(Uri.parse(info['url'] as String));
    final range = request.headers['range'];
    if (range != null) upstream.headers.set('range', range);
    final upstreamRes = await upstream.close();

    final headers = <String, Object>{};
    upstreamRes.headers.forEach((name, values) {
      if (_proxyForwardHeaders.contains(name)) {
        headers[name] = values.join(',');
      }
    });
    headers['access-control-allow-origin'] = '*';

    return Response(upstreamRes.statusCode, body: upstreamRes, headers: headers);
  } catch (e) {
    return _json({'error': 'proxy failed: $e'}, status: 502);
  }
}

Future<void> main() async {
  final router = Router()
    ..get('/', _health)
    ..get('/healthcheck', _health)
    ..get('/api/search', _search)
    ..get('/api/stream/<videoId>', _stream)
    ..get('/api/proxy/<videoId>', _proxy);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('shivaaymusic-server listening on http://0.0.0.0:${server.port}');
}
