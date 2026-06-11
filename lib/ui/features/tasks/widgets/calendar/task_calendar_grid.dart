import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/ui/features/tasks/view_models/task_calendar_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/calendar/task_calendar_day_cell.dart';
import 'package:admin/utils/formatting.dart';

/// The month grid: a 7-column weekday header + 6 equal-height week rows of day
/// cells. Tasks are grouped by day once per build; each cell renders its own
/// chips. The grid fills the available height so the layout never scrolls.
class TaskCalendarGrid extends StatelessWidget {
  const TaskCalendarGrid({super.key, this.formatter});

  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskCalendarViewModel>();
    final tokens = context.inTheme;
    final days = vm.gridDays;
    final byDay = vm.tasksByDayFiltered();
    final today = Date.today();
    final month = vm.month;
    final locale = formatter?.settings.locale;
    final localeArg = locale == null || locale.isEmpty ? null : locale;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      DateFormat('EEE', localeArg).format(days[i].toDateTime()),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tokens.ink3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                for (var week = 0; week < 6; week++)
                  Expanded(
                    child: Row(
                      children: [
                        for (final day in days.sublist(week * 7, week * 7 + 7))
                          Expanded(
                            child: TaskCalendarDayCell(
                              day: day,
                              tasks: byDay[day] ?? const [],
                              inMonth:
                                  day.month == month.month &&
                                  day.year == month.year,
                              isToday: day == today,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
