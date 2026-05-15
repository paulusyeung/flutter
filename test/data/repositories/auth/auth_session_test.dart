import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/repositories/auth/auth_session.dart';

/// Anchors the computed getters on [AuthSession] that the Account Management
/// Plan / Overview cards and the per-screen plan gates read. Trial math uses
/// `DateTime.now()`, so we phrase `trialStarted` / `planExpires` as offsets
/// from "now" rather than fixed timestamps.
AuthSession _session({
  String baseUrl = 'https://example.test',
  bool isHosted = true,
  String plan = '',
  String planExpires = '',
  String trialStarted = '',
  int numTrialDays = 0,
  String eInvoicingToken = '',
}) => AuthSession(
  baseUrl: baseUrl,
  isHosted: isHosted,
  accountId: 'acc1',
  companies: const [],
  currentCompanyId: '',
  plan: plan,
  planExpires: planExpires,
  trialStarted: trialStarted,
  numTrialDays: numTrialDays,
  eInvoicingToken: eInvoicingToken,
);

void main() {
  group('AuthSession.isPaidPlanSlug', () {
    test('true for pro / enterprise / premium_business_plus', () {
      expect(_session(plan: 'pro').isPaidPlanSlug, isTrue);
      expect(_session(plan: 'enterprise').isPaidPlanSlug, isTrue);
      expect(_session(plan: 'premium_business_plus').isPaidPlanSlug, isTrue);
    });

    test('false for free / unknown / empty', () {
      expect(_session().isPaidPlanSlug, isFalse);
      expect(_session(plan: 'free').isPaidPlanSlug, isFalse);
      expect(_session(plan: 'something_else').isPaidPlanSlug, isFalse);
    });

    test('does not factor in self-hosted (slug-only)', () {
      // Self-hosted unlocks features, but the slug check is intentionally
      // strict — `canAddCompany` uses this to decide whether the hosted
      // company-count cap applies, and self-hosted has its own branch upstream.
      expect(_session(isHosted: false).isPaidPlanSlug, isFalse);
    });
  });

  group('AuthSession.isSelfHosted / isHosted', () {
    test('isSelfHosted is the inverse of isHosted', () {
      expect(_session(isHosted: true).isSelfHosted, isFalse);
      expect(_session(isHosted: false).isSelfHosted, isTrue);
    });
  });

  group('AuthSession.isProPlan / isEnterprisePlan', () {
    test('self-hosted always unlocks pro AND enterprise', () {
      // No plan slug, no expiry, no trial — pure licensing model.
      final s = _session(isHosted: false);
      expect(s.isProPlan, isTrue);
      expect(s.isEnterprisePlan, isTrue);
    });

    test('hosted pro unlocks pro but not enterprise', () {
      final s = _session(plan: 'pro');
      expect(s.isProPlan, isTrue);
      expect(s.isEnterprisePlan, isFalse);
    });

    test('hosted enterprise implies pro (enterprise unlocks both)', () {
      // Mirrors v1's `isProPlan => isEnterprisePlan || plan == kPlanPro`.
      final s = _session(plan: 'enterprise');
      expect(s.isProPlan, isTrue);
      expect(s.isEnterprisePlan, isTrue);
    });

    test('hosted free is neither', () {
      expect(_session().isProPlan, isFalse);
      expect(_session().isEnterprisePlan, isFalse);
    });

    test('expired hosted plan reverts to free', () {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      final s = _session(plan: 'pro', planExpires: yesterday);
      expect(s.isProPlan, isFalse);
      expect(s.isEnterprisePlan, isFalse);
    });

    test('future planExpires keeps the plan active', () {
      final tomorrow = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String();
      final s = _session(plan: 'pro', planExpires: tomorrow);
      expect(s.isProPlan, isTrue);
    });
  });

  group('AuthSession.isPlanExpired', () {
    test('false when planExpires is empty', () {
      expect(_session(plan: 'pro').isPlanExpired, isFalse);
    });

    test('false when self-hosted (licensing model has no plan expiry)', () {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      expect(
        _session(isHosted: false, planExpires: yesterday).isPlanExpired,
        isFalse,
      );
    });

    test('true when in the past, false when in the future', () {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      final tomorrow = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String();
      expect(_session(planExpires: yesterday).isPlanExpired, isTrue);
      expect(_session(planExpires: tomorrow).isPlanExpired, isFalse);
    });

    test('false on malformed date string (defensive)', () {
      expect(_session(planExpires: 'not-a-date').isPlanExpired, isFalse);
    });
  });

  group('AuthSession.isPaidAccount', () {
    test('self-hosted always counts as paid', () {
      expect(_session(isHosted: false).isPaidAccount, isTrue);
    });

    test('hosted pro / enterprise, not trialing, not expired → paid', () {
      expect(_session(plan: 'pro').isPaidAccount, isTrue);
      expect(_session(plan: 'enterprise').isPaidAccount, isTrue);
    });

    test('trial subtracts: pro slug + active trial → not paid', () {
      final started = DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String();
      final s = _session(
        plan: 'pro',
        trialStarted: started,
        numTrialDays: 14,
      );
      expect(s.isTrial, isTrue);
      expect(s.isPaidAccount, isFalse);
    });

    test('hosted free → not paid', () {
      expect(_session().isPaidAccount, isFalse);
    });
  });

  group('AuthSession.isFreePlan', () {
    test('true for hosted accounts without pro / enterprise access', () {
      expect(_session().isFreePlan, isTrue);
      expect(_session(plan: 'free').isFreePlan, isTrue);
    });

    test('false for hosted pro / enterprise', () {
      expect(_session(plan: 'pro').isFreePlan, isFalse);
      expect(_session(plan: 'enterprise').isFreePlan, isFalse);
    });

    test('false for self-hosted regardless of plan slug', () {
      expect(_session(isHosted: false).isFreePlan, isFalse);
      expect(_session(isHosted: false, plan: 'free').isFreePlan, isFalse);
    });

    test('true for expired hosted paid plan (reverts to free behavior)', () {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      expect(
        _session(plan: 'pro', planExpires: yesterday).isFreePlan,
        isTrue,
      );
    });
  });

  group('AuthSession.isPremiumBusinessPlusPlan', () {
    test('strict slug check, ignores hosted/self-hosted', () {
      expect(
        _session(plan: 'premium_business_plus').isPremiumBusinessPlusPlan,
        isTrue,
      );
      expect(_session(plan: 'pro').isPremiumBusinessPlusPlan, isFalse);
    });
  });

  group('AuthSession.isTrial / trialDaysRemaining', () {
    test('not in a trial when trialStarted is empty', () {
      expect(_session(numTrialDays: 14).isTrial, isFalse);
      expect(_session(numTrialDays: 14).trialDaysRemaining, 0);
    });

    test('not in a trial when numTrialDays is zero', () {
      final started = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String();
      expect(_session(trialStarted: started).isTrial, isFalse);
      expect(_session(trialStarted: started).trialDaysRemaining, 0);
    });

    test('active trial: remaining shrinks as time passes', () {
      final started = DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String();
      final s = _session(trialStarted: started, numTrialDays: 14);
      expect(s.isTrial, isTrue);
      // 14 - 3 = 11 remaining (allow ±1 for boundary effects).
      expect(s.trialDaysRemaining, inInclusiveRange(10, 11));
    });

    test('expired trial: not a trial anymore, 0 days remaining', () {
      final started = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();
      final s = _session(trialStarted: started, numTrialDays: 14);
      expect(s.isTrial, isFalse);
      expect(s.trialDaysRemaining, 0);
    });

    test('malformed trialStarted falls back to 0 remaining', () {
      final s = _session(trialStarted: 'not-a-date', numTrialDays: 14);
      expect(s.trialDaysRemaining, 0);
      expect(s.isTrial, isFalse);
    });

    test(
      'trialDaysRemaining never exceeds numTrialDays (clock skew safety)',
      () {
        // Pretend the trial started "in the future" (e.g. server clock skew).
        // Should clamp to numTrialDays rather than returning a value > total.
        final started = DateTime.now()
            .add(const Duration(days: 5))
            .toIso8601String();
        final s = _session(trialStarted: started, numTrialDays: 14);
        expect(s.trialDaysRemaining, lessThanOrEqualTo(14));
      },
    );
  });

  group('AuthSession.isDemo', () {
    test('true for the canonical demo URL', () {
      expect(_session(baseUrl: kDemoBaseUrl).isDemo, isTrue);
    });

    test('true for demo URL with trailing slash or /api/v1 suffix', () {
      // The user may have typed (or pasted) a URL with /api/v1 appended or a
      // stray trailing slash. The getter normalizes before comparing.
      expect(
        _session(baseUrl: 'https://demo.invoiceninja.com/').isDemo,
        isTrue,
      );
      expect(
        _session(baseUrl: 'https://demo.invoiceninja.com/api/v1').isDemo,
        isTrue,
      );
      expect(
        _session(baseUrl: 'https://demo.invoiceninja.com/api/v1/').isDemo,
        isTrue,
      );
      expect(
        _session(baseUrl: '  https://demo.invoiceninja.com  ').isDemo,
        isTrue,
      );
    });

    test('false for the hosted production URL', () {
      expect(_session(baseUrl: 'https://invoicing.co').isDemo, isFalse);
    });

    test('false for self-hosted / test URLs', () {
      expect(_session(baseUrl: 'https://example.test').isDemo, isFalse);
      expect(
        _session(baseUrl: 'https://my-self-host.example.com').isDemo,
        isFalse,
      );
    });
  });

  group('AuthSession.eInvoicingToken', () {
    test('defaults to empty string when not supplied', () {
      expect(_session().eInvoicingToken, '');
    });

    test('round-trips through the constructor', () {
      expect(
        _session(eInvoicingToken: 'tok_abc123').eInvoicingToken,
        'tok_abc123',
      );
    });

    test('is preserved through copyWith (not part of the param surface)', () {
      // copyWith intentionally doesn't accept eInvoicingToken — the token
      // is set at login / refresh / restore time and shouldn't be edited
      // mid-session. Confirm it survives a copyWith that touches an
      // unrelated field.
      final original = _session(eInvoicingToken: 'tok_xyz');
      final copy = original.copyWith(currentCompanyId: 'co_42');
      expect(copy.eInvoicingToken, 'tok_xyz');
      expect(copy.currentCompanyId, 'co_42');
    });
  });
}
