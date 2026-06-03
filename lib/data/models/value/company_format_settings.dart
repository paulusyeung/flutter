/// Subset of the company settings JSON that the number / date formatter
/// needs. Built once per company switch and held on `Services`.
///
/// Wire keys mirror the Invoice Ninja API. `use_comma_as_decimal_place` is
/// historically a top-level company property; admin-portal also reads
/// `settings.use_comma_as_decimal_place` so we accept either spelling.
class CompanyFormatSettings {
  const CompanyFormatSettings({
    required this.currencyId,
    required this.countryId,
    required this.dateFormatId,
    required this.useCommaAsDecimalPlace,
    required this.showCurrencyCode,
    required this.enableMilitaryTime,
    required this.locale,
    this.firstMonthOfYear = 1,
    this.firstDayOfWeek = 0,
  });

  final String currencyId;
  final String countryId;
  final String dateFormatId;
  final bool useCommaAsDecimalPlace;
  final bool showCurrencyCode;
  final bool enableMilitaryTime;

  /// Resolved locale string for `intl`'s `DateFormat` (e.g. `en_US`). Defaults
  /// to `en` when we can't derive one from the company.
  final String locale;

  /// `first_month_of_year` (1=Jan..12=Dec) — a TOP-LEVEL company field, not
  /// inside the `settings` blob. Drives the fiscal-year start for the dashboard
  /// and report "this year" / "last year" ranges. Defaults to 1 (calendar
  /// year). Authoritatively sourced from the company row's own column in
  /// `Services._buildFormatter`; see `lib/utils/date_ranges.dart` for the math.
  final int firstMonthOfYear;

  /// `first_day_of_week` (0=Sun..6=Sat) — top-level company field. Drives the
  /// start-of-week for dashboard charts, report week grouping, and the
  /// date-range calendar grid. Defaults to 0 (Sunday).
  final int firstDayOfWeek;

  /// Default fallback: USD, US, MM/DD/YYYY format id `5`. Matches
  /// `admin-portal/lib/constants.dart:kDefaultCurrencyId` /
  /// `kDefaultDateFormat`. Empty `locale` lets `DateFormat` use the system
  /// locale — which works without calling `initializeDateFormatting`.
  static const fallback = CompanyFormatSettings(
    currencyId: '1',
    countryId: '840',
    dateFormatId: '5',
    useCommaAsDecimalPlace: false,
    showCurrencyCode: false,
    enableMilitaryTime: false,
    locale: '',
    firstMonthOfYear: 1,
    firstDayOfWeek: 0,
  );

  /// Parse from a company's stored settings JSON blob (the
  /// `settings: jsonEncode(uc.company.settings)` column in
  /// `auth_repository.dart`). Accepts either the settings map directly or a
  /// company envelope wrapping it under a `settings` key.
  factory CompanyFormatSettings.fromCompanyJson(Map<String, dynamic> json) {
    final settings = json['settings'] is Map<String, dynamic>
        ? json['settings'] as Map<String, dynamic>
        : json;
    return CompanyFormatSettings(
      // Wire keys: currency_id, country_id, date_format_id, language_id,
      // use_comma_as_decimal_place, show_currency_code, military_time.
      currencyId: _str(settings, 'currency_id', fallback.currencyId),
      countryId: _str(settings, 'country_id', fallback.countryId),
      dateFormatId: _str(settings, 'date_format_id', fallback.dateFormatId),
      useCommaAsDecimalPlace: _bool(settings, 'use_comma_as_decimal_place'),
      showCurrencyCode: _bool(settings, 'show_currency_code'),
      enableMilitaryTime: _bool(settings, 'military_time'),
      locale: _localeFromLanguageId(_str(settings, 'language_id', '')),
      // first_month_of_year / first_day_of_week are TOP-LEVEL company fields
      // (not inside `settings`), so read them off the outer `json`. In the
      // common path `Services._buildFormatter` overrides these from the
      // company row's dedicated columns via copyWith.
      firstMonthOfYear: _int(json, 'first_month_of_year', 1),
      firstDayOfWeek: _int(json, 'first_day_of_week', 0),
    );
  }

  CompanyFormatSettings copyWith({
    String? currencyId,
    String? countryId,
    String? dateFormatId,
    bool? useCommaAsDecimalPlace,
    bool? showCurrencyCode,
    bool? enableMilitaryTime,
    String? locale,
    int? firstMonthOfYear,
    int? firstDayOfWeek,
  }) => CompanyFormatSettings(
    currencyId: currencyId ?? this.currencyId,
    countryId: countryId ?? this.countryId,
    dateFormatId: dateFormatId ?? this.dateFormatId,
    useCommaAsDecimalPlace:
        useCommaAsDecimalPlace ?? this.useCommaAsDecimalPlace,
    showCurrencyCode: showCurrencyCode ?? this.showCurrencyCode,
    enableMilitaryTime: enableMilitaryTime ?? this.enableMilitaryTime,
    locale: locale ?? this.locale,
    firstMonthOfYear: firstMonthOfYear ?? this.firstMonthOfYear,
    firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
  );
}

String _str(Map<String, dynamic> m, String key, String fallback) {
  final v = m[key];
  if (v == null) return fallback;
  final s = v.toString();
  return s.isEmpty ? fallback : s;
}

bool _bool(Map<String, dynamic> m, String key) => m[key] == true;

/// Parse a wire value that may arrive as an int or a numeric string (the API
/// sends `first_month_of_year` as a string). Empty / unparseable → [fallback].
int _int(Map<String, dynamic> m, String key, int fallback) {
  final v = m[key];
  if (v is int) return v;
  if (v == null) return fallback;
  return int.tryParse(v.toString()) ?? fallback;
}

/// Map server language IDs to `intl` locale strings. Mirrors the subset of
/// `admin-portal/lib/redux/company/company_selectors.dart:localeSelector`
/// that actually affects formatting. Falls back to `en` for unknown ids
/// (and for `mk_MK` / `sq` which admin-portal also forces to `en`).
String _localeFromLanguageId(String languageId) {
  switch (languageId) {
    case '1':
      return 'en';
    case '2':
      return 'it';
    case '3':
      return 'de';
    case '4':
      return 'fr';
    case '5':
      return 'pt_BR';
    case '6':
      return 'nl';
    case '7':
      return 'es';
    case '8':
      return 'nb_NO';
    case '9':
      return 'da';
    case '10':
      return 'ja';
    case '11':
      return 'sv';
    case '12':
      return 'es_ES';
    case '13':
      return 'fr_CA';
    case '14':
      return 'lt';
    case '15':
      return 'pl';
    case '16':
      return 'cs';
    case '17':
      return 'hr';
    case '18':
      return 'sk';
    case '19':
      return 'el';
    case '20':
      return 'ro';
    case '21':
      return 'tr_TR';
    case '22':
      return 'th';
    case '23':
      return 'pt_PT';
    case '24':
      return 'ru_RU';
    case '25':
      return 'fi';
    case '26':
      return 'zh_TW';
    case '27':
      return 'fa';
    case '28':
      return 'lv_LV';
    case '29':
      return 'sr';
    case '30':
      return 'sl';
    case '31':
      return 'et';
    case '32':
      return 'bg';
    case '33':
      return 'he';
    case '34':
      return 'km_KH';
    case '35':
      return 'hu';
    case '36':
      return 'fr_CH';
    case '37':
      return 'en_GB';
    case '39':
      return 'ar';
    case '40':
      return 'zh_CN';
    case '41':
      return 'vi';
    default:
      return '';
  }
}
