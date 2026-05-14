import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';

/// Targeted tests for the three Outbox screen / 422-surface entry points
/// added on top of the existing dao. The broader state-machine coverage
/// (markDead, scheduleRetry, rewriteTempIdInPayloads, …) lives in
/// `sync_repository_test.dart`.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  Future<int> enqueue({
    String companyId = 'co',
    String entityType = 'client',
    String entityId = 'c1',
    String kind = 'update',
    String idempotencyKey = 'k',
    int createdAt = 0,
    String state = 'pending',
  }) async {
    final id = await db.outboxDao.enqueue(
      OutboxCompanion.insert(
        companyId: companyId,
        entityType: entityType,
        entityId: entityId,
        mutationKind: kind,
        payload: jsonEncode({'id': entityId}),
        idempotencyKey: idempotencyKey,
        nextAttemptAt: 0,
        createdAt: createdAt,
        state: Value(state),
      ),
    );
    return id;
  }

  group('watchAll', () {
    test(
      'emits every row for the company regardless of state, newest first',
      () async {
        final older = await enqueue(entityId: 'a', createdAt: 1, state: 'dead');
        final newer = await enqueue(entityId: 'b', createdAt: 2);
        final inFlight = await enqueue(
          entityId: 'c',
          createdAt: 3,
          state: 'in_flight',
        );
        // A row from a different company must not leak into this stream.
        await enqueue(companyId: 'other', entityId: 'd', createdAt: 4);

        final rows = await db.outboxDao.watchAll('co').first;
        expect(rows.map((r) => r.id), [inFlight, newer, older]);
      },
    );
  });

  group('findDeadForEntity', () {
    test('returns the newest dead row for the (type, id) tuple', () async {
      await enqueue(entityId: 'c1', state: 'dead', idempotencyKey: 'k1');
      final newerDead = await enqueue(
        entityId: 'c1',
        state: 'dead',
        idempotencyKey: 'k2',
      );
      // Pending rows for the same entity are excluded.
      await enqueue(entityId: 'c1', idempotencyKey: 'k3');
      // Dead rows for a different entity are excluded.
      await enqueue(entityId: 'c2', state: 'dead', idempotencyKey: 'k4');

      final row = await db.outboxDao.findDeadForEntity(
        companyId: 'co',
        entityType: 'client',
        entityId: 'c1',
      );
      expect(row?.id, newerDead);
    });

    test('returns null when no dead row exists', () async {
      await enqueue(entityId: 'c1'); // pending
      final row = await db.outboxDao.findDeadForEntity(
        companyId: 'co',
        entityType: 'client',
        entityId: 'c1',
      );
      expect(row, isNull);
    });
  });

  group('markDead', () {
    test(
      'persists fieldErrorsJson alongside the message + status code',
      () async {
        final id = await enqueue();
        await db.outboxDao.markDead(
          id: id,
          error: 'Validation failed',
          statusCode: 422,
          fieldErrorsJson: '{"name":["is required"]}',
        );
        final row = (await (db.select(
          db.outbox,
        )..where((o) => o.id.equals(id))).get()).single;
        expect(row.state, 'dead');
        expect(row.lastError, 'Validation failed');
        expect(row.lastStatusCode, 422);
        expect(row.fieldErrorsJson, '{"name":["is required"]}');
      },
    );
  });

  group('staleRowsForCompany', () {
    test(
      'returns dead + in_flight + far-future-pending rows, scoped to company',
      () async {
        final now = 1000000;
        final dayMs = const Duration(days: 1).inMilliseconds;

        Future<int> add({
          String companyId = 'co',
          String entityId = 'e',
          String state = 'pending',
          int nextAttemptAt = 0,
        }) async {
          return db.outboxDao.enqueue(
            OutboxCompanion.insert(
              companyId: companyId,
              entityType: 'client',
              entityId: entityId,
              mutationKind: 'update',
              payload: '{}',
              idempotencyKey: 'k$entityId$state',
              nextAttemptAt: nextAttemptAt,
              createdAt: now,
              state: Value(state),
            ),
          );
        }

        final dead = await add(entityId: 'dead', state: 'dead');
        final inFlight = await add(entityId: 'flight', state: 'in_flight');
        // Pending parked > 24 h out — stale.
        final parked = await add(
          entityId: 'parked',
          nextAttemptAt: now + 365 * dayMs,
        );
        // Fresh pending — NOT stale.
        await add(entityId: 'fresh', nextAttemptAt: now + 1000);
        // Pending parked just at threshold — NOT stale (strictly greater).
        await add(entityId: 'edge', nextAttemptAt: now + dayMs);
        // Different company — must not leak.
        await add(companyId: 'other', entityId: 'other-dead', state: 'dead');

        final rows = await db.outboxDao.staleRowsForCompany(
          companyId: 'co',
          now: now,
        );
        expect(rows.map((r) => r.id), [dead, inFlight, parked]);
      },
    );
  });

  group('retryDead', () {
    test(
      're-arms a dead row to pending with attempts reset and nextAttemptAt '
      'set, preserving payload / idempotency_key / field_errors_json',
      () async {
        final id = await enqueue(idempotencyKey: 'stable-key');
        await db.outboxDao.markDead(
          id: id,
          error: 'boom',
          statusCode: 422,
          fieldErrorsJson: '{"name":["bad"]}',
        );
        // Bump attempts so we can see them reset.
        await (db.update(db.outbox)..where((o) => o.id.equals(id))).write(
          const OutboxCompanion(attempts: Value(4)),
        );
        await db.outboxDao.retryDead(id: id, now: 12345);
        final row = (await (db.select(
          db.outbox,
        )..where((o) => o.id.equals(id))).get()).single;
        expect(row.state, 'pending');
        expect(row.attempts, 0);
        expect(row.nextAttemptAt, 12345);
        expect(row.idempotencyKey, 'stable-key');
        expect(row.payload, contains('c1'));
        // The prior errors stick around so the form can keep showing them
        // until the retry resolves them or the user discards explicitly.
        expect(row.fieldErrorsJson, '{"name":["bad"]}');
      },
    );
  });
}
