import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

const _redactHeaderKeys = <String>{
  'authorization',
  'x-api-token',
  'x-api-secret',
  'x-api-password-base64',
  'x-api-oauth-password',
};

final _bodyRedactPattern = RegExp(
  r'("(?:password|token|secret|api_token|x_api_token|x_api_secret)")\s*:\s*"[^"]*"',
  caseSensitive: false,
);

/// Logger-name prefixes whose sub-WARNING records we drop on the floor.
///
/// super_editor + super_text_layout + attributed_text emit voluminous
/// FINE-level traces on every keystroke / layout pass / gesture; with
/// `Logger.root.level = Level.ALL` in debug they swamp our own logs.
/// Warnings/errors from these loggers still pass through (the `< WARNING`
/// gate below). Entries are dotted prefixes except `attributions`, which is
/// the bare logger name attributed_text uses (it is *not* `infrastructure.*`).
const _verboseLoggerPrefixes = <String>{
  'editor.', // super_editor edit-mode traces
  'reader.', // super_editor preview traces — reader.gestures etc.
  'textfield.', // super_editor text-field traces
  'document.', // super_editor document.gestures
  'infrastructure.', // super_editor infrastructure.* (incl. .attributions)
  'super_text.', // super_text_layout
  'attributions', // attributed_text package's bare 'attributions' logger
};

/// Initialize the root logger. Call once from `main()`.
void initLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (record.level < Level.WARNING &&
        _verboseLoggerPrefixes.any(record.loggerName.startsWith)) {
      return;
    }
    final message = redact(record.message);
    developer.log(
      message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}

/// Strip likely-sensitive substrings from a string before it's emitted.
///
/// Conservative — over-redacts in logs rather than risk leaking a token.
String redact(String input) {
  return input.replaceAllMapped(
    _bodyRedactPattern,
    (m) => '${m[1]}:"<redacted>"',
  );
}

/// Build a header map suitable for logging — sensitive header values are
/// replaced with `<redacted>`. The original map is not modified.
Map<String, String> redactHeaders(Map<String, String> headers) {
  return {
    for (final entry in headers.entries)
      entry.key: _redactHeaderKeys.contains(entry.key.toLowerCase())
          ? '<redacted>'
          : entry.value,
  };
}
