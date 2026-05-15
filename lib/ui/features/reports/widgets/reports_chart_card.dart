import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/report_preview.dart';
import 'package:admin/domain/reports/report_column_types.dart';
import 'package:admin/domain/reports/report_engine.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/reports/view_models/reports_view_model.dart';

/// Bar chart per group, anchored on the picked numeric column. Renders
/// between the drill breadcrumb and the totals card in `_ReportTableArea`.
/// Caller is responsible for the visibility gate — the card assumes it's
/// mounted only when `view.groups.isNotEmpty && vm.chartVisible`.
///
/// Manages two pieces of local state: the auto-picked chart column (read
/// back from `vm.chartColumn` after the post-frame callback) and the
/// active currency for multi-currency views (transient — not persisted on
/// the VM).
class ReportsChartCard extends StatefulWidget {
  const ReportsChartCard({
    super.key,
    required this.view,
    required this.formatter,
  });

  final ReportView view;
  final Formatter? formatter;

  @override
  State<ReportsChartCard> createState() => _ReportsChartCardState();
}

class _ReportsChartCardState extends State<ReportsChartCard> {
  String? _activeCurrency;

  @override
  void initState() {
    super.initState();
    _scheduleAutoPick();
  }

  @override
  void didUpdateWidget(ReportsChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleAutoPick();
  }

  /// Auto-pick the first numeric column when `vm.chartColumn` is null or
  /// stale (refers to a column the current preview doesn't carry). Runs
  /// post-frame so we don't notify mid-build; guarded by `mounted` so a
  /// disposed card (report switch) doesn't fire a stale write.
  void _scheduleAutoPick() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<ReportsViewModel>();
      final numeric = vm.numericChartColumns();
      if (numeric.isEmpty) return;
      final current = vm.chartColumn;
      final isValid = current != null &&
          numeric.any((c) => c.identifier == current);
      if (!isValid) {
        vm.setChartColumn(numeric.first.identifier);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    final numeric = vm.numericChartColumns();
    final groupColumnId = vm.group;
    final groupColumn = _findColumn(widget.view, groupColumnId);
    final groupLabel = groupColumn?.displayLabel ?? context.tr('chart');

    final picked = _pickedColumn(vm, numeric);
    final allCurrencies = _allCurrenciesForColumn(picked?.identifier);
    final defaultCurrency = _defaultCurrency(allCurrencies);
    final currency = _activeCurrency ?? defaultCurrency;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.sm,
      ),
      child: DashboardCardShell(
        title: groupLabel,
        trailing: _HeaderTrailing(
          numericColumns: numeric,
          pickedColumnId: picked?.identifier,
          currencies: allCurrencies,
          activeCurrency: currency,
          onColumnChanged: (id) {
            if (id == null) return;
            vm.setChartColumn(id);
            // Reset active currency so the default policy re-evaluates
            // against the new column's currency mix.
            setState(() => _activeCurrency = null);
          },
          onCurrencyChanged: (cur) =>
              setState(() => _activeCurrency = cur),
          onClose: () => vm.setChartVisible(false),
        ),
        child: _Body(
          view: widget.view,
          formatter: widget.formatter,
          pickedColumn: picked,
          groupColumn: groupColumn,
          currency: currency,
          showCurrencyHint:
              allCurrencies.length > 1 && _activeCurrency == null,
          accent: tokens.accent,
          axisLabelStyle: theme.textTheme.bodySmall?.copyWith(
            color: tokens.ink2,
          ),
        ),
      ),
    );
  }

  /// The column currently selected for charting, resolved to a `ReportColumn`
  /// from the available numeric set. Returns null when no numeric columns
  /// exist (the body renders the empty-state hint in that case).
  ReportColumn? _pickedColumn(
    ReportsViewModel vm,
    List<ReportColumn> numeric,
  ) {
    if (numeric.isEmpty) return null;
    final id = vm.chartColumn;
    if (id == null) return numeric.first;
    for (final c in numeric) {
      if (c.identifier == id) return c;
    }
    return numeric.first;
  }

  ReportColumn? _findColumn(ReportView view, String? id) {
    if (id == null) return null;
    for (final c in view.visibleColumns) {
      if (c.identifier == id) return c;
    }
    return null;
  }

  /// Union of every currency that appears in any group's bucket for the
  /// given column. Empty when no column is picked or no group has values
  /// for it.
  Set<String> _allCurrenciesForColumn(String? columnId) {
    if (columnId == null) return const <String>{};
    final out = <String>{};
    for (final g in widget.view.groups) {
      final perCur = g.numericTotals[columnId];
      if (perCur == null) continue;
      for (final cur in perCur.keys) {
        if (perCur[cur] != Decimal.zero) out.add(cur);
      }
    }
    return out;
  }

  /// The default currency for the chart: company currency if present in
  /// the data, otherwise the currency with the largest absolute total
  /// across all groups (the "dominant" one). Falls back to '' on empty.
  String _defaultCurrency(Set<String> currencies) {
    if (currencies.isEmpty) return '';
    final companyId = widget.formatter?.settings.currencyId;
    if (companyId != null && currencies.contains(companyId)) return companyId;
    // Pick the dominant currency by summed absolute value across groups.
    final pickedColumn = context.read<ReportsViewModel>().chartColumn;
    if (pickedColumn == null) return currencies.first;
    String best = currencies.first;
    Decimal bestSum = Decimal.zero;
    for (final cur in currencies) {
      Decimal sum = Decimal.zero;
      for (final g in widget.view.groups) {
        final v = g.numericTotals[pickedColumn]?[cur];
        if (v != null) sum += v.abs();
      }
      if (sum > bestSum) {
        bestSum = sum;
        best = cur;
      }
    }
    return best;
  }
}

