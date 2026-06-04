import 'package:decimal/decimal.dart';

final Decimal _oneHundredth = Decimal.parse('0.01');

/// Tax amount for a single expense tax tier, computed from its rate.
///
/// Mirrors admin-portal `expense_model.dart` `calculateTaxAmountN` and React
/// `useCalculateExpenseAmount`:
///   * exclusive: `amount * rate / 100`
///   * inclusive: `amount - amount / (1 + rate / 100)`
///
/// Rounded to 2 decimals — admin-portal's convention; the `Formatter` applies
/// the final per-currency precision on display. A zero rate yields zero.
///
/// In `calculate_tax_by_amount` mode the rate is not used at all — the stored
/// `tax_amount*` is the source of truth — so callers pass the stored amount
/// straight through rather than calling this.
Decimal expenseTierTaxAmount({
  required Decimal amount,
  required Decimal rate,
  required bool usesInclusiveTaxes,
}) {
  if (rate == Decimal.zero) return Decimal.zero;
  if (usesInclusiveTaxes) {
    final divisor = Decimal.one + rate * _oneHundredth;
    if (divisor == Decimal.zero) return Decimal.zero;
    final net = (amount / divisor).toDecimal(scaleOnInfinitePrecision: 10);
    return (amount - net).round(scale: 2);
  }
  return (amount * rate * _oneHundredth).round(scale: 2);
}
