import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/markdown_text_field.dart';

import '../../../_localization_helper.dart';

void main() {
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
