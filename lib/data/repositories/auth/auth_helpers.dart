/// Storage keys used in `flutter_secure_storage`. The map of `(companyId →
/// token)` is stored as a single JSON blob to keep the secure-storage API
/// minimal.
const String kAuthTokensKey = 'invoiceninja.tokens.v1';
const String kAuthBaseUrlKey = 'invoiceninja.base_url.v1';
const String kAuthIsHostedKey = 'invoiceninja.is_hosted.v1';
const String kAuthCurrentCompanyIdKey = 'invoiceninja.current_company.v1';

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
