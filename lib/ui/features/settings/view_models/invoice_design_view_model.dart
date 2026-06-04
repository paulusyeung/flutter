import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Company-scoped state holder for the Invoice Design settings page.
///
/// Pure subclass of [SettingsDraftViewModel] for the lifecycle (load, watch,
/// dirty, reset, save), the override path, and the field-error plumbing — all
/// on the base. The client-scoped path uses [ClientSettingsDraftViewModel]
/// instead, exposed under the same [SettingsDraftHost] surface so the page's
/// body is scope-agnostic.
///
/// All fields written by this page sit on `company.settings.*`
/// (`invoice_design_id`, `page_layout`, `pdf_variables`, …), so the base VM's
/// `updateSettings` / `setOverride` paths cover every callsite.
///
/// Adds one knob beyond the base: the "Update all records" toggles. When a
/// document design (invoice / quote / credit / purchase_order) is changed and
/// the user ticks its toggle, [extraOutboxPayload] stashes a one-shot
/// `_design_updates` list onto the next save's outbox payload;
/// [CompanySyncDispatcher] pops it and fires a `POST /designs/set/default`
/// per entry after the settings PUT lands. Same precedent as Email Settings's
/// `_sync_send_time` ([EmailSettingsViewModel]).
class InvoiceDesignViewModel extends SettingsDraftViewModel {
  InvoiceDesignViewModel({required super.repo, required super.companyId});

  /// Document entities whose design supports the "Update all records" retro
  /// apply (mirrors React / admin-portal — the four required pickers only).
  static const _designEntities = <String>[
    'invoice',
    'quote',
    'credit',
    'purchase_order',
  ];

  /// entity → "also apply to existing records on next save" one-shot flag.
  /// Set by the inline toggle; read in [extraOutboxPayload]; cleared by
  /// [save]. Not part of the draft, so it never touches the Drift snapshot
  /// or the dirty flag.
  final Map<String, bool> _updateAll = {};

  bool updateAll(String entity) => _updateAll[entity] ?? false;

  void setUpdateAll(String entity, bool value) => _updateAll[entity] = value;

  /// The `settings.*_design_id` key for a given document entity.
  static String? _designIdFor(CompanySettings s, String entity) =>
      switch (entity) {
        'invoice' => s.invoiceDesignId,
        'quote' => s.quoteDesignId,
        'credit' => s.creditDesignId,
        'purchase_order' => s.purchaseOrderDesignId,
        _ => null,
      };

  @override
  Map<String, dynamic>? extraOutboxPayload() {
    final now = settings;
    final was = initialSettings;
    final updates = <Map<String, dynamic>>[];
    for (final entity in _designEntities) {
      if (!(_updateAll[entity] ?? false)) continue;
      final id = _designIdFor(now, entity);
      // Fire only when the design actually changed from the loaded baseline
      // (belt-and-suspenders against a stale toggle whose design was reverted),
      // and never for an unsynced offline-create id (`tmp_…`) — the server's
      // `/designs/set/default` 400s on an id it doesn't know yet.
      if (id == null ||
          id.isEmpty ||
          id.startsWith('tmp_') ||
          id == _designIdFor(was, entity)) {
        continue;
      }
      updates.add({'design_id': id, 'entity': entity});
    }
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
    _updateAll.clear();
  }
}
