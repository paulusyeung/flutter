import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_sizing.dart';

void main() {
  group('sizeBoundsFor', () {
    test('returns the right minimums for every catalogued type', () {
      expect(sizeBoundsFor('table').minW, 6);
      expect(sizeBoundsFor('table').minH, 2);
      expect(sizeBoundsFor('qrcode').minW, 2);
      expect(sizeBoundsFor('qrcode').maxW, 6);
      expect(sizeBoundsFor('divider').maxH, 2);
    });
    test('unknown types get the default 1x1 lower bound', () {
      expect(sizeBoundsFor('unknown-future-block').minW, 1);
      expect(sizeBoundsFor('unknown-future-block').minH, 1);
    });
  });

  group('clampSize', () {
    test('clamps width to the type min', () {
      final r = clampSize(type: 'table', desiredW: 2, desiredH: 4, x: 0, y: 0);
      expect(r.w, 6); // bumped up to type minimum
      expect(r.h, 4);
    });
    test('clamps width to the right-edge of the grid', () {
      // Block at x=8; max w to fit grid is 4. But table.minW=6 → bounds say
      // max=clamp(12-8, 6, 12) = clamp(4, 6, 12) = 6; clamp(desired=10, 6, 6) = 6.
      final r = clampSize(type: 'table', desiredW: 10, desiredH: 4, x: 8, y: 0);
      // Effective max is 6 (since 12-8=4 < minW=6 → max raised to minW=6).
      // The desired 10 → clamp to 6.
      expect(r.w, 6);
    });
    test('clamps height to type max for divider', () {
      final r = clampSize(
        type: 'divider',
        desiredW: 12,
        desiredH: 99,
        x: 0,
        y: 0,
      );
      expect(r.h, 2);
    });
    test('honors a custom totalCols', () {
      final r = clampSize(
        type: 'spacer',
        desiredW: 99,
        desiredH: 5,
        x: 0,
        y: 0,
        totalCols: 8,
      );
      expect(r.w, 8);
    });
    test('clamps height down to type minimum', () {
      final r = clampSize(type: 'table', desiredW: 12, desiredH: 0, x: 0, y: 0);
      expect(r.h, 2); // table.minH
    });
  });
}
