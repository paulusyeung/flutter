import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/app/logging.dart' show redact, redactHeaders;

/// In-memory capture of recent HTTP traffic and runtime errors, surfaced by
/// the hidden Debug Panel under Settings → System Logs. Lives in release
/// builds too — that's the whole point: a user hitting a bug in prod can flip
/// the toggle, reproduce, and share what they see.
///
/// Storage is intentionally in-memory only — no disk persistence, no
/// `SharedPreferences`. The `enabled` flag resets to `false` on every app
/// launch, so the panel is opt-in per session.
///
/// All inputs flow through `redact()` / `redactHeaders()` before they hit the
/// ring buffers, so the store never holds a non-redacted token, password, or
/// secret.
class DebugCaptureStore extends ChangeNotifier {
  DebugCaptureStore();

  static const int _networkCapacity = 200;
  static const int _diagnosticCapacity = 200;
  static const int _bodyCapBytes = 32 * 1024;

  bool _enabled = false;
  int _nextRequestId = 1;
  final Map<int, _PendingRequest> _pending = {};
  final Queue<NetworkCaptureEntry> _network = Queue<NetworkCaptureEntry>();
  final Queue<DiagnosticCaptureEntry> _diagnostics =
      Queue<DiagnosticCaptureEntry>();

  /// Whether capture is currently active.
  bool get enabled => _enabled;

  /// Flip capture on / off. Toggling off pauses recording but leaves
  /// already-captured entries in place so the user can still inspect what
  /// was captured. Use [clear] to explicitly wipe the rings. Pending
  /// in-flight requests are dropped on disable since they can no longer be
  /// completed cleanly.
  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!_enabled) {
      _pending.clear();
    }
    notifyListeners();
  }

  /// Newest-first view of recent network entries.
  List<NetworkCaptureEntry> get networkEntries =>
      List.unmodifiable(_network.toList().reversed);

  /// Newest-first view of recent diagnostic (error / warning) entries.
  List<DiagnosticCaptureEntry> get diagnosticEntries =>
      List.unmodifiable(_diagnostics.toList().reversed);

  /// Drop every captured entry. Leaves the `enabled` flag alone.
  void clear() {
    if (_pending.isEmpty && _network.isEmpty && _diagnostics.isEmpty) return;
    _pending.clear();
    _network.clear();
    _diagnostics.clear();
    notifyListeners();
  }

  /// Record the start of an HTTP request. Returns an id the caller passes
  /// back to [completeRequest] or [failRequest]. Returns `null` when capture
  /// is disabled — the caller can plumb the nullable id through without a
  /// per-call guard.
  int? beginRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    String? requestBody,
  }) {
    if (!_enabled) return null;
    final id = _nextRequestId++;
    _pending[id] = _PendingRequest(
      id: id,
      startedAt: DateTime.now(),
      method: method,
      url: url,
      headers: redactHeaders(headers),
      requestBody: requestBody == null ? null : _capBody(redact(requestBody)),
    );
    return id;
  }

  /// Record the response for a previously-begun request. No-op when [id] is
  /// null or unknown (e.g. capture was toggled off mid-request).
  void completeRequest(
    int? id, {
    required int statusCode,
    required Duration duration,
    String? responseBody,
    Map<String, String>? responseHeaders,
  }) {
    if (id == null) return;
    final pending = _pending.remove(id);
    if (pending == null) return;
    _push(
      NetworkCaptureEntry._(
        id: pending.id,
        startedAt: pending.startedAt,
        method: pending.method,
        url: pending.url,
        requestHeaders: pending.headers,
        requestBody: pending.requestBody,
        statusCode: statusCode,
        duration: duration,
        responseBody:
            responseBody == null ? null : _capBody(redact(responseBody)),
        responseHeaders:
            responseHeaders == null ? null : redactHeaders(responseHeaders),
        error: null,
      ),
    );
  }

  /// Record a failure for a previously-begun request (network error, decode
  /// failure, etc.). No-op when [id] is null or unknown.
  void failRequest(
    int? id, {
    required Duration duration,
    required Object error,
  }) {
    if (id == null) return;
    final pending = _pending.remove(id);
    if (pending == null) return;
    _push(
      NetworkCaptureEntry._(
        id: pending.id,
        startedAt: pending.startedAt,
        method: pending.method,
        url: pending.url,
        requestHeaders: pending.headers,
        requestBody: pending.requestBody,
        statusCode: null,
        duration: duration,
        responseBody: null,
        responseHeaders: null,
        error: redact(error.toString()),
      ),
    );
  }

  /// Capture an uncaught error. Safe to call from any zone.
  void recordError(Object error, StackTrace? stack, {String? context}) {
    if (!_enabled) return;
    _pushDiagnostic(
      DiagnosticCaptureEntry._(
        time: DateTime.now(),
        level: 'ERROR',
        loggerName: context,
        message: redact(error.toString()),
        stack: stack?.toString(),
      ),
    );
  }

  /// Capture a `Logger` record. Caller is responsible for filtering by level
  /// (the wiring in `main.dart` only forwards WARNING+).
  void recordLog(LogRecord r) {
    if (!_enabled) return;
    final message = StringBuffer(redact(r.message));
    if (r.error != null) {
      message
        ..write(' :: ')
        ..write(redact(r.error.toString()));
    }
    _pushDiagnostic(
      DiagnosticCaptureEntry._(
        time: r.time,
        level: r.level.name,
        loggerName: r.loggerName,
        message: message.toString(),
        stack: r.stackTrace?.toString(),
      ),
    );
  }

  void _push(NetworkCaptureEntry entry) {
    _network.addLast(entry);
    while (_network.length > _networkCapacity) {
      _network.removeFirst();
    }
    notifyListeners();
  }

  void _pushDiagnostic(DiagnosticCaptureEntry entry) {
    _diagnostics.addLast(entry);
    while (_diagnostics.length > _diagnosticCapacity) {
      _diagnostics.removeFirst();
    }
    notifyListeners();
  }

  static String _capBody(String body) {
    if (body.length <= _bodyCapBytes) return body;
    final head = body.substring(0, _bodyCapBytes);
    return '$head\n…<truncated, ${body.length} chars total>';
  }
}

