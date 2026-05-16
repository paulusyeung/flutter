import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/features/settings/widgets/accent_swatch_grid.dart';
import 'package:admin/ui/features/settings/widgets/color_picker_field.dart';

import '../../../../_localization_helper.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildInTheme(InTheme.light),
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('invalid hex shows errorText and does not commit', (
    tester,
  ) async {
    Color? committed;
    await tester.pumpWidget(
      _host(
        ColorPickerField(
          label: 'Background',
          color: const Color(0xFF112233),
          isOverridden: false,
          palette: kAccentSwatches,
          onChanged: (c) => committed = c,
          onReset: () {},
        ),
      ),
    );

    // Expand the inline picker.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '#ZZZ');
    await tester.pump();

    expect(find.text('Enter a #RRGGBB hex color'), findsOneWidget);
    expect(committed, isNull, reason: 'invalid input must not commit');

    // A valid value clears the error and commits.
    await tester.enterText(find.byType(TextField), '#0A0B0C');
    await tester.pump();
    expect(find.text('Enter a #RRGGBB hex color'), findsNothing);
    expect(committed, const Color(0xFF0A0B0C));
  });

  testWidgets(
    'a sibling-driven rebuild does not clobber the focused field',
    (tester) async {
      // Two fields under one ListenableBuilder, like the editor screen: a
      // notify from one rebuilds both. The focused field must keep its
      // in-progress (invalid, uncommitted) text.
      final notifier = ValueNotifier<int>(0);
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (_, _, _) => Column(
              children: [
                ColorPickerField(
                  label: 'A',
                  color: const Color(0xFF111111),
                  isOverridden: false,
                  palette: kAccentSwatches,
                  onChanged: (_) {},
                  onReset: () {},
                ),
                ColorPickerField(
                  label: 'B',
                  color: const Color(0xFF222222),
                  isOverridden: false,
                  palette: kAccentSwatches,
                  onChanged: (_) {},
                  onReset: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      final fieldA = find.byType(TextField).first;
      await tester.tap(fieldA);
      await tester.enterText(fieldA, '#12'); // partial, invalid, focused
      await tester.pump();

      // A sibling notify rebuilds both ColorPickerFields.
      notifier.value = 1;
      await tester.pump();

      expect(
        tester.widget<TextField>(fieldA).controller!.text,
        '#12',
        reason: 'focused field keeps uncommitted text across rebuild',
      );
    },
  );
}
