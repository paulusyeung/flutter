import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/custom_field_types.dart';
import 'package:admin/utils/formatting.dart';

/// Convenience accessors for the company's per-entity custom-field
/// configuration map.
///
/// The server stores per-entity custom field definitions in
/// `Company.customFields` under keys like `client1..4`, `product1..4`,
/// `invoice1..4`, `contact1..4` — each value follows the pipe-delimited shape
/// `"Label|type"` / `"Label|opt1,opt2"`. All parsing routes through the shared
/// [parseCustomField] so settings and consumers stay in lockstep.
extension CompanyCustomFields on Company {
  /// Parsed label for the slot at [key]. Returns the empty string when the
  /// slot is unconfigured (missing key or empty value), so call sites can
  /// gate visibility with `.isEmpty` without a nullable hop.
  ///
  /// Examples (given `customFields = {'client1': 'Region|North,South'}`):
  /// * `customFieldLabel('client1')` → `'Region'`
  /// * `customFieldLabel('client2')` → `''`
  String customFieldLabel(String key) =>
      parseCustomField(customFields[key]).label;

  /// Render type (`kFieldType*`) for the slot at [key]. An unconfigured slot
  /// resolves to [kFieldTypeSingleLineText] — callers gate on the empty label
  /// first, so the default only matters for configured slots.
  String customFieldType(String key) =>
      parseCustomField(customFields[key]).type;

  /// Dropdown options for the slot at [key]; empty for non-dropdown types.
  List<String> customFieldOptions(String key) =>
      parseCustomField(customFields[key]).options;

  /// Format a stored custom [value] for read-only display on detail screens.
  /// Switch values surface as the localized [yes] / [no]; dates run through
  /// [formatter] (ISO fallback when null); everything else shows verbatim.
  String customFieldDisplay(
    String key,
    String value, {
    Formatter? formatter,
    required String yes,
    required String no,
  }) {
    switch (customFieldType(key)) {
      case kFieldTypeSwitch:
        return isSwitchTruthy(value) ? yes : no;
      case kFieldTypeDate:
        return value.isEmpty ? '' : (formatter?.date(value) ?? value);
      default:
        return value;
    }
  }
}
