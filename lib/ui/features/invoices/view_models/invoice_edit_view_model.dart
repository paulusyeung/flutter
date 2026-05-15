import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/invoice_status.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/repositories/invoice_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// M1 stub. Drives the Invoice edit + create screen. Optimistic — `save()`
/// lands the draft in Drift via the repo, returns the saved entity, and the
/// outbox handles the server round-trip.
///
/// The full setter surface (~30 fields covering line items, taxes,
/// surcharges, custom fields, eInvoice metadata) lands in M3 — see the
/// plan file's M3.B section. For M1 the VM only carries the minimal
/// fields the placeholder edit screen surfaces (client / number / date /
/// due_date / public_notes / private_notes), so the entity_modules screen
/// builders compile.
class InvoiceEditViewModel extends GenericEditViewModel<Invoice> {
  InvoiceEditViewModel({
    required this.repo,
    required this.companyId,
    Invoice? existing,
    Invoice? cloneFrom,
  }) : super(
         initialDraft: cloneFrom ?? existing ?? emptyInvoice(),
         original: existing,
       );

  final InvoiceRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() {
    final d = draft;
    return d.clientId.isNotEmpty ||
        d.number.isNotEmpty ||
        d.poNumber.isNotEmpty ||
        d.publicNotes.isNotEmpty ||
        d.privateNotes.isNotEmpty ||
        d.lineItems.isNotEmpty ||
        d.amount != Decimal.zero;
  }

  @override
  Future<Invoice> performSave() async {
    if (isCreate) {
      return await repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, invoice: draft);
    return draft;
  }

  void resetToEmpty() => reset(emptyDraft: emptyInvoice());

  // M1 field setters — full surface in M3.
  void setClientId(String v) => updateDraft(draft.copyWith(clientId: v));
  void setNumber(String v) => updateDraft(draft.copyWith(number: v));
  void setPoNumber(String v) => updateDraft(draft.copyWith(poNumber: v));
  void setDate(Date? d) => updateDraft(draft.copyWith(date: d));
  void setDueDate(Date? d) => updateDraft(draft.copyWith(dueDate: d));
  void setPublicNotes(String v) => updateDraft(draft.copyWith(publicNotes: v));
  void setPrivateNotes(String v) => updateDraft(draft.copyWith(privateNotes: v));
}

/// Empty draft for new invoices. Defaults match admin-portal's create
/// factory: `exchange_rate = 1`, `date = today`, status = Draft, and the
/// rest are zero / empty. Currency / client cascade is handled in the
/// edit screen by reading the active company settings.
Invoice emptyInvoice() => Invoice(
  id: '',
  number: '',
  poNumber: '',
  date: Date.today(),
  dueDate: null,
  partialDueDate: null,
  statusId: InvoiceStatus.draft,
  clientId: '',
  vendorId: '',
  projectId: '',
  designId: '',
  assignedUserId: '',
  userId: '',
  locationId: '',
  subscriptionId: '',
  parentInvoiceId: '',
  recurringId: '',
  amount: Decimal.zero,
  balance: Decimal.zero,
  paidToDate: Decimal.zero,
  taxAmount: Decimal.zero,
  discount: Decimal.zero,
  partial: Decimal.zero,
  isAmountDiscount: false,
  exchangeRate: Decimal.one,
  taxName1: '',
  taxName2: '',
  taxName3: '',
  taxRate1: Decimal.zero,
  taxRate2: Decimal.zero,
  taxRate3: Decimal.zero,
  usesInclusiveTaxes: false,
  customSurcharge1: Decimal.zero,
  customSurcharge2: Decimal.zero,
  customSurcharge3: Decimal.zero,
  customSurcharge4: Decimal.zero,
  customTaxes1: false,
  customTaxes2: false,
  customTaxes3: false,
  customTaxes4: false,
  publicNotes: '',
  privateNotes: '',
  terms: '',
  footer: '',
  customValue1: '',
  customValue2: '',
  customValue3: '',
  customValue4: '',
  reminder1Sent: null,
  reminder2Sent: null,
  reminder3Sent: null,
  reminderLastSent: null,
  reminderSchedule: '',
  frequencyId: '',
  nextSendDate: null,
  nextSendDatetime: '',
  lastSentDate: null,
  remainingCycles: 0,
  dueDateDays: '',
  autoBill: '',
  autoBillEnabled: false,
  isLocked: false,
  isDeleted: false,
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
);
