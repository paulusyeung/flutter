import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_sizing.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/canvas/block_preview.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/grid/grid_model.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/sample/sample_data.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

/// Drag payload accepted by the canvas. The same `DragTarget` accepts
/// both fresh palette blocks ([PalettePayload]) and reposition gestures
/// on existing blocks ([BlockMovePayload]); the canvas switches on the
/// payload at drop time.
sealed class CanvasDropPayload {
  const CanvasDropPayload();
}

class PalettePayload extends CanvasDropPayload {
  const PalettePayload(this.spec);
  final BlockSpec spec;
}

class BlockMovePayload extends CanvasDropPayload {
  const BlockMovePayload(this.block);
  final DesignBlock block;
}

/// 12-column drag/drop canvas. Built on `Stack` + `Positioned` over a
/// `LayoutBuilder`-measured grid (matching React's `react-grid-layout`
/// coordinate model). Drop target for [BlockSpec] payloads from the
/// palette; clicking a block selects it; long-press + drag repositions.
///
/// Phase-1 scope: drag-from-palette, tap-select, tap-empty-cell-to-deselect,
/// click-and-drag to move blocks. Resize handles, alignment guides, and
/// fine-grained block renderers land in Phase 2.
class WysiwygCanvas extends StatefulWidget {
  const WysiwygCanvas({super.key, required this.vm, this.showGrid});

  final WysiwygDesignViewModel vm;

  /// Phase 16: workspace-owned `ValueNotifier<bool>` that toggles the
  /// column + row guide lines. `null` keeps the legacy always-on
  /// behaviour so callers that don't wire the toggle (e.g. preview-
  /// only test setups) still see the grid.
  final ValueListenable<bool>? showGrid;

  @override
  State<WysiwygCanvas> createState() => _WysiwygCanvasState();
}

/// Fallback notifier handed to [ValueListenableBuilder] when the
/// canvas caller doesn't wire its own `showGrid` toggle — keeps the
/// grid permanently visible without per-call boilerplate.
final ValueNotifier<bool> _alwaysShown = ValueNotifier<bool>(true);

class _WysiwygCanvasState extends State<WysiwygCanvas> {
  /// Grid units high — chosen so a portrait A4-shaped canvas fits at
  /// 600 px wide × ~850 px tall on most laptop screens. Each row is
  /// `width / kGridCols * rowAspect`.
  static const double _rowAspect = 0.08;

  /// Identifies the canvas RenderBox so the drop callback can convert
  /// global offset → local grid coords. Each canvas instance gets its own
  /// key — multiple canvases can mount simultaneously without clashing.
  final GlobalKey _canvasKey = GlobalKey(debugLabel: 'WysiwygCanvasGrid');

  /// Step 5b: the snapped grid target while a drag is in progress —
  /// drives the translucent "ghost" preview and the alignment guides
  /// overlay. Null when nothing is being dragged over the canvas.
  ({int x, int y, int w, int h})? _dragGhost;

  WysiwygDesignViewModel get vm => widget.vm;

