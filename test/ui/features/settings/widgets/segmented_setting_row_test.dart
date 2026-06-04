import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/segmented_setting_row.dart';

import '../../../../_responsive_helper.dart';

void main() {
  SegmentedButton<int> control() => SegmentedButton<int>(
    showSelectedIcon: false,
    segments: const [
      ButtonSegment(value: 0, label: Text('S')),
      ButtonSegment(value: 1, label: Text('M')),
      ButtonSegment(value: 2, label: Text('L')),
      ButtonSegment(value: 3, label: Text('XL')),
    ],
    selected: const {1},
    onSelectionChanged: (_) {},
  );

  Widget row() => SegmentedSettingRow(
    leading: const Icon(Icons.format_size_outlined),
    title: 'Font size',
    subtitle: 'Normal',
    control: control(),
  );

  testWidgets('wide: control stays in the ListTile trailing slot', (
    tester,
  ) async {
    await pumpAt(tester, 800, row());
    expectNoOverflow(tester);

    expect(find.byType(ListTile), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(SegmentedButton<int>),
      ),
      findsOneWidget,
      reason: 'wide branch keeps the control as ListTile.trailing',
    );
  });

  testWidgets('narrow: control drops below the tile, no overflow', (
    tester,
  ) async {
    await pumpAt(tester, 360, row());
    expectNoOverflow(tester);

    // Narrow branch renders the control outside the ListTile (its own
    // horizontally scrollable row) so a wide button can't overflow the tile.
    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(SegmentedButton<int>),
      ),
      findsNothing,
    );
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
  });

  testWidgets(
    'right-aligned FilledButton in a FormSection sizes to content, not full width',
    (tester) async {
      // Regression for the Device Settings "Download" button: the themed
      // FilledButton default `Size.fromHeight(44)` (infinite min-width) would
      // otherwise fill the stretched FormSection column and defeat the
      // centerRight alignment. The per-call `minimumSize` keeps it compact.
      await pumpAt(
        tester,
        800,
        FormSection(
          title: 'Data',
          children: [
            const Text('Press the button below to download the data.'),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                onPressed: () {},
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Download'),
              ),
            ),
          ],
        ),
      );
      expectNoOverflow(tester);

      final buttonWidth = tester.getSize(find.byType(FilledButton)).width;
      final sectionWidth = tester.getSize(find.byType(FormSection)).width;
      expect(
        buttonWidth,
        lessThan(sectionWidth * 0.5),
        reason: 'button must size to content, not fill the stretched column',
      );
    },
  );
}
