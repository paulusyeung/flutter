import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_renderers/total_block.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/sample/sample_data.dart';

import '../../../../../../_localization_helper.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  locale: const Locale('en'),
  theme: buildInTheme(InTheme.light),
  home: Scaffold(body: child),
);

DesignBlock _totalBlock({Map<String, dynamic>? overrides}) {
  final spec = blockSpecFor('total')!;
  final props = Map<String, dynamic>.from(spec.defaultProperties);
  if (overrides != null) props.addAll(overrides);
  return DesignBlock(
    id: 'tot-1',
    type: 'total',
    gridPosition: const GridPosition(x: 0, y: 0, w: 6, h: 6),
    properties: props,
  );
}

void main() {
  testWidgets('renders one row per item where show != false', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TotalBlock(block: _totalBlock(), sample: DesignerSampleData.fallback),
      ),
    );
    await tester.pump();
    // Default 6 items: subtotal / discount / taxes / total / paid_to_date / balance_due.
    // Values come from the sample fixture's Decimals.
    expect(find.text(r'$1,500.00'), findsOneWidget); // subtotal
    expect(find.text(r'$150.00'), findsOneWidget); // taxes
    expect(find.text(r'$1,650.00'), findsNWidgets(2)); // total + balance_due
  });

  testWidgets('items with show:false are filtered out', (tester) async {
    final spec = blockSpecFor('total')!;
    final hiddenItems = [
      for (final item in (spec.defaultProperties['items'] as List))
        {
          ...(item as Map<String, dynamic>),
          if ((item['label'] as String).contains('subtotal')) 'show': false,
        },
    ];
    final block = _totalBlock(overrides: {'items': hiddenItems});
    await tester.pumpWidget(
      _wrap(TotalBlock(block: block, sample: DesignerSampleData.fallback)),
    );
    await tester.pump();
    // Subtotal is gone but total still shows.
    expect(find.text(r'$1,500.00'), findsNothing);
    expect(find.text(r'$1,650.00'), findsNWidgets(2));
  });

  testWidgets('empty items list renders nothing', (tester) async {
    final block = _totalBlock(overrides: {'items': <Map<String, dynamic>>[]});
    await tester.pumpWidget(
      _wrap(TotalBlock(block: block, sample: DesignerSampleData.fallback)),
    );
    await tester.pump();
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('isTotal and isBalance items render in bold weight', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TotalBlock(block: _totalBlock(), sample: DesignerSampleData.fallback),
      ),
    );
    await tester.pump();
    // Find the Text widgets for the two boldened values.
    final balanceTexts = find.text(r'$1,650.00');
    expect(balanceTexts, findsNWidgets(2));
    for (final element in balanceTexts.evaluate()) {
      final text = element.widget as Text;
      expect(text.style?.fontWeight, FontWeight.bold);
    }
  });

  group('Phase 9a — block-level `align`', () {
    Alignment? alignmentFor(WidgetTester tester) {
      final align = tester.widget<Align>(find.byType(Align).first);
      return align.alignment as Alignment?;
    }

    testWidgets('defaults to centerRight when align is unset', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TotalBlock(block: _totalBlock(), sample: DesignerSampleData.fallback),
        ),
      );
      await tester.pump();
      expect(alignmentFor(tester), Alignment.centerRight);
    });

    testWidgets('honours align: left / center / right', (tester) async {
      for (final entry in <String, Alignment>{
        'left': Alignment.centerLeft,
        'center': Alignment.center,
        'right': Alignment.centerRight,
      }.entries) {
        await tester.pumpWidget(
          _wrap(
            TotalBlock(
              block: _totalBlock(overrides: {'align': entry.key}),
              sample: DesignerSampleData.fallback,
            ),
          ),
        );
        await tester.pump();
        expect(alignmentFor(tester), entry.value, reason: 'align=${entry.key}');
      }
    });
  });
}
