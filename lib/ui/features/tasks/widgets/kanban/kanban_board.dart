import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/features/tasks/view_models/kanban_view_model.dart';
import 'package:admin/ui/features/tasks/widgets/kanban/kanban_column.dart';

/// The horizontal board: one column per [TaskStatus], cards inside drag
/// between columns. Reads [KanbanViewModel] off the ambient `Provider`.
///
/// Drop semantics:
///   * Drop a [Task] on a column → that task's `status_id` becomes the
///     column's id; the column's `task_ids` array appends the task at
///     the bottom.
///   * Drop a [Task] on another card → that task lands above the target
///     card in the same column.
///   * Within-column moves are detected by `task.statusId == target.id`.
///
/// The board only ever calls `commitReorder` once per drop, with the
/// **entire** board layout — so changes that span columns write to both
/// the source and target columns transactionally.
class KanbanBoard extends StatelessWidget {
  const KanbanBoard({super.key});

  static const double _columnWidth = 320;
  static const double _columnGap = 12;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<KanbanViewModel>();

    if (vm.isResolving && vm.statuses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.statuses.isEmpty) {
      return EmptyState(
        icon: Icons.label_outline,
        title: context.tr('no_task_statuses'),
        subtitle: context.tr('no_task_statuses_hint'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(InSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vm.statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: _columnGap),
        itemBuilder: (context, i) {
          final status = vm.statuses[i];
          return SizedBox(
            width: _columnWidth,
            child: KanbanColumn(
              status: status,
              tasks: vm.tasksFor(status.id),
              onAcceptTask: (task, beforeTaskId) =>
                  _onAccept(vm, status, task, beforeTaskId),
            ),
          );
        },
      ),
    );
  }

  void _onAccept(
    KanbanViewModel vm,
    TaskStatus targetStatus,
    Task draggedTask,
    String? beforeTaskId,
  ) {
    // Build the next full layout from the current `tasksByStatus`,
    // removing the dragged task from its source column and inserting it
    // at the right position in the target column.
    final next = <String, List<Task>>{
      for (final s in vm.statuses)
        s.id: List<Task>.from(vm.tasksFor(s.id))
          ..removeWhere((t) => t.id == draggedTask.id),
    };
    final targetList = next[targetStatus.id] ?? <Task>[];
    final moved = draggedTask.copyWith(statusId: targetStatus.id);
    if (beforeTaskId == null) {
      targetList.add(moved);
    } else {
      final idx = targetList.indexWhere((t) => t.id == beforeTaskId);
      targetList.insert(idx < 0 ? targetList.length : idx, moved);
    }
    next[targetStatus.id] = targetList;
    vm.commitReorder(orderedByStatus: next);
  }
}
