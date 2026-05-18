import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Shared selected-row chrome for every entity list tile.
///
/// Replaces the per-tile hand-rolled `Material`/`InkWell`/`DecoratedBox`
/// selection styling that previously diverged across the 17 list tiles.
///
/// Design (see `docs/.../when-i-select-a-wiggly-crescent.md` plan):
///
/// * **Selected** → a rounded `accentSoft` highlight painted *behind* the
///   unmodified [child]. The inset is applied to the decoration layer only,
///   never to the child, so wide-table column cells stay pixel-aligned with
///   the fixed `EntityListColumnHeaders` strip (which is not inset and cannot
///   be). `urlSelected` (the master-detail-active row) adds a 1px [accent]
///   border so it reads distinctly from a plain multi-select member and
///   stays legible in dark mode where `accentSoft` is near `surface`.
/// * **Not selected** → the [child] edge-to-edge with a full-bleed bottom
///   hairline, suppressed via [hideBottomDivider] (last row, the selected
///   row itself, or the row directly above the selected one — the scaffold
///   computes this since a tile can't see its neighbour's selection state).
/// * **Ink / hover** → selected rows use a bare [GestureDetector]: on macOS,
///   Material 3 paints an opaque hover overlay over a non-transparent
///   Material color and `overlayColor: transparent` does not suppress it.
///   With no `InkWell` in the tree no overlay can fire, so `accentSoft`
///   stays readable on hover. Unselected rows keep the `InkWell` (its
///   `surfaceAlt` hover + the Material focus highlight for keyboard nav).
///
/// No animation: selection snaps. Arrow-key / J-K navigation in the
/// master-detail list moves selection on every keypress; an implicit tween
/// would smear and trail the focused row.
class SelectableListRow extends StatelessWidget {
  const SelectableListRow({
    super.key,
    required this.selected,
    required this.urlSelected,
    required this.hideBottomDivider,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  /// Drives the `accentSoft` fill. True for both multi-select members and the
  /// master-detail-active row (every screen passes
  /// `selected: vm.isSelected(id) || isUrlSelected`).
  final bool selected;

  /// Adds the 1px [accent] border. Always implies [selected] given how
  /// screens combine the flags, so `urlSelected && !selected` is unreachable
  /// and intentionally has no rendering branch.
  final bool urlSelected;

  /// Suppresses the bottom hairline. Computed by the list scaffold as
  /// `isLast || thisRowSelected || nextRowSelected`.
  final bool hideBottomDivider;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// The tile's own already-padded row content. Its interior padding is left
  /// untouched so column cells stay aligned with the header strip.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;

    final Widget body;
    if (selected) {
      body = Stack(
        children: [
          // First child = painted behind; `child` (non-positioned) sizes the
          // Stack, then this fills that box inset by sm/xs.
          Positioned.fill(
            left: InSpacing.sm,
            right: InSpacing.sm,
            top: InSpacing.xs,
            bottom: InSpacing.xs,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.accentSoft,
                borderRadius: BorderRadius.circular(InRadii.r2),
                border: urlSelected
                    ? Border.all(color: tokens.accent, width: 1)
                    : null,
              ),
            ),
          ),
          child,
        ],
      );
    } else {
      body = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: hideBottomDivider
                ? BorderSide.none
                : BorderSide(color: tokens.border),
          ),
        ),
        child: child,
      );
    }

    if (selected) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: body,
      );
    }
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      hoverColor: tokens.surfaceAlt,
      child: body,
    );
  }
}
