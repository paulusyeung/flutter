import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/core/widgets/centered_form_column.dart';

import '../../../_responsive_helper.dart';

void main() {
  // Locks the contract the billing-edit mobile layout relies on:
  // CenteredFormColumn must preserve the parent's bounded height so it can wrap
  // a Column containing an Expanded (the TabBarView) without an unbounded-flex
  // assertion — AND cap the child width at 820, centered.
  //
  // `scroll: false` gives the body a bounded height (the surface height),
  // mirroring how the edit scaffold places the form in an `Expanded`.
  testWidgets(
    'preserves bounded height for an Expanded child; caps width at 820',
    (tester) async {
      await pumpAt(
        tester,
        1200,
        CenteredFormColumn(
          child: Column(
            key: const ValueKey('col'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('header'),
              Expanded(child: Container(key: const ValueKey('flex'))),
              const Text('footer'),
            ],
          ),
        ),
        height: 400,
        scroll: false,
      );

      expectNoOverflow(tester);
      // Capped to 820 (centered inside the 1200 px surface).
      expect(tester.getSize(find.byKey(const ValueKey('col'))).width, 820);
      // The Expanded resolved to a finite, positive height — i.e. the inner
      // Column kept a bounded maxHeight through Center + ConstrainedBox.
      expect(
        tester.getSize(find.byKey(const ValueKey('flex'))).height,
        greaterThan(0),
      );
    },
  );

  testWidgets('is a no-op below the cap (narrow slide-over pane width)', (
    tester,
  ) async {
    await pumpAt(
      tester,
      460,
      CenteredFormColumn(
        child: Column(
          key: const ValueKey('col'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [SizedBox(height: 20)],
        ),
      ),
      height: 200,
      scroll: false,
    );

    expectNoOverflow(tester);
    // 460 < 820, so the cap doesn't bite — content fills the pane width.
    expect(tester.getSize(find.byKey(const ValueKey('col'))).width, 460);
  });
}
