import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';

/// Shared "Update all records" toggle state + change-detection for the Invoice
/// Design page's document-design pickers. Mixed into the company-scoped
/// `InvoiceDesignViewModel` and the cascade-scoped `ClientSettingsDraftViewModel`
/// / `GroupSettingsDraftViewModel` so the inline checkbox drives every scope
/// through one surface.
///
/// The toggle is one-shot and transient: it lives off the cascade draft so
/// ticking it never dirties the form or triggers a live-preview re-render.
/// Dispatch differs by scope — company piggybacks `{_design_updates}` onto the
/// company PUT via `extraOutboxPayload`; client/group enqueue a dedicated
/// `setDefaultDesign` outbox row per changed entity from their `save()`.
mixin DesignUpdateAllMixin on SettingsDraftHost {
  /// entity → "also apply to existing records on next save" one-shot flag.
  final Map<String, bool> _updateAll = {};

  /// Document entities offered an "Update all records" toggle. Purchase-order
  /// designs are company-scoped server-side (the `/designs/set/default`
  /// `purchase_order` arm ignores `settings_level`), so PO is offered at
  /// company scope only — never client/group ([isCascadeScope]).
  List<String> get designUpdateEntities => isCascadeScope
      ? const ['invoice', 'quote', 'credit']
      : const ['invoice', 'quote', 'credit', 'purchase_order'];

  bool updateAll(String entity) => _updateAll[entity] ?? false;
  void setUpdateAll(String entity, bool value) => _updateAll[entity] = value;

  /// One-shot reset — call after a successful save has dispatched the
  /// directives (or in `onSaveSuccess` at company scope).
  void clearUpdateAll() => _updateAll.clear();

  /// The `settings.*_design_id` key for a document entity.
  static String? designIdFor(CompanySettings s, String entity) =>
      switch (entity) {
        'invoice' => s.invoiceDesignId,
        'quote' => s.quoteDesignId,
        'credit' => s.creditDesignId,
        'purchase_order' => s.purchaseOrderDesignId,
        _ => null,
      };

  /// The ticked + actually-changed design directives as `{design_id, entity}`
  /// maps. Diffs the *own* draft ([draftSettings]) against [initialSettings]
  /// so it's correct at cascade scope — the merged [settings] would mask an
  /// inherited→explicit override as a phantom change. Skips empty / unsynced
  /// (`tmp_`) ids and unchanged entities; the server `/designs/set/default`
  /// 400s on a design id it doesn't know yet.
  List<Map<String, dynamic>> changedDesignUpdates() {
    final now = draftSettings;
    final was = initialSettings;
    final updates = <Map<String, dynamic>>[];
    for (final entity in designUpdateEntities) {
      if (!(_updateAll[entity] ?? false)) continue;
      final id = designIdFor(now, entity);
      if (id == null ||
          id.isEmpty ||
          id.startsWith('tmp_') ||
          id == designIdFor(was, entity)) {
        continue;
      }
      updates.add({'design_id': id, 'entity': entity});
    }
    return updates;
  }
}
