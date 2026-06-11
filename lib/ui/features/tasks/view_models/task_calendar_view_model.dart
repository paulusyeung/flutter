import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/data/repositories/task_repository.dart';
import 'package:admin/domain/tasks/task_day.dart';
import 'package:admin/ui/features/tasks/view_models/task_filters_mixin.dart';
import 'package:admin/utils/date_ranges.dart';

/// Drives the monthly calendar view. Subscribes to every active task
/// (`watchAllActive`, includes invoiced) and groups them by day in Dart. The
/// focused month is internal state — `prev/next/goToToday` mutate it and
/// notify, so scrubbing never touches the URL or remounts the VM.
class TaskCalendarViewModel extends ChangeNotifier with TaskFiltersMixin {
  TaskCalendarViewModel({
    required this.repo,
    required this.companyId,
    int firstDayOfWeek = 0,
    Date? focusMonth,
  }) : _firstDayOfWeek = firstDayOfWeek,
       _month = focusMonth == null
           ? _firstOfThisMonth()
           : Date(focusMonth.year, focusMonth.month, 1) {
    _sub = repo.watchAllActive(companyId: companyId).listen(_onTasks);
  }

  final TaskRepository repo;
  final String companyId;

  int _firstDayOfWeek;
  Date _month; // day-of-month is irrelevant — always the 1st.
  StreamSubscription<List<Task>>? _sub;
  List<Task> _tasks = const [];
  bool _disposed = false;

  Date get month => _month;
  int get firstDayOfWeek => _firstDayOfWeek;

  /// The 42 days (6 weeks) of the current month's grid, honoring the company's
  /// first-day-of-week.
  List<Date> get gridDays => monthGridDays(_month, _firstDayOfWeek);

  /// Tasks grouped by their day for the active filter set, each day's list
  /// sorted chronologically by earliest start. Recomputed per build — cheap
  /// at task volumes a single company holds, and avoids a cache the filter
  /// mixin's setters would have to invalidate.
  Map<Date, List<Task>> tasksByDayFiltered() {
    final src = filtersActive ? _tasks.where(matchesFilters) : _tasks;
    final map = tasksByDay(src);
    for (final list in map.values) {
      list.sort((a, b) {
        final sa = a.earliestStart;
        final sb = b.earliestStart;
        if (sa == null || sb == null) return 0;
        return sa.compareTo(sb);
      });
    }
    return map;
  }

  void setFirstDayOfWeek(int value) {
    if (_firstDayOfWeek == value) return;
    _firstDayOfWeek = value;
    if (!_disposed) notifyListeners();
  }

  void prevMonth() => _setMonth(_addMonths(_month, -1));
  void nextMonth() => _setMonth(_addMonths(_month, 1));
  void goToToday() => _setMonth(_firstOfThisMonth());

  void _setMonth(Date next) {
    if (next == _month) return;
    _month = next;
    if (!_disposed) notifyListeners();
  }

  void _onTasks(List<Task> tasks) {
    _tasks = tasks;
    if (!_disposed) notifyListeners();
  }

  static Date _firstOfThisMonth() {
    final t = Date.today();
    return Date(t.year, t.month, 1);
  }

  /// Step months through `DateTime` so month 0 / 13 normalize correctly — the
  /// `Date` constructor does not (`Date(2026, 0, 1)` would be invalid).
  static Date _addMonths(Date m, int delta) {
    final d = DateTime(m.year, m.month + delta, 1);
    return Date(d.year, d.month, 1);
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
