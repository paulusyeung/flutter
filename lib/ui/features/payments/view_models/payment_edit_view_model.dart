import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/repositories/payment_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the Payment edit + create screen. Optimistic — `save()` lands the
/// draft in Drift via the repo, returns the saved entity, and the outbox
/// handles the server round-trip.
///
/// [sendEmail] is a transient UI-only flag passed straight to the repository
/// (never persisted). On create the default mirrors the company setting
/// `client_manual_payment_notification`; on update the user toggles it
/// explicitly.
class PaymentEditViewModel extends GenericEditViewModel<Payment> {
  PaymentEditViewModel({
    required this.repo,
    required this.companyId,
    Payment? existing,
    Payment? cloneFrom,
    bool defaultSendEmail = false,
  }) : _sendEmail = defaultSendEmail,
       super(
         initialDraft: cloneFrom ?? existing ?? emptyPayment(),
         original: existing,
       );

  final PaymentRepository repo;
  final String companyId;

  bool _sendEmail;

  bool get sendEmail => _sendEmail;

  set sendEmail(bool value) {
    if (_sendEmail == value) return;
    _sendEmail = value;
    notifyListeners();
  }

  /// Sum of allocation amounts. The edit form surfaces the running total +
  /// a "$Y remaining" hint so the user catches a mismatch before the server
  /// rejects it.
  Decimal get allocatedTotal => draft.paymentables.fold<Decimal>(
        Decimal.zero,
        (sum, p) => sum + p.amount,
      );

  /// Difference between the payment amount and the running allocation total.
  /// Positive = under-allocated (more to spread); negative = over-allocated
  /// (the form should flag this red).
  Decimal get allocationRemainder => draft.amount - allocatedTotal;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.clientId.isNotEmpty ||
        d.amount != Decimal.zero ||
        d.transactionReference.isNotEmpty ||
        d.privateNotes.isNotEmpty ||
        d.paymentables.isNotEmpty;
  }

  @override
  Future<Payment> performSave() async {
    if (isCreate) {
      return await repo.create(
        companyId: companyId,
        draft: draft,
        sendEmail: _sendEmail,
      );
    }
    await repo.save(
      companyId: companyId,
      payment: draft,
      sendEmail: _sendEmail,
    );
    return draft;
  }

  void resetToEmpty() => reset(emptyDraft: emptyPayment());

  // ── Field setters ──────────────────────────────────────────────────

  void setClientId(String v) => updateDraft(draft.copyWith(clientId: v));
  void setClientContactId(String v) =>
      updateDraft(draft.copyWith(clientContactId: v));
  void setVendorId(String v) => updateDraft(draft.copyWith(vendorId: v));
  void setProjectId(String v) => updateDraft(draft.copyWith(projectId: v));
  void setCurrencyId(String v) => updateDraft(draft.copyWith(currencyId: v));
  void setExchangeCurrencyId(String v) =>
      updateDraft(draft.copyWith(exchangeCurrencyId: v));
  void setCompanyGatewayId(String v) =>
      updateDraft(draft.copyWith(companyGatewayId: v));
  void setGatewayTypeId(String v) =>
      updateDraft(draft.copyWith(gatewayTypeId: v));
  void setTypeId(String v) => updateDraft(draft.copyWith(typeId: v));
  void setStatusId(String v) => updateDraft(draft.copyWith(statusId: v));
  void setAssignedUserId(String v) =>
      updateDraft(draft.copyWith(assignedUserId: v));
  void setNumber(String v) => updateDraft(draft.copyWith(number: v));
  void setDate(Date? d) => updateDraft(draft.copyWith(date: d));
  void setTransactionReference(String v) =>
      updateDraft(draft.copyWith(transactionReference: v));
  void setPrivateNotes(String v) =>
      updateDraft(draft.copyWith(privateNotes: v));
  void setIsManual(bool v) => updateDraft(draft.copyWith(isManual: v));
  void setAmount(String input) => updateDraft(
        draft.copyWith(amount: Decimal.tryParse(input.trim()) ?? Decimal.zero),
      );
  void setExchangeRate(String input) => updateDraft(
        draft.copyWith(
          exchangeRate: Decimal.tryParse(input.trim()) ?? Decimal.one,
        ),
      );
  void setCustomValue1(String v) =>
      updateDraft(draft.copyWith(customValue1: v));
  void setCustomValue2(String v) =>
      updateDraft(draft.copyWith(customValue2: v));
  void setCustomValue3(String v) =>
      updateDraft(draft.copyWith(customValue3: v));
  void setCustomValue4(String v) =>
      updateDraft(draft.copyWith(customValue4: v));

  /// Replace the entire paymentables list (allocations editor calls this).
  void replacePaymentables(List<Paymentable> next) =>
      updateDraft(draft.copyWith(paymentables: List.unmodifiable(next)));
}

/// Empty draft for new payments. Defaults: `exchange_rate = 1`, `date = today`,
/// `is_manual = true` (gateway-paid payments come back from server-side
/// callbacks, not user creates).
Payment emptyPayment() => Payment(
      id: '',
      number: '',
      statusId: '',
      typeId: '',
      clientId: '',
      clientContactId: '',
      companyGatewayId: '',
      gatewayTypeId: '',
      projectId: '',
      vendorId: '',
      invitationId: '',
      currencyId: '',
      exchangeCurrencyId: '',
      transactionReference: '',
      transactionId: '',
      privateNotes: '',
      customValue1: '',
      customValue2: '',
      customValue3: '',
      customValue4: '',
      userId: '',
      createdUserId: '',
      assignedUserId: '',
      date: Date.today(),
      amount: Decimal.zero,
      applied: Decimal.zero,
      refunded: Decimal.zero,
      exchangeRate: Decimal.one,
      isManual: true,
      isDeleted: false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      archivedAt: null,
    );
