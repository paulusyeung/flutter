import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/repositories/_repository_helpers.dart';
import 'package:admin/data/repositories/expense_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the Expense edit + create screen. Optimistic — `save()` lands the
/// draft in Drift via the repo, returns the saved entity, and the outbox
/// handles the server round-trip.
class ExpenseEditViewModel extends GenericEditViewModel<Expense> {
  ExpenseEditViewModel({
    required this.repo,
    required this.companyId,
    Expense? existing,
    Expense? cloneFrom,
    super.sync,
    super.connectivity,
  }) : super(
         initialDraft: cloneFrom ?? existing ?? emptyExpense(),
         original: existing,
         companyId: companyId,
       );

  final ExpenseRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.vendorId.isNotEmpty ||
        d.clientId.isNotEmpty ||
        d.projectId.isNotEmpty ||
        d.categoryId.isNotEmpty ||
        d.amount != Decimal.zero ||
        d.publicNotes.isNotEmpty ||
        d.privateNotes.isNotEmpty ||
        d.transactionReference.isNotEmpty;
  }

  @override
  Future<SaveResult<Expense>> performSave() async {
    if (isCreate) {
      final result = await repo.create(
        companyId: companyId,
        draft: draft,
        existingTempId: recoveryTempId,
      );
      rememberCreateTempId(result.entity.id);
      return result;
    }
    return repo.save(companyId: companyId, expense: draft);
  }

  void resetToEmpty() => reset(emptyDraft: emptyExpense());

  // ── Field setters ──────────────────────────────────────────────────

  void setVendorId(String v) => updateDraft(draft.copyWith(vendorId: v));
  void setClientId(String v) => updateDraft(draft.copyWith(clientId: v));
  void setProjectId(String v) => updateDraft(draft.copyWith(projectId: v));
  void setCategoryId(String v) => updateDraft(draft.copyWith(categoryId: v));
  void setCurrencyId(String v) => updateDraft(draft.copyWith(currencyId: v));
  void setInvoiceCurrencyId(String v) =>
      updateDraft(draft.copyWith(invoiceCurrencyId: v));
  void setAssignedUserId(String v) =>
      updateDraft(draft.copyWith(assignedUserId: v));
  void setNumber(String v) => updateDraft(draft.copyWith(number: v));
  void setDate(Date? d) => updateDraft(draft.copyWith(date: d));
  void setPaymentDate(Date? d) => updateDraft(draft.copyWith(paymentDate: d));
  void setPaymentTypeId(String v) =>
      updateDraft(draft.copyWith(paymentTypeId: v));
  void setTransactionReference(String v) =>
      updateDraft(draft.copyWith(transactionReference: v));
  void setTransactionId(String v) =>
      updateDraft(draft.copyWith(transactionId: v));
  void setBankId(String v) => updateDraft(draft.copyWith(bankId: v));
  void setAmount(String input) => updateDraft(
    draft.copyWith(amount: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setForeignAmount(String input) => updateDraft(
    draft.copyWith(
      foreignAmount: Decimal.tryParse(input.trim()) ?? Decimal.zero,
    ),
  );
  void setExchangeRate(String input) => updateDraft(
    draft.copyWith(exchangeRate: Decimal.tryParse(input.trim()) ?? Decimal.one),
  );
  void setTaxName1(String v) => updateDraft(draft.copyWith(taxName1: v));
  void setTaxName2(String v) => updateDraft(draft.copyWith(taxName2: v));
  void setTaxName3(String v) => updateDraft(draft.copyWith(taxName3: v));
  void setTaxRate1(String input) => updateDraft(
    draft.copyWith(taxRate1: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setTaxRate2(String input) => updateDraft(
    draft.copyWith(taxRate2: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setTaxRate3(String input) => updateDraft(
    draft.copyWith(taxRate3: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setTaxAmount1(String input) => updateDraft(
    draft.copyWith(taxAmount1: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setTaxAmount2(String input) => updateDraft(
    draft.copyWith(taxAmount2: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setTaxAmount3(String input) => updateDraft(
    draft.copyWith(taxAmount3: Decimal.tryParse(input.trim()) ?? Decimal.zero),
  );
  void setUsesInclusiveTaxes(bool v) =>
      updateDraft(draft.copyWith(usesInclusiveTaxes: v));
  void setCalculateTaxByAmount(bool v) =>
      updateDraft(draft.copyWith(calculateTaxByAmount: v));
  void setShouldBeInvoiced(bool v) =>
      updateDraft(draft.copyWith(shouldBeInvoiced: v));
  void setInvoiceDocuments(bool v) =>
      updateDraft(draft.copyWith(invoiceDocuments: v));
  void setPublicNotes(String v) => updateDraft(draft.copyWith(publicNotes: v));
  void setPrivateNotes(String v) =>
      updateDraft(draft.copyWith(privateNotes: v));
  void setCustomValue1(String v) =>
      updateDraft(draft.copyWith(customValue1: v));
  void setCustomValue2(String v) =>
      updateDraft(draft.copyWith(customValue2: v));
  void setCustomValue3(String v) =>
      updateDraft(draft.copyWith(customValue3: v));
  void setCustomValue4(String v) =>
      updateDraft(draft.copyWith(customValue4: v));
}

/// Empty draft for new expenses. Defaults match admin-portal's create
/// factory: `exchange_rate = 1`, `date = today`, and the rest are zero /
/// empty until the user picks values. Currency / vendor / client cascade
/// is handled in the edit screen by reading the active company settings.
Expense emptyExpense() => Expense(
  id: '',
  userId: '',
  assignedUserId: '',
  vendorId: '',
  invoiceId: '',
  clientId: '',
  bankId: '',
  invoiceCurrencyId: '',
  expenseCurrencyId: '',
  currencyId: '',
  categoryId: '',
  paymentTypeId: '',
  recurringExpenseId: '',
  privateNotes: '',
  publicNotes: '',
  transactionReference: '',
  transactionId: '',
  date: Date.today(),
  number: '',
  paymentDate: null,
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  taxName1: '',
  taxName2: '',
  taxName3: '',
  projectId: '',
  entityType: '',
  amount: Decimal.zero,
  foreignAmount: Decimal.zero,
  exchangeRate: Decimal.one,
  taxAmount1: Decimal.zero,
  taxAmount2: Decimal.zero,
  taxAmount3: Decimal.zero,
  taxRate1: Decimal.zero,
  taxRate2: Decimal.zero,
  taxRate3: Decimal.zero,
  isDeleted: false,
  shouldBeInvoiced: false,
  invoiceDocuments: false,
  usesInclusiveTaxes: false,
  calculateTaxByAmount: false,
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
);
