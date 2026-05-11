/// Typed errors thrown by [ApiClient].
///
/// The sync engine pattern-matches on these to decide whether to retry, mark
/// dead, or surface a UI prompt. Adding a new error case means updating both
/// `ApiClient._raiseFromResponse` and the corresponding sync-engine branch.
sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

/// Server demands re-auth with the user's password (e.g. on delete / purge).
class PasswordRequiredException extends ApiException {
  const PasswordRequiredException([super.message = 'Password required']);
}

/// 422 — validation failure. [fieldErrors] is `{ fieldName: [msg, ...] }`.
class ValidationException extends ApiException {
  const ValidationException(super.message, this.fieldErrors);
  final Map<String, List<String>> fieldErrors;
}

class ConflictException extends ApiException {
  const ConflictException([super.message = 'Conflict']);
}

class ClientTooOldException extends ApiException {
  const ClientTooOldException({
    required this.minRequiredVersion,
    required this.currentVersion,
  }) : super('Client too old');
  final String minRequiredVersion;
  final String currentVersion;
}

class RateLimitedException extends ApiException {
  const RateLimitedException({this.retryAfter, String message = 'Rate limited'})
    : super(message);
  final Duration? retryAfter;
}

class ServerException extends ApiException {
  const ServerException(this.statusCode, [String message = 'Server error'])
    : super(message);
  final int statusCode;
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// Demo builds short-circuit non-GET requests; this is the error the UI
/// surfaces to explain the no-op.
class DemoModeException extends ApiException {
  const DemoModeException() : super('Demo mode — changes are not saved.');
}
