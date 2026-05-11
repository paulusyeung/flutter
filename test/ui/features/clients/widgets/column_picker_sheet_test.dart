import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/ui/core/list/entity_column_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../_localization_helper.dart';

void main() {
  Widget host({
    required List<String> initial,
    required ValueChanged<List<String>> onApply,
    VoidCallback? onReset,
  }) {
    return MaterialApp(
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => EntityColumnPickerSheet(
                  initial: initial,
                  allColumns: kAllClientColumns,
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
    await tester.dragUntilVisible(
      find.text('VAT Number'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    expect(find.text('VAT Number'), findsOneWidget);
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
      find.text('VAT Number'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    final tile = find.ancestor(
      of: find.text('VAT Number'),
      matching: find.byType(CheckboxListTile),
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();

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
