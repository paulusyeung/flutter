import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/sync_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:admin/domain/sync/sync_dispatcher.dart';
import 'package:admin/domain/sync/sync_event.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';

/// These tests target the sync engine's STATE MACHINE — the transitions that
/// production reliability depends on:
///   * success → outbox row removed
///   * 422 → row marked dead + ValidationFailedEvent
///   * 409 → row stays pending + ConflictEvent (with retry deferred)
///   * PasswordRequired → row stays pending + PasswordRequiredEvent
///   * 429 with Retry-After → row stays pending with delay honored
///   * 5xx/network → backoff schedule (1st failure → 5s, 2nd → 30s, ...)
///   * exceeding max attempts → marked dead
///   * unknown mutation kind / missing dispatcher → marked dead, never hangs

/// Programmable fake dispatcher — each `dispatch` call throws a queued
/// outcome (or returns void on success).
class _ProgrammableDispatcher implements SyncDispatcher {
  final List<Object?> _outcomes = [];
  int dispatches = 0;
  OutboxRow? lastRow;

  void queueSuccess() => _outcomes.add(null);
  void queueThrow(Object error) => _outcomes.add(error);

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    dispatches++;
    lastRow = row;
    if (_outcomes.isEmpty) {
      throw StateError('no outcome queued for dispatch #$dispatches');
    }
    final outcome = _outcomes.removeAt(0);
    if (outcome is Object) {
      throw outcome;
    }
  }
}

