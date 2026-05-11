import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('upsert + get round-trips', () async {
    await db.userSettingsDao.upsert(
      UserSettingsCompanion(
        companyId: const Value('co'),
        userId: const Value('u'),
        tableColumnsJson: Value(
          jsonEncode({
            'EntityType.client': ['name'],
          }),
        ),
        extraJson: Value(jsonEncode({'accent_color': '#f00'})),
        updatedAt: const Value(123),
      ),
    );
    final row = await db.userSettingsDao.get('co');
    expect(row, isNotNull);
    expect(row!.userId, 'u');
    expect(row.updatedAt, 123);
    final tc = jsonDecode(row.tableColumnsJson) as Map<String, dynamic>;
    expect(tc['EntityType.client'], ['name']);
  });

  test('writeTableColumns updates only that column', () async {
    await db.userSettingsDao.upsert(
      UserSettingsCompanion(
        companyId: const Value('co'),
        userId: const Value('u'),
        tableColumnsJson: const Value('{}'),
        extraJson: Value(jsonEncode({'accent_color': '#f00'})),
        updatedAt: const Value(0),
      ),
    );
    await db.userSettingsDao.writeTableColumns(
      companyId: 'co',
      tableColumnsJson: jsonEncode({
        'EntityType.client': ['balance'],
      }),
      now: 555,
    );
    final row = await db.userSettingsDao.get('co');
    expect(row!.updatedAt, 555);
    // extra_json untouched.
    expect((jsonDecode(row.extraJson) as Map)['accent_color'], '#f00');
  });

  test('watch emits the latest row', () async {
    final stream = db.userSettingsDao.watch('co');
    await db.userSettingsDao.upsert(
      UserSettingsCompanion(
        companyId: const Value('co'),
        userId: const Value('u'),
        updatedAt: const Value(1),
      ),
    );
    final emitted = await stream.first;
    expect(emitted, isNotNull);
    expect(emitted!.userId, 'u');
  });
}
