import 'package:admin/data/models/domain/billing/invitation.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/domain/billing/totals_calculator.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Shared base for every billing-doc edit ViewModel (Invoice / Quote /
/// Credit / PurchaseOrder / RecurringInvoice). Layers four behaviors
/// every subclass would otherwise duplicate (~120 lines per entity):
///
/// 1. **Live totals** — `vm.totals` re-runs `computeTotals(...)` on every
///    `notifyListeners()`, driven by the abstract [totalsInputOf]
///    accessor.
/// 2. **Line-item collection ops** — `replaceLineItems`, `addLineItem`,
///    `removeLineItemAt`, `updateLineItemAt`, `reorderLineItem`.
/// 3. **Invitation toggle** — `setContactInvitation(contactId, included)`
///    folds a contact id into the entity's invitations array.
/// 4. **eInvoice field update** — `setEInvoiceField(key, value)` writes
///    into the open-ended `e_invoice` map without typed accessors.
///
/// Subclasses implement seven thin `protected` accessor/mutator methods
/// against their concrete freezed type (`Invoice.copyWith(...)`, etc.) —
/// Dart's generic system can't generate `copyWith` over arbitrary types,
/// so the subclass provides the field bridge.
///
/// Per-entity simple setters (setClientId, setNumber, setDate, etc.)
/// stay in the subclass since they're already one-liners via the
/// `setStr` / `setBool` / `setDec` helpers on [GenericEditViewModel].
abstract class GenericBillingDocEditViewModel<T> extends GenericEditViewModel<T> {
  GenericBillingDocEditViewModel({
    required super.initialDraft,
    super.original,
    this.currencyPrecision = 2,
  });

  /// Decimal precision for currency rounding (typically 2; some currencies
  /// use 0 — e.g. JPY). Drives `computeTotals`'s rounding scale.
  final int currencyPrecision;

  // ── Subclass bridge ────────────────────────────────────────────────
  //
  // Concrete freezed types can't share a `copyWith` interface, so the
  // subclass provides field access via these protected methods. Each one
  // is a single-line wrapper around `draft.copyWith(...)` (write) or a
  // bare field accessor (read).

  /// Read the line-items array off the draft.
  List<LineItem> lineItemsOf(T draft);

  /// Return a new draft with [items] swapped in.
  T copyWithLineItems(T draft, List<LineItem> items);

  /// Read the invitations array off the draft.
  List<Invitation> invitationsOf(T draft);

  /// Return a new draft with [invitations] swapped in.
  T copyWithInvitations(T draft, List<Invitation> invitations);

  /// Read the open-ended `eInvoice` map. Null when unset.
  Map<String, dynamic>? eInvoiceOf(T draft);

  /// Return a new draft with [eInvoice] swapped in (or removed when null).
  T copyWithEInvoice(T draft, Map<String, dynamic>? eInvoice);

  /// Build the totals input from the draft. Subclasses pull together
  /// line items + discount + taxes + surcharges. Re-computed on every
  /// `notifyListeners()` — keep it cheap.
  BillingTotalsInput totalsInputOf(T draft);

  // ── Shared behaviors ───────────────────────────────────────────────

  /// Live totals — re-evaluated on every read. Used by the sticky-bottom
  /// `TotalsWidget` on each edit screen.
  BillingTotalsResult get totals =>
      computeTotals(totalsInputOf(draft), currencyPrecision);

  /// Replace the entire line-items list. Wraps in `List.unmodifiable` so
  /// downstream consumers can't mutate the draft's array out from under
  /// the ViewModel.
  void replaceLineItems(List<LineItem> items) =>
      updateDraft(copyWithLineItems(draft, List.unmodifiable(items)));

  void addLineItem(LineItem item) {
    replaceLineItems([...lineItemsOf(draft), item]);
  }

  void removeLineItemAt(int index) {
    final items = lineItemsOf(draft);
    if (index < 0 || index >= items.length) return;
    final next = List<LineItem>.from(items)..removeAt(index);
    replaceLineItems(next);
  }

