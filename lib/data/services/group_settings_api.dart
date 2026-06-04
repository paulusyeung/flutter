import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/data/services/upload_source.dart';

/// Concrete API for `/api/v1/group_settings`. The base class handles
/// list/get/create/update/delete/action; this subclass only supplies the
/// path and the parsers.
class GroupSettingsApi
    extends BaseEntityApi<GroupSettingListApi, GroupSettingItemApi> {
  GroupSettingsApi(super.client);

  @override
  String get basePath => '/api/v1/group_settings';

  @override
  GroupSettingListApi parseList(Object json) =>
      GroupSettingListApi.fromJson(json as Map<String, dynamic>);

  @override
  GroupSettingItemApi parseItem(Object json) =>
      GroupSettingItemApi.fromJson(json as Map<String, dynamic>);

  /// Upload a document attachment to a group. Returns the refreshed group
  /// envelope (now carrying `documents`). Mirrors `ProductsApi.uploadDocument`
  /// — `POST /group_settings/{id}/upload` with `_method=PUT`.
  Future<GroupSettingApi> uploadDocument({
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
