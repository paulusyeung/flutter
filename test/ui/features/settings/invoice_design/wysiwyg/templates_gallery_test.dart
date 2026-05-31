import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/templates.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/templates_gallery.dart';

import '../../../../../_localization_helper.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  locale: const Locale('en'),
  theme: buildInTheme(InTheme.light),
  home: Scaffold(body: child),
);

void main() {
  group('showRichTemplateGallery (Phase 8f)', () {
    testWidgets('renders one card per starter template', (tester) async {
      DesignTemplateStarter? picked;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () async {
            picked = await showRichTemplateGallery(ctx);
          },
          child: const Text('open'),
        );
      })));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // Three starters → three cards. _app_pending.json carries the
      // translated titles, so we assert against the localized strings.
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Minimal'), findsAtLeast(1));
      expect(find.text('Quote-friendly'), findsOneWidget);
      expect(picked, isNull);
    });

    testWidgets('tapping a card resolves with the matching starter',
        (tester) async {
      DesignTemplateStarter? picked;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () async {
            picked = await showRichTemplateGallery(ctx);
          },
          child: const Text('open'),
        );
      })));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap the "Minimal" card (find via the card body text — the
      // category chip also says "Minimal", so disambiguate by the
      // InkWell ancestor that wraps the card).
      final minimalCard = find
          .ancestor(
            of: find.text('Single-column flow, no shipping address.'),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.tap(minimalCard);
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.id, 'minimal');
    });

    testWidgets('category filter chips narrow the visible cards',
        (tester) async {
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => showRichTemplateGallery(ctx),
          child: const Text('open'),
        );
      })));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // All three starters visible by default ("All" chip selected) —
      // assert against the translated description strings (unique
      // per starter, not shared with category chips).
      expect(find.text('Two-column header, products + totals, public notes, footer.'),
          findsOneWidget);
      expect(find.text('Single-column flow, no shipping address.'),
          findsOneWidget);
      expect(find.text('Adds terms, signature line, and emphasizes public notes.'),
          findsOneWidget);

      // Tap the "Minimal" category chip → only the minimal starter
      // (category: 'minimal') stays. The "All" + "Modern" / "Classic"
      // chips share the row; pick by ChoiceChip ancestor.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Minimal'));
      await tester.pumpAndSettle();
      expect(find.text('Single-column flow, no shipping address.'),
          findsOneWidget);
      expect(find.text('Two-column header, products + totals, public notes, footer.'),
          findsNothing);
      expect(find.text('Adds terms, signature line, and emphasizes public notes.'),
          findsNothing);
    });

    testWidgets('close button dismisses the dialog without a pick',
        (tester) async {
      DesignTemplateStarter? picked;
      var done = false;
      await tester.pumpWidget(_wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () async {
            picked = await showRichTemplateGallery(ctx);
            done = true;
          },
          child: const Text('open'),
        );
      })));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(picked, isNull);
    });
  });
}
