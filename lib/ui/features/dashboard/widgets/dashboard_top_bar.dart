import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/date_range_picker_button.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/settings_popover.dart';

/// Wide-layout TopBar shown above the dashboard scroll. Matches
/// `screens.jsx:196-201`: title = company name, subtitle = "Dashboard ·
/// {Month YYYY}", actions = combined date-range/filter popover + settings +
/// "New invoice". Refresh is reached via the page's pull-to-refresh; currency
/// and include-drafts are folded into the date-range popover.
///
/// Mobile uses a standard `AppBar` instead — see `DashboardScreen` for the
/// narrow-width path.
class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.vm,
    required this.companyName,
    this.onNewInvoice,
    this.onAddClient,
    this.onLogExpense,
    this.onReports,
    this.formatter,
  });

  final DashboardViewModel vm;
  final String companyName;

  /// Null when the invoices module is disabled — the primary "New invoice"
  /// button is then omitted entirely.
  final VoidCallback? onNewInvoice;

  /// Secondary quick actions, surfaced in an overflow menu next to the
  /// primary "New Invoice" button so desktop has the same fast paths as
  /// the mobile quick-actions row. Null entries are omitted.
  final VoidCallback? onAddClient;
  final VoidCallback? onLogExpense;
  final VoidCallback? onReports;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final (_, end) = vm.filter.resolveDates();
    final subtitle =
        '${context.tr('dashboard')} · ${_monthName(context, end.month)} ${end.year}';
    final newInvoiceLabel = context.tr('new_invoice');

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        InSpacing.xl,
        InSpacing.md(context),
        InSpacing.xl,
        InSpacing.md(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tokens.ink3),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: InSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DateRangePickerButton(
                current: vm.filter.range,
                onChange: vm.setDateRange,
                formatter: formatter,
              ),
              DashboardSettingsButton(vm: vm),
              if (onNewInvoice != null)
                FilledButton.icon(
                  onPressed: onNewInvoice,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(newInvoiceLabel),
                ),
              if (_overflowEntries(context).isNotEmpty)
                PopupMenuButton<VoidCallback>(
                  tooltip: context.tr('more_actions'),
                  position: PopupMenuPosition.under,
                  icon: Icon(Icons.more_vert, color: tokens.ink2),
                  onSelected: (cb) => cb(),
                  itemBuilder: (context) => _overflowEntries(context),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<VoidCallback>> _overflowEntries(BuildContext context) {
    PopupMenuItem<VoidCallback> item(
      IconData icon,
      String key,
      VoidCallback cb,
    ) {
      final tokens = context.inTheme;
      return PopupMenuItem<VoidCallback>(
        value: cb,
        child: Row(
          children: [
            Icon(icon, size: 16, color: tokens.ink2),
            const SizedBox(width: InSpacing.sm),
            Text(context.tr(key)),
          ],
        ),
      );
    }

    return [
      if (onAddClient != null)
        item(Icons.person_add_alt_1_outlined, 'new_client', onAddClient!),
      if (onLogExpense != null)
        item(Icons.receipt_long_outlined, 'new_expense', onLogExpense!),
      if (onReports != null)
        item(Icons.bar_chart_outlined, 'reports', onReports!),
    ];
  }

  static const _monthKeys = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];

  String _monthName(BuildContext context, int m) =>
      (m >= 1 && m <= 12) ? context.tr(_monthKeys[m - 1]) : '';
}
