// Shared responsive-regression pump helper. Extracted from
// `clients/client_detail_cards_grid_test.dart` (the original ad-hoc `_pump`)
// so every responsive test sets up the surface, theme, and localization the
// same way and asserts overflow consistently.
//
// Usage:
//   await pumpAt(tester, 500, MyWidget());            // narrow
//   await pumpAt(tester, 1200, MyWidget());           // wide
//   expectNoOverflow(tester);                         // no RenderFlex throw
//
// The widget is wrapped in a scrollable Scaffold body so vertically tall
// content doesn't itself trip an unbounded-height error — the point is to
// catch *horizontal* overflow and unbounded-width mistakes at each width.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';

import '_localization_helper.dart';

/// Standard responsive breakpoints to sweep: narrow (mobile / sidebar),
/// medium (split), wide (desktop).
const kResponsiveWidths = <double>[500, 800, 1200];

Future<void> pumpAt(
  WidgetTester tester,
  double width,
  Widget child, {
  double height = 1400,
  bool scroll = true,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final body = scroll ? SingleChildScrollView(child: child) : child;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(body: body),
    ),
  );
  await tester.pump();
}

/// Fails if the last pump produced a layout exception (RenderFlex overflow,
/// unbounded constraints, …). Call after [pumpAt].
void expectNoOverflow(WidgetTester tester) {
  expect(
    tester.takeException(),
    isNull,
    reason: 'layout overflow / constraint violation at this width',
  );
}