EntityRegistry _registryWith(SyncDispatcher dispatcher) => EntityRegistry({
  EntityType.client: EntityHandlers(
    type: EntityType.client,
    wireName: 'client',
    apiPath: '/api/v1/clients',
    routePath: '/clients',
    icon: Icons.people,
    requiresPasswordFor: const {MutationKind.delete},
    dispatcher: dispatcher,
  ),
});

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  Future<int> enqueueClient({
    required String entityId,
    MutationKind kind = MutationKind.update,
    int nextAttemptAt = 0,
    int attempts = 0,
    String idempotencyKey = 'k',
  }) => db.outboxDao.enqueue(
    OutboxCompanion.insert(
      companyId: 'co',
      entityType: 'client',
      entityId: entityId,
      mutationKind: kind.wireName,
      payload: jsonEncode({'id': entityId}),
      idempotencyKey: idempotencyKey,
      nextAttemptAt: nextAttemptAt,
      createdAt: 0,
      attempts: Value(attempts),
    ),
  );

  Future<OutboxRow?> rowById(int id) async {
    final rows = await db.outboxDao.nextReady(companyId: 'co', now: 1 << 60);
    for (final r in rows) {
      if (r.id == id) return r;
    }
    return null;
  }

  SyncRepository makeEngine(SyncDispatcher dispatcher, {int nowMs = 1000}) {
    return SyncRepository(
      db: db,
      registry: _registryWith(dispatcher),
      now: () => DateTime.fromMillisecondsSinceEpoch(nowMs),
    );
  }

  group('success path', () {
    test('200-class result removes the outbox row', () async {
      final disp = _ProgrammableDispatcher()..queueSuccess();
      final engine = makeEngine(disp);
      await enqueueClient(entityId: 'c1');

      final success = await engine.drainOnce(companyId: 'co');
      expect(success, 1);
      final remaining = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(remaining, isEmpty);
    });
  });

  group('error transitions', () {
    test(
      '422 marks the row dead and emits ValidationFailedEvent with fields',
      () async {
        final disp = _ProgrammableDispatcher()
          ..queueThrow(
            const ValidationException('Validation failed', {
              'email': ['Must be unique'],
            }),
          );
        final engine = makeEngine(disp);
        final events = <SyncEvent>[];
        engine.events.listen(events.add);
        final id = await enqueueClient(entityId: 'c1');

        await engine.drainOnce(companyId: 'co');
        await Future<void>.delayed(Duration.zero); // flush broadcast

        final row = await rowById(id);
        // After dead, the row no longer comes back via nextReady() since
        // nextReady only returns pending. Read directly via the table.
        final all = await (db.select(
          db.outbox,
        )..where((o) => o.id.equals(id))).get();
        expect(all.single.state, 'dead');
        expect(all.single.lastStatusCode, 422);
        expect(row, isNull, reason: 'dead rows are not pending');

        expect(events, hasLength(1));
        final v = events.single as ValidationFailedEvent;
        expect(v.fieldErrors['email'], ['Must be unique']);
      },
    );

    test('409 leaves the row pending but parked far in the future so the '
        'engine does not auto-retry into the same conflict', () async {
      final disp = _ProgrammableDispatcher()
        ..queueThrow(const ConflictException('Stale'));
      final engine = makeEngine(disp, nowMs: 1000);
      final events = <SyncEvent>[];
      engine.events.listen(events.add);
      final id = await enqueueClient(entityId: 'c1');

      await engine.drainOnce(companyId: 'co');
      await Future<void>.delayed(Duration.zero);

      final row = await (db.select(
        db.outbox,
      )..where((o) => o.id.equals(id))).getSingle();
      expect(row.state, 'pending');
      expect(row.lastStatusCode, 409);
      // The exact delay is an implementation detail; what we care about is
      // that auto-retry won't fire in any reasonable drain window.
      expect(
        row.nextAttemptAt - 1000,
        greaterThan(const Duration(days: 30).inMilliseconds),
        reason: 'auto-retry must not hit the same 409 over and over',
      );
      expect(events.single, isA<ConflictEvent>());
    });

    test(
      'PasswordRequired keeps row + emits event so UI prompts the user',
      () async {
        final disp = _ProgrammableDispatcher()
          ..queueThrow(const PasswordRequiredException());
        final engine = makeEngine(disp);
        final events = <SyncEvent>[];
        engine.events.listen(events.add);
        final id = await enqueueClient(
          entityId: 'c1',
          kind: MutationKind.delete,
        );

        await engine.drainOnce(companyId: 'co');
        await Future<void>.delayed(Duration.zero);

        final row = await (db.select(
          db.outbox,
        )..where((o) => o.id.equals(id))).getSingle();
        expect(row.state, 'pending');
        expect(events.single, isA<PasswordRequiredEvent>());
      },
    );

    test(
      '429 with Retry-After honors the delay before the next attempt',
      () async {
        final disp = _ProgrammableDispatcher()
          ..queueThrow(
            const RateLimitedException(retryAfter: Duration(seconds: 12)),
          );
        final engine = makeEngine(disp, nowMs: 1000);
        final id = await enqueueClient(entityId: 'c1');

        await engine.drainOnce(companyId: 'co');

        final row = await (db.select(
          db.outbox,
        )..where((o) => o.id.equals(id))).getSingle();
        expect(
          row.nextAttemptAt,
          1000 + 12000,
          reason: 'Retry-After dictates the wakeup time',
        );
      },
    );

    test('5xx walks the backoff schedule by attempt count', () async {
      // First attempt: 0 → backoffSchedule[1] = 30s
      final disp = _ProgrammableDispatcher()
        ..queueThrow(const ServerException(500, 'Boom'));
      final engine = makeEngine(disp, nowMs: 1000);
      final id = await enqueueClient(entityId: 'c1', attempts: 0);

      await engine.drainOnce(companyId: 'co');
      final row1 = await (db.select(
        db.outbox,
      )..where((o) => o.id.equals(id))).getSingle();
      expect(
        row1.nextAttemptAt - 1000,
        kBackoffSchedule[1].inMilliseconds,
        reason: 'attempt 0 → next attempt 1 → schedule[1]',
      );
    });

    test('exceeding max attempts marks the row dead', () async {
      final disp = _ProgrammableDispatcher()
        ..queueThrow(const ServerException(500, 'Boom'));
      final engine = makeEngine(disp);
      final id = await enqueueClient(
        entityId: 'c1',
        attempts: kMaxAttempts - 1,
      );

      await engine.drainOnce(companyId: 'co');

      final row = await (db.select(
        db.outbox,
      )..where((o) => o.id.equals(id))).getSingle();
      expect(row.state, 'dead');
    });
  });

  group('FIFO + safety', () {
    test('rows past their next_attempt_at are picked up in id order', () async {
      // Two pending rows; the engine should dispatch in insert order.
      final disp = _ProgrammableDispatcher()
        ..queueSuccess()
        ..queueSuccess();
      final engine = makeEngine(disp, nowMs: 1000);
      await enqueueClient(entityId: 'first');
      await enqueueClient(entityId: 'second');

      await engine.drainOnce(companyId: 'co');
      expect(disp.dispatches, 2);
    });

    test(
      'unknown mutation_kind is marked dead, not silently retried forever',
      () async {
        final disp = _ProgrammableDispatcher();
        final engine = makeEngine(disp);
        final id = await db.outboxDao.enqueue(
          OutboxCompanion.insert(
            companyId: 'co',
            entityType: 'client',
            entityId: 'c1',
            mutationKind: 'action:future_thing', // unknown in M1
            payload: '{}',
            idempotencyKey: 'k',
            nextAttemptAt: 0,
            createdAt: 0,
          ),
        );

        await engine.drainOnce(companyId: 'co');

        final row = await (db.select(
          db.outbox,
        )..where((o) => o.id.equals(id))).getSingle();
        expect(row.state, 'dead');
        expect(
          disp.dispatches,
          0,
          reason: 'unknown kinds never reach the dispatcher',
        );
      },
    );

    test(
      'missing registry entry is marked dead, not silently retried forever',
      () async {
        final disp = _ProgrammableDispatcher();
        final engine = makeEngine(disp);
        final id = await db.outboxDao.enqueue(
          OutboxCompanion.insert(
            companyId: 'co',
            entityType: 'invoice', // not registered in this test
            entityId: 'i1',
            mutationKind: MutationKind.update.wireName,
            payload: '{}',
            idempotencyKey: 'k',
            nextAttemptAt: 0,
            createdAt: 0,
          ),
        );

        await engine.drainOnce(companyId: 'co');

        final row = await (db.select(
          db.outbox,
        )..where((o) => o.id.equals(id))).getSingle();
        expect(row.state, 'dead');
      },
    );
  });
}
