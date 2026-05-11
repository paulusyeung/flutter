import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Uppercase, letter-spaced label that introduces a group of [SidebarNavItem]s.
/// Passes `null` for a bare spacer between groups.
class SidebarSectionHeader extends StatelessWidget {
  const SidebarSectionHeader(this.label, {super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      child: Text(
        label!.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: context.inTheme.ink3,
        ),
      ),
    );
  }
}
