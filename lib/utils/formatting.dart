/// Number / date / address / URL formatting. Ported from
/// `admin-portal/lib/utils/formatting.dart` with these cleanups:
///
/// 1. No global state. The old code read company + statics from Redux and
///    mutated `numberFormatSymbols['custom']` on every call. This file is
///    pure: stateless helpers + a `Formatter` class bound to one company's
///    settings + statics maps.
/// 2. The `formatNumber` mega-function is split into one method per intent
///    (`money`, `percent`, `integer`, `decimal`, `inputMoney`, `inputAmount`).
///    The `FormatNumberType` enum is gone.
/// 3. `Decimal` is the input type for money methods (per the project rule
///    "Money is `Decimal`, never `double`"). Conversion to `double` happens
///    only at the final string-formatting step.
/// 4. Number grouping is hand-rolled (`_formatGrouped`) so it can take
///    separators directly — no `intl`'s `numberFormatSymbols` hijack.
library;

import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';

import 'package:admin/data/models/value/company_format_settings.dart';
import 'package:admin/data/models/value/country.dart';
import 'package:admin/data/models/value/currency.dart';
import 'package:admin/data/models/value/datetime_format.dart';

// ---------------------------------------------------------------------------
// Pure utilities (no app state, no statics).
// ---------------------------------------------------------------------------

/// Round a double to [precision] decimal places. Carries forward the
/// floating-point workaround from
/// `admin-portal/lib/utils/formatting.dart:22-38` — e.g. `35 * 1.107` ends up
/// `38.745000000000001` and naïve rounding produces `38.74` instead of
/// `38.75`. Money in this codebase is `Decimal` so this helper is for
/// non-money use (percentages, ratios) only.
double round(double? value, int precision) {
  if (value == null || value.isNaN) return 0;
  final fac = pow(10, precision) as int;
  var result = value * fac;
  if ('$result'.contains('999999')) result += 0.000001;
  return result.round() / fac;
}

/// Parse a messy user-input string to `int`. Strips every non-digit and
/// non-sign character before parsing. Returns `null` when the input parses
/// to zero and [zeroIsNull] is set.
int? parseInt(String? value, {bool zeroIsNull = false}) {
  if (value == null) return zeroIsNull ? null : 0;
  final stripped = value.replaceAll(RegExp(r'[^0-9\-]'), '');
  final n = int.tryParse(stripped) ?? 0;
  return (n == 0 && zeroIsNull) ? null : n;
}

/// Parse a messy user-input string to `Decimal`. Handles thousand separators
/// and the "comma as decimal place" company setting (`1.234,56` → `1234.56`).
Decimal? parseDecimal(
  String? value, {
  bool zeroIsNull = false,
  bool useCommaAsDecimalPlace = false,
}) {
  if (value == null) return zeroIsNull ? null : Decimal.zero;
  var v = value;
  if (useCommaAsDecimalPlace && v.contains(',')) {
    v = v.replaceAll('.', '').replaceAll(',', '.');
  }
  v = v.replaceAll(RegExp(r'[^0-9\.\-]'), '');
  final n = Decimal.tryParse(v) ?? Decimal.zero;
  return (n == Decimal.zero && zeroIsNull) ? null : n;
}

/// Renders a `Decimal` for an editable input field: empty string for zero,
/// otherwise `.toString()`. Use this — not `.toString()` directly — when
/// seeding a `TextField`/`EntityEditField` from a non-nullable `Decimal`, so
/// blank/new forms don't display a stray `0` the user has to clear.
String decimalInputText(Decimal value) =>
    value == Decimal.zero ? '' : value.toString();

/// Same as [parseDecimal] but returns `double`. Used for non-money inputs
/// (tax rates, exchange rates) where `Decimal` is overkill.
double? parseDouble(
  String? value, {
  bool zeroIsNull = false,
  bool useCommaAsDecimalPlace = false,
}) {
  if (value == null) return zeroIsNull ? null : 0.0;
  var v = value;
  if (useCommaAsDecimalPlace && v.contains(',')) {
    v = v.replaceAll('.', '').replaceAll(',', '.');
  }
  v = v.replaceAll(RegExp(r'[^0-9\.\-]'), '');
  final n = double.tryParse(v) ?? 0.0;
  return (n == 0 && zeroIsNull) ? null : n;
}

