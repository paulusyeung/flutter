// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_config_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaxConfigApi _$TaxConfigApiFromJson(Map<String, dynamic> json) =>
    _TaxConfigApi(
      version: json['version'] as String? ?? '',
      sellerSubregion: json['seller_subregion'] as String? ?? '',
      actsAsSender: json['acts_as_sender'] as bool? ?? false,
      actsAsReceiver: json['acts_as_receiver'] as bool? ?? false,
      regions:
          (json['regions'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, TaxRegionApi.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, TaxRegionApi>{},
    );

Map<String, dynamic> _$TaxConfigApiToJson(_TaxConfigApi instance) =>
    <String, dynamic>{
      'version': instance.version,
      'seller_subregion': instance.sellerSubregion,
      'acts_as_sender': instance.actsAsSender,
      'acts_as_receiver': instance.actsAsReceiver,
      'regions': instance.regions,
    };

_TaxRegionApi _$TaxRegionApiFromJson(
  Map<String, dynamic> json,
) => _TaxRegionApi(
  taxAllSubregions: json['tax_all_subregions'] as bool? ?? false,
  taxThreshold: (json['tax_threshold'] as num?)?.toDouble() ?? 0.0,
  hasSalesAboveThreshold: json['has_sales_above_threshold'] as bool? ?? false,
  subregions:
      (json['subregions'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, TaxSubregionApi.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, TaxSubregionApi>{},
);

Map<String, dynamic> _$TaxRegionApiToJson(_TaxRegionApi instance) =>
    <String, dynamic>{
      'tax_all_subregions': instance.taxAllSubregions,
      'tax_threshold': instance.taxThreshold,
      'has_sales_above_threshold': instance.hasSalesAboveThreshold,
      'subregions': instance.subregions,
    };

_TaxSubregionApi _$TaxSubregionApiFromJson(Map<String, dynamic> json) =>
    _TaxSubregionApi(
      applyTax: json['apply_tax'] as bool? ?? false,
      taxName: json['tax_name'] as String? ?? '',
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      reducedTaxRate: (json['reduced_tax_rate'] as num?)?.toDouble() ?? 0.0,
      vatNumber: json['vat_number'] as String? ?? '',
    );

Map<String, dynamic> _$TaxSubregionApiToJson(_TaxSubregionApi instance) =>
    <String, dynamic>{
      'apply_tax': instance.applyTax,
      'tax_name': instance.taxName,
      'tax_rate': instance.taxRate,
      'reduced_tax_rate': instance.reducedTaxRate,
      'vat_number': instance.vatNumber,
    };
