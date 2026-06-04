import 'package:admin/data/services/upload_source.dart';

import 'package:admin/data/models/api/expense_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/expenses`. The base class handles list/get/
/// create/update/delete/action; this subclass only supplies the path, the
/// parsers, and the multipart document upload that mirrors Project.
///
/// Named `ExpensesApi` (plural) to avoid collision with `ExpenseApi` (the
/// single-resource model class in `data/models/api/expense_api_model.dart`).
class ExpensesApi extends BaseEntityApi<ExpenseListApi, ExpenseItemApi> {
  ExpensesApi(super.client);

  @override
  String get basePath => '/api/v1/expenses';

  @override
  ExpenseListApi parseList(Object json) =>
      ExpenseListApi.fromJson(json as Map<String, dynamic>);

  @override
  ExpenseItemApi parseItem(Object json) =>
      ExpenseItemApi.fromJson(json as Map<String, dynamic>);

  /// `POST /api/v1/expenses/{id}/template` — apply a design or email
  /// template. Payload carries `template_id`. Mirrors
  /// `InvoicesApi.runTemplate`.
  Future<ExpenseItemApi?> runTemplate({
    required String id,
    required String templateId,
    required String idempotencyKey,
  }) => action(
    id: id,
    action: 'template',
    idempotencyKey: idempotencyKey,
    payload: {'template_id': templateId},
  );

  /// Upload a document attachment to an expense. Returns the refreshed
  /// expense envelope with the new document in its `documents` array.
  /// Mirrors `ProjectsApi.uploadDocument` — same multipart field name.
  Future<ExpenseApi> uploadDocument({
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
