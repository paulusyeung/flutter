import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'task_status.freezed.dart';

/// Clean domain model for a TaskStatus row. Used by the kanban board's
/// columns and by the status dropdown on the Task edit form. Edited via
/// Settings → Advanced → Task Statuses.
@freezed
abstract class TaskStatus with _$TaskStatus {
  const factory TaskStatus({
    required String id,
    required String name,
    required String color,
    required int statusOrder,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    required bool isDeleted,
    @Default(false) bool isDirty,
  }) = _TaskStatus;

  factory TaskStatus.fromApi(TaskStatusApi a) => TaskStatus(
    id: a.id,
    name: a.name,
    color: a.color,
    statusOrder: a.statusOrder ?? 0,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
    isDeleted: a.isDeleted,
  );
}

extension TaskStatusPayload on TaskStatus {
  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    return <String, dynamic>{
      if (preserveTempId || !id.startsWith('tmp_')) 'id': id,
      'name': name,
      'color': color,
      'status_order': statusOrder,
    };
  }
}
