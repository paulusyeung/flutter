import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_api_model.freezed.dart';
part 'user_api_model.g.dart';

/// Envelope for `GET /api/v1/users/{id}` and `PUT /api/v1/users/{id}`.
///
/// The PUT body is itself a `UserApi` JSON map; the server echoes the patched
/// record back inside `data`.
@freezed
abstract class UserItemApi with _$UserItemApi {
  const factory UserItemApi({required UserApi data}) = _UserItemApi;

  factory UserItemApi.fromJson(Map<String, dynamic> json) =>
      _$UserItemApiFromJson(json);
}

/// Full user record returned by `/api/v1/users/{id}?include=company_user`.
///
/// We model the user-level fields the Settings > User Details screen edits
/// (name / email / phone / signature / language / oauth status) explicitly so
/// dropdowns and validators get typed access. The active company's per-user
/// settings travel under the singular `company_user` field — only the active
/// company is included when the request carries `?include=company_user`,
/// matching the React app's `useUserDetailsQuery` shape.
@freezed
abstract class UserApi with _$UserApi {
  const factory UserApi({
    @Default('') String id,
    @JsonKey(name: 'first_name') @Default('') String firstName,
    @JsonKey(name: 'last_name') @Default('') String lastName,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String signature,
    @JsonKey(name: 'language_id') @Default('') String languageId,

    // -- Connect tab inputs ---------------------------------------------------
    @JsonKey(name: 'oauth_provider_id') @Default('') String oauthProviderId,
    @JsonKey(name: 'oauth_user_token') @Default('') String oauthUserToken,
    @JsonKey(name: 'oauth_user_refresh_token')
    @Default('')
    String oauthUserRefreshToken,

    // -- Two-factor / phone -------------------------------------------------
    @JsonKey(name: 'google_2fa_secret', fromJson: _boolFromJson)
    @Default(false)
    bool google2faSecret,
    @JsonKey(name: 'verified_phone_number', fromJson: _boolFromJson)
    @Default(false)
    bool verifiedPhoneNumber,

    // -- Misc ---------------------------------------------------------------
    @JsonKey(name: 'has_password') @Default(false) bool hasPassword,
    @JsonKey(name: 'last_login') @Default(0) int lastLogin,
    @JsonKey(name: 'created_at') @Default(0) int createdAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'archived_at') @Default(0) int archivedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,

    // -- Per-company-user (active company only when ?include=company_user) -
    @JsonKey(name: 'company_user') CompanyUserApi? companyUser,
  }) = _UserApi;

  factory UserApi.fromJson(Map<String, dynamic> json) =>
      _$UserApiFromJson(json);
}

/// Per-(user, company) record. Holds the notifications array and the loose
/// `settings` blob (accent_color, etc.) we round-trip verbatim — the server
/// accepts unknown keys, so anything we don't model here stays on the wire.
@freezed
abstract class CompanyUserApi with _$CompanyUserApi {
  const factory CompanyUserApi({
    @Default('') String permissions,
    @JsonKey(name: 'is_owner') @Default(false) bool isOwner,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'is_locked') @Default(false) bool isLocked,
    @Default(NotificationsApi()) NotificationsApi notifications,
    @Default(<String, dynamic>{}) Map<String, dynamic> settings,
    @JsonKey(name: 'react_settings')
    @Default(<String, dynamic>{})
    Map<String, dynamic> reactSettings,
  }) = _CompanyUserApi;

  factory CompanyUserApi.fromJson(Map<String, dynamic> json) =>
      _$CompanyUserApiFromJson(json);
}

/// Wraps the `notifications` object. Today the server only emits the `email`
/// channel; modelling it as its own object leaves room for `sms`, `push`, etc.
/// without a schema migration.
@freezed
abstract class NotificationsApi with _$NotificationsApi {
  const factory NotificationsApi({@Default(<String>[]) List<String> email}) =
      _NotificationsApi;

  factory NotificationsApi.fromJson(Map<String, dynamic> json) =>
      _$NotificationsApiFromJson(json);
}

/// The server emits `0`/`1`, `"true"`/`"false"`, or a real bool depending on
/// the endpoint — see [UserSummaryApi] in `login_response_api_model.dart` for
/// the same workaround in the leaner auth-session view.
bool _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}
