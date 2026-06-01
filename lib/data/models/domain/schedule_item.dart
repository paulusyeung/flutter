import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/schedule_item_api_model.dart';

part 'schedule_item.freezed.dart';

/// Read-only display row of an invoice's payment schedule
/// (`invoice.schedule[]`, present only with `?show_schedule=true`).
/// `amount` stays a `String` — it's a server-rendered display value, not a
/// money input the client computes with.
@freezed
abstract class ScheduleItem with _$ScheduleItem {
  const factory ScheduleItem({
    required String date,
    required String amount,
    required bool autoBill,
  }) = _ScheduleItem;

  factory ScheduleItem.fromApi(ScheduleItemApi a) =>
      ScheduleItem(date: a.date, amount: a.amount, autoBill: a.autoBill);
}

extension ScheduleItemCopy on ScheduleItem {
  /// Re-encode for the dedicated Drift column round-trip (the column is
  /// JSON-encoded `List<ScheduleItemApi>`; keys mirror the wire shape so
  /// `ScheduleItemApi.fromJson` reads it back).
  Map<String, dynamic> toApiJson() => {
    'date': date,
    'amount': amount,
    'auto_bill': autoBill,
  };
}
