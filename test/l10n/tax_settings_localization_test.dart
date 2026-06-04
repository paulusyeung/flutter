import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/utils/tax_regions.dart';

/// Guards that every localization key rendered by Settings → Tax Settings
/// resolves to a real string — either in `assets/i18n/en.json` (the Transifex
/// source of truth) or `assets/i18n/_app_pending.json` (app-local strings not
/// yet in Transifex). `context.tr()` returns the raw snake_case key when a
/// key is missing from BOTH, so a gap here ships developer slugs to users.
///
/// This is the safety net the pre-launch review was missing: the Tax Settings
/// screen leans heavily on app-local keys (region names, the Calculate Taxes
/// editor labels), and no other test covers them.
void main() {
  test('every Tax Settings localization key resolves', () async {
    final keys = await _loadAllAvailableKeys();

    // Region card labels are data-driven off this map, so pull them straight
    // from the source rather than hard-coding (keeps the test honest if the
    // region list changes).
    final used = <String>{
      ...kTaxRegionLabelKeys.values,

      // tax_settings_body.dart
      'tax_settings',
      'invoice_tax_rates',
      'invoice_item_tax_rates',
      'expense_tax_rates',
      'inclusive_taxes',
      'exclusive_inclusive_tax_help',
      'default_tax_rate',
      'disabled',
      'one_tax_rate',
      'two_tax_rates',
      'three_tax_rates',
      'calculate_taxes',
      'calculate_taxes_help',
      'calculate_taxes_warning',
      'cancel',
      'continue',
      'tax_rates',
      'configure_tax_rates',
      'seller_subregion',
      'tax_regions_initialize_hint',
      'selected_of',
      'show',
      'hide',
      'apply_tax_to_all_subregions',
      'sales_above_threshold',
      'edit',

      // tax_rate_picker.dart
      'no_tax_rates_yet',
      'no_tax_rates_yet_hint',

      // subregion_edit_dialog.dart
      'tax_name',
      'tax_rate',
      'reduced_rate',
      'vat_number',
      'save',

      // tax_rates_edit_screen.dart
      'new_tax_rate',
      'edit_tax_rate',
      'name',
      'rate',
    };

    final missing = used.where((k) => !keys.contains(k)).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason:
          'Tax Settings uses these keys but neither en.json nor '
          '_app_pending.json defines them — they would render as raw slugs. '
          'Add them to assets/i18n/_app_pending.json:\n${missing.join('\n')}',
    );
  });
}

Future<Set<String>> _loadAllAvailableKeys() async {
  final keys = <String>{};
  for (final path in const [
    'assets/i18n/en.json',
    'assets/i18n/_app_pending.json',
  ]) {
    final raw = await File(path).readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    keys.addAll(json.keys);
  }
  return keys;
}
