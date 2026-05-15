import 'package:go_router/go_router.dart';

import 'package:admin/data/db/dao/task_dao.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/ui/features/projects/widgets/project_name_label.dart';
import 'package:admin/ui/features/tasks/widgets/client_name_label.dart';
import 'package:admin/ui/features/tasks/widgets/task_status_pill.dart';
import 'package:admin/utils/formatting.dart';

typedef TaskColumn = ColumnDefinition<Task>;

const List<String> kDefaultTaskColumns = <String>[
  TaskFieldIds.number,
  TaskFieldIds.description,
  TaskFieldIds.rate,
  TaskFieldIds.updatedAt,
];

final List<TaskColumn> kAllTaskColumns = <TaskColumn>[
  TaskColumn(
    id: TaskFieldIds.number,
    labelKey: 'number',
    width: 120,
    cellBuilder: (t, ctx) => cellLink(
      ctx,
      t.number,
      bold: true,
      onTap: () => ctx.go('/tasks/${t.id}/edit'),
    ),
    valueBuilder: (t) => cellNonZeroString(t.number),
  ),
  TaskColumn(
    id: TaskFieldIds.description,
    labelKey: 'description',
    cellBuilder: (t, _) => cellText(t.description),
    valueBuilder: (t) => cellNonZeroString(t.description),
  ),
  TaskColumn(
    id: TaskFieldIds.clientId,
    labelKey: 'client',
    width: 180,
    // Subscribes to `services.clients.watch` and falls back to the raw
    // id while the watch is empty — see `ClientNameLabel`.
    cellBuilder: (t, _) => t.clientId.isEmpty
        ? cellEmpty()
        : ClientNameLabel(clientId: t.clientId),
    valueBuilder: (t) => cellNonZeroString(t.clientId),
  ),
  // Default-off — Tasks already shows Client by default, and surfacing
  // Project too clutters the wide table for the majority of users who
  // don't use Projects. Flippable via the column picker.
  TaskColumn(
    id: TaskFieldIds.projectId,
    labelKey: 'project',
    width: 180,
    cellBuilder: (t, _) => t.projectId.isEmpty
        ? cellEmpty()
        : ProjectNameLabel(projectId: t.projectId),
    valueBuilder: (t) => cellNonZeroString(t.projectId),
  ),
  TaskColumn(
    id: TaskFieldIds.rate,
    labelKey: 'rate',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (t, _) => cellMoney(t.rate),
    valueBuilder: (t) => cellMoneyValue(t.rate),
  ),
  TaskColumn(
    id: 'duration',
    labelKey: 'duration',
    width: 120,
    align: ColumnAlign.end,
    cellBuilder: (t, _) =>
        cellText(formatDuration(t.totalDuration(), compactDays: true)),
    valueBuilder: (t) => formatDuration(t.totalDuration(), compactDays: true),
  ),
  TaskColumn(
    id: TaskFieldIds.taskStatusId,
    labelKey: 'status',
    width: 140,
    // Subscribes to `services.taskStatuses.watch` — renders the color
    // dot + name. Falls back to the raw id while the watch is empty.
    cellBuilder: (t, _) =>
        t.statusId.isEmpty ? cellEmpty() : TaskStatusPill(statusId: t.statusId),
    valueBuilder: (t) => cellNonZeroString(t.statusId),
  ),
  TaskColumn(
    id: TaskFieldIds.updatedAt,
    labelKey: 'last_updated',
    width: 120,
    cellBuilder: (t, ctx) => cellDate(t.updatedAt, ctx),
    valueBuilder: (t) => t.updatedAt.toIso8601String(),
  ),
];

final Map<String, TaskColumn> taskColumnsById = {
  for (final c in kAllTaskColumns) c.id: c,
};
