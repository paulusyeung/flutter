import 'package:flutter_test/flutter_test.dart';

import 'package:admin/utils/tax_regions.dart';

/// Pins the country → SellerSubregion routing table to React's
/// `useCalculateTaxesRegion.ts` + `SellerSubregion.tsx` behaviour. If the
/// React source list changes upstream, this test fails and the port stays
/// honest.
void main() {
  group('sellerSubregionForCountryId', () {
    test('US (country_id=840) routes to the US-state picker', () {
      expect(sellerSubregionForCountryId('840'), SellerSubregionKind.us);
    });

    test('AU (country_id=36) routes to the disabled AU placeholder', () {
      expect(sellerSubregionForCountryId('36'), SellerSubregionKind.australia);
    });

    test(
      'GB / UK (country_id=826) routes to the GB placeholder + is supported',
      () {
        expect(sellerSubregionForCountryId('826'), SellerSubregionKind.britain);
        // React `useCalculateTaxesRegion` lists GB as a supported seller. Post-
        // Brexit it is NOT in the EU set, so it must be listed explicitly or UK
        // companies never see the Calculate Taxes toggle.
        expect(kCalculateTaxesSupportedCountries.contains('GB'), isTrue);
      },
    );

    test(
      'AD / Andorra (country_id=20) routes to the disabled AD placeholder',
      () {
        // React `useCalculateTaxesRegion` lists AD as a supported seller.
        expect(sellerSubregionForCountryId('20'), SellerSubregionKind.andorra);
        expect(kCalculateTaxesSupportedCountries.contains('AD'), isTrue);
      },
    );

    test('null / empty country_id renders no picker', () {
      expect(sellerSubregionForCountryId(null), SellerSubregionKind.none);
      expect(sellerSubregionForCountryId(''), SellerSubregionKind.none);
    });

    test('unknown country_id renders no picker', () {
      expect(sellerSubregionForCountryId('999999'), SellerSubregionKind.none);
    });
  });

  group('region constants', () {
    test('kTaxRegionOrder matches React `CalculateTaxes.tsx`', () {
      expect(kTaxRegionOrder, ['US', 'EU', 'UK', 'AU', 'AD', 'SG']);
    });

    test('kTaxRegionsWithSalesThreshold is EU + UK + SG', () {
      // React renders the sales-above-threshold toggle for EURegions,
      // UKRegions, and SGRegions (`showSalesAboveThreshold`); US / AU / AD do
      // not.
      expect(kTaxRegionsWithSalesThreshold, {'EU', 'UK', 'SG'});
    });

    test('kEuCalculateTaxesCountries covers all React EU/EEA ISO codes', () {
      // 33 codes — 32 in `eu-countries.ts` (Spain has 3 sub-territories)
      // plus the EU/EEA non-EU members (NO/IS/LI). Match the React
      // canonical list exactly so the picker offers the same options.
      expect(kEuCalculateTaxesCountries.keys.toSet(), {
        'AT',
        'BE',
        'BG',
        'HR',
        'CY',
        'CZ',
        'DK',
        'EE',
        'FI',
        'FR',
        'DE',
        'GR',
        'HU',
        'IE',
        'IT',
        'LV',
        'LT',
        'LU',
        'NO',
        'IS',
        'LI',
        'MT',
        'NL',
        'PL',
        'PT',
        'RO',
        'SK',
        'SI',
        'ES',
        'ES-CN',
        'ES-ML',
        'ES-CE',
        'SE',
      });
    });

    test('kUsStates contains 50 states + DC', () {
      expect(kUsStates.length, 51);
      expect(kUsStates.containsKey('CA'), isTrue);
      expect(kUsStates.containsKey('DC'), isTrue);
    });
  });
}
