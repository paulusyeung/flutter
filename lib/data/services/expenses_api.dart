import 'package:http/http.dart' as http;

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

  /// Upload a document attachment to an expense. Returns the refreshed
  /// expense envelope with the new document in its `documents` array.
  /// Mirrors `ProjectsApi.uploadDocument` — same multipart field name.
  Future<ExpenseItemApi> uploadDocument({
    required String expenseId,
    required String filePath,
    required String idempotencyKey,
  }) async {
    final file = await http.MultipartFile.fromPath('documents[]', filePath);
    final raw = await client.uploadMultipart(
      path: '$basePath/$expenseId/upload',
      fields: const {'_method': 'POST'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }
}
