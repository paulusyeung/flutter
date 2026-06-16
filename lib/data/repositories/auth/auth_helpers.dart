/// Storage keys used in `flutter_secure_storage`. The map of `(companyId →
/// token)` is stored as a single JSON blob to keep the secure-storage API
/// minimal.
const String kAuthTokensKey = 'invoiceninja.tokens.v1';
const String kAuthBaseUrlKey = 'invoiceninja.base_url.v1';
const String kAuthIsHostedKey = 'invoiceninja.is_hosted.v1';
const String kAuthCurrentCompanyIdKey = 'invoiceninja.current_company.v1';

/// Whether the user has opted in to biometric (FaceID / TouchID) gating on
/// cold launch. Persisted as `'true'` / absent; any other value is treated as
/// disabled so a corrupt write can't accidentally enable the gate without an
/// explicit user action.
const String kAuthBiometricEnabledKey = 'invoiceninja.biometric_enabled.v1';

/// Set when the idle session-timeout re-locks a session that still has unsynced
/// outbox work (so the local DB + tokens are preserved instead of wiped — see
/// `AuthRepository.logout(preserveLocalData:)`). On the next `restore()` this
/// forces a re-auth gate before re-entering — biometric if enabled, otherwise a
/// fresh sign-in — instead of silently auto-restoring the prior session. Cleared
/// on successful re-entry. Persisted as `'true'` / absent.
const String kAuthSessionLockedKey = 'invoiceninja.session_locked.v1';

/// Invoice Ninja stores the user-visible company name inside `settings.name`.
/// The top-level `display_name` / `name` fields are typically empty, so they
/// only serve as fallbacks. Mirrors admin-portal's `company_model.dart:528`.
String companyDisplayName({
  required Map<String, dynamic> settings,
  required String displayName,
  required String name,
}) {
  final settingsName = settings['name'];
  if (settingsName is String && settingsName.trim().isNotEmpty) {
    return settingsName;
  }
  if (displayName.isNotEmpty) return displayName;
  if (name.isNotEmpty) return name;
  return 'Untitled';
}

/// `settings.company_logo` carries an absolute URL on self-hosted instances
/// and an Invoice Ninja CDN URL on hosted ones. Empty / missing → null so the
/// avatar falls through to its initials path.
String? companyLogoUrl(Map<String, dynamic> settings) {
  final v = settings['company_logo'];
  if (v is String && v.trim().isNotEmpty) return v.trim();
  return null;
}

/// Appends a cache-busting `v=<updatedAt>` to a resolved logo URL. Invoice
/// Ninja reuses the same `company_logo` URL when a logo is replaced (it
/// overwrites the file at a stable path), so without this (a) the derived
/// `AuthCompany.logoUrl` string wouldn't change, so `_onCompaniesChanged`'s
/// diff never fires and the picker session never re-emits, and (b) the
/// avatar's `Image.network` would serve the stale cached bytes. Mirrors the
/// cache-bust in `logo_screen.dart`. Null / empty in → returned unchanged so
/// the avatar still falls through to its initials path.
String? cacheBustedLogoUrl(String? rawUrl, int updatedAt) {
  if (rawUrl == null || rawUrl.isEmpty) return rawUrl;
  final sep = rawUrl.contains('?') ? '&' : '?';
  return '$rawUrl${sep}v=$updatedAt';
}
