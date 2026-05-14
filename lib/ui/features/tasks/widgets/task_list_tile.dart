import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/cell_copy_hover.dart';
import 'package:admin/ui/core/widgets/leading_select_slot.dart';
import 'package:admin/ui/features/tasks/widgets/running_duration_label.dart';
import 'package:admin/ui/features/tasks/widgets/task_actions.dart';
import 'package:admin/utils/formatting.dart';

/// One row in the tasks list. Wide-mode layout matches the column header
/// strip (leading `…` slot, leading select, per-column cells, reserved
/// trailing pill slot). Narrow stacks identity + duration + running pill.
class TaskListTile extends StatefulWidget {
  const TaskListTile({
    super.key,
    required this.task,
    required this.columns,
    required this.onTap,
    this.wide = true,
    this.onAction,
    this.onSelectTap,
    this.onLongPress,
    this.selected = false,
    this.selecting = false,
    this.isLast = false,
  });

  final Task task;
  final List<ColumnDefinition<Task>> columns;
  final VoidCallback onTap;
  final bool wide;
  final ValueChanged<TaskAction>? onAction;
  final VoidCallback? onSelectTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selecting;
  final bool isLast;

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final tokens = context.inTheme;
    return InkWell(
      onTap: w.selecting ? w.onSelectTap : w.onTap,
      onLongPress: w.onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: w.selected ? tokens.accentSoft : null,
          border: BorderDirectional(
            bottom: w.isLast
                ? BorderSide.none
                : BorderSide(color: tokens.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
          child: w.wide ? _wide(context, tokens) : _narrow(context, tokens),
        ),
      ),
    );
  }

  Widget _wide(BuildContext context, InTheme tokens) {
    final w = widget;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: kColWMoreMenu,
          child: (w.onAction == null || w.selecting)
              ? const SizedBox.shrink()
              : EntityActionsPopupButton<TaskAction>(
                  icon: Icons.more_horiz,
                  items: TaskActions.itemsFor(context, w.task, w.onAction!),
                ),
        ),
        const SizedBox(width: kColCellGap),
        _leading(),
        const SizedBox(width: kColCellGap),
        for (final col in w.columns) ...[
          _CellSlot(
            column: col,
            task: w.task,
            child: col.cellBuilder(w.task, context),
          ),
          const SizedBox(width: kColCellGap),
        ],
        // Reserved trailing pill slot: shows the running badge when active.
        SizedBox(
          width: kColWPillSlot,
          child: w.task.isRunning && w.task.timeLog.isNotEmpty
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: RunningDurationLabel(
                    start: w.task.timeLog.last.start!,
                    precision: const Duration(seconds: 1),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _narrow(BuildContext context, InTheme tokens) {
    final w = widget;
    final t = w.task;
    final identity = t.description.isEmpty
        ? (t.number.isEmpty ? '—' : '#${t.number}')
        : t.description;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _leading(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                identity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (t.clientId.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  t.clientId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.ink3, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (t.isRunning && t.timeLog.isNotEmpty)
          RunningDurationLabel(
            start: t.timeLog.last.start!,
            precision: const Duration(seconds: 1),
          )
        else
          Text(
            formatDuration(t.totalDuration(), compactDays: true),
            style: TextStyle(
              color: tokens.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        if (w.onAction != null && !w.selecting) ...[
          const SizedBox(width: 4),
          EntityActionsPopupButton<TaskAction>(
            icon: Icons.more_horiz,
            items: TaskActions.itemsFor(context, w.task, w.onAction!),
          ),
        ],
      ],
    );
  }

  Widget _leading() {
    final w = widget;
    return LeadingSelectSlot(
      selecting: w.selecting,
      selected: w.selected,
      onSelectTap: w.onSelectTap,
      defaultChild: const SizedBox.shrink(),
    );
  }
}

class _CellSlot extends StatelessWidget {
  const _CellSlot({
    required this.column,
    required this.task,
    required this.child,
  });
  final ColumnDefinition<Task> column;
  final Task task;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final aligned = Align(
      alignment: column.align == ColumnAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: child,
    );
    final cell = CellCopyHover(
      value: column.valueBuilder?.call(task),
      align: column.align,
      child: aligned,
    );
    if (column.isFlex) return Expanded(child: cell);
    return SizedBox(width: column.width, child: cell);
  }
}
