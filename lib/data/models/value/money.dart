import 'package:decimal/decimal.dart';

/// Tolerant `Decimal` parser. Invoice Ninja's API returns money either as a
/// number (`100.00`) or a string (`"100.00"`), occasionally as an empty
/// string. Anything unparseable returns [Decimal.zero] — money is never null
/// in the domain model, so the parser never returns null.
///
/// **Never** parse money as `double`. Use this helper for every monetary
/// field; the CI lint test will fail the build if a `double` named like a
/// money field appears in `lib/data/models/`.
Decimal parseMoney(Object? raw) {
  if (raw == null) return Decimal.zero;
  if (raw is num) {
    return Decimal.parse(raw.toString());
  }
  if (raw is String) {
    if (raw.isEmpty) return Decimal.zero;
    return Decimal.tryParse(raw) ?? Decimal.zero;
  }
  return Decimal.zero;
}
