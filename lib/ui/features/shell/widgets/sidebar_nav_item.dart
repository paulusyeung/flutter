import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// One row in the sidebar nav list. Three visual states:
///
///   * **active** — accent background + ink, bold weight.
///   * **inactive enabled** — transparent background, muted ink.
///   * **disabled** — same as inactive but with `ink4` and a tap that pops a
///     "Coming soon" SnackBar instead of switching branches. The disabled
///     state is what the design's many placeholder items use today.
///
/// Optional [trailingHover] reveals a secondary action button on mouse
/// hover (wide-mode only — compact rail and disabled rows ignore it). The
/// hover slot is intended for `IconButton`-shaped widgets whose internal
/// gesture detector consumes taps so the row's `onTap` doesn't also fire.
class SidebarNavItem extends StatefulWidget {
  const SidebarNavItem({
    required this.label,
    required this.icon,
    required this.active,
    this.onTap,
    this.count,
    this.disabled = false,
    this.compact = false,
    this.trailingHover,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final int? count;
  final bool disabled;

  /// Icon-only variant for the collapsed wide-layout sidebar. The label
  /// surfaces in a hover tooltip; the optional `count` becomes a small accent
  /// dot at the icon's top-right (numbers don't fit in 64 px).
  final bool compact;

  /// Secondary action revealed at the row's right edge when the mouse
  /// hovers over this row. Ignored in [compact] mode (no horizontal room)
  /// and on [disabled] rows (no real action to invoke).
  final Widget? trailingHover;

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _hovered = false;

  bool get _showsTrailingHover =>
      widget.trailingHover != null && !widget.compact && !widget.disabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final fg = widget.disabled
        ? tokens.ink4
        : widget.active
        ? tokens.accentInk
        : tokens.ink2;
    final iconFg = widget.disabled
        ? tokens.ink4
        : widget.active
        ? tokens.accent
        : tokens.ink3;
    final bg = widget.active ? tokens.accentSoft : Colors.transparent;
    final effectiveOnTap = widget.disabled
        ? () => Notify.info(
            context,
            context.tr('feature_coming_soon', {'feature': widget.label}),
          )
        : widget.onTap;
    final iconWidget = Icon(widget.icon, size: 18, color: iconFg);
    final body = widget.compact
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.count != null && widget.count! > 0
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        iconWidget,
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            key: const Key('clients-badge-dot'),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tokens.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: tokens.surface,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : iconWidget,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.active
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
                if (widget.count != null && widget.count! > 0) ...[
                  const SizedBox(width: 6),
                  _Badge(count: widget.count!, active: widget.active),
                ],
                if (_showsTrailingHover && _hovered) ...[
                  const SizedBox(width: 4),
                  widget.trailingHover!,
                ],
              ],
            ),
          );
    final tile = Material(
      color: bg,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: InkWell(
        onTap: effectiveOnTap,
        borderRadius: BorderRadius.circular(InRadii.r2),
        child: body,
      ),
    );
    Widget result = tile;
    if (_showsTrailingHover) {
      result = MouseRegion(
        onEnter: (_) {
          if (!_hovered) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_hovered) setState(() => _hovered = false);
        },
        child: result,
      );
    }
    if (widget.disabled) {
      return Tooltip(
        message: context.tr('coming_soon'),
        waitDuration: const Duration(milliseconds: 600),
        child: result,
      );
    }
    if (widget.compact) {
      // Enabled items also need a tooltip in compact mode — the label is the
      // only thing telling the user what this icon is.
      return Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 600),
        child: result,
      );
    }
    return result;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.active});

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active ? tokens.surface : tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        count > 999 ? '999+' : '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active ? tokens.accent : tokens.ink3,
        ),
      ),
    );
  }
}
