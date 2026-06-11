import 'package:admin/data/services/companies_api.dart';
import 'package:admin/domain/sync/base_entity_sync_dispatcher.dart';
import 'package:admin/domain/sync/mutation.dart';

/// The [MutationKind.setDefaultDesign] dispatcher — the Invoice Design
/// "Update all records" retro-apply at client/group scope. Spread into the
/// Client + GroupSetting dispatchers' `customActions` (company scope fires the
/// same `POST /designs/set/default` inline from `CompanySyncDispatcher`).
///
/// The endpoint lives on [CompaniesApi] but is scope-parameterised; the outbox
/// payload carries `settings_level` plus whichever scope id applies
/// (`client_id` / `group_settings_id`), so one closure serves both scopes.
/// Returns no entity to upsert — fire-and-forget, returns `null`.
Map<MutationKind, CustomMutationHandler<TInner>>
setDefaultDesignHandlers<TInner>(CompaniesApi companiesApi) {
  return {
    MutationKind.setDefaultDesign: ({required row, required payload}) async {
      await companiesApi.setDefaultDesign(
        designId: payload['design_id'] as String,
        entity: payload['entity'] as String,
        settingsLevel: payload['settings_level'] as String,
        clientId: payload['client_id'] as String?,
        groupSettingsId: payload['group_settings_id'] as String?,
        idempotencyKey: row.idempotencyKey,
      );
      return null;
    },
  };
}
