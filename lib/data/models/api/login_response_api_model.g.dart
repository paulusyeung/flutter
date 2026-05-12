// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginResponseApi _$LoginResponseApiFromJson(Map<String, dynamic> json) =>
    _LoginResponseApi(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => UserCompanyApi.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <UserCompanyApi>[],
      staticData:
          json['static'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$LoginResponseApiToJson(_LoginResponseApi instance) =>
    <String, dynamic>{'data': instance.data, 'static': instance.staticData};

_UserCompanyApi _$UserCompanyApiFromJson(
  Map<String, dynamic> json,
) => _UserCompanyApi(
  isAdmin: json['is_admin'] as bool? ?? false,
  isOwner: json['is_owner'] as bool? ?? false,
  permissions: json['permissions'] as String? ?? '',
  permissionsUpdatedAt: (json['permissions_updated_at'] as num?)?.toInt() ?? 0,
  company: CompanyEnvelopeApi.fromJson(json['company'] as Map<String, dynamic>),
  token: TokenApi.fromJson(json['token'] as Map<String, dynamic>),
  account: AccountEnvelopeApi.fromJson(json['account'] as Map<String, dynamic>),
  settings:
      json['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  user: json['user'] == null
      ? const UserSummaryApi()
      : UserSummaryApi.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserCompanyApiToJson(_UserCompanyApi instance) =>
    <String, dynamic>{
      'is_admin': instance.isAdmin,
      'is_owner': instance.isOwner,
      'permissions': instance.permissions,
      'permissions_updated_at': instance.permissionsUpdatedAt,
      'company': instance.company,
      'token': instance.token,
      'account': instance.account,
      'settings': instance.settings,
      'user': instance.user,
    };

_UserSummaryApi _$UserSummaryApiFromJson(Map<String, dynamic> json) =>
    _UserSummaryApi(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      google2faSecret: json['google_2fa_secret'] == null
          ? false
          : _boolFromJson(json['google_2fa_secret']),
      verifiedPhoneNumber: json['verified_phone_number'] == null
          ? false
          : _boolFromJson(json['verified_phone_number']),
    );

Map<String, dynamic> _$UserSummaryApiToJson(_UserSummaryApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'phone': instance.phone,
      'google_2fa_secret': instance.google2faSecret,
      'verified_phone_number': instance.verifiedPhoneNumber,
    };

_CompanyEnvelopeApi _$CompanyEnvelopeApiFromJson(Map<String, dynamic> json) =>
    _CompanyEnvelopeApi(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      companyKey: json['company_key'] as String? ?? '',
      customFields:
          (json['custom_fields'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      sizeId: json['size_id'] as String? ?? '',
      industryId: json['industry_id'] as String? ?? '',
      legalEntityId: (json['legal_entity_id'] as num?)?.toInt() ?? 0,
      enabledModules: (json['enabled_modules'] as num?)?.toInt() ?? 0,
      settings:
          json['settings'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$CompanyEnvelopeApiToJson(_CompanyEnvelopeApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'name': instance.name,
      'company_key': instance.companyKey,
      'custom_fields': instance.customFields,
      'size_id': instance.sizeId,
      'industry_id': instance.industryId,
      'legal_entity_id': instance.legalEntityId,
      'enabled_modules': instance.enabledModules,
      'settings': instance.settings,
    };

_TokenApi _$TokenApiFromJson(Map<String, dynamic> json) => _TokenApi(
  token: json['token'] as String? ?? '',
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$TokenApiToJson(_TokenApi instance) => <String, dynamic>{
  'token': instance.token,
  'name': instance.name,
};

_AccountEnvelopeApi _$AccountEnvelopeApiFromJson(Map<String, dynamic> json) =>
    _AccountEnvelopeApi(
      id: json['id'] as String? ?? '',
      defaultCompanyId: json['default_company_id'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      numTrialDays: (json['num_trial_days'] as num?)?.toInt() ?? 0,
      hostedClientCount: (json['hosted_client_count'] as num?)?.toInt() ?? 0,
      hostedCompanyCount: (json['hosted_company_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AccountEnvelopeApiToJson(_AccountEnvelopeApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'default_company_id': instance.defaultCompanyId,
      'plan': instance.plan,
      'num_trial_days': instance.numTrialDays,
      'hosted_client_count': instance.hostedClientCount,
      'hosted_company_count': instance.hostedCompanyCount,
    };
