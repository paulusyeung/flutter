import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/core/adaptive.dart';

/// Lays out two edit fields side-by-side on wide widths, stacked on narrow.
///
/// Mirror of `ClientEditFieldPair`. Kept independent so vendor edits stay
/// decoupled from client widgets — same pattern the Project / Product
/// edits follow.
class VendorEditFieldPair extends StatelessWidget {
  const VendorEditFieldPair({
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
              SizedBox(width: InSpacing.md(context)),
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
