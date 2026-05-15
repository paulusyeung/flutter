import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/project_dao.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/projects/view_models/project_list_view_model.dart';
import 'package:admin/ui/features/projects/widgets/project_actions.dart';
import 'package:admin/ui/features/projects/widgets/project_list_empty_state.dart';
import 'package:admin/ui/features/projects/widgets/project_list_tile.dart';
import 'package:admin/ui/features/projects/widgets/project_token_search_field.dart';

/// Projects list screen — pure config + per-entity widgets. Mirrors
/// `ProductListScreen` / `TaskListScreen`; the screen-level chrome lives
/// in `EntityListScreenScaffold`.
class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<Project, ProjectListViewModel>(
      titleKey: 'projects',
      newRoute: '/projects/new',
      newLabelKey: 'new_project',
      emptyIcon: Icons.work_outline,
      emptyTitleKey: 'no_projects_yet',
      wantsFormatter: true,
      buildVm: (services, companyId) => ProjectListViewModel(
        repo: services.projects,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
      ),
      sortOptions: (context) => [
        SortOption(id: ProjectFieldIds.name, label: context.tr('name')),
        SortOption(id: ProjectFieldIds.number, label: context.tr('number')),
        SortOption(id: ProjectFieldIds.clientId, label: context.tr('client')),
        SortOption(id: ProjectFieldIds.dueDate, label: context.tr('due_date')),
        SortOption(
          id: ProjectFieldIds.budgetedHours,
          label: context.tr('budgeted_hours'),
        ),
        SortOption(
          id: ProjectFieldIds.currentHours,
          label: context.tr('current_hours'),
        ),
        SortOption(
          id: ProjectFieldIds.taskRate,
          label: context.tr('task_rate'),
        ),
        SortOption(
          id: ProjectFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          ProjectTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => ProjectListEmptyState(vm: vm),
      tileBuilder: (context, vm, project, index, options) {
        final isUrlSelected = options.selectedId == project.id;
        return ProjectListTile(
          project: project,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(project.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(project.id)
              : () => context.go('/projects/${project.id}'),
          onLongPress: () => vm.toggleSelected(project.id),
          onSelectTap: () => vm.toggleSelected(project.id),
          onAction: options.selecting
              ? null
              : (action) => ProjectActions.dispatch(
                  context,
                  context.read<Services>(),
                  vm.companyId,
                  project,
                  action,
                ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_project',
          pluralSuccessKey: 'archived_projects',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_project',
          pluralSuccessKey: 'restored_projects',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
