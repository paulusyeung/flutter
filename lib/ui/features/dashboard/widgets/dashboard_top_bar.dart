import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/date_range_picker_button.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/settings_popover.dart';
import 'package:admin/ui/features/dashboard/widgets/manage_dashboard_cards_sheet.dart';

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
    this.formatter,
  });

  final DashboardViewModel vm;
  final String companyName;

  /// Null when the invoices module is disabled — the primary "New invoice"
  /// button is then omitted entirely.
  final VoidCallback? onNewInvoice;

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
              DashboardCardsButton(vm: vm),
              if (onNewInvoice != null)
                FilledButton.icon(
                  onPressed: onNewInvoice,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text(newInvoiceLabel),
                ),
            ],
          ),
        ],
      ),
    );
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
