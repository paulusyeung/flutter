import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/credit_api_model.dart';
import 'package:admin/data/models/api/expense_api_model.dart';
import 'package:admin/data/models/api/invoice_api_model.dart';
import 'package:admin/data/models/api/payment_api_model.dart';
import 'package:admin/data/models/api/purchase_order_api_model.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/ui/features/billing_shared/ledger/ledger_entry.dart';

// status_id '2' = sent (non-draft) so these count toward AR. The api models
// default status_id to '1' (draft), which the ledger now excludes.
Invoice _inv(
  String id,
  String date,
  String amount, {
  bool deleted = false,
  String status = '2',
  int createdAt = 0,
}) =>
    Invoice.fromApi(InvoiceApi(
      id: id,
      number: id,
      date: date,
      amount: amount,
      isDeleted: deleted,
      statusId: status,
      createdAt: createdAt,
    ));

Payment _pay(String id, String date, String amount) =>
    Payment.fromApi(PaymentApi(id: id, number: id, date: date, amount: amount));

Credit _cred(String id, String date, String amount, {String status = '2'}) =>
    Credit.fromApi(
        CreditApi(id: id, number: id, date: date, amount: amount,
            statusId: status));

PurchaseOrder _po(String id, String date, String amount,
        {String status = '2'}) =>
    PurchaseOrder.fromApi(PurchaseOrderApi(
        id: id, number: id, date: date, amount: amount, statusId: status));

void main() {
  group('buildClientLedger', () {
    test('chronological running balance; output newest-first', () {
      final entries = buildClientLedger(
        invoices: [
          _inv('i1', '2026-01-01', '100'),
          _inv('i2', '2026-01-10', '50'),
        ],
        payments: [_pay('p1', '2026-01-05', '40')],
        credits: [_cred('c1', '2026-01-08', '10')],
      );
      expect(entries.map((e) => e.id).toList(), ['i2', 'c1', 'p1', 'i1']);
      final byId = {for (final e in entries) e.id: e};
      expect(byId['i1']!.runningBalance, Decimal.parse('100'));
      expect(byId['p1']!.runningBalance, Decimal.parse('60')); // 100-40
      expect(byId['c1']!.runningBalance, Decimal.parse('50')); // 60-10
      expect(byId['i2']!.runningBalance, Decimal.parse('100')); // 50+50
    });

    test('invoices are debits (+), payments and credits are credits (−)', () {
      final e = buildClientLedger(
        invoices: [_inv('i1', '2026-01-01', '100')],
        payments: [_pay('p1', '2026-01-02', '30')],
        credits: [_cred('c1', '2026-01-03', '20')],
      );
      final byId = {for (final x in e) x.id: x};
      expect(byId['i1']!.adjustment, Decimal.parse('100'));
      expect(byId['p1']!.adjustment, Decimal.parse('-30'));
      expect(byId['c1']!.adjustment, Decimal.parse('-20'));
    });

    test('deleted rows are excluded', () {
      final e = buildClientLedger(
        invoices: [
          _inv('i1', '2026-01-01', '100'),
          _inv('i2', '2026-01-02', '999', deleted: true),
        ],
        payments: const [],
        credits: const [],
      );
      expect(e.map((x) => x.id), ['i1']);
      expect(e.single.runningBalance, Decimal.parse('100'));
    });

    test('draft invoices and draft credits are excluded from AR', () {
      final e = buildClientLedger(
        invoices: [
          _inv('sent', '2026-01-01', '100'),
          _inv('draft', '2026-01-02', '999', status: '1'),
        ],
        payments: const [],
        credits: [
          _cred('cd', '2026-01-03', '40', status: '1'), // draft credit
        ],
      );
      expect(e.map((x) => x.id), ['sent']);
      expect(e.single.runningBalance, Decimal.parse('100'));
    });

    test('same-date rows order by createdAt (precise tiebreak)', () {
      final e = buildClientLedger(
        invoices: [
          _inv('later', '2026-01-01', '5', createdAt: 2000),
          _inv('earlier', '2026-01-01', '10', createdAt: 1000),
        ],
        payments: const [],
        credits: const [],
      );
      // Chronologically: earlier (createdAt 1000) then later → balances
      // 10 then 15. Display is newest-first.
      final byId = {for (final x in e) x.id: x};
      expect(byId['earlier']!.runningBalance, Decimal.parse('10'));
      expect(byId['later']!.runningBalance, Decimal.parse('15'));
      expect(e.first.id, 'later');
    });

    test('undated rows sort oldest (stable)', () {
      final e = buildClientLedger(
        invoices: [
          _inv('i_undated', '', '10'),
          _inv('i_dated', '2026-01-01', '5'),
        ],
        payments: const [],
        credits: const [],
      );
      final byId = {for (final x in e) x.id: x};
      expect(byId['i_undated']!.runningBalance, Decimal.parse('10'));
      expect(byId['i_dated']!.runningBalance, Decimal.parse('15'));
      expect(e.first.id, 'i_dated');
    });

    test('opening row anchors the bottom; zero adjustment/balance', () {
      final e = buildClientLedger(
        invoices: [_inv('i1', '2026-01-05', '100')],
        payments: const [],
        credits: const [],
        openingAt: DateTime.utc(2025, 12, 31),
      );
      expect(e.length, 2);
      final opening = e.last; // bottom (oldest) in newest-first display
      expect(opening.isOpening, isTrue);
      expect(opening.adjustment, Decimal.zero);
      expect(opening.runningBalance, Decimal.zero);
      // The opening row carries a *placeholder* kind (invoice) — the tab's
      // filter MUST gate on `isOpening`, not kind, or a non-invoice chip
      // would hide the genesis anchor. Lock that contract here.
      expect(opening.kind, LedgerKind.invoice);
      const active = {LedgerKind.payment};
      final visibleBuggy =
          e.where((x) => active.contains(x.kind)).toList();
      final visibleFixed = e
          .where((x) => x.isOpening || active.contains(x.kind))
          .toList();
      expect(visibleBuggy.any((x) => x.isOpening), isFalse,
          reason: 'kind-only filter drops the genesis row (the bug)');
      expect(visibleFixed.any((x) => x.isOpening), isTrue,
          reason: 'isOpening-guarded filter keeps it (the fix)');
      // The real row's running balance is unchanged by the genesis row.
      expect(e.first.id, 'i1');
      expect(e.first.runningBalance, Decimal.parse('100'));
      expect(e.first.isOpening, isFalse);
    });
  });

  group('buildVendorLedger', () {
    test('expenses + purchase orders both add to spend', () {
      final entries = buildVendorLedger(
        expenses: [
          Expense.fromApi(const ExpenseApi(
              id: 'e1', number: 'e1', date: '2026-01-02', amount: '70')),
        ],
        purchaseOrders: [_po('po1', '2026-01-01', '30')],
      );
      expect(entries.map((e) => e.id), ['e1', 'po1']);
      final byId = {for (final e in entries) e.id: e};
      expect(byId['po1']!.runningBalance, Decimal.parse('30'));
      expect(byId['e1']!.runningBalance, Decimal.parse('100'));
    });

    test('draft purchase orders are excluded', () {
      final entries = buildVendorLedger(
        expenses: const [],
        purchaseOrders: [
          _po('sent', '2026-01-01', '30'),
          _po('draft', '2026-01-02', '999', status: '1'),
        ],
      );
      expect(entries.map((e) => e.id), ['sent']);
      expect(entries.single.runningBalance, Decimal.parse('30'));
    });
  });
}
