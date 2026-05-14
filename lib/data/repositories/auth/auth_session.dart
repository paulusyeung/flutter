import 'package:flutter/foundation.dart';

import 'package:admin/app/env.dart';

/// Hard cap on companies per account (matches admin-portal's UI limit).
const int kMaxCompaniesPerAccount = 10;

/// Why "New Company" is unavailable, or `ok` if it is. The picker renders
/// the matching reason as an inline subtitle on the disabled row.
enum CanAddCompanyResult { ok, notOwner, capReached, hostedPlanLimit, demoMode }

/// What the rest of the app sees about the current login. Held as a single
/// immutable value so the shell can listen via `AuthRepository.session`.
@immutable
class AuthSession {
  const AuthSession({
    required this.baseUrl,
    required this.isHosted,
    required this.accountId,
    required this.companies,
    required this.currentCompanyId,
    this.plan = '',
    this.hostedCompanyCount = 0,
    this.userId = '',
    this.userEmail = '',
    this.userPhone = '',
    this.userFirstName = '',
    this.userLastName = '',
    this.googleTwoFactorEnabled = false,
    this.verifiedPhoneNumber = false,
    this.biometricEnabled = false,
  });

  final String baseUrl;
  final bool isHosted;
  final String accountId;

  /// Sorted by display name; UI uses this for the company switcher.
  final List<AuthCompany> companies;

  final String currentCompanyId;

  /// Account plan slug, e.g. `pro`, `enterprise`, `` (free). Drives whether
  /// the hosted company-count limit gates "New Company".
  final String plan;

  /// On hosted, the max number of companies the account's plan allows.
  /// `0` on self-hosted (limit doesn't apply).
  final int hostedCompanyCount;

  /// Authenticated user's id (`users.id`), used to address `/company_users/{id}`.
  final String userId;
  final String userEmail;
  final String userPhone;

  /// User-level name fields. Populated from `/users/{id}` after Settings >
  /// User Details edits land; the login envelope's `UserSummaryApi` doesn't
  /// carry them, so on a fresh login these stay empty until the first
  /// User Details refresh. The topbar / company picker fall back to email
  /// when both are blank.
  final String userFirstName;
  final String userLastName;

  /// True when the user has Google Authenticator–style 2FA enabled. Drives
  /// the enable-vs-disable branch of the 2FA settings screen.
  final bool googleTwoFactorEnabled;

  /// True when the user has completed SMS phone verification. On hosted this
  /// is the gate the server enforces before showing the QR setup; self-hosted
  /// skips the check.
  final bool verifiedPhoneNumber;

  /// User preference: gate cold launches with a biometric (FaceID / TouchID)
  /// prompt. Persisted via `kAuthBiometricEnabledKey`. The transient "we are
  /// currently locked" flag lives on `AuthRepository.requiresBiometricUnlock`
  /// — separating "preference" from "current state" keeps both observable
  /// without conflating them.
  final bool biometricEnabled;

  AuthCompany? get currentCompany {
    for (final c in companies) {
      if (c.id == currentCompanyId) return c;
    }
    return companies.isEmpty ? null : companies.first;
  }

  /// Hosted plan is "paid" (no per-company-count limit) when the plan slug
  /// is one of the entitled tiers. Matches admin-portal's `isPaidAccount`.
  bool get _isPaidPlan =>
      plan == 'pro' || plan == 'enterprise' || plan == 'premium_business_plus';

  /// First-failing reason for adding a new company, or `ok` when allowed.
  /// Order: demo build > not owner > hard cap > hosted plan limit.
  CanAddCompanyResult get canAddCompany {
    if (Env.demoMode) return CanAddCompanyResult.demoMode;
    final me = currentCompany;
    if (me == null || !me.isOwner) return CanAddCompanyResult.notOwner;
    if (companies.length >= kMaxCompaniesPerAccount) {
      return CanAddCompanyResult.capReached;
    }
    if (isHosted && !_isPaidPlan && companies.length >= hostedCompanyCount) {
      return CanAddCompanyResult.hostedPlanLimit;
    }
    return CanAddCompanyResult.ok;
  }

  AuthSession copyWith({
    String? currentCompanyId,
    List<AuthCompany>? companies,
    bool? googleTwoFactorEnabled,
    bool? verifiedPhoneNumber,
    String? userPhone,
    String? userEmail,
    String? userFirstName,
    String? userLastName,
    bool? biometricEnabled,
  }) => AuthSession(
    baseUrl: baseUrl,
    isHosted: isHosted,
    accountId: accountId,
    companies: companies ?? this.companies,
    currentCompanyId: currentCompanyId ?? this.currentCompanyId,
    plan: plan,
    hostedCompanyCount: hostedCompanyCount,
    userId: userId,
    userEmail: userEmail ?? this.userEmail,
    userPhone: userPhone ?? this.userPhone,
    userFirstName: userFirstName ?? this.userFirstName,
    userLastName: userLastName ?? this.userLastName,
    googleTwoFactorEnabled:
        googleTwoFactorEnabled ?? this.googleTwoFactorEnabled,
    verifiedPhoneNumber: verifiedPhoneNumber ?? this.verifiedPhoneNumber,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
  );
}

@immutable
class AuthCompany {
  const AuthCompany({
    required this.id,
    required this.name,
    required this.displayName,
    required this.permissions,
    required this.isAdmin,
    required this.isOwner,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String displayName;

  /// Absolute URL to the company's uploaded logo, or null when none is set.
  final String? logoUrl;

  /// Comma-separated permission strings — the format admin-portal uses too.
  final String permissions;

  final bool isAdmin;
  final bool isOwner;

  bool can(String permission) {
    if (isAdmin || isOwner) return true;
    if (permissions.isEmpty) return false;
    return permissions.split(',').contains(permission);
  }
}
