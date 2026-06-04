import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/document_api_model.dart';

part 'task_api_model.freezed.dart';
part 'task_api_model.g.dart';

/// Raw JSON shape of a task as returned by `/api/v1/tasks`.
///
/// `timeLog` stays as a `String` here (the raw JSON-array-of-arrays the
/// server returns). The domain model parses it into `List<TimeEntry>`
/// once in `Task.fromApi`.
@freezed
abstract class TaskApi with _$TaskApi {
  const factory TaskApi({
    @Default('') String id,
    @JsonKey(name: 'user_id') @Default('') String userId,
    @JsonKey(name: 'assigned_user_id') @Default('') String assignedUserId,
    @Default('') String number,
    @Default('') String description,
    @JsonKey(name: 'rate') @Default('0') Object rate,
    @JsonKey(name: 'invoice_id') @Default('') String invoiceId,
    @JsonKey(name: 'client_id') @Default('') String clientId,
    @JsonKey(name: 'project_id') @Default('') String projectId,
    @JsonKey(name: 'status_id') @Default('') String statusId,
    @JsonKey(name: 'status_order') int? statusOrder,
    @JsonKey(name: 'time_log') @Default('') String timeLog,
    @JsonKey(name: 'custom_value1') @Default('') String customValue1,
    @JsonKey(name: 'custom_value2') @Default('') String customValue2,
    @JsonKey(name: 'custom_value3') @Default('') String customValue3,
    @JsonKey(name: 'custom_value4') @Default('') String customValue4,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'is_running') @Default(false) bool isRunning,
    @JsonKey(name: 'is_date_based') @Default(false) bool isDateBased,
    // Nullable so JSON-omitted (→ null) is distinguishable from
    // JSON-present-and-empty (→ const []). Same convention as `ExpenseApi`.
    List<DocumentApi>? documents,
  }) = _TaskApi;

  factory TaskApi.fromJson(Map<String, dynamic> json) =>
      _$TaskApiFromJson(json);
}

/// `GET /tasks` response envelope.
@freezed
abstract class TaskListApi with _$TaskListApi {
  const factory TaskListApi({@Default([]) List<TaskApi> data}) = _TaskListApi;

  factory TaskListApi.fromJson(Map<String, dynamic> json) =>
      _$TaskListApiFromJson(json);
}

/// `POST/PUT /tasks/{id}` single-item envelope.
@freezed
abstract class TaskItemApi with _$TaskItemApi {
  const factory TaskItemApi({required TaskApi data}) = _TaskItemApi;

  factory TaskItemApi.fromJson(Map<String, dynamic> json) =>
      _$TaskItemApiFromJson(json);
}
