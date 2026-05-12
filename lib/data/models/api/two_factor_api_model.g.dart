// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TwoFactorSetupApiImpl _$$TwoFactorSetupApiImplFromJson(
  Map<String, dynamic> json,
) => _$TwoFactorSetupApiImpl(
  qrCode: json['qrCode'] as String? ?? '',
  secret: json['secret'] as String? ?? '',
);

Map<String, dynamic> _$$TwoFactorSetupApiImplToJson(
  _$TwoFactorSetupApiImpl instance,
) => <String, dynamic>{'qrCode': instance.qrCode, 'secret': instance.secret};
