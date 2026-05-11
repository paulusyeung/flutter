import 'dart:convert';

import '../db/app_database.dart';

/// Resolves effective settings for a client by walking the cascade
/// `client.settings → group.settings → company.settings`, matching
/// `admin-portal/lib/redux/settings/settings_state.dart:93-99`.
///
/// In M1 only the company-level layer is populated (no Groups yet). The
/// walker is structured so M2's Group entity drops in without changing
/// callers.
class SettingsRepository {
  SettingsRepository({required AppDatabase db}) : _db = db;
  final AppDatabase _db;

  /// Return the effective settings map for the given client. Keys later in
  /// the lookup chain are overridden by earlier ones.
  Future<Map<String, dynamic>> resolved({
    required String companyId,
    String? clientId,
  }) async {
    final company = await _db.companiesDao.byId(companyId);
    final companySettings =
        company == null ? <String, dynamic>{} : _decodeOrEmpty(company.settings);

    final clientSettings = <String, dynamic>{};
    if (clientId != null) {
      final client =
          await _db.clientDao.watchById(companyId: companyId, id: clientId).first;
      if (client != null) {
        final payload = jsonDecode(client.payload) as Map<String, dynamic>;
        final inner = payload['settings'];
        if (inner is Map<String, dynamic>) clientSettings.addAll(inner);
      }
    }

    // Walk later-to-earlier so earlier (client) takes precedence.
    return <String, dynamic>{
      ...companySettings,
      // Groups go here in M2.
      ...clientSettings,
    };
  }

  Map<String, dynamic> _decodeOrEmpty(String raw) {
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}
