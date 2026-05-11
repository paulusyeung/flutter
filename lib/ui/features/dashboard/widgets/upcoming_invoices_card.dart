import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/dashboard/dashboard_list_rows.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/async_section.dart';
import 'package:admin/ui/features/dashboard/widgets/invoice_table.dart';
import 'package:admin/ui/features/dashboard/widgets/list_card.dart';

class UpcomingInvoicesCard extends StatelessWidget {
  const UpcomingInvoicesCard({
    super.key,
    required this.section,
    required this.formatter,
    required this.onInvoiceTap,
    required this.onClientTap,
    required this.onViewAll,
    required this.onRetry,
  });

  final AsyncSection<List<DashboardInvoiceRow>> section;
  final Formatter formatter;
  final void Function(DashboardInvoiceRow) onInvoiceTap;
  final void Function(DashboardInvoiceRow) onClientTap;
  final VoidCallback onViewAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard<DashboardInvoiceRow>(
      title: context.tr('upcoming_invoices'),
      section: section,
      footerLabel: context.tr('all_invoices'),
      onViewAll: onViewAll,
      onRetry: onRetry,
      emptyIcon: Icons.calendar_today_outlined,
      emptyTitle: context.tr('no_invoices_due_soon'),
      bodyBuilder: (context, rows) => DashboardInvoiceTable(
        rows: rows,
        formatter: formatter,
        onInvoiceTap: onInvoiceTap,
        onClientTap: onClientTap,
      ),
    );
  }
}
