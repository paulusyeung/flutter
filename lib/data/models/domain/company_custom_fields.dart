import 'package:admin/data/models/domain/company.dart';

/// Convenience accessors for the company's per-entity custom-field
/// configuration map.
///
/// The server stores per-entity custom field labels in `Company.customFields`
/// under keys like `client1..4`, `product1..4`, `invoice1..4`,
/// `contact1..4` — each value follows the format `"Label|preset1,preset2"`.
/// Today the app reads only the label; presets exist in the wire shape but
/// aren't surfaced as a value-picker yet.
extension CompanyCustomFields on Company {
  /// Parsed label for the slot at [key]. Returns the empty string when the
  /// slot is unconfigured (missing key or empty value), so call sites can
  /// gate visibility with `.isEmpty` without a nullable hop.
  ///
  /// Examples (given `customFields = {'client1': 'Region|North,South'}`):
  /// * `customFieldLabel('client1')` → `'Region'`
  /// * `customFieldLabel('client2')` → `''`
  /// * `customFieldLabel('product1')` → `''`
  String customFieldLabel(String key) {
    final raw = customFields[key];
    if (raw == null || raw.isEmpty) return '';
    final pipe = raw.indexOf('|');
    return pipe == -1 ? raw : raw.substring(0, pipe);
  }
}
