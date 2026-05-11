import 'package:admin/app/theme.dart';
import 'package:admin/data/models/api/client_api_model.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Client makeClient() => Client.fromApi(
    ClientApi(id: 'c1', name: 'Acme Co', updatedAt: 1700000000),
  );

  Future<void> pump(
    WidgetTester tester, {
    required bool selecting,
    required bool selected,
    VoidCallback? onTap,
    VoidCallback? onSelectTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(Brightness.light),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: ClientListTile(
              client: makeClient(),
              formatter: null,
              wide: false,
              selecting: selecting,
              selected: selected,
              onTap: onTap ?? () {},
              onSelectTap: onSelectTap,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('hover on desktop reveals the leading checkbox', (tester) async {
    var selectTaps = 0;
    var rowTaps = 0;
    await pump(
      tester,
      selecting: false,
      selected: false,
      onTap: () => rowTaps++,
      onSelectTap: () => selectTaps++,
    );

    // No mouse yet: avatar visible, no checkbox.
    expect(find.byType(SelectionCheckbox), findsNothing);

    // Simulate a mouse hovering over the tile.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(ClientListTile)));
    await tester.pump();

    expect(find.byType(SelectionCheckbox), findsOneWidget);

    // Tap the revealed checkbox: onSelectTap fires; the underlying row's
    // onTap (which would navigate) must NOT fire.
    await tester.tap(find.byType(SelectionCheckbox));
    await tester.pump();

    expect(selectTaps, 1);
    expect(rowTaps, 0);
  });

  testWidgets('checkbox stays visible while selecting and reflects selected', (
    tester,
  ) async {
    await pump(tester, selecting: true, selected: true);

    final checkbox = find.byType(SelectionCheckbox);
    expect(checkbox, findsOneWidget);
    final widget = tester.widget<SelectionCheckbox>(checkbox);
    expect(widget.checked, isTrue);
  });

  testWidgets('without onSelectTap, hover does not reveal a checkbox', (
    tester,
  ) async {
    await pump(tester, selecting: false, selected: false, onSelectTap: null);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(ClientListTile)));
    await tester.pump();

    expect(find.byType(SelectionCheckbox), findsNothing);
  });
}
