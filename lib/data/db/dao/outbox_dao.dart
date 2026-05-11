import 'package:drift/drift.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/tables/outbox_table.dart';

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
    required int nextAttemptAt,
    required String error,
    int? statusCode,
  }) => (update(outbox)..where((o) => o.id.equals(id))).write(
    OutboxCompanion(
      state: const Value('pending'),
      nextAttemptAt: Value(nextAttemptAt),
      attempts: const Value.absent(),
      lastError: Value(error),
      lastStatusCode: Value(statusCode),
    ),
  );

  Future<void> markDead({
    required int id,
    required String error,
    int? statusCode,
  }) => (update(outbox)..where((o) => o.id.equals(id))).write(
    OutboxCompanion(
      state: const Value('dead'),
      lastError: Value(error),
      lastStatusCode: Value(statusCode),
    ),
  );

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