  /// Convert a global drag offset to a `{x, y, w, h}` snapped grid cell
  /// based on the canvas's current RenderBox. Returns null if the canvas
  /// hasn't been laid out yet.
  ({int x, int y, int w, int h})? _snapDragToGrid({
    required Offset globalOffset,
    required int width,
    required int height,
    required double cellWidth,
    required double cellHeight,
  }) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalOffset);
    final gx = (local.dx / cellWidth).floor().clamp(0, kGridCols - width);
    final gy = (local.dy / cellHeight).floor();
    return (x: gx, y: gy < 0 ? 0 : gy, w: width, h: height);
  }

  ({int w, int h}) _payloadSize(CanvasDropPayload payload) => switch (payload) {
        PalettePayload(:final spec) =>
          (w: spec.defaultWidth, h: spec.defaultHeight),
        BlockMovePayload(:final block) =>
          (w: block.gridPosition.w, h: block.gridPosition.h),
      };

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final blocks = vm.blocks;
    final sample = DesignerSampleData.fallback;
    // Phase 5c: apply the document's primary font to every Text inside
    // the canvas via a DefaultTextStyle. GoogleFonts.getFont fetches and
    // caches lazily; unknown families fall back to the default.
    final primaryFont = vm.documentSettings.primaryFont;
    TextStyle? fontStyle;
    try {
      fontStyle = GoogleFonts.getFont(primaryFont);
    } catch (_) {
      // Unknown font name — keep the default style. We swallow rather
      // than rebuild on every keystroke in the font field.
      fontStyle = null;
    }

    return Container(
      color: tokens.bg,
      padding: EdgeInsets.all(InSpacing.lg(context)),
      child: DefaultTextStyle.merge(
        style: fontStyle ?? const TextStyle(),
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: AspectRatio(
            aspectRatio: 210 / 297, // A4 portrait
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / kGridCols;
                final cellHeight = constraints.maxWidth * _rowAspect;
                final selectedBlock = vm.selectedBlock;
                return DragTarget<CanvasDropPayload>(
                  // Step 5b: as the user drags, snap the cursor to a grid
                  // cell and store it as `_dragGhost` so the ghost overlay
                  // + alignment guides render at the snap target.
                  onMove: (details) {
                    final size = _payloadSize(details.data);
                    final snap = _snapDragToGrid(
                      globalOffset: details.offset,
                      width: size.w,
                      height: size.h,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                    );
                    if (snap == null) return;
                    if (snap != _dragGhost) {
                      setState(() => _dragGhost = snap);
                    }
                  },
                  onLeave: (_) {
                    if (_dragGhost != null) {
                      setState(() => _dragGhost = null);
                    }
                  },
                  // Drop at cursor coords. Convert the global drop offset
                  // to local Stack coords via the canvas RenderBox, snap
                  // to grid cells, then either add a fresh block from the
                  // palette or move an existing block to the drop target.
                  onAcceptWithDetails: (details) {
                    setState(() => _dragGhost = null);
                    final box = _canvasKey.currentContext?.findRenderObject()
                        as RenderBox?;
                    final payload = details.data;
                    if (box == null) {
                      // Safe fallback: append at next-free slot.
                      if (payload is PalettePayload) vm.addBlock(payload.spec);
                      return;
                    }
                    final local = box.globalToLocal(details.offset);
                    final gx = (local.dx / cellWidth).floor();
                    final gy = (local.dy / cellHeight).floor();
                    switch (payload) {
                      case PalettePayload(:final spec):
                        vm.addBlockAt(spec, gx, gy);
                      case BlockMovePayload(:final block):
                        // Drop coord is the new top-left; reuse the
                        // existing w/h.
                        vm.moveBlock(
                          block.id,
                          GridPosition(
                            x: gx.clamp(0, kGridCols - block.gridPosition.w),
                            y: gy < 0 ? 0 : gy,
                            w: block.gridPosition.w,
                            h: block.gridPosition.h,
                          ),
                        );
                    }
                  },
                  builder: (context, candidate, rejected) {
                    final highlighted = candidate.isNotEmpty;
                    return Container(
                      key: _canvasKey,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: highlighted ? tokens.accent : tokens.border,
                          width: highlighted ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(InRadii.r2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Phase 16: hidden when the workspace's
                          // showGrid notifier is false. Wrapped in
                          // its own ValueListenableBuilder so a toggle
                          // doesn't trigger the surrounding block
                          // tree to rebuild.
                          ValueListenableBuilder<bool>(
                            valueListenable:
                                widget.showGrid ?? _alwaysShown,
                            key: const ValueKey('canvas-grid-guides'),
                            builder: (_, shown, _) => shown
                                ? _GridGuides(
                                    cellWidth: cellWidth,
                                    cellHeight: cellHeight,
                                    color: tokens.border,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          // Deselect when the user clicks empty canvas.
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => vm.selectBlock(null),
                            ),
                          ),
                          if (blocks.isEmpty)
                            const Center(child: _EmptyHint()),
                          for (final block in blocks)
                            _CanvasBlock(
                              vm: vm,
                              block: block,
                              cellWidth: cellWidth,
                              cellHeight: cellHeight,
                              sample: sample,
                              selected: block.id == vm.selectedBlockId,
                            ),
                          // Phase 1.5 #4: render the selection toolbar in
                          // the outer canvas Stack (not inside the block's
                          // tree) so it can render above a y=0 block
                          // without being clipped by the block's bounds.
                          if (selectedBlock != null)
                            _FloatingSelectionToolbar(
                              vm: vm,
                              block: selectedBlock,
                              cellWidth: cellWidth,
                              cellHeight: cellHeight,
                            ),
                          // Resize handles overlay (Step 4c). Only on the
                          // currently-selected, non-locked block.
                          if (selectedBlock != null && !selectedBlock.locked)
                            _ResizeHandles(
                              vm: vm,
                              block: selectedBlock,
                              cellWidth: cellWidth,
                              cellHeight: cellHeight,
                            ),
                          // Step 5b + 5c: ghost preview + alignment guides
                          // during drag. Drawn last so they render on top
                          // of blocks. `_dragGhost` is set by `onMove`
                          // above and cleared on `onLeave`/`onAccept`.
                          if (_dragGhost != null) ...[
                            _AlignmentGuides(
                              ghost: _dragGhost!,
                              blocks: blocks,
                              cellWidth: cellWidth,
                              cellHeight: cellHeight,
                              color: tokens.accent,
                            ),
                            _DragGhost(
                              ghost: _dragGhost!,
                              cellWidth: cellWidth,
                              cellHeight: cellHeight,
                              color: tokens.accent,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        ),
      ),
    );
  }
}


class _GridGuides extends StatelessWidget {
  const _GridGuides({
    required this.cellWidth,
    required this.cellHeight,
    required this.color,
  });

  final double cellWidth;
  final double cellHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GuidesPainter(
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _GuidesPainter extends CustomPainter {
  _GuidesPainter({
    required this.cellWidth,
    required this.cellHeight,
    required this.color,
  });
  final double cellWidth;
  final double cellHeight;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    // Column separators (11 lines between the 12 grid columns).
    for (var i = 1; i < kGridCols; i++) {
      final x = cellWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Phase 16: row separators — derived from the actual canvas
    // height (the row count grows with the tallest block + slack,
    // so there's no fixed `kGridRows`).
    if (cellHeight > 0) {
      for (var y = cellHeight; y < size.height; y += cellHeight) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GuidesPainter old) =>
      old.cellWidth != cellWidth ||
      old.cellHeight != cellHeight ||
      old.color != color;
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(InSpacing.lg(context)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.dashboard_customize_outlined,
          size: 48,
          color: context.inTheme.ink3,
        ),
        SizedBox(height: InSpacing.md(context)),
        Text(
          context.tr('drag_and_drop_to_add'),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.inTheme.ink3),
        ),
      ],
    ),
  );
}

class _CanvasBlock extends StatelessWidget {
  const _CanvasBlock({
    required this.vm,
    required this.block,
    required this.cellWidth,
    required this.cellHeight,
    required this.sample,
    required this.selected,
  });

  final WysiwygDesignViewModel vm;
  final DesignBlock block;
  final double cellWidth;
  final double cellHeight;
  final DesignerSampleData sample;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = block.gridPosition;
    final tokens = context.inTheme;
    final width = p.w * cellWidth;
    final height = p.h * cellHeight;

    final body = GestureDetector(
      onTap: () => vm.selectBlock(block.id),
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(InRadii.r2),
            border: Border.all(
              color: selected ? tokens.accent : Colors.transparent,
              width: 2,
            ),
          ),
          // Phase 1.5 #4: the inline _SelectionToolbar moved up to the
          // canvas Stack as _FloatingSelectionToolbar so it can render
          // above a y=0 block without being clipped by this block's
          // bounds.
          child: BlockPreview(block: block, sample: sample),
        ),
      ),
    );

    return Positioned(
      left: p.x * cellWidth,
      top: p.y * cellHeight,
      width: width,
      height: height,
      // Locked blocks omit the Draggable wrap — drag attempts no-op.
      child: block.locked
          ? body
          : _DraggableBlock(
              block: block,
              width: width,
              height: height,
              child: body,
            ),
    );
  }
}

