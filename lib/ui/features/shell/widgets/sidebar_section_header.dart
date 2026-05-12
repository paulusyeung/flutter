import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Uppercase, letter-spaced label that introduces a group of [SidebarNavItem]s.
/// Passes `null` for a bare spacer between groups.
///
/// In `compact` mode (collapsed wide sidebar) the text is replaced with a
/// 1-px horizontal rule so visual grouping survives without overflowing the
/// 64-px rail.
class SidebarSectionHeader extends StatelessWidget {
  const SidebarSectionHeader(this.label, {this.compact = false, super.key});

  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox(height: 8);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(height: 1, color: context.inTheme.border),
      );
    }
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
