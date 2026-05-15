// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_check_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthCheckResponse _$HealthCheckResponseFromJson(Map<String, dynamic> json) =>
    _HealthCheckResponse(
      systemHealth: json['system_health'] as bool? ?? false,
      dbCheck: json['simple_db_check'] as bool? ?? false,
      phpVersion: json['php_version'] == null
          ? const HealthCheckPhpResponse()
          : HealthCheckPhpResponse.fromJson(
              json['php_version'] as Map<String, dynamic>,
            ),
      queueData: json['queue_data'] == null
          ? const HealthCheckQueueResponse()
          : HealthCheckQueueResponse.fromJson(
              json['queue_data'] as Map<String, dynamic>,
            ),
      queue: json['queue'] as String? ?? '',
      emailDriver: json['mail_mailer'] as String? ?? '',
      pdfEngine: json['pdf_engine'] as String? ?? '',
      filePermissions: json['file_permissions'] as String? ?? '',
      trailingSlash: json['trailing_slash'] as bool? ?? false,
      exchangeRateApiNotConfigured:
          json['exchange_rate_api_not_configured'] as bool? ?? false,
      pendingMigration: json['pending_migration'] as bool? ?? false,
      cacheEnabled: json['cache_enabled'] as bool? ?? false,
      envWritable: json['env_writable'] as bool? ?? false,
      openBasedir: json['open_basedir'] as bool? ?? false,
      execEnabled: json['exec'] as bool? ?? false,
      phantomEnabled: json['phantom_enabled'] as bool? ?? false,
      pendingJobs: (json['jobs_pending'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$HealthCheckResponseToJson(
  _HealthCheckResponse instance,
) => <String, dynamic>{
  'system_health': instance.systemHealth,
  'simple_db_check': instance.dbCheck,
  'php_version': instance.phpVersion,
  'queue_data': instance.queueData,
  'queue': instance.queue,
  'mail_mailer': instance.emailDriver,
  'pdf_engine': instance.pdfEngine,
  'file_permissions': instance.filePermissions,
  'trailing_slash': instance.trailingSlash,
  'exchange_rate_api_not_configured': instance.exchangeRateApiNotConfigured,
  'pending_migration': instance.pendingMigration,
  'cache_enabled': instance.cacheEnabled,
  'env_writable': instance.envWritable,
  'open_basedir': instance.openBasedir,
  'exec': instance.execEnabled,
  'phantom_enabled': instance.phantomEnabled,
  'jobs_pending': instance.pendingJobs,
};

_HealthCheckPhpResponse _$HealthCheckPhpResponseFromJson(
  Map<String, dynamic> json,
) => _HealthCheckPhpResponse(
  currentPhpVersion: json['current_php_version'] as String? ?? '',
  currentPhpCliVersion: json['current_php_cli_version'] as String? ?? '',
  minimumPhpVersion: json['minimum_php_version'] as String? ?? '',
  isOkay: json['is_okay'] as bool? ?? false,
  memoryLimit: json['memory_limit'] as String? ?? '',
);

Map<String, dynamic> _$HealthCheckPhpResponseToJson(
  _HealthCheckPhpResponse instance,
) => <String, dynamic>{
  'current_php_version': instance.currentPhpVersion,
  'current_php_cli_version': instance.currentPhpCliVersion,
  'minimum_php_version': instance.minimumPhpVersion,
  'is_okay': instance.isOkay,
  'memory_limit': instance.memoryLimit,
};

_HealthCheckQueueResponse _$HealthCheckQueueResponseFromJson(
  Map<String, dynamic> json,
) => _HealthCheckQueueResponse(
  pending: (json['pending'] as num?)?.toInt() ?? 0,
  failed: (json['failed'] as num?)?.toInt() ?? 0,
  lastError: json['last_error'] as String? ?? '',
);

Map<String, dynamic> _$HealthCheckQueueResponseToJson(
  _HealthCheckQueueResponse instance,
) => <String, dynamic>{
  'pending': instance.pending,
  'failed': instance.failed,
  'last_error': instance.lastError,
};

_HealthCheckLastErrorResponse _$HealthCheckLastErrorResponseFromJson(
  Map<String, dynamic> json,
) => _HealthCheckLastErrorResponse(
  lastError: json['last_error'] as String? ?? '',
);

Map<String, dynamic> _$HealthCheckLastErrorResponseToJson(
  _HealthCheckLastErrorResponse instance,
) => <String, dynamic>{'last_error': instance.lastError};
