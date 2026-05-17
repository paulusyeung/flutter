import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_item_api_model.freezed.dart';
part 'schedule_item_api_model.g.dart';

/// One row of an invoice's *displayed* payment schedule — the shape the
/// server embeds under `invoice.schedule[]` when the invoice is fetched
/// with `?show_schedule=true`. Distinct from `ScheduleParamsRow` (the
/// `parameters.schedule[]` *write* shape on a Schedule resource): this is
/// the read-only projection React renders (`ScheduleItem` in
/// `react/src/common/interfaces/schedule.ts`).
@freezed
abstract class ScheduleItemApi with _$ScheduleItemApi {
  const factory ScheduleItemApi({
    @Default('') String date,
    @Default('') String amount,
    @JsonKey(name: 'auto_bill') @Default(false) bool autoBill,
  }) = _ScheduleItemApi;

  factory ScheduleItemApi.fromJson(Map<String, dynamic> json) =>
      _$ScheduleItemApiFromJson(json);
}
