import 'package:admin/data/models/api/bank_transaction_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/bank_transactions`. Adds the four `match`
/// variants and the two non-standard bulk actions
/// (`convert_matched`, `unlink`) on top of the base CRUD.
class BankTransactionsApi
    extends BaseEntityApi<BankTransactionListApi, BankTransactionItemApi> {
  BankTransactionsApi(super.client);

  @override
  String get basePath => '/api/v1/bank_transactions';

  @override
  BankTransactionListApi parseList(Object json) =>
      BankTransactionListApi.fromJson(json as Map<String, dynamic>);

  @override
  BankTransactionItemApi parseItem(Object json) =>
      BankTransactionItemApi.fromJson(json as Map<String, dynamic>);

  /// `POST /api/v1/bank_transactions/match` — match-action endpoint shared
  /// by four UI flows. The payload differs by direction + action:
  ///
  ///   * CREDIT, create payment from invoices: `{transactions: [{id,
  ///     invoice_ids: "id1,id2"}]}`
  ///   * CREDIT, link existing payment:        `{transactions: [{id,
  ///     payment_id}]}`
  ///   * DEBIT, create expense:                `{transactions: [{id,
  ///     vendor_id, ninja_category_id}]}`
  ///   * DEBIT, link existing expense:         `{transactions: [{id,
  ///     expense_id}]}`
  ///
  /// Returns the list envelope of updated transactions.
  Future<BankTransactionListApi> match({
    required List<Map<String, dynamic>> transactions,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '$basePath/match',
      idempotencyKey: idempotencyKey,
      body: {'transactions': transactions},
    );
    return parseList(raw as Object);
  }

  /// `POST /api/v1/bank_transactions/bulk` — non-standard bulk actions.
  /// `action` is one of `convert_matched` or `unlink` (the standard
  /// archive/restore/delete go through the registry's bulk plumbing).
  Future<BankTransactionListApi> bulkAction({
    required String action,
    required List<String> ids,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '$basePath/bulk',
      idempotencyKey: idempotencyKey,
      body: {'action': action, 'ids': ids},
    );
    return parseList(raw as Object);
  }
}
