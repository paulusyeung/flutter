import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/expense_recurring_conversion.dart';
import 'package:admin/domain/recurring_frequency.dart';
import 'package:admin/ui/features/expenses/view_models/expense_edit_view_model.dart'
    show emptyExpense;
import 'package:admin/ui/features/recurring_expenses/view_models/recurring_expense_edit_view_model.dart'
    show emptyRecurringExpense;

/// Locks down the cross-entity clone converters. The bug they fix: Expense and
/// RecurringExpense are distinct Freezed types, so the previous actions passed
/// the wrong type to the create route's `state.extra is X` guard and the form
/// opened blank. The converters return the correct static type (guaranteeing
/// the guard matches) and carry the shared money/tax/identity fields.
void main() {
  group('RecurringExpense.toExpenseClone', () {
    test('returns an Expense, carries shared fields, resets per-instance '
        'identity, drops recurring-only fields', () {
      final re = emptyRecurringExpense().copyWith(
        id: 're_1',
        number: 'RE-1',
        vendorId: 'v1',
        clientId: 'c1',
        categoryId: 'cat1',
        projectId: 'p1',
        currencyId: 'usd',
        invoiceCurrencyId: 'eur',
        amount: Decimal.parse('100'),
        exchangeRate: Decimal.parse('1.5'),
        foreignAmount: Decimal.parse('150'),
        taxName1: 'VAT',
        taxRate1: Decimal.parse('10'),
        taxAmount1: Decimal.parse('10'),
        usesInclusiveTaxes: true,
        publicNotes: 'pub',
        privateNotes: 'priv',
        customValue1: 'cv1',
        // Per-instance fields that must NOT carry into the clone.
        invoiceId: 'inv1',
        paymentTypeId: 'pt1',
        transactionReference: 'txr',
        transactionId: 'txid',
        paymentDate: Date.today(),
        isDeleted: true,
        isDirty: true,
        // Recurring-only fields that must be dropped.
        statusId: '2',
        remainingCycles: 5,
        lastSentDate: Date.today(),
      );

      final exp = re.toExpenseClone();

      expect(exp, isA<Expense>());
      // Reset identity.
      expect(exp.id, '');
      expect(exp.number, '');
      expect(exp.invoiceId, '');
      expect(exp.paymentTypeId, '');
      expect(exp.transactionReference, '');
      expect(exp.transactionId, '');
      expect(exp.paymentDate, isNull);
      expect(exp.isDeleted, isFalse);
      expect(exp.isDirty, isFalse);
      expect(exp.archivedAt, isNull);
      expect(exp.documents, isEmpty);
      // Carried money / tax / identity.
      expect(exp.vendorId, 'v1');
      expect(exp.clientId, 'c1');
      expect(exp.categoryId, 'cat1');
      expect(exp.projectId, 'p1');
      expect(exp.currencyId, 'usd');
      expect(exp.invoiceCurrencyId, 'eur');
      expect(exp.amount, Decimal.parse('100'));
      expect(exp.exchangeRate, Decimal.parse('1.5'));
      expect(exp.foreignAmount, Decimal.parse('150'));
      expect(exp.taxName1, 'VAT');
      expect(exp.taxRate1, Decimal.parse('10'));
      expect(exp.taxAmount1, Decimal.parse('10'));
      expect(exp.usesInclusiveTaxes, isTrue);
      expect(exp.publicNotes, 'pub');
      expect(exp.privateNotes, 'priv');
      expect(exp.customValue1, 'cv1');
    });
  });

  group('Expense.toRecurringExpenseClone', () {
    test('returns a RecurringExpense, seeds default schedule, carries shared '
        'fields, resets per-instance identity', () {
      final e = emptyExpense().copyWith(
        id: 'e_1',
        number: 'E-1',
        vendorId: 'v1',
        currencyId: 'usd',
        amount: Decimal.parse('200'),
        taxName1: 'GST',
        taxRate1: Decimal.parse('7'),
        publicNotes: 'pub',
        invoiceId: 'inv1',
        paymentTypeId: 'pt1',
        isDirty: true,
      );

      final r = e.toRecurringExpenseClone();

      expect(r, isA<RecurringExpense>());
      // Reset identity.
      expect(r.id, '');
      expect(r.number, '');
      expect(r.invoiceId, '');
      expect(r.paymentTypeId, '');
      expect(r.isDirty, isFalse);
      expect(r.recurringDates, isEmpty);
      // Default schedule (matches emptyRecurringExpense()).
      expect(r.frequencyId, kRecurringFrequencyMonthly);
      expect(r.remainingCycles, -1);
      expect(r.nextSendDate?.toIso(), Date.today().toIso());
      expect(r.lastSentDate, isNull);
      expect(r.statusId, isNull);
      // Carried fields.
      expect(r.vendorId, 'v1');
      expect(r.currencyId, 'usd');
      expect(r.amount, Decimal.parse('200'));
      expect(r.taxName1, 'GST');
      expect(r.taxRate1, Decimal.parse('7'));
      expect(r.publicNotes, 'pub');
    });
  });
}
