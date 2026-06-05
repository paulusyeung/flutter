import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/invitation_api_model.dart';

part 'invitation.freezed.dart';

/// Bridges a billing doc (invoice / quote / credit / purchase_order) to a
/// specific client or vendor contact. Tracks the email/portal lifecycle:
/// sent → viewed → opened, plus any delivery error.
///
/// Dates stay as wire strings (ISO timestamps); the UI parses with
/// `DateTime.tryParse` at render time so we don't burn a `Decimal`-like
/// custom value type for fields the user only reads.
@freezed
abstract class Invitation with _$Invitation {
  const factory Invitation({
    @Default('') String id,
    @Default('') String key,
    @Default('') String link,
    @Default('') String clientContactId,
    @Default('') String vendorContactId,
    @Default('') String sentDate,
    @Default('') String viewedDate,
    @Default('') String openedDate,
    @Default('') String emailStatus,
    @Default('') String emailError,
    @Default('') String messageId,
  }) = _Invitation;

  factory Invitation.fromApi(InvitationApi a) => Invitation(
    id: a.id,
    key: a.key,
    link: a.link,
    clientContactId: a.clientContactId,
    vendorContactId: a.vendorContactId,
    sentDate: a.sentDate,
    viewedDate: a.viewedDate,
    openedDate: a.openedDate,
    emailStatus: a.emailStatus,
    emailError: a.emailError,
    messageId: a.messageId,
  );
}

extension InvitationAccessors on Invitation {
  /// Surfaces the per-invitation lifecycle status without round-tripping
  /// through the raw strings. Mirrors admin-portal
  /// `invitation_entity.dart` accessors.
  bool get hasBeenSent => sentDate.isNotEmpty;
  bool get hasBeenViewed => viewedDate.isNotEmpty;
  bool get hasBeenOpened => openedDate.isNotEmpty;
  bool get hasBounced => emailStatus == 'bounced';
  bool get hasError => emailStatus == 'error' || emailError.isNotEmpty;
}

extension InvitationPayload on Invitation {
  Map<String, dynamic> toApiJson() => <String, dynamic>{
    if (id.isNotEmpty) 'id': id,
    if (clientContactId.isNotEmpty) 'client_contact_id': clientContactId,
    if (vendorContactId.isNotEmpty) 'vendor_contact_id': vendorContactId,
  };
}

extension InvitationClone on Invitation {
  /// An invitation copy suitable for a *cloned* billing doc: preserves the
  /// recipient (the contact ids) but drops every per-send lifecycle field —
  /// the server `id`/`key`/portal `link`, the sent/viewed/opened dates, and
  /// the delivery status/error/`messageId`. Without this a clone inherits the
  /// source's sent/viewed/bounced state (e.g. a bounce badge or a vendor-portal
  /// link pointing at the original doc) onto a brand-new draft.
  Invitation freshClone() => Invitation(
    clientContactId: clientContactId,
    vendorContactId: vendorContactId,
  );
}
