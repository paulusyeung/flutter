import 'dart:convert';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/api/schedule_item_api_model.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/domain/sync/mutation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the FEATURES-156 rebuild: the `payment_schedule_*` outbox rows and
/// the `schedule` dedicated-Drift-column round-trip (the 112-locations
/// pattern — `Invoice.toApiJson` omits `schedule`, so a local `repo.save`
/// must not wipe a server-sourced schedule).
class _FakeInvoicesApi implements InvoicesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  InvoiceRepository repo() =>
      InvoiceRepository(db: db, api: _FakeInvoicesApi());

  InvoiceApi api(String id, {List<ScheduleItemApi>? schedule}) =>
      InvoiceApi(id: id, statusId: '2', updatedAt: 1700000000,
          schedule: schedule);

  Future<List<OutboxRow>> outbox() =>
      db.outboxDao.nextReady(companyId: 'co', now: 1 << 60);

  group('payment-schedule outbox rows', () {
    test('createPaymentSchedule enqueues payment_schedule_create', () async {
      final r = repo();
      await r.createPaymentSchedule(
        companyId: 'co',
        id: 'inv1',
        body: const {'template': 'payment_schedule'},
      );
      final p = (await outbox()).single;
      expect(p.mutationKind, MutationKind.paymentScheduleCreate.wireName);
      expect(p.entityId, 'inv1');
      final payload = jsonDecode(p.payload) as Map<String, dynamic>;
      expect(payload['id'], 'inv1');
      expect((payload['body'] as Map)['template'], 'payment_schedule');
    });

    test('createCustom enqueues payment_schedule_create_custom', () async {
      final r = repo();
      await r.createCustomPaymentSchedule(
        companyId: 'co',
        id: 'inv1',
        body: const {'template': 'payment_schedule'},
      );
      expect(
        (await outbox()).single.mutationKind,
        MutationKind.paymentScheduleCreateCustom.wireName,
      );
    });

    test('deletePaymentSchedule enqueues payment_schedule_delete', () async {
      final r = repo();
      await r.deletePaymentSchedule(companyId: 'co', id: 'inv1');
      final p = (await outbox()).single;
      expect(p.mutationKind, MutationKind.paymentScheduleDelete.wireName);
      expect(p.entityId, 'inv1');
    });

    test('sendEInvoice enqueues a send_e_invoice row', () async {
      final r = repo();
      await r.sendEInvoice(companyId: 'co', id: 'inv1');
      final p = (await outbox()).single;
      expect(p.mutationKind, MutationKind.sendEInvoice.wireName);
      expect(p.entityId, 'inv1');
    });
  });

  group('schedule Drift round-trip (dedicated column)', () {
    test('show_schedule upsert persists; plain upsert + edit preserve it',
        () async {
      final r = repo();

      // 1. A `?show_schedule=true` response (schedule present) persists via
      //    _apiToCompanion → _fromRow overlay.
      await r.applyUpdateResponse(
        companyId: 'co',
        serverResponse: api('inv1', schedule: const [
          ScheduleItemApi(date: '2026-06-01', amount: '50', autoBill: true),
        ]),
      );
      var back = await r.watch(companyId: 'co', id: 'inv1').first;
      expect(back!.schedule, hasLength(1));
      expect(back.schedule.single.date, '2026-06-01');

      // 2. A later plain/list upsert OMITS schedule (null) → must NOT wipe
      //    the stored column (the documents-style preserve guard).
      await r.applyUpdateResponse(
        companyId: 'co',
        serverResponse: api('inv1'), // schedule == null
      );
      back = await r.watch(companyId: 'co', id: 'inv1').first;
      expect(
        back!.schedule,
        hasLength(1),
        reason: 'schedule-less response must not clobber the column',
      );

      // 3. A local invoice edit-save must preserve it (Invoice.toApiJson
      //    omits schedule; the dedicated column round-trips it).
      await r.save(
        companyId: 'co',
        invoice: back.copyWith(number: 'INV-RENAMED'),
      );
      final edited = await r.watch(companyId: 'co', id: 'inv1').first;
      expect(edited!.number, 'INV-RENAMED');
      expect(
        edited.schedule,
        hasLength(1),
        reason: 'editing the invoice must preserve its payment schedule',
      );
    });
  });
}
