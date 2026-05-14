// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivityLabelApi _$ActivityLabelApiFromJson(Map<String, dynamic> json) =>
    _ActivityLabelApi(
      label: json['label'] as String? ?? '',
      hashedId: json['hashed_id'] as String? ?? '',
    );

Map<String, dynamic> _$ActivityLabelApiToJson(_ActivityLabelApi instance) =>
    <String, dynamic>{'label': instance.label, 'hashed_id': instance.hashedId};

_ActivityApi _$ActivityApiFromJson(Map<String, dynamic> json) => _ActivityApi(
  id: json['hashed_id'] as String? ?? '',
  activityTypeId: (json['activity_type_id'] as num?)?.toInt() ?? 0,
  notes: json['notes'] as String? ?? '',
  createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  ip: json['ip'] as String? ?? '',
  user: json['user'] == null
      ? null
      : ActivityLabelApi.fromJson(json['user'] as Map<String, dynamic>),
  client: json['client'] == null
      ? null
      : ActivityLabelApi.fromJson(json['client'] as Map<String, dynamic>),
  invoice: json['invoice'] == null
      ? null
      : ActivityLabelApi.fromJson(json['invoice'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ActivityApiToJson(_ActivityApi instance) =>
    <String, dynamic>{
      'hashed_id': instance.id,
      'activity_type_id': instance.activityTypeId,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'ip': instance.ip,
      'user': instance.user,
      'client': instance.client,
      'invoice': instance.invoice,
    };

_ActivityListApi _$ActivityListApiFromJson(Map<String, dynamic> json) =>
    _ActivityListApi(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => ActivityApi.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ActivityListApiToJson(_ActivityListApi instance) =>
    <String, dynamic>{'data': instance.data};
