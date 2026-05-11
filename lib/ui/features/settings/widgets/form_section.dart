import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Groups a related set of form fields under a single subheading, rendered
/// as a bordered card (surface + 1px border + r3 + shadow1) with a header
/// row + divider. Mirrors the v2 card pattern used by the dashboard and
/// client detail screens.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: InSpacing.lg),
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
              padding: const EdgeInsets.fromLTRB(
                InSpacing.lg,
                InSpacing.lg,
                InSpacing.lg,
                InSpacing.md,
              ),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: tokens.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: tokens.border),
            Padding(
              padding: const EdgeInsets.all(InSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
