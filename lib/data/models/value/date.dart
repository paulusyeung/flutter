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
  static Date? tryParse(String? input) {
    if (input == null || input.isEmpty) return null;
    final parts = input.split('-');
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
