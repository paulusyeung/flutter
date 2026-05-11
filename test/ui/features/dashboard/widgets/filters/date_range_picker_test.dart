import 'package:admin/app/theme.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/date_range_picker_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../_localization_helper.dart';

void main() {
  Future<DashboardDateRange?> pumpAndCapture(
    WidgetTester tester,
    DashboardDateRange current,
    Future<void> Function(WidgetTester tester) interact,
  ) async {
    DashboardDateRange? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(Brightness.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await Navigator.of(context).push<DashboardDateRange?>(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: Center(
                          child: SizedBox(
                            width: 720,
                            child: DashboardDateRangePopover(current: current),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await interact(tester);
    await tester.pumpAndSettle();
    return captured;
  }

  testWidgets('tapping a preset chip pops with that preset', (tester) async {
    final result = await pumpAndCapture(
      tester,
      const DashboardPresetRange(DashboardDatePreset.thisMonth),
      (tester) async {
        await tester.tap(find.text('Last 7 Days'));
      },
    );
    expect(result, isA<DashboardPresetRange>());
    expect(
      (result as DashboardPresetRange).preset,
      DashboardDatePreset.last7,
    );
  });

  testWidgets('tapping two days then Apply pops with a custom range', (
    tester,
  ) async {
    // Anchor the popover on a fixed initial range so we know which dates are
    // visible: pre-seeding with a custom range positions the calendar on the
    // start month.
    final result = await pumpAndCapture(
      tester,
      DashboardCustomRange(
        start: const Date(2026, 3, 1),
        end: const Date(2026, 3, 1),
      ),
      (tester) async {
        // Tap day 5 (start) then day 12 (end) in the left calendar (March).
        // Both months render the digits 5 and 12 so we restrict by the cell
        // height; the start-edge tap is the first '5' encountered.
        await tester.tap(find.text('5').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('12').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply'));
      },
    );
    expect(result, isA<DashboardCustomRange>());
    final custom = result! as DashboardCustomRange;
    expect(custom.start, const Date(2026, 3, 5));
    expect(custom.end, const Date(2026, 3, 12));
  });

  testWidgets('Cancel returns null', (tester) async {
    final result = await pumpAndCapture(
      tester,
      const DashboardPresetRange(DashboardDatePreset.thisMonth),
      (tester) async {
        await tester.tap(find.text('Cancel'));
      },
    );
    expect(result, isNull);
  });

  testWidgets('Apply is disabled until two days are picked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(Brightness.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 720,
              child: DashboardDateRangePopover(
                current: const DashboardPresetRange(
                  DashboardDatePreset.thisMonth,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Pre-seeded range = today's month, both start/end set → Apply enabled.
    final applyFinder = find.widgetWithText(FilledButton, 'Apply');
    final applyInitial = tester.widget<FilledButton>(applyFinder);
    expect(applyInitial.onPressed, isNotNull);

    // Tap a single day to enter "start only" state — Apply disables.
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();
    final applyAfter = tester.widget<FilledButton>(applyFinder);
    expect(applyAfter.onPressed, isNull);
  });
}
