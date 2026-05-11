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

/// Initialize the root logger. Call once from `main()`.
void initLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
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
  return input.replaceAllMapped(_bodyRedactPattern, (m) => '${m[1]}:"<redacted>"');
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
