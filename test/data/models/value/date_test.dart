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

  // The Batch-5 DST fixes (dashboard previous-period, schedule "next run",
  // recurring send-date preview, payment-schedule default, project days-
  // remaining) all route their day math through these helpers instead of
  // local-midnight + Duration(days:) / .inDays, which drifts a calendar day
  // across a DST transition. These guard the UTC date-space contract.
  group('addDays / differenceInDays (UTC date-space, DST-safe)', () {
    test('addDays steps exact calendar days across DST boundaries', () {
      // US fall-back: Nov 1 2026. +7 from Oct 25 must land on Nov 1.
      expect(const Date(2026, 10, 25).addDays(7), const Date(2026, 11, 1));
      // US spring-forward: Mar 8 2026.
      expect(const Date(2026, 3, 7).addDays(1), const Date(2026, 3, 8));
      // Backwards across the same boundary.
      expect(const Date(2026, 11, 1).addDays(-7), const Date(2026, 10, 25));
    });

    test('differenceInDays counts exact calendar days across DST', () {
      expect(
        const Date(2026, 11, 1).differenceInDays(const Date(2026, 10, 25)),
        7,
      );
      expect(
        const Date(2026, 3, 8).differenceInDays(const Date(2026, 3, 7)),
        1,
      );
      expect(
        const Date(2026, 10, 25).differenceInDays(const Date(2026, 11, 1)),
        -7,
      );
    });
  });
}
