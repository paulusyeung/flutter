import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/expense.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/utils/formatting.dart';

/// 4-cell KPI strip at the top of the vendor detail body. Replaces the
/// legacy 2-cell `VendorDetailAggregateCard` — adds locally-derived
/// expense aggregates (total + last activity date) so the strip carries
/// the same shape as the other entities' detail KPIs.
///
/// Cells:
///   1. **balance** — `vendor.balance`
///   2. **paid_to_date** — `vendor.paidToDate`
///   3. **total_expenses** — sum of `expense.amount` for non-deleted
///      expenses linked to this vendor (computed from the local Drift
///      store via `ExpenseRepository.watchForVendor` — no network call).
///   4. **last_expense_date** — most recent `expense.date` from the same
///      set; `—` when no expenses.
///
/// Layout switches at 1100 px (mirrors `ExpenseDetailKpiStrip`).
class VendorDetailKpiStrip extends StatelessWidget {
  const VendorDetailKpiStrip({
    super.key,
    required this.vendor,
    required this.companyId,
    this.formatter,
  });

  final Vendor vendor;
  final String companyId;
  final Formatter? formatter;

  static const double _wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<List<Expense>>(
      stream: services.expenses.watchForVendor(
        companyId: companyId,
        vendorId: vendor.id,
      ),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? const <Expense>[];
        return _Strip(
          vendor: vendor,
          expenses: expenses,
          formatter: formatter,
        );
      },
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({
    required this.vendor,
    required this.expenses,
    required this.formatter,
  });

  final Vendor vendor;
  final List<Expense> expenses;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);

    // Only sum expenses in the vendor's currency. Summing across mixed
    // currencies would produce a meaningless total — Decimal addition is
    // currency-blind. The "Last expense" cell below can stay currency-
    // agnostic since a date is currency-neutral.
    final vendorCurrency = vendor.currencyId;
    final totalExpenses = expenses
        .where((e) => e.currencyId == vendorCurrency)
        .fold<Decimal>(Decimal.zero, (acc, e) => acc + e.amount);

    Date? mostRecent;
    for (final e in expenses) {
      final d = e.date;
      if (d == null) continue;
      if (mostRecent == null || d.compareTo(mostRecent) > 0) mostRecent = d;
    }

    final lastDateText = mostRecent == null
        ? '—'
        : (formatter == null
            ? mostRecent.toIso()
            : formatter!.date(mostRecent.toIso()));

    final cells = <Widget>[
      _KpiCell(
        label: context.tr('balance'),
        amount: vendor.balance,
        currencyId: vendor.currencyId,
        tokens: tokens,
        theme: theme,
        formatter: formatter,
        highlightWhenPositive: tokens.overdue,
      ),
      _KpiCell(
        label: context.tr('paid_to_date'),
        amount: vendor.paidToDate,
        currencyId: vendor.currencyId,
        tokens: tokens,
        theme: theme,
        formatter: formatter,
      ),
      _KpiCell(
        label: context.tr('total_expenses'),
        amount: totalExpenses,
        currencyId: vendor.currencyId,
        tokens: tokens,
        theme: theme,
        formatter: formatter,
      ),
      _TextKpiCell(
        label: context.tr('last_expense_date'),
        value: lastDateText,
        tokens: tokens,
        theme: theme,
      ),
    ];

    return DashboardCardShell(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.lg(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= VendorDetailKpiStrip._wideBreakpoint) {
            return _HorizontalStrip(cells: cells, tokens: tokens);
          }
          return _Grid2x2(cells: cells);
        },
      ),
    );
  }
}

class _HorizontalStrip extends StatelessWidget {
  const _HorizontalStrip({required this.cells, required this.tokens});
  final List<Widget> cells;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: InSpacing.lg(context)),
            child: SizedBox(
              width: 1,
              height: 36,
              child: ColoredBox(color: tokens.border),
            ),
          ),
        );
      }
      children.add(Expanded(child: cells[i]));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class _Grid2x2 extends StatelessWidget {
  const _Grid2x2({required this.cells});
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cells[0]),
            SizedBox(width: InSpacing.md(context)),
            Expanded(child: cells[1]),
          ],
        ),
        SizedBox(height: InSpacing.md(context)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cells[2]),
            SizedBox(width: InSpacing.md(context)),
            Expanded(child: cells[3]),
          ],
        ),
      ],
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.label,
    required this.amount,
    required this.currencyId,
    required this.tokens,
    required this.theme,
    required this.formatter,
    this.highlightWhenPositive,
  });

  final String label;
  final Decimal amount;
  final String currencyId;
  final InTheme tokens;
  final ThemeData theme;
  final Formatter? formatter;
  final Color? highlightWhenPositive;

  @override
  Widget build(BuildContext context) {
    final isZero = amount == Decimal.zero;
    final formatted =
        formatter?.money(amount, clientCurrencyId: currencyId) ?? '';
    final value = (isZero || formatted.isEmpty) ? '—' : formatted;
    final valueColor = isZero
        ? tokens.ink3
        : (highlightWhenPositive != null && amount > Decimal.zero
            ? highlightWhenPositive!
            : tokens.ink);
    return _Cell(
      label: label,
      tokens: tokens,
      theme: theme,
      value: Text(
        value,
        style: theme.textTheme.titleLarge?.copyWith(
          color: valueColor,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TextKpiCell extends StatelessWidget {
  const _TextKpiCell({
    required this.label,
    required this.value,
    required this.tokens,
    required this.theme,
  });

  final String label;
  final String value;
  final InTheme tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      label: label,
      tokens: tokens,
      theme: theme,
      value: Text(
        value,
        style: theme.textTheme.titleLarge?.copyWith(
          color: value == '—' ? tokens.ink3 : tokens.ink,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    required this.tokens,
    required this.theme,
  });

  final String label;
  final Widget value;
  final InTheme tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.ink3,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}
