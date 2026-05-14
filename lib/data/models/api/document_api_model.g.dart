// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
