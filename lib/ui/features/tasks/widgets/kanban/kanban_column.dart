import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/data/models/domain/task_status.dart';
import 'package:admin/ui/features/tasks/widgets/kanban/kanban_card.dart';

/// One column on the kanban board. Renders the status header + a scrollable
/// list of [KanbanCard]s, wrapped in DragTargets so cards can be dropped
/// onto cards (insert above) or onto the empty area below (append).
class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.onAcceptTask,
  });

  final TaskStatus status;
  final List<Task> tasks;

  /// Called when the user drops [task] onto this column. [beforeTaskId] is
  /// the id of the card the dragged task should appear *above*, or null
  /// to append at the bottom.
  final void Function(Task task, String? beforeTaskId) onAcceptTask;

  Color _parseColor(BuildContext context) {
    final tokens = context.inTheme;
    final raw = status.color.trim().replaceFirst('#', '');
    if (raw.length == 6) {
      final v = int.tryParse(raw, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return tokens.ink3;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final dot = _parseColor(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(InSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.name.isEmpty ? status.id : status.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                ),
                Text(
                  tasks.length.toString(),
                  style: TextStyle(fontSize: 12, color: tokens.ink3),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Expanded(
            child: DragTarget<Task>(
              onAcceptWithDetails: (details) {
                onAcceptTask(details.data, null);
              },
              builder: (context, candidate, rejected) {
                return ListView.builder(
                  padding: const EdgeInsets.all(InSpacing.sm),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return DragTarget<Task>(
                      onWillAcceptWithDetails: (details) =>
                          details.data.id != t.id,
                      onAcceptWithDetails: (details) {
                        onAcceptTask(details.data, t.id);
                      },
                      builder: (context, candidate, rejected) {
                        final card = LongPressDraggable<Task>(
                          data: t,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 280,
                              child: Opacity(
                                opacity: 0.85,
                                child: KanbanCard(task: t),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: KanbanCard(task: t),
                          ),
                          child: KanbanCard(task: t),
                        );
                        if (candidate.isNotEmpty) {
                          return Stack(
                            children: [
                              card,
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 0,
                                child: Container(
                                  height: 3,
                                  color: tokens.accent,
                                ),
                              ),
                            ],
                          );
                        }
                        return card;
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
