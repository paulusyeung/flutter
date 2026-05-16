import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/features/dashboard/widgets/delta_chip.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_card.dart';
import 'package:admin/ui/features/dashboard/widgets/kpi_sparkline.dart';

import '../../../../_localization_helper.dart';

Future<void> _pump(WidgetTester tester, {List<double>? sparkline}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 140,
            child: KpiCard(
              label: 'Outstanding',
              value: r'$1,000',
              deltaPercent: 4.2,
              goodDirection: GoodDirection.down,
              sparklineValues: sparkline,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders no sparkline when sparklineValues is null', (
    tester,
  ) async {
    await _pump(tester, sparkline: null);
    expect(find.byType(KpiSparkline), findsNothing);
    // The real period-over-period signal (delta chip) still renders.
    expect(find.byType(DeltaChip), findsOneWidget);
  });

  testWidgets('renders the sparkline when real values are provided', (
    tester,
  ) async {
    await _pump(tester, sparkline: const [1, 2, 3, 4, 5]);
    expect(find.byType(KpiSparkline), findsOneWidget);
  });
}
