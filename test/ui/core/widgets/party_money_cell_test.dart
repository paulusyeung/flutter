import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/vendor_api_model.dart';
import 'package:admin/ui/core/widgets/party_money_cell.dart';

import '../../features/shell/_shell_test_helpers.dart';

void main() {
  // The no-party branch is the only one with no `Services` in the tree (a
  // billing row with no client/vendor yet) — it must yield a null currency and
  // never touch the provider.
  testWidgets('PartyCurrencyBuilder yields a null currency with no party', (
    tester,
  ) async {
    String? captured = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: PartyCurrencyBuilder(
          builder: (context, currencyId) {
            captured = currencyId;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(captured, isNull);
  });

  // Core path: resolve the party's own `currency_id` from Drift so money cells
  // render the document's currency, not the company default. Seeds a vendor on
  // a non-company currency and asserts the builder surfaces it.
  testWidgets('PartyCurrencyBuilder resolves a vendor\'s currency id', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: [const FakeCompany(id: 'co1', name: 'Co')],
    );
    addTearDown(fixture.dispose);

    // Seed a clean vendor row (id 'v1') whose currency is '3' (≠ company).
    await fixture.services.vendors.applyUpdateResponse(
      companyId: 'co1',
      serverResponse: const VendorApi(id: 'v1', name: 'V', currencyId: '3'),
    );

    String? captured = 'unset';
    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        PartyCurrencyBuilder(
          vendorId: 'v1',
          builder: (context, currencyId) {
            captured = currencyId;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    // The vendor watch emits asynchronously; pump a few bounded frames for it
    // (not pumpAndSettle — the fixture's Services keep timers pending).
    for (var i = 0; i < 10 && captured != '3'; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(captured, '3');

    // Dispose the subtree inside the test body so the Drift watch's
    // stream-close timer (`StreamQueryStore.markAsClosed` schedules a
    // zero-duration Timer on unsubscribe) fires before the binding's
    // end-of-test `!timersPending` invariant check.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
