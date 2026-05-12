import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/adaptive.dart';

/// Lays out two edit fields side-by-side on wide widths, stacked on narrow.
///
/// Used inside the edit-screen cards to pair semantically-related fields
/// (e.g. first_name + last_name, city + state) so a desktop card reads as
/// half as tall as one stacked column.
///
/// Below [Breakpoints.wide] the two children stack as a `Column` so each
/// gets the full card width.
class ClientEditFieldPair extends StatelessWidget {
  const ClientEditFieldPair({
    super.key,
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isWide(constraints)) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: InSpacing.md),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [left, right],
        );
      },
    );
  }
}
