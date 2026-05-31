import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/domain/design.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/grid/grid_model.dart';

DesignBlock _b(String id, int x, int y, int w, int h) => DesignBlock(
  id: id,
  type: 't',
  gridPosition: GridPosition(x: x, y: y, w: w, h: h),
);

void main() {
  group('blocksOverlap', () {
    test('same-id blocks never overlap (in-place re-layout safety)', () {
      final a = _b('1', 0, 0, 4, 4);
      final b = _b('1', 0, 0, 4, 4);
      expect(blocksOverlap(a, b), isFalse);
    });
    test('horizontally adjacent blocks do not overlap', () {
      expect(blocksOverlap(_b('a', 0, 0, 4, 2), _b('b', 4, 0, 4, 2)), isFalse);
    });
    test('vertically adjacent blocks do not overlap', () {
      expect(blocksOverlap(_b('a', 0, 0, 4, 2), _b('b', 0, 2, 4, 2)), isFalse);
    });
    test('intersecting blocks overlap', () {
      expect(blocksOverlap(_b('a', 0, 0, 6, 4), _b('b', 4, 2, 6, 4)), isTrue);
    });
  });

  group('pushCollisionsDown', () {
    test('non-overlapping layout is returned unchanged', () {
      final blocks = [_b('a', 0, 0, 4, 2), _b('b', 4, 0, 4, 2), _b('c', 0, 3, 12, 1)];
      final out = pushCollisionsDown(blocks);
      for (var i = 0; i < blocks.length; i++) {
        expect(out[i].gridPosition.y, blocks[i].gridPosition.y);
      }
    });

    test('overlapping block is pushed below the colliding block', () {
      // 'a' at (0,0,12,4); 'b' resized to overlap → should be pushed to y=4
      final blocks = [
        _b('a', 0, 0, 12, 4),
        _b('b', 0, 2, 12, 4),
      ];
      final out = pushCollisionsDown(blocks);
      expect(out[0].gridPosition.y, 0);
      expect(out[1].gridPosition.y, 4); // pushed below 'a' (y=0, h=4 → next y=4)
    });

    test('cascading pushes settle correctly', () {
      // Three stacked overlaps — each should chain below the previous.
      final blocks = [
        _b('a', 0, 0, 12, 3),
        _b('b', 0, 1, 12, 3),
        _b('c', 0, 2, 12, 3),
      ];
      final out = pushCollisionsDown(blocks);
      final byId = {for (final x in out) x.id: x};
      expect(byId['a']!.gridPosition.y, 0);
      expect(byId['b']!.gridPosition.y, 3);
      expect(byId['c']!.gridPosition.y, 6);
    });

    test('input ordering is preserved in the output indices', () {
      final blocks = [_b('z', 0, 5, 4, 2), _b('a', 0, 0, 4, 2), _b('m', 4, 0, 4, 2)];
      final out = pushCollisionsDown(blocks);
      expect(out.map((b) => b.id).toList(), ['z', 'a', 'm']);
    });

    test('does NOT pull blocks upward into whitespace', () {
      // Single block at y=10 with empty rows above stays put — designer
      // preserves whitespace.
      final blocks = [_b('only', 0, 10, 12, 2)];
      final out = pushCollisionsDown(blocks);
      expect(out[0].gridPosition.y, 10);
    });
  });

  group('findFirstEmptySlot', () {
    test('empty canvas → top-left', () {
      final slot = findFirstEmptySlot(const [], 4, 2);
      expect(slot, const GridPosition(x: 0, y: 0, w: 4, h: 2));
    });

    test('fits in the gap right of an existing block', () {
      final slot = findFirstEmptySlot([_b('a', 0, 0, 4, 2)], 4, 2);
      expect(slot.x, 4);
      expect(slot.y, 0);
    });

    test('falls below when no horizontal room', () {
      // Full-width row at y=0; next slot must be at y=2 (after h=2).
      final slot = findFirstEmptySlot([_b('a', 0, 0, 12, 2)], 6, 2);
      expect(slot.y, 2);
      expect(slot.x, 0);
    });

    test('clamps oversize width to the grid', () {
      final slot = findFirstEmptySlot(const [], 99, 1);
      expect(slot.w, 12);
    });
  });

  group('annotateBlocksAsApi', () {
    test('single block at x=0 is left-aligned', () {
      final out = annotateBlocksAsApi([_b('a', 0, 0, 4, 2)]);
      expect(out[0].rowAlign, 'left');
      expect(out[0].colStart, 1);
      expect(out[0].colSpan, 4);
      expect(out[0].rowWidth, '33.333333%');
    });

    test('block touching right edge is right-aligned', () {
      final out = annotateBlocksAsApi([_b('a', 8, 0, 4, 2)]);
      expect(out[0].rowAlign, 'right');
      expect(out[0].colStart, 9);
    });

    test('mid-row block is center-aligned', () {
      final out = annotateBlocksAsApi([_b('a', 3, 0, 4, 2)]);
      expect(out[0].rowAlign, 'center');
    });

    test('full-width block is left-aligned', () {
      final out = annotateBlocksAsApi([_b('a', 0, 0, 12, 2)]);
      expect(out[0].rowAlign, 'left');
      expect(out[0].rowWidth, '100.000000%');
    });

    test('empty input returns empty output (legacy designs)', () {
      expect(annotateBlocksAsApi(const []), isEmpty);
    });

    test('annotated wire JSON carries the four save-time fields', () {
      // jsonEncode flattens nested typed freezed objects to maps, mirroring
      // what the network layer sends.
      final wire = jsonDecode(jsonEncode(
        annotateBlocksAsApi([_b('logo-1', 0, 0, 4, 4)])
            .map((b) => b.toJson())
            .toList(),
      )) as List<dynamic>;
      final first = wire.first as Map<String, dynamic>;
      expect(first['id'], 'logo-1');
      expect(first['type'], 't');
      expect(first['gridPosition'], {'x': 0, 'y': 0, 'w': 4, 'h': 4});
      expect(first['rowAlign'], 'left');
      expect(first['rowWidth'], '33.333333%');
      expect(first['colStart'], 1);
      expect(first['colSpan'], 4);
    });
  });
}
