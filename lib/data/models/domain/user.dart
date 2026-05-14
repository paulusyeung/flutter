import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/user_api_model.dart';

part 'user.freezed.dart';

/// Domain `User` — the authenticated user as the Settings > User Details
/// screen sees them. Companies the user has access to (and their
/// per-company-user records) carry through `companyUser`.
///
/// Settings live in two parallel maps mirroring the Company pattern:
///  * [companyUserSettings] — typed-ish [CompanyUserSettings] for the fields
///    we edit (accent_color, notification toggles, …).
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
    @Default(0) int lastLogin,
    @Default(0) int updatedAt,
    @Default(CompanyUser()) CompanyUser companyUser,
    @Default(<String, dynamic>{}) Map<String, dynamic> rawCompanyUserSettings,
    @Default(CompanyUserSettings()) CompanyUserSettings companyUserSettings,
    @Default(<String>[]) List<String> notificationsEmail,
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
      lastLogin: api.lastLogin,
      updatedAt: api.updatedAt,
      companyUser: CompanyUser(
        permissions: cu.permissions,
        isOwner: cu.isOwner,
        isAdmin: cu.isAdmin,
        isLocked: cu.isLocked,
      ),
      rawCompanyUserSettings: cu.settings,
      companyUserSettings: CompanyUserSettings.fromJson(cu.settings),
      notificationsEmail: cu.notifications.email,
    );
  }

  /// Display name for the user; falls back to email when no name is set
  /// (matches the legacy admin-portal behaviour).
  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }
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

  const factory CompanyUserSettings({
    @Default('') String accentColor,
    @Default(false) bool userLoggedInNotification,
    @Default(false) bool taskAssignedNotification,
    @Default(false) bool disableRecurringPaymentNotification,
    @Default(false) bool enableEInvoiceReceivedNotification,
  }) = _CompanyUserSettings;

  factory CompanyUserSettings.fromJson(Map<String, dynamic> json) {
    return CompanyUserSettings(
      accentColor: json['accent_color']?.toString() ?? '',
      userLoggedInNotification: _bool(json['user_logged_in_notification']),
      taskAssignedNotification: _bool(json['task_assigned_notification']),
      disableRecurringPaymentNotification: _bool(
        json['disable_recurring_payment_notification'],
      ),
      enableEInvoiceReceivedNotification: _bool(
        json['enable_e_invoice_received_notification'],
      ),
    );
  }

  /// Serialise the typed fields back into a JSON map. Callers merge this on
  /// top of [User.rawCompanyUserSettings] so unmodelled keys (the React
  /// preferences blob, dashboard prefs, …) survive the round-trip.
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (accentColor.isNotEmpty) 'accent_color': accentColor,
    'user_logged_in_notification': userLoggedInNotification,
    'task_assigned_notification': taskAssignedNotification,
    'disable_recurring_payment_notification':
        disableRecurringPaymentNotification,
    'enable_e_invoice_received_notification':
        enableEInvoiceReceivedNotification,
  };
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}
