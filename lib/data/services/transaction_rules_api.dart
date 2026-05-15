import 'package:admin/data/models/api/transaction_rule_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/bank_transaction_rules`. List and get fetches
/// always carry `include=vendor,expense_category` so the joined names land
/// in the DTO and the list page renders without a second fetch.
class TransactionRulesApi
    extends BaseEntityApi<TransactionRuleListApi, TransactionRuleItemApi> {
  TransactionRulesApi(super.client);

  @override
  String get basePath => '/api/v1/bank_transaction_rules';

  @override
  TransactionRuleListApi parseList(Object json) =>
      TransactionRuleListApi.fromJson(json as Map<String, dynamic>);

  @override
  TransactionRuleItemApi parseItem(Object json) =>
      TransactionRuleItemApi.fromJson(json as Map<String, dynamic>);

  /// Override get() to add `?include=vendor,expense_category` so the
  /// joined records arrive on detail fetches the same way they do on the
  /// list endpoint.
  @override
  Future<TransactionRuleItemApi> get(String id) async {
    final raw = await client.getOne(
      '$basePath/$id?include=vendor,expense_category',
    );
    return parseItem(raw as Object);
  }
}
