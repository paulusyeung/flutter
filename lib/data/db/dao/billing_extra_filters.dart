import 'package:admin/domain/payment_status.dart';

/// Pure parsers that turn a list ViewModel's `extraFilters` map (the
/// server-bound filter dimensions) into the typed inputs each billing-doc
/// DAO's `watchPage` applies as **local Drift predicates**.
///
/// Why this exists: the standalone Invoice / Quote / Credit / Payment /
/// Expense lists render from the local Drift cache (`watchPage`), but only
/// the *server* fetch (`ensurePageLoaded`) was honoring `extraFilters`. The
/// local watch re-emitted the whole cache, so a `client:` / `status:` /
/// `date_range:` filter looked like it did nothing. These helpers + the
/// per-DAO predicates close that gap so the local view matches the server
/// filter exactly. Keeping the value parsing here (one source of truth,
/// one test target) avoids re-deriving the divergence-prone mappings —
/// especially the payment computed-status wire→id table — in five places.

/// `client_id` — membership set of client ids. Multi-value (the
/// `ClientFilterKey` is a union membership key).
Set<String> parseClientIdFilter(Map<String, Set<String>> extraFilters) =>
    extraFilters['client_id'] ?? const <String>{};

/// Invoice `status_id` — already the persisted numeric wire ids `'1'..'6'`,
/// so they map straight onto the `statusId` column.
Set<String> parseInvoiceStatusFilter(Map<String, Set<String>> extraFilters) =>
    extraFilters['status_id'] ?? const <String>{};

/// Invoice `overdue:true` — single boolean dimension.
bool parseOverdueFilter(Map<String, Set<String>> extraFilters) =>
    (extraFilters['overdue'] ?? const <String>{}).contains('true');

/// Expense `categories` — membership set of category ids (the server param
/// is `categories`; the local column is `category_id`).
Set<String> parseExpenseCategoryFilter(Map<String, Set<String>> extraFilters) =>
    extraFilters['categories'] ?? const <String>{};

/// Quote `client_status` — wire labels (`draft|sent|approved|expired|
/// upcoming|converted`). Passed through verbatim; `QuoteDao.watchPage`
/// turns the enumerated + computed members into a single OR predicate
/// mirroring `Quote.calculatedStatusId` / `Quote.isExpired`.
Set<String> parseQuoteStatusFilter(Map<String, Set<String>> extraFilters) =>
    extraFilters['client_status'] ?? const <String>{};

/// Payment `client_status` — wire labels. Map to the `statusId` discriminators
/// `PaymentDao.watchPage` already understands (numeric `'1'..'6'` plus the
/// virtual `kPaymentStatusPartiallyUnapplied` `'-2'`). Mirrors
/// `kPaymentStatusLabels` (the inverse of that table) so the local predicate
/// and `Payment.calculatedStatusId` stay in lockstep.
Set<String> parsePaymentStatusFilter(Map<String, Set<String>> extraFilters) {
  final wire = extraFilters['client_status'] ?? const <String>{};
  if (wire.isEmpty) return const <String>{};
  const byLabel = <String, String>{
    'pending': kPaymentStatusPending,
    'cancelled': kPaymentStatusCancelled,
    'failed': kPaymentStatusFailed,
    'completed': kPaymentStatusCompleted,
    'partially_refunded': kPaymentStatusPartiallyRefunded,
    'refunded': kPaymentStatusRefunded,
    'partially_unapplied': kPaymentStatusPartiallyUnapplied,
    'unapplied': kPaymentStatusUnapplied,
  };
  return {
    for (final w in wire)
      if (byLabel[w] != null) byLabel[w]!,
  };
}

/// A closed `[start, end]` date window (inclusive), or `(null, null)` when
/// absent / malformed. [partCount] is 2 for the base `date_range`
/// (`"<start>,<end>"`, invoices/quotes) and 3 for `PaymentFilters::date_range`
/// (`"<label>,<start>,<end>"`). Values are ISO `YYYY-MM-DD` strings, which
/// compare correctly with the `date` TEXT column lexicographically.
({String? start, String? end}) parseDateRangeFilter(
  Map<String, Set<String>> extraFilters, {
  required int partCount,
}) {
  final raw = (extraFilters['date_range'] ?? const <String>{});
  if (raw.isEmpty) return (start: null, end: null);
  final parts = raw.first.split(',');
  if (parts.length < partCount) return (start: null, end: null);
  final start = parts[partCount - 2].trim();
  final end = parts[partCount - 1].trim();
  if (start.isEmpty || end.isEmpty) return (start: null, end: null);
  return (start: start, end: end);
}
