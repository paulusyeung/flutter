// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoginResponseApiImpl _$$LoginResponseApiImplFromJson(
  Map<String, dynamic> json,
) => _$LoginResponseApiImpl(
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => UserCompanyApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <UserCompanyApi>[],
  staticData:
      json['static'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$$LoginResponseApiImplToJson(
  _$LoginResponseApiImpl instance,
) => <String, dynamic>{'data': instance.data, 'static': instance.staticData};

_$UserCompanyApiImpl _$$UserCompanyApiImplFromJson(
  Map<String, dynamic> json,
) => _$UserCompanyApiImpl(
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

Map<String, dynamic> _$$UserCompanyApiImplToJson(
  _$UserCompanyApiImpl instance,
) => <String, dynamic>{
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

_$UserSummaryApiImpl _$$UserSummaryApiImplFromJson(Map<String, dynamic> json) =>
    _$UserSummaryApiImpl(
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

Map<String, dynamic> _$$UserSummaryApiImplToJson(
  _$UserSummaryApiImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'phone': instance.phone,
  'google_2fa_secret': instance.google2faSecret,
  'verified_phone_number': instance.verifiedPhoneNumber,
};

_$CompanyEnvelopeApiImpl _$$CompanyEnvelopeApiImplFromJson(
  Map<String, dynamic> json,
) => _$CompanyEnvelopeApiImpl(
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
      json['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$$CompanyEnvelopeApiImplToJson(
  _$CompanyEnvelopeApiImpl instance,
) => <String, dynamic>{
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

_$TokenApiImpl _$$TokenApiImplFromJson(Map<String, dynamic> json) =>
    _$TokenApiImpl(
      token: json['token'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );

Map<String, dynamic> _$$TokenApiImplToJson(_$TokenApiImpl instance) =>
    <String, dynamic>{'token': instance.token, 'name': instance.name};

_$AccountEnvelopeApiImpl _$$AccountEnvelopeApiImplFromJson(
  Map<String, dynamic> json,
) => _$AccountEnvelopeApiImpl(
  id: json['id'] as String? ?? '',
  defaultCompanyId: json['default_company_id'] as String? ?? '',
  plan: json['plan'] as String? ?? '',
  numTrialDays: (json['num_trial_days'] as num?)?.toInt() ?? 0,
  hostedClientCount: (json['hosted_client_count'] as num?)?.toInt() ?? 0,
  hostedCompanyCount: (json['hosted_company_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$AccountEnvelopeApiImplToJson(
  _$AccountEnvelopeApiImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'default_company_id': instance.defaultCompanyId,
  'plan': instance.plan,
  'num_trial_days': instance.numTrialDays,
  'hosted_client_count': instance.hostedClientCount,
  'hosted_company_count': instance.hostedCompanyCount,
};
