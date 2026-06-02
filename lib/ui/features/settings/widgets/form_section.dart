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
    this.elevated = true,
  });

  /// Section heading. When null, the header row + divider are omitted
  /// entirely and the card is just a padded container of [children] —
  /// used by the billing-doc edit cards which want a flat, title-less
  /// look. Settings screens pass a non-null title.
  final String? title;
  final List<Widget> children;
  final Widget? trailing;

  /// When false, drop the drop shadow (keep the 1px border) for a
  /// flatter look. Default true preserves the existing settings /
  /// dashboard appearance.
  final bool elevated;

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
          boxShadow: elevated ? tokens.shadow1 : null,
        ),
        // A transparent Material gives descendant ListTiles/InkWells a Material
        // ancestor to paint ink on — without it, Flutter 3.44 asserts because
        // this Container's background would hide the ink.
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
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
                          title!,
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
              ],
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
