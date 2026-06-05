import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/user_api_model.dart';

part 'user.freezed.dart';

/// Domain `User` — the authenticated user as the Settings > User Details
/// screen sees them. Companies the user has access to (and their
/// per-company-user records) carry through `companyUser`.
///
/// Settings live in two parallel maps mirroring the Company pattern:
///  * [companyUserSettings] — typed-ish [CompanyUserSettings] for the fields
///    we edit (accent_color). Notification prefs live elsewhere:
///    `user_logged_in_notification` is a top-level [User] field and the
///    per-event / special codes live in [notificationsEmail].
///  * [rawCompanyUserSettings] — the original server JSON for the per-user
///    settings blob; everything the new app doesn't model round-trips
///    untouched on save.
@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    @Default('') String id,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String signature,
    @Default('') String languageId,
    @Default('') String oauthProviderId,
    @Default('') String oauthUserToken,
    @Default('') String oauthUserRefreshToken,
    @Default(false) bool googleTwoFactorEnabled,
    @Default(false) bool verifiedPhoneNumber,
    @Default(false) bool hasPassword,
    @Default(false) bool userLoggedInNotification,
    @Default('') String customValue1,
    @Default('') String customValue2,
    @Default('') String customValue3,
    @Default('') String customValue4,
    @Default(0) int lastLogin,
    @Default(0) int emailVerifiedAt,
    @Default(0) int createdAt,
    @Default(0) int updatedAt,
    @Default(0) int archivedAt,
    @Default(false) bool isDeleted,
    @Default(false) bool isDirty,
    @Default(CompanyUser()) CompanyUser companyUser,
    @Default(<String, dynamic>{}) Map<String, dynamic> rawCompanyUserSettings,
    @Default(CompanyUserSettings()) CompanyUserSettings companyUserSettings,
    @Default(<String>[]) List<String> notificationsEmail,
    @Default(<String, dynamic>{}) Map<String, dynamic> rawNotifications,
  }) = _User;

  factory User.fromApi(UserApi api) {
    final cu = api.companyUser ?? const CompanyUserApi();
    return User(
      id: api.id,
      firstName: api.firstName,
      lastName: api.lastName,
      email: api.email,
      phone: api.phone,
      signature: api.signature,
      languageId: api.languageId,
      oauthProviderId: api.oauthProviderId,
      oauthUserToken: api.oauthUserToken,
      oauthUserRefreshToken: api.oauthUserRefreshToken,
      googleTwoFactorEnabled: api.google2faSecret,
      verifiedPhoneNumber: api.verifiedPhoneNumber,
      hasPassword: api.hasPassword,
      userLoggedInNotification: api.userLoggedInNotification,
      customValue1: api.customValue1,
      customValue2: api.customValue2,
      customValue3: api.customValue3,
      customValue4: api.customValue4,
      lastLogin: api.lastLogin,
      emailVerifiedAt: api.emailVerifiedAt,
      createdAt: api.createdAt,
      updatedAt: api.updatedAt,
      archivedAt: api.archivedAt,
      isDeleted: api.isDeleted,
      companyUser: CompanyUser(
        permissions: cu.permissions,
        isOwner: cu.isOwner,
        isAdmin: cu.isAdmin,
        isLocked: cu.isLocked,
      ),
      rawCompanyUserSettings: cu.settings,
      companyUserSettings: CompanyUserSettings.fromJson(cu.settings),
      notificationsEmail: _emailNotifications(cu.notifications),
      rawNotifications: cu.notifications,
    );
  }

  /// Display name for the user; falls back to email when no name is set
  /// (matches the legacy admin-portal behaviour).
  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }

  /// `true` when the user has been invited but hasn't confirmed the email.
  /// Drives the "Pending invite" status pill on the User Management list.
  /// `email_verified_at` is the canonical signal — `!hasPassword` would
  /// false-positive on OAuth users; `lastLogin == 0` would false-positive
  /// on freshly created users who simply haven't logged in yet.
  bool get isPending => emailVerifiedAt == 0;

  /// Parsed permission tokens (`view_client`, `edit_invoice`, `create_all`, …).
  /// Empty when `is_admin = true` — administrators implicitly have all perms.
  List<String> get permissions {
    final s = companyUser.permissions.trim();
    if (s.isEmpty) return const <String>[];
    return s
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
  }

  /// Round-trip the domain model back to a [UserApi] for the PUT save body.
  /// The typed [companyUserSettings] is merged on top of
  /// [rawCompanyUserSettings] so unmodelled keys survive the trip.
  UserApi toApi() {
    return UserApi(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      signature: signature,
      languageId: languageId,
      oauthProviderId: oauthProviderId,
      oauthUserToken: oauthUserToken,
      oauthUserRefreshToken: oauthUserRefreshToken,
      google2faSecret: googleTwoFactorEnabled,
      verifiedPhoneNumber: verifiedPhoneNumber,
      hasPassword: hasPassword,
      userLoggedInNotification: userLoggedInNotification,
      customValue1: customValue1,
      customValue2: customValue2,
      customValue3: customValue3,
      customValue4: customValue4,
      lastLogin: lastLogin,
      emailVerifiedAt: emailVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
      isDeleted: isDeleted,
      companyUser: CompanyUserApi(
        permissions: companyUser.permissions,
        isOwner: companyUser.isOwner,
        isAdmin: companyUser.isAdmin,
        isLocked: companyUser.isLocked,
        notifications: <String, dynamic>{
          ...rawNotifications,
          'email': notificationsEmail,
        },
        settings: <String, dynamic>{
          ...rawCompanyUserSettings,
          ...companyUserSettings.toJson(),
        },
      ),
    );
  }
}

/// Pull the `email` channel out of the raw `company_user.notifications` map.
/// Other channels (e.g. `slack`, written by the legacy app's advanced
/// notification settings) are preserved via [User.rawNotifications] and
/// re-emitted untouched on save, so editing email prefs doesn't wipe them.
List<String> _emailNotifications(Map<String, dynamic> notifications) {
  final email = notifications['email'];
  if (email is List) {
    return email.map((e) => e.toString()).toList(growable: false);
  }
  return const <String>[];
}

/// Per-(user, company) metadata. The role flags + raw permission string
/// drive feature-gating UI; not editable from User Details (lives under
/// User Management instead).
@freezed
abstract class CompanyUser with _$CompanyUser {
  const factory CompanyUser({
    @Default('') String permissions,
    @Default(false) bool isOwner,
    @Default(false) bool isAdmin,
    @Default(false) bool isLocked,
  }) = _CompanyUser;
}

/// The typed slice of `company_user.settings` the User Details screen edits.
/// Anything not here round-trips through [User.rawCompanyUserSettings].
@freezed
abstract class CompanyUserSettings with _$CompanyUserSettings {
  const CompanyUserSettings._();

  const factory CompanyUserSettings({@Default('') String accentColor}) =
      _CompanyUserSettings;

  factory CompanyUserSettings.fromJson(Map<String, dynamic> json) {
    return CompanyUserSettings(
      accentColor: json['accent_color']?.toString() ?? '',
    );
  }

  /// Serialise the typed fields back into a JSON map. Callers merge this on
  /// top of [User.rawCompanyUserSettings] so unmodelled keys (the React
  /// preferences blob, dashboard prefs, …) survive the round-trip.
  ///
  /// `accent_color` is emitted even when empty: a reset sets it to `''`, and
  /// without the key here the merge would keep the stale value from
  /// [User.rawCompanyUserSettings] and the reset wouldn't persist.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'accent_color': accentColor,
  };
}
