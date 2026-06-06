import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/features/billing_shared/view_models/billing_doc_edit_view_model.dart';

/// Auto-check a client's contacts when a billing doc (Invoice / Quote /
/// Credit / RecurringInvoice) is created with the client already chosen.
///
/// Creating "New X" for a client reaches the edit screen as a draft with the
/// client set but no invitations — whether the clientId arrived via `?client=`
/// (Clients list ⋮, synthesized into the draft in `buildVm`) or via `extra:`
/// (embedded Invoices/Quotes/… tab). The client dropdown's `onChanged` never
/// fires, so [GenericBillingDocEditViewModel.selectClient] (which seeds
/// invitations) is never called and the contacts stay unchecked. This resolves
/// the client from Drift and seeds invitations to match what picking the client
/// in the dropdown would have produced.
///
/// No-op when there is no client, the client isn't cached, or the draft
/// already carries invitations (e.g. a real clone, or the user has touched
/// the Contacts tab) — so it never clobbers an existing selection.
///
/// Deferred via [WidgetsBinding.addPostFrameCallback] so the scaffold's
/// listeners are attached before `notifyListeners` fires — same rationale as
/// the `?project=`/`?product=` prefill seeds in the edit screens (see the
/// trace comment in `invoice_edit_screen.dart`).
void seedClientInvitationsFromPrefill<T>({
  required Services services,
  required String companyId,
  required GenericBillingDocEditViewModel<T> vm,
}) {
  if (vm.clientId.isEmpty || vm.hasInvitations) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      services.clients
          .watch(companyId: companyId, id: vm.clientId)
          .first
          .then((client) {
            if (client == null) return;
            vm.seedClientInvitationsIfEmpty(client.contacts);
          })
          .catchError((Object _) {}),
    );
  });
}
