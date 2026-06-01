import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/statics_repository.dart';
import 'package:admin/data/services/statics_service.dart';

/// A statics service that fails loudly — `applyStatic` must never reach the
/// network, so any `fetch()` here would be a bug.
class _ThrowingStaticsService implements StaticsService {
  @override
  Future<Map<String, dynamic>> fetch() async =>
      throw StateError('StaticsService.fetch should not be called');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late StaticsRepository statics;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    statics = StaticsRepository(db: db, service: _ThrowingStaticsService());
  });
  tearDown(() async {
    await db.close();
  });

  group('applyStatic', () {
    test('no-ops on null without touching the cache', () async {
      await statics.applyStatic(null);
      expect(await db.staticsDao.read(), isNull);
      expect(statics.currencies, isEmpty);
    });

    test('no-ops on the empty map a delta refresh carries', () async {
      // A delta /refresh (no include_static) returns `static: {}`. Writing
      // that would blank every dropdown — guard must short-circuit.
      await statics.applyStatic(const <String, dynamic>{});
      expect(await db.staticsDao.read(), isNull);
      expect(statics.currencies, isEmpty);
    });

    test('writes a non-empty blob through and warms typed views', () async {
      await statics.applyStatic(const {
        'currencies': [
          {'id': '1', 'name': 'US Dollar', 'code': 'USD'},
        ],
      });

      final cached = await db.staticsDao.read();
      expect(cached, isNotNull);
      expect(cached!.payload, contains('US Dollar'));
      expect(statics.currency('1')?.name, 'US Dollar');
    });

    test(
      'does not blank a populated cache when later given an empty map',
      () async {
        await statics.applyStatic(const {
          'currencies': [
            {'id': '1', 'name': 'US Dollar', 'code': 'USD'},
          ],
        });
        await statics.applyStatic(const <String, dynamic>{});

        expect(statics.currency('1')?.name, 'US Dollar');
        expect((await db.staticsDao.read())!.payload, contains('US Dollar'));
      },
    );
  });
}
