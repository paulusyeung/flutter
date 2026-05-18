import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/markdown_text_field.dart';

import '../../../_localization_helper.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: buildInTheme(InTheme.light),
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('many fields mount in one frame without a duplicate-IME throw and '
      'tap promotes reader→editor, blur reverts', (tester) async {
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            for (var i = 0; i < 4; i++)
              MarkdownTextField(
                label: 'F$i',
                initialValue: 'body $i',
                height: 80,
                onChanged: (_) {},
              ),
          ],
        ),
      ),
    );
    await tester.pump();

    // All four render read-only — no SuperEditor (and thus no IME client)
    // mounted, so no "Found N duplicate input IDs this frame".
    expect(tester.takeException(), isNull);
    expect(find.byType(SuperReader), findsNWidgets(4));
    expect(find.byType(SuperEditor), findsNothing);

    // Tapping a field promotes exactly that one to the editing SuperEditor.
    // (Tap the field root, not SuperReader — the reader is a sliver, and it
    // sits under an IgnorePointer; the tap layer is the host GestureDetector.)
    await tester.tap(find.byType(MarkdownTextField).first);
    await tester.pump(); // run the post-frame callback in _enterEditing
    await tester.pump(); // rebuild with the editor
    expect(find.byType(SuperEditor), findsOneWidget);
    expect(find.byType(SuperReader), findsNWidgets(3));
    expect(tester.takeException(), isNull);

    // Blur reverts it back to a reader (≤1 SuperEditor invariant holds).
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump();
    expect(find.byType(SuperEditor), findsNothing);
    expect(find.byType(SuperReader), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
  testWidgets('reseeds the document when externalValueKey changes', (
    tester,
  ) async {
    final emissions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 480,
              child: MarkdownTextField(
                label: 'Terms',
                initialValue: 'first',
                externalValueKey: 'k1',
                onChanged: emissions.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Reseed with a different value + key. Pumping the new widget should
    // replace the document content with no spurious onChanged emission.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(InTheme.light),
        localizationsDelegates: kTestLocalizationsDelegates,
        supportedLocales: kTestSupportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 480,
              child: MarkdownTextField(
                label: 'Terms',
                initialValue: 'second',
                externalValueKey: 'k2',
                onChanged: emissions.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(emissions, isEmpty);
  });
}
