import 'package:decimal/decimal.dart';

import 'package:admin/data/models/value/money.dart';

/// Result of one `POST /api/v1/charts/calculated_fields` call.
///
/// The endpoint returns a **bare scalar** (verified against the demo API:
/// `69430`, `25`, `0`). We still tolerate a `{value|data: n}` wrapper
/// defensively in case the server shape ever changes. Hand-written to match
/// the rest of `models/domain/dashboard/`.
class DashboardCalculatedField {
  const DashboardCalculatedField(this.value);

  /// Raw numeric value. Interpretation depends on the card's format:
  /// money/avg → currency, count → integer, time → seconds.
  final num value;

  Decimal get asDecimal => parseMoney(value);

  static DashboardCalculatedField fromServer(Object? raw) {
    if (raw is num) return DashboardCalculatedField(raw);
    if (raw is String) {
      return DashboardCalculatedField(num.tryParse(raw) ?? 0);
    }
    if (raw is Map) {
      final v = raw['value'] ?? raw['data'] ?? raw['total'];
      if (v is num) return DashboardCalculatedField(v);
      if (v is String) return DashboardCalculatedField(num.tryParse(v) ?? 0);
    }
    return const DashboardCalculatedField(0);
  }

  /// JSON round-trip for the dashboard cache payload (stored as `{"value":n}`).
  Map<String, dynamic> toJson() => {'value': value};

  static DashboardCalculatedField fromJson(Map<String, dynamic> json) =>
      fromServer(json);
}
