import 'package:admin/data/services/emails_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// The [MutationKind.reactivateEmail] dispatcher, identical across every
/// entity that can trigger a bounce reactivation (Client's Email-History tab,
/// the billing docs' Sends tab). Spread into [wireEntity]'s `customActions`
/// so any owning entity's outbox row drains through the same closure.
///
/// `POST /api/v1/reactivate_email/{message_id}` returns no entity payload we
/// apply locally — the suppression clears server-side and the bounce
/// indicator refreshes on the owning entity's next sync. Fire-and-forget:
/// the handler returns `null`.
Map<MutationKind, CustomMutationHandler<TInner>>
reactivateEmailHandlers<TInner>(EmailsApi emailsApi) {
  return {
    MutationKind.reactivateEmail: ({required row, required payload}) async {
      await emailsApi.reactivateEmail(
        messageId: payload['message_id'] as String,
        idempotencyKey: row.idempotencyKey,
      );
      return null;
    },
  };
}
