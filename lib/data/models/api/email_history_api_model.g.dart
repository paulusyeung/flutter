// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_history_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmailHistoryEventApi _$EmailHistoryEventApiFromJson(
  Map<String, dynamic> json,
) => _EmailHistoryEventApi(
  date: json['date'] as String? ?? '',
  deliveryMessage: json['delivery_message'] as String? ?? '',
  recipient: json['recipient'] as String? ?? '',
  server: json['server'] as String? ?? '',
  serverIp: json['server_ip'] as String? ?? '',
  status: json['status'] as String? ?? '',
  bounceId: json['bounce_id'] as String? ?? '',
);

Map<String, dynamic> _$EmailHistoryEventApiToJson(
  _EmailHistoryEventApi instance,
) => <String, dynamic>{
  'date': instance.date,
  'delivery_message': instance.deliveryMessage,
  'recipient': instance.recipient,
  'server': instance.server,
  'server_ip': instance.serverIp,
  'status': instance.status,
  'bounce_id': instance.bounceId,
};

_EmailHistoryRecordApi _$EmailHistoryRecordApiFromJson(
  Map<String, dynamic> json,
) => _EmailHistoryRecordApi(
  entity: json['entity'] as String? ?? '',
  entityId: json['entity_id'] as String? ?? '',
  subject: json['subject'] as String? ?? '',
  recipients: json['recipients'] as String? ?? '',
  events:
      (json['events'] as List<dynamic>?)
          ?.map((e) => EmailHistoryEventApi.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$EmailHistoryRecordApiToJson(
  _EmailHistoryRecordApi instance,
) => <String, dynamic>{
  'entity': instance.entity,
  'entity_id': instance.entityId,
  'subject': instance.subject,
  'recipients': instance.recipients,
  'events': instance.events,
};
