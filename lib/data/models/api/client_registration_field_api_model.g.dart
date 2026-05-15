// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_registration_field_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClientRegistrationFieldApi _$ClientRegistrationFieldApiFromJson(
  Map<String, dynamic> json,
) => _ClientRegistrationFieldApi(
  key: json['key'] as String? ?? '',
  required: json['required'] as bool? ?? false,
  visible: json['visible'] as bool? ?? true,
);

Map<String, dynamic> _$ClientRegistrationFieldApiToJson(
  _ClientRegistrationFieldApi instance,
) => <String, dynamic>{
  'key': instance.key,
  'required': instance.required,
  'visible': instance.visible,
};
