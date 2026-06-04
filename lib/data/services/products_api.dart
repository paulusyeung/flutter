import 'package:admin/data/services/upload_source.dart';

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

  /// Upload a document attachment to a product. Returns the refreshed
  /// product envelope. Mirrors `CompaniesApi.uploadDocument` /
  /// `ClientsApi.uploadDocument` — same multipart field name.
  Future<ProductApi> uploadDocument({
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
