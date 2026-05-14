import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Shared shell every dashboard card uses: bordered surface card with an
/// optional title row + trailing link, optional inner padding override, and a
/// content body. Matches the v2 mockup's pattern (surface + 1px border + r3
/// + shadow1).
class DashboardCardShell extends StatelessWidget {
  const DashboardCardShell({
    super.key,
    this.title,
    this.trailing,
    this.padding,
    required this.child,
  });

  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final hasHeader = title != null || trailing != null;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
        boxShadow: tokens.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                InSpacing.lg(context),
                InSpacing.lg(context),
                InSpacing.lg(context),
                InSpacing.md(context),
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: tokens.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: tokens.border),
          ],
          Padding(
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: InSpacing.lg(context),
                  vertical: InSpacing.md(context),
                ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Standard "View all"-style footer link. Capitalisation and copy varies by
/// card — pass the desired label.
class DashboardCardFooterLink extends StatelessWidget {
  const DashboardCardFooterLink({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(InRadii.r1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinkText(
              label: label,
              style: TextStyle(fontSize: 12, color: tokens.ink3),
            ),
            Icon(Icons.chevron_right, size: 14, color: tokens.ink3),
          ],
        ),
      ),
    );
  }
}
