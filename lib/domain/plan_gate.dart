import 'package:admin/data/repositories/auth/auth_session.dart';

/// Single source of truth for hosted pro/enterprise feature gating.
///
/// Before this file, gating lived in four places (the gated-slug `const` sets,
/// `_gateLevelFor` in `settings_screen.dart`, ~8 ad-hoc
/// `session.isProPlan`/`isEnterprisePlan` reads in feature screens, and
/// `canAddCompany`). That drift produced a real bug (the Client Portal
/// subdomain gate never engaged). Every gate now resolves through
/// [planGateFor] / [planTierFor] so adding a gated surface is a one-line map
/// edit and the rules can't disagree.
///
/// **Always gate on the trial-aware predicates** ([AuthSession.hasProAccess] /
/// [AuthSession.hasEnterpriseAccess]) — trialing hosted users get full
/// features for free, so gating on `isProPlan` alone regresses them.
enum PlanTier { pro, enterprise }

/// Non-settings gated surfaces (settings sections are keyed by slug instead —
/// see [kProGatedSettings] / [kEnterpriseGatedSettings]).
enum GatedFeature {
  /// Reports module — Pro in both reference apps.
  reports,

  /// Document / attachment upload on any entity — Enterprise in both.
  documents,

  /// E-invoice settings — Enterprise on hosted (React parity).
  eInvoiceSettings,

  /// Creating / editing a custom invoice design — Pro (distinct from the
  /// Invoice Design *settings* section, which is gated by slug).
  customDesigns,

  /// Removing Invoice Ninja branding ("white label") — Pro.
  whiteLabel,
}

const Map<GatedFeature, PlanTier> _kFeatureTier = {
  GatedFeature.reports: PlanTier.pro,
  GatedFeature.documents: PlanTier.enterprise,
  GatedFeature.eInvoiceSettings: PlanTier.enterprise,
  GatedFeature.customDesigns: PlanTier.pro,
  GatedFeature.whiteLabel: PlanTier.pro,
};

/// Settings sections gated behind the Pro plan (Enterprise implies Pro).
/// Mirrors admin-portal's `kAdvancedSettings`. Self-hosted unlocks all.
/// Re-exported from `settings_search_catalog.dart` for existing importers.
const Set<String> kProGatedSettings = {
  'invoice_design',
  'custom_fields',
  'generated_numbers',
  'client_portal',
  'email_settings',
  'templates_and_reminders',
  'group_settings',
  'payment_links',
  'schedules',
  'custom_designs',
  'transaction_rules',
};

/// Settings sections gated behind the Enterprise plan specifically.
const Set<String> kEnterpriseGatedSettings = {'users', 'e_invoice'};

/// True when [session] has access to [tier] (trial-aware, self-hosted unlocks).
bool sessionHasTier(AuthSession session, PlanTier tier) =>
    tier == PlanTier.enterprise
    ? session.hasEnterpriseAccess
    : session.hasProAccess;

/// The plan tier a settings slug or feature *requires*, independent of the
/// current session. Returns null when the surface is ungated.
PlanTier? planTierFor({String? settingsSlug, GatedFeature? feature}) {
  if (feature != null) return _kFeatureTier[feature];
  if (settingsSlug != null) {
    if (kEnterpriseGatedSettings.contains(settingsSlug)) {
      return PlanTier.enterprise;
    }
    if (kProGatedSettings.contains(settingsSlug)) return PlanTier.pro;
  }
  return null;
}

/// The tier the [session] is **missing** for a settings slug / feature, or
/// null when the surface is ungated, the user qualifies (incl. trial /
/// self-hosted), or the session hasn't loaded yet (fail-open on *read*; gated
/// *writes* are blocked separately — see the offline gate policy).
PlanTier? planGateFor(
  AuthSession? session, {
  String? settingsSlug,
  GatedFeature? feature,
}) {
  if (session == null) return null;
  final required = planTierFor(settingsSlug: settingsSlug, feature: feature);
  if (required == null) return null;
  return sessionHasTier(session, required) ? null : required;
}
