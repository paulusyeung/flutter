import 'package:admin/app/theme.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/core/list/state_filter_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDropdown(
    WidgetTester tester, {
    required Set<EntityState> selected,
    required void Function(EntityState) onToggle,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(Brightness.light),
        home: Scaffold(
          body: StateFilterDropdown(selected: selected, onToggle: onToggle),
        ),
      ),
    );
  }

  testWidgets('label shows the single selected state', (tester) async {
    await pumpDropdown(
      tester,
      selected: const {EntityState.active},
      onToggle: (_) {},
    );
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('label joins multiple selected states in enum order', (
    tester,
  ) async {
    await pumpDropdown(
      tester,
      selected: const {EntityState.archived, EntityState.active},
      onToggle: (_) {},
    );
    expect(find.text('Active, Archived'), findsOneWidget);
  });

  testWidgets('label shows "All" when no states are selected', (tester) async {
    await pumpDropdown(tester, selected: const {}, onToggle: (_) {});
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('opening the menu reveals one checkbox per state', (
    tester,
  ) async {
    await pumpDropdown(
      tester,
      selected: const {EntityState.active},
      onToggle: (_) {},
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
  });

  testWidgets('tapping a checkbox fires onToggle with the matching state', (
    tester,
  ) async {
    final toggled = <EntityState>[];
    await pumpDropdown(
      tester,
      selected: const {EntityState.active},
      onToggle: toggled.add,
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Archived'));
    await tester.pumpAndSettle();
    expect(toggled, [EntityState.archived]);
  });
}
