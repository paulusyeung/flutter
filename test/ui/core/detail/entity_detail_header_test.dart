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
}) => EntityDetailHeader(
  seedForAvatar: 'seed',
  displayName: displayName,
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
}
