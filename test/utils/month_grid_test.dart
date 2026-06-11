import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/value/date.dart';
import 'package:admin/utils/date_ranges.dart';

void main() {
  group('startOfMonthGrid / monthGridDays', () {
    // June 1, 2026 is a Monday.
    test('Sunday-start grid spills into the previous month', () {
      expect(startOfMonthGrid(Date(2026, 6, 15), 0), Date(2026, 5, 31));
    });

    test('Monday-start grid begins on the 1st when the 1st is a Monday', () {
      expect(startOfMonthGrid(Date(2026, 6, 30), 1), Date(2026, 6, 1));
    });

    test('monthGridDays returns 42 contiguous days from the grid start', () {
      final days = monthGridDays(Date(2026, 6, 1), 0);
      expect(days.length, 42);
      expect(days.first, startOfMonthGrid(Date(2026, 6, 1), 0));
      for (var i = 1; i < days.length; i++) {
        expect(days[i], days[i - 1].addDays(1));
      }
      // Spans the whole month.
      expect(days, contains(Date(2026, 6, 1)));
      expect(days, contains(Date(2026, 6, 30)));
    });
  });
}
