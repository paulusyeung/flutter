import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/recurring_expense.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/recurring_frequency.dart';

/// Conversions between [Expense] and [RecurringExpense] for the cross-entity
/// "Clone to Expense" / "Clone to Recurring" actions.
///
/// The two are distinct Freezed classes (no subtype relationship), so a cast
/// like React's `recurringExpense as Expense` throws in Dart — an explicit
/// field-by-field build is required. Both produce a clean unsaved clone seed:
/// the shared fields carry over, per-instance identity is reset
/// (id / number / invoice / payment / transaction / timestamps), and
/// `documents` / `isDirty` fall back to their empty defaults (omitted).

final DateTime _epoch0 = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

extension RecurringExpenseToExpense on RecurringExpense {
  /// Build a fresh [Expense] clone seed — drops the recurring-only schedule
  /// fields (`frequencyId` / `remainingCycles` / `nextSendDate` /
  /// `lastSentDate` / `statusId` / `recurringDates`).
  Expense toExpenseClone() => Expense(
    id: '',
    userId: userId,
    assignedUserId: assignedUserId,
    vendorId: vendorId,
    invoiceId: '',
    clientId: clientId,
    bankId: bankId,
    invoiceCurrencyId: invoiceCurrencyId,
    expenseCurrencyId: expenseCurrencyId,
    currencyId: currencyId,
    categoryId: categoryId,
    paymentTypeId: '',
    recurringExpenseId: recurringExpenseId,
    privateNotes: privateNotes,
    publicNotes: publicNotes,
    transactionReference: '',
    transactionId: '',
    date: date,
    number: '',
    paymentDate: null,
    customValue1: customValue1,
    customValue2: customValue2,
    customValue3: customValue3,
    customValue4: customValue4,
    taxName1: taxName1,
    taxName2: taxName2,
    taxName3: taxName3,
    projectId: projectId,
    entityType: entityType,
    amount: amount,
    foreignAmount: foreignAmount,
    exchangeRate: exchangeRate,
    taxAmount1: taxAmount1,
    taxAmount2: taxAmount2,
    taxAmount3: taxAmount3,
    taxRate1: taxRate1,
    taxRate2: taxRate2,
    taxRate3: taxRate3,
    isDeleted: false,
    shouldBeInvoiced: shouldBeInvoiced,
    invoiceDocuments: invoiceDocuments,
    usesInclusiveTaxes: usesInclusiveTaxes,
    calculateTaxByAmount: calculateTaxByAmount,
    updatedAt: _epoch0,
    createdAt: _epoch0,
    archivedAt: null,
  );
}

extension ExpenseToRecurringExpense on Expense {
  /// Build a fresh [RecurringExpense] clone seed — seeds the schedule with the
  /// create-form defaults (monthly, endless, next send today, no status), the
  /// same values as `emptyRecurringExpense()`.
  RecurringExpense toRecurringExpenseClone() => RecurringExpense(
    id: '',
    userId: userId,
    assignedUserId: assignedUserId,
    vendorId: vendorId,
    invoiceId: '',
    clientId: clientId,
    bankId: bankId,
    invoiceCurrencyId: invoiceCurrencyId,
    expenseCurrencyId: expenseCurrencyId,
    currencyId: currencyId,
    categoryId: categoryId,
    paymentTypeId: '',
    recurringExpenseId: recurringExpenseId,
    privateNotes: privateNotes,
    publicNotes: publicNotes,
    transactionReference: '',
    transactionId: '',
    date: date,
    number: '',
    paymentDate: null,
    customValue1: customValue1,
    customValue2: customValue2,
    customValue3: customValue3,
    customValue4: customValue4,
    taxName1: taxName1,
    taxName2: taxName2,
    taxName3: taxName3,
    projectId: projectId,
    entityType: entityType,
    frequencyId: kRecurringFrequencyMonthly,
    remainingCycles: -1,
    nextSendDate: Date.today(),
    lastSentDate: null,
    statusId: null,
    amount: amount,
    foreignAmount: foreignAmount,
    exchangeRate: exchangeRate,
    taxAmount1: taxAmount1,
    taxAmount2: taxAmount2,
    taxAmount3: taxAmount3,
    taxRate1: taxRate1,
    taxRate2: taxRate2,
    taxRate3: taxRate3,
    isDeleted: false,
    shouldBeInvoiced: shouldBeInvoiced,
    invoiceDocuments: invoiceDocuments,
    usesInclusiveTaxes: usesInclusiveTaxes,
    calculateTaxByAmount: calculateTaxByAmount,
    updatedAt: _epoch0,
    createdAt: _epoch0,
    archivedAt: null,
  );
}