/// Wraps the block body in a `Draggable<CanvasDropPayload>` on desktop
/// and a `LongPressDraggable` on touch so the same gesture system supports
/// both input modes. The feedback widget is a translucent copy of the
/// block at its actual size; `childWhenDragging` fades the original.
class _DraggableBlock extends StatelessWidget {
  const _DraggableBlock({
    required this.block,
    required this.width,
    required this.height,
    required this.child,
  });

  final DesignBlock block;
  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final payload = BlockMovePayload(block);
    final feedback = Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.7,
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
    final childWhenDragging =
        Opacity(opacity: 0.3, child: IgnorePointer(child: child));

    if (isDesktop) {
      return Draggable<CanvasDropPayload>(
        data: payload,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: child,
      );
    }
    return LongPressDraggable<CanvasDropPayload>(
      data: payload,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: child,
    );
  }
}

/// Floating toolbar layered into the canvas Stack above the blocks. When
/// the selected block sits at `y > 0` the toolbar renders above it; for a
/// block at `y == 0` it slides inside the block's top edge so it stays
/// visible (previously clipped by the canvas's borders).
class _FloatingSelectionToolbar extends StatelessWidget {
  const _FloatingSelectionToolbar({
    required this.vm,
    required this.block,
    required this.cellWidth,
    required this.cellHeight,
  });

