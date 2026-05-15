import 'package:admin/data/models/api/schedule_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/task_schedulers`. Standard CRUD + bulk
/// (archive/restore/delete) — the bulk endpoint and idempotency-key /
/// password-required plumbing come from [BaseEntityApi].
class SchedulesApi extends BaseEntityApi<ScheduleListApi, ScheduleItemApi> {
  SchedulesApi(super.client);

  @override
  String get basePath => '/api/v1/task_schedulers';

  @override
  ScheduleListApi parseList(Object json) =>
      ScheduleListApi.fromJson(json as Map<String, dynamic>);

  @override
  ScheduleItemApi parseItem(Object json) =>
      ScheduleItemApi.fromJson(json as Map<String, dynamic>);
}
