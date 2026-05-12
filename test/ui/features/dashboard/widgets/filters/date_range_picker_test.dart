import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/date_range_picker_button.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';
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
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await Navigator.of(context)
                      .push<DashboardDateRange?>(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            body: Center(
                              child: SizedBox(
                                width: 720,
                                child: DashboardDateRangePopover(
                                  current: current,
                                ),
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
    expect((result as DashboardPresetRange).preset, DashboardDatePreset.last7);
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

  testWidgets('popover opens at full width without layout overflow', (
    tester,
  ) async {
    // Reproduces the bug fix: `showMenu` capped the popover at ~280 px,
    // crushing the calendars. With the custom `PopupRoute`, the popover
    // should size to 960 px on a wide viewport with no overflow.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DashboardDateRange? captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Center(
            child: DateRangePickerButton(
              current: const DashboardPresetRange(
                DashboardDatePreset.thisMonth,
              ),
              onChange: (r) => captured = r,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DateRangePickerButton));
    await tester.pumpAndSettle();

    // No RenderFlex / layout overflow exceptions during open.
    expect(tester.takeException(), isNull);

    // Popover is on-screen at the requested wide-breakpoint width.
    final popoverFinder = find.byType(DashboardDateRangePopover);
    expect(popoverFinder, findsOneWidget);
    expect(tester.getSize(popoverFinder).width, 960.0);
    // Popover's left edge sits at or right of the persistent sidebar so the
    // preset rail isn't hidden behind it on wide layouts.
    final topLeft = tester.getTopLeft(popoverFinder);
    expect(topLeft.dx, greaterThanOrEqualTo(kInSidebarWidth + 16));

    // Tap a preset to dismiss cleanly.
    await tester.tap(find.text('Last 7 Days'));
    await tester.pumpAndSettle();
    expect(captured, isA<DashboardPresetRange>());
  });

  testWidgets('popover clamps width to fit a narrow viewport', (tester) async {
    // Below `Breakpoints.wide` (600 px) the shell hosts the sidebar in a
    // modal `AppDrawer` instead of inline, so the popover can use the full
    // viewport minus 16 px margins. At 500 px viewport: 500 - 32 = 468.
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Center(
            child: DateRangePickerButton(
              current: const DashboardPresetRange(
                DashboardDatePreset.thisMonth,
              ),
              onChange: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DateRangePickerButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final popoverFinder = find.byType(DashboardDateRangePopover);
    expect(popoverFinder, findsOneWidget);
    expect(tester.getSize(popoverFinder).width, 468.0);

    final topRight = tester.getTopRight(popoverFinder);
    expect(topRight.dx, lessThanOrEqualTo(500 - 16));
    final topLeft = tester.getTopLeft(popoverFinder);
    expect(topLeft.dx, 16.0);
  });

  testWidgets('Apply is disabled until two days are picked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
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
