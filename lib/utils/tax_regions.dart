// Tax-region constants and lookups for Settings → Tax Settings.
//
// Ported verbatim from the React client:
//  * `src/common/hooks/useCalculateTaxesRegion.ts` — supported countries
//    for the Calculate Taxes feature.
//  * `src/common/constants/eu-countries.ts` — EU/EEA member ISO-3166-2
//    codes used as the EU subregion picker source.
//  * `src/pages/settings/tax-settings/components/calculate-taxes/components/SellerSubregion.tsx`
//    — seller-subregion widget routing (US states / EU countries /
//    disabled AU / disabled GB).
//
// Display values mirror what the React UI shows. Keep this file in sync
// with the JS source so behaviour parity is provable by inspection.

/// Static map of `country_id` (Invoice Ninja's numeric DB id, shipped as a
/// String) → ISO-3166-2 code. The full statics blob keeps the canonical
/// mapping; this constant only covers the three countries we need to special
/// case for [calculateTaxesRegionForCountryId]. Add new ids here if the UI
/// grows additional country-specific branches.
const Map<String, String> kCountryIdToIso3166Alpha2 = {
  '20': 'AD', // Andorra
  '36': 'AU', // Australia
  '840': 'US', // United States
  '826': 'GB', // United Kingdom (Great Britain)
};

/// EU / EEA member countries with their English display name. Keys are the
/// ISO-3166-2 (alpha-2) codes; values are the React-source-of-truth labels.
const Map<String, String> kEuCalculateTaxesCountries = {
  'AT': 'Austria',
  'BE': 'Belgium',
  'BG': 'Bulgaria',
  'HR': 'Croatia',
  'CY': 'Cyprus',
  'CZ': 'Czech Republic',
  'DK': 'Denmark',
  'EE': 'Estonia',
  'FI': 'Finland',
  'FR': 'France',
  'DE': 'Germany',
  'GR': 'Greece',
  'HU': 'Hungary',
  'IE': 'Ireland',
  'IT': 'Italy',
  'LV': 'Latvia',
  'LT': 'Lithuania',
  'LU': 'Luxembourg',
  'NO': 'Norway',
  'IS': 'Iceland',
  'LI': 'Liechtenstein',
  'MT': 'Malta',
  'NL': 'Netherlands',
  'PL': 'Poland',
  'PT': 'Portugal',
  'RO': 'Romania',
  'SK': 'Slovakia',
  'SI': 'Slovenia',
  'ES': 'Spain',
  'ES-CN': 'Canary Islands',
  'ES-ML': 'Melilla',
  'ES-CE': 'Ceuta',
  'SE': 'Sweden',
};

/// Countries that support the Calculate Taxes automation (per React's
/// `useCalculateTaxesRegion`). Used to gate the toggle's visibility — kept
/// here in raw form even though the v1 Flutter UI exposes the toggle
/// unconditionally; the gate is one constant flip away.
final Set<String> kCalculateTaxesSupportedCountries = <String>{
  'AU',
  'US',
  'AD', // Andorra — supported seller per React `useCalculateTaxesRegion`.
  'GB', // Great Britain — supported seller per React `useCalculateTaxesRegion`;
  // post-Brexit it is NOT in `kEuCalculateTaxesCountries`, so it must be listed
  // here explicitly or UK companies never see the Calculate Taxes toggle.
  ...kEuCalculateTaxesCountries.keys,
};

/// Identifies which subregion-picker UI to render on the Tax Settings page.
/// Mirrors the four-way switch in React `SellerSubregion.tsx`.
enum SellerSubregionKind { us, eu, australia, britain, andorra, none }

/// Resolve which seller-subregion widget to render for the given
/// `country_id`. Returns [SellerSubregionKind.none] when the country isn't
/// in any of the supported regions — the widget is then hidden.
SellerSubregionKind sellerSubregionForCountryId(String? countryId) {
  if (countryId == null || countryId.isEmpty) return SellerSubregionKind.none;
  final iso = kCountryIdToIso3166Alpha2[countryId];
  if (iso == 'US') return SellerSubregionKind.us;
  if (iso == 'AU') return SellerSubregionKind.australia;
  if (iso == 'GB') return SellerSubregionKind.britain;
  if (iso == 'AD') return SellerSubregionKind.andorra;
  if (iso != null && kEuCalculateTaxesCountries.containsKey(iso)) {
    return SellerSubregionKind.eu;
  }
  return SellerSubregionKind.none;
}

/// 50 US states + DC + 5 commonly-used territories, keyed by their
/// USPS two-letter postal abbreviation. Display names follow USPS.
const Map<String, String> kUsStates = {
  'AL': 'Alabama',
  'AK': 'Alaska',
  'AZ': 'Arizona',
  'AR': 'Arkansas',
  'CA': 'California',
  'CO': 'Colorado',
  'CT': 'Connecticut',
  'DE': 'Delaware',
  'FL': 'Florida',
  'GA': 'Georgia',
  'HI': 'Hawaii',
  'ID': 'Idaho',
  'IL': 'Illinois',
  'IN': 'Indiana',
  'IA': 'Iowa',
  'KS': 'Kansas',
  'KY': 'Kentucky',
  'LA': 'Louisiana',
  'ME': 'Maine',
  'MD': 'Maryland',
  'MA': 'Massachusetts',
  'MI': 'Michigan',
  'MN': 'Minnesota',
  'MS': 'Mississippi',
  'MO': 'Missouri',
  'MT': 'Montana',
  'NE': 'Nebraska',
  'NV': 'Nevada',
  'NH': 'New Hampshire',
  'NJ': 'New Jersey',
  'NM': 'New Mexico',
  'NY': 'New York',
  'NC': 'North Carolina',
  'ND': 'North Dakota',
  'OH': 'Ohio',
  'OK': 'Oklahoma',
  'OR': 'Oregon',
  'PA': 'Pennsylvania',
  'RI': 'Rhode Island',
  'SC': 'South Carolina',
  'SD': 'South Dakota',
  'TN': 'Tennessee',
  'TX': 'Texas',
  'UT': 'Utah',
  'VT': 'Vermont',
  'VA': 'Virginia',
  'WA': 'Washington',
  'WV': 'West Virginia',
  'WI': 'Wisconsin',
  'WY': 'Wyoming',
  'DC': 'District of Columbia',
};

/// Region order used by the Calculate Taxes editor — matches React's
/// `CalculateTaxes.tsx` mounting order (US, EU, UK, AU, Andorra, Singapore).
const List<String> kTaxRegionOrder = ['US', 'EU', 'UK', 'AU', 'AD', 'SG'];

/// Localization key for each region's display name. Resolved from
/// `assets/i18n/en.json` or, for the app-local names not yet in Transifex,
/// `assets/i18n/_app_pending.json` (see `tax_settings_localization_test`).
const Map<String, String> kTaxRegionLabelKeys = {
  'US': 'united_states',
  'EU': 'europe',
  'UK': 'united_kingdom',
  'AU': 'australia',
  'AD': 'andorra',
  'SG': 'singapore',
};

/// Regions that render a Sales-Above-Threshold toggle. Mirrors React: EU
/// (`EURegions.tsx`), UK (`UKRegions.tsx`), and SG (`SGRegions.tsx` passes
/// `showSalesAboveThreshold`). US / AU / AD do not.
const Set<String> kTaxRegionsWithSalesThreshold = {'EU', 'UK', 'SG'};
