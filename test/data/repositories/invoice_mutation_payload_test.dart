import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/services/invoices_api.dart';

class _FakeInvoicesApi implements InvoicesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Regression: `UpdateInvoiceRequest` 422s (`invoice_status_changed`) if the
/// PUT carries a `paid_to_date` that differs from the server's current value.
/// In an offline-first client the cached value can be stale, so we must NOT
/// assert `paid_to_date` on the outbound create/update — but the display /
/// live-preview serialization (`toApiJson`) must still carry it.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  InvoiceRepository repo() => InvoiceRepository(
    db: db,
    api: _FakeInvoicesApi(),
    settings: SettingsRepository(db: db),
  );

  Future<void> seedCompany() => db.companiesDao.upsertAll([
    CompaniesCompanion.insert(
      id: 'co',
      name: 'Acme',
      settings: jsonEncode(<String, dynamic>{}),
      permissions: '',
      accountId: 'acct',
      token: 'tok',
      updatedAt: 1700000000,
    ),
  ]);

  Future<List<OutboxRow>> outbox() =>
      db.outboxDao.nextReady(companyId: 'co', now: 1 << 60);

  // A draft invoice that already carries a server-derived paid_to_date.
  Invoice paidInvoice() => Invoice.fromApi(
    const InvoiceApi(id: 'inv1', statusId: '1', paidToDate: '50'),
  );

  test('save() outbox payload omits paid_to_date', () async {
    await seedCompany();
    await repo().save(companyId: 'co', invoice: paidInvoice());
    final rows = await outbox();
    expect(rows, hasLength(1));
    final payload = jsonDecode(rows.single.payload) as Map<String, dynamic>;
    expect(payload.containsKey('paid_to_date'), isFalse);
  });

  test('create() outbox payload omits paid_to_date', () async {
    await seedCompany();
    await repo().create(companyId: 'co', draft: paidInvoice());
    final rows = await outbox();
    expect(rows, hasLength(1));
    final payload = jsonDecode(rows.single.payload) as Map<String, dynamic>;
    expect(payload.containsKey('paid_to_date'), isFalse);
  });

  test('toApiJson (display / live-preview) still carries paid_to_date', () {
    expect(paidInvoice().toApiJson().containsKey('paid_to_date'), isTrue);
  });
}
