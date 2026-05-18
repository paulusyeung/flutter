import 'package:decimal/decimal.dart';

import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/invoice.dart';
import 'package:admin/data/models/domain/payment.dart';
import 'package:admin/data/models/domain/purchase_order.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/entity_type.dart';

/// What kind of document a [LedgerEntry] represents — drives the row icon,
/// the filter chips, and tap-through routing.
enum LedgerKind {
  invoice(EntityType.invoice),
  payment(EntityType.payment),
  credit(EntityType.credit),
  expense(EntityType.expense),
  purchaseOrder(EntityType.purchaseOrder);

  const LedgerKind(this.entityType);

  final EntityType entityType;
}

/// One row in a client / vendor ledger. [adjustment] is the signed delta
/// applied to the running balance (a debit is positive — it increases what
/// is owed; a payment / credit is negative). [runningBalance] is the balance
/// *after* this entry, computed in chronological order over the full ledger
/// (filtering rows in the UI never changes a row's balance — same as a
/// real account statement).
class LedgerEntry {
  const LedgerEntry({
    required this.kind,
    required this.id,
    required this.number,
    required this.date,
    required this.adjustment,
    required this.runningBalance,
  });

  final LedgerKind kind;
  final String id;
  final String number;
  final Date? date;
  final Decimal adjustment;
  final Decimal runningBalance;
}

/// Sort key: chronological, with a stable tiebreak so the running balance is
/// deterministic (important for tests + a steady UI). Undated rows sort
/// oldest — they're almost always legacy / imported rows.
int _compare((Date?, LedgerKind, String) a, (Date?, LedgerKind, String) b) {
  final ad = a.$1, bd = b.$1;
  if (ad != null && bd != null) {
    final c = ad.compareTo(bd);
    if (c != 0) return c;
  } else if (ad == null && bd != null) {
    return -1;
  } else if (ad != null && bd == null) {
    return 1;
  }
  final k = a.$2.index.compareTo(b.$2.index);
  if (k != 0) return k;
  return a.$3.compareTo(b.$3);
}

class _Raw {
  _Raw(this.kind, this.id, this.number, this.date, this.adjustment);
  final LedgerKind kind;
  final String id;
  final String number;
  final Date? date;
  final Decimal adjustment;
}

List<LedgerEntry> _assemble(List<_Raw> raws) {
  raws.sort((a, b) => _compare(
        (a.date, a.kind, a.number),
        (b.date, b.kind, b.number),
      ));
  var running = Decimal.zero;
  final out = <LedgerEntry>[];
  for (final r in raws) {
    running += r.adjustment;
    out.add(LedgerEntry(
      kind: r.kind,
      id: r.id,
      number: r.number,
      date: r.date,
      adjustment: r.adjustment,
      runningBalance: running,
    ));
  }
  // Newest first for display; running balance was computed chronologically
  // above so each row still carries its correct as-of balance.
  return out.reversed.toList(growable: false);
}

/// Client receivables ledger: invoices add to what's owed; payments and
/// credits reduce it. Deleted rows are excluded. This is a client-side
/// approximation of the server's authoritative `client.ledger` (which logs
/// activity-level adjustments) — close enough for an at-a-glance statement,
/// not a reconciliation source of truth.
List<LedgerEntry> buildClientLedger({
  required List<Invoice> invoices,
  required List<Payment> payments,
  required List<Credit> credits,
}) {
  final raws = <_Raw>[
    for (final i in invoices)
      if (!i.isDeleted)
        _Raw(LedgerKind.invoice, i.id, i.number, i.date, i.amount),
    for (final p in payments)
      if (!p.isDeleted)
        _Raw(LedgerKind.payment, p.id, p.number, p.date, -p.amount),
    for (final c in credits)
      if (!c.isDeleted)
        _Raw(LedgerKind.credit, c.id, c.number, c.date, -c.amount),
  ];
  return _assemble(raws);
}

/// Vendor ledger: expenses + purchase orders both add to spend. There's no
/// authoritative vendor ledger server-side; this is purely a local
/// chronological roll-up.
List<LedgerEntry> buildVendorLedger({
  required List<Expense> expenses,
  required List<PurchaseOrder> purchaseOrders,
}) {
  final raws = <_Raw>[
    for (final e in expenses)
      if (!e.isDeleted)
        _Raw(LedgerKind.expense, e.id, e.number, e.date, e.amount),
    for (final po in purchaseOrders)
      if (!po.isDeleted)
        _Raw(LedgerKind.purchaseOrder, po.id, po.number, po.date, po.amount),
  ];
  return _assemble(raws);
}
