import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/widgets/calendar/task_calendar_chip.dart';

/// One day in the month grid: the day number (today in a filled accent
/// circle), up to three task chips, then a "+N more" line. Tapping the cell —
/// or the overflow line — opens that day's daily view.
class TaskCalendarDayCell extends StatelessWidget {
  const TaskCalendarDayCell({
    super.key,
    required this.day,
    required this.tasks,
    required this.inMonth,
    required this.isToday,
  });

  final Date day;
  final List<Task> tasks;
  final bool inMonth;
  final bool isToday;

  static const _maxChips = 3;

  void _openDay(BuildContext context) =>
      context.go('/tasks?view=daily&date=${day.toIso()}');

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final overflow = tasks.length - _maxChips;

    return InkWell(
      onTap: () => _openDay(context),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border, width: 0.5),
        ),
        padding: const EdgeInsets.all(4),
        child: Opacity(
          opacity: inMonth ? 1 : 0.45,
          // Whole cell content in one non-scrollable scroll view: clips
          // gracefully (no RenderFlex overflow) when a grid row is very short,
          // including the fixed-height day-number badge.
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _dayNumber(context, tokens),
                const SizedBox(height: 2),
                for (final task in tasks.take(_maxChips))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: TaskCalendarChip(task: task),
                  ),
                if (overflow > 0)
                  GestureDetector(
                    onTap: () => _openDay(context),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, top: 1),
                      child: Text(
                        '+$overflow ${context.tr('more')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayNumber(BuildContext context, InTheme tokens) {
    final text = '${day.day}';
    if (isToday) {
      return Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: tokens.accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.accentInk,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 3, top: 3),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(text, style: TextStyle(fontSize: 11, color: tokens.ink)),
      ),
    );
  }
}