class _PendingRequest {
  _PendingRequest({
    required this.id,
    required this.startedAt,
    required this.method,
    required this.url,
    required this.headers,
    required this.requestBody,
  });

  final int id;
  final DateTime startedAt;
  final String method;
  final String url;
  final Map<String, String> headers;
  final String? requestBody;
}

/// One completed (or failed) HTTP round-trip captured by [DebugCaptureStore].
class NetworkCaptureEntry {
  NetworkCaptureEntry._({
    required this.id,
    required this.startedAt,
    required this.method,
    required this.url,
    required this.requestHeaders,
    required this.requestBody,
    required this.statusCode,
    required this.duration,
    required this.responseBody,
    required this.responseHeaders,
    required this.error,
  });

  final int id;
  final DateTime startedAt;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final String? requestBody;

  /// `null` when [error] is set (request failed before a response landed).
  final int? statusCode;
  final Duration duration;
  final String? responseBody;
  final Map<String, String>? responseHeaders;

  /// Non-null when the request threw (e.g. `NetworkException`,
  /// `ServerException`). Already redacted.
  final String? error;

  bool get succeeded =>
      error == null && statusCode != null && statusCode! < 400;
}

/// One captured diagnostic record (uncaught error or WARNING+ logger record).
class DiagnosticCaptureEntry {
  DiagnosticCaptureEntry._({
    required this.time,
    required this.level,
    required this.loggerName,
    required this.message,
    required this.stack,
  });

  final DateTime time;
  final String level;
  final String? loggerName;
  final String message;
  final String? stack;
}
