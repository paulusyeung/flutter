// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gateway_token_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GatewayTokenApi _$GatewayTokenApiFromJson(Map<String, dynamic> json) =>
    _GatewayTokenApi(
      id: json['id'] as String? ?? '',
      companyGatewayId: json['company_gateway_id'] as String? ?? '',
      gatewayTypeId: json['gateway_type_id'] as String? ?? '',
      gatewayCustomerReference:
          json['gateway_customer_reference'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      meta: json['meta'] as Map<String, dynamic>?,
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      archivedAt: (json['archived_at'] as num?)?.toInt() ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$GatewayTokenApiToJson(_GatewayTokenApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_gateway_id': instance.companyGatewayId,
      'gateway_type_id': instance.gatewayTypeId,
      'gateway_customer_reference': instance.gatewayCustomerReference,
      'is_default': instance.isDefault,
      'meta': instance.meta,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'archived_at': instance.archivedAt,
      'is_deleted': instance.isDeleted,
    };
