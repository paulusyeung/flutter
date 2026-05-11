import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';
import 'package:admin/ui/features/shell/widgets/sidebar_nav_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_shell_test_helpers.dart';

/// Pumps an empty widget after the test body so StreamBuilders (Drift watchers
/// inside the sidebar) cancel cleanly and don't leave pending microtasks.
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders current company in switcher header', (tester) async {
    final fixture = await buildFixture(
      companies: const [
        FakeCompany(id: 'c1', name: 'Acme Co'),
        FakeCompany(id: 'c2', name: 'Stark Industries'),
      ],
      currentCompanyId: 'c1',
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        InSidebar(currentBranch: 0, onSelectBranch: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acme Co'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('active branch is reflected on the Clients tile', (tester) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co')],
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        InSidebar(currentBranch: 0, onSelectBranch: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    final navItems = tester.widgetList<SidebarNavItem>(
      find.byType(SidebarNavItem),
    );
    final clientsTile = navItems.firstWhere((w) => w.label == 'Clients');
    expect(clientsTile.active, isTrue);
    final dashboardTile = navItems.firstWhere((w) => w.label == 'Dashboard');
    expect(dashboardTile.active, isFalse);
    await _drain(tester);
  });

  testWidgets(
    'tapping an enabled branch fires onSelectBranch with the right index',
    (tester) async {
      final fixture = await buildFixture(
        companies: const [FakeCompany(id: 'c1', name: 'Acme Co')],
      );
      addTearDown(fixture.dispose);

      final selections = <int>[];
      await tester.pumpWidget(
        wrapWithShell(
          fixture.services,
          InSidebar(currentBranch: 0, onSelectBranch: selections.add),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dashboard'));
      await tester.pump();
      expect(selections, [1]);
      await _drain(tester);
    },
  );

}
