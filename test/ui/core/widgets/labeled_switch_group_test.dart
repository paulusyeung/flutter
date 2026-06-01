import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/widgets/labeled_switch_group.dart';

void main() {
  group('LabeledSwitchGroup', () {
    Future<void> pump(WidgetTester tester, List<LabeledSwitchItem> items) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: LabeledSwitchGroup(items: items),
            ),
          ),
        ),
      );
    }

    testWidgets('renders a label and a switch per item', (tester) async {
      await pump(tester, [
        LabeledSwitchItem(label: 'Add to Invoices', value: true, onChanged: (_) {}),
        LabeledSwitchItem(label: 'CC Only', value: false, onChanged: (_) {}),
      ]);

      expect(find.text('Add to Invoices'), findsOneWidget);
      expect(find.text('CC Only'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    });

    testWidgets('tapping the label toggles via onChanged', (tester) async {
      bool? received;
      await pump(tester, [
        LabeledSwitchItem(
          label: 'CC Only',
          value: false,
          onChanged: (v) => received = v,
        ),
      ]);

      await tester.tap(find.text('CC Only'));
      await tester.pump();

      expect(received, isTrue);
    });

    testWidgets('tapping the switch toggles via onChanged', (tester) async {
      bool? received;
      await pump(tester, [
        LabeledSwitchItem(
          label: 'CC Only',
          value: true,
          onChanged: (v) => received = v,
        ),
      ]);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(received, isFalse);
    });

    testWidgets('a null onChanged renders a disabled, inert switch', (
      tester,
    ) async {
      var fired = false;
      await pump(tester, [
        const LabeledSwitchItem(label: 'Add to Invoices', value: false),
        LabeledSwitchItem(
          label: 'CC Only',
          value: true,
          onChanged: (_) => fired = true,
        ),
      ]);

      expect(tester.widget<Switch>(find.byType(Switch).at(0)).onChanged, isNull);
      await tester.tap(find.text('Add to Invoices'));
      await tester.pump();
      expect(fired, isFalse);
    });

    testWidgets('switches align across rows with different label lengths', (
      tester,
    ) async {
      await pump(tester, [
        LabeledSwitchItem(label: 'A very long toggle label', value: true, onChanged: (_) {}),
        LabeledSwitchItem(label: 'Short', value: false, onChanged: (_) {}),
      ]);

      final first = tester.getTopLeft(find.byType(Switch).at(0));
      final second = tester.getTopLeft(find.byType(Switch).at(1));
      expect(first.dx, second.dx);
    });

    testWidgets('the group hugs its content rather than filling the width', (
      tester,
    ) async {
      await pump(tester, [
        LabeledSwitchItem(label: 'CC Only', value: false, onChanged: (_) {}),
      ]);

      // The aligned switch sits well left of the 600px parent's right edge —
      // the empty space is to the right of the switch, not before it.
      final switchRight = tester.getBottomRight(find.byType(Switch)).dx;
      expect(switchRight, lessThan(400));
    });
  });
}
