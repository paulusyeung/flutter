import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_suggestion_menu.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/filter_token_chip.dart';
import 'package:admin/ui/features/clients/client_filter_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../_localization_helper.dart';

/// Coverage for the pieces of the token search subsystem that fit a fast
/// unit-test loop: input parsing (`FilterInputParse.of`) and the chip
/// widget. Behavioral coverage of the FilterKey writes lives in
/// `test/ui/features/clients/client_filter_keys_test.dart`; the
/// repo / query-string path is in `client_repository_test.dart`.
///
/// The full token field is intentionally NOT tested here: its
/// `OverlayPortal` + composited-transform follower + focus-driven stream
/// subscriptions don't settle cleanly under `pumpAndSettle`, so we get
/// orders of magnitude more value out of the focused unit tests plus
/// manual / smoke checks at the screen level.

void main() {
  group('FilterInputParse.of', () {
    final keys = <FilterKey>[const IsFilterKey(), const GroupFilterKey()];

    test('no colon → key mode with the input as query', () {
      final parse = FilterInputParse.of('acme', keys);
      expect(parse.matchedKey, isNull);
      expect(parse.query, 'acme');
    });

    test('known prefix → value mode with the tail as query', () {
      final parse = FilterInputParse.of('is:arch', keys);
      expect(parse.matchedKey?.id, 'is');
      expect(parse.query, 'arch');
    });

    test('alias resolves to the same key (`status` → `is`)', () {
      final parse = FilterInputParse.of('status:active', keys);
      expect(parse.matchedKey?.id, 'is');
      expect(parse.query, 'active');
    });

    test('unmatched prefix falls back to free text', () {
      final parse = FilterInputParse.of('unknown:foo', keys);
      expect(parse.matchedKey, isNull);
      expect(
        parse.query,
        'unknown:foo',
        reason:
            'unrecognised prefix is left as-is so the user can search '
            'literally for it via the "Search for" row',
      );
    });
  });

  group('FilterTokenChip', () {
    Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      theme: buildInTheme(Brightness.light),
      home: Scaffold(body: child),
    );

    const sampleToken = FilterToken(
      keyId: 'is',
      displayKey: 'Status',
      rawValue: 'archived',
      displayValue: 'Archived',
    );

    testWidgets('renders the display value', (tester) async {
      await tester.pumpWidget(
        wrap(FilterTokenChip(token: sampleToken, onRemove: () {})),
      );
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('status'), findsOneWidget);
    });

    testWidgets(
      'close icon fires onRemove; chip body is inert when onTap is null',
      (tester) async {
        var removed = 0;
        await tester.pumpWidget(
          wrap(FilterTokenChip(token: sampleToken, onRemove: () => removed++)),
        );

        // No onTap supplied → body tap does nothing (the historical
        // "inert chip" contract still holds for that case).
        await tester.tap(find.text('Archived'));
        await tester.pump();
        expect(removed, 0);

        // The × IconButton stays interactive regardless.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        expect(removed, 1);
      },
    );

    testWidgets('body tap fires onTap when supplied; × still fires onRemove', (
      tester,
    ) async {
      var tapped = 0;
      var removed = 0;
      await tester.pumpWidget(
        wrap(
          FilterTokenChip(
            token: sampleToken,
            onRemove: () => removed++,
            onTap: () => tapped++,
          ),
        ),
      );

      // Body tap routes to onTap (the new "edit this chip" gesture).
      await tester.tap(find.text('Archived'));
      await tester.pump();
      expect(tapped, 1);
      expect(removed, 0, reason: 'body tap must not double-fire onRemove');

      // The × button still routes to onRemove only.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(removed, 1);
      expect(tapped, 1, reason: 'tapping × must not also fire onTap');
    });
  });
}
