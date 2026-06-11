import 'package:admin/data/models/api/tag_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/tags`.
///
/// Listing **requires** an `entity_type` query param (`task` / `project`);
/// callers pass it via `list(filters: {'entity_type': ...})`. Tags aren't
/// paginated/browsable in the generic sense — [TagRepository.refreshAll]
/// fetches both entity types. Mutations (create/update/delete/archive/
/// restore) flow through the inherited generic methods.
class TagsApi extends BaseEntityApi<TagListApi, TagItemApi> {
  TagsApi(super.client);

  @override
  String get basePath => '/api/v1/tags';

  @override
  TagListApi parseList(Object json) =>
      TagListApi.fromJson(json as Map<String, dynamic>);

  @override
  TagItemApi parseItem(Object json) =>
      TagItemApi.fromJson(json as Map<String, dynamic>);
}
