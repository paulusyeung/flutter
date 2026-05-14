import 'package:admin/data/models/api/company_gateway_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/company_gateways`. The base class handles list/
/// get/create/update/delete/action; this subclass only supplies the path and
/// the parsers.
///
/// Named `CompanyGatewaysApi` (plural) to avoid collision with `CompanyGatewayApi`
/// (the single-resource model class in
/// `data/models/api/company_gateway_api_model.dart`).
class CompanyGatewaysApi
    extends BaseEntityApi<CompanyGatewayListApi, CompanyGatewayItemApi> {
  CompanyGatewaysApi(super.client);

  @override
  String get basePath => '/api/v1/company_gateways';

  @override
  CompanyGatewayListApi parseList(Object json) =>
      CompanyGatewayListApi.fromJson(json as Map<String, dynamic>);

  @override
  CompanyGatewayItemApi parseItem(Object json) =>
      CompanyGatewayItemApi.fromJson(json as Map<String, dynamic>);
}
