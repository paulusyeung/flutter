import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/company_api_model.dart';
import 'package:admin/data/models/api/company_settings_api_model.dart';
import 'package:admin/data/models/domain/company_settings.dart';

part 'company.freezed.dart';

/// Domain `Company` — what the UI sees.
///
/// The settings blob is carried in two parallel shapes:
///  * [settings] — typed [CompanySettings], holds the ~200 fields the app
///    actively understands. Field mutations flow through this.
///  * [rawSettings] — the original server JSON map. Holds every key the
///    server sent, including the ~50 we haven't modeled.
///
/// On save we merge `{...rawSettings, ...settings.toJson()}` so the PUT body
/// preserves every unknown key alongside the user's typed edits. Without
/// this, fields like `mailgun_secret` or `e_invoice_type` would silently
/// disappear from the server on the first settings save.
///
/// `legalEntityId != 0` is the signal that this tenant has bound a legal
/// entity; the Details tab disables the `id_number` and `vat_number` fields
/// when set (matches React `Details.tsx`).
@freezed
abstract class Company with _$Company {
  const Company._();

  const factory Company({
    @Default('') String id,
    @Default('') String displayName,
    @Default('') String name,
    @Default('') String companyKey,
    @Default('') String sizeId,
    @Default('') String industryId,
    @Default('') String firstMonthOfYear,
    @Default('') String firstDayOfWeek,
    @Default(0) int enabledModules,
    @Default(0) int legalEntityId,
    @Default('') String subdomain,
    @Default('') String portalDomain,
    @Default('') String portalMode,
    @Default(<String, String>{}) Map<String, String> customFields,
    @Default(<String, dynamic>{}) Map<String, dynamic> rawSettings,
    @Default(CompanySettings()) CompanySettings settings,
    @Default(<Document>[]) List<Document> documents,
    @Default(0) int updatedAt,
    @Default(0) int archivedAt,
  }) = _Company;

  factory Company.fromApi(CompanyApi api) => Company(
    id: api.id,
    displayName: api.displayName,
    name: api.name,
    companyKey: api.companyKey,
    sizeId: api.sizeId,
    industryId: api.industryId,
    firstMonthOfYear: api.firstMonthOfYear,
    firstDayOfWeek: api.firstDayOfWeek,
    enabledModules: api.enabledModules,
    legalEntityId: api.legalEntityId,
    subdomain: api.subdomain,
    portalDomain: api.portalDomain,
    portalMode: api.portalMode,
    customFields: api.customFields,
    rawSettings: api.settings,
    settings: CompanySettingsApi.fromJson(api.settings),
    documents: api.documents.map(Document.fromApi).toList(growable: false),
    updatedAt: api.updatedAt,
    archivedAt: api.archivedAt,
  );

  /// Build the PUT body. The `settings` map merges `rawSettings` (so unknown
  /// server keys round-trip) with the typed `settings.toJson()` (so the
  /// user's typed edits win).
  Map<String, dynamic> toApiJson() {
    final mergedSettings = <String, dynamic>{
      ...rawSettings,
      ...settings.toJson(),
    };
    return CompanyApi(
      id: id,
      displayName: displayName,
      name: name,
      companyKey: companyKey,
      sizeId: sizeId,
      industryId: industryId,
      firstMonthOfYear: firstMonthOfYear,
      firstDayOfWeek: firstDayOfWeek,
      enabledModules: enabledModules,
      legalEntityId: legalEntityId,
      subdomain: subdomain,
      portalDomain: portalDomain,
      portalMode: portalMode,
      customFields: customFields,
      settings: mergedSettings,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
    ).toJson();
  }
}

/// Domain attachment on a company. Mirrors the subset of [DocumentApi] the
/// UI surfaces.
@freezed
abstract class Document with _$Document {
  const factory Document({
    @Default('') String id,
    @Default('') String name,
    @Default('') String hash,
    @Default('') String type,
    @Default('') String url,
    @Default(0) int size,
    @Default(true) bool isPublic,
    @Default(0) int createdAt,
    @Default(0) int updatedAt,
  }) = _Document;

  factory Document.fromApi(DocumentApi api) => Document(
    id: api.id,
    name: api.name,
    hash: api.hash,
    type: api.type,
    url: api.url,
    size: api.size,
    isPublic: api.isPublic,
    createdAt: api.createdAt,
    updatedAt: api.updatedAt,
  );
}
