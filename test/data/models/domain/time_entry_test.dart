import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/time_entry.dart';

void main() {
  DateTime at(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  group('TimeEntry.encodeLog / parseLog', () {
    test('round-trips a stopped billable entry', () {
      final entries = [
        TimeEntry(
          start: at(1000000),
          stop: at(1003600),
          description: 'work',
          billable: true,
        ),
      ];
      final decoded = TimeEntry.parseLog(TimeEntry.encodeLog(entries));
      expect(decoded.length, 1);
      expect(decoded.first.start, at(1000000));
      expect(decoded.first.stop, at(1003600));
      expect(decoded.first.description, 'work');
      expect(decoded.first.billable, true);
    });

    test('encodes a running entry with a 0 stop', () {
      final json = TimeEntry.encodeLog([
        TimeEntry(start: at(1000000), stop: null),
      ]);
      expect(json, contains('1000000,0'));
      final decoded = TimeEntry.parseLog(json);
      expect(decoded.first.isRunning, true);
      expect(decoded.first.stop, isNull);
    });

    test('skips a transient entry with no start (B10 guard)', () {
      final entries = [
        const TimeEntry(start: null, stop: null),
        TimeEntry(start: at(1000000), stop: null),
      ];
      final decoded = TimeEntry.parseLog(TimeEntry.encodeLog(entries));
      expect(
        decoded.length,
        1,
        reason: 'a null-start entry must not serialize as epoch 0',
      );
      expect(decoded.first.start, at(1000000));
    });

    test('parseLog tolerates empty / malformed input', () {
      expect(TimeEntry.parseLog(null), isEmpty);
      expect(TimeEntry.parseLog(''), isEmpty);
      expect(TimeEntry.parseLog('not json'), isEmpty);
      expect(TimeEntry.parseLog('{}'), isEmpty);
    });
  });
}
