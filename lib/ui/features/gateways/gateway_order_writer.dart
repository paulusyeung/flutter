import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';

/// Wire-side key for the per-scope gateway-order override. Same string the
/// server uses on `client.settings` / `group.settings`.
const String _kCompanyGatewayIdsKey = 'company_gateway_ids';

/// Persist [csv] (the new comma-separated `companyGatewayIds`) to whichever
/// scope is currently active.
///
///   * Company → writes `company.settings.companyGatewayIds = csv` and saves
///     the whole `Company` via `services.company.updateCompany(...)`.
///   * Group → loads the active group, applies
///     `withCascadeOverride('company_gateway_ids', csv)`, saves via
///     `services.groupSettings.save(...)`.
///   * Client → same shape against `Client.withCascadeOverride`, saves via
///     `services.clients.save(...)`.
///
/// All three paths flow through the standard outbox, so the call is
/// fire-and-forget from the caller's POV. Returns once the local write
/// commits (the server send happens asynchronously off the outbox).
Future<void> writeGatewayOrder(
  Services services,
  SettingsLevelController scope,
  String csv,
) async {
  final session = services.auth.session.value;
  if (session == null) return;
  final companyId = session.currentCompanyId;

  switch (scope.level) {
    case SettingsLevel.company:
      final company = await services.company.watchCompany(companyId).first;
      if (company == null) return;
      final next = company.copyWith(
        settings: company.settings.copyWith(companyGatewayIds: csv),
      );
      await services.company.updateCompany(draft: next);
    case SettingsLevel.group:
      final targetId = scope.targetId;
      if (targetId == null) return;
      final group = await services.groupSettings
          .watchByRealId(companyId: companyId, id: targetId)
          .first;
      if (group == null) return;
      final next = group.withCascadeOverride(_kCompanyGatewayIdsKey, csv);
      await services.groupSettings.save(companyId: companyId, group: next);
    case SettingsLevel.client:
      final targetId = scope.targetId;
      if (targetId == null) return;
      final client = await services.clients
          .watch(companyId: companyId, id: targetId)
          .first;
      if (client == null) return;
      final next = client.withCascadeOverride(_kCompanyGatewayIdsKey, csv);
      await services.clients.save(companyId: companyId, client: next);
  }
}

/// Remove the per-scope `company_gateway_ids` override so the gateway list
/// falls back to the parent scope's order (group → company, or company at
/// group scope). Company-scope is a no-op since there's no parent to fall
/// back to.
Future<void> clearGatewayOrderOverride(
  Services services,
  SettingsLevelController scope,
) async {
  if (scope.isCompany) return;
  final session = services.auth.session.value;
  if (session == null) return;
  final companyId = session.currentCompanyId;
  switch (scope.level) {
    case SettingsLevel.company:
      return;
    case SettingsLevel.group:
      final targetId = scope.targetId;
      if (targetId == null) return;
      final group = await services.groupSettings
          .watchByRealId(companyId: companyId, id: targetId)
          .first;
      if (group == null) return;
      final next = group.withCascadeOverride(_kCompanyGatewayIdsKey, null);
      await services.groupSettings.save(companyId: companyId, group: next);
    case SettingsLevel.client:
      final targetId = scope.targetId;
      if (targetId == null) return;
      final client = await services.clients
          .watch(companyId: companyId, id: targetId)
          .first;
      if (client == null) return;
      final next = client.withCascadeOverride(_kCompanyGatewayIdsKey, null);
      await services.clients.save(companyId: companyId, client: next);
  }
}

/// One read-side result describing the currently-applied gateway order at
/// the active scope. `csv` is the order to render; `isOverriding` is true
/// when the active scope itself stamped that order; `inheritedSourceLabel`
/// is the user-facing name of the parent that supplied the order when
/// inheriting (null at company scope or when no inherited order exists).
class GatewayOrderResolution {
  const GatewayOrderResolution({
    required this.csv,
    required this.isOverriding,
    this.inheritedSourceLabel,
  });

  final String csv;
  final bool isOverriding;
  final String? inheritedSourceLabel;
}

/// Resolve the gateway order that should be displayed at the active scope,
/// plus whether the active scope is providing that order (vs inheriting
/// from up the cascade). Used to gate the inheritance-hint banner and the
/// "Reset to default" affordance on `GatewayReorderScreen`.
///
/// Cascade order: client → group (via `client.groupSettingsId`) → company.
Future<GatewayOrderResolution> resolveGatewayOrder(
  Services services,
  SettingsLevelController scope,
) async {
  final session = services.auth.session.value;
  if (session == null) {
    return const GatewayOrderResolution(csv: '', isOverriding: false);
  }
  final companyId = session.currentCompanyId;
  final company = await services.company.watchCompany(companyId).first;
  final companyCsv = company?.settings.companyGatewayIds ?? '';

  switch (scope.level) {
    case SettingsLevel.company:
      return GatewayOrderResolution(csv: companyCsv, isOverriding: true);

    case SettingsLevel.group:
      final targetId = scope.targetId;
      if (targetId == null) {
        return GatewayOrderResolution(csv: companyCsv, isOverriding: false);
      }
      final group = await services.groupSettings
          .watchByRealId(companyId: companyId, id: targetId)
          .first;
      final groupCsv = group?.settings?[_kCompanyGatewayIdsKey]?.toString();
      if (groupCsv != null && groupCsv.isNotEmpty) {
        return GatewayOrderResolution(csv: groupCsv, isOverriding: true);
      }
      return GatewayOrderResolution(
        csv: companyCsv,
        isOverriding: false,
        // Inherited from company.
        inheritedSourceLabel: null,
      );

    case SettingsLevel.client:
      final targetId = scope.targetId;
      if (targetId == null) {
        return GatewayOrderResolution(csv: companyCsv, isOverriding: false);
      }
      final client = await services.clients
          .watch(companyId: companyId, id: targetId)
          .first;
      final clientCsv = client?.settings?[_kCompanyGatewayIdsKey]?.toString();
      if (clientCsv != null && clientCsv.isNotEmpty) {
        return GatewayOrderResolution(csv: clientCsv, isOverriding: true);
      }
      // Inherit: try the client's group first.
      final groupId = client?.groupSettingsId ?? '';
      if (groupId.isNotEmpty) {
        final group = await services.groupSettings
            .watchByRealId(companyId: companyId, id: groupId)
            .first;
        final groupCsv = group?.settings?[_kCompanyGatewayIdsKey]?.toString();
        if (groupCsv != null && groupCsv.isNotEmpty) {
          return GatewayOrderResolution(
            csv: groupCsv,
            isOverriding: false,
            inheritedSourceLabel: group?.name,
          );
        }
      }
      return GatewayOrderResolution(csv: companyCsv, isOverriding: false);
  }
}
