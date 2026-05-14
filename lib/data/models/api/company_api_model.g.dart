// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanyApi _$CompanyApiFromJson(Map<String, dynamic> json) => _CompanyApi(
  id: json['id'] as String? ?? '',
  displayName: json['display_name'] as String? ?? '',
  name: json['name'] as String? ?? '',
  companyKey: json['company_key'] as String? ?? '',
  sizeId: json['size_id'] as String? ?? '',
  industryId: json['industry_id'] as String? ?? '',
  firstMonthOfYear: json['first_month_of_year'] as String? ?? '',
  firstDayOfWeek: json['first_day_of_week'] as String? ?? '',
  enabledModules: (json['enabled_modules'] as num?)?.toInt() ?? 0,
  legalEntityId: (json['legal_entity_id'] as num?)?.toInt() ?? 0,
  subdomain: json['subdomain'] as String? ?? '',
  portalDomain: json['portal_domain'] as String? ?? '',
  portalMode: json['portal_mode'] as String? ?? '',
  customFields:
      (json['custom_fields'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
  settings:
      json['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  documents:
      (json['documents'] as List<dynamic>?)
          ?.map((e) => DocumentApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DocumentApi>[],
  updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
  archivedAt: (json['archived_at'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CompanyApiToJson(_CompanyApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'name': instance.name,
      'company_key': instance.companyKey,
      'size_id': instance.sizeId,
      'industry_id': instance.industryId,
      'first_month_of_year': instance.firstMonthOfYear,
      'first_day_of_week': instance.firstDayOfWeek,
      'enabled_modules': instance.enabledModules,
      'legal_entity_id': instance.legalEntityId,
      'subdomain': instance.subdomain,
      'portal_domain': instance.portalDomain,
      'portal_mode': instance.portalMode,
      'custom_fields': instance.customFields,
      'settings': instance.settings,
      'documents': instance.documents,
      'updated_at': instance.updatedAt,
      'archived_at': instance.archivedAt,
    };

_DocumentApi _$DocumentApiFromJson(Map<String, dynamic> json) => _DocumentApi(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  hash: json['hash'] as String? ?? '',
  type: json['type'] as String? ?? '',
  url: json['url'] as String? ?? '',
  size: (json['size'] as num?)?.toInt() ?? 0,
  isPublic: json['is_public'] as bool? ?? true,
  createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DocumentApiToJson(_DocumentApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hash': instance.hash,
      'type': instance.type,
      'url': instance.url,
      'size': instance.size,
      'is_public': instance.isPublic,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

_CompanyItemApi _$CompanyItemApiFromJson(Map<String, dynamic> json) =>
    _CompanyItemApi(
      data: CompanyApi.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CompanyItemApiToJson(_CompanyItemApi instance) =>
    <String, dynamic>{'data': instance.data};