/// Human-readable file size. Matches `admin-portal:74-78` — KB / MB only,
/// rounded to one decimal, then int-truncated.
String formatSize(int size) => size > 1000000
    ? '${round(size / 1000000, 1).toInt()} MB'
    : '${round(size / 1000, 0).toInt()} KB';

/// Strip every non-digit from a phone number for tel: / sms: URIs.
String cleanPhoneNumber(String phoneNumber) =>
    phoneNumber.replaceAll(RegExp(r'\D'), '');

/// Self-hosted users paste a base URL; this canonicalises it by stripping
/// trailing slashes and any pre-existing `/api/v1` suffix.
String cleanApiUrl(String? url) => (url ?? '')
    .trim()
    .replaceFirst(RegExp(r'/api/v1'), '')
    .replaceFirst(RegExp(r'/$'), '');

/// Build the full API base URL.
String formatApiUrl(String? url) {
  final clean = cleanApiUrl(url);
  return clean.isEmpty ? '' : '$clean/api/v1';
}

String convertDateTimeToSqlDate([DateTime? date]) =>
    (date ?? DateTime.now()).toIso8601String().split('T').first;

DateTime convertSqlDateToDateTime([String? date]) {
  final parts = (date ?? convertDateTimeToSqlDate()).split('-');
  // `parseInt` strips non-digit suffixes — admin-portal callers sometimes
  // feed timestamps like `'2024-05-11T15:42:00Z'` into this function, and
  // `int.parse` would throw on `parts[2]` whereas `parseInt` coerces.
  return DateTime.utc(
    parseInt(parts[0])!,
    parseInt(parts[1])!,
    parseInt(parts[2])!,
  );
}

DateTime convertTimestampToDate(int? timestamp) =>
    DateTime.fromMillisecondsSinceEpoch((timestamp ?? 0) * 1000, isUtc: true);

String convertTimestampToDateString(int? timestamp) => (timestamp ?? 0) == 0
    ? ''
    : convertTimestampToDate(timestamp).toIso8601String();

DateTime convertTimeOfDayToDateTime(
  TimeOfDay? timeOfDay, [
  DateTime? dateTime,
]) {
  final base = dateTime ?? DateTime.now();
  return DateTime(
    base.year,
    base.month,
    base.day,
    timeOfDay?.hour ?? 0,
    timeOfDay?.minute ?? 0,
  ).toUtc();
}

TimeOfDay convertDateTimeToTimeOfDay(DateTime? dateTime) =>
    TimeOfDay(hour: dateTime?.hour ?? 0, minute: dateTime?.minute ?? 0);

/// `0:13:42` style formatter for a [Duration]. Matches old behaviour.
String formatDuration(Duration? duration, {bool showSeconds = true}) {
  final time = (duration ?? Duration.zero).toString().split('.').first;
  if (showSeconds) return time;
  final parts = time.split(':');
  return '${parts[0]}:${parts[1]}';
}

// ---------------------------------------------------------------------------
// Address.
// ---------------------------------------------------------------------------

/// Address bag passed to [Formatter.address]. Either billing or shipping —
/// the caller picks which set of fields belongs here.
class Address {
  const Address({
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.countryId = '',
  });

  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postalCode;
  final String countryId;
}

// ---------------------------------------------------------------------------
// Formatter — bound to one company's settings + the cached statics maps.
// ---------------------------------------------------------------------------

/// Default ID for Euro in the Invoice Ninja statics bundle — used by
/// [Formatter.money] to apply the country-driven separator override that
/// admin-portal documents at `formatting.dart:160-169`.
const String _kCurrencyEuro = '3';

/// "All currencies" sentinel used in admin-portal filters; the formatter
/// treats it as "use company default" (`formatting.dart:122-123`).
const String kCurrencyAll = '-1';

class Formatter {
  Formatter({
    required this.settings,
    required this.currencies,
    required this.countries,
    required this.dateFormats,
  });

  final CompanyFormatSettings settings;
  final Map<String, Currency> currencies;
  final Map<String, Country> countries;
  final Map<String, DatetimeFormat> dateFormats;

  // -------------------------------------------------------------------------
  // Currency / country resolution.
  // -------------------------------------------------------------------------

