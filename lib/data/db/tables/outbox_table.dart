import 'package:drift/drift.dart';

/// Mutation queue. Every write goes through here.
///
/// `mutation_kind` is free-form TEXT so new actions (`upload`,
/// `action:send_email`, `action:mark_paid`, etc.) can land without a schema
/// migration. `idempotency_key` is generated when the row is created and
/// reused on every retry — never regenerated.
///
/// `state` is one of `pending | in_flight | dead`. Dead rows surface on the
/// Outbox screen for user action (edit-to-fix, discard).
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get companyId => text().named('company_id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get mutationKind => text().named('mutation_kind')();
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text().named('idempotency_key')();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().named('next_attempt_at')();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().named('last_error').nullable()();
  IntColumn get lastStatusCode =>
      integer().named('last_status_code').nullable()();

  /// JSON-encoded `Map<String, List<String>>` keyed by API field name. Set
  /// alongside `last_error` when a 422 marks the row dead, so the Outbox
  /// screen and the edit form can replay per-field errors after restart.
  /// Null on non-422 rows.
  TextColumn get fieldErrorsJson =>
      text().named('field_errors_json').nullable()();
  BoolColumn get requiresPassword =>
      boolean().named('requires_password').withDefault(const Constant(false))();
  TextColumn get batchId => text().named('batch_id').nullable()();
  IntColumn get createdAt => integer().named('created_at')();
}
