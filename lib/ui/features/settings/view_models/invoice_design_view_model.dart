import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/features/settings/view_models/design_update_all_mixin.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Company-scoped state holder for the Invoice Design settings page.
///
/// Pure subclass of [SettingsDraftViewModel] for the lifecycle (load, watch,
/// dirty, reset, save), the override path, and the field-error plumbing — all
/// on the base. The client/group-scoped path uses
/// `ClientSettingsDraftViewModel` / `GroupSettingsDraftViewModel` instead,
/// exposed under the same [SettingsDraftHost] surface so the page's body is
/// scope-agnostic.
///
/// All fields written by this page sit on `company.settings.*`
/// (`invoice_design_id`, `page_layout`, `pdf_variables`, …), so the base VM's
/// `updateSettings` / `setOverride` paths cover every callsite.
///
/// Adds one knob beyond the base: the "Update all records" toggles, shared via
/// [DesignUpdateAllMixin]. When a document design is changed and the user ticks
/// its toggle, [extraOutboxPayload] stashes a one-shot `_design_updates` list
/// onto the next save's outbox payload; [CompanySyncDispatcher] pops it and
/// fires a `POST /designs/set/default` per entry after the settings PUT lands.
/// (Client/group scope routes the same directives through dedicated
/// `setDefaultDesign` outbox rows instead — see the cascade VMs.) Same
/// precedent as Email Settings's `_sync_send_time`.
class InvoiceDesignViewModel extends SettingsDraftViewModel
    with DesignUpdateAllMixin {
  InvoiceDesignViewModel({required super.repo, required super.companyId});

  @override
  Map<String, dynamic>? extraOutboxPayload() {
    final updates = changedDesignUpdates();
    return updates.isEmpty ? null : {'_design_updates': updates};
  }

  @override
  void onSaveSuccess(Company saved) {
    // Clear the one-shot flags only on a *successful* save (the base has
    // already advanced the baseline). Clearing in a `finally` would zero the
    // flags after a failed save too, leaving the still-mounted toggle checkbox
    // ticked but inert — so a retry wouldn't re-fire. On success the toggle
    // unmounts anyway (design now equals baseline), so a fresh later change
    // starts unticked.
    clearUpdateAll();
  }
}
