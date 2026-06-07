// Regression: signing out while a billing-doc edit screen is mounted used to
// crash with a full-screen framework assertion. The root cause was
// `BillingEditTotals._ensureStream` force-unwrapping `auth.session.value!`,
// which is null during logout — the still-mounted edit screen rebuilds once
// more on the logout frame (its LayoutBuilder re-inflates the totals bar →
// didChangeDependencies → _ensureStream), the `!` threw mid-layout, and the
// downstream symptom was the `InheritedElement.notifyClients` "is not true"
// assertion. The fix routes the read through the nullable
// `auth.currentCompanyId`.

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/domain/billing/totals_calculator.dart';
import 'package:admin/ui/features/billing_shared/billing_edit_totals.dart';

import '../shell/_shell_test_helpers.dart';

void main() {
  BillingTotalsResult zeroTotals(int precision) => BillingTotalsResult(
    subtotal: Decimal.zero,
    total: Decimal.zero,
    taxAmount: Decimal.zero,
    taxBreakdown: const {},
  );

  testWidgets('mounts without throwing when the session is null (logout '
      'teardown)', (tester) async {
    final fixture = await buildFixture(
      companies: [const FakeCompany(id: 'co_a', name: 'Acme')],
    );
    addTearDown(fixture.dispose);

    // Mimic the logout that clears the session out from under a still-mounted
    // edit screen. After this `auth.session.value` is null.
    await fixture.services.auth.logout();
    expect(fixture.services.auth.currentCompanyId, isNull);

    // Fresh mount with a client selected → `_ensureStream` takes the
    // `clients.watch(companyId: ...)` branch, the exact path that read
    // `session.value!.currentCompanyId` and threw before the fix.
    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        BillingEditTotals(
          totalsAt: zeroTotals,
          discount: Decimal.zero,
          discountIsAmount: false,
          clientId: 'client_x',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
