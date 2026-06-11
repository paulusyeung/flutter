import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/detail/entity_detail_header.dart';

import '../../../_localization_helper.dart';

/// Regression cover for the avatar fallback: a number-only identity (`#0009`,
/// the task/invoice/payment case) yields no initials, so the avatar must show
/// the entity-type icon rather than a bare `?`. Named entities keep initials.

Widget _host(Widget child) => MaterialApp(
  theme: buildInTheme(InTheme.light),
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  home: Scaffold(body: Center(child: child)),
);

EntityDetailHeader _header({
  required String displayName,
  IconData? fallbackIcon,
  String? number,
}) => EntityDetailHeader(
  seedForAvatar: 'seed',
  displayName: displayName,
  number: number,
  // Epoch-0 timestamps + null formatter render the subtitle as empty, so
  // the header needs no Formatter wiring for these avatar-focused checks.
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  isDeleted: false,
  isArchived: false,
  isDirty: false,
  fallbackIcon: fallbackIcon,
);

void main() {
  testWidgets('number-only identity shows the entity icon, not "?"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_header(displayName: '#0009', fallbackIcon: Icons.task)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.task), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });

  testWidgets('named identity shows tinted initials, no icon', (tester) async {
    await tester.pumpWidget(
      _host(_header(displayName: 'John Lennon', fallbackIcon: Icons.task)),
    );
    await tester.pumpAndSettle();

    expect(find.text('JL'), findsOneWidget);
    expect(find.byIcon(Icons.task), findsNothing);
  });

  testWidgets('number-only identity with no fallback icon keeps the "?" '
      'placeholder', (tester) async {
    await tester.pumpWidget(_host(_header(displayName: '#0009')));
    await tester.pumpAndSettle();

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('desktop: copyable #number renders inside the baseline row '
      'with no layout error', (tester) async {
    // The header number gets a CopyableValue (copies the bare number). On
    // desktop that wraps the text in a Row + hover icon inside the header's
    // baseline-aligned Row — guard against a baseline/layout regression.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        _host(_header(displayName: 'John Lennon', number: '0009')),
      );
      await tester.pumpAndSettle();

      expect(find.text('#0009'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
