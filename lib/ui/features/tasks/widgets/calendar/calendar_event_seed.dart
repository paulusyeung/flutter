import 'package:admin/data/models/api/calendar_connection_api_model.dart';
import 'package:admin/data/models/domain/time_entry.dart';

/// Pure seed helpers for converting a calendar event into a task. Kept UI-free
/// (no `emptyTask`/widget imports) so the conversion rules are unit-testable in
/// isolation. The widget assembles the full [Task] from these + the dedupe meta.

/// The single [TimeEntry] a converted event seeds. Mirrors React's
/// `buildTimeLog`:
/// - all-day events have no clock time → anchor a 1h block at 09:00 local on
///   the event's date;
/// - a degenerate/zero-length timed event (end ≤ start) is padded to 1h from
///   its start;
/// - otherwise the event's start..end.
List<TimeEntry> seedTimeLogForEvent(CalendarEvent event) {
  if (event.allDay) {
    final d = event.startLocal ?? DateTime.now();
    final start = DateTime(d.year, d.month, d.day, 9);
    return [
      TimeEntry(
        start: start,
        stop: start.add(const Duration(hours: 1)),
        billable: true,
      ),
    ];
  }
  final start = event.startLocal ?? DateTime.now();
  var end = event.endLocal;
  if (end == null || !end.isAfter(start)) {
    end = start.add(const Duration(hours: 1));
  }
  return [TimeEntry(start: start, stop: end, billable: true)];
}

/// Description for a converted task: the event title, then its body when
/// present, blank-trimmed.
String seedDescriptionForEvent(CalendarEvent event) => [
  event.title,
  event.description,
].where((s) => s.trim().isNotEmpty).join('\n\n');
