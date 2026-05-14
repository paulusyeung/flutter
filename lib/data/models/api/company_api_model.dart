import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/document_api_model.dart';

// `DocumentApi` moved out of this file when Client and Product also started
// carrying document arrays. Re-exported so existing call sites keep working
// with no import churn.
export 'package:admin/data/models/api/document_api_model.dart';

part 'company_api_model.freezed.dart';
part 'company_api_model.g.dart';

/// Wire shape of `/api/v1/companies/{id}` (also embedded in `/auth/me` via
/// `CompanyEnvelopeApi`).
///
/// `settings` stays as a raw map for the same reason it does on
/// [CompanyEnvelopeApi] — the typed model only covers ~200 of ~250 server
/// fields, and round-tripping through it would drop the others silently.
/// Callers build the typed view via `CompanySettingsApi.fromJson(settings)`
/// when they need to read individual fields.
@freezed
abstract class CompanyApi with _$CompanyApi {
  @JsonSerializable(includeIfNull: false)
  const factory CompanyApi({
    @Default('') String id,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default('') String name,
    @JsonKey(name: 'company_key') @Default('') String companyKey,
    @JsonKey(name: 'size_id') @Default('') String sizeId,
    @JsonKey(name: 'industry_id') @Default('') String industryId,
    @JsonKey(name: 'first_month_of_year') @Default('') String firstMonthOfYear,
    @JsonKey(name: 'first_day_of_week') @Default('') String firstDayOfWeek,
    @JsonKey(name: 'enabled_modules') @Default(0) int enabledModules,
    @JsonKey(name: 'legal_entity_id') @Default(0) int legalEntityId,
    @JsonKey(name: 'subdomain') @Default('') String subdomain,
    @JsonKey(name: 'portal_domain') @Default('') String portalDomain,
    @JsonKey(name: 'portal_mode') @Default('') String portalMode,
    @JsonKey(name: 'custom_fields')
    @Default(<String, String>{})
    Map<String, String> customFields,
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
    @Default(<DocumentApi>[]) List<DocumentApi> documents,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
  }) = _CompanyApi;

  factory CompanyApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyApiFromJson(json);
}

/// Envelope for `/api/v1/companies/{id}` item responses (`{ data: ... }`).
@freezed
abstract class CompanyItemApi with _$CompanyItemApi {
  const factory CompanyItemApi({required CompanyApi data}) = _CompanyItemApi;

  factory CompanyItemApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyItemApiFromJson(json);
}
