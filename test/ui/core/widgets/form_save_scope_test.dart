import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/widgets/form_save_scope.dart';

void main() {
  group('FormSaveScope', () {
    testWidgets('single-line TextField onSubmitted invokes onSubmit', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormSaveScope(
              onSubmit: () => count++,
              child: Builder(
                builder: (context) {
                  final scope = FormSaveScope.maybeOf(context)!;
                  return TextField(onSubmitted: (_) => scope.trySubmit());
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(count, 1);
    });

    testWidgets('disabled scope does not fire onSubmit', (tester) async {
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormSaveScope(
              enabled: false,
              onSubmit: () => count++,
              child: Builder(
                builder: (context) {
                  final scope = FormSaveScope.maybeOf(context)!;
                  return TextField(onSubmitted: (_) => scope.trySubmit());
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(count, 0);
    });

    testWidgets('maybeOf returns null without an ancestor scope', (
      tester,
    ) async {
      FormSaveScope? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                captured = FormSaveScope.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(captured, isNull);
    });
  });
}
