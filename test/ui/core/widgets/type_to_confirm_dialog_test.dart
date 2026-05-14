import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/type_to_confirm_dialog.dart';

import '../../../_localization_helper.dart';

/// Spawns a tap target that, when tapped, opens the dialog with the given
/// args and stashes the result. Caller pumps and inspects.
Future<TypeToConfirmResult?> _open(
  WidgetTester tester, {
  required String typeToConfirm,
  String? reasonLabel,
}) async {
  TypeToConfirmResult? captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(InTheme.light),
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                captured = await showTypeToConfirmDialog(
                  context,
                  title: 'Delete it?',
                  message: 'This is permanent.',
                  typeToConfirm: typeToConfirm,
                  reasonLabel: reasonLabel,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  // Caller drives the dialog from here; return null so they can dispatch
  // interactions and then re-read the result via the closure.
  return captured;
}

/// Finds the Continue button by Continue/CANCEL text (depending on the
/// dialog state machine). Uses `find.widgetWithText(FilledButton, …)` so
/// the disabled-state test can poke at `onPressed == null` directly.
Finder _continueButton() => find.widgetWithText(FilledButton, 'Continue');
Finder _cancelButton() => find.widgetWithText(TextButton, 'Cancel');

void main() {
  group('showTypeToConfirmDialog', () {
    testWidgets('Continue is disabled until the user types the magic word', (
      tester,
    ) async {
      await _open(tester, typeToConfirm: 'delete');
      // Dialog renders with Continue disabled.
      final disabledButton =
          tester.widget<FilledButton>(_continueButton());
      expect(disabledButton.onPressed, isNull);

      // Typing the wrong thing keeps it disabled.
      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(_continueButton()).onPressed,
        isNull,
      );

      // Typing the right thing enables it.
      await tester.enterText(find.byType(TextField), 'delete');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(_continueButton()).onPressed,
        isNotNull,
      );
    });

    testWidgets('match is case-insensitive and ignores leading/trailing space', (
      tester,
    ) async {
      await _open(tester, typeToConfirm: 'purge');

      await tester.enterText(find.byType(TextField), '  PURGE  ');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(_continueButton()).onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'Cancel pops with confirmed=false (no reason captured even when shown)',
      (tester) async {
        TypeToConfirmResult? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildInTheme(InTheme.light),
            localizationsDelegates: kTestLocalizationsDelegates,
            supportedLocales: kTestSupportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showTypeToConfirmDialog(
                        context,
                        title: 'Cancel account?',
                        message: 'This is permanent.',
                        typeToConfirm: 'delete',
                        reasonLabel: 'Why are you leaving?',
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(_cancelButton());
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.confirmed, isFalse);
      },
    );

    testWidgets(
      'submit returns confirmed=true with the typed reason when reasonLabel '
      'is provided',
      (tester) async {
        TypeToConfirmResult? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildInTheme(InTheme.light),
            localizationsDelegates: kTestLocalizationsDelegates,
            supportedLocales: kTestSupportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showTypeToConfirmDialog(
                        context,
                        title: 'Cancel account?',
                        message: 'This is permanent.',
                        typeToConfirm: 'delete',
                        reasonLabel: 'Why are you leaving?',
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Two TextFields now — the confirm field is the first (autofocused),
        // the reason field is the second.
        final fields = find.byType(TextField);
        expect(fields, findsNWidgets(2));
        await tester.enterText(fields.at(0), 'delete');
        await tester.enterText(fields.at(1), 'too expensive');
        await tester.pump();
        await tester.tap(_continueButton());
        await tester.pumpAndSettle();

        expect(result?.confirmed, isTrue);
        expect(result?.reason, 'too expensive');
      },
    );

    testWidgets(
      'reason field is absent when reasonLabel is null — only the confirm '
      'field renders',
      (tester) async {
        await _open(tester, typeToConfirm: 'purge', reasonLabel: null);
        expect(find.byType(TextField), findsOneWidget);
      },
    );
  });
}
