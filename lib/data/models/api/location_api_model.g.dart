// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocationApi _$LocationApiFromJson(Map<String, dynamic> json) => _LocationApi(
  id: json['id'] as String? ?? '',
  userId: json['user_id'] as String? ?? '',
  vendorId: json['vendor_id'] as String? ?? '',
  clientId: json['client_id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  address1: json['address1'] as String? ?? '',
  address2: json['address2'] as String? ?? '',
  city: json['city'] as String? ?? '',
  state: json['state'] as String? ?? '',
  postalCode: json['postal_code'] as String? ?? '',
  countryId: json['country_id'] as String? ?? '',
  customValue1: json['custom_value1'] as String? ?? '',
  customValue2: json['custom_value2'] as String? ?? '',
  customValue3: json['custom_value3'] as String? ?? '',
  customValue4: json['custom_value4'] as String? ?? '',
  isShippingLocation: json['is_shipping_location'] as bool? ?? false,
  createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
  archivedAt: (json['archived_at'] as num?)?.toInt() ?? 0,
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$LocationApiToJson(_LocationApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'vendor_id': instance.vendorId,
      'client_id': instance.clientId,
      'name': instance.name,
      'address1': instance.address1,
      'address2': instance.address2,
      'city': instance.city,
      'state': instance.state,
      'postal_code': instance.postalCode,
      'country_id': instance.countryId,
      'custom_value1': instance.customValue1,
      'custom_value2': instance.customValue2,
      'custom_value3': instance.customValue3,
      'custom_value4': instance.customValue4,
      'is_shipping_location': instance.isShippingLocation,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'archived_at': instance.archivedAt,
      'is_deleted': instance.isDeleted,
    };
