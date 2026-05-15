import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/report_payload.dart';
import 'package:admin/data/models/domain/report_preview.dart';
import 'package:admin/data/repositories/reports_repository.dart';
import 'package:admin/domain/reports/report_column_types.dart';
import 'package:admin/domain/reports/report_engine.dart';
import 'package:admin/domain/reports/report_registry.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/reports/view_models/reports_view_model.dart';
import 'package:admin/utils/formatting.dart';

/// Sits inside the [ReportsScreen]'s Scaffold body. Owns the toolbar, the
/// state branching (initial / loading / ready / error), and the responsive
/// layout switch between the wide/medium table and the narrow card list.
class ReportsBody extends StatelessWidget {
  const ReportsBody({required this.formatter, super.key});

  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    // context.watch on each child that actually needs to rebuild — wrapping
    // a Provider-watching subtree in ListenableBuilder double-subscribes.
    return Column(
      children: [
        const _ReportsToolbar(),
        const Divider(height: 1),
        Expanded(child: _ReportsContent(formatter: formatter)),
      ],
    );
  }
}

// ─── Toolbar ──────────────────────────────────────────────────────────────

class _ReportsToolbar extends StatelessWidget {
  const _ReportsToolbar();

  @override
  Widget build(BuildContext context) {
    // Watch so error-state / run-state changes redraw the Keep-waiting and
    // Run controls. Leaf buttons reread `vm.*` after each toolbar rebuild.
    final vm = context.watch<ReportsViewModel>();
    final tokens = context.inTheme;
    return Container(
      color: tokens.surface,
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.sm,
      ),
      // Horizontal scroll instead of Wrap — wrapping into two rows looks
      // accidental when controls grow (localized labels, new buttons in
      // later phases). Users scroll past overflow with the trackpad or
      // arrow keys.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ReportPickerButton(vm: vm),
            SizedBox(width: InSpacing.md(context)),
            _DateRangeButton(vm: vm),
            if (vm.definition.supportsPreview) ...[
              SizedBox(width: InSpacing.md(context)),
              _RunButton(vm: vm),
            ],
            if (vm.run.error != null &&
                vm.run.error!.kind == ReportErrorKind.timeout) ...[
              SizedBox(width: InSpacing.md(context)),
              FilledButton.tonal(
                onPressed: vm.keepWaiting,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 44),
                ),
                child: Text(context.tr('keep_waiting')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportPickerButton extends StatelessWidget {
  const _ReportPickerButton({required this.vm});

  final ReportsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final session = context.read<Services>().auth.session.value;
    final canList = kReportDefinitions.where((def) {
      final company = session?.currentCompany;
      if (company == null) return true;
      return company.can(def.requiredPermission);
    }).toList();

    return DropdownButton<String>(
      value: vm.reportIdentifier,
      underline: const SizedBox.shrink(),
      onChanged: (v) {
        if (v == null) return;
        vm.setReport(v);
      },
      items: [
        for (final def in canList)
          DropdownMenuItem<String>(
            value: def.identifier,
            child: Text(context.tr(def.labelKey)),
          ),
      ],
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({required this.vm});

  final ReportsViewModel vm;

  static const _allPresets = ReportDatePreset.values;

  @override
  Widget build(BuildContext context) {
    final current = vm.payload.datePreset;
    final label = context.tr(_labelKey(current));
    return MenuAnchor(
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.calendar_today_outlined, size: 16),
        label: Text(label),
      ),
      menuChildren: [
        // Custom date range deferred — Phase 1 ships preset-only. When
        // custom dates land, drop the filter below and wire a
        // `showDateRangePicker` (or the dashboard's `DateRangePickerButton`
        // popover shape) to the `custom` menu item. `vm.payload.datePreset`
        // can still arrive as `custom` via persistence; the label switch
        // below handles that without crashing.
        for (final p in _allPresets)
          if (p != ReportDatePreset.custom)
            MenuItemButton(
              onPressed: () => vm.setPayload(
                vm.payload.copyWith(datePreset: p),
              ),
              child: Text(context.tr(_labelKey(p))),
            ),
      ],
    );
  }

  String _labelKey(ReportDatePreset p) {
    switch (p) {
      case ReportDatePreset.allTime:
        return 'all_time';
      case ReportDatePreset.last7:
        return 'last_7_days';
      case ReportDatePreset.last30:
        return 'last_30_days';
      case ReportDatePreset.last90:
        return 'last_90_days';
      case ReportDatePreset.last365:
        return 'last_365_days';
      case ReportDatePreset.thisMonth:
        return 'this_month';
      case ReportDatePreset.lastMonth:
        return 'last_month';
      case ReportDatePreset.thisQuarter:
        return 'this_quarter';
      case ReportDatePreset.lastQuarter:
        return 'last_quarter';
      case ReportDatePreset.thisYear:
        return 'this_year';
      case ReportDatePreset.lastYear:
        return 'last_year';
      case ReportDatePreset.custom:
        return 'custom';
    }
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.vm});

  final ReportsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final isLoading = vm.run.isLoading;
    if (isLoading) {
      return FilledButton.icon(
        onPressed: vm.cancelRun,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(context.tr('cancel')),
      );
    }
    final label = vm.isParamDirty
        ? context.tr('run_to_refresh')
        : context.tr('run_report');
    return Tooltip(
      message: label,
      child: FilledButton.icon(
        onPressed: vm.runReport,
        icon: const Icon(Icons.play_arrow, size: 16),
        label: Text(label),
      ),
    );
  }
}

