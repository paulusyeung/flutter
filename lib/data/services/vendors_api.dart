import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/vendor_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/vendors`. The base class handles
/// list/get/create/update/delete/action; this subclass only supplies the
/// path and the parsers that lift `Map<String, dynamic>` into typed
/// envelopes.
///
/// Named `VendorsApi` (plural) to avoid collision with `VendorApi` (the
/// single-resource model class in `data/models/api/vendor_api_model.dart`).
class VendorsApi extends BaseEntityApi<VendorListApi, VendorItemApi> {
  VendorsApi(super.client);

  @override
  String get basePath => '/api/v1/vendors';

  @override
  VendorListApi parseList(Object json) =>
      VendorListApi.fromJson(json as Map<String, dynamic>);

  @override
  VendorItemApi parseItem(Object json) =>
      VendorItemApi.fromJson(json as Map<String, dynamic>);

  /// Upload a document attachment to a vendor. Returns the refreshed vendor
  /// envelope with the new document in its `documents` array. Mirrors the
  /// `ClientsApi.uploadDocument` shape — same multipart field name.
  Future<VendorItemApi> uploadDocument({
    required String vendorId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('documents[]', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$vendorId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }
}
