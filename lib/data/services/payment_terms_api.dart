import 'package:admin/data/models/api/payment_term_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/payment_terms`. Standard CRUD only — payment
/// terms have no `/sort` endpoint (the dropdown orders by `num_days`).
class PaymentTermsApi
    extends BaseEntityApi<PaymentTermListApi, PaymentTermItemApi> {
  PaymentTermsApi(super.client);

  @override
  String get basePath => '/api/v1/payment_terms';

  @override
  PaymentTermListApi parseList(Object json) =>
      PaymentTermListApi.fromJson(json as Map<String, dynamic>);

  @override
  PaymentTermItemApi parseItem(Object json) =>
      PaymentTermItemApi.fromJson(json as Map<String, dynamic>);
}
