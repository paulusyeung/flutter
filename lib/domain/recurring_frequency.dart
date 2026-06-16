import 'package:admin/data/models/value/date.dart';

/// Recurring schedule frequency ids. Mirrors admin-portal
/// `constants.dart:1234-1247` (`kFrequencies`). Stored on the server as
/// a string in `frequency_id`.
const String kRecurringFrequencyDaily = '1';
const String kRecurringFrequencyWeekly = '2';
const String kRecurringFrequencyTwoWeeks = '3';
const String kRecurringFrequencyFourWeeks = '4';
const String kRecurringFrequencyMonthly = '5';
const String kRecurringFrequencyTwoMonths = '6';
const String kRecurringFrequencyThreeMonths = '7';
const String kRecurringFrequencyFourMonths = '8';
const String kRecurringFrequencySixMonths = '9';
const String kRecurringFrequencyAnnually = '10';
const String kRecurringFrequencyTwoYears = '11';
const String kRecurringFrequencyThreeYears = '12';

/// Localization keys for each frequency — `context.tr(kRecurringFrequencyLabelKey[id]!)`.
const Map<String, String> kRecurringFrequencyLabelKey = <String, String>{
  kRecurringFrequencyDaily: 'freq_daily',
  kRecurringFrequencyWeekly: 'freq_weekly',
  kRecurringFrequencyTwoWeeks: 'freq_two_weeks',
  kRecurringFrequencyFourWeeks: 'freq_four_weeks',
  kRecurringFrequencyMonthly: 'freq_monthly',
  kRecurringFrequencyTwoMonths: 'freq_two_months',
  kRecurringFrequencyThreeMonths: 'freq_three_months',
  kRecurringFrequencyFourMonths: 'freq_four_months',
  kRecurringFrequencySixMonths: 'freq_six_months',
  kRecurringFrequencyAnnually: 'freq_annually',
  kRecurringFrequencyTwoYears: 'freq_two_years',
  kRecurringFrequencyThreeYears: 'freq_three_years',
};

/// Convenient ordered list (matches the dropdown order users expect).
const List<String> kRecurringFrequencyOrdered = <String>[
  kRecurringFrequencyDaily,
  kRecurringFrequencyWeekly,
  kRecurringFrequencyTwoWeeks,
  kRecurringFrequencyFourWeeks,
  kRecurringFrequencyMonthly,
  kRecurringFrequencyTwoMonths,
  kRecurringFrequencyThreeMonths,
  kRecurringFrequencyFourMonths,
  kRecurringFrequencySixMonths,
  kRecurringFrequencyAnnually,
  kRecurringFrequencyTwoYears,
  kRecurringFrequencyThreeYears,
];

/// Compute the n-th send date for the UX preview chip on the edit screen.
///
/// Returns the date `n` recurrences after [start] for the given
/// [frequencyId]. Uses `DateTime` math; falls back to a single-day step
/// when the id is unknown so the UI degrades gracefully.
Date? nextSendAfter(Date start, String frequencyId, int n) {
  if (n < 0) return null;
  if (n == 0) return start;
  final dt = start.toDateTime();
  DateTime next;
  switch (frequencyId) {
    // Day-multiple steps use Date.addDays (UTC date-space) — local-midnight +
    // Duration(days:) lands at 23:00 of the prior day across a fall-back DST
    // transition, so the preview chip showed a send date one day early (L2).
    case kRecurringFrequencyDaily:
      next = start.addDays(n).toDateTime();
    case kRecurringFrequencyWeekly:
      next = start.addDays(7 * n).toDateTime();
    case kRecurringFrequencyTwoWeeks:
      next = start.addDays(14 * n).toDateTime();
    case kRecurringFrequencyFourWeeks:
      next = start.addDays(28 * n).toDateTime();
    case kRecurringFrequencyMonthly:
      next = _addMonths(dt, n);
    case kRecurringFrequencyTwoMonths:
      next = _addMonths(dt, 2 * n);
    case kRecurringFrequencyThreeMonths:
      next = _addMonths(dt, 3 * n);
    case kRecurringFrequencyFourMonths:
      next = _addMonths(dt, 4 * n);
    case kRecurringFrequencySixMonths:
      next = _addMonths(dt, 6 * n);
    case kRecurringFrequencyAnnually:
      next = _addMonths(dt, 12 * n);
    case kRecurringFrequencyTwoYears:
      next = _addMonths(dt, 24 * n);
    case kRecurringFrequencyThreeYears:
      next = _addMonths(dt, 36 * n);
    default:
      return null;
  }
  return Date(next.year, next.month, next.day);
}

/// Add [months] to [dt], clamping to the last valid day of the target
/// month. e.g. Jan 31 + 1 month → Feb 28/29 (avoids the DateTime
/// "rolls forward to March" surprise).
DateTime _addMonths(DateTime dt, int months) {
  final totalMonths = dt.month - 1 + months;
  final newYear = dt.year + (totalMonths ~/ 12);
  final newMonth = (totalMonths % 12) + 1;
  // Last day of the new month — use the Day 0 of next-month trick.
  final lastDay = DateTime(newYear, newMonth + 1, 0).day;
  final clampedDay = dt.day > lastDay ? lastDay : dt.day;
  return DateTime(newYear, newMonth, clampedDay);
}
