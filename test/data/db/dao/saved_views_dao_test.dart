import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  Future<void> insert({
    String id = 'v1',
    String companyId = 'co',
    String entityType = 'client',
    String name = 'My view',
    String payloadJson = '{"v":1,"data":{}}',
    int createdAt = 1,
    int updatedAt = 1,
  }) => db.savedViewsDao.insertView(
    SavedViewsCompanion(
      id: Value(id),
      companyId: Value(companyId),
      entityType: Value(entityType),
      name: Value(name),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    ),
  );

  test('insert + byId round-trips', () async {
    await insert(payloadJson: '{"v":1,"data":{"search":"acme"}}');
    final row = await db.savedViewsDao.byId('v1');
    expect(row, isNotNull);
    expect(row!.companyId, 'co');
    expect(row.entityType, 'client');
    expect(row.name, 'My view');
    expect(row.payloadJson, '{"v":1,"data":{"search":"acme"}}');
  });

  test('watchAll filters by company and orders by name', () async {
    await insert(id: 'a', name: 'Zoo');
    await insert(id: 'b', name: 'Acme');
    // Different company — must not leak.
    await insert(id: 'c', companyId: 'other', name: 'Other');

    final rows = await db.savedViewsDao.watchAll('co').first;
    expect(rows.map((r) => r.id), ['b', 'a']);
  });

  test('watchForEntity filters by company and entity type', () async {
    await insert(id: 'a', entityType: 'client', name: 'Acme clients');
    await insert(id: 'b', entityType: 'product', name: 'Top products');
    await insert(id: 'c', entityType: 'client', name: 'Bay clients');

    final rows = await db.savedViewsDao.watchForEntity('co', 'client').first;
    expect(rows.map((r) => r.id), ['a', 'c']);
  });

  test('updateById writes name + payload + bumps updatedAt', () async {
    await insert();
    await db.savedViewsDao.updateById(
      id: 'v1',
      name: 'Renamed',
      payloadJson: '{"v":1,"data":{"search":"foo"}}',
      now: 99,
    );
    final row = await db.savedViewsDao.byId('v1');
    expect(row!.name, 'Renamed');
    expect(row.payloadJson, '{"v":1,"data":{"search":"foo"}}');
    expect(row.updatedAt, 99);
  });

  test('updateById with only name leaves payload untouched', () async {
    await insert(payloadJson: '{"v":1,"data":{"search":"orig"}}');
    await db.savedViewsDao.updateById(id: 'v1', name: 'New name', now: 5);
    final row = await db.savedViewsDao.byId('v1');
    expect(row!.name, 'New name');
    expect(row.payloadJson, '{"v":1,"data":{"search":"orig"}}');
  });

  test('deleteById removes the row', () async {
    await insert();
    await db.savedViewsDao.deleteById('v1');
    expect(await db.savedViewsDao.byId('v1'), isNull);
  });
}
