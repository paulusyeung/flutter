import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/invoice_table.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';

/// "Needs your attention" — full-width past-due invoice table. Matches
/// `screens.jsx:298-305`: card shell + `InvoiceTable` (compact).
class NeedsYourAttentionCard extends StatelessWidget {
  const NeedsYourAttentionCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onRowTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardInvoiceRow>> section;
  final Formatter formatter;
  final void Function(DashboardInvoiceRow) onRowTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardInvoiceRow>(
      title: context.tr('needs_your_attention'),
      section: section,
      footerLabel: context.tr('all_invoices'),
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.check_circle_outline,
      emptyTitle: context.tr('all_caught_up'),
      emptySubtitle: context.tr('nothing_overdue_message'),
      bodyBuilder: (context, rows) => DashboardInvoiceTable(
        rows: rows,
        formatter: formatter,
        onRowTap: onRowTap,
        alwaysOverdue: true,
      ),
    );
  }
}
