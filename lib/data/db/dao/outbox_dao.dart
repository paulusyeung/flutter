import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/tables/outbox_table.dart';
import 'package:admin/domain/sync/mutation.dart';

part 'outbox_dao.g.dart';

/// `state` values: `pending | in_flight | dead`.
enum OutboxState { pending, inFlight, dead }

@DriftAccessor(tables: [Outbox])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  Future<int> enqueue(OutboxCompanion row) => into(outbox).insert(row);

  /// One-shot count of non-`dead` rows for [companyId]. The picker uses this
  /// to decide whether a company switch needs a "you have unsaved changes"
  /// confirmation; the streaming variant below feeds badges that refresh
  /// continuously.
  Future<int> pendingCountForCompany(String companyId) async {
    final count = outbox.id.count();
    final q = selectOnly(outbox)
      ..addColumns([count])
      ..where(
        outbox.companyId.equals(companyId) & outbox.state.equals('pending'),
      );
    final row = await q.getSingle();
    return row.read(count) ?? 0;
  }

  /// Delete every non-`dead` row for [companyId]. Used by the "Discard" branch
  /// of the confirm-before-switch dialog.
  Future<int> deletePendingForCompany(String companyId) =>
      (delete(outbox)..where(
            (o) => o.companyId.equals(companyId) & o.state.equals('pending'),
          ))
          .go();

  Stream<int> watchPendingCount({required String companyId}) {
    final count = outbox.id.count();
    final q = selectOnly(outbox)
      ..addColumns([count])
      ..where(
        outbox.companyId.equals(companyId) & outbox.state.equals('pending'),
      );
    return q.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Stream<int> watchDeadCount({required String companyId}) {
    final count = outbox.id.count();
    final q = selectOnly(outbox)
      ..addColumns([count])
      ..where(outbox.companyId.equals(companyId) & outbox.state.equals('dead'));
    return q.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<List<OutboxRow>> nextReady({
    required String companyId,
    required int now,
    int limit = 50,
  }) {
    final q = select(outbox)
      ..where(
        (o) =>
            o.companyId.equals(companyId) &
            o.state.equals('pending') &
            o.nextAttemptAt.isSmallerOrEqualValue(now),
      )
      ..orderBy([(o) => OrderingTerm(expression: o.id)])
      ..limit(limit);
    return q.get();
  }

  /// Find an existing `pending` row for [companyId] + [entityType] so the
  /// caller can collapse rapid edits of an idempotent mutation (e.g. user
  /// settings) into one outbox row instead of N.
  Future<OutboxRow?> findPending({
    required String companyId,
    required String entityType,
  }) {
    final q = select(outbox)
      ..where(
        (o) =>
            o.companyId.equals(companyId) &
            o.entityType.equals(entityType) &
            o.state.equals('pending'),
      )
      ..orderBy([(o) => OrderingTerm(expression: o.id)])
      ..limit(1);
    return q.getSingleOrNull();
  }

  /// Overwrite the payload of an existing outbox row (idempotency key stays
  /// the same — server treats a retry with a fresher payload as equivalent
  /// to the original).
  Future<void> updatePayload({required int id, required String payload}) =>
      (update(outbox)..where((o) => o.id.equals(id))).write(
        OutboxCompanion(payload: Value(payload)),
      );

  Future<void> markInFlight(int id) =>
      (update(outbox)..where((o) => o.id.equals(id))).write(
        const OutboxCompanion(state: Value('in_flight')),
      );

  Future<void> deleteRow(int id) =>
      (delete(outbox)..where((o) => o.id.equals(id))).go();

  Future<void> scheduleRetry({
    required int id,
    required int attempts,
    required int nextAttemptAt,
    required String error,
    int? statusCode,
  }) => (update(outbox)..where((o) => o.id.equals(id))).write(
    OutboxCompanion(
      state: const Value('pending'),
      nextAttemptAt: Value(nextAttemptAt),
      attempts: Value(attempts),
      lastError: Value(error),
      lastStatusCode: Value(statusCode),
    ),
  );

  Future<void> markDead({
    required int id,
    required String error,
    int? statusCode,
    String? fieldErrorsJson,
  }) => (update(outbox)..where((o) => o.id.equals(id))).write(
    OutboxCompanion(
      state: const Value('dead'),
      lastError: Value(error),
      lastStatusCode: Value(statusCode),
      fieldErrorsJson: Value(fieldErrorsJson),
    ),
  );

  /// Stream of non-`dead` rows for one specific entity. Drives the
  /// optimistic "syncing…" entries in the client Activity tab; can be
  /// scoped to a single [kind] (e.g. only `addComment` rows) when the
  /// caller only cares about a particular flavor of mutation.
  ///
  /// Includes `pending` and `in_flight` rows so a row that's mid-send still
  /// shows up; excludes `dead` rows so a 422-failed comment doesn't linger
  /// in the tab (the user will see it on the Outbox screen instead).
  Stream<List<OutboxRow>> watchPendingForEntity({
    required String companyId,
    required String entityType,
    required String entityId,
    MutationKind? kind,
  }) {
    final wireKind = kind?.wireName;
    final q = select(outbox)
      ..where(
        (o) =>
            o.companyId.equals(companyId) &
            o.entityType.equals(entityType) &
            o.entityId.equals(entityId) &
            o.state.isNotValue('dead') &
            (wireKind == null
                ? const Constant(true)
                : o.mutationKind.equals(wireKind)),
      )
      ..orderBy([(o) => OrderingTerm(expression: o.id)]);
    return q.watch();
  }

  /// Stream of every outbox row for [companyId], newest first. Drives the
  /// Outbox screen. Includes `pending`, `in_flight`, and `dead` rows so the
  /// user sees the full mutation queue, not just the failures.
  Stream<List<OutboxRow>> watchAll(String companyId) {
    final q = select(outbox)
      ..where((o) => o.companyId.equals(companyId))
      ..orderBy([
        (o) => OrderingTerm(expression: o.createdAt, mode: OrderingMode.desc),
      ]);
    return q.watch();
  }

  /// Newest `dead` row for the given entity (if any). The edit form calls
  /// this on open so it can replay 422 field errors against the form.
  Future<OutboxRow?> findDeadForEntity({
    required String companyId,
    required String entityType,
    required String entityId,
  }) {
    final q = select(outbox)
      ..where(
        (o) =>
            o.companyId.equals(companyId) &
            o.entityType.equals(entityType) &
            o.entityId.equals(entityId) &
            o.state.equals('dead'),
      )
      ..orderBy([
        (o) => OrderingTerm(expression: o.id, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return q.getSingleOrNull();
  }

  /// Re-arm a `dead` row for immediate retry. Resets `attempts` and
  /// `nextAttemptAt` so the next [drainOnce] picks it up; preserves
  /// `idempotency_key`, `payload`, and `field_errors_json` so the server
  /// sees the same request and the UI can still surface the prior errors
  /// if the retry fails again.
  Future<void> retryDead({required int id, required int now}) =>
      (update(outbox)..where((o) => o.id.equals(id))).write(
        OutboxCompanion(
          state: const Value('pending'),
          attempts: const Value(0),
          nextAttemptAt: Value(now),
        ),
      );

  /// Delete `dead` rows whose `created_at` is older than [olderThanMs].
  /// Returns the number of rows removed.
  ///
  /// Dead rows hold the full mutation payload (PII, sometimes payment / tax
  /// fields) and are otherwise never cleaned up — the user has to discard
  /// them one by one from the Outbox UI. Auto-pruning bounds how long the
  /// data sits on disk in the (currently unencrypted) Drift DB.
  Future<int> pruneDead({required int olderThanMs}) =>
      (delete(outbox)..where(
            (o) =>
                o.state.equals('dead') &
                o.createdAt.isSmallerThanValue(olderThanMs),
          ))
          .go();

  /// Rewrite tmp ids inside payloads of pending rows once a `create` lands and
  /// produces a real id. The repository / sync engine calls this in the same
  /// transaction as inserting into `id_remap`.
  Future<void> rewriteTempIdInPayloads({
    required String companyId,
    required String entityType,
    required String tempId,
    required String realId,
  }) async {
    final rows =
        await (select(outbox)..where(
              (o) =>
                  o.companyId.equals(companyId) &
                  o.state.equals('pending') &
                  (o.payload.contains(tempId) | o.entityId.equals(tempId)),
            ))
            .get();
    for (final row in rows) {
      final newPayload = row.payload.replaceAll(tempId, realId);
      final newEntityId = row.entityId == tempId ? realId : row.entityId;
      await (update(outbox)..where((o) => o.id.equals(row.id))).write(
        OutboxCompanion(
          payload: Value(newPayload),
          entityId: Value(newEntityId),
        ),
      );
    }
  }
}
