import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/system_log_api_model.dart';
import 'package:admin/data/repositories/system_log_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/system_logs_api.dart';

class _FakeApi implements SystemLogsApi {
  _FakeApi(this._scripted);

  /// Each entry is consumed in order: either a `SystemLogListApi` payload
  /// or an `Object` to throw.
  final List<Object> _scripted;
  int calls = 0;

  @override
  Future<SystemLogListApi> fetchPage({
    int perPage = 200,
    String sort = 'created_at|DESC',
  }) async {
    calls++;
    if (_scripted.isEmpty) {
      throw StateError('no scripted response');
    }
    final next = _scripted.removeAt(0);
    if (next is SystemLogListApi) return next;
    throw next;
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  SystemLogApi row(
    String id, {
    int createdAt = 1778830000,
    int categoryId = 2,
    int eventId = 30,
    int typeId = 303,
    String log = '"hello"',
  }) => SystemLogApi(
    id: id,
    companyId: 'c1',
    userId: 'u1',
    clientId: '',
    eventId: eventId,
    categoryId: categoryId,
    typeId: typeId,
    log: log,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  group('SystemLogRepository — happy path', () {
    test('refresh writes rows; watch emits them newest first', () async {
      final api = _FakeApi([
        SystemLogListApi(
          data: [
            row('older', createdAt: 1000),
            row('newest', createdAt: 3000),
            row('middle', createdAt: 2000),
          ],
        ),
      ]);
      final repo = SystemLogRepository(db: db, api: api);

      final result = await repo.refresh('c1');
      expect(result, SystemLogRefreshResult.ok);

      final emitted = await repo.watch('c1').first;
      expect(emitted.map((r) => r.id).toList(), ['newest', 'middle', 'older']);
      expect(emitted.first.log, '"hello"');
    });

    test('replace-on-refresh purges rows that vanished server-side', () async {
      final api = _FakeApi([
        SystemLogListApi(data: [row('a'), row('b'), row('c')]),
        // Server deletes 'b' upstream → only a + c on second fetch.
        SystemLogListApi(data: [row('a'), row('c')]),
      ]);
      final repo = SystemLogRepository(db: db, api: api);

      await repo.refresh('c1');
      expect((await repo.watch('c1').first).map((r) => r.id).toSet(), {
        'a',
        'b',
        'c',
      });

      await repo.refresh('c1');
      expect((await repo.watch('c1').first).map((r) => r.id).toSet(), {
        'a',
        'c',
      });
    });

    test('lastFetchedAt persists after a 0-row refresh', () async {
      final now = DateTime.utc(2026, 5, 15, 12, 0, 0);
      final api = _FakeApi([
        // Account with zero system logs — DAO MAX(fetched_at) would be NULL.
        const SystemLogListApi(data: <SystemLogApi>[]),
      ]);
      final repo = SystemLogRepository(db: db, api: api, now: () => now);

      expect(await repo.refresh('c1'), SystemLogRefreshResult.ok);

      // The DAO's cache is empty, but the repo's in-memory fallback should
      // keep the timestamp so the staleness check doesn't refire forever.
      expect(await repo.lastFetchedAt('c1'), now);
    });

    test('lastFetchedAt advances after refresh', () async {
      var now = DateTime.utc(2026, 5, 15, 12, 0, 0);
      final api = _FakeApi([
        SystemLogListApi(data: [row('a')]),
      ]);
      final repo = SystemLogRepository(db: db, api: api, now: () => now);

      expect(await repo.lastFetchedAt('c1'), isNull);

      await repo.refresh('c1');
      final first = await repo.lastFetchedAt('c1');
      expect(first, isNotNull);
      expect(first!.toUtc(), now);

      // Second refresh after time passes.
      now = DateTime.utc(2026, 5, 15, 13, 0, 0);
      api._scripted.add(SystemLogListApi(data: [row('a')]));
      await repo.refresh('c1');
      expect(await repo.lastFetchedAt('c1'), now);
    });

    test('rows are scoped per company', () async {
      final api1 = _FakeApi([
        SystemLogListApi(data: [row('x')]),
      ]);
      final repo = SystemLogRepository(db: db, api: api1);
      await repo.refresh('c1');

      final empty = await repo.watch('c2').first;
      expect(empty, isEmpty);
      final full = await repo.watch('c1').first;
      expect(full, hasLength(1));
    });
  });

  group('SystemLogRepository — refresh-result mapping', () {
    test('403 → forbidden; cache untouched', () async {
      final api = _FakeApi([
        SystemLogListApi(data: [row('first')]),
        const ServerException(403, 'forbidden'),
      ]);
      final repo = SystemLogRepository(db: db, api: api);
      await repo.refresh('c1');

      final result = await repo.refresh('c1');
      expect(result, SystemLogRefreshResult.forbidden);

      final rows = await repo.watch('c1').first;
      expect(rows.single.id, 'first');
    });

    test('404 → notFound; cache untouched', () async {
      final api = _FakeApi([
        SystemLogListApi(data: [row('keep')]),
        const ServerException(404, 'not found'),
      ]);
      final repo = SystemLogRepository(db: db, api: api);
      await repo.refresh('c1');

      final result = await repo.refresh('c1');
      expect(result, SystemLogRefreshResult.notFound);
      final rows = await repo.watch('c1').first;
      expect(rows.single.id, 'keep');
    });

    test('412 password-required → forbidden', () async {
      final api = _FakeApi([const PasswordRequiredException()]);
      final repo = SystemLogRepository(db: db, api: api);
      expect(await repo.refresh('c1'), SystemLogRefreshResult.forbidden);
    });

    test('network error → networkError without throwing', () async {
      final api = _FakeApi([const NetworkException('offline')]);
      final repo = SystemLogRepository(db: db, api: api);
      expect(await repo.refresh('c1'), SystemLogRefreshResult.networkError);
    });

    test('empty companyId is a no-op', () async {
      final api = _FakeApi([]);
      final repo = SystemLogRepository(db: db, api: api);
      expect(await repo.refresh(''), SystemLogRefreshResult.ok);
      expect(api.calls, 0);
    });
  });
}
