import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';

/// One row in the sidebar nav list. Three visual states:
///
///   * **active** — accent background + ink, bold weight.
///   * **inactive enabled** — transparent background, muted ink.
///   * **disabled** — same as inactive but with `ink4` and a tap that pops a
///     "Coming soon" SnackBar instead of switching branches. The disabled
///     state is what the design's many placeholder items use today.
class SidebarNavItem extends StatelessWidget {
  const SidebarNavItem({
    required this.label,
    required this.icon,
    required this.active,
    this.onTap,
    this.count,
    this.disabled = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final int? count;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final fg = disabled
        ? tokens.ink4
        : active
        ? tokens.accentInk
        : tokens.ink2;
    final iconFg = disabled
        ? tokens.ink4
        : active
        ? tokens.accent
        : tokens.ink3;
    final bg = active ? tokens.accentSoft : Colors.transparent;
    final effectiveOnTap = disabled
        ? () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('feature_coming_soon', {'feature': label}),
              ),
            ),
          )
        : onTap;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 6),
            _Badge(count: count!, active: active),
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
        child: row,
      ),
    );
    if (disabled) {
      return Tooltip(
        message: context.tr('coming_soon'),
        waitDuration: const Duration(milliseconds: 600),
        child: tile,
      );
    }
    return tile;
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
