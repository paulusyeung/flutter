import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/task_dao.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/tasks/view_models/task_list_view_model.dart';
import 'package:admin/ui/features/tasks/views/kanban_screen.dart';
import 'package:admin/ui/features/tasks/widgets/task_actions.dart';
import 'package:admin/ui/features/tasks/widgets/task_list_tile.dart';
import 'package:admin/ui/features/tasks/widgets/task_token_search_field.dart';
import 'package:admin/ui/features/tasks/widgets/tasks_view_toggle.dart';

/// Which body the tasks screen renders. Read from `?view=` on the URL so
/// deep links and back/forward navigation surface in the right view from
/// the first frame.
enum TasksViewMode { list, kanban }

/// Tasks list screen. When `view == TasksViewMode.kanban` the body
/// delegates to [KanbanScreen]; otherwise it's the standard
/// `EntityListScreenScaffold`. Both share the same AppBar toggle so the
/// user always sees how to switch back.
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key, this.view = TasksViewMode.list});

  final TasksViewMode view;

  @override
  Widget build(BuildContext context) {
    if (view == TasksViewMode.kanban) {
      return const KanbanScreen();
    }
    return EntityListScreenScaffold<Task, TaskListViewModel>(
      titleKey: 'tasks',
      newRoute: '/tasks/new',
      newLabelKey: 'new_task',
      emptyIcon: Icons.task_outlined,
      emptyTitleKey: 'no_tasks',
      buildVm: (services, companyId) => TaskListViewModel(
        repo: services.tasks,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
      ),
      sortOptions: (context) => [
        SortOption(
          id: TaskFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
        SortOption(id: TaskFieldIds.number, label: context.tr('number')),
        SortOption(
          id: TaskFieldIds.description,
          label: context.tr('description'),
        ),
        SortOption(id: TaskFieldIds.rate, label: context.tr('rate')),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          TaskTokenSearchField(vm: vm, wide: wide),
      extraAppBarActions: (context, vm, wide) => [
        TasksViewToggle(active: view, wide: wide),
      ],
      tileBuilder: (context, vm, task, index, options) => TaskListTile(
        task: task,
        columns: options.wide ? vm.columns : const [],
        wide: options.wide,
        isLast: options.isLast,
        selecting: options.selecting,
        selected: vm.isSelected(task.id),
        onTap: options.selecting
            ? () => vm.toggleSelected(task.id)
            : () => context.go('/tasks/${task.id}'),
        onLongPress: () => vm.toggleSelected(task.id),
        onSelectTap: () => vm.toggleSelected(task.id),
        onAction: options.selecting
            ? null
            : (action) => TaskActions.dispatch(
                context,
                context.read<Services>(),
                vm.companyId,
                task,
                action,
              ),
      ),
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_task',
          pluralSuccessKey: 'archived_tasks',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_task',
          pluralSuccessKey: 'restored_tasks',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