  void updateLineItemAt(int index, LineItem item) {
    final items = lineItemsOf(draft);
    if (index < 0 || index >= items.length) return;
    final next = List<LineItem>.from(items);
    next[index] = item;
    replaceLineItems(next);
  }

  /// Drop trailing blank rows from the line items array. Wired to the
  /// pre-save hook by the desktop inline-editable table so the
  /// always-visible trailing empty row never reaches the server.
  void stripEmptyLineItems() {
    final items = lineItemsOf(draft);
    if (items.isEmpty) return;
    var end = items.length;
    while (end > 0 && items[end - 1].isBlank) {
      end--;
    }
    if (end == items.length) return;
    replaceLineItems(items.sublist(0, end));
  }

  /// Move the item at [from] to position [to]. Tolerant of
  /// [ReorderableListView]'s convention that "to" is the target *index
  /// before* the item is removed (so moving forward by one is a no-op).
  void reorderLineItem(int from, int to) {
    final items = lineItemsOf(draft);
    if (from < 0 || from >= items.length) return;
    if (to < 0 || to > items.length) return;
    final next = List<LineItem>.from(items);
    final row = next.removeAt(from);
    next.insert(to > from ? to - 1 : to, row);
    replaceLineItems(next);
  }

  /// Toggle [contactId] into / out of the entity's `invitations` array.
  /// Used by the Contacts tab — when the user checks a contact, this
  /// appends a new [Invitation] row keyed to the contact; unchecking
  /// removes the row.
  ///
  /// The new row carries empty values for the lifecycle timestamps
  /// (`sentDate` / `viewedDate` / `openedDate`) — the server fills those
  /// after the first send. Vendor contacts use the `vendorContactId`
  /// slot via [setVendorContactInvitation] instead.
  void setContactInvitation(String contactId, bool included) {
    final current = invitationsOf(draft);
    final exists = current.any((i) => i.clientContactId == contactId);
    if (included == exists) return;
    if (included) {
      final next = [
        ...current,
        Invitation(
          id: '',
          key: '',
          link: '',
          clientContactId: contactId,
          vendorContactId: '',
          sentDate: '',
          viewedDate: '',
          openedDate: '',
          emailStatus: '',
          emailError: '',
          messageId: '',
        ),
      ];
      updateDraft(copyWithInvitations(draft, next));
    } else {
      final next = current
          .where((i) => i.clientContactId != contactId)
          .toList(growable: false);
      updateDraft(copyWithInvitations(draft, next));
    }
  }

  /// Vendor variant of [setContactInvitation] — used by PurchaseOrder.
  /// Keyed off `vendorContactId` instead of `clientContactId`.
  void setVendorContactInvitation(String vendorContactId, bool included) {
    final current = invitationsOf(draft);
    final exists = current.any((i) => i.vendorContactId == vendorContactId);
    if (included == exists) return;
    if (included) {
      final next = [
        ...current,
        Invitation(
          id: '',
          key: '',
          link: '',
          clientContactId: '',
          vendorContactId: vendorContactId,
          sentDate: '',
          viewedDate: '',
          openedDate: '',
          emailStatus: '',
          emailError: '',
          messageId: '',
        ),
      ];
      updateDraft(copyWithInvitations(draft, next));
    } else {
      final next = current
          .where((i) => i.vendorContactId != vendorContactId)
          .toList(growable: false);
      updateDraft(copyWithInvitations(draft, next));
    }
  }

  /// Update one key in the open-ended `eInvoice` map. Pass null to
  /// remove the key. When the resulting map is empty, the whole field
  /// is cleared to null (matches admin-portal's omit-when-empty
  /// convention so an unedited draft doesn't ship `{}`).
  void setEInvoiceField(String key, dynamic value) {
    final current = Map<String, dynamic>.from(eInvoiceOf(draft) ?? const {});
    if (value == null) {
      current.remove(key);
    } else {
      current[key] = value;
    }
    updateDraft(
      copyWithEInvoice(draft, current.isEmpty ? null : current),
    );
  }
}
