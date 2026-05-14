import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart'
    show TasksViewMode;

/// AppBar trailing widget that switches between list + kanban. On wide
/// screens renders a labelled `SegmentedButton`; on narrow falls back to a
/// single-icon toggle so the AppBar stays compact.
///
/// Driven entirely via URL: tapping a segment navigates to `/tasks` or
/// `/tasks?view=kanban`. The list/kanban screens read the query param and
/// rebuild accordingly — no shared local state to keep in sync.
class TasksViewToggle extends StatelessWidget {
  const TasksViewToggle({super.key, required this.active, required this.wide});

  final TasksViewMode active;
  final bool wide;

  void _go(BuildContext context, TasksViewMode next) {
    if (next == active) return;
    if (next == TasksViewMode.kanban) {
      context.go('/tasks?view=kanban');
    } else {
      context.go('/tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return SegmentedButton<TasksViewMode>(
        segments: [
          ButtonSegment(
            value: TasksViewMode.list,
            icon: const Icon(Icons.view_list_outlined, size: 16),
            label: Text(context.tr('list')),
          ),
          ButtonSegment(
            value: TasksViewMode.kanban,
            icon: const Icon(Icons.view_kanban_outlined, size: 16),
            label: Text(context.tr('kanban')),
          ),
        ],
        selected: {active},
        showSelectedIcon: false,
        onSelectionChanged: (next) => _go(context, next.first),
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      );
    }
    return IconButton(
      tooltip: active == TasksViewMode.kanban
          ? context.tr('list')
          : context.tr('kanban'),
      icon: Icon(
        active == TasksViewMode.kanban
            ? Icons.view_list_outlined
            : Icons.view_kanban_outlined,
      ),
      onPressed: () => _go(
        context,
        active == TasksViewMode.kanban
            ? TasksViewMode.list
            : TasksViewMode.kanban,
      ),
    );
  }
}
