import 'package:http/http.dart' as http;

import 'package:admin/data/models/api/project_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/projects`. The base class handles list/get/
/// create/update/delete/action; this subclass only supplies the path,
/// the parsers, and the multipart document upload that mirrors Client.
///
/// Named `ProjectsApi` (plural) to avoid collision with `ProjectApi` (the
/// single-resource model class in `data/models/api/project_api_model.dart`).
class ProjectsApi extends BaseEntityApi<ProjectListApi, ProjectItemApi> {
  ProjectsApi(super.client);

  @override
  String get basePath => '/api/v1/projects';

  @override
  ProjectListApi parseList(Object json) =>
      ProjectListApi.fromJson(json as Map<String, dynamic>);

  @override
  ProjectItemApi parseItem(Object json) =>
      ProjectItemApi.fromJson(json as Map<String, dynamic>);

  /// Upload a document attachment to a project. Returns the refreshed project
  /// envelope with the new document in its `documents` array. Mirrors
  /// `ClientsApi.uploadDocument` — same multipart field name.
  Future<ProjectApi> uploadDocument({
    required String entityId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('documents[]', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$entityId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object).data;
  }
}