  /// Resolve which currency to format with. Mirrors the cascade at
  /// `admin-portal/lib/utils/formatting.dart:122-134`: explicit override →
  /// client → vendor → group → company default.
  String _resolveCurrencyId({
    String? currencyId,
    String? clientCurrencyId,
    String? vendorCurrencyId,
    String? groupCurrencyId,
  }) {
    if (currencyId == kCurrencyAll) return settings.currencyId;
    if (currencyId != null && currencyId.isNotEmpty) return currencyId;
    if (clientCurrencyId != null && clientCurrencyId.isNotEmpty) {
      return clientCurrencyId;
    }
    if (vendorCurrencyId != null && vendorCurrencyId.isNotEmpty) {
      return vendorCurrencyId;
    }
    if (groupCurrencyId != null && groupCurrencyId.isNotEmpty) {
      return groupCurrencyId;
    }
    return settings.currencyId;
  }

  String _resolveCountryId({String? clientCountryId, String? vendorCountryId}) {
    if (clientCountryId != null && clientCountryId.isNotEmpty) {
      return clientCountryId;
    }
    if (vendorCountryId != null && vendorCountryId.isNotEmpty) {
      return vendorCountryId;
    }
    return settings.countryId;
  }

  // -------------------------------------------------------------------------
  // Money / numbers.
  // -------------------------------------------------------------------------

  /// Format a money amount. Returns `''` for null, and also for zero when
  /// [zeroIsNull] is set. Pass [clientCurrencyId] / [vendorCurrencyId] /
  /// [groupCurrencyId] to honour per-entity currency overrides.
  ///
  /// When [compact] is true, render the magnitude with a SI-style suffix
  /// (`12.3K`, `4.5M`) — used by the dashboard chart axis. The currency
  /// symbol / code prefix or suffix follows the same rules as the normal
  /// form. Compact display ignores [roundToPrecision].
  String money(
    Decimal? amount, {
    String? currencyId,
    String? clientCurrencyId,
    String? vendorCurrencyId,
    String? groupCurrencyId,
    String? clientCountryId,
    String? vendorCountryId,
    bool? showCurrencyCode,
    bool roundToPrecision = true,
    bool zeroIsNull = false,
    bool compact = false,
  }) {
    if (amount == null) return '';
    if (zeroIsNull && amount == Decimal.zero) return '';

    final resolvedCurrencyId = _resolveCurrencyId(
      currencyId: currencyId,
      clientCurrencyId: clientCurrencyId,
      vendorCurrencyId: vendorCurrencyId,
      groupCurrencyId: groupCurrencyId,
    );
    final currency = currencies[resolvedCurrencyId];
    if (currency == null) return '';

    final country =
        countries[_resolveCountryId(
          clientCountryId: clientCountryId,
          vendorCountryId: vendorCountryId,
        )];

    final (thousandSep, decimalSep, swap) = _separators(
      currency: currency,
      companyCurrency: currencies[settings.currencyId],
      country: country,
    );

    String body;
    String prefixSign;
    if (compact) {
      final (compactBody, compactSign) = _formatCompact(
        amount,
        decimal: decimalSep,
      );
      body = compactBody;
      prefixSign = compactSign;
    } else {
      final rounded = roundToPrecision
          ? Decimal.parse(amount.toStringAsFixed(currency.precision))
          : amount;
      // Trail up to 3 decimals beyond `precision` when we aren't rounding, to
      // preserve any extra precision in the input. Matches the old patterns
      // `#,##0.00###` etc.
      final maxDecimals = roundToPrecision
          ? currency.precision
          : currency.precision + 3;
      body = _formatGrouped(
        rounded.abs().toDouble(),
        minDecimals: currency.precision,
        maxDecimals: maxDecimals,
        thousand: thousandSep,
        decimal: decimalSep,
      );
      prefixSign = _signPrefix(rounded, body);
    }

    final showCode = showCurrencyCode ?? settings.showCurrencyCode;
    if (showCode || currency.symbol.isEmpty) {
      return '$prefixSign$body ${currency.code}';
    }
    if (swap) {
      return '$prefixSign$body ${currency.symbol.trim()}';
    }
    return '$prefixSign${currency.symbol}$body';
  }

