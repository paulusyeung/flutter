import 'package:admin/data/db/dao/task_dao.dart';
import 'package:admin/data/models/domain/task.dart';
import 'package:admin/domain/columns/column_cells.dart';
import 'package:admin/domain/columns/column_definition.dart';
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
    cellBuilder: (t, _) => cellText(t.number, bold: true),
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
    cellBuilder: (t, _) => cellText(t.clientId),
    valueBuilder: (t) => cellNonZeroString(t.clientId),
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
    cellBuilder: (t, _) => cellText(t.statusId),
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
