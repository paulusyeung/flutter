import 'package:admin/app/theme.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/ui/features/clients/widgets/state_filter_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPills(
    WidgetTester tester, {
    required Set<EntityState> selected,
    required void Function(EntityState) onToggle,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildInTheme(Brightness.light),
        home: Scaffold(
          body: StateFilterPills(selected: selected, onToggle: onToggle),
        ),
      ),
    );
  }

  testWidgets('renders one pill per EntityState', (tester) async {
    await pumpPills(tester, selected: const {EntityState.active}, onToggle: (_) {});
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Deleted'), findsOneWidget);
  });

  testWidgets('tap fires onToggle with the chip\'s state', (tester) async {
    final toggled = <EntityState>[];
    await pumpPills(
      tester,
      selected: const {EntityState.active},
      onToggle: toggled.add,
    );
    await tester.tap(find.text('Archived'));
    expect(toggled, [EntityState.archived]);
  });

  testWidgets('each pill has at least a 48-dp touch target', (tester) async {
    await pumpPills(
      tester,
      selected: const {EntityState.active},
      onToggle: (_) {},
    );
    // InkWell + ConstrainedBox(minHeight: 48) — the tappable area's
    // rendered height must be >= 48.
    final inkwells = find.descendant(
      of: find.byType(StateFilterPills),
      matching: find.byType(InkWell),
    );
    expect(inkwells, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      final size = tester.getSize(inkwells.at(i));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}