// ─── Body content (state branching) ───────────────────────────────────────

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.formatter});

  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();
    final run = vm.run;

    // Loading without prior content → skeleton-ish shell.
    if (run.isLoading && run.preview == null) {
      return const _LoadingShell();
    }
    // Error without prior content → full error view.
    if (run.status == ReportRunStatus.error && run.preview == null) {
      return _ErrorState(error: run.error!, onRetry: vm.runReport);
    }
    // No preview yet → Initial empty state.
    if (run.preview == null) {
      return _InitialState(
        reportLabel: context.tr(vm.definition.labelKey),
      );
    }
    // Ready (possibly with overlaid error banner).
    return _ReportTableArea(formatter: formatter);
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState({required this.reportLabel});

  final String reportLabel;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ReportsViewModel>();
    return EmptyState(
      icon: Icons.bar_chart_outlined,
      title: context.tr('reports'),
      subtitle: context.tr('run_report_to_load_hint', {'report': reportLabel}),
      action: vm.definition.supportsPreview
          ? FilledButton.icon(
              onPressed: vm.runReport,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text(context.tr('run_report')),
            )
          : null,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final ReportError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    String message;
    switch (error.kind) {
      case ReportErrorKind.timeout:
        message = l10n('report_timed_out');
      case ReportErrorKind.planRequired:
        message = l10n('upgrade_to_view_reports');
      case ReportErrorKind.unauthorized:
        message = l10n('access_denied');
      case ReportErrorKind.validation:
        message = error.fieldErrors?.values
                .expand((v) => v)
                .where((s) => s.isNotEmpty)
                .join('\n') ??
            l10n('an_error_occurred');
      case ReportErrorKind.network:
        message = l10n('no_internet_connection');
      case ReportErrorKind.passwordRequired:
        message = l10n('password_required');
      case ReportErrorKind.serverError:
      case ReportErrorKind.cancelled:
      case ReportErrorKind.unknown:
        message = error.message ?? l10n('an_error_occurred');
    }
    return ErrorView(message: message, onRetry: onRetry);
  }
}

// ─── Table area (post-Run) ────────────────────────────────────────────────

