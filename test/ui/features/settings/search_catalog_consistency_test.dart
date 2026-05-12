import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/settings_search_catalog.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/address_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/company_details_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/custom_fields_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/defaults_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/documents_screen.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/logo_screen.dart';

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
/// screen's source path and its `kSearchKeys` constant.
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

    for (final tab in _companyDetailsTabsUnderTest) {
      test('${tab.label}: every kSearchKeys entry is referenced in source', () {
        final source = File(tab.sourcePath).readAsStringSync();
        final referenced = _extractReferencedKeys(source);
        for (final key in tab.keys) {
          expect(
            referenced.contains(key),
            isTrue,
            reason:
                'kSearchKeys for ${tab.label} declares "$key" but no '
                'context.tr("$key") or apiKey: "$key" reference exists in '
                '${tab.sourcePath}. Either render the field or drop the key.',
          );
        }
      });
    }
  });
}

class _TabUnderTest {
  const _TabUnderTest({
    required this.label,
    required this.sourcePath,
    required this.keys,
  });

  final String label;
  final String sourcePath;
  final List<String> keys;
}

final List<_TabUnderTest> _companyDetailsTabsUnderTest = [
  const _TabUnderTest(
    label: 'company_details/details',
    sourcePath:
        'lib/ui/features/settings/views/basic/company_details/company_details_screen.dart',
    keys: kCompanyDetailsDetailsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/address',
    sourcePath:
        'lib/ui/features/settings/views/basic/company_details/address_screen.dart',
    keys: kCompanyDetailsAddressSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/logo',
    sourcePath:
        'lib/ui/features/settings/views/basic/company_details/logo_screen.dart',
    keys: kCompanyDetailsLogoSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/defaults',
    sourcePath:
        'lib/ui/features/settings/views/basic/company_details/defaults_screen.dart',
    keys: kCompanyDetailsDefaultsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/documents',
    sourcePath:
        'lib/ui/features/settings/views/basic/company_details/documents_screen.dart',
    keys: kCompanyDetailsDocumentsSearchKeys,
  ),
  const _TabUnderTest(
    label: 'company_details/custom_fields',
    sourcePath:
        'lib/ui/features/settings/views/basic/company_details/custom_fields_screen.dart',
    keys: kCompanyDetailsCustomFieldsSearchKeys,
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
