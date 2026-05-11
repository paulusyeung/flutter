import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/outbox_table.dart';

part 'outbox_dao.g.dart';

/// `state` values: `pending | in_flight | dead`.
enum OutboxState { pending, inFlight, dead }

@DriftAccessor(tables: [Outbox])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  Future<int> enqueue(OutboxCompanion row) =>
      into(outbox).insert(row);

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
      ..where(
        outbox.companyId.equals(companyId) & outbox.state.equals('dead'),
      );
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

  Future<void> markInFlight(int id) =>
      (update(outbox)..where((o) => o.id.equals(id)))
          .write(const OutboxCompanion(state: Value('in_flight')));

  Future<void> deleteRow(int id) =>
      (delete(outbox)..where((o) => o.id.equals(id))).go();

  Future<void> scheduleRetry({
    required int id,
    required int nextAttemptAt,
    required String error,
    int? statusCode,
  }) =>
      (update(outbox)..where((o) => o.id.equals(id))).write(
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
  }) =>
      (update(outbox)..where((o) => o.id.equals(id))).write(
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
    final rows = await (select(outbox)
          ..where(
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
