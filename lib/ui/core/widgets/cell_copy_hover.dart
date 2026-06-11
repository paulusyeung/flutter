import 'package:flutter/material.dart';

import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/ui/core/widgets/copyable_value.dart';

/// Wraps a table cell with a hover-reveal copy icon.
///
/// When [value] is null or empty the wrapper is a no-op and the [child] is
/// rendered unchanged. Otherwise a small icon chip fades in on mouse hover
/// at the trailing edge (or leading edge for end-aligned cells, so it
/// doesn't overlap the right-justified value). Clicking the icon writes
/// [value] to the system clipboard and surfaces the standard
/// `copied_to_clipboard` snackbar (via [copyToClipboard]).
///
/// Mouse-only — `MouseRegion`'s `onEnter`/`onExit` never fire on touch, so
/// iOS/Android render the wrapper transparently with no extra affordance.
/// (Touch copy in detail screens is handled by [CopyableValue]; in lists a
/// tap navigates to the row, so there's deliberately no mobile copy here.)
class CellCopyHover extends StatefulWidget {
  const CellCopyHover({
    super.key,
    required this.child,
    required this.value,
    this.align = ColumnAlign.start,
  });

  final Widget child;
  final String? value;
  final ColumnAlign align;

  @override
  State<CellCopyHover> createState() => _CellCopyHoverState();
}

class _CellCopyHoverState extends State<CellCopyHover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (value == null || value.isEmpty) return widget.child;

    final isEnd = widget.align == ColumnAlign.end;

    return MouseRegion(
      onEnter: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 0,
            bottom: 0,
            start: isEnd ? 0 : null,
            end: isEnd ? null : 0,
            child: IgnorePointer(
              ignoring: !_hovering,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: _hovering ? 1.0 : 0.0,
                child: Center(
                  // Dense surface: keep Tab walking rows, not cells.
                  child: CopyIconButton(value: value, canRequestFocus: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
