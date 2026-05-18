import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';

import '../../../_localization_helper.dart';

/// Builds the canonical action list: a primary "Edit" item (the only place
/// `isPrimary` is ever set in the app) plus an ordinary "Archive" item.
List<EntityActionItem<String>> _items({
  required VoidCallback onEdit,
  required VoidCallback onArchive,
}) => [
  EntityActionItem(
    kind: 'edit',
    icon: Icons.edit_outlined,
    label: 'Edit',
    enabled: true,
    isPrimary: true,
    onTap: onEdit,
  ),
  EntityActionItem(
    kind: 'archive',
    icon: Icons.archive_outlined,
    label: 'Archive',
    enabled: true,
    onTap: onArchive,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required bool splitEditAction,
  bool editEnabled = true,
  IconData icon = Icons.more_vert,
  required VoidCallback onEdit,
  required VoidCallback onArchive,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: Center(
          child: EntityActionsPopupButton<String>(
            splitEditAction: splitEditAction,
            editEnabled: editEnabled,
            icon: icon,
            items: _items(onEdit: onEdit, onArchive: onArchive),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('split mode: standalone edit button fires onTap and is '
      'removed from the overflow menu', (tester) async {
    var edited = 0;
    var archived = 0;
    await _pump(
      tester,
      splitEditAction: true,
      onEdit: () => edited++,
      onArchive: () => archived++,
    );

    final editButton = find.widgetWithIcon(
      IconButton,
      MdiIcons.circleEditOutline,
    );
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(edited, 1);
    expect(archived, 0);

    // Open the `…` menu — Edit must no longer be listed, Archive must be.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('non-split mode: no standalone edit button, Edit stays in '
      'the menu (unchanged behavior)', (tester) async {
    await _pump(
      tester,
      splitEditAction: false,
      onEdit: () {},
      onArchive: () {},
    );

    expect(
      find.widgetWithIcon(IconButton, MdiIcons.circleEditOutline),
      findsNothing,
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('split mode forces the vertical 3-dot overflow icon even when '
      'a horizontal icon is passed', (tester) async {
    await _pump(
      tester,
      splitEditAction: true,
      icon: Icons.more_horiz,
      onEdit: () {},
      onArchive: () {},
    );

    expect(find.widgetWithIcon(IconButton, Icons.more_vert), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.more_horiz), findsNothing);
    expect(
      find.widgetWithIcon(IconButton, MdiIcons.circleEditOutline),
      findsOneWidget,
    );
  });

  testWidgets('split mode + editEnabled:false: pencil renders disabled and '
      'does nothing when tapped', (tester) async {
    var edited = 0;
    await _pump(
      tester,
      splitEditAction: true,
      editEnabled: false,
      onEdit: () => edited++,
      onArchive: () {},
    );

    final editButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, MdiIcons.circleEditOutline),
    );
    expect(editButton.onPressed, isNull);

    await tester.tap(
      find.widgetWithIcon(IconButton, MdiIcons.circleEditOutline),
    );
    await tester.pumpAndSettle();
    expect(edited, 0);
  });
}
