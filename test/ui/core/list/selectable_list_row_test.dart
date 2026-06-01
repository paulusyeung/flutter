import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/list/selectable_list_row.dart';

const _childKey = Key('row-child');

Future<void> _pump(
  WidgetTester tester, {
  required bool selected,
  required bool urlSelected,
  required bool hideBottomDivider,
  required VoidCallback onTap,
  VoidCallback? onLongPress,
  TextDirection textDirection = TextDirection.ltr,
  Widget child = const SizedBox(key: _childKey, height: 48, width: 200),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      home: Scaffold(
        body: Directionality(
          textDirection: textDirection,
          child: SelectableListRow(
            selected: selected,
            urlSelected: urlSelected,
            hideBottomDivider: hideBottomDivider,
            onTap: onTap,
            onLongPress: onLongPress,
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// The single `DecoratedBox` the widget renders (inside [SelectableListRow]).
BoxDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(SelectableListRow),
      matching: find.byType(DecoratedBox),
    ),
  );
  return box.decoration as BoxDecoration;
}

void main() {
  const tokens = InTheme.light;

  testWidgets('selected → flat full-bleed accentSoft + 3px start accent '
      'border, no rounding, no Stack, no divider, no InkWell', (tester) async {
    await _pump(
      tester,
      selected: true,
      urlSelected: false,
      hideBottomDivider: true,
      onTap: () {},
    );

    final d = _decoration(tester);
    expect(d.color, tokens.accentSoft);
    expect(d.borderRadius, isNull);

    final border = d.border! as BorderDirectional;
    expect(border.start, BorderSide(color: tokens.accent, width: 3));
    expect(border.bottom, BorderSide.none);
    expect(border.top, BorderSide.none);
    expect(border.end, BorderSide.none);

    // No Stack/positioned overlay — the bar is a painted border so `child`
    // is never re-laid-out.
    expect(
      find.descendant(
        of: find.byType(SelectableListRow),
        matching: find.byType(PositionedDirectional),
      ),
      findsNothing,
    );

    // Content is NOT displaced — full-bleed, no inset.
    expect(
      tester.getTopLeft(find.byKey(_childKey)),
      tester.getTopLeft(find.byType(SelectableListRow)),
    );

    // Selected rows drop the InkWell (macOS opaque-hover fix).
    expect(
      find.descendant(
        of: find.byType(SelectableListRow),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(find.byKey(_childKey), findsOneWidget);
  });

  testWidgets('selected + urlSelected → identical flat render', (tester) async {
    await _pump(
      tester,
      selected: true,
      urlSelected: true,
      hideBottomDivider: true,
      onTap: () {},
    );

    final d = _decoration(tester);
    expect(d.color, tokens.accentSoft);
    expect(d.borderRadius, isNull);
    final border = d.border! as BorderDirectional;
    expect(border.start, BorderSide(color: tokens.accent, width: 3));
  });

  testWidgets('text does NOT raise on select — child top-left identical for '
      'selected vs unselected at fixed row height', (tester) async {
    // Mirrors the scaffold: ConstrainedBox(minHeight) around the row, and a
    // vertically-centered child whose intrinsic height is < the floor.
    Widget host(bool selected) => MaterialApp(
      theme: buildInTheme(InTheme.light),
      home: Scaffold(
        body: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: SelectableListRow(
            selected: selected,
            urlSelected: selected,
            hideBottomDivider: true,
            onTap: () {},
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                SizedBox(key: _childKey, height: 20, width: 100),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(false));
    final unselected = tester.getTopLeft(find.byKey(_childKey));

    await tester.pumpWidget(host(true));
    final selectedPos = tester.getTopLeft(find.byKey(_childKey));

    expect(selectedPos, unselected); // same dx AND dy — no vertical jump
  });

  testWidgets('not selected → bottom hairline + InkWell, no fill', (
    tester,
  ) async {
    await _pump(
      tester,
      selected: false,
      urlSelected: false,
      hideBottomDivider: false,
      onTap: () {},
    );

    final d = _decoration(tester);
    expect(d.color, isNull);
    final border = d.border! as Border;
    expect(border.bottom.color, tokens.border);
    expect(border.top, BorderSide.none);

    expect(
      find.descendant(
        of: find.byType(SelectableListRow),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });

  testWidgets('not selected + hideBottomDivider → no hairline', (tester) async {
    await _pump(
      tester,
      selected: false,
      urlSelected: false,
      hideBottomDivider: true,
      onTap: () {},
    );

    final border = _decoration(tester).border! as Border;
    expect(border.bottom, BorderSide.none);
  });

  testWidgets('onTap / onLongPress fire when selected', (tester) async {
    var taps = 0;
    var longs = 0;
    await _pump(
      tester,
      selected: true,
      urlSelected: true,
      hideBottomDivider: true,
      onTap: () => taps++,
      onLongPress: () => longs++,
    );
    await tester.tap(find.byType(SelectableListRow));
    await tester.longPress(find.byType(SelectableListRow));
    expect(taps, 1);
    expect(longs, 1);
  });

  testWidgets('onTap / onLongPress fire when not selected', (tester) async {
    var taps = 0;
    var longs = 0;
    await _pump(
      tester,
      selected: false,
      urlSelected: false,
      hideBottomDivider: false,
      onTap: () => taps++,
      onLongPress: () => longs++,
    );
    await tester.tap(find.byType(SelectableListRow));
    await tester.longPress(find.byType(SelectableListRow));
    expect(taps, 1);
    expect(longs, 1);
  });

  testWidgets('RTL → accent marker is a directional start border', (
    tester,
  ) async {
    await _pump(
      tester,
      selected: true,
      urlSelected: true,
      hideBottomDivider: true,
      onTap: () {},
      textDirection: TextDirection.rtl,
    );

    // BorderDirectional.start resolves to the right (leading) edge in RTL —
    // Flutter handles the resolution; we just assert the marker is the
    // directional start side, not a hard-coded left.
    final border = _decoration(tester).border! as BorderDirectional;
    expect(border.start, BorderSide(color: tokens.accent, width: 3));
  });
}