  /// Compact body: `12.3K`, `4.5M`, `1.2B`. Returns `(body, signPrefix)`.
  /// Decimal separator is honored so European locales render `12,3K`.
  ///
  /// Implemented locally rather than via `NumberFormat.compactCurrency` so we
  /// keep the per-currency separator + swap-symbol cascade that `money`
  /// already resolves above.
  (String, String) _formatCompact(Decimal amount, {required String decimal}) {
    final value = amount.toDouble();
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    String body;
    if (abs < 1000) {
      body = abs.toStringAsFixed(0);
    } else if (abs < 1000000) {
      body = '${(abs / 1000).toStringAsFixed(1).replaceFirst('.', decimal)}K';
    } else if (abs < 1000000000) {
      body =
          '${(abs / 1000000).toStringAsFixed(1).replaceFirst('.', decimal)}M';
    } else {
      body =
          '${(abs / 1000000000).toStringAsFixed(1).replaceFirst('.', decimal)}B';
    }
    // Strip trailing `.0` / `,0` for round magnitudes (`1.0K` → `1K`).
    if (body.length > 3 &&
        body.substring(body.length - 3, body.length - 1) == '${decimal}0') {
      body = '${body.substring(0, body.length - 3)}${body[body.length - 1]}';
    }
    // Don't prefix `-` if the rounded body collapsed to zero.
    final showSign = sign == '-' && !_isZeroString(body);
    return (body, showSign ? '-' : '');
  }

  /// Format a percentage value (the value is the percentage itself — pass
  /// `15.5` for "15.5%"). Always grouped, up to 5 fractional digits.
  String percent(num? value, {bool zeroIsNull = false}) {
    if (value == null) return '';
    if (zeroIsNull && value == 0) return '';
    final (thousand, decimal, _) = _separators(
      currency: currencies[settings.currencyId],
      companyCurrency: currencies[settings.currencyId],
      country: countries[settings.countryId],
    );
    final body = _formatGrouped(
      value.abs().toDouble(),
      minDecimals: 0,
      maxDecimals: 5,
      thousand: thousand,
      decimal: decimal,
    );
    final prefix = value < 0 && !_isZeroString(body) ? '-' : '';
    return '$prefix$body%';
  }

  /// Integer with thousand separators (e.g. `1,234`).
  String integer(num value) {
    final (thousand, decimal, _) = _separators(
      currency: currencies[settings.currencyId],
      companyCurrency: currencies[settings.currencyId],
      country: countries[settings.countryId],
    );
    final body = _formatGrouped(
      value.abs().toDouble(),
      minDecimals: 0,
      maxDecimals: 0,
      thousand: thousand,
      decimal: decimal,
    );
    final prefix = value < 0 && !_isZeroString(body) ? '-' : '';
    return '$prefix$body';
  }

  /// Decimal number with thousand separators, no fixed precision (up to 5).
  String decimal(num value) {
    final (thousand, decimal, _) = _separators(
      currency: currencies[settings.currencyId],
      companyCurrency: currencies[settings.currencyId],
      country: countries[settings.countryId],
    );
    final body = _formatGrouped(
      value.abs().toDouble(),
      minDecimals: 0,
      maxDecimals: 5,
      thousand: thousand,
      decimal: decimal,
    );
    final prefix = value < 0 && !_isZeroString(body) ? '-' : '';
    return '$prefix$body';
  }

  /// Money formatted for an `<input>` field — no thousand separator, decimal
  /// separator follows the company's `use_comma_as_decimal_place` flag, and
  /// zero renders as `''`.
  String inputMoney(Decimal? value, {String? currencyId}) {
    if (value == null || value == Decimal.zero) return '';
    final resolved = _resolveCurrencyId(currencyId: currencyId);
    final currency = currencies[resolved] ?? currencies[settings.currencyId];
    final precision = currency?.precision ?? 2;
    final decimalSep = settings.useCommaAsDecimalPlace ? ',' : '.';
    final body = _formatGrouped(
      value.abs().toDouble(),
      minDecimals: precision,
      maxDecimals: precision,
      thousand: '',
      decimal: decimalSep,
    );
    final prefix = value < Decimal.zero && !_isZeroString(body) ? '-' : '';
    return '$prefix$body';
  }

