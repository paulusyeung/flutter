import 'package:flutter_test/flutter_test.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/settings_search_catalog.dart';

void main() {
  group('settings search catalog', () {
    test('every catalog section has a matching SettingsSectionDef', () {
      for (final slug in kSettingsSearchCatalog.keys) {
        expect(
          kSettingsSectionsBySlug.containsKey(slug),
          isTrue,
          reason:
              'Catalog references section "$slug" but no '
              'SettingsSectionDef has that slug. Add the section to '
              'kSettingsSections or remove the orphan catalog entry.',
        );
      }
    });

    test('section routes all start with /settings/<slug>', () {
      for (final section in kSettingsSections) {
        expect(
          section.route,
          startsWith('/settings/'),
          reason:
              'Section "${section.slug}" has unexpected route '
              '${section.route}',
        );
      }
    });

    test('searchSettings returns the full catalog for an empty query', () {
      final l10n = Localization.forTesting(strings: const {});
      final hits = searchSettings('', l10n);
      final totalFields = kSettingsSearchCatalog.values
          .map((v) => v.length)
          .fold<int>(0, (a, b) => a + b);
      expect(hits, hasLength(totalFields));
    });

    test('searchSettings matches case-insensitively on localized label', () {
      // Stub a label so we can search by the rendered string, not the key.
      final l10n = Localization.forTesting(
        strings: const {'vat_number': 'VAT Number'},
      );
      final hits = searchSettings('vat', l10n);
      expect(hits, isNotEmpty);
      expect(
        hits.any(
          (h) =>
              h.fieldKey == 'vat_number' && h.section.slug == 'company_details',
        ),
        isTrue,
      );
    });

    test('searchSettings returns no hits for a no-match query', () {
      final l10n = Localization.forTesting(strings: const {});
      // Missing keys fall through to the raw key, so the query has to miss
      // both the localized label and every field key in the catalog.
      final hits = searchSettings('zzz_definitely_not_a_field', l10n);
      expect(hits, isEmpty);
    });
  });
}
