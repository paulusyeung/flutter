import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/dashboard/dashboard_activity.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/activity_card.dart';

import '../../../../_localization_helper.dart';

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback? onViewAll,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: ActivityCard(
              section: const AsyncSection<List<DashboardActivity>>.ready([]),
              onViewAll: onViewAll,
              onRetry: () {},
              onActivityTap: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hides the "View all" link when there is no destination', (
    tester,
  ) async {
    await _pump(tester, onViewAll: null);
    expect(find.text('View All'), findsNothing);
  });

  testWidgets('shows and fires "View all" when a destination exists', (
    tester,
  ) async {
    var tapped = false;
    await _pump(tester, onViewAll: () => tapped = true);
    expect(find.text('View All'), findsOneWidget);
    await tester.tap(find.text('View All'));
    expect(tapped, isTrue);
  });
}
