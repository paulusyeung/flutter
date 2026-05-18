import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';
import 'package:admin/ui/core/list/search/filter_token_chip.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildInTheme(InTheme.light),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('FilterTokenChip — segmented (comparable key)', () {
    const segToken = FilterToken(
      keyId: 'created',
      displayKey: 'Created',
      rawValue: 'gte:2026-01-01',
      displayValue: '2026-01-01',
      displayComparator: 'is on or after',
    );

    testWidgets('renders field, comparator and value with two ▾ carets', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FilterTokenChip(
            token: segToken,
            onRemove: () {},
            onTap: (_) {},
            onComparatorTap: (_) {},
            onValueTap: (_) {},
          ),
        ),
      );

      expect(find.text('created'), findsOneWidget);
      expect(find.text('is on or after'), findsOneWidget);
      expect(find.text('2026-01-01'), findsOneWidget);
      // One caret on the comparator segment, one on the value segment.
      expect(find.byIcon(Icons.arrow_drop_down), findsNWidgets(2));
    });

    testWidgets('each segment is an independent tap target', (tester) async {
      var field = 0;
      var comparator = 0;
      var value = 0;
      await tester.pumpWidget(
        _host(
          FilterTokenChip(
            token: segToken,
            onRemove: () {},
            onTap: (_) => field++,
            onComparatorTap: (_) => comparator++,
            onValueTap: (_) => value++,
          ),
        ),
      );

      await tester.tap(find.text('created'));
      await tester.tap(find.text('is on or after'));
      await tester.tap(find.text('2026-01-01'));
      await tester.pump();

      expect(field, 1);
      expect(comparator, 1);
      expect(value, 1);
    });

    testWidgets('chip is a rounded rectangle, never a pill', (tester) async {
      await tester.pumpWidget(
        _host(
          FilterTokenChip(
            token: segToken,
            onRemove: () {},
            onTap: (_) {},
            onComparatorTap: (_) {},
            onValueTap: (_) {},
          ),
        ),
      );

      final decorated = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      expect(
        decorated.borderRadius,
        BorderRadius.circular(InRadii.r1),
        reason: 'must use InRadii.r1, not BorderRadius.circular(999)',
      );
    });

    testWidgets('readOnly variant has no carets and no close button', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const FilterTokenChip.readOnly(token: segToken)));
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
      // Comparator still shown inline for context.
      expect(find.text('is on or after'), findsOneWidget);
    });
  });

  group('FilterTokenChip — plain (non-comparable key)', () {
    const plainToken = FilterToken(
      keyId: 'country',
      displayKey: 'Country',
      rawValue: '840',
      displayValue: 'United States',
    );

    testWidgets('aggregate/plain chip has no comparator segment (no carets)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(FilterTokenChip(token: plainToken, onRemove: () {}, onTap: (_) {})),
      );
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      expect(find.text('country'), findsOneWidget);
      expect(find.text('United States'), findsOneWidget);
    });
  });
}
