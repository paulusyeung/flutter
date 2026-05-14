import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/task_statuses`. Adds [sort] for the
/// drag-handle reorder under Settings → Advanced → Task Statuses (and the
/// long-press-header reorder on the kanban board).
class TaskStatusesApi
    extends BaseEntityApi<TaskStatusListApi, TaskStatusItemApi> {
  TaskStatusesApi(super.client);

  @override
  String get basePath => '/api/v1/task_statuses';

  @override
  TaskStatusListApi parseList(Object json) =>
      TaskStatusListApi.fromJson(json as Map<String, dynamic>);

  @override
  TaskStatusItemApi parseItem(Object json) =>
      TaskStatusItemApi.fromJson(json as Map<String, dynamic>);

  /// Bulk reorder. Payload `{ "status_ids": ["<id>", ...] }` in the new
  /// order. Routed through `MutationKind.reorder` like the tasks variant.
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
}
