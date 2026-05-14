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
    this.planExpires = '',
    this.trialPlan = '',
    this.trialStarted = '',
    this.numTrialDays = 0,
    this.defaultCompanyId = '',
    this.hostedClientCount = 0,
    this.hostedCompanyCount = 0,
    this.userId = '',
    this.userEmail = '',
    this.userPhone = '',
    this.userFirstName = '',
    this.userLastName = '',
    this.googleTwoFactorEnabled = false,
    this.verifiedPhoneNumber = false,
    this.biometricEnabled = false,
    this.referralCode = '',
    this.referralMeta = const <String, int>{},
    this.ninjaPortalUrl = '',
  });

  final String baseUrl;
  final bool isHosted;
  final String accountId;

  /// Sorted by display name; UI uses this for the company switcher.
  final List<AuthCompany> companies;

  final String currentCompanyId;

  /// Account plan slug, e.g. `pro`, `enterprise`, `premium_business_plus`,
  /// `` (free). Drives whether the hosted company-count limit gates "New
  /// Company" and what the Account Management → Plan card shows.
  final String plan;

  /// ISO date string for when the paid plan expires (hosted only). Empty
  /// when on a free plan or self-hosted. Decoded from
  /// `account.plan_expires` in the login envelope.
  final String planExpires;

  /// Plan slug the user is currently trialing (e.g. `pro`). Empty when no
  /// trial is active. Server populates only while `trial_started` is set.
  final String trialPlan;

  /// ISO datetime string for when the active trial started (hosted only).
  /// Empty when no trial is in progress.
  final String trialStarted;

  /// How many days long the active trial was provisioned for. Used together
  /// with [trialStarted] to render the trial-countdown progress bar.
  final int numTrialDays;

  /// The account-level default company — what new sessions land on when no
  /// per-device override is set. Drives the "Set default company" button on
  /// Account Management → Overview: visible when the active company differs.
  final String defaultCompanyId;

  /// On hosted free / trial plans, the max number of clients the account
  /// can hold. `0` on paid plans (no cap) and self-hosted.
  final int hostedClientCount;

  /// On hosted free / trial plans, the max number of companies the account's
  /// plan allows. `0` on paid plans (no cap) and self-hosted. Together with
  /// [companies] this drives the `canAddCompany` gate.
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

  /// Referral program data — hosted-only. `referralCode` slots into the
  /// referral URL `https://app.invoicing.co/#/register?rc=<code>`;
  /// `referralMeta` is the per-plan count map (`{free: 12, pro: 3, ...}`).
  /// Both are empty on self-hosted and on cold restore (we don't persist
  /// them — fresh login refills them).
  final String referralCode;
  final Map<String, int> referralMeta;

  /// Pre-signed URL for the user's hosted billing portal. Empty on
  /// self-hosted and on cold restore (we don't persist it; fresh login
  /// refills). Hosted users land here from Account Management → Plan
  /// → "Manage Plan" / "Upgrade Plan" / "Change Plan".
  final String ninjaPortalUrl;

  AuthCompany? get currentCompany {
    for (final c in companies) {
      if (c.id == currentCompanyId) return c;
    }
    return companies.isEmpty ? null : companies.first;
  }

  /// Hosted plan is "paid" (no per-company-count limit) when the plan slug
  /// is one of the entitled tiers. Matches admin-portal's `isPaidAccount`.
  bool get isPaidPlan =>
      plan == 'pro' || plan == 'enterprise' || plan == 'premium_business_plus';

  bool get isProPlan => plan == 'pro';
  bool get isEnterprisePlan => plan == 'enterprise';
  bool get isPremiumBusinessPlusPlan => plan == 'premium_business_plus';

  /// True when a trial is currently active: server sent a non-empty
  /// `trial_started`, and the elapsed days are still within `numTrialDays`.
  /// Returning the boolean is cheap; the UI uses [trialDaysRemaining] when
  /// it needs the actual countdown value.
  bool get isTrial {
    if (trialStarted.isEmpty || numTrialDays <= 0) return false;
    return trialDaysRemaining > 0;
  }

  /// Days left in the active trial, clamped to `[0, numTrialDays]`. Returns
  /// 0 when no trial is in progress so callers can render without a
  /// null-check.
  int get trialDaysRemaining {
    if (trialStarted.isEmpty || numTrialDays <= 0) return 0;
    final started = DateTime.tryParse(trialStarted);
    if (started == null) return 0;
    final elapsed = DateTime.now().difference(started).inDays;
    final remaining = numTrialDays - elapsed;
    if (remaining < 0) return 0;
    if (remaining > numTrialDays) return numTrialDays;
    return remaining;
  }

  /// First-failing reason for adding a new company, or `ok` when allowed.
  /// Order: demo build > not owner > hard cap > hosted plan limit.
  CanAddCompanyResult get canAddCompany {
    if (Env.demoMode) return CanAddCompanyResult.demoMode;
    final me = currentCompany;
    if (me == null || !me.isOwner) return CanAddCompanyResult.notOwner;
    if (companies.length >= kMaxCompaniesPerAccount) {
      return CanAddCompanyResult.capReached;
    }
    if (isHosted && !isPaidPlan && companies.length >= hostedCompanyCount) {
      return CanAddCompanyResult.hostedPlanLimit;
    }
    return CanAddCompanyResult.ok;
  }

  AuthSession copyWith({
    String? currentCompanyId,
    List<AuthCompany>? companies,
    String? defaultCompanyId,
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
    planExpires: planExpires,
    trialPlan: trialPlan,
    trialStarted: trialStarted,
    numTrialDays: numTrialDays,
    defaultCompanyId: defaultCompanyId ?? this.defaultCompanyId,
    hostedClientCount: hostedClientCount,
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
    referralCode: referralCode,
    referralMeta: referralMeta,
    ninjaPortalUrl: ninjaPortalUrl,
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
