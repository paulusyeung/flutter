// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContactApi _$ContactApiFromJson(Map<String, dynamic> json) => _ContactApi(
  id: json['id'] as String? ?? '',
  firstName: json['first_name'] as String? ?? '',
  lastName: json['last_name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  isPrimary: json['is_primary'] as bool? ?? false,
  sendEmail: json['send_email'] as bool? ?? true,
  customValue1: json['custom_value1'] as String? ?? '',
  customValue2: json['custom_value2'] as String? ?? '',
  customValue3: json['custom_value3'] as String? ?? '',
  customValue4: json['custom_value4'] as String? ?? '',
  createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
  archivedAt: (json['archived_at'] as num?)?.toInt() ?? 0,
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$ContactApiToJson(_ContactApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'is_primary': instance.isPrimary,
      'send_email': instance.sendEmail,
      'custom_value1': instance.customValue1,
      'custom_value2': instance.customValue2,
      'custom_value3': instance.customValue3,
      'custom_value4': instance.customValue4,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'archived_at': instance.archivedAt,
      'is_deleted': instance.isDeleted,
    };
