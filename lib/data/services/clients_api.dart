import '../models/api/client_api_model.dart';
import 'base_entity_api.dart';

/// Concrete API for `/api/v1/clients`. The base class handles list/get/create/
/// update/delete/action; this subclass only supplies the path and the
/// parsers that lift `Map<String, dynamic>` into typed envelopes.
///
/// Named `ClientsApi` (plural) to avoid collision with `ClientApi` (the
/// single-resource model class in `data/models/api/client_api_model.dart`).
class ClientsApi extends BaseEntityApi<ClientListApi, ClientItemApi> {
  ClientsApi(super.client);

  @override
  String get basePath => '/api/v1/clients';

  @override
  ClientListApi parseList(Object json) =>
      ClientListApi.fromJson(json as Map<String, dynamic>);

  @override
  ClientItemApi parseItem(Object json) =>
      ClientItemApi.fromJson(json as Map<String, dynamic>);
}
