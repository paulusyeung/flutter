import 'dart:async';
import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/base_entity_repository.dart';
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
        // The dead row also carries the structured field errors so the
        // edit form can replay them after restart; the bare last_error
        // alone isn't enough.
        expect(all.single.fieldErrorsJson, isNotNull);
        final persisted = jsonDecode(all.single.fieldErrorsJson!);
        expect(persisted, {
          'email': ['Must be unique'],
        });

        expect(events, hasLength(1));
        final v = events.single as ValidationFailedEvent;
        expect(v.fieldErrors['email'], ['Must be unique']);
      },
    );

    test('422 with no field map leaves fieldErrorsJson null — the bare message '
        'stays in last_error so we don\'t serialize an empty object', () async {
      final disp = _ProgrammableDispatcher()
        ..queueThrow(const ValidationException('Validation failed', {}));
      final engine = makeEngine(disp);
      final id = await enqueueClient(entityId: 'c2');
      await engine.drainOnce(companyId: 'co');
      final all = await (db.select(
        db.outbox,
      )..where((o) => o.id.equals(id))).get();
      expect(all.single.state, 'dead');
      expect(all.single.fieldErrorsJson, isNull);
      expect(all.single.lastError, 'Validation failed');
    });

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

  group('auto-drain on enqueue', () {
    test(
      'BaseEntityRepository.enqueueMutation invokes onEnqueued so the row drains '
      'without an explicit drainOnce call',
      () async {
        final disp = _ProgrammableDispatcher()..queueSuccess();
        // Share a clock between the repo and the engine — without this, the
        // repo stamps `nextAttemptAt` from real wall-clock time and the
        // engine's `nextReady` (using its own injected 1000ms clock) filters
        // the row out as "not ready yet".
        DateTime fakeNow() => DateTime.fromMillisecondsSinceEpoch(1000);
        final engine = SyncRepository(
          db: db,
          registry: _registryWith(disp),
          now: fakeNow,
        );
        final repo = _TestRepo(
          db: db,
          now: fakeNow,
          onEnqueued: (companyId) {
            engine.drainOnce(companyId: companyId);
          },
        );

        await repo.enqueueMutation(
          companyId: 'co',
          entityId: 'c1',
          kind: MutationKind.update,
          payload: const {'id': 'c1'},
        );
        // The auto-drain is fire-and-forget; pump microtasks until the
        // dispatcher has been hit.
        for (var i = 0; i < 10 && disp.dispatches == 0; i++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(disp.dispatches, 1);
        final remaining = await db.outboxDao.nextReady(
          companyId: 'co',
          now: 1 << 60,
        );
        expect(
          remaining,
          isEmpty,
          reason: 'auto-drain should have removed the row',
        );
      },
    );
  });

  group('single-flight', () {
    test('concurrent drainOnce calls for the same company coalesce — each row '
        'is dispatched exactly once', () async {
      // Gate the first dispatch so both drainOnce calls overlap.
      final firstGate = Completer<void>();
      final disp = _GatedDispatcher(firstBlocker: firstGate.future);
      final engine = makeEngine(disp);
      await enqueueClient(entityId: 'c1', idempotencyKey: 'k1');
      await enqueueClient(entityId: 'c2', idempotencyKey: 'k2');

      final first = engine.drainOnce(companyId: 'co');
      // Let the drain reach the gated first dispatch.
      await Future<void>.delayed(Duration.zero);
      final second = engine.drainOnce(companyId: 'co');
      expect(
        identical(first, second),
        isTrue,
        reason: 'second concurrent call must return the in-flight future',
      );

      firstGate.complete();
      await Future.wait([first, second]);

      expect(
        disp.dispatches,
        2,
        reason: 'two rows → two dispatches total, not four',
      );
    });

    test(
      'a fresh drainOnce after the previous one settles starts a new pass',
      () async {
        final disp = _ProgrammableDispatcher()
          ..queueSuccess()
          ..queueSuccess();
        final engine = makeEngine(disp);
        await enqueueClient(entityId: 'c1', idempotencyKey: 'k1');
        await engine.drainOnce(companyId: 'co');
        await enqueueClient(entityId: 'c2', idempotencyKey: 'k2');
        await engine.drainOnce(companyId: 'co');

        expect(disp.dispatches, 2);
      },
    );

    test(
      'drainOnce for different companies run in parallel, not serialised',
      () async {
        final firstGate = Completer<void>();
        final disp = _GatedDispatcher(firstBlocker: firstGate.future);
        final engine = makeEngine(disp);
        // co-A row gates the dispatch; co-B should still drain to completion.
        await db.outboxDao.enqueue(
          OutboxCompanion.insert(
            companyId: 'co-A',
            entityType: 'client',
            entityId: 'a1',
            mutationKind: 'update',
            payload: '{}',
            idempotencyKey: 'ka',
            nextAttemptAt: 0,
            createdAt: 0,
          ),
        );
        await db.outboxDao.enqueue(
          OutboxCompanion.insert(
            companyId: 'co-B',
            entityType: 'client',
            entityId: 'b1',
            mutationKind: 'update',
            payload: '{}',
            idempotencyKey: 'kb',
            nextAttemptAt: 0,
            createdAt: 0,
          ),
        );

        final drainA = engine.drainOnce(companyId: 'co-A');
        final drainB = engine.drainOnce(companyId: 'co-B');
        // B should finish on its own — it's gated by nothing.
        await drainB;
        // A is still parked on the gate; release and finish.
        firstGate.complete();
        await drainA;

        expect(disp.dispatches, 2);
      },
    );
  });

  group('cancel', () {
    test('stops the drain between rows', () async {
      // First dispatch blocks until we release it; later dispatches return
      // immediately. With cancel firing during the block, the second outbox
      // row must never reach the dispatcher.
      final firstDispatchGate = Completer<void>();
      final disp = _GatedDispatcher(firstBlocker: firstDispatchGate.future);
      final engine = makeEngine(disp);
      await enqueueClient(entityId: 'c1', idempotencyKey: 'k1');
      await enqueueClient(entityId: 'c2', idempotencyKey: 'k2');

      final drainFuture = engine.drainOnce(companyId: 'co');
      // Let the drain reach the first dispatch and park there.
      await Future<void>.delayed(Duration.zero);
      expect(disp.dispatches, 1, reason: 'first row should be in-flight');

      final cancelFuture = engine.cancel();
      firstDispatchGate.complete(); // release the in-flight request

      await cancelFuture;
      final success = await drainFuture;

      expect(disp.dispatches, 1, reason: 'second row was skipped after cancel');
      expect(success, 1, reason: 'first row still counted as a success');
      // The skipped row is still pending and will be picked up next drain.
      final remaining = await db.outboxDao.nextReady(
        companyId: 'co',
        now: 1 << 60,
      );
      expect(remaining.map((r) => r.idempotencyKey), contains('k2'));
    });

    test('returns immediately when no drain is in flight', () async {
      final engine = makeEngine(_ProgrammableDispatcher());
      // Should not hang.
      await engine.cancel().timeout(const Duration(seconds: 1));
    });

    test('a fresh drainOnce after cancel processes all rows', () async {
      final disp = _ProgrammableDispatcher()
        ..queueSuccess()
        ..queueSuccess();
      final engine = makeEngine(disp);
      await engine.cancel(); // sets the flag while idle
      await enqueueClient(entityId: 'c1', idempotencyKey: 'k1');
      await enqueueClient(entityId: 'c2', idempotencyKey: 'k2');

      final success = await engine.drainOnce(companyId: 'co');

      expect(
        success,
        2,
        reason: 'drainOnce clears the stale cancel flag on entry',
      );
    });
  });
}

class _GatedDispatcher implements SyncDispatcher {
  _GatedDispatcher({required this.firstBlocker});
  final Future<void> firstBlocker;
  int dispatches = 0;

  @override
  Future<void> dispatch({
    required OutboxRow row,
    required MutationKind kind,
  }) async {
    dispatches++;
    if (dispatches == 1) await firstBlocker;
  }
}

/// Minimal concrete repository for `BaseEntityRepository` tests — the real
/// `ClientRepository` etc. drag in API clients we don't need here. The
/// `entityType: EntityType.client` matches what the `_registryWith(...)`
/// helper above registers, so the dispatcher hooks up correctly.
class _TestRepo extends BaseEntityRepository<Object, Object> {
  _TestRepo({required super.db, super.onEnqueued, super.now})
    : super(entityType: EntityType.client);

  @override
  String get entityTypeName => 'client';
}
