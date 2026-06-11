import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/tasks/task_day.dart';
import 'package:admin/utils/formatting.dart';

/// A pending edit to one weekly cell (one task × one day). A null field means
/// that aspect wasn't touched; [merge] overlays a newer edit's non-null fields
/// so several edits to the same cell within the debounce window collapse.
class CellEdit {
  CellEdit({this.duration, this.description, this.billable});

  /// Raw user-typed duration text. An empty string means "cleared" → delete.
  String? duration;
  String? description;
  bool? billable;

  void merge(CellEdit other) {
    if (other.duration != null) duration = other.duration;
    if (other.description != null) description = other.description;
    if (other.billable != null) billable = other.billable;
  }

  CellEdit copy() => CellEdit(
    duration: duration,
    description: description,
    billable: billable,
  );

  bool sameValueAs(CellEdit o) =>
      duration == o.duration &&
      description == o.description &&
      billable == o.billable;
}

/// Duration text → seconds, mirroring React's `parseDurationToSeconds`:
/// empty string → 0 (a cleared cell deletes the entry); otherwise reuse
/// [parseDurationInput] (bare number = hours, `1:30` = H:M, unit suffixes).
/// Returns null only for unparseable *non-empty* input.
int? durationStringToSeconds(String raw) {
  if (raw.trim().isEmpty) return 0;
  return parseDurationInput(raw)?.inSeconds;
}

/// Collapse every entry in [logs] whose start's LOCAL date is [day] into a
/// single entry merging [edit], leaving entries on other days untouched.
/// Returns the new log, or null if [edit] carries an unparseable duration.
///
/// Local↔UTC discipline (the load-bearing part): day membership and the
/// synthesized 09:00 start are computed in local wall-clock, then stored as
/// UTC — [TimeEntry.start] is UTC on the wire. An existing entry's start is
/// preserved verbatim so re-editing a cell never drifts its clock time.
List<TimeEntry>? applyCellEditToLogs(
  List<TimeEntry> logs,
  Date day,
  CellEdit edit,
  DateTime now,
) {
  TimeEntry? existing;
  final remaining = <TimeEntry>[];
  for (final e in logs) {
    if (timeEntryLocalDate(e) == day) {
      // First same-day entry seeds description/billable/start; any further
      // same-day entries are intentionally collapsed away.
      existing ??= e;
    } else {
      remaining.add(e);
    }
  }

  final int seconds;
  if (edit.duration != null) {
    final parsed = durationStringToSeconds(edit.duration!);
    if (parsed == null) return null;
    seconds = parsed;
  } else if (existing != null) {
    seconds = existing.durationUpTo(now).inSeconds;
  } else {
    seconds = 0;
  }

  final description = edit.description ?? existing?.description ?? '';
  final billable = edit.billable ?? existing?.billable ?? true;

  // Zero duration and no description → delete the entry.
  if (seconds <= 0 && description.isEmpty) {
    return remaining;
  }

  final DateTime startUtc;
  if (existing?.start != null) {
    startUtc = existing!.start!;
  } else {
    // Local 09:00 on `day`, stored as UTC.
    startUtc = DateTime(day.year, day.month, day.day, 9).toUtc();
  }
  remaining.add(
    TimeEntry(
      start: startUtc,
      stop: startUtc.add(Duration(seconds: seconds)),
      description: description,
      billable: billable,
    ),
  );
  return remaining;
}
