import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/features/shell/widgets/sidebar_nav_item.dart';

/// Theme that supplies the `InTheme` extension `SidebarNavItem` reads via
/// `context.inTheme`.
ThemeData _theme() => ThemeData.light().copyWith(
  extensions: <ThemeExtension<dynamic>>[InTheme.light],
);

Widget _wrap(Widget child) => MaterialApp(
  theme: _theme(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('trailingHover is hidden until the mouse enters, shown on hover, '
      'hidden again on exit', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SidebarNavItem(
          label: 'Clients',
          icon: Icons.people_outline,
          active: false,
          onTap: () {},
          trailingHover: const SizedBox(
            key: Key('trailing'),
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
    await tester.pump();

    // Hidden before any pointer activity.
    expect(find.byKey(const Key('trailing')), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);

    // Moving over the row reveals the trailing widget.
    await gesture.moveTo(tester.getCenter(find.byType(SidebarNavItem)));
    await tester.pump();
    expect(find.byKey(const Key('trailing')), findsOneWidget);

    // Moving off the row hides it again.
    await gesture.moveTo(const Offset(1000, 1000));
    await tester.pump();
    expect(find.byKey(const Key('trailing')), findsNothing);
  });

  testWidgets(
    'tapping the trailingHover button does not also fire the row\'s onTap',
    (tester) async {
      var rowTaps = 0;
      var trailingTaps = 0;
      await tester.pumpWidget(
        _wrap(
          SidebarNavItem(
            label: 'Clients',
            icon: Icons.people_outline,
            active: false,
            onTap: () => rowTaps++,
            trailingHover: IconButton(
              key: const Key('trailing-btn'),
              icon: const Icon(Icons.add),
              onPressed: () => trailingTaps++,
            ),
          ),
        ),
      );
      await tester.pump();

      // Hover to reveal the trailing button.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(SidebarNavItem)));
      await tester.pump();

      await tester.tap(find.byKey(const Key('trailing-btn')));
      await tester.pump();

      expect(trailingTaps, 1);
      expect(
        rowTaps,
        0,
        reason:
            "IconButton's GestureDetector consumes the tap so the "
            "ancestor InkWell.onTap doesn't also fire",
      );
    },
  );

  testWidgets('compact mode ignores trailingHover even on hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SidebarNavItem(
          label: 'Clients',
          icon: Icons.people_outline,
          active: false,
          compact: true,
          onTap: () {},
          trailingHover: const SizedBox(
            key: Key('trailing'),
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(SidebarNavItem)));
    await tester.pump();
    expect(find.byKey(const Key('trailing')), findsNothing);
  });

  testWidgets('disabled rows do not surface the hover trailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SidebarNavItem(
          label: 'Invoices',
          icon: Icons.receipt_long_outlined,
          active: false,
          disabled: true,
          trailingHover: const SizedBox(
            key: Key('trailing'),
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(SidebarNavItem)));
    await tester.pump();
    expect(find.byKey(const Key('trailing')), findsNothing);
  });
}