class _HeaderTrailing extends StatelessWidget {
  const _HeaderTrailing({
    required this.numericColumns,
    required this.pickedColumnId,
    required this.currencies,
    required this.activeCurrency,
    required this.onColumnChanged,
    required this.onCurrencyChanged,
    required this.onClose,
  });

  final List<ReportColumn> numericColumns;
  final String? pickedColumnId;
  final Set<String> currencies;
  final String activeCurrency;
  final ValueChanged<String?> onColumnChanged;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final showColumnPicker = numericColumns.length > 1;
    final showCurrencyPicker = currencies.length > 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showColumnPicker) ...[
          DropdownButton<String>(
            value: pickedColumnId,
            underline: const SizedBox.shrink(),
            isDense: true,
            onChanged: onColumnChanged,
            items: [
              for (final c in numericColumns)
                DropdownMenuItem(
                  value: c.identifier,
                  child: Text(c.displayLabel),
                ),
            ],
          ),
          SizedBox(width: InSpacing.md(context)),
        ],
        if (showCurrencyPicker) ...[
          DropdownButton<String>(
            value: activeCurrency.isEmpty ? null : activeCurrency,
            underline: const SizedBox.shrink(),
            isDense: true,
            onChanged: (cur) {
              if (cur != null) onCurrencyChanged(cur);
            },
            items: [
              for (final cur in currencies)
                DropdownMenuItem(
                  value: cur,
                  child: Text(_currencyLabel(context, cur)),
                ),
            ],
          ),
          SizedBox(width: InSpacing.md(context)),
        ],
        IconButton(
          tooltip: context.tr('hide_chart'),
          icon: Icon(Icons.close, size: 18, color: tokens.ink3),
          onPressed: onClose,
        ),
      ],
    );
  }

  String _currencyLabel(BuildContext context, String currencyId) {
    // The Formatter resolves currency code/name from the statics. The
    // chart card may not be able to reach that map here without lifting
    // the formatter into the trailing widget — keep it simple and show
    // the id; the picker is rarely opened.
    return currencyId;
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.view,
    required this.formatter,
    required this.pickedColumn,
    required this.groupColumn,
    required this.currency,
    required this.showCurrencyHint,
    required this.accent,
    required this.axisLabelStyle,
  });

  final ReportView view;
  final Formatter? formatter;
  final ReportColumn? pickedColumn;
  final ReportColumn? groupColumn;
  final String currency;
  final bool showCurrencyHint;
  final Color accent;
  final TextStyle? axisLabelStyle;

  @override
  Widget build(BuildContext context) {
    if (pickedColumn == null) {
      return _EmptyHint(message: context.tr('no_numeric_values_to_chart'));
    }
    final values = _bars(view, pickedColumn!.identifier, currency);
    if (values.isEmpty) {
      return _EmptyHint(message: context.tr('no_numeric_values_to_chart'));
    }
    final maxY = values
        .map((b) => b.value.toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final yMax = maxY <= 0 ? 1.0 : maxY * 1.15;
    final rotateLabels = values.length > 6;
    final isMoney = pickedColumn!.type == ReportColumnType.money;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCurrencyHint)
          Padding(
            padding: EdgeInsets.only(bottom: InSpacing.sm),
            child: Text(
              context
                  .tr('chart_currency_hint')
                  .replaceFirst(':currency', currency),
              style: axisLabelStyle,
            ),
          ),
        Semantics(
          label: 'Bar chart, ${values.length} groups by '
              '${pickedColumn!.displayLabel}',
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yMax,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, _) {
                      final bar = values[group.x];
                      return BarTooltipItem(
                        '${bar.key}\n${_formatValue(bar.value, isMoney)}',
                        TextStyle(color: context.inTheme.surface),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions) return;
                    final spot = response?.spot;
                    if (spot == null) return;
                    final idx = spot.touchedBarGroupIndex;
                    if (idx < 0 || idx >= values.length) return;
                    context
                        .read<ReportsViewModel>()
                        .setSelectedGroup(values[idx].key);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          _formatValue(Decimal.parse(v.toString()), isMoney),
                          style: axisLabelStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: rotateLabels ? 72 : 36,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= values.length) {
                          return const SizedBox.shrink();
                        }
                        final label = values[i].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: rotateLabels
                              ? RotatedBox(
                                  quarterTurns: -1,
                                  child: Text(label, style: axisLabelStyle),
                                )
                              : Text(
                                  label,
                                  style: axisLabelStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].value.toDouble(),
                          color: accent,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(InRadii.r1),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(Decimal value, bool isMoney) {
    if (isMoney && formatter != null) {
      return formatter!.money(value, currencyId: currency);
    }
    return value.toString();
  }

  /// Build the bar series for the current column + currency. Sorts by
  /// value descending so the largest bar sits leftmost (more readable
  /// than the engine's alphabetic group order).
  List<_Bar> _bars(ReportView view, String columnId, String currency) {
    final out = <_Bar>[];
    for (final g in view.groups) {
      final v = g.numericTotals[columnId]?[currency];
      if (v == null || v == Decimal.zero) continue;
      out.add(_Bar(key: g.key, value: v));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }
}

class _Bar {
  const _Bar({required this.key, required this.value});
  final String key;
  final Decimal value;
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: InSpacing.md(context)),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.inTheme.ink2,
        ),
      ),
    );
  }
}
