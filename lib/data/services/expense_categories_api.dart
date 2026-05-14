import 'package:admin/data/models/api/expense_category_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/expense_categories`. No documents, no extra
/// actions — the entity is plain CRUD via the base class.
class ExpenseCategoriesApi
    extends BaseEntityApi<ExpenseCategoryListApi, ExpenseCategoryItemApi> {
  ExpenseCategoriesApi(super.client);

  @override
  String get basePath => '/api/v1/expense_categories';

  @override
  ExpenseCategoryListApi parseList(Object json) =>
      ExpenseCategoryListApi.fromJson(json as Map<String, dynamic>);

  @override
  ExpenseCategoryItemApi parseItem(Object json) =>
      ExpenseCategoryItemApi.fromJson(json as Map<String, dynamic>);
}
