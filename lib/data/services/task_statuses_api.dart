import 'package:admin/data/models/api/task_status_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/task_statuses`. Adds [reorderOne] for the
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

  /// Persist a single status's new `status_order` via a normal update
  /// `PUT /task_statuses/{id}`. The server (`TaskStatusController::update`)
  /// shifts + renumbers every sibling around it — there is **no** bulk
  /// `/task_statuses/sort` endpoint (only `/tasks/sort` exists), so a
  /// reorder is modeled as a single-status move. Routed through
  /// `MutationKind.reorder`; see `TaskStatusRepository.reorder`.
  Future<void> reorderOne({
    required String id,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'PUT',
      path: '$basePath/$id',
      idempotencyKey: idempotencyKey,
      body: payload,
    );
  }
}
