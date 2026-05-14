import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/repositories/auth/auth_session.dart';

/// Anchors the new computed getters on [AuthSession] that the Account
/// Management Plan / Overview cards read for the trial countdown + plan
/// label. The trial math uses `DateTime.now()`, so the tests phrase
/// `trialStarted` as offsets from "now" rather than fixed timestamps.
AuthSession _session({
  String plan = '',
  String trialStarted = '',
  int numTrialDays = 0,
}) => AuthSession(
  baseUrl: 'https://example.test',
  isHosted: true,
  accountId: 'acc1',
  companies: const [],
  currentCompanyId: '',
  plan: plan,
  trialStarted: trialStarted,
  numTrialDays: numTrialDays,
);

void main() {
  group('AuthSession plan helpers', () {
    test('isPaidPlan is true for pro / enterprise / premium_business_plus', () {
      expect(_session(plan: 'pro').isPaidPlan, isTrue);
      expect(_session(plan: 'enterprise').isPaidPlan, isTrue);
      expect(_session(plan: 'premium_business_plus').isPaidPlan, isTrue);
    });

    test('isPaidPlan is false for free / unknown / empty', () {
      expect(_session().isPaidPlan, isFalse);
      expect(_session(plan: 'free').isPaidPlan, isFalse);
      expect(_session(plan: 'something_else').isPaidPlan, isFalse);
    });

    test('plan-specific getters', () {
      expect(_session(plan: 'pro').isProPlan, isTrue);
      expect(_session(plan: 'enterprise').isEnterprisePlan, isTrue);
      expect(_session(plan: 'premium_business_plus').isPremiumBusinessPlusPlan,
          isTrue);
      expect(_session(plan: 'pro').isEnterprisePlan, isFalse);
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
}
