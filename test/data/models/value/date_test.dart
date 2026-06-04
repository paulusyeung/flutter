import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/value/date.dart';

void main() {
  group('Date.tryParse', () {
    test('parses a plain YYYY-MM-DD', () {
      expect(Date.tryParse('2026-07-04'), const Date(2026, 7, 4));
    });

    test('parses a space-separated datetime (server next_send_date shape)', () {
      // Recurring invoices' next_send_date / last_sent_date come back as a
      // full timestamp — the date must still parse (time discarded).
      expect(Date.tryParse('2026-07-04 04:00:17'), const Date(2026, 7, 4));
      expect(Date.tryParse('2026-05-04 04:00:17'), const Date(2026, 5, 4));
    });

    test('parses a T-separated ISO datetime', () {
      expect(Date.tryParse('2026-07-04T17:00:00'), const Date(2026, 7, 4));
    });

    test('returns null for empty or null', () {
      expect(Date.tryParse(''), isNull);
      expect(Date.tryParse(null), isNull);
    });

    test('returns null for malformed input', () {
      expect(Date.tryParse('not-a-date'), isNull);
      expect(Date.tryParse('2026/07/04'), isNull);
      expect(Date.tryParse('2026-07'), isNull);
    });
  });
}
