import 'package:admin/data/models/api/product_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/products`. The base class handles list/get/
/// create/update/delete/action; this subclass only supplies the path and
/// the parsers that lift `Map<String, dynamic>` into typed envelopes.
class ProductsApi extends BaseEntityApi<ProductListApi, ProductItemApi> {
  ProductsApi(super.client);

  @override
  String get basePath => '/api/v1/products';

  @override
  ProductListApi parseList(Object json) =>
      ProductListApi.fromJson(json as Map<String, dynamic>);

  @override
  ProductItemApi parseItem(Object json) =>
      ProductItemApi.fromJson(json as Map<String, dynamic>);
}
