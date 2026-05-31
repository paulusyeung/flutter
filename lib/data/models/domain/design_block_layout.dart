import 'package:admin/data/models/api/design_api_model.dart';
import 'package:admin/data/models/domain/design.dart';

/// Save-time row-layout annotation for WYSIWYG designer blocks.
///
/// Ports React `utils/row-layout.ts` (`annotateBlocksWithRowLayout`). Pure
/// projection from `gridPosition` + row siblings — the four derived fields
/// (`rowAlign`, `rowWidth`, `colStart`, `colSpan`) are never stored on the
/// in-memory [DesignBlock]; they're always re-derived at save time so a
/// drag-then-save always produces a fresh value.
///
/// Lives in the domain layer (not the UI tree's `grid_model.dart`) because
/// `DesignTemplate.toApi()` calls it on every save path — keeping it
/// data-side avoids data → UI imports.

const int kDesignerGridCols = 12;

List<DesignBlockApi> annotateBlocksAsApi(List<DesignBlock> blocks) {
  if (blocks.isEmpty) return const <DesignBlockApi>[];

  final rowMap = <int, List<DesignBlock>>{};
  for (final b in blocks) {
    rowMap.putIfAbsent(b.gridPosition.y, () => <DesignBlock>[]).add(b);
  }

  return blocks.map((b) {
    final p = b.gridPosition;
    final inRow = rowMap[p.y] ?? <DesignBlock>[b];
    return b.toApi().copyWith(
      rowAlign: _deriveRowAlign(b, inRow),
      rowWidth: _widthForCols(p.w),
      colStart: p.x + 1,
      colSpan: p.w,
    );
  }).toList(growable: false);
}

String _deriveRowAlign(DesignBlock block, List<DesignBlock> blocksInRow) {
  final p = block.gridPosition;
  if (p.w >= kDesignerGridCols) return 'left';
  if (p.x == 0) return 'left';
  if (p.x + p.w == kDesignerGridCols) return 'right';
  // Mid-row blocks: 'center' is the closest flex-margin approximation. The
  // server places sandwiched blocks after their left siblings regardless.
  return 'center';
}

String _widthForCols(int w) {
  // "33.333333%" style — matches what the React annotator emits.
  final pct = (w / kDesignerGridCols) * 100;
  return '${pct.toStringAsFixed(6)}%';
}
