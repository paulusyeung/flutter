import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/tasks/view_models/task_calendar_view_model.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart';
import 'package:admin/ui/features/tasks/widgets/calendar/task_calendar_grid.dart';
import 'package:admin/ui/features/tasks/widgets/calendar/task_calendar_header.dart';
import 'package:admin/ui/features/tasks/widgets/task_filter_bar.dart';
import 'package:admin/ui/features/tasks/widgets/tasks_view_toggle.dart';
import 'package:admin/utils/formatting.dart';

/// Monthly calendar view for tasks. Mirrors the kanban-screen shape: owns its
/// own [TaskCalendarViewModel], rebuilds it on company switch, and carries the
/// shared [TasksViewToggle] in the AppBar. The `Formatter` is resolved once and
/// passed down for the month label + weekday headers.
class TaskCalendarScreen extends StatefulWidget {
  const TaskCalendarScreen({super.key, this.focusDate});

  /// Seeds the focused month (from `?date=`); null defaults to the current
  /// month.
  final Date? focusDate;

  @override
  State<TaskCalendarScreen> createState() => _TaskCalendarScreenState();
}

class _TaskCalendarScreenState extends State<TaskCalendarScreen> {
  late final Services _services;
  late String _companyId;
  late TaskCalendarViewModel _vm;
  Formatter? _formatter;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _formatter = _services.formatterIfReady(_companyId);
    _vm = TaskCalendarViewModel(
      repo: _services.tasks,
      companyId: _companyId,
      firstDayOfWeek: _formatter?.settings.firstDayOfWeek ?? 0,
      focusMonth: widget.focusDate,
    );
    _services.auth.session.addListener(_onSessionChanged);
    _resolveFormatter();
  }

  Future<void> _resolveFormatter() async {
    final forCompany = _companyId;
    final f = await _services.formatterFor(forCompany);
    // Bail if the company switched while we were resolving — otherwise the old
    // company's first-day-of-week lands on the new company's VM.
    if (!mounted || forCompany != _companyId) return;
    setState(() => _formatter = f);
    _vm.setFirstDayOfWeek(f.settings.firstDayOfWeek);
  }

  void _onSessionChanged() {
    final s = _services.auth.session.value;
    if (s == null || s.currentCompanyId == _companyId) return;
    final old = _vm;
    _companyId = s.currentCompanyId;
    _formatter = _services.formatterIfReady(_companyId);
    setState(() {
      _vm = TaskCalendarViewModel(
        repo: _services.tasks,
        companyId: _companyId,
        firstDayOfWeek: _formatter?.settings.firstDayOfWeek ?? 0,
      );
    });
    old.dispose();
    _resolveFormatter();
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildTasksViewAppBar(context, TasksViewMode.calendar),
      floatingActionButton: FloatingActionButton(
        tooltip: context.tr('new_task'),
        onPressed: () => goToCreateRoute(context, '/tasks/new'),
        child: const Icon(Icons.add),
      ),
      body: ChangeNotifierProvider<TaskCalendarViewModel>.value(
        value: _vm,
        child: Column(
          children: [
            TaskFilterBar(filters: _vm, companyId: _companyId),
            TaskCalendarHeader(formatter: _formatter),
            Expanded(child: TaskCalendarGrid(formatter: _formatter)),
          ],
        ),
      ),
    );
  }
}
