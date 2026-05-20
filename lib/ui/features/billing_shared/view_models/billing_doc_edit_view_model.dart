import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/billing/invitation.dart';
import 'package:admin/data/models/domain/billing/line_item.dart';
import 'package:admin/data/models/domain/contact.dart';
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

  /// Read the client id off the draft.
  String clientIdOf(T draft);

  /// Return a new draft with [clientId] swapped in.
  T copyWithClientId(T draft, String clientId);

  /// Read the open-ended `eInvoice` map. Null when unset.
  Map<String, dynamic>? eInvoiceOf(T draft);

  /// Return a new draft with [eInvoice] swapped in (or removed when null).
  T copyWithEInvoice(T draft, Map<String, dynamic>? eInvoice);

  /// Build the totals input from the draft. Subclasses pull together
  /// line items + discount + taxes + surcharges. Re-computed on every
  /// `notifyListeners()` — keep it cheap.
  BillingTotalsInput totalsInputOf(T draft);

  // ── Shared behaviors ───────────────────────────────────────────────

  // Memoized totals. `TotalsWidget` reads `vm.totals` on every form
  // rebuild — i.e. every keystroke in any field, including ones that
  // don't affect totals (number, notes, client, dates). `computeTotals`
  // is pure and `BillingTotalsInput` is value-equal, so we recompute
  // only when the input actually changes.
  BillingTotalsInput? _cachedTotalsInput;
  BillingTotalsResult? _cachedTotalsResult;

  /// Live totals, recomputed only when the totals input changes. Used by
  /// the sticky-bottom `TotalsWidget` on each edit screen.
  BillingTotalsResult get totals {
    final input = totalsInputOf(draft);
    final cached = _cachedTotalsResult;
    if (cached != null && input == _cachedTotalsInput) return cached;
    final result = computeTotals(input, currencyPrecision);
    _cachedTotalsInput = input;
    _cachedTotalsResult = result;
    return result;
  }

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

  /// Per-row server validation errors, derived from `fieldErrors` keys
  /// shaped like `line_items.0.cost`. Returns a map keyed by row index
  /// to a sub-map keyed by API field name. The desktop items table
  /// surfaces each entry as the matching cell's `errorText`.
  Map<int, Map<String, String>> get lineItemRowErrors {
    if (fieldErrors.isEmpty) return const {};
    final out = <int, Map<String, String>>{};
    for (final entry in fieldErrors.entries) {
      final parts = entry.key.split('.');
      if (parts.length < 3 || parts[0] != 'line_items') continue;
      final idx = int.tryParse(parts[1]);
      if (idx == null) continue;
      final field = parts.sublist(2).join('.');
      final msg = entry.value.isEmpty ? '' : entry.value.first;
      if (msg.isEmpty) continue;
      (out[idx] ??= <String, String>{})[field] = msg;
    }
    return out;
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

  // ── Cross-client validation ──────────────────────────────────────────
  //
  // An invoice (or quote/credit/recurring) must not carry a task or
  // expense whose source row belongs to a different client. The picker
  // already filters by `t.clientId == '' || t.clientId == draft.clientId`
  // (Round 2) and Round 8 added the auto-cascade so the draft's client is
  // set to the picked task's client when the draft was previously empty.
  // The save-time validation below is defense-in-depth: it catches legacy
  // invoices, API-imported drafts, and any data drift that the picker
  // path didn't filter.

  /// Source-row clientIds keyed by `task.id` for every task referenced by
  /// the draft's line items. Empty entries (source row not found or its
  /// `clientId` was blank) short-circuit validation as "no constraint" so
  /// missing data never blocks save. Populated synchronously by the
  /// picker invoke helper via [registerSourceClientIds] and lazily by
  /// the layout via [hydrateSourceClientIds].
  final Map<String, String> _taskClientIds = {};
  final Map<String, String> _expenseClientIds = {};

  /// Picker-side push: the picker has the picked `Task` / `Expense`
  /// objects in memory so it can hand their clientIds back to the VM
  /// without a Drift round-trip. Idempotent — repeated calls just
  /// overwrite the same keys.
  void registerSourceClientIds({
    Map<String, String> tasks = const {},
    Map<String, String> expenses = const {},
  }) {
    if (tasks.isEmpty && expenses.isEmpty) return;
    _taskClientIds.addAll(tasks);
    _expenseClientIds.addAll(expenses);
    notifyListeners();
  }

  /// Layout-side lazy hydrate: resolve the source clientId of every
  /// task/expense referenced by the existing draft (typically a loaded
  /// invoice being edited). Best-effort — failure is silent so an
  /// offline open doesn't block save unnecessarily. Idempotent; only
  /// fetches ids that aren't already in the maps.
  Future<void> hydrateSourceClientIds({
    required Services services,
    required String companyId,
  }) async {
    final items = lineItemsOf(draft);
    final neededTaskIds = items
        .map((li) => li.taskId)
        .whereType<String>()
        .where((s) => s.isNotEmpty && !_taskClientIds.containsKey(s))
        .toSet();
    final neededExpenseIds = items
        .map((li) => li.expenseId)
        .whereType<String>()
        .where((s) => s.isNotEmpty && !_expenseClientIds.containsKey(s))
        .toSet();
    if (neededTaskIds.isEmpty && neededExpenseIds.isEmpty) return;
    try {
      final tasks = await Future.wait(neededTaskIds.map((id) => services.tasks
          .watchByRealId(companyId: companyId, id: id)
          .first));
      final expenses = await Future.wait(neededExpenseIds.map((id) => services
          .expenses
          .watchByRealId(companyId: companyId, id: id)
          .first));
      var changed = false;
      for (final t in tasks) {
        if (t != null && t.clientId.isNotEmpty) {
          _taskClientIds[t.id] = t.clientId;
          changed = true;
        }
      }
      for (final e in expenses) {
        if (e != null && e.clientId.isNotEmpty) {
          _expenseClientIds[e.id] = e.clientId;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (_) {
      // Picker block + auto-cascade keep new data safe; legacy data we
      // can't resolve just won't trip the save validator. No harm.
    }
  }

  /// Returns `{'line_items': [crossClientMessage]}` when any line item's
  /// source task/expense `clientId` is non-blank and doesn't match the
  /// draft's `clientId`. Per-doc VMs merge the result into their
  /// `validate()` so the save flow surfaces it the same way as the
  /// existing `client_required` error.
  Map<String, List<String>> validateCrossClient(String crossClientMessage) {
    final draftClientId = clientIdOf(draft);
    if (draftClientId.isEmpty) return const {};
    for (final li in lineItemsOf(draft)) {
      final tId = li.taskId;
      if (tId != null && tId.isNotEmpty) {
        final src = _taskClientIds[tId] ?? '';
        if (src.isNotEmpty && src != draftClientId) {
          return {
            'line_items': [crossClientMessage],
          };
        }
      }
      final eId = li.expenseId;
      if (eId != null && eId.isNotEmpty) {
        final src = _expenseClientIds[eId] ?? '';
        if (src.isNotEmpty && src != draftClientId) {
          return {
            'line_items': [crossClientMessage],
          };
        }
      }
    }
    return const {};
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

  /// Set the client and, when it actually changed, rebuild the
  /// invitations array from the new client's [contacts]: one invitation
  /// per contact with `sendEmail == true`, falling back to the primary
  /// contact (then the first contact) when none opt in. Mirrors
  /// admin-portal's `UpdateInvoiceClient` reducer + `emailContacts`.
  ///
  /// Re-selecting the same client id is a no-op for invitations, so
  /// manual Contacts-tab selections survive an incidental re-fire.
  /// Vendor-contact docs (PurchaseOrder) keep calling `setClientId`
  /// directly and never reach this path.
  void selectClient(String clientId, Iterable<Contact> contacts) {
    final changed = clientIdOf(draft) != clientId;
    var next = copyWithClientId(draft, clientId);
    if (changed) {
      next = copyWithInvitations(next, _autoInvitations(contacts));
    }
    updateDraft(next);
  }

  /// The invitations to seed when a client is (re)selected: every
  /// non-deleted contact with `sendEmail` or `ccOnly`, or — when none opt
  /// in — the primary contact, or the first contact as a last resort.
  /// Empty when the client has no contacts at all. `ccOnly` contacts are
  /// still emailed (the server demotes them to CC), so they must keep an
  /// invitation even though CC-only auto-clears `sendEmail`.
  List<Invitation> _autoInvitations(Iterable<Contact> contacts) {
    final live = contacts.where((c) => !c.isDeleted).toList(growable: false);
    var chosen =
        live.where((c) => c.sendEmail || c.ccOnly).toList(growable: false);
    if (chosen.isEmpty && live.isNotEmpty) {
      final primary = live.where((c) => c.isPrimary).toList(growable: false);
      chosen = primary.isNotEmpty ? primary : [live.first];
    }
    return [
      for (final c in chosen)
        Invitation(
          id: '',
          key: '',
          link: '',
          clientContactId: c.id,
          vendorContactId: '',
          sentDate: '',
          viewedDate: '',
          openedDate: '',
          emailStatus: '',
          emailError: '',
          messageId: '',
        ),
    ];
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

  /// Read a nested value out of the `eInvoice` structure. [path] mixes
  /// `String` map keys and `int` list indices (UBL arrays serialize as
  /// JSON arrays, e.g. `['CreditNote', 'BillingReference', 0, ...]`).
  /// Returns null when any segment is missing.
  dynamic readEInvoicePath(T draft, List<Object> path) {
    dynamic node = eInvoiceOf(draft);
    for (final key in path) {
      if (key is int) {
        if (node is List && key >= 0 && key < node.length) {
          node = node[key];
        } else {
          return null;
        }
      } else {
        if (node is Map && node.containsKey(key)) {
          node = node[key];
        } else {
          return null;
        }
      }
    }
    return node;
  }

  /// Write a nested value into the `eInvoice` structure, creating
  /// intermediate `Map`s / `List`s as needed. [path] mixes `String` map
  /// keys and `int` list indices. Pass null to remove the leaf. After the
  /// write, empty maps/lists are pruned and an empty root collapses to
  /// null — same omit-when-empty convention as [setEInvoiceField], so an
  /// unedited draft never ships `{}` or a partial UBL skeleton.
  void setEInvoicePath(List<Object> path, dynamic value) {
    assert(path.isNotEmpty);
    final root =
        _deepCloneJson(eInvoiceOf(draft) ?? const <String, dynamic>{})
            as Map<String, dynamic>;
    if (value == null) {
      _removeAtPath(root, path);
    } else {
      _setAtPath(root, path, value);
    }
    _pruneAlongPath(root, path);
    updateDraft(copyWithEInvoice(draft, root.isEmpty ? null : root));
  }

  static dynamic _deepCloneJson(dynamic v) {
    if (v is Map) {
      return <String, dynamic>{
        for (final e in v.entries) e.key as String: _deepCloneJson(e.value),
      };
    }
    if (v is List) return <dynamic>[for (final e in v) _deepCloneJson(e)];
    return v;
  }

  static void _setAtPath(dynamic container, List<Object> path, dynamic value) {
    final key = path.first;
    if (path.length == 1) {
      if (key is int) {
        final list = container as List;
        while (list.length <= key) {
          list.add(null);
        }
        list[key] = value;
      } else {
        (container as Map)[key as String] = value;
      }
      return;
    }
    final nextKey = path[1];
    dynamic child;
    if (key is int) {
      final list = container as List;
      while (list.length <= key) {
        list.add(null);
      }
      child = list[key];
      if (child is! Map && child is! List) {
        child = nextKey is int ? <dynamic>[] : <String, dynamic>{};
        list[key] = child;
      }
    } else {
      final map = container as Map;
      child = map[key as String];
      if (child is! Map && child is! List) {
        child = nextKey is int ? <dynamic>[] : <String, dynamic>{};
        map[key] = child;
      }
    }
    _setAtPath(child, path.sublist(1), value);
  }

  static void _removeAtPath(dynamic container, List<Object> path) {
    if (container == null) return;
    final key = path.first;
    if (path.length == 1) {
      if (key is int && container is List) {
        if (key >= 0 && key < container.length) container.removeAt(key);
      } else if (container is Map) {
        container.remove(key);
      }
      return;
    }
    dynamic child;
    if (key is int && container is List) {
      if (key < 0 || key >= container.length) return;
      child = container[key];
    } else if (container is Map) {
      child = container[key];
    } else {
      return;
    }
    _removeAtPath(child, path.sublist(1));
  }

  static bool _isEmptyNode(dynamic v) =>
      v == null || (v is Map && v.isEmpty) || (v is List && v.isEmpty);

  /// Prune **only along the edited [path]**: after a set/remove, walk the
  /// path from the leaf back up and drop a container entry that became
  /// empty. Unrelated sibling/server branches and their array indices are
  /// left untouched (a whole-tree prune would silently strip server-
  /// provided `{}` / `[]` / null elsewhere in `eInvoice` on round-trip).
  static void _pruneAlongPath(dynamic container, List<Object> path) {
    if (container == null || path.isEmpty) return;
    final key = path.first;
    if (path.length > 1) {
      dynamic child;
      if (key is int && container is List) {
        if (key < 0 || key >= container.length) return;
        child = container[key];
      } else if (container is Map) {
        child = container[key];
      } else {
        return;
      }
      _pruneAlongPath(child, path.sublist(1));
    }
    if (key is int && container is List) {
      if (key >= 0 && key < container.length && _isEmptyNode(container[key])) {
        container.removeAt(key);
      }
    } else if (container is Map) {
      if (container.containsKey(key) && _isEmptyNode(container[key])) {
        container.remove(key);
      }
    }
  }
}