  /// Generic numeric input — no thousand separator, no forced precision.
  String inputAmount(num? value) {
    if (value == null || value == 0) return '';
    final decimalSep = settings.useCommaAsDecimalPlace ? ',' : '.';
    final body = _formatGrouped(
      value.abs().toDouble(),
      minDecimals: 0,
      maxDecimals: 5,
      thousand: '',
      decimal: decimalSep,
    );
    final prefix = value < 0 && !_isZeroString(body) ? '-' : '';
    return '$prefix$body';
  }

  // -------------------------------------------------------------------------
  // Dates.
  // -------------------------------------------------------------------------

  /// Format an ISO date(time) string. Pattern is whichever the company's
  /// `date_format_id` resolves to in the statics bundle; falls back to
  /// `yyyy-MM-dd` if missing. Mirrors `admin-portal:421-470`, including the
  /// "double period" fix on line 469.
  String date(
    String? value, {
    bool showDate = true,
    bool showTime = false,
    bool showSeconds = true,
  }) {
    if (value == null || value.isEmpty) return '';

    final timeFormat = showSeconds
        ? (settings.enableMilitaryTime ? 'H:mm:ss' : 'h:mm:ss a')
        : (settings.enableMilitaryTime ? 'H:mm' : 'h:mm a');

    final datePattern = dateFormats[settings.dateFormatId]?.format;

    String? pattern;
    DateTime? parsed;
    if (showTime) {
      pattern = showDate
          ? '${datePattern ?? 'yyyy-MM-dd'} $timeFormat'
          : timeFormat;
      // Time values are server UTC; suffix `Z` if missing so DateTime.parse
      // doesn't treat them as local.
      parsed = DateTime.tryParse(
        value.endsWith('Z') ? value : '${value}Z',
      )?.toLocal();
    } else {
      pattern = datePattern ?? 'yyyy-MM-dd';
      parsed = DateTime.tryParse(value);
    }
    if (parsed == null) return '';

    final formatted = DateFormat(
      pattern,
      settings.locale.isEmpty ? null : settings.locale,
    ).format(parsed);
    // Foreign-language month abbreviations can produce `..` — see
    // admin-portal #527 / formatting.dart:469.
    return formatted.replaceFirst('..', '.');
  }

  /// `MMM d - MMM d, yyyy` range, year suppressed for the current year.
  String dateRange(String startIso, String endIso) {
    final start = DateTime.tryParse(startIso)?.toLocal();
    final end = DateTime.tryParse(endIso)?.toLocal();
    if (start == null || end == null) return '';
    final today = DateTime.now();
    final startPattern = today.year == start.year ? 'MMM d' : 'MMM d, yyyy';
    final endPattern = today.year == end.year ? 'MMM d' : 'MMM d, yyyy';
    final locale = settings.locale.isEmpty ? null : settings.locale;
    final s = DateFormat(startPattern, locale).format(start);
    final e = DateFormat(endPattern, locale).format(end);
    return '$s - $e';
  }

  /// Parse a user-entered date string using the company's date pattern,
  /// returning an ISO `yyyy-MM-dd` for storage. Returns `''` on bad input.
  String parseDate(String value) {
    if (value.isEmpty) return '';
    final pattern = dateFormats[settings.dateFormatId]?.format ?? 'yyyy-MM-dd';
    try {
      return convertDateTimeToSqlDate(
        DateFormat(
          pattern,
          settings.locale.isEmpty ? null : settings.locale,
        ).parse(value),
      );
    } catch (_) {
      return '';
    }
  }

