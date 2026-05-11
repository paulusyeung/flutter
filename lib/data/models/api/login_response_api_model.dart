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
class LoginResponseApi with _$LoginResponseApi {
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
class UserCompanyApi with _$UserCompanyApi {
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
  }) = _UserCompanyApi;

  factory UserCompanyApi.fromJson(Map<String, dynamic> json) =>
      _$UserCompanyApiFromJson(json);
}

@freezed
class CompanyEnvelopeApi with _$CompanyEnvelopeApi {
  const factory CompanyEnvelopeApi({
    @Default('') String id,
    @JsonKey(name: 'display_name') @Default('') String displayName,
    @Default('') String name,
    @JsonKey(name: 'company_key') @Default('') String companyKey,
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
  }) = _CompanyEnvelopeApi;

  factory CompanyEnvelopeApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyEnvelopeApiFromJson(json);
}

@freezed
class TokenApi with _$TokenApi {
  const factory TokenApi({
    @Default('') String token,
    @Default('') String name,
  }) = _TokenApi;

  factory TokenApi.fromJson(Map<String, dynamic> json) =>
      _$TokenApiFromJson(json);
}

@freezed
class AccountEnvelopeApi with _$AccountEnvelopeApi {
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
