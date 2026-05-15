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

/// Server refused the request because the account's plan tier doesn't cover
/// the endpoint (e.g. Reports on a free plan). Raised by
/// [ApiClient._raiseFromResponse] when the server emits one of:
///   * HTTP 402 Payment Required
///   * HTTP 401/403 with `error_type: "plan_required"` in the JSON body
///
/// The sync engine marks dead — retrying won't upgrade the account. UIs
/// catch this to render an "Upgrade your plan" prompt instead of the
/// generic "Unauthorized" toast.
class PlanRequiredException extends ApiException {
  const PlanRequiredException([super.message = 'Plan upgrade required']);
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

/// Thrown by `ApiClient.uploadMultipartChunked` when the caller's
/// `isCancelled` callback returns true between chunks. Treat as a silent
/// stop — the UI initiated it, no toast needed.
class UploadCancelledException extends ApiException {
  const UploadCancelledException() : super('Upload cancelled');
}
