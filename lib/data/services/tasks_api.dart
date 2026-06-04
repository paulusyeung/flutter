import 'package:admin/data/models/api/task_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/data/services/upload_source.dart';

/// Concrete API for `/api/v1/tasks`. Adds two methods outside the standard
/// CRUD set: [sort] for the kanban reorder endpoint and [uploadDocument]
/// for the multipart document attachment (mirrors Expense / Project).
class TasksApi extends BaseEntityApi<TaskListApi, TaskItemApi> {
  TasksApi(super.client);

  @override
  String get basePath => '/api/v1/tasks';

  @override
  TaskListApi parseList(Object json) =>
      TaskListApi.fromJson(json as Map<String, dynamic>);

  @override
  TaskItemApi parseItem(Object json) =>
      TaskItemApi.fromJson(json as Map<String, dynamic>);

  /// Bulk reorder of tasks across statuses. Payload shape:
  ///
  /// ```
  /// {
  ///   "status_ids": ["<sid1>", "<sid2>", ...],          // column order
  ///   "task_ids":   { "<sid1>": ["<tid1>", "<tid2>"], ... }
  /// }
  /// ```
  ///
  /// Wired via the dispatcher's `customActions` map under
  /// `MutationKind.reorder` — see `services.dart`.
  Future<void> sort({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'POST',
      path: '$basePath/sort',
      idempotencyKey: idempotencyKey,
      body: payload,
    );
  }

  /// Upload a document attachment to a task. Returns the refreshed task
  /// envelope with the new document in its `documents` array. Mirrors
  /// `ExpensesApi.uploadDocument` — same multipart field name.
  Future<TaskApi> uploadDocument({
    required String entityId,
    required UploadSource source,
    required String idempotencyKey,
  }) async {
    final file = await source.toMultipartFile('documents[]');
    final raw = await client.uploadMultipart(
      path: '$basePath/$entityId/upload',
      fields: const {'_method': 'PUT'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object).data;
  }
}