  final WysiwygDesignViewModel vm;
  final DesignBlock block;
  final double cellWidth;
  final double cellHeight;

  static const double _toolbarHeight = 28;
  // Phase 20a: approximate intrinsic width of the toolbar. Used to
  // keep it inside the canvas on the LEFT for narrow blocks near x=0
  // — anchoring by `right: canvasWidth - blockRight` alone lets the
  // natural-width toolbar overhang past x=0 when its width exceeds
  // `blockLeft + blockWidth`. The toolbar is 3 IconButtons (each at
  // Material's default 48-px tap target — `Icon(size: 18)` doesn't
  // shrink the surrounding hit area) + Padding(4,2) on the Material
  // wrapper, so measured intrinsic is ~150 px. Round up to be safe;
  // `MainAxisSize.min` keeps actual painting tight regardless.
  static const double _toolbarApproxWidth = 160;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final p = block.gridPosition;
    final blockLeft = p.x * cellWidth;
    final blockTop = p.y * cellHeight;
    final blockWidth = p.w * cellWidth;
    // Above the block when there's room; inside the top edge when the
    // block sits at y=0 (avoids canvas-border clipping).
    final top = blockTop >= _toolbarHeight + 2
        ? blockTop - _toolbarHeight - 2
        : blockTop + 2;
    final blockRight = blockLeft + blockWidth;
    final canvasWidth = cellWidth * kGridCols;
    // Anchor the toolbar to the block's right edge and let it size to its
    // content instead of forcing it into `width: blockWidth`. A narrow
    // selected block (w≈3) is thinner than the three-button toolbar
    // (~92px), which RenderFlex-overflowed this Row — "overflowed by 8.5
    // pixels on the right" in the diagnostics log.
    //
    // Phase 20a: clamp the right-anchor so the toolbar's implied left
    // edge stays >= 0 — without this, a 1-cell block at x=0 anchored to
    // its right edge would paint ~70 px past the canvas's left edge.
    // `maxRight` is the largest `Positioned.right` that keeps the
    // intrinsic-width toolbar inside the canvas on the left.
    final rawRight = canvasWidth - blockRight;
    final maxRight = canvasWidth - _toolbarApproxWidth;
    final right = maxRight <= 0
        ? 0.0
        : rawRight.clamp(0.0, maxRight).toDouble();
    return Positioned(
      top: top,
      right: right,
      child: Material(
        color: tokens.accent,
        borderRadius: BorderRadius.circular(InRadii.r1),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconAction(
                icon: Icons.copy_outlined,
                tooltip: context.tr('duplicate'),
                onPressed: () => vm.duplicateBlock(block.id),
              ),
              _IconAction(
                icon: block.locked
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                tooltip: context.tr(block.locked ? 'unlock' : 'lock'),
                onPressed: () => vm.toggleLock(block.id),
              ),
              _IconAction(
                icon: Icons.close,
                tooltip: context.tr('delete'),
                onPressed: () => vm.deleteBlock(block.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 8-handle resize overlay drawn around the selected block. Each handle is
/// a small filled circle at a corner or edge midpoint. Dragging a handle
/// adjusts the block's grid `(x, y, w, h)` by converting pixel deltas to
/// grid cells and clamping via [clampSize]. The gesture snapshots once to
/// history at the start (so the whole drag is one undoable step) and runs
/// [WysiwygDesignViewModel.fixOverlaps] on release to resolve any new
/// overlaps.
class _ResizeHandles extends StatefulWidget {
  const _ResizeHandles({
    required this.vm,
    required this.block,
    required this.cellWidth,
    required this.cellHeight,
  });

  final WysiwygDesignViewModel vm;
  final DesignBlock block;
  final double cellWidth;
  final double cellHeight;

  @override
  State<_ResizeHandles> createState() => _ResizeHandlesState();
}

class _ResizeHandlesState extends State<_ResizeHandles> {
  /// Pointer position in **global** screen coordinates at the start of the
  /// gesture. We compute cell deltas from
  /// `(currentGlobalPosition - _startGlobal)` rather than accumulating
  /// per-frame `details.delta`. The delta version was broken: Flutter
  /// reports `DragUpdateDetails.delta` in the *event receiver's local*
  /// coords, and the receiver (this handle's `Positioned`) moves with the
  /// block as it resizes. The result was a polluted accumulator that
  /// stopped growing past +1 cell. Global coords are immune to that.
  Offset _startGlobal = Offset.zero;
  late GridPosition _initial;

  static const double _handleSize = 8;
  static const double _hitSize = 18;

  void _startDrag(DragStartDetails details) {
    widget.vm.recordHistorySnapshot();
    _initial = widget.block.gridPosition;
    _startGlobal = details.globalPosition;
  }

  void _updateDrag(DragUpdateDetails details, ResizeHandleKind kind) {
    final accumulated = details.globalPosition - _startGlobal;
    final next = computeResizedGridPosition(
      initial: _initial,
      accumulatedPixels: accumulated,
      cellWidth: widget.cellWidth,
      cellHeight: widget.cellHeight,
      blockType: widget.block.type,
      touchesLeft: kind.touchesLeft,
      touchesRight: kind.touchesRight,
      touchesTop: kind.touchesTop,
      touchesBottom: kind.touchesBottom,
    );
    if (next != widget.block.gridPosition) {
      widget.vm.updateBlock(widget.block.copyWith(gridPosition: next));
    }
  }

  void _endDrag() {
    widget.vm.fixOverlaps();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.block.gridPosition;
    final left = p.x * widget.cellWidth;
    final top = p.y * widget.cellHeight;
    final width = p.w * widget.cellWidth;
    final height = p.h * widget.cellHeight;

    Widget handle(ResizeHandleKind kind, double dx, double dy) {
      return Positioned(
        left: left + dx - _hitSize / 2,
        top: top + dy - _hitSize / 2,
        width: _hitSize,
        height: _hitSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _startDrag,
          onPanUpdate: (d) => _updateDrag(d, kind),
          onPanEnd: (_) => _endDrag(),
          child: MouseRegion(
            cursor: kind.cursor,
            child: Center(
              child: Container(
                width: _handleSize,
                height: _handleSize,
                decoration: BoxDecoration(
                  color: context.inTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      key: const ValueKey('wysiwyg-resize-handles'),
      children: [
        handle(ResizeHandleKind.topLeft, 0, 0),
        handle(ResizeHandleKind.top, width / 2, 0),
        handle(ResizeHandleKind.topRight, width, 0),
        handle(ResizeHandleKind.right, width, height / 2),
        handle(ResizeHandleKind.bottomRight, width, height),
        handle(ResizeHandleKind.bottom, width / 2, height),
        handle(ResizeHandleKind.bottomLeft, 0, height),
        handle(ResizeHandleKind.left, 0, height / 2),
      ],
    );
  }
}

/// Promoted to `@visibleForTesting` so the cursor-mapping regression test
/// can import it without exposing the rest of the canvas internals.
@visibleForTesting
enum ResizeHandleKind {
  // macOS NSCursor has no diagonal-corner resize cursor — both the
  // per-corner names (`resizeUpLeft` etc.) AND the diagonal pair
  // (`resizeUpLeftDownRight` / `resizeUpRightDownLeft`) fall back to the
  // basic arrow on macOS (verified against the Flutter SDK source's
  // per-platform docstrings). Use the bidirectional cursors that DO
  // render on macOS, differentiating the two diagonal pairs:
  //   NW-SE corners → resizeLeftRight (maps to NSCursor.resizeLeftRight)
  //   NE-SW corners → resizeUpDown    (maps to NSCursor.resizeUpDown)
  // Axes don't perfectly match the diagonal direction but the cursor
  // change is clear and the two pairs are visually distinct from each
  // other and from the edge cursors.
  topLeft(
    touchesTop: true,
    touchesLeft: true,
    cursor: SystemMouseCursors.resizeLeftRight,
  ),
  top(touchesTop: true, cursor: SystemMouseCursors.resizeUp),
  topRight(
    touchesTop: true,
    touchesRight: true,
    cursor: SystemMouseCursors.resizeUpDown,
  ),
  right(touchesRight: true, cursor: SystemMouseCursors.resizeRight),
  bottomRight(
    touchesBottom: true,
    touchesRight: true,
    cursor: SystemMouseCursors.resizeLeftRight,
  ),
  bottom(touchesBottom: true, cursor: SystemMouseCursors.resizeDown),
  bottomLeft(
    touchesBottom: true,
    touchesLeft: true,
    cursor: SystemMouseCursors.resizeUpDown,
  ),
  left(touchesLeft: true, cursor: SystemMouseCursors.resizeLeft);

  const ResizeHandleKind({
    this.touchesTop = false,
    this.touchesRight = false,
    this.touchesBottom = false,
    this.touchesLeft = false,
    required this.cursor,
  });

  final bool touchesTop;
  final bool touchesRight;
  final bool touchesBottom;
  final bool touchesLeft;
  final MouseCursor cursor;
}

/// Step 5b: translucent rectangle at the snapped drop target while a drag
/// is in progress. Helps the user see WHERE the block will land (the
/// `Draggable.feedback` rides under the cursor; this rides on the grid).
class _DragGhost extends StatelessWidget {
  const _DragGhost({
    required this.ghost,
    required this.cellWidth,
    required this.cellHeight,
    required this.color,
  });

  final ({int x, int y, int w, int h}) ghost;
  final double cellWidth;
  final double cellHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: ghost.x * cellWidth,
      top: ghost.y * cellHeight,
      width: ghost.w * cellWidth,
      height: ghost.h * cellHeight,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(InRadii.r2),
          ),
        ),
      ),
    );
  }
}

/// Step 5c: alignment guide lines. Renders magenta accent lines spanning
/// the canvas whenever the dragged ghost's left / right / top / bottom
/// edge aligns with the corresponding edge of another block. Cheap O(n)
/// scan per build — only runs while dragging.
class _AlignmentGuides extends StatelessWidget {
  const _AlignmentGuides({
    required this.ghost,
    required this.blocks,
    required this.cellWidth,
    required this.cellHeight,
    required this.color,
  });

  final ({int x, int y, int w, int h}) ghost;
  final List<DesignBlock> blocks;
  final double cellWidth;
  final double cellHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final verticals = <int>{};
    final horizontals = <int>{};
    final ghostL = ghost.x;
    final ghostR = ghost.x + ghost.w;
    final ghostT = ghost.y;
    final ghostB = ghost.y + ghost.h;
    for (final b in blocks) {
      final p = b.gridPosition;
      final l = p.x;
      final r = p.x + p.w;
      final t = p.y;
      final btm = p.y + p.h;
      if (ghostL == l || ghostL == r) verticals.add(ghostL);
      if (ghostR == l || ghostR == r) verticals.add(ghostR);
      if (ghostT == t || ghostT == btm) horizontals.add(ghostT);
      if (ghostB == t || ghostB == btm) horizontals.add(ghostB);
    }
    if (verticals.isEmpty && horizontals.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _AlignmentGuidesPainter(
            verticals: verticals,
            horizontals: horizontals,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AlignmentGuidesPainter extends CustomPainter {
  _AlignmentGuidesPainter({
    required this.verticals,
    required this.horizontals,
    required this.cellWidth,
    required this.cellHeight,
    required this.color,
  });

  final Set<int> verticals;
  final Set<int> horizontals;
  final double cellWidth;
  final double cellHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (final x in verticals) {
      final px = x * cellWidth;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), paint);
    }
    for (final y in horizontals) {
      final py = y * cellHeight;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), paint);
    }
  }

  @override
  bool shouldRepaint(_AlignmentGuidesPainter old) =>
      old.verticals != verticals ||
      old.horizontals != horizontals ||
      old.cellWidth != cellWidth ||
      old.cellHeight != cellHeight ||
      old.color != color;
}

/// Pure helper for the resize gesture: given a starting [GridPosition], a
/// pixel-space accumulated offset, the cell size, and which edges/corners
/// the handle touches, compute the new (clamped) grid position. Extracted
/// from `_ResizeHandlesState` so the gesture math is unit-testable without
/// pumping a widget.
///
/// `accumulatedPixels` is the displacement of the cursor since the
/// gesture started — typically `details.globalPosition - startGlobal`
/// (NOT a per-frame delta, which would be polluted by the receiver's own
/// motion as the block resizes).
@visibleForTesting
GridPosition computeResizedGridPosition({
  required GridPosition initial,
  required Offset accumulatedPixels,
  required double cellWidth,
  required double cellHeight,
  required String blockType,
  required bool touchesLeft,
  required bool touchesRight,
  required bool touchesTop,
  required bool touchesBottom,
}) {
  final dxCells = (accumulatedPixels.dx / cellWidth).round();
  final dyCells = (accumulatedPixels.dy / cellHeight).round();
  var nx = initial.x;
  var ny = initial.y;
  var nw = initial.w;
  var nh = initial.h;
  if (touchesLeft) {
    nx = (initial.x + dxCells).clamp(0, initial.x + initial.w - 1);
    nw = initial.w - (nx - initial.x);
  } else if (touchesRight) {
    nw = initial.w + dxCells;
  }
  if (touchesTop) {
    ny = (initial.y + dyCells).clamp(0, initial.y + initial.h - 1);
    nh = initial.h - (ny - initial.y);
  } else if (touchesBottom) {
    nh = initial.h + dyCells;
  }
  final clamped = clampSize(
    type: blockType,
    desiredW: nw,
    desiredH: nh,
    x: nx,
    y: ny,
  );
  return GridPosition(x: nx, y: ny, w: clamped.w, h: clamped.h);
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, color: Colors.white, size: 16),
    tooltip: tooltip,
    padding: const EdgeInsets.all(4),
    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    onPressed: onPressed,
  );
}
