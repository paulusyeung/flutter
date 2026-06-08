import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/mdi_icons.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';

import '../../../_localization_helper.dart';

/// Mirrors the fixture in `entity_actions_hide_unsupported_test.dart`: a
/// primary Edit, a hidden action (Refund), and a transient-busy inert action
/// (Busy) that stays visible.
List<EntityActionItem<String>> _items() => [
  const EntityActionItem(
    kind: 'edit',
    icon: MdiIcons.circleEditOutline,
    label: 'Edit',
    enabled: true,
    isPrimary: true,
  ),
  const EntityActionItem(
    kind: 'refund',
    icon: Icons.money_off,
    label: 'Refund',
    enabled: false,
  ),
  const EntityActionItem(
    kind: 'busy',
    icon: Icons.hourglass_empty,
    label: 'Busy',
    enabled: false,
    disabledTooltipKey: null,
  ),
];

/// A soft-deleted record drops the primary Edit and keeps only lifecycle ops.
const _noPrimary = <EntityActionItem<String>>[
  EntityActionItem(
    kind: 'archive',
    icon: Icons.archive_outlined,
    label: 'Archive',
    enabled: true,
    isLifecycle: true,
  ),
  EntityActionItem(
    kind: 'delete',
    icon: Icons.delete_outline,
    label: 'Delete',
    enabled: true,
    isLifecycle: true,
  ),
];

/// A record whose only action is Edit (e.g. a bank account with no lifecycle).
const _editOnly = <EntityActionItem<String>>[
  EntityActionItem(
    kind: 'edit',
    icon: MdiIcons.circleEditOutline,
    label: 'Edit',
    enabled: true,
    isPrimary: true,
  ),
];

Widget _host(Widget child) => MaterialApp(
  theme: buildInTheme(InTheme.light),
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('surfaces the primary Edit button + a ⋮ overflow with the rest', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(EntityDetailActionsRow<String>(items: _items())),
    );
    await tester.pumpAndSettle();

    // Edit is surfaced as its own FilledButton; the rest live behind the ⋮.
    expect(find.widgetWithText(FilledButton, 'Edit'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // The overflow holds the transient-busy item — not Edit (it's the surfaced
    // button, removed from the menu), nor the unsupported Refund.
    expect(find.text('Busy'), findsOneWidget);
    expect(find.widgetWithText(MenuItemButton, 'Edit'), findsNothing);
    expect(find.text('Refund'), findsNothing);
  });

  testWidgets('with no primary action, shows only the ⋮ overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(EntityDetailActionsRow<String>(items: _noPrimary)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('with only the primary action, shows Edit and no ⋮', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(EntityDetailActionsRow<String>(items: _editOnly)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Edit'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}
