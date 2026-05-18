import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/db/dao/billing_extra_filters.dart';

/// Locks down the local-side filtering gap: the standalone Invoice / Quote /
/// Credit / Payment / Expense lists render from the Drift cache via
/// `watchPage`, which used to ignore `extraFilters` entirely (only the
/// server fetch honored them) — so `client:` / `status:` / `date_range:`
/// filters looked like they did nothing. These tests assert the parsers and
/// the per-DAO predicates now constrain the local watch.
void main() {
  group('billing_extra_filters parsers', () {
    test('client_id / status_id / categories / overdue', () {
      expect(parseClientIdFilter({'client_id': {'c1', 'c2'}}), {'c1', 'c2'});
      expect(parseClientIdFilter(const {}), isEmpty);
      expect(parseInvoiceStatusFilter({'status_id': {'4'}}), {'4'});
      expect(parseExpenseCategoryFilter({'categories': {'k1'}}), {'k1'});
      expect(parseOverdueFilter({'overdue': {'true'}}), isTrue);
      expect(parseOverdueFilter(const {}), isFalse);
    });

    test('payment client_status wire labels map to status discriminators', () {
      expect(
        parsePaymentStatusFilter({
          'client_status': {'completed', 'partially_unapplied', 'pending'},
        }),
        {'4', '-2', '1'},
      );
      expect(parsePaymentStatusFilter(const {}), isEmpty);
    });

    test('quote client_status passes wire labels through', () {
      expect(
        parseQuoteStatusFilter({'client_status': {'expired', 'draft'}}),
        {'expired', 'draft'},
      );
    });

    test('date_range: arity-tolerant (last two parts) — canonical & legacy',
        () {
      // Canonical v5 `column,start,end`.
      expect(
        parseDateRangeFilter({'date_range': {'date,2026-01-01,2026-03-31'}}),
        (start: '2026-01-01', end: '2026-03-31'),
      );
      // Legacy 2-part (pre-upgrade persisted filter).
      expect(
        parseDateRangeFilter({'date_range': {'2026-01-01,2026-03-31'}}),
        (start: '2026-01-01', end: '2026-03-31'),
      );
      // Legacy payment `label,start,end`.
      expect(
        parseDateRangeFilter(
          {'date_range': {'This quarter,2026-01-01,2026-03-31'}},
        ),
        (start: '2026-01-01', end: '2026-03-31'),
      );
      // Malformed / absent → no window.
      expect(
        parseDateRangeFilter({'date_range': {'only-one'}}),
        (start: null, end: null),
      );
      expect(
        parseDateRangeFilter(const {}),
        (start: null, end: null),
      );
    });
  });

  group('local DAO predicates', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<List<String>> ids(Stream<List<dynamic>> s) =>
        s.first.then((r) => r.map((e) => e.id as String).toList()..sort());

    test('credit watchPage filters by client_id (the reported bug)', () async {
      await db.creditDao.upsert(CreditsCompanion.insert(
        id: 'a', companyId: 'co', updatedAt: 1, payload: '{}',
        clientId: const Value('c1'),
      ));
      await db.creditDao.upsert(CreditsCompanion.insert(
        id: 'b', companyId: 'co', updatedAt: 2, payload: '{}',
        clientId: const Value('c2'),
      ));

      expect(
        await ids(db.creditDao.watchPage(
          companyId: 'co', offset: 0, limit: 50, clientIds: const {'c1'},
        )),
        ['a'],
      );
      // No filter → both rows (the old, unfiltered behaviour still works).
      expect(
        await ids(db.creditDao.watchPage(companyId: 'co', offset: 0, limit: 50)),
        ['a', 'b'],
      );
    });

    test('invoice watchPage: status_id, overdue, date_range', () async {
      // paid (4), sent (2) past-due w/ balance, sent (2) future-due.
      await db.invoiceDao.upsert(InvoicesCompanion.insert(
        id: 'paid', companyId: 'co', updatedAt: 1, payload: '{}',
        statusId: const Value('4'), date: const Value('2026-02-01'),
      ));
      await db.invoiceDao.upsert(InvoicesCompanion.insert(
        id: 'late', companyId: 'co', updatedAt: 2, payload: '{}',
        statusId: const Value('2'), balance: const Value('10'),
        dueDate: const Value('2026-01-01'), date: const Value('2026-01-15'),
      ));
      await db.invoiceDao.upsert(InvoicesCompanion.insert(
        id: 'future', companyId: 'co', updatedAt: 3, payload: '{}',
        statusId: const Value('2'), balance: const Value('10'),
        dueDate: const Value('2099-01-01'), date: const Value('2026-06-01'),
      ));

      expect(
        await ids(db.invoiceDao.watchPage(
          companyId: 'co', offset: 0, limit: 50, statusIds: const {'4'},
        )),
        ['paid'],
      );
      expect(
        await ids(db.invoiceDao.watchPage(
          companyId: 'co', offset: 0, limit: 50, overdueAsOf: '2026-05-17',
        )),
        ['late'],
      );
      expect(
        await ids(db.invoiceDao.watchPage(
          companyId: 'co', offset: 0, limit: 50,
          dateStart: '2026-01-01', dateEnd: '2026-03-01',
        )),
        ['late', 'paid'],
      );
    });

    test('quote watchPage: converted / expired / draft computed status',
        () async {
      await db.quoteDao.upsert(QuotesCompanion.insert(
        id: 'draft', companyId: 'co', updatedAt: 1, payload: '{}',
        statusId: const Value('1'), dueDate: const Value('2099-01-01'),
      ));
      await db.quoteDao.upsert(QuotesCompanion.insert(
        id: 'conv', companyId: 'co', updatedAt: 2, payload: '{}',
        statusId: const Value('2'), invoiceId: const Value('inv1'),
      ));
      await db.quoteDao.upsert(QuotesCompanion.insert(
        id: 'exp', companyId: 'co', updatedAt: 3, payload: '{}',
        statusId: const Value('2'), dueDate: const Value('2026-01-01'),
      ));

      expect(
        await ids(db.quoteDao.watchPage(
          companyId: 'co', offset: 0, limit: 50,
          statuses: const {'converted'}, statusAsOf: '2026-05-17',
        )),
        ['conv'],
      );
      expect(
        await ids(db.quoteDao.watchPage(
          companyId: 'co', offset: 0, limit: 50,
          statuses: const {'expired'}, statusAsOf: '2026-05-17',
        )),
        ['exp'],
      );
      expect(
        await ids(db.quoteDao.watchPage(
          companyId: 'co', offset: 0, limit: 50,
          statuses: const {'draft'}, statusAsOf: '2026-05-17',
        )),
        ['draft'],
      );
    });

    test('payment watchPage: client_id + date_range', () async {
      await db.paymentDao.upsert(PaymentsCompanion.insert(
        id: 'a', companyId: 'co', updatedAt: 1, payload: '{}',
        clientId: const Value('c1'), date: const Value('2026-02-10'),
      ));
      await db.paymentDao.upsert(PaymentsCompanion.insert(
        id: 'b', companyId: 'co', updatedAt: 2, payload: '{}',
        clientId: const Value('c2'), date: const Value('2026-09-10'),
      ));

      expect(
        await ids(db.paymentDao.watchPage(
          companyId: 'co', offset: 0, limit: 50, clientIds: const {'c1'},
        )),
        ['a'],
      );
      expect(
        await ids(db.paymentDao.watchPage(
          companyId: 'co', offset: 0, limit: 50,
          dateStart: '2026-01-01', dateEnd: '2026-03-01',
        )),
        ['a'],
      );
    });

    test('expense watchPage: client_id + categories', () async {
      await db.expenseDao.upsert(ExpensesCompanion.insert(
        id: 'a', companyId: 'co', updatedAt: 1, payload: '{}',
        clientId: const Value('c1'), categoryId: const Value('k1'),
      ));
      await db.expenseDao.upsert(ExpensesCompanion.insert(
        id: 'b', companyId: 'co', updatedAt: 2, payload: '{}',
        clientId: const Value('c1'), categoryId: const Value('k2'),
      ));

      expect(
        await ids(db.expenseDao.watchPage(
          companyId: 'co', offset: 0, limit: 50, categoryIds: const {'k1'},
        )),
        ['a'],
      );
      expect(
        await ids(db.expenseDao.watchPage(
          companyId: 'co', offset: 0, limit: 50, clientIds: const {'c1'},
        )),
        ['a', 'b'],
      );
    });
  });
}
