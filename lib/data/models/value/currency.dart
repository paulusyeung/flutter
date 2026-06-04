import 'package:decimal/decimal.dart';

import 'package:admin/data/models/value/money.dart';

/// Statics-bundle currency. Wire shape matches
/// `admin-portal/lib/data/models/static/currency_model.dart`. Reference data,
/// not a domain entity — kept plain (no freezed) so it stays cheap to build
/// from the cached JSON blob.
class Currency {
  const Currency({
    required this.id,
    required this.name,
    required this.code,
    required this.symbol,
    required this.precision,
    required this.thousandSeparator,
    required this.decimalSeparator,
    required this.swapCurrencySymbol,
    required this.exchangeRate,
  });

  final String id;
  final String name;
  final String code;
  final String symbol;
  final int precision;
  final String thousandSeparator;
  final String decimalSeparator;
  final bool swapCurrencySymbol;
  final Decimal exchangeRate;

  factory Currency.fromMap(Map<String, dynamic> json) => Currency(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    code: json['code']?.toString() ?? '',
    symbol: json['symbol']?.toString() ?? '',
    precision: (json['precision'] as num?)?.toInt() ?? 2,
    thousandSeparator: json['thousand_separator']?.toString() ?? '',
    decimalSeparator: json['decimal_separator']?.toString() ?? '',
    swapCurrencySymbol: json['swap_currency_symbol'] == true,
    exchangeRate: parseMoney(json['exchange_rate']),
  );
}

/// Cross-currency exchange rate derived from the two currencies' base (vs USD)
/// rates: `invoice.exchangeRate / expense.exchangeRate`. Returns null when
/// either currency is unknown or the expense currency's base rate is zero.
/// Mirrors React's expense currency conversion (`AdditionalInfo`).
Decimal? crossCurrencyRate(
  Map<String, Currency> currencies, {
  required String fromExpenseCurrencyId,
  required String toInvoiceCurrencyId,
}) {
  final from = currencies[fromExpenseCurrencyId];
  final to = currencies[toInvoiceCurrencyId];
  if (from == null || to == null || from.exchangeRate == Decimal.zero) {
    return null;
  }
  return (to.exchangeRate / from.exchangeRate).toDecimal(
    scaleOnInfinitePrecision: 10,
  );
}
