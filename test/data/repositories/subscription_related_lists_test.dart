import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/api/recurring_invoice_api_model.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/data/repositories/recurring_invoice_repository.dart';
import 'package:admin/data/repositories/settings_repository.dart';
import 'package:admin/data/services/invoices_api.dart';
import 'package:admin/data/services/recurring_invoices_api.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the Payment Link detail screen's embedded related lists: invoices
/// and recurring invoices are filtered locally by the denormalized
/// `subscription_id` column (`watchForSubscription`, mirroring
/// `watchForClient`).
class _FakeInvoicesApi implements InvoicesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeRecurringInvoicesApi implements RecurringInvoicesApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  InvoiceRepository invoiceRepo() => InvoiceRepository(
    db: db,
    api: _FakeInvoicesApi(),
    settings: SettingsRepository(db: db),
  );

  RecurringInvoiceRepository recurringRepo() =>
      RecurringInvoiceRepository(db: db, api: _FakeRecurringInvoicesApi());

  group('watchForSubscription', () {
    test(
      'invoices: returns only rows with a matching subscription_id',
      () async {
        final repo = invoiceRepo();
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'i1',
          serverResponse: const InvoiceApi(
            id: 'i1',
            statusId: '2',
            updatedAt: 1700000000,
            subscriptionId: 'sub_a',
          ),
        );
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'i2',
          serverResponse: const InvoiceApi(
            id: 'i2',
            statusId: '2',
            updatedAt: 1700000001,
            subscriptionId: 'sub_b',
          ),
        );
        await repo.applyCreateResponse(
          companyId: 'co',
          tempId: 'i3',
          serverResponse: const InvoiceApi(
            id: 'i3',
            statusId: '2',
            updatedAt: 1700000002,
            subscriptionId: 'sub_a',
          ),
        );

        final forA = await repo
            .watchForSubscription(companyId: 'co', subscriptionId: 'sub_a')
            .first;
        expect(forA.map((i) => i.id), unorderedEquals(['i1', 'i3']));
      },
    );

    test('invoices: empty subscriptionId yields an empty list', () async {
      final repo = invoiceRepo();
      final result = await repo
          .watchForSubscription(companyId: 'co', subscriptionId: '')
          .first;
      expect(result, isEmpty);
    });

    test('recurring invoices: filters by subscription_id', () async {
      final repo = recurringRepo();
      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: 'r1',
        serverResponse: const RecurringInvoiceApi(
          id: 'r1',
          statusId: '2',
          updatedAt: 1700000000,
          subscriptionId: 'sub_a',
        ),
      );
      await repo.applyCreateResponse(
        companyId: 'co',
        tempId: 'r2',
        serverResponse: const RecurringInvoiceApi(
          id: 'r2',
          statusId: '2',
          updatedAt: 1700000001,
          subscriptionId: 'sub_b',
        ),
      );

      final forA = await repo
          .watchForSubscription(companyId: 'co', subscriptionId: 'sub_a')
          .first;
      expect(forA.map((r) => r.id), unorderedEquals(['r1']));
    });
  });
}
