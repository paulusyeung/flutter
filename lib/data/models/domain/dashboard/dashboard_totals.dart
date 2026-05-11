import 'package:decimal/decimal.dart';

import 'package:admin/data/models/value/money.dart';

/// Aggregate totals returned by `POST /api/v1/charts/totals_v2`.
///
/// Server response shape (unwrapped):
/// ```
/// {
///   "currencies": { "1": "USD - United States Dollar", ... },
///   "1": { revenue: ..., expenses: ..., invoices: ..., outstanding: ... },
///   "2": { ... }
/// }
/// ```
///
/// The dashboard repo stores the raw JSON in `dashboard_cache`; this class is
/// the in-memory projection used by the ViewModel and widgets.
class DashboardTotals {
  const DashboardTotals({required this.byCurrency, required this.currencies});

  /// Per-currency totals, keyed by currency id (string form, e.g. `"1"`).
  final Map<String, DashboardCurrencyTotals> byCurrency;

  /// Currency id → display label (e.g. `{ "1": "USD - United States Dollar" }`).
  final Map<String, String> currencies;

  bool get isEmpty => byCurrency.isEmpty;

  static DashboardTotals fromJson(Map<String, dynamic> json) {
    final currencies = <String, String>{};
    final rawCurrencies = json['currencies'];
    if (rawCurrencies is Map) {
      for (final entry in rawCurrencies.entries) {
        currencies[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }
    final byCurrency = <String, DashboardCurrencyTotals>{};
    for (final entry in json.entries) {
      if (entry.key == 'currencies') continue;
      final v = entry.value;
      if (v is Map<String, dynamic>) {
        byCurrency[entry.key] = DashboardCurrencyTotals.fromJson(v);
      } else if (v is Map) {
        byCurrency[entry.key] = DashboardCurrencyTotals.fromJson(
          v.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    }
    return DashboardTotals(byCurrency: byCurrency, currencies: currencies);
  }
}

class DashboardCurrencyTotals {
  const DashboardCurrencyTotals({
    required this.code,
    required this.revenuePaidToDate,
    required this.expensesAmount,
    required this.invoicedAmount,
    required this.invoicedDate,
    required this.outstandingAmount,
    required this.outstandingCount,
  });

  /// Currency code (e.g. `USD`). Pulled from `revenue.code`, which the server
  /// echoes on every sub-bucket.
  final String code;

  final Decimal revenuePaidToDate;
  final Decimal expensesAmount;
  final Decimal invoicedAmount;
  final String invoicedDate; // ISO date of the most recent invoice; may be ''
  final Decimal outstandingAmount;
  final int outstandingCount;

  static DashboardCurrencyTotals fromJson(Map<String, dynamic> json) {
    final revenue = _mapAt(json, 'revenue');
    final expenses = _mapAt(json, 'expenses');
    final invoices = _mapAt(json, 'invoices');
    final outstanding = _mapAt(json, 'outstanding');
    final code =
        (revenue['code'] ??
                expenses['code'] ??
                invoices['code'] ??
                outstanding['code'] ??
                '')
            .toString();
    final countRaw = outstanding['outstanding_count'];
    final count = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;
    return DashboardCurrencyTotals(
      code: code,
      revenuePaidToDate: parseMoney(revenue['paid_to_date']),
      expensesAmount: parseMoney(expenses['amount']),
      invoicedAmount: parseMoney(invoices['invoiced_amount']),
      invoicedDate: (invoices['date'] ?? '').toString(),
      outstandingAmount: parseMoney(outstanding['amount']),
      outstandingCount: count,
    );
  }

  static Map<String, dynamic> _mapAt(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    return const {};
  }
}
