import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/api_client.dart';

/// Thin wrapper around the QuickBooks integration endpoints. The repository
/// has no local state — `company.quickbooks` is the source of truth and is
/// kept fresh by `_persistAndActivate` / `applyUpdateResponse`. The two
/// methods exposed here are the only side-effects the Account Management →
/// Integrations → QuickBooks screen needs to fire.
class QuickbooksRepository {
  QuickbooksRepository({
    required ApiClient apiClient,
    required AuthRepository auth,
  }) : _api = apiClient,
       _auth = auth;

  final ApiClient _api;
  final AuthRepository _auth;

  /// Mint a short-lived "one time token" the server hands the Intuit OAuth
  /// authorize endpoint, and build the URL the user opens to complete the
  /// connect flow. The hosted page redirects back to the Invoice Ninja
  /// server with the OAuth code; the server stores the tokens on
  /// `company.quickbooks` and the next `/refresh` propagates them locally.
  ///
  /// Mirrors React `useQuickbooksConnect`:
  ///   `POST /api/v1/one_time_token { context: 'quickbooks' }` →
  ///   `{ data: { hash: '<token>' } }` →
  ///   `GET {baseUrl}/quickbooks/authorize/<token>` (launched externally).
  ///
  /// Returns the URL to launch via `url_launcher`. Throws on transport /
  /// HTTP failure so the caller can toast.
  Future<Uri> buildAuthorizeUrl() async {
    final raw = await _api.postJson(
      '/api/v1/one_time_token',
      body: const {'context': 'quickbooks'},
    );
    if (raw is! Map<String, dynamic>) {
      throw StateError(
        'Unexpected /one_time_token response shape: ${raw.runtimeType}',
      );
    }
    // Server response shape: `{ data: { hash: '<token>' } }`. Tolerate a
    // top-level `hash` for older builds.
    String? token;
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      token = data['hash'] as String?;
    }
    token ??= raw['hash'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('one_time_token response missing hash');
    }
    final baseUrl = _auth.session.value?.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('cannot build QuickBooks authorize URL without baseUrl');
    }
    return Uri.parse(baseUrl).resolve('/quickbooks/authorize/$token');
  }

  /// Disconnect the integration server-side. Mirrors React
  /// `useQuickbooksDisconnect`: `POST /api/v1/quickbooks/disconnect`.
  ///
  /// On success, refresh the session so `company.quickbooks` flips back to
  /// `null` everywhere the UI reads from (incl. the local Drift row that
  /// drives `CompanyRepository.watchCompany`).
  Future<void> disconnect() async {
    await _api.postJson('/api/v1/quickbooks/disconnect', body: const {});
    // Low-frequency, user-initiated integration toggle — force a full
    // snapshot so `company.quickbooks` is unambiguously authoritative.
    await _auth.refresh(fullSync: true);
  }

  /// Re-authorize an expired connection. Mirrors React
  /// `useQuickbooksReconnect`: `POST /api/v1/quickbooks/reconnect_url {}` →
  /// `{ data: { reconnect_url: '<url>' } }`. The caller launches the URL;
  /// the hosted page redirects back like the initial connect. Tolerant
  /// parse (nested `data` or flat) matching [buildAuthorizeUrl].
  Future<Uri> reconnectUrl() async {
    final raw = await _api.postJson(
      '/api/v1/quickbooks/reconnect_url',
      body: const {},
    );
    if (raw is! Map<String, dynamic>) {
      throw StateError(
        'Unexpected /quickbooks/reconnect_url response shape: '
        '${raw.runtimeType}',
      );
    }
    String? url;
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      url = data['reconnect_url'] as String?;
    }
    url ??= raw['reconnect_url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('reconnect_url response missing reconnect_url');
    }
    return Uri.parse(url);
  }

  /// Trigger a one-shot import of QuickBooks entities into Invoice Ninja.
  /// Mirrors React `QuickBooksImportTab`: `POST /api/v1/quickbooks/sync`
  /// with the per-entity booleans. The server runs the import async; the
  /// next `/refresh` (or a manual "Refresh status") reflects results.
  Future<void> triggerImport({
    required bool client,
    required bool product,
    required bool invoice,
  }) async {
    await _api.postJson(
      '/api/v1/quickbooks/sync',
      body: {'client': client, 'product': product, 'invoice': invoice},
    );
  }
}
