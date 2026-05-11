import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/date_range_picker_button.dart';
import 'package:admin/ui/features/dashboard/widgets/filters/settings_popover.dart';

/// TopBar shown above the dashboard scroll. Matches `screens.jsx:196-201`:
///   title = company name, subtitle = "Dashboard · {Month YYYY}",
///   actions = date-range button + settings popover + refresh + New invoice.
class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.vm,
    required this.companyName,
    required this.onNewInvoice,
    required this.onRefresh,
  });

  final DashboardViewModel vm;
  final String companyName;
  final VoidCallback onNewInvoice;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final (_, end) = vm.filter.resolveDates();
    final subtitle = 'Dashboard · ${_monthName(end.month)} ${end.year}';

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
              ),
              IconButton(
                onPressed: () => _openSettings(context),
                icon: Icon(Icons.tune, size: 18, color: tokens.ink2),
                tooltip: 'Settings',
              ),
              IconButton(
                onPressed: vm.isAnyRefreshing ? null : onRefresh,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: vm.isAnyRefreshing ? tokens.ink3 : tokens.ink2,
                ),
                tooltip: 'Refresh',
              ),
              FilledButton.icon(
                onPressed: onNewInvoice,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('New invoice'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final tokens = context.inTheme;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    if (isWide) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Offset offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
      final size = box?.size ?? const Size(320, 32);
      await showMenu<void>(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx + size.width - 320,
          offset.dy + size.height + 4,
          offset.dx + size.width,
          offset.dy,
        ),
        color: tokens.surface,
        items: [
          PopupMenuItem<void>(
            enabled: false,
            child: DashboardSettingsForm(vm: vm),
          ),
        ],
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => DashboardSettingsForm(vm: vm),
      );
    }
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _monthName(int m) => (m >= 1 && m <= 12) ? _months[m - 1] : '';
}
