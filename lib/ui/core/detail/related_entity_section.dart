import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Wraps an embedded list inside an entity detail tab body: a header row
/// with the section title and a "View all" link routing to the standalone
/// workspace screen pre-scoped to this parent, plus a fixed-height region
/// hosting the embedded list. The host tab already owns the bordered card
/// chrome (see `EntityDetailTabs`) — this widget adds only the header and
/// the height constraint a `ListView` needs to render inside a scrollable
/// parent.
///
/// Used by the client and vendor detail tabs to embed `InvoiceListScreen`,
/// `ExpenseListScreen`, etc. with their parent-id filter.
class RelatedEntitySection extends StatelessWidget {
  const RelatedEntitySection({
    super.key,
    required this.titleKey,
    required this.viewAllPath,
    required this.viewAllLabelKey,
    required this.child,
  });

  /// Localization key for the section header (e.g. `'invoices'`).
  final String titleKey;

  /// Route + query string for the "View all" link (e.g.
  /// `/invoices?client_id=abc_123`). The top-level list's `listBuilder` in
  /// `lib/app/entity_modules.dart` reads the query param.
  final String viewAllPath;

  /// Localization key for the link label (e.g. `'view_all_invoices'`).
  final String viewAllLabelKey;

  /// The embedded list widget (e.g.
  /// `InvoiceListScreen(clientId: id, embedded: true)`).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Row(
            children: [
              Text(
                context.tr(titleKey),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              LinkText(
                label: context.tr(viewAllLabelKey),
                onTap: () => GoRouter.of(context).go(viewAllPath),
              ),
            ],
          ),
        ),
        // ListView inside a SingleChildScrollView needs a bounded height.
        // Half the viewport, clamped to 320–520 so a tall detail body still
        // surfaces the rest of the screen below the tab strip. The "View
        // all" link is the escape hatch when the user needs more rows.
        LayoutBuilder(
          builder: (ctx, _) {
            final viewport = MediaQuery.sizeOf(ctx).height;
            final height = (viewport * 0.5).clamp(320.0, 520.0);
            return SizedBox(height: height, child: child);
          },
        ),
      ],
    );
  }
}
