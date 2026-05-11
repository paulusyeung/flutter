import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/date_range_picker_button.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/settings_popover.dart';

/// TopBar shown above the dashboard scroll. Matches `screens.jsx:196-201`:
///   title = company name, subtitle = "Dashboard · {Month YYYY}",
///   actions = combined date-range/filter popover + "New invoice".
/// Refresh is reached via the page's pull-to-refresh; currency and
/// include-drafts are folded into the date-range popover.
class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.vm,
    required this.companyName,
    required this.onNewInvoice,
    this.formatter,
  });

  final DashboardViewModel vm;
  final String companyName;
  final VoidCallback onNewInvoice;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final (_, end) = vm.filter.resolveDates();
    final subtitle =
        '${context.tr('dashboard')} · ${_monthName(context, end.month)} ${end.year}';

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        InSpacing.xl,
        InSpacing.md,
        InSpacing.xl,
        InSpacing.md,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
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
              FilledButton.icon(
                onPressed: onNewInvoice,
                style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                icon: const Icon(Icons.add, size: 14),
                label: Text(context.tr('new_invoice')),
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
