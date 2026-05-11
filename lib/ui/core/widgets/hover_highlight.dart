import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Wraps [child] in a `MouseRegion` and paints a subtle background tint
/// while the pointer is over it. Used to make clickable cards / rows "pop"
/// on hover without relying solely on the default `InkWell` overlay (which
/// is so subtle it's easy to miss).
///
/// Place this *inside* the click handler (`InkWell` / `TableRowInkWell`) —
/// it does not handle taps itself, only the hover paint. When [enabled] is
/// false the wrapper is a no-op.
class HoverHighlight extends StatefulWidget {
  const HoverHighlight({
    super.key,
    required this.child,
    this.enabled = true,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final bool enabled;
  final BorderRadius? borderRadius;

  /// Hover background. Defaults to `tokens.surfaceAlt`.
  final Color? color;

  @override
  State<HoverHighlight> createState() => _HoverHighlightState();
}

class _HoverHighlightState extends State<HoverHighlight> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final tokens = context.inTheme;
    final hoverColor = widget.color ?? tokens.surfaceAlt;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovering ? hoverColor : Colors.transparent,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}
