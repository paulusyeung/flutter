import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/domain/plan_gate.dart';

AuthSession _s({
  bool isHosted = true,
  String plan = '',
  int trialDaysLeft = -1,
}) => AuthSession(
  baseUrl: 'https://example.test',
  isHosted: isHosted,
  accountId: 'a',
  companies: const [],
  currentCompanyId: '',
  plan: plan,
  trialDaysLeft: trialDaysLeft,
);

void main() {
  group('planGateFor — settings slugs', () {
    test('free hosted user is gated on a pro section', () {
      expect(
        planGateFor(_s(), settingsSlug: 'invoice_design'),
        PlanTier.pro,
      );
    });

    test('free hosted user is gated on an enterprise section', () {
      expect(planGateFor(_s(), settingsSlug: 'users'), PlanTier.enterprise);
      expect(
        planGateFor(_s(), settingsSlug: 'e_invoice'),
        PlanTier.enterprise,
      );
    });

    test('pro user clears pro gates but not enterprise', () {
      final pro = _s(plan: 'pro');
      expect(planGateFor(pro, settingsSlug: 'invoice_design'), isNull);
      expect(
        planGateFor(pro, settingsSlug: 'users'),
        PlanTier.enterprise,
      );
    });

    test('trial user clears both (trial-aware, no regression)', () {
      final trial = _s(trialDaysLeft: 7);
      expect(planGateFor(trial, settingsSlug: 'invoice_design'), isNull);
      expect(planGateFor(trial, settingsSlug: 'users'), isNull);
    });

    test('group_settings is Pro-gated and trial-aware (R1 regression)', () {
      expect(
        planGateFor(_s(), settingsSlug: 'group_settings'),
        PlanTier.pro,
      );
      expect(
        planGateFor(_s(plan: 'pro'), settingsSlug: 'group_settings'),
        isNull,
      );
      expect(
        planGateFor(_s(trialDaysLeft: 3), settingsSlug: 'group_settings'),
        isNull,
      );
    });

    test('self-hosted clears everything', () {
      final sh = _s(isHosted: false);
      expect(planGateFor(sh, settingsSlug: 'users'), isNull);
    });

    test('ungated slug returns null', () {
      expect(planGateFor(_s(), settingsSlug: 'company_details'), isNull);
    });

    test('null session fails open (read) — no gate surfaced', () {
      expect(planGateFor(null, settingsSlug: 'invoice_design'), isNull);
    });
  });

  group('planGateFor — features', () {
    test('reports is pro, documents/e-invoice are enterprise', () {
      final free = _s();
      expect(
        planGateFor(free, feature: GatedFeature.reports),
        PlanTier.pro,
      );
      expect(
        planGateFor(free, feature: GatedFeature.documents),
        PlanTier.enterprise,
      );
    });

    test('pro user still gated on enterprise documents', () {
      expect(
        planGateFor(_s(plan: 'pro'), feature: GatedFeature.documents),
        PlanTier.enterprise,
      );
      expect(
        planGateFor(_s(plan: 'pro'), feature: GatedFeature.reports),
        isNull,
      );
    });
  });
}
