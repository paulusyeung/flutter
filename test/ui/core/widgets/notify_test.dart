import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/core/widgets/notify.dart';

Future<void> _pump(
  WidgetTester tester,
  void Function(BuildContext) onPressed, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildInTheme(
        brightness == Brightness.dark ? InTheme.dark : InTheme.light,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onPressed(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Notify', () {
    testWidgets('action button fires its callback', (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        (c) => Notify.error(
          c,
          'Failed',
          action: NotifyAction('Retry', () => pressed++),
        ),
      );
      await tester.tap(find.text('go'));
      // SnackBar slides in over ~250ms — pump past the animation so the
      // action button is at its final position before we tap it.
      await tester.pumpAndSettle();

      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();
      expect(pressed, 1);
    });

    testWidgets(
      'showing a second toast replaces the first instead of queueing',
      (tester) async {
        await _pump(tester, (c) {
          Notify.info(c, 'First');
          Notify.info(c, 'Second');
        });
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        // The hideCurrentSnackBar call before the second show leaves only
        // the second toast visible — the first is dropped, not queued.
        expect(find.text('First'), findsNothing);
        expect(find.text('Second'), findsOneWidget);
      },
    );
  });

  group('formatNotifyError', () {
    test('strips Exception prefix', () {
      expect(formatNotifyError(Exception('boom')), 'boom');
    });

    test('strips a custom *Exception type-name prefix', () {
      expect(
        formatNotifyError(_FakeNamedException('lookup failed')),
        'lookup failed',
      );
    });

    test('leaves plain strings untouched', () {
      expect(formatNotifyError('plain'), 'plain');
    });
  });
}

class _FakeNamedException implements Exception {
  _FakeNamedException(this.message);
  final String message;

  @override
  String toString() => 'SocketException: $message';
}
