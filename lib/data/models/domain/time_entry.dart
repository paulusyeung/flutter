import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/value/parsing.dart';

part 'time_entry.freezed.dart';

/// One row in a task's `time_log` array.
///
/// Wire shape: `[start_unix, stop_unix, description, billable]`. A zero
/// stop means the entry is running (server convention). We model both
/// start and stop as nullable `DateTime` so the in-form transient state
/// "user just tapped + Add time and hasn't picked a start yet" is
/// representable; encode treats null start/stop as 0.
@freezed
abstract class TimeEntry with _$TimeEntry {
  const factory TimeEntry({
    required DateTime? start,
    required DateTime? stop,
    @Default('') String description,
    @Default(true) bool billable,
  }) = _TimeEntry;

  /// Parse a single wire entry. The server returns `[number, number, string,
  /// bool]`; older payloads may omit description / billable.
  factory TimeEntry.fromWire(List<dynamic> a) {
    DateTime? secondsToDt(Object? v) {
      final n = v is num ? v.toInt() : 0;
      return epochSecondsToUtcOrNull(n);
    }

    return TimeEntry(
      start: a.isNotEmpty ? secondsToDt(a[0] as Object?) : null,
      stop: a.length > 1 ? secondsToDt(a[1]) : null,
      description: a.length > 2 ? (a[2] as String? ?? '') : '',
      billable: a.length > 3 ? (a[3] as bool? ?? true) : true,
    );
  }

  /// Parse the full `time_log` JSON string into a list. Empty / null / non-
  /// list input yields the empty list — the server occasionally sends `""`
  /// or `null` for tasks with no entries.
  static List<TimeEntry> parseLog(String? raw) {
    if (raw == null || raw.isEmpty) return const <TimeEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <TimeEntry>[];
      return decoded
          .whereType<List<dynamic>>()
          .map(TimeEntry.fromWire)
          .toList(growable: false);
    } catch (_) {
      // Malformed `time_log` shouldn't break the screen; surface an empty
      // log instead.
      return const <TimeEntry>[];
    }
  }

  /// Encode a list back to the wire shape. Used by `Task.toApiJson()`.
  static String encodeLog(List<TimeEntry> entries) {
    int dtToSeconds(DateTime? dt) =>
        dt == null ? 0 : dt.millisecondsSinceEpoch ~/ 1000;
    final raw = <List<dynamic>>[
      for (final e in entries)
        [dtToSeconds(e.start), dtToSeconds(e.stop), e.description, e.billable],
    ];
    return jsonEncode(raw);
  }
}

extension TimeEntryX on TimeEntry {
  /// An entry is running when it has a start but no stop.
  bool get isRunning => start != null && stop == null;

  /// Total elapsed time. For a running entry, measured against [now]; for a
  /// stopped entry, the difference between stop and start. Returns
  /// [Duration.zero] when the entry has no start yet.
  Duration durationUpTo(DateTime now) {
    final s = start;
    if (s == null) return Duration.zero;
    final e = stop ?? now;
    final d = e.difference(s);
    return d.isNegative ? Duration.zero : d;
  }
}
