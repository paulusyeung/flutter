import 'package:admin/ui/features/shell/widgets/show_theme_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_shell_test_helpers.dart';

// Pumps the `ThemeMenu` content directly (as company_picker_test pumps
// `CompanyPicker`) rather than driving the PopupRoute — `wrapWithShell` uses a
// plain `MaterialApp`, so the "Device settings" `GoRouter.maybeOf(context)` is
// null and that row's navigation safely no-ops.
void main() {
  testWidgets('renders the three modes with the active one checked', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co')],
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const ThemeMenu(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    // Labels are rendered via Text.rich, so match the rich text.
    expect(find.text('Light', findRichText: true), findsOneWidget);
    expect(find.text('Dark', findRichText: true), findsOneWidget);
    // The System row shows its resolved brightness inline ("System · Light"
    // under the test's default light platform brightness).
    expect(find.textContaining('System'), findsOneWidget);

    // The shortcut into the full appearance settings.
    expect(find.text('Device Settings'), findsOneWidget);

    // Default mode is System -> exactly one check, on the System row.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('tapping a mode row applies it to the ThemeController', (
    tester,
  ) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co')],
    );
    addTearDown(fixture.dispose);

    expect(fixture.services.theme.themeMode, ThemeMode.system);

    await tester.pumpWidget(
      wrapWithShell(fixture.services, const ThemeMenu(fillWidth: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark', findRichText: true));
    await tester.pumpAndSettle();

    expect(fixture.services.theme.themeMode, ThemeMode.dark);
    // The check follows the selection.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
