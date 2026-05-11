import 'package:admin/domain/sync/entity_type.dart' show EntityType;

/// Events the sync engine emits for the UI to react to. The shell subscribes
/// and routes each to the appropriate sheet/badge.
sealed class SyncEvent {
  const SyncEvent({required this.entityType, required this.entityId});
  final EntityType entityType;
  final String entityId;
}

/// 422 — the server permanently rejected the payload. The Outbox screen
/// shows the row; the user must edit or discard.
class ValidationFailedEvent extends SyncEvent {
  const ValidationFailedEvent({
    required super.entityType,
    required super.entityId,
    required this.fieldErrors,
    required this.message,
  });
  final Map<String, List<String>> fieldErrors;
  final String message;
}

/// 409 — server has newer data. `ConflictResolutionSheet` opens.
class ConflictEvent extends SyncEvent {
  const ConflictEvent({
    required super.entityType,
    required super.entityId,
    required this.message,
  });
  final String message;
}

/// 403 password-required — `ConfirmPasswordSheet` opens.
class PasswordRequiredEvent extends SyncEvent {
  const PasswordRequiredEvent({
    required super.entityType,
    required super.entityId,
  });
}

/// Row gave up after the max retry count. Sits on the Outbox screen until
/// the user retries or discards.
class DeadEvent extends SyncEvent {
  const DeadEvent({
    required super.entityType,
    required super.entityId,
    required this.message,
    required this.statusCode,
  });
  final String message;
  final int? statusCode;
}
