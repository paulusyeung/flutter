import 'package:freezed_annotation/freezed_annotation.dart';

part 'invitation_api_model.freezed.dart';
part 'invitation_api_model.g.dart';

/// Raw JSON shape of an invitation row nested inside an invoice / quote /
/// credit / purchase_order envelope. Bridges the billing doc to a specific
/// client (or vendor) contact for the email/portal flow.
///
/// `client_contact_id` and `vendor_contact_id` are mutually exclusive —
/// invoices/quotes/credits populate the client field, purchase orders use
/// the vendor field. The domain model carries both as nullable.
@freezed
abstract class InvitationApi with _$InvitationApi {
  const factory InvitationApi({
    @Default('') String id,
    @Default('') String key,
    @Default('') String link,
    @JsonKey(name: 'client_contact_id') @Default('') String clientContactId,
    @JsonKey(name: 'vendor_contact_id') @Default('') String vendorContactId,
    @JsonKey(name: 'sent_date') @Default('') String sentDate,
    @JsonKey(name: 'viewed_date') @Default('') String viewedDate,
    @JsonKey(name: 'opened_date') @Default('') String openedDate,
    @JsonKey(name: 'email_status') @Default('') String emailStatus,
    @JsonKey(name: 'email_error') @Default('') String emailError,
    @JsonKey(name: 'message_id') @Default('') String messageId,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
  }) = _InvitationApi;

  factory InvitationApi.fromJson(Map<String, dynamic> json) =>
      _$InvitationApiFromJson(json);
}
