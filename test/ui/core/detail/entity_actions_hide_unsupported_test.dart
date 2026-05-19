import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';

import '../../../_localization_helper.dart';

/// An action list exercising every visibility case:
///  * `Edit`      — enabled, shown
///  * `Refund`    — disabled (default `coming_soon` key) → hidden, since it
///                  isn't supported in this context
///  * `Busy`      — disabled but `disabledTooltipKey: null` (transient busy)
///                  → still rendered, inert
///  * `Clone`     — group whose children are all disabled, so the group is
///                  itself `enabled: false` → hidden (no empty submenu)
List<EntityActionItem<String>> _items() => [
  const EntityActionItem(
    kind: 'edit',
    icon: Icons.edit_outlined,
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
  const EntityActionItem(
    kind: 'clone',
    icon: Icons.copy,
    label: 'Clone',
    // Mirrors `cloneGroupActionItem`: enabled = children.any((c) => enabled).
    enabled: false,
    children: [
      EntityActionItem(
        kind: 'clone_to_quote',
        icon: Icons.copy,
        label: 'Clone to Quote',
        enabled: false,
      ),
    ],
  ),
];

Widget _host(Widget child) => MaterialApp(
  theme: buildInTheme(InTheme.light),
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('list popup menu hides unsupported actions, keeps busy ones', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(EntityActionsPopupButton<String>(items: _items())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Busy'), findsOneWidget); // transient-busy stays visible
    expect(find.text('Refund'), findsNothing); // unsupported → hidden
    expect(find.text('Clone'), findsNothing); // all-disabled group → hidden
  });

  testWidgets('the surviving busy item renders inert (onPressed == null)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(EntityActionsPopupButton<String>(items: _items())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    final busy = tester.widget<MenuItemButton>(
      find.ancestor(
        of: find.text('Busy'),
        matching: find.byType(MenuItemButton),
      ),
    );
    expect(busy.onPressed, isNull);
  });

  testWidgets('overflow action bar does not render a button for an '
      'unsupported action', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 1000, // wide enough that nothing overflows into "More"
          child: EntityOverflowActionBar<String>(items: _items()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Refund'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Clone'), findsNothing);
    // Busy is disabled-but-visible; Edit is the primary FilledButton.
    expect(find.widgetWithText(OutlinedButton, 'Busy'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Edit'), findsOneWidget);
  });
}
