import 'package:admin/data/models/api/bank_account_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/bank_integrations` (wire entity:
/// `bank_integration`; UI label "bank account"). The base class handles
/// list / get / create / update / delete / action; this subclass supplies
/// the path, the parsers, and the non-standard `refresh_accounts`
/// endpoint.
///
/// Named `BankAccountsApi` (plural) to avoid collision with `BankAccountApi`
/// (the single-resource model class in `data/models/api/...`).
class BankAccountsApi
    extends BaseEntityApi<BankAccountListApi, BankAccountItemApi> {
  BankAccountsApi(super.client);

  @override
  String get basePath => '/api/v1/bank_integrations';

  @override
  BankAccountListApi parseList(Object json) =>
      BankAccountListApi.fromJson(json as Map<String, dynamic>);

  @override
  BankAccountItemApi parseItem(Object json) =>
      BankAccountItemApi.fromJson(json as Map<String, dynamic>);

  /// `POST /api/v1/one_time_token` — mints a short-lived hash the client
  /// hands to the aggregator's hosted connect page (Yodlee / Nordigen).
  /// `context` is `'yodlee'` or `'nordigen'` (React parity). Online-only
  /// interactive flow (not an outbox mutation — you can't link a bank
  /// offline); demo-mode is correctly blocked by `postJson`.
  Future<String> oneTimeToken({required String context}) async {
    final raw = await client.postJson(
      '/api/v1/one_time_token',
      body: {'context': context, 'platform': 'flutter'},
    );
    if (raw is Map) {
      final data = raw['data'];
      if (data is Map && data['hash'] is String) {
        return data['hash'] as String;
      }
      if (raw['hash'] is String) return raw['hash'] as String;
    }
    throw const FormatException('one_time_token: no hash in response');
  }

  /// `POST /api/v1/bank_integrations/refresh_accounts` — pings the upstream
  /// providers (Yodlee/Nordigen) for the account list and pulls down any
  /// fresh balances. Returns the refreshed list envelope.
  Future<BankAccountListApi> refreshAccounts({
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '$basePath/refresh_accounts',
      idempotencyKey: idempotencyKey,
      body: const <String, dynamic>{},
    );
    return parseList(raw as Object);
  }
}