class _ReportTableArea extends StatelessWidget {
  const _ReportTableArea({required this.formatter});

  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();
    final view = vm.buildView(
      companyCurrencyId: formatter?.settings.currencyId,
    );
    if (view.rows.isEmpty && view.groups.isEmpty) {
      return Column(
        children: [
          if (vm.selectedGroup != null) _DrillBreadcrumb(vm: vm),
          Expanded(
            child: EmptyState(
              icon: Icons.search_off,
              title: context.tr('no_results'),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (vm.selectedGroup != null) _DrillBreadcrumb(vm: vm),
        // Totals card renders whenever there's any row count to summarize —
        // money totals are nice-to-have, the row count is the floor (e.g.
        // Activity / Task reports have no money columns but should still
        // show "47 rows" in the totals card).
        if (view.rowCountByCurrency.isNotEmpty || view.totalRowCount > 0)
          _TotalsCard(view: view, formatter: formatter),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tier = Breakpoints.reportTier(constraints.maxWidth);
              if (tier == ReportLayoutTier.narrow) {
                return _ReportCardList(view: view, formatter: formatter);
              }
              return _ReportDataTable(
                view: view,
                formatter: formatter,
                pinFirstColumn: tier == ReportLayoutTier.medium,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DrillBreadcrumb extends StatelessWidget {
  const _DrillBreadcrumb({required this.vm});

  final ReportsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      color: tokens.surface,
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.sm,
      ),
      child: Row(
        children: [
          InputChip(
            avatar: const Icon(Icons.filter_alt_outlined, size: 16),
            label: Text(vm.selectedGroup ?? ''),
            // Tap anywhere on the chip — body or delete icon — clears the
            // drill. The breadcrumb is the only exit affordance for the
            // drilled view, so make the whole control feel like a button.
            onPressed: () => vm.setSelectedGroup(null),
            onDeleted: () => vm.setSelectedGroup(null),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.view, required this.formatter});

  final ReportView view;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(InSpacing.lg(context)),
      padding: EdgeInsets.all(InSpacing.lg(context)),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
        color: tokens.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in view.rowCountByCurrency.entries)
            Padding(
              padding: EdgeInsets.symmetric(vertical: InSpacing.sm / 2),
              child: Text(
                _line(context, entry.key, entry.value),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }

  String _line(BuildContext context, String currencyId, int count) {
    final tr = context.tr;
    final currency = formatter?.currencies[currencyId];
    final label = currencyId.isEmpty
        ? tr('total')
        : (currency?.code.isNotEmpty == true ? currency!.code : currencyId);
    return '$label · $count ${count == 1 ? tr('row') : tr('rows')}';
  }
}

// ─── The table itself ────────────────────────────────────────────────────

class _ReportDataTable extends StatelessWidget {
  const _ReportDataTable({
    required this.view,
    required this.formatter,
    required this.pinFirstColumn,
  });

  final ReportView view;
  final Formatter? formatter;
  final bool pinFirstColumn;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _tableMinWidth(context),
        child: ListView.builder(
          shrinkWrap: false,
          itemCount: _bodyRowCount() + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _HeaderRow(view: view);
            final i = index - 1;
            if (view.groups.isNotEmpty) {
              return _GroupRow(
                view: view,
                group: view.groups[i],
                formatter: formatter,
                background:
                    i.isEven ? tokens.surface : tokens.surfaceAlt,
              );
            }
            return _DataRow(
              view: view,
              row: view.rows[i],
              formatter: formatter,
              background: i.isEven ? tokens.surface : tokens.surfaceAlt,
            );
          },
        ),
      ),
    );
  }

  int _bodyRowCount() =>
      view.groups.isNotEmpty ? view.groups.length : view.rows.length;

  double _tableMinWidth(BuildContext context) {
    // 160 px per column gives a comfortable default; the horizontal scroll
    // view handles overflow on narrower viewports.
    final cols = view.visibleColumns.length;
    return cols * 160.0;
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.view});

  final ReportView view;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ReportsViewModel>();
    final tokens = context.inTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.sm,
      ),
      child: Row(
        children: [
          for (final col in view.visibleColumns)
            Expanded(
              child: Semantics(
                button: true,
                label: () {
                  if (vm.sortField != col.identifier) {
                    return 'Sort by ${col.displayLabel}';
                  }
                  return 'Sort by ${col.displayLabel}. '
                      'Currently ${vm.sortAscending ? 'ascending' : 'descending'}. '
                      'Double-tap to toggle.';
                }(),
                child: InkWell(
                  onTap: () => vm.toggleSort(col.identifier),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: InSpacing.sm),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            col.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        if (vm.sortField == col.identifier)
                        Icon(
                          vm.sortAscending
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 18,
                          color: tokens.ink2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.view,
    required this.row,
    required this.formatter,
    required this.background,
  });

  final ReportView view;
  final ReportRow row;
  final Formatter? formatter;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final wire = row.entityWire;
    final id = row.entityId;
    final handlers = wire == null
        ? null
        : resolveDrillTarget(services.entityRegistry, wire);
    final canDrill = handlers != null && id != null && id.isNotEmpty;
    return Material(
      color: background,
      child: InkWell(
        onTap: canDrill
            ? () => context.go('${handlers.routePath}/$id')
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: InSpacing.lg(context),
            vertical: InSpacing.sm,
          ),
          child: Row(
            children: [
              for (var i = 0; i < view.visibleColumns.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: InSpacing.sm),
                    child: _CellText(
                      cell: _cellByColumn(view, row, i),
                      column: view.visibleColumns[i],
                      formatter: formatter,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.view,
    required this.group,
    required this.formatter,
    required this.background,
  });

  final ReportView view;
  final GroupTotals group;
  final Formatter? formatter;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ReportsViewModel>();
    return Semantics(
      button: true,
      label: 'Group ${group.key}, ${group.count} '
          '${group.count == 1 ? "row" : "rows"}. Double-tap to drill in.',
      child: Material(
        color: background,
        child: InkWell(
          onTap: () => vm.setSelectedGroup(group.key),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: InSpacing.lg(context),
              vertical: InSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: InSpacing.sm),
                    child: Text(
                      '${group.key} (${group.count})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                for (var i = 1; i < view.visibleColumns.length; i++)
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: InSpacing.sm),
                      child: _GroupTotalText(
                        column: view.visibleColumns[i],
                        group: group,
                        formatter: formatter,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTotalText extends StatelessWidget {
  const _GroupTotalText({
    required this.column,
    required this.group,
    required this.formatter,
  });

  final ReportColumn column;
  final GroupTotals group;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    if (!isAggregatable(column.type)) return const Text('');
    final perCurrency = group.numericTotals[column.identifier];
    if (perCurrency == null || perCurrency.isEmpty) return const Text('');
    // Render the dominant currency entry; multi-currency groups show "—"
    // in the cell and rely on the totals card for the full breakdown.
    if (perCurrency.length == 1) {
      final e = perCurrency.entries.first;
      final value = e.value;
      if (column.type == ReportColumnType.money) {
        // Formatter is still loading on first paint — render the
        // placeholder so the column doesn't briefly flash a raw Decimal.
        final f = formatter;
        if (f == null) return const Text('—');
        return Text(
          f.money(value, currencyId: e.key.isEmpty ? null : e.key),
        );
      }
      return Text('$value');
    }
    return const Text('—');
  }
}

class _CellText extends StatelessWidget {
  const _CellText({
    required this.cell,
    required this.column,
    required this.formatter,
  });

  final ReportCell cell;
  final ReportColumn column;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final text = cell.displayValue ?? _fallback(context);
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Server values aren't always pre-formatted (typed numbers, some
  // entity references); use the formatter for money and fall back to a
  // plain `toString` otherwise.
  String _fallback(BuildContext context) {
    if (cell is ReportNumberCell) {
      final c = cell as ReportNumberCell;
      if (c.value == null) return '';
      if (column.type == ReportColumnType.money) {
        // CLAUDE.md convention: money columns render `—` while the
        // formatter is loading, never the raw Decimal.toString().
        final f = formatter;
        if (f == null) return '—';
        return f.money(
          c.value!,
          currencyId:
              c.currencyId == null || c.currencyId!.isEmpty ? null : c.currencyId,
        );
      }
      return c.value!.toString();
    }
    if (cell is ReportDateCell) {
      return (cell as ReportDateCell).value?.toIso() ?? '';
    }
    if (cell is ReportDateTimeCell) {
      return (cell as ReportDateTimeCell).value?.toIso8601String() ?? '';
    }
    if (cell is ReportAgeCell) {
      final c = cell as ReportAgeCell;
      if (c.isPaid) return context.tr('paid');
      return '${c.days ?? ''}';
    }
    if (cell is ReportBoolCell) {
      final c = cell as ReportBoolCell;
      if (c.value == null) return '';
      return c.value! ? context.tr('yes') : context.tr('no');
    }
    if (cell is ReportDurationCell) {
      return '${(cell as ReportDurationCell).seconds ?? 0}s';
    }
    if (cell is ReportStringCell) {
      return (cell as ReportStringCell).value ?? '';
    }
    return cell.displayValue ?? '';
  }
}

// Rows still carry cells in the original server order — the engine
// reorders `visibleColumns` (group column to index 0 when grouped) but
// not the cells themselves. `cellIndexByColumn` maps the visible column's
// identifier back to its original row-cell index, so drill-down rendering
// (group at index 0 in visibleColumns; original cell elsewhere in
// row.cells) lands on the right cell.
ReportCell _cellByColumn(ReportView view, ReportRow row, int visibleIdx) {
  final colId = view.visibleColumns[visibleIdx].identifier;
  final origIdx = view.cellIndexByColumn[colId];
  if (origIdx == null || origIdx >= row.cells.length) {
    // Defensive: visible column we couldn't map back. Render empty.
    return const ReportStringCell(value: '');
  }
  return row.cells[origIdx];
}

// ─── Narrow-viewport card list ────────────────────────────────────────────

class _ReportCardList extends StatelessWidget {
  const _ReportCardList({required this.view, required this.formatter});

  final ReportView view;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    if (view.groups.isNotEmpty) {
      return ListView.separated(
        itemCount: view.groups.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final g = view.groups[i];
          return ListTile(
            title: Text(g.key),
            subtitle: Text('${g.count} ${context.tr('rows')}'),
            onTap: () => context.read<ReportsViewModel>().setSelectedGroup(g.key),
          );
        },
      );
    }
    return ListView.separated(
      itemCount: view.rows.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final row = view.rows[i];
        final services = context.read<Services>();
        final wire = row.entityWire;
        final id = row.entityId;
        final handlers = wire == null
            ? null
            : resolveDrillTarget(services.entityRegistry, wire);
        final canDrill =
            handlers != null && id != null && id.isNotEmpty;
        return ListTile(
          onTap: canDrill
              ? () => context.go('${handlers.routePath}/$id')
              : null,
          title: Text(
            row.cells.first.displayValue ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var k = 1; k < view.visibleColumns.length && k < 4; k++)
                Text(
                  '${view.visibleColumns[k].displayLabel}: '
                  '${row.cells.length > k ? (row.cells[k].displayValue ?? '') : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
    );
  }
}
