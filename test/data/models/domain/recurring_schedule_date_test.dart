import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/recurring_schedule_date.dart';

/// `RecurringScheduleDate` parses the server's `recurring_dates` rows
/// (`GET /recurring_invoices/{id}?show_dates=true`). The schedule tab renders
/// these read-only; the parse must tolerate missing/blank fields.
void main() {
  group('RecurringScheduleDate.fromJson', () {
    test('parses send_date + due_date', () {
      final r = RecurringScheduleDate.fromJson(const {
        'send_date': '2026-06-15',
        'due_date': '2026-06-22',
      });
      expect(r.sendDate?.toIso(), '2026-06-15');
      expect(r.dueDate?.toIso(), '2026-06-22');
    });

    test('missing keys → null dates (no throw)', () {
      final r = RecurringScheduleDate.fromJson(const {});
      expect(r.sendDate, isNull);
      expect(r.dueDate, isNull);
    });

    test('blank strings → null dates', () {
      final r = RecurringScheduleDate.fromJson(const {
        'send_date': '',
        'due_date': '',
      });
      expect(r.sendDate, isNull);
      expect(r.dueDate, isNull);
    });

    test('a send date without a due date is preserved', () {
      final r = RecurringScheduleDate.fromJson(const {
        'send_date': '2026-07-01',
      });
      expect(r.sendDate?.toIso(), '2026-07-01');
      expect(r.dueDate, isNull);
    });
  });
}
