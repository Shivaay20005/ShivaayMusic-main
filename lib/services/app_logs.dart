import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// File-backed logger.
///
/// Why this exists: on a release build `printINFO`/`printERROR` are compiled
/// out (`kReleaseMode` early-return) and Android hides another app's logcat
/// from a normal app anyway, so a user reporting "songs do not play" had no way
/// to send us what actually happened. Everything written here is appended to a
/// plain text file in the app's own documents directory and can be shared from
/// Settings -> Music & Playback -> Diagnostics -> Share logs.
///
/// Design notes:
/// * Never throws. A logging failure must not break playback.
/// * Writes are serialised through a single future chain, so concurrent
///   callers cannot interleave and corrupt lines.
/// * Logs written before [init] finishes are buffered and flushed afterwards.
/// * The file is rotated once it grows past [_maxBytes], so it cannot grow
///   without bound on a long-running player.
class AppLogs {
  AppLogs._();

  /// Rotate when the file passes this size; the newest ~75% of it is kept.
  static const int _maxBytes = 3 * 1024 * 1024;

  static File? _file;
  static bool _ready = false;
  static bool _initialising = false;

  /// Lines waiting to be written, and whether a flush is already scheduled.
  static final List<String> _pending = <String>[];
  static bool _flushScheduled = false;
  static Future<void> _chain = Future<void>.value();

  /// Simple rate limit so a chatty listener cannot turn logging into jank.
  static const int _maxLinesPerSecond = 200;
  static int _windowStartMs = 0;
  static int _windowCount = 0;

  static bool get isReady => _ready;

  /// Resolves the log file and starts recording. Call once during startup.
  static Future<void> init() async {
    if (_ready || _initialising) return;
    _initialising = true;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/logs');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _file = File('${dir.path}/app_logs.txt');
      _ready = true;
      write('logs', '===== session started =====');
      _flushNow();
    } catch (e) {
      // Documented failure path: keep the app running, logs stay in memory.
      debugPrint('AppLogs.init failed: $e');
    } finally {
      _initialising = false;
    }
  }

  /// Appends one line. Safe to call from anywhere, including before [init].
  static void write(String tag, Object? message) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _windowStartMs > 1000) {
      _windowStartMs = nowMs;
      _windowCount = 0;
    }
    if (_windowCount >= _maxLinesPerSecond) {
      if (_windowCount == _maxLinesPerSecond) {
        _pending.add(
            '${DateTime.now().toIso8601String()} [logs] throttled (>$_maxLinesPerSecond lines/s)');
      }
      _windowCount++;
      _scheduleFlush();
      return;
    }
    _windowCount++;

    final line = '${DateTime.now().toIso8601String()} [$tag] $message';
    if (_pending.length < 4000) _pending.add(line);
    _scheduleFlush();
  }

  /// Convenience wrapper that includes the stack trace of a caught error.
  static void error(String tag, Object error, [StackTrace? stack]) {
    write(tag, 'ERROR $error${stack == null ? '' : '\n$stack'}');
  }

  /// Coalesces writes into one disk hit per [Duration] instead of one per line.
  static void _scheduleFlush() {
    if (!_ready || _file == null || _pending.isEmpty || _flushScheduled) return;
    _flushScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      _flushScheduled = false;
      _flushNow();
    });
  }

  static void _flushNow() {
    if (!_ready || _file == null || _pending.isEmpty) return;
    final batch = '${_pending.join('\n')}\n';
    _pending.clear();

    _chain = _chain.then((_) async {
      final file = _file;
      if (file == null) return;
      try {
        await file.writeAsString(batch, mode: FileMode.append, flush: false);
        await _rotateIfNeeded(file);
      } catch (_) {
        // Disk full / permission revoked: drop the batch rather than crash.
      }
    });
  }

  static Future<void> _rotateIfNeeded(File file) async {
    try {
      if (!await file.exists()) return;
      if (await file.length() <= _maxBytes) return;
      final content = await file.readAsString();
      final keepFrom = content.length - (_maxBytes * 3 ~/ 4);
      final slice = content.substring(keepFrom < 0 ? 0 : keepFrom);
      final firstNewline = slice.indexOf('\n');
      final kept = firstNewline >= 0 ? slice.substring(firstNewline + 1) : slice;
      await file.writeAsString(kept, flush: true);
    } catch (_) {
      // Rotation is best-effort; a failed rotation only means a bigger file.
    }
  }

  /// Current contents, or an empty string when nothing has been recorded.
  static Future<String> read() async {
    try {
      _flushNow();
      await _chain;
      final file = _file;
      if (file == null || !await file.exists()) return '';
      return await file.readAsString();
    } catch (_) {
      return '';
    }
  }

  static Future<String?> path() async {
    _flushNow();
    await _chain;
    return _file?.path;
  }

  static Future<void> clear() async {
    _pending.clear();
    try {
      await _chain;
      await _file?.writeAsString('', flush: true);
    } catch (_) {}
  }

  /// Opens the Android share sheet with the log file attached.
  ///
  /// Returns false when there is nothing to share (or the platform refused),
  /// so the caller can show a useful message instead of an empty sheet.
  static Future<bool> share({String subject = 'ShivaayMusic logs'}) async {
    try {
      _flushNow();
      await _chain;
      final file = _file;
      if (file == null || !await file.exists()) return false;
      if (await file.length() == 0) return false;
      await Share.shareXFiles([XFile(file.path)], subject: subject);
      return true;
    } catch (e) {
      debugPrint('AppLogs.share failed: $e');
      return false;
    }
  }
}
