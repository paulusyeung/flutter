import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/widgets/selection_checkbox.dart';

/// Canonical leading avatar/checkbox slot for entity list rows.
///
/// Reserves a 32×32 hit target on the start edge of the row and owns the
/// hover/selection swap: on desktop, hovering the slot reveals an empty
/// `SelectionCheckbox` in place of [defaultChild]; in selection mode the
/// checkbox is always visible and reflects [selected]. Hover is scoped to
/// the slot itself — moving the cursor over the name / money / pill cells
/// of the row does **not** reveal the checkbox.
///
/// Every `<Entity>ListTile` should use this widget for its leading slot.
/// Do not wrap the row in your own `MouseRegion` to drive selection reveal —
/// the row-wide scope is exactly the bug this widget exists to prevent.
class LeadingSelectSlot extends StatefulWidget {
  const LeadingSelectSlot({
    super.key,
    required this.selecting,
    required this.selected,
    required this.onSelectTap,
    required this.defaultChild,
  });

  /// Whole-list selection mode. When true the checkbox is always shown
  /// regardless of hover, and reflects [selected].
  final bool selecting;

  /// True when this row is part of the active selection.
  final bool selected;

  /// Fires when the user clicks the leading slot while the checkbox is
  /// visible (either via hover-reveal or selection mode). Null disables
  /// selection participation entirely — the slot renders [defaultChild]
  /// only, the cursor stays default, and hover-reveal never fires.
  final VoidCallback? onSelectTap;

  /// What renders when not selecting and not hovered (e.g. a tinted avatar
  /// for Clients, `SizedBox.shrink()` for entities without an identity
  /// avatar). The slot always reserves 32×32 regardless of whether
  /// [defaultChild] paints anything — that keeps the MouseRegion hit
  /// target stable and the row's right-hand columns aligned.
  final Widget defaultChild;

  @override
  State<LeadingSelectSlot> createState() => _LeadingSelectSlotState();
}

class _LeadingSelectSlotState extends State<LeadingSelectSlot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final canSelect = widget.onSelectTap != null;
    final Widget child;
    if (widget.selecting) {
      child = _HitTarget(
        onTap: widget.onSelectTap,
        child: SelectionCheckbox(checked: widget.selected),
      );
    } else if (_isHovered && canSelect) {
      child = _HitTarget(
        onTap: widget.onSelectTap,
        child: const SelectionCheckbox(checked: false),
      );
    } else {
      child = widget.defaultChild;
    }

    return SizedBox(
      width: kColLeadingWidth,
      height: 32,
      child: MouseRegion(
        onEnter: canSelect
            ? (_) {
                if (!_isHovered) setState(() => _isHovered = true);
              }
            : null,
        onExit: canSelect
            ? (_) {
                if (_isHovered) setState(() => _isHovered = false);
              }
            : null,
        child: child,
      ),
    );
  }
}

class _HitTarget extends StatelessWidget {
  const _HitTarget({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
