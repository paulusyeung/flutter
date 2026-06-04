import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/services/api_client.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/base_entity_api.dart';
import 'package:admin/data/services/upload_source.dart';

/// Concrete API for `/api/v1/companies`. Companies are a singleton-per-tenant
/// (no list/create/delete from this app) but we still extend [BaseEntityApi]
/// so the outbox dispatcher can use the same `update` method as everything
/// else.
///
/// `list` is unused in M1 — companies arrive via `/auth/me`. Multipart
/// uploads for logo + document attachments use [uploadLogo] / [uploadDocument]
/// because the outbox payload format doesn't naturally carry binary.
class CompaniesApi extends BaseEntityApi<CompanyItemApi, CompanyItemApi> {
  CompaniesApi(super.client);

  @override
  String get basePath => '/api/v1/companies';

  ApiClient get apiClient => client;

  @override
  CompanyItemApi parseList(Object json) =>
      CompanyItemApi.fromJson(json as Map<String, dynamic>);

  @override
  CompanyItemApi parseItem(Object json) =>
      CompanyItemApi.fromJson(json as Map<String, dynamic>);

  /// Upload a new company logo. Server replaces the existing one; the response
  /// is a refreshed company envelope whose `settings.company_logo` carries
  /// the new URL.
  Future<CompanyItemApi> uploadLogo({
    required String companyId,
    required UploadSource source,
    required String idempotencyKey,
  }) async {
    final file = await source.toMultipartFile('company_logo');
    // Logo goes through the company *update* endpoint (`PUT /companies/{id}`
    // via POST + `_method` form-spoof), matching admin-portal / React — there
    // is no `/upload` sub-route for the logo, and POST alone is "Method not
    // supported for this route".
    final raw = await client.uploadMultipart(
      path: '$basePath/$companyId',
      fields: const {'_method': 'PUT'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }

  /// Upload a document attachment to the company. Server returns the
  /// refreshed company envelope (documents nested inside).
  Future<CompanyItemApi> uploadDocument({
    required String companyId,
    required UploadSource source,
    required String idempotencyKey,
  }) async {
    final file = await source.toMultipartFile('documents[]');
    // Company documents DO use the `/upload` sub-route (unlike logo / cert),
    // POST + `_method=PUT` — matches admin-portal / React.
    final raw = await client.uploadMultipart(
      path: '$basePath/$companyId/upload',
      fields: const {'_method': 'PUT'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }

  /// Permanently delete a company. Requires the user's password (the
  /// `requiresPassword: true` flag routes the cached password into
  /// `X-API-PASSWORD-BASE64`). Legacy admin-portal sends the
  /// `cancellation_message` in the body; React drops it on the floor.
  ///
  /// Named distinctly from `BaseEntityApi.delete` because the company
  /// destructive flow carries a `cancellation_message` body that the
  /// generic signature doesn't accept.
  /// Probe the server for subdomain availability. Returns `true` when the
  /// subdomain is free, `false` when it's already taken or otherwise rejected
  /// by validation. Network errors / 5xx propagate so the UI shows
  /// "couldn't check" rather than a false positive.
  ///
  /// The Client Portal Settings tab calls this on a debounce as the user
  /// types — see `_SubdomainField`. Save is **not** gated on the result;
  /// the server is authoritative and rejects on PUT if needed.
  Future<bool> checkSubdomainAvailable(String subdomain) async {
    try {
      await client.postJson(
        '/api/v1/check_subdomain',
        body: {'subdomain': subdomain},
        readOnly: true,
      );
      return true;
    } on ValidationException {
      return false;
    } on ServerException catch (e) {
      if (e.statusCode >= 400 && e.statusCode < 500) return false;
      rethrow;
    }
  }

  Future<void> deleteWithBody({
    required String id,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'DELETE',
      path: '$basePath/$id',
      idempotencyKey: idempotencyKey,
      body: body,
      requiresPassword: true,
    );
  }

  // ── E-Invoice / PEPPOL ───────────────────────────────────────────────
  // All eight write methods return the refreshed company envelope so the
  // dispatcher can `applyUpdateResponse` and Drift stays in sync. The two
  // GET probes (`getEInvoiceQuota` / `getEInvoiceHealthCheck`) are
  // out-of-outbox: live fetches issued by the Preferences card on mount.

  /// Multipart upload of a digital certificate (`.p12` / `.pfx` / `.pem` /
  /// `.cer` / `.crt` / `.der` / `.p7b` / `.spc` / `.bin` / `.txt`). Field
  /// name `e_invoice_certificate` matches admin-portal `web_client.dart`
  /// and React `EInvoice.tsx`. Server flips `has_e_invoice_certificate`
  /// to true and returns the refreshed envelope.
  Future<CompanyItemApi> uploadEInvoiceCertificate({
    required String companyId,
    required UploadSource source,
    required String idempotencyKey,
  }) async {
    final file = await source.toMultipartFile('e_invoice_certificate');
    // Certificate goes through the company *update* endpoint (`PUT
    // /companies/{id}` via POST + `_method` form-spoof), same as the logo —
    // no `/upload` sub-route.
    final raw = await client.uploadMultipart(
      path: '$basePath/$companyId',
      fields: const {'_method': 'PUT'},
      files: [file],
      idempotencyKey: idempotencyKey,
    );
    return parseItem(raw as Object);
  }

  /// Onboard the active tenant to PEPPOL. Payload mirrors React
  /// `peppol/Onboarding.tsx`: `party_name`, `line1`, `line2`, `city`,
  /// `county`, `zip`, `country`, `vat_number` or `id_number`,
  /// `acts_as_sender`, `acts_as_receiver`, `classification`, `tenant_id`.
  /// Server returns the refreshed company envelope with the new
  /// `legal_entity_id`.
  Future<CompanyItemApi> peppolSetup({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '/api/v1/einvoice/peppol/setup',
      idempotencyKey: idempotencyKey,
      body: payload,
    );
    return parseItem(raw as Object);
  }

  /// Singapore PEPPOL onboarding. Same `POST /api/v1/einvoice/peppol/setup`
  /// as [peppolSetup], but preserves the response's `corppass_url`: for
  /// Singapore the server returns a CorpPass government-auth redirect the
  /// caller must launch immediately (mirrors React `peppol/Onboarding.tsx`
  /// `window.location.href = corppass_url`). [peppolSetup]'s
  /// `parseItem(raw)` would drop that transient field. EU responses carry
  /// no `corppass_url` → `corppassUrl` is null and registration is
  /// immediate (identical to [peppolSetup]).
  Future<({CompanyItemApi company, String? corppassUrl})>
  peppolSetupWithRedirect({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '/api/v1/einvoice/peppol/setup',
      idempotencyKey: idempotencyKey,
      body: payload,
    );
    final url = raw is Map ? raw['corppass_url'] as String? : null;
    return (company: parseItem(raw as Object), corppassUrl: url);
  }

  /// Update PEPPOL preferences (`acts_as_sender` / `acts_as_receiver`).
  /// Server returns the refreshed company envelope.
  Future<CompanyItemApi> peppolUpdatePreferences({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '/api/v1/einvoice/peppol/update',
      idempotencyKey: idempotencyKey,
      body: payload,
    );
    return parseItem(raw as Object);
  }

  /// Disconnect from PEPPOL. Payload carries `company_key`,
  /// `legal_entity_id`, `tax_data`, `e_invoicing_token` — the four pieces
  /// the server needs to revoke the binding.
  Future<CompanyItemApi> peppolDisconnect({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '/api/v1/einvoice/peppol/disconnect',
      idempotencyKey: idempotencyKey,
      body: payload,
    );
    return parseItem(raw as Object);
  }

  /// Add an additional per-country VAT identifier for multi-country PEPPOL
  /// operation. Payload: `{country, vat_number}`.
  Future<dynamic> peppolAddTaxIdentifier({
    required String country,
    required String vatNumber,
    required String idempotencyKey,
  }) {
    return client.mutate(
      method: 'POST',
      path: '/api/v1/einvoice/peppol/add_additional_legal_identifier',
      idempotencyKey: idempotencyKey,
      body: {'country': country, 'vat_number': vatNumber},
    );
  }

  /// Remove an additional per-country VAT identifier. Payload:
  /// `{country, vat_number}`.
  Future<dynamic> peppolRemoveTaxIdentifier({
    required String country,
    required String vatNumber,
    required String idempotencyKey,
  }) {
    return client.mutate(
      method: 'DELETE',
      path: '/api/v1/einvoice/peppol/remove_additional_legal_identifier',
      idempotencyKey: idempotencyKey,
      body: {'country': country, 'vat_number': vatNumber},
    );
  }

  /// Save the payment-means configuration. Payload carries an `entity`
  /// (`'company'`) + `payment_means: [{code, iban?, bic_swift?, ...}]`.
  /// Server returns the refreshed company envelope.
  Future<dynamic> saveEInvoicePaymentMeans({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) {
    return client.mutate(
      method: 'POST',
      path: '/api/v1/einvoice/configurations',
      idempotencyKey: idempotencyKey,
      body: payload,
    );
  }

  /// Regenerate the e-invoicing token. Surfaced by the Preferences card
  /// when the health-check endpoint reports the current token unhealthy.
  Future<CompanyItemApi> regenerateEInvoiceToken({
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: '/api/v1/einvoice/token/update',
      idempotencyKey: idempotencyKey,
      body: const <String, dynamic>{},
    );
    return parseItem(raw as Object);
  }

  /// Retroactively apply a design to existing records of [entity] — powers
  /// the Invoice Design page's "Update all records" toggle. `POST
  /// /api/v1/designs/set/default`. [settingsLevel] is `company` /
  /// `group_settings` / `client`; the matching scope id is sent for the
  /// latter two. Mirrors React `InvoiceDesign.tsx` and admin-portal
  /// `invoice_design_vm.dart`. The server returns a status message we don't
  /// need, so the body is ignored.
  Future<void> setDefaultDesign({
    required String designId,
    required String entity,
    required String settingsLevel,
    required String idempotencyKey,
    String? clientId,
    String? groupSettingsId,
  }) async {
    await client.mutate(
      method: 'POST',
      path: '/api/v1/designs/set/default',
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'design_id': designId,
        'entity': entity,
        'settings_level': settingsLevel,
        if (clientId != null) 'client_id': clientId,
        if (groupSettingsId != null) 'group_settings_id': groupSettingsId,
      },
    );
  }

  /// Live fetch of the PEPPOL credit quota. Out-of-outbox; the Preferences
  /// card calls this on mount and ignores network errors.
  Future<dynamic> getEInvoiceQuota() {
    return client.getOne('/api/v1/einvoice/quota');
  }

  /// Live fetch of the PEPPOL token health-check. Returns true when the
  /// active token is valid, false when it should be regenerated. Out-of-
  /// outbox; surfaced by the Preferences card to gate the Regenerate
  /// Token button.
  Future<dynamic> getEInvoiceHealthCheck() {
    return client.getOne('/api/v1/einvoice/health_check');
  }
}
