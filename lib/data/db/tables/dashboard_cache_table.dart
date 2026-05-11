import 'package:drift/drift.dart';

/// Cache of read-only dashboard API responses, keyed by
/// `(company_id, kind, filter_hash)`.
///
/// The dashboard is read-only — there is no outbox path. The repo writes the
/// raw API JSON response into [payload] and the UI watches per-row streams
/// per the project rule "Drift is the only thing the UI reads from."
///
/// `kind` is one of:
///   - `totals_current`, `totals_previous` — POST `charts/totals_v2`
///   - `chart`                              — POST `charts/chart_summary_v2`
///   - `activities`                         — GET  `activities?reactv2`
///   - `past_due`, `upcoming_invoices`      — GET  `invoices?...`
///   - `recent_payments`                    — GET  `payments?...`
///   - `expired_quotes`, `upcoming_quotes`  — GET  `quotes?...`
///   - `upcoming_recurring`                 — GET  `recurring_invoices?...`
///
/// `filter_hash` is `'_'` for list-card kinds (they aren't filter-keyed).
/// Only `totals_current`, `totals_previous`, and `chart` use a real hash.
@DataClassName('DashboardCacheRow')
class DashboardCache extends Table {
  TextColumn get companyId => text().named('company_id')();
  TextColumn get kind => text()();
  TextColumn get filterHash => text().named('filter_hash')();
  TextColumn get payload => text()();
  IntColumn get fetchedAt => integer().named('fetched_at')();

  @override
  Set<Column> get primaryKey => {companyId, kind, filterHash};
}
