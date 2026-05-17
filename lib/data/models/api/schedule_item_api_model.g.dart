// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_item_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleItemApi _$ScheduleItemApiFromJson(Map<String, dynamic> json) =>
    _ScheduleItemApi(
      date: json['date'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      autoBill: json['auto_bill'] as bool? ?? false,
    );

Map<String, dynamic> _$ScheduleItemApiToJson(_ScheduleItemApi instance) =>
    <String, dynamic>{
      'date': instance.date,
      'amount': instance.amount,
      'auto_bill': instance.autoBill,
    };
