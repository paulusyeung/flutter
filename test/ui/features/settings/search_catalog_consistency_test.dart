import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/settings_search_catalog.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/address_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/defaults_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/documents_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/logo_screen.dart';
import 'package:admin/ui/features/settings/views/basic/product_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/task_settings_screen.dart';
import 'package:admin/ui/features/settings/views/basic/tax_settings_body.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_invoices_body.dart';
import 'package:admin/ui/features/settings/views/basic/workflow_settings/workflow_settings_quotes_body.dart';

/// Verifies that the per-screen `kSearchKeys` constants stay in sync with the
/// fields actually rendered by each screen. The catch is simple: every key in
/// a screen's `kSearchKeys` must appear as either an `apiKey: '<key>'` or a
/// `context.tr('<key>')` reference in that screen's source. If a developer
/// removes a field but forgets to update the keys list, this test fails.
///
/// The test scans the source file as text rather than pumping the widget —
/// pumping a settings screen requires a full `Services` graph and is left to
/// follow-up work. The text scan still catches the dominant drift case
/// (stale key after field removal) without that scaffolding cost.
///
/// To extend coverage to a new screen: add a `_TabUnderTest` entry with the
/// screen's source path(s) and its `kSearchKeys` constant. `sourcePaths`
/// accepts multiple files for screens whose rendering surface spans more
/// than one widget (e.g. Tax Settings, where the body, picker, and
/// subregion dialog each render distinct labels).
void main() {
  group('search catalog consistency', () {
    test('kSettingsSearchCatalog[company_details] equals the union of '
        'per-tab kSearchKeys constants', () {
      final union = <String>[
        ...kCompanyDetailsDetailsSearchKeys,
        ...kCompanyDetailsAddressSearchKeys,
        ...kCompanyDetailsLogoSearchKeys,
        ...kCompanyDetailsDefaultsSearchKeys,
        ...kCompanyDetailsDocumentsSearchKeys,
        ...kCompanyDetailsCustomFieldsSearchKeys,
      ];
      expect(
        kSettingsSearchCatalog['company_details'],
        union,
        reason:
            'kSettingsSearchCatalog["company_details"] must aggregate the '
            'per-tab constants via spread. Edit settings_search_catalog.dart '
            'to keep them in sync.',
      );
    });

    test('kSettingsSearchCatalog[workflow_settings] equals the union of '
        'per-tab kSearchKeys constants', () {
      final union = <String>[
        ...kWorkflowSettingsInvoicesSearchKeys,
        ...kWorkflowSettingsQuotesSearchKeys,
      ];
      expect(
        kSettingsSearchCatalog['workflow_settings'],
        union,
        reason:
            'kSettingsSearchCatalog["workflow_settings"] must aggregate the '
            'per-tab constants via spread. Edit settings_search_catalog.dart '
            'to keep them in sync.',
      );
    });

    for (final tab in _tabsUnderTest) {
      test('${tab.label}: every kSearchKeys entry is referenced in source', () {
        final source = tab.sourcePaths
            .map((p) => File(p).readAsStringSync())
            .join('\n');
        final referenced = _extractReferencedKeys(source);
        for (final key in tab.keys) {
          expect(
            referenced.contains(key),
            isTrue,
            reason:
                'kSearchKeys for ${tab.label} declares "$key" but no '
                'context.tr("$key") or apiKey: "$key" reference exists in '
                '${tab.sourcePaths.join(", ")}. Either render the field or '
                'drop the key.',
          );
        }
      });
    }
  });
}

class _TabUnderTest {
  const _TabUnderTest({
    required this.label,
    required this.sourcePaths,
    required this.keys,
  });

  final String label;
  final List<String> sourcePaths;
  final List<String> keys;
}

final List<_TabUnderTest> _tabsUnderTest = [
  const _TabUnderTest(
    label: 'company_details/details',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/company_details/company_details_screen.dart',
    ],
    keys: kCompanyDetailsDetailsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/address',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/company_details/address_screen.dart',
    ],
    keys: kCompanyDetailsAddressSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/logo',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/company_details/logo_screen.dart',
    ],
    keys: kCompanyDetailsLogoSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/defaults',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/company_details/defaults_screen.dart',
    ],
    keys: kCompanyDetailsDefaultsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/documents',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/company_details/documents_screen.dart',
    ],
    keys: kCompanyDetailsDocumentsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/custom_fields',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/company_details/custom_fields_screen.dart',
    ],
    keys: kCompanyDetailsCustomFieldsSearchKeys,
  ),
  // Tax Settings — rendering surface spans the body widget + the slot
  // picker + the regional subregion edit dialog. The labels for `tax_name`,
  // `tax_rate`, and `reduced_rate` live in the dialog; everything else is
  // in the body.
  const _TabUnderTest(
    label: 'tax_settings',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/tax_settings_body.dart',
      'lib/ui/features/settings/widgets/tax_rate_picker.dart',
      'lib/ui/features/settings/widgets/subregion_edit_dialog.dart',
    ],
    keys: kTaxSettingsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'product_settings',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/product_settings_screen.dart',
    ],
    keys: kProductSettingsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'task_settings',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/task_settings_screen.dart',
    ],
    keys: kTaskSettingsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'workflow_settings/invoices',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/workflow_settings/workflow_settings_invoices_body.dart',
    ],
    keys: kWorkflowSettingsInvoicesSearchKeys,
  ),
  const _TabUnderTest(
    label: 'workflow_settings/quotes',
    sourcePaths: [
      'lib/ui/features/settings/views/basic/workflow_settings/workflow_settings_quotes_body.dart',
    ],
    keys: kWorkflowSettingsQuotesSearchKeys,
  ),
];

final _trKey = RegExp(r"""context\.tr\(\s*['"]([\w]+)['"]""");
final _apiKey = RegExp(r"""apiKey:\s*['"]([\w]+)['"]""");
final _labelText = RegExp(r"""labelText:\s*context\.tr\(\s*['"]([\w]+)['"]""");

Set<String> _extractReferencedKeys(String source) {
  final keys = <String>{};
  for (final pattern in [_trKey, _apiKey, _labelText]) {
    for (final match in pattern.allMatches(source)) {
      keys.add(match.group(1)!);
    }
  }
  return keys;
}
