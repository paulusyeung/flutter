import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/widgets/party_money_cell.dart';

/// Full party→currency resolution (vendor/client → `currency_id`) is exercised
/// against the real Drift stack in the live demo run and mirrors the proven
/// `BillingEditTotals` resolution. This unit test pins the no-party fallback —
/// the only branch with no `Services` in the tree (a billing row with no client
/// /vendor yet) must yield a null currency and never touch the provider.
void main() {
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
}
