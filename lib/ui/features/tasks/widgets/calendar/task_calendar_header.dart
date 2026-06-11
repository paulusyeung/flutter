import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/view_models/task_calendar_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// Month navigation bar above the calendar grid: prev / next month, the month
/// label, and a Today shortcut. The label uses the company locale; there is no
/// `Formatter` month-only method, so a locale-aware `DateFormat('MMMM yyyy')`
/// is the minimal acceptable exception (safe — intl date symbols are preloaded
/// by GlobalMaterialLocalizations at boot).
class TaskCalendarHeader extends StatelessWidget {
  const TaskCalendarHeader({super.key, this.formatter});

  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskCalendarViewModel>();
    final tokens = context.inTheme;
    final locale = formatter?.settings.locale;
    final label = DateFormat(
      'MMMM yyyy',
      locale == null || locale.isEmpty ? null : locale,
    ).format(DateTime(vm.month.year, vm.month.month));

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: InSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.tr('previous'),
            icon: const Icon(Icons.chevron_left),
            onPressed: vm.prevMonth,
          ),
          IconButton(
            tooltip: context.tr('next'),
            icon: const Icon(Icons.chevron_right),
            onPressed: vm.nextMonth,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
            onPressed: vm.goToToday,
            child: Text(context.tr('today')),
          ),
        ],
      ),
    );
  }
}
