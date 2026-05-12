import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response_api_model.freezed.dart';
part 'login_response_api_model.g.dart';

/// Shape of `/api/v1/login` and `/api/v1/refresh`.
///
/// Mirrors `admin-portal/lib/data/models/entities.dart:594` (LoginResponse).
/// `data` is the array of companies this user has access to. `static` is the
/// global reference-data blob (currencies, countries, etc.) — kept as a raw
/// map; `StaticsRepository` parses it lazily.
@freezed
abstract class LoginResponseApi with _$LoginResponseApi {
  const factory LoginResponseApi({
    @Default(<UserCompanyApi>[]) List<UserCompanyApi> data,
    @JsonKey(name: 'static')
    @Default(<String, dynamic>{})
    Map<String, dynamic> staticData,
  }) = _LoginResponseApi;

  factory LoginResponseApi.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseApiFromJson(json);
}

/// One per company this user has access to. The token is per-company.
@freezed
abstract class UserCompanyApi with _$UserCompanyApi {
  const factory UserCompanyApi({
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'is_owner') @Default(false) bool isOwner,
    @Default('') String permissions,
    @JsonKey(name: 'permissions_updated_at')
    @Default(0)
    int permissionsUpdatedAt,
    required CompanyEnvelopeApi company,
    required TokenApi token,
    required AccountEnvelopeApi account,
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
    @JsonKey(name: 'user') @Default(UserSummaryApi()) UserSummaryApi user,
  }) = _UserCompanyApi;

  factory UserCompanyApi.fromJson(Map<String, dynamic> json) =>
      _$UserCompanyApiFromJson(json);
}

/// Minimum the new app needs to know about the authenticated user: the id,
/// for routing PUTs to `/api/v1/company_users/{id}`.
@freezed
abstract class UserSummaryApi with _$UserSummaryApi {
  const factory UserSummaryApi({
    @Default('') String id,
    @JsonKey(name: 'email') @Default('') String email,
  }) = _UserSummaryApi;

  factory UserSummaryApi.fromJson(Map<String, dynamic> json) =>
      _$UserSummaryApiFromJson(json);
}

@freezed
abstract class CompanyEnvelopeApi with _$CompanyEnvelopeApi {
  const factory CompanyEnvelopeApi({
    @Default('') String id,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default('') String name,
    @JsonKey(name: 'company_key') @Default('') String companyKey,
    @JsonKey(name: 'custom_fields')
    @Default(<String, String>{})
    Map<String, String> customFields,
    @JsonKey(name: 'size_id') @Default('') String sizeId,
    @JsonKey(name: 'industry_id') @Default('') String industryId,
    @JsonKey(name: 'legal_entity_id') @Default(0) int legalEntityId,
    @JsonKey(name: 'enabled_modules') @Default(0) int enabledModules,
    // `settings` stays as a raw map — every key the server sends is
    // preserved verbatim through the round-trip. Strong-typing here would
    // drop unknown keys at fromJson/toJson, silently corrupting fields
    // we haven't modeled yet. The repository builds the typed view on
    // demand via `CompanySettingsApi.fromJson`.
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
  }) = _CompanyEnvelopeApi;

  factory CompanyEnvelopeApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyEnvelopeApiFromJson(json);
}

@freezed
abstract class TokenApi with _$TokenApi {
  const factory TokenApi({
    @Default('') String token,
    @Default('') String name,
  }) = _TokenApi;

  factory TokenApi.fromJson(Map<String, dynamic> json) =>
      _$TokenApiFromJson(json);
}

@freezed
abstract class AccountEnvelopeApi with _$AccountEnvelopeApi {
  const factory AccountEnvelopeApi({
    @Default('') String id,
    @JsonKey(name: 'default_company_id') @Default('') String defaultCompanyId,
    @Default('') String plan,
    @JsonKey(name: 'num_trial_days') @Default(0) int numTrialDays,
    @JsonKey(name: 'hosted_client_count') @Default(0) int hostedClientCount,
    @JsonKey(name: 'hosted_company_count') @Default(0) int hostedCompanyCount,
  }) = _AccountEnvelopeApi;

  factory AccountEnvelopeApi.fromJson(Map<String, dynamic> json) =>
      _$AccountEnvelopeApiFromJson(json);
}
