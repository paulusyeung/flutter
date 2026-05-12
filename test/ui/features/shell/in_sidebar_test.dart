import 'package:admin/data/db/app_database.dart';
import 'package:admin/ui/features/shell/widgets/in_sidebar.dart';
import 'package:admin/ui/features/shell/widgets/sidebar_nav_item.dart';
import 'package:drift/drift.dart' show Value;
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

  testWidgets('collapsed mode hides labels and shows tooltips', (tester) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co')],
    );
    addTearDown(fixture.dispose);
    await fixture.services.sidebar.set(true);

    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        InSidebar(currentBranch: 1, onSelectBranch: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNothing);
    expect(find.byTooltip('Dashboard'), findsOneWidget);
    expect(
      tester.getSize(find.byType(InSidebar)).width,
      kInSidebarCollapsedWidth,
    );
    await _drain(tester);
  });

  testWidgets('tapping the collapse toggle flips services.sidebar', (
    tester,
  ) async {
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
    expect(fixture.services.sidebar.value, isFalse);

    await tester.tap(find.byTooltip('Hide Sidebar'));
    await tester.pumpAndSettle();

    expect(fixture.services.sidebar.value, isTrue);
    expect(
      tester.getSize(find.byType(InSidebar)).width,
      kInSidebarCollapsedWidth,
    );
    await _drain(tester);
  });

  testWidgets('clients badge survives collapsed mode as a dot', (tester) async {
    final fixture = await buildFixture(
      companies: const [FakeCompany(id: 'c1', name: 'Acme Co')],
    );
    addTearDown(fixture.dispose);
    await fixture.db.clientDao.upsertAll([
      ClientsCompanion.insert(
        id: 'cl1',
        companyId: 'c1',
        name: 'A',
        number: '',
        email: '',
        displayName: 'A',
        balance: '0',
        updatedAt: 0,
        payload: '{}',
      ),
      ClientsCompanion.insert(
        id: 'cl2',
        companyId: 'c1',
        name: 'B',
        number: '',
        email: '',
        displayName: 'B',
        balance: '0',
        updatedAt: 0,
        payload: '{}',
        archivedAt: const Value.absent(),
      ),
    ]);
    await fixture.services.sidebar.set(true);

    await tester.pumpWidget(
      wrapWithShell(
        fixture.services,
        InSidebar(currentBranch: 0, onSelectBranch: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clients-badge-dot')), findsOneWidget);
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
