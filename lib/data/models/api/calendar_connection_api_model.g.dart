// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_connection_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarConnection _$CalendarConnectionFromJson(Map<String, dynamic> json) =>
    _CalendarConnection(
      connected: json['connected'] as bool? ?? false,
      provider: json['provider'] as String?,
      email: json['email'] as String?,
      expiresAt: (json['expires_at'] as num?)?.toInt(),
      calendars:
          (json['calendars'] as List<dynamic>?)
              ?.map((e) => CalendarInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CalendarInfo>[],
    );

Map<String, dynamic> _$CalendarConnectionToJson(_CalendarConnection instance) =>
    <String, dynamic>{
      'connected': instance.connected,
      'provider': instance.provider,
      'email': instance.email,
      'expires_at': instance.expiresAt,
      'calendars': instance.calendars,
    };

_CalendarInfo _$CalendarInfoFromJson(Map<String, dynamic> json) =>
    _CalendarInfo(
      calendarId: json['calendar_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      primary: json['primary'] as bool? ?? false,
      writable: json['writable'] as bool? ?? false,
      selected: json['selected'] as bool? ?? false,
    );

Map<String, dynamic> _$CalendarInfoToJson(_CalendarInfo instance) =>
    <String, dynamic>{
      'calendar_id': instance.calendarId,
      'name': instance.name,
      'primary': instance.primary,
      'writable': instance.writable,
      'selected': instance.selected,
    };

_CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    _CalendarEvent(
      id: json['id'] as String? ?? '',
      calendarEventId: json['calendar_event_id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      providerEventId: json['provider_event_id'] as String? ?? '',
      calendarId: json['calendar_id'] as String? ?? '',
      calendarName: json['calendar_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      allDay: json['all_day'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      updated: json['updated'] as String? ?? '',
    );

Map<String, dynamic> _$CalendarEventToJson(_CalendarEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'calendar_event_id': instance.calendarEventId,
      'provider': instance.provider,
      'provider_event_id': instance.providerEventId,
      'calendar_id': instance.calendarId,
      'calendar_name': instance.calendarName,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'start': instance.start,
      'end': instance.end,
      'all_day': instance.allDay,
      'status': instance.status,
      'updated': instance.updated,
    };
