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

Invoice _inv(String id, String date, String amount, {bool deleted = false}) =>
    Invoice.fromApi(InvoiceApi(
      id: id,
      number: id,
      date: date,
      amount: amount,
      isDeleted: deleted,
    ));

Payment _pay(String id, String date, String amount) =>
    Payment.fromApi(PaymentApi(id: id, number: id, date: date, amount: amount));

Credit _cred(String id, String date, String amount) =>
    Credit.fromApi(CreditApi(id: id, number: id, date: date, amount: amount));

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
      // Newest-first display order.
      expect(entries.map((e) => e.id).toList(), ['i2', 'c1', 'p1', 'i1']);
      // Running balance is the chronological as-of figure on each row.
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

    test('undated rows sort oldest (stable)', () {
      final e = buildClientLedger(
        invoices: [
          _inv('i_undated', '', '10'),
          _inv('i_dated', '2026-01-01', '5'),
        ],
        payments: const [],
        credits: const [],
      );
      // Undated first chronologically → balance 10, then +5 = 15.
      final byId = {for (final x in e) x.id: x};
      expect(byId['i_undated']!.runningBalance, Decimal.parse('10'));
      expect(byId['i_dated']!.runningBalance, Decimal.parse('15'));
      // Display newest-first: dated row on top.
      expect(e.first.id, 'i_dated');
    });
  });

  group('buildVendorLedger', () {
    test('expenses + purchase orders both add to spend', () {
      final entries = buildVendorLedger(
        expenses: [
          Expense.fromApi(
              const ExpenseApi(id: 'e1', number: 'e1', date: '2026-01-02', amount: '70')),
        ],
        purchaseOrders: [
          PurchaseOrder.fromApi(const PurchaseOrderApi(
              id: 'po1', number: 'po1', date: '2026-01-01', amount: '30')),
        ],
      );
      expect(entries.map((e) => e.id), ['e1', 'po1']); // newest-first
      final byId = {for (final e in entries) e.id: e};
      expect(byId['po1']!.runningBalance, Decimal.parse('30'));
      expect(byId['e1']!.runningBalance, Decimal.parse('100'));
    });
  });
}
