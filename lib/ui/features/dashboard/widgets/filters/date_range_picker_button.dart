import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';

/// Ghost-style button in the TopBar that opens a popover with date-range
/// presets + a "Custom range..." option. Matches `screens.jsx:198`.
class DateRangePickerButton extends StatelessWidget {
  const DateRangePickerButton({
    super.key,
    required this.current,
    required this.onChange,
    this.extraContent,
  });

  final DashboardDateRange current;
  final ValueChanged<DashboardDateRange> onChange;

  /// Optional widget rendered as a non-dismissing footer inside the popover —
  /// used by the dashboard to fold currency / include-drafts controls in
  /// alongside the date presets, matching the design's single-filter spec.
  final Widget? extraContent;

  static const String _customKey = '__custom__';

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final label = _labelFor(context, current);
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: tokens.ink2,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadii.r2),
          side: BorderSide(color: tokens.border),
        ),
      ),
      icon: const Icon(Icons.filter_alt_outlined, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Offset offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? const Size(160, 32);
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy,
      ),
      items: [
        for (final preset in DashboardDatePreset.values)
          PopupMenuItem<String>(
            value: preset.name,
            child: Text(_presetLabel(context, preset)),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: _customKey,
          child: Text('${context.tr('custom_range')}...'),
        ),
        if (extraContent != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem<String>(enabled: false, child: extraContent!),
        ],
      ],
    );
    if (result == null || !context.mounted) return;
    if (result == _customKey) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      if (picked == null) return;
      onChange(
        DashboardCustomRange(
          start: Date(picked.start.year, picked.start.month, picked.start.day),
          end: Date(picked.end.year, picked.end.month, picked.end.day),
        ),
      );
      return;
    }
    final preset = DashboardDatePreset.values.firstWhere(
      (p) => p.name == result,
      orElse: () => DashboardDatePreset.thisMonth,
    );
    onChange(DashboardPresetRange(preset));
  }

  String _labelFor(BuildContext context, DashboardDateRange r) {
    if (r is DashboardPresetRange) return _presetLabel(context, r.preset);
    if (r is DashboardCustomRange) {
      return '${r.start.toIso()} → ${r.end.toIso()}';
    }
    return context.tr('date_range');
  }

  String _presetLabel(BuildContext context, DashboardDatePreset p) {
    final key = switch (p) {
      DashboardDatePreset.last7 => 'last7_days',
      DashboardDatePreset.last30 => 'last_30_days',
      // No upstream key for "Last 365 days" — falls through to pending.
      DashboardDatePreset.last365 => 'last_365_days',
      DashboardDatePreset.thisMonth => 'this_month',
      DashboardDatePreset.lastMonth => 'last_month',
      DashboardDatePreset.thisQuarter => 'this_quarter',
      DashboardDatePreset.lastQuarter => 'last_quarter',
      DashboardDatePreset.thisYear => 'this_year',
      DashboardDatePreset.lastYear => 'last_year',
      DashboardDatePreset.allTime => 'all_time',
    };
    return context.tr(key);
  }
}
