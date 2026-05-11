import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/models/value/date.dart';

/// Ghost-style button in the TopBar that opens a popover with date-range
/// presets + a "Custom range..." option. Matches `screens.jsx:198`.
class DateRangePickerButton extends StatelessWidget {
  const DateRangePickerButton({
    super.key,
    required this.current,
    required this.onChange,
  });

  final DashboardDateRange current;
  final ValueChanged<DashboardDateRange> onChange;

  static const String _customKey = '__custom__';

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final label = _labelFor(current);
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
            child: Text(_presetLabel(preset)),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _customKey,
          child: Text('Custom range...'),
        ),
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

  String _labelFor(DashboardDateRange r) {
    if (r is DashboardPresetRange) return _presetLabel(r.preset);
    if (r is DashboardCustomRange) {
      return '${r.start.toIso()} → ${r.end.toIso()}';
    }
    return 'Date range';
  }

  String _presetLabel(DashboardDatePreset p) {
    switch (p) {
      case DashboardDatePreset.last7:
        return 'Last 7 days';
      case DashboardDatePreset.last30:
        return 'Last 30 days';
      case DashboardDatePreset.last365:
        return 'Last 365 days';
      case DashboardDatePreset.thisMonth:
        return 'This month';
      case DashboardDatePreset.lastMonth:
        return 'Last month';
      case DashboardDatePreset.thisQuarter:
        return 'This quarter';
      case DashboardDatePreset.lastQuarter:
        return 'Last quarter';
      case DashboardDatePreset.thisYear:
        return 'This year';
      case DashboardDatePreset.lastYear:
        return 'Last year';
      case DashboardDatePreset.allTime:
        return 'All time';
    }
  }
}
