import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_check_api_model.freezed.dart';
part 'health_check_api_model.g.dart';

/// Shape of `GET /api/v1/health_check`. Self-hosted diagnostic endpoint that
/// reports server-side environment status (PHP, queue, mail, PDF engine, file
/// permissions, etc.). Fetched once per dialog open; never persisted.
@freezed
abstract class HealthCheckResponse with _$HealthCheckResponse {
  const factory HealthCheckResponse({
    @JsonKey(name: 'system_health') @Default(false) bool systemHealth,
    @JsonKey(name: 'simple_db_check') @Default(false) bool dbCheck,
    @JsonKey(name: 'php_version')
    @Default(HealthCheckPhpResponse())
    HealthCheckPhpResponse phpVersion,
    @JsonKey(name: 'queue_data')
    @Default(HealthCheckQueueResponse())
    HealthCheckQueueResponse queueData,
    @Default('') String queue,
    @JsonKey(name: 'mail_mailer') @Default('') String emailDriver,
    @JsonKey(name: 'pdf_engine') @Default('') String pdfEngine,
    @JsonKey(name: 'file_permissions') @Default('') String filePermissions,
    @JsonKey(name: 'trailing_slash') @Default(false) bool trailingSlash,
    @JsonKey(name: 'exchange_rate_api_not_configured')
    @Default(false)
    bool exchangeRateApiNotConfigured,
    @JsonKey(name: 'pending_migration') @Default(false) bool pendingMigration,
    @JsonKey(name: 'cache_enabled') @Default(false) bool cacheEnabled,
    @JsonKey(name: 'env_writable') @Default(false) bool envWritable,
    @JsonKey(name: 'open_basedir') @Default(false) bool openBasedir,
    @JsonKey(name: 'exec') @Default(false) bool execEnabled,
    @JsonKey(name: 'phantom_enabled') @Default(false) bool phantomEnabled,
    @JsonKey(name: 'jobs_pending') @Default(0) int pendingJobs,
  }) = _HealthCheckResponse;

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckResponseFromJson(json);
}

@freezed
abstract class HealthCheckPhpResponse with _$HealthCheckPhpResponse {
  const factory HealthCheckPhpResponse({
    @JsonKey(name: 'current_php_version')
    @Default('')
    String currentPhpVersion,
    @JsonKey(name: 'current_php_cli_version')
    @Default('')
    String currentPhpCliVersion,
    @JsonKey(name: 'minimum_php_version')
    @Default('')
    String minimumPhpVersion,
    @JsonKey(name: 'is_okay') @Default(false) bool isOkay,
    @JsonKey(name: 'memory_limit') @Default('') String memoryLimit,
  }) = _HealthCheckPhpResponse;

  factory HealthCheckPhpResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckPhpResponseFromJson(json);
}

@freezed
abstract class HealthCheckQueueResponse with _$HealthCheckQueueResponse {
  const factory HealthCheckQueueResponse({
    @Default(0) int pending,
    @Default(0) int failed,
    @JsonKey(name: 'last_error') @Default('') String lastError,
  }) = _HealthCheckQueueResponse;

  factory HealthCheckQueueResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckQueueResponseFromJson(json);
}

/// Shape of `GET /api/v1/last_error`. Server-side capture of the most recent
/// uncaught exception or stack trace. Empty when no error is on file.
@freezed
abstract class HealthCheckLastErrorResponse
    with _$HealthCheckLastErrorResponse {
  const factory HealthCheckLastErrorResponse({
    @JsonKey(name: 'last_error') @Default('') String lastError,
  }) = _HealthCheckLastErrorResponse;

  factory HealthCheckLastErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckLastErrorResponseFromJson(json);
}
