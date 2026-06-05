import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/repositories/task_status_repository.dart';
import 'package:admin/data/services/task_statuses_api.dart';
import 'package:admin/domain/sync/mutation.dart';

/// `TaskStatusRepository.reorder` mirrors the server's single-status move
/// model: there is **no** `/task_statuses/sort` endpoint, so a reorder PUTs
/// the one moved status with an insertion `status_order` and lets the server
/// renumber siblings. These tests lock the insertion math and the outbox
/// shape — a standard single-status update, never the old `{status_ids}`
/// bulk-`/sort` payload (which 404'd against the live server).
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  TaskStatusRepository makeRepo() =>
      TaskStatusRepository(db: db, api: _FakeApi());

  TaskStatusApi api(String id, int order) =>
      TaskStatusApi(id: id, name: id, statusOrder: order, updatedAt: order);

  // Seed four ordered statuses a,b,c,d (status_order 1..4), no outbox rows.
  Future<TaskStatusRepository> seeded() async {
    final repo = makeRepo();
    await repo.applyBundle(
      companyId: 'co',
      bundle: [api('a', 1), api('b', 2), api('c', 3), api('d', 4)],
    );
    return repo;
  }

  Future<Map<String, int>> orders(TaskStatusRepository repo) async {
    final list = await repo.watchAll(companyId: 'co').first;
    return {for (final s in list) s.id: s.statusOrder};
  }

  Future<Map<String, dynamic>> reorderPayload() async {
    final pending = await db.outboxDao.pendingRowsForCompany('co');
    final rows = pending
        .where((r) => r.mutationKind == MutationKind.reorder.wireName)
        .toList();
    expect(rows, hasLength(1), reason: 'exactly one reorder mutation enqueued');
    return jsonDecode(rows.single.payload) as Map<String, dynamic>;
  }

  test('move-to-top: slot = successor\'s current order', () async {
    final repo = await seeded();
    await repo.reorder(companyId: 'co', orderedStatusIds: ['d', 'a', 'b', 'c']);

    // Optimistic local renumber is 1-based in the new sequence.
    expect(await orders(repo), {'d': 1, 'a': 2, 'b': 3, 'c': 4});

    final payload = await reorderPayload();
    final moved = payload['status'] as Map<String, dynamic>;
    expect(moved['id'], 'd');
    expect(moved['status_order'], 1); // a's pre-move order
    expect(payload['all_ids'], ['d', 'a', 'b', 'c']);
    // Single-status shape — NOT the old bulk `/sort` payload.
    expect(payload.containsKey('status_ids'), isFalse);
  });

  test('move-to-bottom: slot = maxOrder + 1 (append)', () async {
    final repo = await seeded();
    await repo.reorder(companyId: 'co', orderedStatusIds: ['b', 'c', 'd', 'a']);

    expect(await orders(repo), {'b': 1, 'c': 2, 'd': 3, 'a': 4});

    final moved = (await reorderPayload())['status'] as Map<String, dynamic>;
    expect(moved['id'], 'a');
    expect(moved['status_order'], 5); // max(1..4) + 1
  });

  test('move-into-middle: slot = new successor\'s current order', () async {
    final repo = await seeded();
    // a, [d], b, c  → d's new successor is b (current order 2).
    await repo.reorder(companyId: 'co', orderedStatusIds: ['a', 'd', 'b', 'c']);

    expect(await orders(repo), {'a': 1, 'd': 2, 'b': 3, 'c': 4});

    final moved = (await reorderPayload())['status'] as Map<String, dynamic>;
    expect(moved['id'], 'd');
    expect(moved['status_order'], 2); // b's pre-move order
  });

  test(
    'the reorder mutation carries the real moved id (not a sentinel)',
    () async {
      final repo = await seeded();
      await repo.reorder(
        companyId: 'co',
        orderedStatusIds: ['d', 'a', 'b', 'c'],
      );
      final pending = await db.outboxDao.pendingRowsForCompany('co');
      final row = pending.firstWhere(
        (r) => r.mutationKind == MutationKind.reorder.wireName,
      );
      expect(row.entityId, 'd');
    },
  );

  test('a no-op reorder (unchanged order) enqueues nothing', () async {
    final repo = await seeded();
    await repo.reorder(companyId: 'co', orderedStatusIds: ['a', 'b', 'c', 'd']);
    final pending = await db.outboxDao.pendingRowsForCompany('co');
    expect(
      pending.where((r) => r.mutationKind == MutationKind.reorder.wireName),
      isEmpty,
    );
  });

  test('a reorder naming an unknown status is a safe no-op', () async {
    // `z` was never seeded, so detection picks it as the mover but its row is
    // absent from the local cache. The guard must bail — no throw, no mutation.
    final repo = await seeded();
    await repo.reorder(
      companyId: 'co',
      orderedStatusIds: ['a', 'b', 'c', 'd', 'z'],
    );
    final pending = await db.outboxDao.pendingRowsForCompany('co');
    expect(
      pending.where((r) => r.mutationKind == MutationKind.reorder.wireName),
      isEmpty,
    );
  });
}

/// The repo path under test never reaches the network (the outbox handler
/// would), so a throwing stub suffices — mirrors `_FakeTasksApi`.
class _FakeApi implements TaskStatusesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
