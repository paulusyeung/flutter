// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DesignTemplateApi _$DesignTemplateApiFromJson(Map<String, dynamic> json) =>
    _DesignTemplateApi(
      body: json['body'] as String? ?? '',
      header: json['header'] as String? ?? '',
      footer: json['footer'] as String? ?? '',
      includes: json['includes'] as String? ?? '',
      product: json['product'] as String? ?? '',
      task: json['task'] as String? ?? '',
    );

Map<String, dynamic> _$DesignTemplateApiToJson(_DesignTemplateApi instance) =>
    <String, dynamic>{
      'body': instance.body,
      'header': instance.header,
      'footer': instance.footer,
      'includes': instance.includes,
      'product': instance.product,
      'task': instance.task,
    };

_DesignApi _$DesignApiFromJson(Map<String, dynamic> json) => _DesignApi(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  isCustom: json['is_custom'] as bool? ?? false,
  isActive: json['is_active'] as bool? ?? true,
  isTemplate: json['is_template'] as bool? ?? false,
  isFree: json['is_free'] as bool? ?? true,
  entities: json['entities'] as String? ?? '',
  design: json['design'] == null
      ? const DesignTemplateApi()
      : DesignTemplateApi.fromJson(json['design'] as Map<String, dynamic>),
  createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
  archivedAt: (json['archived_at'] as num?)?.toInt() ?? 0,
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$DesignApiToJson(_DesignApi instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_custom': instance.isCustom,
      'is_active': instance.isActive,
      'is_template': instance.isTemplate,
      'is_free': instance.isFree,
      'entities': instance.entities,
      'design': instance.design,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'archived_at': instance.archivedAt,
      'is_deleted': instance.isDeleted,
    };

_DesignListApi _$DesignListApiFromJson(Map<String, dynamic> json) =>
    _DesignListApi(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => DesignApi.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DesignApi>[],
    );

Map<String, dynamic> _$DesignListApiToJson(_DesignListApi instance) =>
    <String, dynamic>{'data': instance.data};

_DesignItemApi _$DesignItemApiFromJson(Map<String, dynamic> json) =>
    _DesignItemApi(
      data: DesignApi.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DesignItemApiToJson(_DesignItemApi instance) =>
    <String, dynamic>{'data': instance.data};
