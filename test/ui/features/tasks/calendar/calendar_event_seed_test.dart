import 'package:admin/data/models/api/calendar_connection_api_model.dart';
import 'package:admin/ui/features/tasks/widgets/calendar/calendar_event_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seedTimeLogForEvent', () {
    test('timed event preserves the event duration', () {
      const e = CalendarEvent(
        start: '2026-06-14T09:00:00Z',
        end: '2026-06-14T10:30:00Z',
      );
      final entry = seedTimeLogForEvent(e).single;
      // start/stop render in local time, but their delta is tz-independent.
      expect(entry.stop!.difference(entry.start!), const Duration(minutes: 90));
      expect(entry.billable, isTrue);
    });

    test('zero-length timed event pads to 1h', () {
      const e = CalendarEvent(
        start: '2026-06-14T09:00:00Z',
        end: '2026-06-14T09:00:00Z',
      );
      final entry = seedTimeLogForEvent(e).single;
      expect(entry.stop!.difference(entry.start!), const Duration(hours: 1));
    });

    test('all-day event anchors a 1h block at 09:00 local on its date', () {
      const e = CalendarEvent(
        allDay: true,
        start: '2026-06-14',
        end: '2026-06-15',
      );
      final entry = seedTimeLogForEvent(e).single;
      expect(entry.start, DateTime(2026, 6, 14, 9));
      expect(entry.stop!.difference(entry.start!), const Duration(hours: 1));
    });
  });

  group('seedDescriptionForEvent', () {
    test('title only', () {
      expect(
        seedDescriptionForEvent(const CalendarEvent(title: 'Standup')),
        'Standup',
      );
    });

    test('title + body joined by a blank line', () {
      expect(
        seedDescriptionForEvent(
          const CalendarEvent(title: 'Standup', description: 'Daily sync'),
        ),
        'Standup\n\nDaily sync',
      );
    });
  });

  group('CalendarEvent helpers', () {
    test('all-day dayKey/startLocal use the floating date (no tz shift)', () {
      const e = CalendarEvent(allDay: true, start: '2026-06-14');
      expect(e.dayKey, '2026-06-14');
      expect(e.startLocal, DateTime(2026, 6, 14));
    });

    test('timed dayKey agrees with the local start date', () {
      const e = CalendarEvent(start: '2026-06-14T12:00:00Z');
      final local = e.startLocal!;
      final expected =
          '${local.year.toString().padLeft(4, '0')}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
      expect(e.dayKey, expected);
    });

    test('isCancelled reflects the status', () {
      expect(const CalendarEvent(status: 'cancelled').isCancelled, isTrue);
      expect(const CalendarEvent(status: 'confirmed').isCancelled, isFalse);
    });
  });
}
