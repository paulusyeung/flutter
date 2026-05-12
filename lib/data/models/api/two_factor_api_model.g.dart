// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwoFactorSetupApi _$TwoFactorSetupApiFromJson(Map<String, dynamic> json) =>
    _TwoFactorSetupApi(
      qrCode: json['qrCode'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
    );

Map<String, dynamic> _$TwoFactorSetupApiToJson(_TwoFactorSetupApi instance) =>
    <String, dynamic>{'qrCode': instance.qrCode, 'secret': instance.secret};
