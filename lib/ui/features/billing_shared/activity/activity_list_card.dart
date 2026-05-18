import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// The bordered card the embedded entity datatables render inside
/// (`_wideTable` in `entity_list_screen_scaffold.dart`). Reused by the
/// Activity tab so its list matches the sibling Invoices/Quotes/… tabs.
class ActivityListCard extends StatelessWidget {
  const ActivityListCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      child: child,
    );
  }
}
