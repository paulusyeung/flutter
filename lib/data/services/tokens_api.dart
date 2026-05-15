import 'package:admin/data/models/api/token_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/tokens`.
class TokensApi extends BaseEntityApi<TokenListApi, TokenItemApi> {
  TokensApi(super.client);

  @override
  String get basePath => '/api/v1/tokens';

  @override
  TokenListApi parseList(Object json) =>
      TokenListApi.fromJson(json as Map<String, dynamic>);

  @override
  TokenItemApi parseItem(Object json) =>
      TokenItemApi.fromJson(json as Map<String, dynamic>);
}
