import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/email_history_api_model.dart';

part 'email_history.freezed.dart';

/// Clean domain shape for the client email-history feed
/// (`POST /api/v1/emails/clientHistory/{clientId}`). Read-only — never stored
/// in Drift, never written through the outbox; the ViewModel fetches it live.
///
/// Dates stay as wire strings (ISO timestamps); the UI formats at render time.
@freezed
abstract class EmailHistoryEvent with _$EmailHistoryEvent {
  const factory EmailHistoryEvent({
    @Default('') String date,
    @Default('') String deliveryMessage,
    @Default('') String recipient,
    @Default('') String server,
    @Default('') String serverIp,
    @Default('') String status,
    @Default('') String bounceId,
  }) = _EmailHistoryEvent;

  factory EmailHistoryEvent.fromApi(EmailHistoryEventApi a) =>
      EmailHistoryEvent(
        date: a.date,
        deliveryMessage: a.deliveryMessage,
        recipient: a.recipient,
        server: a.server,
        serverIp: a.serverIp,
        status: a.status,
        bounceId: a.bounceId,
      );
}

extension EmailHistoryEventAccessors on EmailHistoryEvent {
  /// A reactivatable bounce/spam event carries a Postmark `bounce_id`.
  bool get canReactivate => bounceId.isNotEmpty;
}

@freezed
abstract class EmailHistoryRecord with _$EmailHistoryRecord {
  const factory EmailHistoryRecord({
    @Default('') String entity,
    @Default('') String entityId,
    @Default('') String subject,
    @Default('') String recipients,
    @Default(<EmailHistoryEvent>[]) List<EmailHistoryEvent> events,
  }) = _EmailHistoryRecord;

  factory EmailHistoryRecord.fromApi(EmailHistoryRecordApi a) =>
      EmailHistoryRecord(
        entity: a.entity,
        entityId: a.entityId,
        subject: a.subject,
        recipients: a.recipients,
        events: a.events.map(EmailHistoryEvent.fromApi).toList(),
      );
}
