// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchResultApi _$SearchResultApiFromJson(Map<String, dynamic> json) =>
    _SearchResultApi(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );

Map<String, dynamic> _$SearchResultApiToJson(_SearchResultApi instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'id': instance.id,
      'path': instance.path,
    };
