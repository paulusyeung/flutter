import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/ui/features/tasks/widgets/weekly/weekly_merge.dart';

final _now = DateTime(2026, 6, 15, 12);

TimeEntry _e(
  DateTime start,
  DateTime? stop, {
  String desc = '',
  bool billable = true,
}) =>
    TimeEntry(start: start, stop: stop, description: desc, billable: billable);

void main() {
  group('durationStringToSeconds', () {
    test('empty → 0; decimal hours; h:mm; invalid → null', () {
      expect(durationStringToSeconds(''), 0);
      expect(durationStringToSeconds('1.5'), 5400);
      expect(durationStringToSeconds('1:30'), 5400);
      expect(durationStringToSeconds('abc'), isNull);
    });
  });

  group('applyCellEditToLogs', () {
    final day = Date(2026, 6, 10);

    test('collapses same-day entries into one of the new duration', () {
      final logs = [
        _e(DateTime(2026, 6, 10, 9), DateTime(2026, 6, 10, 10)),
        _e(DateTime(2026, 6, 10, 14), DateTime(2026, 6, 10, 15)),
        _e(DateTime(2026, 6, 11, 9), DateTime(2026, 6, 11, 10)), // other day
      ];
      final out = applyCellEditToLogs(
        logs,
        day,
        CellEdit(duration: '5'),
        _now,
      )!;
      final onDay = out.where((e) => e.start!.toLocal().day == 10).toList();
      expect(onDay.length, 1);
      expect(
        onDay.first.stop!.difference(onDay.first.start!),
        const Duration(hours: 5),
      );
      // Other-day entry untouched.
      expect(out.where((e) => e.start!.toLocal().day == 11).length, 1);
    });

    test('preserves the existing start clock time', () {
      final logs = [
        _e(DateTime(2026, 6, 10, 13, 30), DateTime(2026, 6, 10, 14, 30)),
      ];
      final out = applyCellEditToLogs(
        logs,
        day,
        CellEdit(billable: false),
        _now,
      )!;
      final e = out.single;
      expect(e.start!.toLocal().hour, 13);
      expect(e.start!.toLocal().minute, 30);
      expect(e.billable, isFalse);
    });

    test('a new cell uses a local 09:00 start', () {
      final out = applyCellEditToLogs(
        const [],
        day,
        CellEdit(duration: '2'),
        _now,
      )!;
      final e = out.single;
      expect(e.start!.toLocal().hour, 9);
      expect(e.stop!.difference(e.start!), const Duration(hours: 2));
    });

    test('zero duration + no description deletes the entry', () {
      final logs = [_e(DateTime(2026, 6, 10, 9), DateTime(2026, 6, 10, 10))];
      expect(
        applyCellEditToLogs(logs, day, CellEdit(duration: ''), _now),
        isEmpty,
      );
    });

    test('zero duration WITH a description keeps a zero-length entry', () {
      final out = applyCellEditToLogs(
        const [],
        day,
        CellEdit(duration: '0', description: 'note'),
        _now,
      )!;
      expect(out.single.description, 'note');
      expect(out.single.stop, out.single.start);
    });

    test('unparseable duration returns null', () {
      expect(
        applyCellEditToLogs(const [], day, CellEdit(duration: 'abc'), _now),
        isNull,
      );
    });

    test('note-only edit on a multi-entry day preserves ALL entries and total '
        'hours (no silent collapse / time loss)', () {
      final logs = [
        _e(DateTime(2026, 6, 10, 9), DateTime(2026, 6, 10, 10)), // 1h
        _e(DateTime(2026, 6, 10, 14), DateTime(2026, 6, 10, 15)), // 1h
        _e(DateTime(2026, 6, 11, 9), DateTime(2026, 6, 11, 10)), // other day
      ];
      final out = applyCellEditToLogs(
        logs,
        day,
        CellEdit(description: 'standup'),
        _now,
      )!;
      final onDay = out.where((e) => e.start!.toLocal().day == 10).toList();
      expect(onDay.length, 2, reason: 'both same-day entries survive');
      final totalSeconds = onDay.fold<int>(
        0,
        (sum, e) => sum + e.durationUpTo(_now).inSeconds,
      );
      expect(
        totalSeconds,
        const Duration(hours: 2).inSeconds,
        reason: 'a note-only edit must not drop logged hours',
      );
      // The note lands on the first same-day entry (the one the cell shows).
      expect(onDay.first.description, 'standup');
      expect(onDay[1].description, '', reason: 'other entry note untouched');
      // Other-day entry untouched.
      expect(out.where((e) => e.start!.toLocal().day == 11).length, 1);
    });

    test('billable-only edit on a multi-entry day keeps both entries', () {
      final logs = [
        _e(DateTime(2026, 6, 10, 9), DateTime(2026, 6, 10, 10)),
        _e(DateTime(2026, 6, 10, 14), DateTime(2026, 6, 10, 15)),
      ];
      final out = applyCellEditToLogs(
        logs,
        day,
        CellEdit(billable: false),
        _now,
      )!;
      expect(out.length, 2);
      expect(out.first.billable, isFalse);
    });
  });
}
