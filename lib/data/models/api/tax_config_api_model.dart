import 'package:freezed_annotation/freezed_annotation.dart';

part 'tax_config_api_model.freezed.dart';
part 'tax_config_api_model.g.dart';

/// Wire shape of the company `tax_data` blob — the live config edited from
/// Settings → Tax Settings → Calculate Taxes. Mirrors the legacy
/// `TaxConfigEntity` (admin-portal `tax_model.dart`) and the React
/// `tax_data` interface.
///
/// `origin_tax_data` (the geo-snapshot legacy `TaxDataEntity`) is a separate
/// server field; we don't model it — it round-trips through the raw company
/// settings map.
@freezed
abstract class TaxConfigApi with _$TaxConfigApi {
  @JsonSerializable(includeIfNull: false)
  const factory TaxConfigApi({
    @Default('') String version,
    @JsonKey(name: 'seller_subregion') @Default('') String sellerSubregion,
    @JsonKey(name: 'acts_as_sender') @Default(false) bool actsAsSender,
    @JsonKey(name: 'acts_as_receiver') @Default(false) bool actsAsReceiver,
    @Default(<String, TaxRegionApi>{}) Map<String, TaxRegionApi> regions,
  }) = _TaxConfigApi;

  factory TaxConfigApi.fromJson(Map<String, dynamic> json) =>
      _$TaxConfigApiFromJson(json);
}

@freezed
abstract class TaxRegionApi with _$TaxRegionApi {
  @JsonSerializable(includeIfNull: false)
  const factory TaxRegionApi({
    @JsonKey(name: 'tax_all_subregions') @Default(false) bool taxAllSubregions,
    @JsonKey(name: 'tax_threshold') @Default(0.0) double taxThreshold,
    @JsonKey(name: 'has_sales_above_threshold')
    @Default(false)
    bool hasSalesAboveThreshold,
    @Default(<String, TaxSubregionApi>{})
    Map<String, TaxSubregionApi> subregions,
  }) = _TaxRegionApi;

  factory TaxRegionApi.fromJson(Map<String, dynamic> json) =>
      _$TaxRegionApiFromJson(json);
}

@freezed
abstract class TaxSubregionApi with _$TaxSubregionApi {
  @JsonSerializable(includeIfNull: false)
  const factory TaxSubregionApi({
    @JsonKey(name: 'apply_tax') @Default(false) bool applyTax,
    @JsonKey(name: 'tax_name') @Default('') String taxName,
    @JsonKey(name: 'tax_rate') @Default(0.0) double taxRate,
    @JsonKey(name: 'reduced_tax_rate') @Default(0.0) double reducedTaxRate,
    @JsonKey(name: 'vat_number') @Default('') String vatNumber,
  }) = _TaxSubregionApi;

  factory TaxSubregionApi.fromJson(Map<String, dynamic> json) =>
      _$TaxSubregionApiFromJson(json);
}
