import 'package:admin/ui/features/clients/widgets/column_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required List<String> initial,
    required ValueChanged<List<String>> onApply,
    VoidCallback? onReset,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ColumnPickerSheet(
                  initial: initial,
                  onApply: onApply,
                  onReset: onReset ?? () {},
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('renders selected columns first, then available', (tester) async {
    await tester.pumpWidget(
      host(initial: const ['name', 'balance'], onApply: (_) {}),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('SELECTED (2)'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    // Scroll down to surface an available column (the sheet's scroll view
    // is taller than the test viewport).
    await tester.dragUntilVisible(
      find.text('VAT number'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('VAT number'), findsOneWidget);
  });

  testWidgets('unticking a selected column removes it from selected', (
    tester,
  ) async {
    List<String>? applied;
    await tester.pumpWidget(
      host(initial: const ['name', 'balance'], onApply: (v) => applied = v),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap the leading checkbox in the "Balance" row to untick it.
    final balanceTile = find.ancestor(
      of: find.text('Balance'),
      matching: find.byType(CheckboxListTile),
    );
    await tester.tap(balanceTile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(applied, ['name']);
  });

  testWidgets('ticking an available column adds it to the end', (tester) async {
    List<String>? applied;
    await tester.pumpWidget(
      host(initial: const ['name'], onApply: (v) => applied = v),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('VAT number'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    final tile = find.ancestor(
      of: find.text('VAT number'),
      matching: find.byType(CheckboxListTile),
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();

    // Scroll back up so the Done button is hittable.
    await tester.dragUntilVisible(
      find.text('Done'),
      find.byType(CustomScrollView),
      const Offset(0, 400),
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(applied, ['name', 'vat_number']);
  });

  testWidgets('Reset to defaults invokes the reset callback', (tester) async {
    var resetCalled = false;
    await tester.pumpWidget(
      host(
        initial: const ['name', 'balance', 'paid_to_date'],
        onApply: (_) {},
        onReset: () => resetCalled = true,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset to defaults'));
    await tester.pumpAndSettle();
    expect(resetCalled, isTrue);
  });
}
