/// A timezone-free, time-free calendar date (year/month/day).
///
/// Invoice Ninja's API uses `YYYY-MM-DD` strings for fields like `invoice_date`,
/// `due_date`, and `date`. Decoding these as `DateTime` smuggles in a time and
/// a timezone, which causes off-by-one bugs as soon as values cross zones.
/// [Date] is deliberately minimal so equality, formatting, and storage all
/// stay obvious.
class Date implements Comparable<Date> {
  const Date(this.year, this.month, this.day);

  /// Parse `YYYY-MM-DD`. Empty or null inputs return null.
  ///
  /// Tolerates a trailing time component: some endpoints return date-only
  /// fields as a full timestamp (e.g. recurring invoices' `next_send_date` /
  /// `last_sent_date` come back as `2026-07-04 04:00:17`, space- or
  /// `T`-separated). The time is intentionally discarded — this type is
  /// deliberately time-free, so we take the calendar date verbatim and never
  /// timezone-convert.
  static Date? tryParse(String? input) {
    if (input == null || input.isEmpty) return null;
    final dateOnly = input.split(RegExp('[ T]')).first;
    final parts = dateOnly.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return Date(y, m, d);
  }

  /// Today in the device's local timezone.
  factory Date.today() {
    final now = DateTime.now();
    return Date(now.year, now.month, now.day);
  }

  final int year;
  final int month;
  final int day;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Lift this calendar date into a local-time [DateTime] at midnight.
  /// Use for cell renderers that expect a `DateTime` (e.g. `cellDate`);
  /// the local-zone choice is deliberate so the rendered day matches the
  /// user's wall-clock interpretation of the date.
  DateTime toDateTime() => DateTime(year, month, day);

  /// Whole calendar days from [other] to this date (`this - other`), mirroring
  /// `DateTime.difference(...).inDays`. Positive when this date is later than
  /// [other] — e.g. `Date.today().differenceInDays(dueDate)` is how many days
  /// an invoice is overdue.
  int differenceInDays(Date other) =>
      toDateTime().difference(other.toDateTime()).inDays;

  @override
  String toString() => toIso();

  @override
  int compareTo(Date other) {
    if (year != other.year) return year - other.year;
    if (month != other.month) return month - other.month;
    return day - other.day;
  }

  @override
  bool operator ==(Object other) =>
      other is Date &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
