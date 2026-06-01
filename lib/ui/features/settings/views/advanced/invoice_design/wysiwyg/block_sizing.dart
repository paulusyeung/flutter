// Per-block-type min/max grid sizes for the resize handles. Ported from
// React `utils/block-sizing.ts` (which derives these from content sizing
// in a much heavier flow); we use pragmatic constants here. The resize
// gesture clamps deltas to these so a user can't shrink a `table` to 1×1
// or a `qrcode` below its readable footprint.

/// Inclusive grid bounds for the resize gesture. `w` in `1..=12`.
class BlockSizeBounds {
  const BlockSizeBounds({
    required this.minW,
    required this.minH,
    this.maxW = 12,
    this.maxH = 30,
  });

  final int minW;
  final int minH;
  final int maxW;
  final int maxH;
}

const Map<String, BlockSizeBounds> _kBlockSizeBounds =
    <String, BlockSizeBounds>{
      // Branding
      'logo': BlockSizeBounds(minW: 2, minH: 2),
      'image': BlockSizeBounds(minW: 2, minH: 2),
      'company-info': BlockSizeBounds(minW: 3, minH: 2),

      // Content
      'text': BlockSizeBounds(minW: 2, minH: 1),
      'public-notes': BlockSizeBounds(minW: 3, minH: 1),
      'terms': BlockSizeBounds(minW: 3, minH: 1),
      'footer': BlockSizeBounds(minW: 3, minH: 1),
      'client-info': BlockSizeBounds(minW: 3, minH: 2),
      'client-shipping-info': BlockSizeBounds(minW: 3, minH: 2),
      'invoice-details': BlockSizeBounds(minW: 3, minH: 2),

      // Data — tables need real space for headers
      'table': BlockSizeBounds(minW: 6, minH: 2),
      'tasks-table': BlockSizeBounds(minW: 6, minH: 2),
      'total': BlockSizeBounds(minW: 3, minH: 2),

      // Layout
      'divider': BlockSizeBounds(minW: 2, minH: 1, maxH: 2),
      'spacer': BlockSizeBounds(minW: 1, minH: 1),
      'qrcode': BlockSizeBounds(minW: 2, minH: 2, maxW: 6, maxH: 6),
      'signature': BlockSizeBounds(minW: 2, minH: 2),
    };

/// Default bounds for an unknown block type — wide enough for most things
/// but still constrained so a typo doesn't let the user shrink to 0.
const BlockSizeBounds _kDefaultBounds = BlockSizeBounds(minW: 1, minH: 1);

BlockSizeBounds sizeBoundsFor(String type) =>
    _kBlockSizeBounds[type] ?? _kDefaultBounds;

/// Clamp a desired `(w, h)` to the block's min/max bounds AND to the grid
/// boundary at the block's left/top. Used by the resize handles each
/// frame so the displayed size stays within both the type's contract
/// (e.g. tables don't go below `6×2`) and the canvas (the block must fit
/// to the right of `x` and below `y`).
({int w, int h}) clampSize({
  required String type,
  required int desiredW,
  required int desiredH,
  required int x,
  required int y,
  int totalCols = 12,
}) {
  final bounds = sizeBoundsFor(type);
  final maxW = (totalCols - x).clamp(bounds.minW, bounds.maxW);
  final w = desiredW.clamp(bounds.minW, maxW);
  final h = desiredH.clamp(bounds.minH, bounds.maxH);
  return (w: w, h: h);
}
