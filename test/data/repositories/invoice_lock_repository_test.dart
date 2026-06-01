import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/domain/billing/invoice_lock.dart';
import 'package:admin/domain/sync/mutation.dart';

class _FakeInvoicesApi implements InvoicesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  InvoiceRepository repo() => InvoiceRepository(
    db: db,
    api: _FakeInvoicesApi(),
    settings: SettingsRepository(db: db),
  );

  Future<void> seedCompany(Map<String, dynamic> settings) =>
      db.companiesDao.upsertAll([
        CompaniesCompanion.insert(
          id: 'co',
          name: 'Acme',
          settings: jsonEncode(settings),
          permissions: '',
          accountId: 'acct',
          token: 'tok',
          updatedAt: 1700000000,
        ),
      ]);

  // status_id 2 = sent.
  Invoice sentInvoice() =>
      Invoice.fromApi(const InvoiceApi(id: 'inv1', statusId: '2'));

  Future<List<OutboxRow>> outbox() =>
      db.outboxDao.nextReady(companyId: 'co', now: 1 << 60);

  test(
    'save() on a locked (sent) invoice throws and enqueues nothing',
    () async {
      await seedCompany({'lock_invoices': 'when_sent'});
      await expectLater(
        repo().save(companyId: 'co', invoice: sentInvoice()),
        throwsA(isA<InvoiceLockedException>()),
      );
      expect(await outbox(), isEmpty);
    },
  );

  test('save() with a SAVE-PARAM status transition is NOT blocked', () async {
    await seedCompany({'lock_invoices': 'when_sent'});
    await repo().save(
      companyId: 'co',
      invoice: sentInvoice(),
      extraQuery: const {'mark_sent': 'true'},
    );
    expect((await outbox()).single.mutationKind, MutationKind.update.wireName);
  });

  test('save() enqueues normally when lock_invoices is off', () async {
    await seedCompany({'lock_invoices': 'off'});
    await repo().save(companyId: 'co', invoice: sentInvoice());
    expect((await outbox()).single.entityId, 'inv1');
  });

  test('create() of a draft is never gated, even with when_sent', () async {
    await seedCompany({'lock_invoices': 'when_sent'});
    final draft = Invoice.fromApi(const InvoiceApi(id: '', statusId: '1'));
    await repo().create(companyId: 'co', draft: draft);
    expect((await outbox()).single.mutationKind, MutationKind.create.wireName);
  });
}
