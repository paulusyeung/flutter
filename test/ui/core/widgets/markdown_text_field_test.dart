import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/markdown_text_field.dart';

import '../../../_localization_helper.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? initialValue,
  bool enabled = true,
  ValueChanged<String>? onChanged,
  Object? externalValueKey,
}) async {
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
              initialValue: initialValue,
              enabled: enabled,
              externalValueKey: externalValueKey,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  // Pump one extra frame so SuperEditor finishes its initial layout pass.
  await tester.pump();
}

void main() {
  testWidgets('renders the label and a toolbar when enabled', (tester) async {
    await _pump(tester, initialValue: 'Hello **world**');

    expect(find.text('Terms'), findsOneWidget);
    // Toolbar shows bold/italic/underline + list buttons (5 icon buttons).
    expect(find.byIcon(Icons.format_bold), findsOneWidget);
    expect(find.byIcon(Icons.format_italic), findsOneWidget);
    expect(find.byIcon(Icons.format_underline), findsOneWidget);
    expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
    expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
  });

  testWidgets('hides the toolbar when disabled', (tester) async {
    await _pump(tester, initialValue: 'plain', enabled: false);

    expect(find.text('Terms'), findsOneWidget);
    expect(find.byIcon(Icons.format_bold), findsNothing);
  });

  testWidgets('reseeds the document when externalValueKey changes', (
    tester,
  ) async {
    final emissions = <String>[];

    await _pump(
      tester,
      initialValue: 'first',
      externalValueKey: 'k1',
      onChanged: emissions.add,
    );

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
