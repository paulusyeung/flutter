import 'package:admin/data/models/api/design_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/designs`. No reorder endpoint; designs are
/// ordered alphabetically by name.
class DesignsApi extends BaseEntityApi<DesignListApi, DesignItemApi> {
  DesignsApi(super.client);

  @override
  String get basePath => '/api/v1/designs';

  @override
  DesignListApi parseList(Object json) =>
      DesignListApi.fromJson(json as Map<String, dynamic>);

  @override
  DesignItemApi parseItem(Object json) =>
      DesignItemApi.fromJson(json as Map<String, dynamic>);
}
