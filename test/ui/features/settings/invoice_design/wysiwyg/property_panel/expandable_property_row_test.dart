import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/expandable_property_row.dart';

import '../../../../../../_localization_helper.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  locale: const Locale('en'),
  theme: buildInTheme(InTheme.light),
  // ReorderableDragStartListener needs to live INSIDE a ReorderableList
  // to actually start a drag, but for visual/structure tests we don't
  // need that — Flutter is happy to mount the listener standalone.
  home: Scaffold(
    body: ReorderableListView(
      onReorder: (_, _) {},
      children: [Container(key: const ValueKey('only-row'), child: child)],
    ),
  ),
);

void main() {
  group('ExpandablePropertyRow (Phase 15b)', () {
    testWidgets('collapsed → expandedChild is not mounted', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ExpandablePropertyRow(
            index: 0,
            title: const Text('Header'),
            subtitle: const Text('subtitle'),
            expanded: false,
            onToggleExpanded: () {},
            trailing: const Icon(Icons.bookmark),
            expandedChild: const Text('EXPANDED-BODY'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('subtitle'), findsOneWidget);
      expect(find.text('EXPANDED-BODY'), findsNothing);
      // Chevron is `expand_more` when collapsed.
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('expanded → expandedChild mounts under the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ExpandablePropertyRow(
            index: 0,
            title: const Text('Header'),
            subtitle: const Text('subtitle'),
            expanded: true,
            onToggleExpanded: () {},
            trailing: const Icon(Icons.bookmark),
            expandedChild: const Text('EXPANDED-BODY'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('EXPANDED-BODY'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('tapping the chevron fires onToggleExpanded', (tester) async {
      var toggles = 0;
      await tester.pumpWidget(
        _wrap(
          ExpandablePropertyRow(
            index: 0,
            title: const Text('Header'),
            subtitle: const Text('subtitle'),
            expanded: false,
            onToggleExpanded: () => toggles++,
            trailing: const Icon(Icons.bookmark),
            expandedChild: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.expand_more));
      expect(toggles, 1);
    });

    testWidgets('trailing slot accepts arbitrary widgets', (tester) async {
      // Confirms Info/Table can pass a delete IconButton AND Total can
      // pass a Switch.adaptive — both via the same `trailing:` slot.
      await tester.pumpWidget(
        _wrap(
          ExpandablePropertyRow(
            index: 0,
            title: const Text('Header'),
            subtitle: const Text('subtitle'),
            expanded: false,
            onToggleExpanded: () {},
            trailing: const Switch.adaptive(value: true, onChanged: null),
            expandedChild: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
