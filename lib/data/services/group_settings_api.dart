import 'package:admin/data/models/api/group_setting_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

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
}
