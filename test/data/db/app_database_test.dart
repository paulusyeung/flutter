import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    test('CompanyScopedDao isolates rows across companies', () async {
      await db.clientDao.upsert(
        ClientsCompanion.insert(
          id: 'a',
          companyId: 'co1',
          name: 'In company 1',
          number: '',
          email: '',
          displayName: '',
          balance: '0',
          updatedAt: 1,
          payload: '{}',
        ),
      );
      await db.clientDao.upsert(
        ClientsCompanion.insert(
          id: 'b',
          companyId: 'co2',
          name: 'In company 2',
          number: '',
          email: '',
          displayName: '',
          balance: '0',
          updatedAt: 1,
          payload: '{}',
        ),
      );

      final co1 = await db.clientDao
          .watchPage(companyId: 'co1', offset: 0, limit: 50)
          .first;
      final co2 = await db.clientDao
          .watchPage(companyId: 'co2', offset: 0, limit: 50)
          .first;
      expect(co1.map((c) => c.id), ['a']);
      expect(co2.map((c) => c.id), ['b']);
    });

    test('search matches on name, number, and email via LIKE', () async {
      await db.clientDao.upsertAll([
        ClientsCompanion.insert(
          id: '1',
          companyId: 'co',
          name: 'Stark Industries',
          number: 'C-1',
          email: 'tony@stark.test',
          displayName: '',
          balance: '0',
          updatedAt: 1,
          payload: '{}',
        ),
        ClientsCompanion.insert(
          id: '2',
          companyId: 'co',
          name: 'Wayne Enterprises',
          number: 'C-2',
          email: 'bruce@wayne.test',
          displayName: '',
          balance: '0',
          updatedAt: 1,
          payload: '{}',
        ),
      ]);

      final byName = await db.clientDao
          .watchPage(companyId: 'co', offset: 0, limit: 50, search: 'stark')
          .first;
      expect(byName.map((c) => c.id), ['1']);

      final byEmail = await db.clientDao
          .watchPage(companyId: 'co', offset: 0, limit: 50, search: 'wayne.test')
          .first;
      expect(byEmail.map((c) => c.id), ['2']);
    });

    test('id_remap remember+resolve round-trips', () async {
      await db.idRemapDao.remember(
        entityType: 'client',
        tempId: 'tmp_xyz',
        realId: 'real_123',
        now: 1,
      );
      final real = await db.idRemapDao
          .resolve(entityType: 'client', tempId: 'tmp_xyz');
      expect(real, 'real_123');
    });

    test('outbox enqueue + nextReady honors next_attempt_at', () async {
      await db.outboxDao.enqueue(
        OutboxCompanion.insert(
          companyId: 'co',
          entityType: 'client',
          entityId: 'tmp_a',
          mutationKind: 'create',
          payload: '{}',
          idempotencyKey: 'k1',
          nextAttemptAt: 100,
          createdAt: 0,
        ),
      );
      final tooEarly = await db.outboxDao.nextReady(companyId: 'co', now: 50);
      expect(tooEarly, isEmpty);

      final ready = await db.outboxDao.nextReady(companyId: 'co', now: 200);
      expect(ready, hasLength(1));
      expect(ready.first.entityId, 'tmp_a');
    });

    test('outbox rewriteTempIdInPayloads patches pending rows', () async {
      await db.outboxDao.enqueue(
        OutboxCompanion.insert(
          companyId: 'co',
          entityType: 'invoice',
          entityId: 'tmp_inv',
          mutationKind: 'create',
          payload: '{"client_id":"tmp_client"}',
          idempotencyKey: 'k',
          nextAttemptAt: 0,
          createdAt: 0,
        ),
      );

      await db.outboxDao.rewriteTempIdInPayloads(
        companyId: 'co',
        entityType: 'client',
        tempId: 'tmp_client',
        realId: 'real_c',
      );

      final rows = await db.outboxDao.nextReady(companyId: 'co', now: 1);
      expect(rows.single.payload, '{"client_id":"real_c"}');
    });
  });
}
