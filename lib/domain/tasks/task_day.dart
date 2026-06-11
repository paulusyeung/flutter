import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/time_entry.dart';
import 'package:admin/data/models/value/date.dart';

/// Calendar-day helpers shared by the task daily / weekly / monthly views.
///
/// Tasks carry no stored date — a task's "day" is the LOCAL date of its
/// earliest time-entry start (this is exactly the server's
/// `calculated_start_date`, sent on the wire as `date`). [TimeEntry.start] is
/// decoded as UTC, so every day computation here converts to local
/// (`.toLocal()`) before extracting year/month/day — otherwise a task logged
/// near midnight lands on the wrong calendar cell for users away from UTC.

extension TaskDay on Task {
  /// Earliest time-entry start (UTC), or null when no entry has a start. This
  /// is the instant the server reports as `calculated_start_date`.
  DateTime? get earliestStart {
    DateTime? earliest;
    for (final e in timeLog) {
      final s = e.start;
      if (s == null) continue;
      if (earliest == null || s.isBefore(earliest)) earliest = s;
    }
    return earliest;
  }

  /// The local calendar date this task belongs to, or null when the log is
  /// empty / has no started entry.
  Date? get day {
    final s = earliestStart?.toLocal();
    if (s == null) return null;
    return Date(s.year, s.month, s.day);
  }
}

/// Local calendar date of a single time entry's start, or null when unset.
Date? timeEntryLocalDate(TimeEntry e) {
  final s = e.start;
  if (s == null) return null;
  final local = s.toLocal();
  return Date(local.year, local.month, local.day);
}

/// Every time entry across [tasks] whose start's local date is [day], paired
/// with its owning task, sorted by start time ascending. Backs the daily
/// timeline. Entries without a start are skipped.
List<({Task task, TimeEntry entry})> entriesOnDay(
  Iterable<Task> tasks,
  Date day,
) {
  final out = <({Task task, TimeEntry entry})>[];
  for (final task in tasks) {
    for (final entry in task.timeLog) {
      if (timeEntryLocalDate(entry) == day) {
        out.add((task: task, entry: entry));
      }
    }
  }
  out.sort((a, b) => a.entry.start!.compareTo(b.entry.start!));
  return out;
}

/// Group [tasks] by their [TaskDay.day]. Tasks with no day are dropped.
Map<Date, List<Task>> tasksByDay(Iterable<Task> tasks) {
  final out = <Date, List<Task>>{};
  for (final task in tasks) {
    final d = task.day;
    if (d == null) continue;
    out.putIfAbsent(d, () => <Task>[]).add(task);
  }
  return out;
}

/// The task's display identity for chips/rows: its description (HTML stripped,
/// whitespace-collapsed, optionally clipped to [max] characters), falling back
/// to `#number`, then `—`. Mirrors `kanban_card`'s identity rule so every task
/// surface reads the same. The "secondary" line (project / client name) is
/// resolved separately via `ProjectNameLabel` / `ClientNameLabel` — those names
/// are not carried on the [Task] model.
String taskPrimaryLabel(Task task, {int max = 0}) {
  final desc = _plain(task.description);
  if (desc.isEmpty) {
    return task.number.isEmpty ? '—' : '#${task.number}';
  }
  if (max > 0 && desc.length > max) {
    return '${desc.substring(0, max).trimRight()}…';
  }
  return desc;
}

final _tagRe = RegExp('<[^>]*>');
final _wsRe = RegExp(r'\s+');

/// Strip residual HTML tags (legacy Quill descriptions) and collapse runs of
/// whitespace so a multi-line description never breaks a single-line chip.
String _plain(String raw) =>
    raw.replaceAll(_tagRe, ' ').replaceAll(_wsRe, ' ').trim();
