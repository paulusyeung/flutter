import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Groups a related set of form fields under a single subheading, rendered
/// as a bordered card (surface + 1px border + r3 + shadow1) with a header
/// row + divider. Mirrors the v2 card pattern used by the dashboard and
/// client detail screens. The optional [trailing] widget renders on the
/// right of the header row (e.g. an "Upload" button on the Documents tab).
///
/// [spacing] (default `InSpacing.lg(context)`) is interleaved between adjacent
/// children so callers don't sprinkle `SizedBox(height: …)` between every
/// field — pass `0` if the section manages its own gaps (e.g. it places a
/// `Divider` between rows).
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.spacing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  /// Gap interleaved between adjacent children. Null falls back to the
  /// responsive `InSpacing.lg(context)` (12 narrow / 16 wide).
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: InSpacing.lg(context)),
      child: Container(
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
            Padding(
              padding: EdgeInsets.fromLTRB(
                InSpacing.lg(context),
                InSpacing.lg(context),
                InSpacing.lg(context),
                InSpacing.md(context),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tokens.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: tokens.border),
            Padding(
              padding: EdgeInsets.all(InSpacing.lg(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _interleave(
                  children,
                  spacing ?? InSpacing.lg(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _interleave(List<Widget> children, double spacing) {
    if (spacing == 0 || children.length < 2) return children;
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(height: spacing));
      out.add(children[i]);
    }
    return out;
  }
}
