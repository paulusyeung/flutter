import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_history_api_model.freezed.dart';
part 'email_history_api_model.g.dart';

/// One delivery event inside an [EmailHistoryRecordApi]. Mirrors the React
/// client's `Event` interface returned by
/// `POST /api/v1/emails/clientHistory/{clientId}`.
///
/// `bounce_id` is the Postmark message id; it is non-empty only for bounced /
/// spam events and is the id fed to `POST /api/v1/reactivate_email/{id}`.
@freezed
abstract class EmailHistoryEventApi with _$EmailHistoryEventApi {
  const factory EmailHistoryEventApi({
    @Default('') String date,
    @JsonKey(name: 'delivery_message') @Default('') String deliveryMessage,
    @Default('') String recipient,
    @Default('') String server,
    @JsonKey(name: 'server_ip') @Default('') String serverIp,
    @Default('') String status,
    @JsonKey(name: 'bounce_id') @Default('') String bounceId,
  }) = _EmailHistoryEventApi;

  factory EmailHistoryEventApi.fromJson(Map<String, dynamic> json) =>
      _$EmailHistoryEventApiFromJson(json);
}

/// One sent email (per billing doc) with its delivery events. The endpoint
/// returns a bare JSON array of these — there is no `{data: [...]}` envelope,
/// so callers parse the list directly.
@freezed
abstract class EmailHistoryRecordApi with _$EmailHistoryRecordApi {
  const factory EmailHistoryRecordApi({
    @Default('') String entity,
    @JsonKey(name: 'entity_id') @Default('') String entityId,
    @Default('') String subject,
    @Default('') String recipients,
    @Default([]) List<EmailHistoryEventApi> events,
  }) = _EmailHistoryRecordApi;

  factory EmailHistoryRecordApi.fromJson(Map<String, dynamic> json) =>
      _$EmailHistoryRecordApiFromJson(json);
}
