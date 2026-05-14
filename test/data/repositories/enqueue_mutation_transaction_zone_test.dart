import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';

/// Regression for the kanban-reorder "stuck pending/0" bug.
///
/// `enqueueMutation` schedules its `onEnqueued` callback via
/// `Future(() => ...)` so it fires after any wrapping `db.transaction(...)`
/// commits. But without `Zone.root.run(...)` around the scheduling, the
/// timer callback inherits Drift's `#drift_transaction` zone value from
/// the caller. When the callback fires, the transaction has committed and
/// its executor is disposed — so any DB query made *inside* the deferred
/// kick (in production: `sync.drainOnce` → `outboxDao.nextReady`) routes
/// through the torn-down executor and silently sees no rows. The kanban
/// drag's reorder row sits at `pending/0` until the next user-driven
/// drain trigger (company switch / app resume / manual Retry).
///
/// This test mirrors the production failure: `onEnqueued` runs
/// `outboxDao.nextReady(...)` directly. If the deferred callback is bound
/// to a closed transaction zone, the SELECT returns empty.
class _StubRepository extends BaseEntityRepository<Object, Object> {
  _StubRepository({required super.db, required super.onEnqueued})
    : super(entityType: EntityType.task);

  @override
  Stream<Object?> watchByRealId({
    required String companyId,
    required String id,
  }) => const Stream.empty();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  test(
    'enqueueMutation inside db.transaction — deferred kick sees the row',
    () async {
      const companyId = 'co-1';
      // Capture what the kick observes from *inside* its callback. In
      // production this is `sync.drainOnce → outboxDao.nextReady` — same
      // query, same zone-routing question.
      final kickSawRowsCompleter = Completer<List<OutboxRow>>();
      final repo = _StubRepository(
        db: db,
        onEnqueued: (cid) async {
          try {
            final rows = await db.outboxDao.nextReady(
              companyId: cid,
              now: DateTime.now().millisecondsSinceEpoch,
            );
            if (!kickSawRowsCompleter.isCompleted) {
              kickSawRowsCompleter.complete(rows);
            }
          } catch (e, st) {
            if (!kickSawRowsCompleter.isCompleted) {
              kickSawRowsCompleter.completeError(e, st);
            }
          }
        },
      );

      await db.transaction(() async {
        await repo.enqueueMutation(
          companyId: companyId,
          entityId: '_sort',
          kind: MutationKind.reorder,
          payload: const {'status_ids': <String>[]},
        );
      });

      final rows = await kickSawRowsCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw StateError(
          'Deferred kick never fired — `Zone.root.run` may be missing or '
          'the Future never reached the timer queue.',
        ),
      );

      expect(
        rows.length,
        1,
        reason:
            'The deferred kick must see the row enqueued inside the '
            'transaction. If this is 0, the SELECT inside the kick is '
            'still bound to the (now-closed) transaction zone — the '
            '`Zone.root.run` wrap in `enqueueMutation` is missing or '
            'broken.',
      );
      expect(rows.single.entityId, '_sort');
      expect(rows.single.mutationKind, MutationKind.reorder.wireName);
      expect(rows.single.state, 'pending');
    },
  );

  test(
    'enqueueMutation outside any transaction — deferred kick still sees row',
    () async {
      const companyId = 'co-1';
      final kickSawRowsCompleter = Completer<List<OutboxRow>>();
      final repo = _StubRepository(
        db: db,
        onEnqueued: (cid) async {
          final rows = await db.outboxDao.nextReady(
            companyId: cid,
            now: DateTime.now().millisecondsSinceEpoch,
          );
          if (!kickSawRowsCompleter.isCompleted) {
            kickSawRowsCompleter.complete(rows);
          }
        },
      );

      await repo.enqueueMutation(
        companyId: companyId,
        entityId: 'task-1',
        kind: MutationKind.update,
        payload: const {'id': 'task-1'},
      );

      final rows = await kickSawRowsCompleter.future.timeout(
        const Duration(seconds: 2),
      );
      expect(rows.length, 1);
      expect(rows.single.entityId, 'task-1');
    },
  );
}
