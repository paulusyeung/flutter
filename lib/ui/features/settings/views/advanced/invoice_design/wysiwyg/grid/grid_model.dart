import 'package:admin/data/models/domain/design.dart';
// Re-export the annotation API so existing imports of grid_model.dart keep
// working. The actual implementation lives in the domain layer.
export 'package:admin/data/models/domain/design_block_layout.dart'
    show annotateBlocksAsApi;

/// 12-column grid model for the WYSIWYG designer canvas.
///
/// Ports React's `utils/layout-normalizer.ts` (collision push) and
/// `utils/row-layout.ts` (row annotation) line-for-line so the saved
/// `blocks[]` payload matches what the React app would emit. Pure logic —
/// no Flutter widgets.
///
/// All coords use the same convention as the React `react-grid-layout`:
///   x ∈ [0, 11], w ∈ [1, 12], y / h are unbounded row indices.

const int kGridCols = 12;

/// Two blocks overlap when their bounding boxes intersect on both axes.
/// Identical block IDs short-circuit (used for in-place re-layout passes).
bool blocksOverlap(DesignBlock a, DesignBlock b) {
  if (a.id == b.id) return false;
  final ap = a.gridPosition;
  final bp = b.gridPosition;
  return ap.x < bp.x + bp.w &&
      ap.x + ap.w > bp.x &&
      ap.y < bp.y + bp.h &&
      ap.y + ap.h > bp.y;
}

/// Resize-driven collision resolver: push overlapping blocks down without
/// pulling whitespace up. Mirrors `pushLayoutCollisionsDown` —
/// designer should preserve user intent (whitespace) when resolving overlaps.
///
/// Input order is preserved in the output: the returned list has blocks at
/// the same indices, but with adjusted `gridPosition.y` where needed.
List<DesignBlock> pushCollisionsDown(List<DesignBlock> blocks) {
  if (blocks.isEmpty) return blocks;

  // Sort by (y, x) for deterministic settle order; remember original index
  // so we can rebuild the input ordering on the way out.
  final indexed =
      List<MapEntry<int, DesignBlock>>.generate(
        blocks.length,
        (i) => MapEntry(i, blocks[i]),
        growable: false,
      )..sort((a, b) {
        final ap = a.value.gridPosition;
        final bp = b.value.gridPosition;
        if (ap.y != bp.y) return ap.y - bp.y;
        if (ap.x != bp.x) return ap.x - bp.x;
        return a.key - b.key;
      });

  final settled = <DesignBlock>[];
  final resolved = <String, DesignBlock>{};

  for (final entry in indexed) {
    var next = entry.value;
    var moved = true;
    while (moved) {
      moved = false;
      for (final other in settled) {
        if (blocksOverlap(next, other)) {
          final p = next.gridPosition;
          next = next.copyWith(
            gridPosition: p.copyWith(
              y: other.gridPosition.y + other.gridPosition.h,
            ),
          );
          moved = true;
        }
      }
    }
    settled.add(next);
    resolved[next.id] = next;
  }

  return List<DesignBlock>.generate(
    blocks.length,
    (i) => resolved[blocks[i].id] ?? blocks[i],
    growable: false,
  );
}

/// First (y, x, w, h) slot that fits a block of size [w] × [h] anywhere on
/// the canvas, scanning top-to-bottom, left-to-right. Used by tap-to-add
/// from the palette: the new block goes wherever it fits without colliding.
///
/// If no slot exists between existing rows, places below the lowest block.
GridPosition findFirstEmptySlot(List<DesignBlock> blocks, int w, int h) {
  final cw = w.clamp(1, kGridCols);
  if (blocks.isEmpty) return GridPosition(x: 0, y: 0, w: cw, h: h);

  // Try each row from 0 to (maxY + 1), each x from 0 to (12 - w).
  final maxY = blocks.fold<int>(
    0,
    (m, b) => b.gridPosition.y + b.gridPosition.h > m
        ? b.gridPosition.y + b.gridPosition.h
        : m,
  );
  for (var y = 0; y <= maxY; y++) {
    for (var x = 0; x <= kGridCols - cw; x++) {
      final candidate = DesignBlock(
        id: '_probe',
        type: '_probe',
        gridPosition: GridPosition(x: x, y: y, w: cw, h: h),
      );
      final clear = blocks.every((b) => !blocksOverlap(candidate, b));
      if (clear) return candidate.gridPosition;
    }
  }
  return GridPosition(x: 0, y: maxY, w: cw, h: h);
}

// `annotateBlocksAsApi` lives in
// `lib/data/models/domain/design_block_layout.dart` (re-exported above so
// existing imports keep working). The implementation moved out of this
// file to break a data → UI import in `DesignTemplate.toApi()`.
