/// Configuration for one user-added dashboard metric card — the Flutter port
/// of React's `dashboard_fields` entry
/// (`react/src/pages/dashboard/components/DashboardCardSelector.tsx`).
///
/// Each card = a [field] (one of [kDashboardCardFields]) × [period] ×
/// [calculate] × [format]. The tuple is fetched via
/// `POST /api/v1/charts/calculated_fields`. Hand-written (no codegen) to match
/// the rest of `models/domain/dashboard/` (see `dashboard_totals.dart`).
library;

enum CardPeriod { current, previous, total }

enum CardCalc { sum, avg, count }

enum CardFormat { money, time }

/// The 13 field keys, exactly as React's `FIELDS`
/// (`DashboardCardSelector.tsx`). Order is the picker's default order.
const List<String> kDashboardCardFields = [
  'active_invoices',
  'outstanding_invoices',
  'completed_payments',
  'refunded_payments',
  'active_quotes',
  'unapproved_quotes',
  'logged_tasks',
  'invoiced_tasks',
  'paid_tasks',
  'logged_expenses',
  'pending_expenses',
  'invoiced_expenses',
  'invoice_paid_expenses',
];

/// Localization key for a field's card label. React's `FIELDS_LABELS` maps
/// every field to `total_<field>` (e.g. `active_invoices` →
/// `total_active_invoices`).
String fieldLabelKey(String field) => 'total_$field';

/// Only the three `*_tasks` fields may use [CardFormat.time]; everything else
/// is always [CardFormat.money]. Mirrors React's
/// `selectedField.endsWith('tasks')`.
bool isTaskField(String field) => field.endsWith('tasks');

class DashboardCardConfig {
  const DashboardCardConfig({
    required this.field,
    required this.period,
    required this.calculate,
    required this.format,
  });

  final String field;
  final CardPeriod period;
  final CardCalc calculate;
  final CardFormat format;

  /// Stable identity used as the persistence value and the per-card cache
  /// `kind` suffix. Matches React's encode (minus the trailing index, which
  /// only existed to disambiguate React's array keys — list order does that
  /// for us).
  String get key => '$field|${period.name}|${calculate.name}|${format.name}';

  /// Parse a `field|period|calculate|format` key. Returns null for anything
  /// malformed or referencing an unknown field/enum (callers skip it).
  static DashboardCardConfig? tryParse(Object? raw) {
    if (raw is! String) return null;
    final parts = raw.split('|');
    if (parts.length != 4) return null;
    final field = parts[0];
    if (!kDashboardCardFields.contains(field)) return null;
    final period = _byName(CardPeriod.values, parts[1]);
    final calc = _byName(CardCalc.values, parts[2]);
    var fmt = _byName(CardFormat.values, parts[3]);
    if (period == null || calc == null || fmt == null) return null;
    // A non-task field can never legitimately be `time`.
    if (fmt == CardFormat.time && !isTaskField(field)) fmt = CardFormat.money;
    return DashboardCardConfig(
      field: field,
      period: period,
      calculate: calc,
      format: fmt,
    );
  }

  /// Persisted form is just [key] — keeps the nav_state envelope compact and
  /// mirrors React storing an array of encoded strings.
  String toJson() => key;

  static T? _byName<T extends Enum>(List<T> values, String name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardCardConfig && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
