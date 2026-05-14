import 'package:admin/data/models/api/tax_rate_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/tax_rates`. Standard CRUD only. The dropdown on
/// Settings → Tax Settings reads from Drift; the underlying rows arrive
/// bundled via `/refresh?first_load=true`.
class TaxRatesApi extends BaseEntityApi<TaxRateListApi, TaxRateItemApi> {
  TaxRatesApi(super.client);

  @override
  String get basePath => '/api/v1/tax_rates';

  @override
  TaxRateListApi parseList(Object json) =>
      TaxRateListApi.fromJson(json as Map<String, dynamic>);

  @override
  TaxRateItemApi parseItem(Object json) =>
      TaxRateItemApi.fromJson(json as Map<String, dynamic>);
}
