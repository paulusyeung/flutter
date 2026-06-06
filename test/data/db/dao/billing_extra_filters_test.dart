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
      expect(
        parseClientIdFilter({
          'client_id': {'c1', 'c2'},
        }),
        {'c1', 'c2'},
      );
      expect(parseClientIdFilter(const {}), isEmpty);
      expect(
        parseInvoiceStatusFilter({
          'status_id': {'4'},
        }),
        {'4'},
      );
      expect(
        parseExpenseCategoryFilter({
          'categories': {'k1'},
        }),
        {'k1'},
      );
      expect(
        parseOverdueFilter({
          'overdue': {'true'},
        }),
        isTrue,
      );
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
        parseQuoteStatusFilter({
          'client_status': {'expired', 'draft'},
        }),
        {'expired', 'draft'},
      );
    });

    test('credit client_status labels map to status_id wire ids', () {
      expect(
        parseCreditStatusFilter({
          'client_status': {'draft', 'partial', 'applied'},
        }),
        {'1', '3', '4'},
      );
      expect(
        parseCreditStatusFilter({
          'client_status': {'sent'},
        }),
        {'2'},
      );
      // Unknown label is dropped (no wire id), empty map → empty.
      expect(
        parseCreditStatusFilter({
          'client_status': {'bogus'},
        }),
        isEmpty,
      );
      expect(parseCreditStatusFilter(const {}), isEmpty);
    });

    test(
      'date_range: arity-tolerant (last two parts) — canonical & legacy',
      () {
        // Canonical v5 `column,start,end`.
        expect(
          parseDateRangeFilter({
            'date_range': {'date,2026-01-01,2026-03-31'},
          }),
          (start: '2026-01-01', end: '2026-03-31'),
        );
        // Legacy 2-part (pre-upgrade persisted filter).
        expect(
          parseDateRangeFilter({
            'date_range': {'2026-01-01,2026-03-31'},
          }),
          (start: '2026-01-01', end: '2026-03-31'),
        );
        // Legacy payment `label,start,end`.
        expect(
          parseDateRangeFilter({
            'date_range': {'This quarter,2026-01-01,2026-03-31'},
          }),
          (start: '2026-01-01', end: '2026-03-31'),
        );
        // Malformed / absent → no window.
        expect(
          parseDateRangeFilter({
            'date_range': {'only-one'},
          }),
          (start: null, end: null),
        );
        expect(parseDateRangeFilter(const {}), (start: null, end: null));
      },
    );

    test('parseComparableDateFilter: op:value, bare, window, rel', () {
      // Explicit operator prefix.
      expect(
        parseComparableDateFilter({
          'date': {'gte:2026-01-01'},
        }, 'date'),
        (op: 'gte', value: '2026-01-01'),
      );
      expect(
        parseComparableDateFilter({
          'date': {'lt:2026-02-01'},
        }, 'date'),
        (op: 'lt', value: '2026-02-01'),
      );
      // Bare value defaults to gte (the key's defaultOp).
      expect(
        parseComparableDateFilter({
          'date': {'2026-01-01'},
        }, 'date'),
        (op: 'gte', value: '2026-01-01'),
      );
      // A window wire (comma) belongs to the *_range slot, not here.
      expect(
        parseComparableDateFilter({
          'date': {'date,2026-01-01,2026-03-31'},
        }, 'date'),
        (op: null, value: null),
      );
      // Absent / blank → no comparator.
      expect(parseComparableDateFilter(const {}, 'date'), (
        op: null,
        value: null,
      ));
      expect(
        parseComparableDateFilter({
          'date': {''},
        }, 'date'),
        (op: null, value: null),
      );
      // Relative token resolves to absolute ISO (bare → gte; prefix keeps op).
      final now = DateTime.utc(2026, 1, 8);
      expect(
        parseComparableDateFilter(
          {
            'date': {'rel:d7'},
          },
          'date',
          now: now,
        ),
        (op: 'gte', value: '2026-01-01'),
      );
      expect(
        parseComparableDateFilter(
          {
            'date': {'lt:rel:d7'},
          },
          'date',
          now: now,
        ),
        (op: 'lt', value: '2026-01-01'),
      );
    });

    test('due_date_range: symmetric window parser on its own slot', () {
      expect(
        parseDueDateRangeFilter({
          'due_date_range': {'due_date,2026-02-01,2026-02-28'},
        }),
        (start: '2026-02-01', end: '2026-02-28'),
      );
      expect(
        parseDueDateRangeFilter({
          'due_date_range': {'2026-02-01,2026-02-28'},
        }),
        (start: '2026-02-01', end: '2026-02-28'),
      );
      // Reads only its own slot — a `date_range` value doesn't leak in.
      expect(
        parseDueDateRangeFilter({
          'date_range': {'date,2026-01-01,2026-03-31'},
        }),
        (start: null, end: null),
      );
      expect(parseDueDateRangeFilter(const {}), (start: null, end: null));
    });

    test('updated_at_range / created_at_range: clients between windows', () {
      // Canonical 3-part wire the `DateColumnFilterKey` between operator emits.
      expect(
        parseUpdatedAtRangeFilter({
          'updated_at_range': {'updated_at,2026-04-01,2026-04-30'},
        }),
        (start: '2026-04-01', end: '2026-04-30'),
      );
      expect(
        parseCreatedAtRangeFilter({
          'created_at_range': {'created_at,2026-01-01,2026-01-31'},
        }),
        (start: '2026-01-01', end: '2026-01-31'),
      );
      // Legacy 2-part still parses (arity-tolerant — last two parts).
      expect(
        parseUpdatedAtRangeFilter({
          'updated_at_range': {'2026-04-01,2026-04-30'},
        }),
        (start: '2026-04-01', end: '2026-04-30'),
      );
      // Each reads only its own slot — no cross-leak between the two windows.
      expect(
        parseCreatedAtRangeFilter({
          'updated_at_range': {'updated_at,2026-04-01,2026-04-30'},
        }),
        (start: null, end: null),
      );
      expect(parseUpdatedAtRangeFilter(const {}), (start: null, end: null));
      expect(parseCreatedAtRangeFilter(const {}), (start: null, end: null));
    });
  });

  group('local DAO predicates', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<List<String>> ids(Stream<List<dynamic>> s) =>
        s.first.then((r) => r.map((e) => e.id as String).toList()..sort());

    test('credit watchPage filters by client_id (the reported bug)', () async {
      await db.creditDao.upsert(
        CreditsCompanion.insert(
          id: 'a',
          companyId: 'co',
          updatedAt: 1,
          payload: '{}',
          clientId: const Value('c1'),
        ),
      );
      await db.creditDao.upsert(
        CreditsCompanion.insert(
          id: 'b',
          companyId: 'co',
          updatedAt: 2,
          payload: '{}',
          clientId: const Value('c2'),
        ),
      );

      expect(
        await ids(
          db.creditDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            clientIds: const {'c1'},
          ),
        ),
        ['a'],
      );
      // No filter → both rows (the old, unfiltered behaviour still works).
      expect(
        await ids(
          db.creditDao.watchPage(companyId: 'co', offset: 0, limit: 50),
        ),
        ['a', 'b'],
      );
    });

    test('credit watchPage: status filter (status_id membership)', () async {
      for (final (id, status) in [
        ('d', '1'), // draft
        ('s', '2'), // sent
        ('p', '3'), // partial
        ('ap', '4'), // applied
      ]) {
        await db.creditDao.upsert(
          CreditsCompanion.insert(
            id: id,
            companyId: 'co',
            updatedAt: 1,
            payload: '{}',
            statusId: Value(status),
          ),
        );
      }

      // Single status.
      expect(
        await ids(
          db.creditDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            statuses: const {'1'},
          ),
        ),
        ['d'],
      );
      // Multi-select ORs.
      expect(
        await ids(
          db.creditDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            statuses: const {'3', '4'},
          ),
        ),
        ['ap', 'p'],
      );
      // Empty set → no status predicate (all four rows).
      expect(
        await ids(
          db.creditDao.watchPage(companyId: 'co', offset: 0, limit: 50),
        ),
        ['ap', 'd', 'p', 's'],
      );
    });

    test('invoice watchPage: status_id, overdue, date_range', () async {
      // paid (4), sent (2) past-due w/ balance, sent (2) future-due.
      await db.invoiceDao.upsert(
        InvoicesCompanion.insert(
          id: 'paid',
          companyId: 'co',
          updatedAt: 1,
          payload: '{}',
          statusId: const Value('4'),
          date: const Value('2026-02-01'),
        ),
      );
      await db.invoiceDao.upsert(
        InvoicesCompanion.insert(
          id: 'late',
          companyId: 'co',
          updatedAt: 2,
          payload: '{}',
          statusId: const Value('2'),
          balance: const Value('10'),
          dueDate: const Value('2026-01-01'),
          date: const Value('2026-01-15'),
        ),
      );
      await db.invoiceDao.upsert(
        InvoicesCompanion.insert(
          id: 'future',
          companyId: 'co',
          updatedAt: 3,
          payload: '{}',
          statusId: const Value('2'),
          balance: const Value('10'),
          dueDate: const Value('2099-01-01'),
          date: const Value('2026-06-01'),
        ),
      );

      expect(
        await ids(
          db.invoiceDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            statusIds: const {'4'},
          ),
        ),
        ['paid'],
      );
      expect(
        await ids(
          db.invoiceDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            overdueAsOf: '2026-05-17',
          ),
        ),
        ['late'],
      );
      expect(
        await ids(
          db.invoiceDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            dateStart: '2026-01-01',
            dateEnd: '2026-03-01',
          ),
        ),
        ['late', 'paid'],
      );
    });

    test(
      'quote watchPage: converted / expired / draft computed status',
      () async {
        await db.quoteDao.upsert(
          QuotesCompanion.insert(
            id: 'draft',
            companyId: 'co',
            updatedAt: 1,
            payload: '{}',
            statusId: const Value('1'),
            dueDate: const Value('2099-01-01'),
          ),
        );
        await db.quoteDao.upsert(
          QuotesCompanion.insert(
            id: 'conv',
            companyId: 'co',
            updatedAt: 2,
            payload: '{}',
            statusId: const Value('2'),
            invoiceId: const Value('inv1'),
          ),
        );
        await db.quoteDao.upsert(
          QuotesCompanion.insert(
            id: 'exp',
            companyId: 'co',
            updatedAt: 3,
            payload: '{}',
            statusId: const Value('2'),
            dueDate: const Value('2026-01-01'),
          ),
        );

        expect(
          await ids(
            db.quoteDao.watchPage(
              companyId: 'co',
              offset: 0,
              limit: 50,
              statuses: const {'converted'},
              statusAsOf: '2026-05-17',
            ),
          ),
          ['conv'],
        );
        expect(
          await ids(
            db.quoteDao.watchPage(
              companyId: 'co',
              offset: 0,
              limit: 50,
              statuses: const {'expired'},
              statusAsOf: '2026-05-17',
            ),
          ),
          ['exp'],
        );
        expect(
          await ids(
            db.quoteDao.watchPage(
              companyId: 'co',
              offset: 0,
              limit: 50,
              statuses: const {'draft'},
              statusAsOf: '2026-05-17',
            ),
          ),
          ['draft'],
        );
      },
    );

    test('payment watchPage: client_id + date_range', () async {
      await db.paymentDao.upsert(
        PaymentsCompanion.insert(
          id: 'a',
          companyId: 'co',
          updatedAt: 1,
          payload: '{}',
          clientId: const Value('c1'),
          date: const Value('2026-02-10'),
        ),
      );
      await db.paymentDao.upsert(
        PaymentsCompanion.insert(
          id: 'b',
          companyId: 'co',
          updatedAt: 2,
          payload: '{}',
          clientId: const Value('c2'),
          date: const Value('2026-09-10'),
        ),
      );

      expect(
        await ids(
          db.paymentDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            clientIds: const {'c1'},
          ),
        ),
        ['a'],
      );
      expect(
        await ids(
          db.paymentDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            dateStart: '2026-01-01',
            dateEnd: '2026-03-01',
          ),
        ),
        ['a'],
      );
    });

    test('expense watchPage: client_id + categories', () async {
      await db.expenseDao.upsert(
        ExpensesCompanion.insert(
          id: 'a',
          companyId: 'co',
          updatedAt: 1,
          payload: '{}',
          clientId: const Value('c1'),
          categoryId: const Value('k1'),
        ),
      );
      await db.expenseDao.upsert(
        ExpensesCompanion.insert(
          id: 'b',
          companyId: 'co',
          updatedAt: 2,
          payload: '{}',
          clientId: const Value('c1'),
          categoryId: const Value('k2'),
        ),
      );

      expect(
        await ids(
          db.expenseDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            categoryIds: const {'k1'},
          ),
        ),
        ['a'],
      );
      expect(
        await ids(
          db.expenseDao.watchPage(
            companyId: 'co',
            offset: 0,
            limit: 50,
            clientIds: const {'c1'},
          ),
        ),
        ['a', 'b'],
      );
    });
  });

  group('resolveRelativeDateToken', () {
    final now = DateTime(2026, 5, 18, 9, 30, 15);

    test('rel:dN → date-only N days before now', () {
      expect(resolveRelativeDateToken('rel:d7', now: now), '2026-05-11');
      expect(resolveRelativeDateToken('rel:d30', now: now), '2026-04-18');
    });

    test('rel:hN → second-precision timestamp N hours before now', () {
      expect(
        resolveRelativeDateToken('rel:h24', now: now),
        '2026-05-17T09:30:15',
      );
      expect(
        resolveRelativeDateToken('rel:h1', now: now),
        '2026-05-18T08:30:15',
      );
    });

    test('non-relative token → null', () {
      expect(resolveRelativeDateToken('2026-01-01', now: now), isNull);
      expect(resolveRelativeDateToken('rel:x9', now: now), isNull);
      expect(resolveRelativeDateToken('', now: now), isNull);
    });
  });

  group('resolveRelativeFilterTokens', () {
    final now = DateTime(2026, 5, 18, 9, 30, 15);

    test('rewrites rel: inside the op-prefixed wire, preserving the op', () {
      final out = resolveRelativeFilterTokens(const {
        'created_at': {'gte:rel:d7'},
        'updated_at': {'lt:rel:h24'},
      }, now: now);
      expect(out['created_at'], {'gte:2026-05-11'});
      expect(out['updated_at'], {'lt:2026-05-17T09:30:15'});
    });

    test('no rel: token EVER survives into the assembled API filters map', () {
      final extra = {
        'created_at': {'gte:rel:d30'},
        'balance': {'gt:1000'},
        'country_id': {'8', '9'},
        'date_range': {'date,2026-01-01,2026-02-01'},
      };
      final resolved = resolveRelativeFilterTokens(extra, now: now);
      // Mirrors the repository chokepoint join.
      final joined = {
        for (final e in resolved.entries)
          if (e.value.isNotEmpty) e.key: (e.value.toList()..sort()).join(','),
      };
      for (final v in joined.values) {
        expect(v.contains('rel:'), isFalse, reason: 'leaked rel: in "$v"');
      }
      expect(joined['created_at'], 'gte:2026-04-18');
      expect(joined['balance'], 'gt:1000');
    });

    test('returns the same instance when nothing is relative', () {
      const extra = {
        'balance': {'gt:1000'},
        'country_id': {'8'},
      };
      expect(identical(resolveRelativeFilterTokens(extra), extra), isTrue);
    });
  });
}