  /// Parse a user-entered time string using the company's military-time
  /// preference. Pinned to `2000-01-01` so callers get just a time of day.
  DateTime? parseTime(String value) {
    if (value.isEmpty) return null;
    final showSeconds = ':'.allMatches(value).length >= 2;
    final fmt = showSeconds
        ? (settings.enableMilitaryTime ? 'H:mm:ss' : 'h:mm:ss a')
        : (settings.enableMilitaryTime ? 'H:mm' : 'h:mm a');
    try {
      return DateFormat(
        'y-M-d $fmt',
        settings.locale.isEmpty ? null : settings.locale,
      ).parse('2000-01-01 $value');
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Address.
  // -------------------------------------------------------------------------

  /// Render a postal address. The country line is suppressed when it matches
  /// the company's default country (matches the old code at
  /// `formatting.dart:306-313`).
  String address(Address addr, {String delimiter = '\n'}) {
    final buf = StringBuffer();
    if (addr.address1.isNotEmpty) buf.write('${addr.address1}$delimiter');
    if (addr.address2.isNotEmpty) buf.write('${addr.address2}$delimiter');
    if (addr.city.isNotEmpty) buf.write('${addr.city}, ');
    if (addr.state.isNotEmpty) buf.write('${addr.state} ');
    if (addr.postalCode.isNotEmpty) buf.write(addr.postalCode);
    if (addr.countryId.isNotEmpty && addr.countryId != settings.countryId) {
      if (buf.isNotEmpty) buf.write(delimiter);
      buf.write(countries[addr.countryId]?.name ?? '');
    }
    return buf.toString();
  }

  /// Format a custom-field value. Type is one of `switch`, `date`, or
  /// anything else (returned as-is). Caller supplies `yes`/`no` strings
  /// already localised — this file doesn't depend on l10n.
  String? customValue({
    String? value,
    String? fieldType,
    required String yes,
    required String no,
  }) {
    switch (fieldType) {
      case 'switch':
        return value == 'yes' ? yes : no;
      case 'date':
        return date(value);
      default:
        return value;
    }
  }

  // -------------------------------------------------------------------------
  // Internals.
  // -------------------------------------------------------------------------

  /// Pick thousand / decimal separators and the swap-symbol flag for the
  /// *display* currency. Mirrors `admin-portal/lib/utils/formatting.dart:156-169`:
  ///
  /// - Thousand / decimal separators come from the display currency itself.
  /// - The initial `swap` flag comes from the *company's* default currency
  ///   (not the display currency). Admin-portal does this deliberately so a
  ///   foreign-currency display inherits the company's symbol-placement
  ///   convention.
  /// - For EUR specifically, the country's `swap_currency_symbol` /
  ///   separators override (EUR in Germany formats `1.234,56`; in Ireland
  ///   `1,234.56`).
  (String thousand, String decimal, bool swap) _separators({
    Currency? currency,
    Currency? companyCurrency,
    Country? country,
  }) {
    if (currency == null) return ('', '.', false);
    var thousand = currency.thousandSeparator;
    var decimal = currency.decimalSeparator;
    var swap =
        companyCurrency?.swapCurrencySymbol ?? currency.swapCurrencySymbol;
    if (currency.id == _kCurrencyEuro && country != null) {
      swap = country.swapCurrencySymbol;
      if (country.thousandSeparator.isNotEmpty) {
        thousand = country.thousandSeparator;
      }
      if (country.decimalSeparator.isNotEmpty) {
        decimal = country.decimalSeparator;
      }
    }
    return (thousand, decimal, swap);
  }

  String _signPrefix(Decimal rounded, String body) {
    if (rounded >= Decimal.zero) return '';
    // Prevent `-0.00` style display when rounding produced zero.
    if (_isZeroString(body)) return '';
    return '-';
  }
}

/// Group [value] with [thousand] every three digits and write [decimal]
/// before the fractional part. Always renders the absolute value — callers
/// add the sign themselves. [minDecimals] forces trailing zeros up to that
/// count; [maxDecimals] caps any extra precision.
String _formatGrouped(
  double value, {
  required int minDecimals,
  required int maxDecimals,
  required String thousand,
  required String decimal,
}) {
  final decimals = max(minDecimals, maxDecimals);
  final fixed = value.toStringAsFixed(decimals);
  final dot = fixed.indexOf('.');
  final intPart = dot < 0 ? fixed : fixed.substring(0, dot);
  var fracPart = dot < 0 ? '' : fixed.substring(dot + 1);
  while (fracPart.length > minDecimals && fracPart.endsWith('0')) {
    fracPart = fracPart.substring(0, fracPart.length - 1);
  }

  final buf = StringBuffer();
  final len = intPart.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(thousand);
    buf.write(intPart[i]);
  }
  if (fracPart.isNotEmpty) {
    buf.write(decimal);
    buf.write(fracPart);
  }
  return buf.toString();
}

/// True if [s] contains only `0`, `.`, or `,` — i.e. its numeric value is
/// zero. Used to suppress `-0.00` displays after rounding.
bool _isZeroString(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c != '0' && c != '.' && c != ',') return false;
  }
  return true;
}
