import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/expense_api_model.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/domain/billing/totals_calculator.dart';
import 'package:admin/domain/expense_invoice_line_item.dart';

void main() {
  // Run the produced line item through the invoice totals calculator with the
  // matching invoice-level inclusive flag, and return the invoice total. This
  // is the end-to-end check that matters: the invoice total must land on the
  // expense's (converted) gross regardless of inclusive mode or currency.
  Decimal invoiceTotalFor(Expense expense, {required bool invoiceInclusive}) {
    final item = expenseInvoiceLineItem(
      expense,
      invoiceInclusive: invoiceInclusive,
    );
    return computeTotals(
      BillingTotalsInput(
        lineItems: [item],
        discount: Decimal.zero,
        isAmountDiscount: true,
        usesInclusiveTaxes: invoiceInclusive,
      ),
      2,
    ).total;
  }

  group('expenseInvoiceLineItem', () {
    test('exclusive-tax expense → bills net + tax = expense gross', () {
      final expense = Expense.fromApi(
        const ExpenseApi(amount: '100', taxName1: 'GST', taxRate1: '10'),
      );
      // `invoiceExpense` seeds the new invoice exclusive (= the expense mode).
      final item = expenseInvoiceLineItem(expense, invoiceInclusive: false);
      expect(item.cost, Decimal.fromInt(100)); // net == amount for exclusive
      expect(item.taxRate1, Decimal.fromInt(10));
      expect(item.taxName1, 'GST');
      expect(
        invoiceTotalFor(expense, invoiceInclusive: false),
        Decimal.fromInt(110),
      );
    });

    test('inclusive-tax expense → no over-bill (total == gross, not 110)', () {
      final expense = Expense.fromApi(
        const ExpenseApi(
          amount: '100',
          taxName1: 'GST',
          taxRate1: '10',
          usesInclusiveTaxes: true,
        ),
      );
      // `invoiceExpense` seeds the new invoice inclusive (= the expense mode).
      final item = expenseInvoiceLineItem(expense, invoiceInclusive: true);
      expect(item.cost, Decimal.fromInt(100)); // gross == amount for inclusive
      // Pre-fix this billed 110 (tax added on top of an already-inclusive 100).
      expect(
        invoiceTotalFor(expense, invoiceInclusive: true),
        Decimal.fromInt(100),
      );
    });

    test('foreign-currency expense → billed in the invoice currency', () {
      final expense = Expense.fromApi(
        const ExpenseApi(
          amount: '100',
          taxName1: 'GST',
          taxRate1: '10',
          invoiceCurrencyId: '2',
          exchangeRate: '1.2',
          foreignAmount: '120',
        ),
      );
      final item = expenseInvoiceLineItem(expense, invoiceInclusive: false);
      expect(item.cost, Decimal.fromInt(120)); // net(100) × fx(1.2)
      // Converted gross = 110 × 1.2 = 132.
      expect(
        invoiceTotalFor(expense, invoiceInclusive: false),
        Decimal.fromInt(132),
      );
    });

    test('by-amount tax → no line rate carried, bills the full gross', () {
      final expense = Expense.fromApi(
        const ExpenseApi(
          amount: '100',
          taxName1: 'GST',
          taxAmount1: '8',
          calculateTaxByAmount: true,
        ),
      );
      final item = expenseInvoiceLineItem(expense, invoiceInclusive: false);
      expect(item.cost, Decimal.fromInt(108)); // gross = amount + taxAmountSum
      expect(item.taxRate1, Decimal.zero);
      expect(item.taxName1, '');
      expect(
        invoiceTotalFor(expense, invoiceInclusive: false),
        Decimal.fromInt(108),
      );
    });
  });
}
