import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/utils/formatting.dart';

/// "Standing" card on the client detail screen — the page's most important
/// numbers, laid out as a 2x2 mini-KPI grid: paid_to_date, balance,
/// credit_balance, and (placeholder) payment_balance. Outstanding balance
/// tints `overdue` when positive so the user spots it without reading the
/// number.
///
/// Money formats via the screen's [Formatter] when available; falls back to
/// `—` while the formatter future is in flight or the amount is zero.
class ClientDetailStandingCard extends StatelessWidget {
  const ClientDetailStandingCard({
    super.key,
    required this.client,
    required this.formatter,
  });

  final Client client;
  final Formatter? formatter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return DashboardCardShell(
      title: context.tr('standing'),
      child: _Grid(
        cells: [
          _KpiCell(
            label: context.tr('paid_to_date'),
            amount: client.paidToDate,
            tokens: tokens,
            formatter: formatter,
            currencyId: client.currencyId,
          ),
          _KpiCell(
            label: context.tr('balance'),
            amount: client.balance,
            tokens: tokens,
            formatter: formatter,
            currencyId: client.currencyId,
            highlightWhenPositive: tokens.overdue,
          ),
          _KpiCell(
            label: context.tr('credit_balance'),
            amount: client.creditBalance,
            tokens: tokens,
            formatter: formatter,
            currencyId: client.currencyId,
          ),
          // `payment_balance` is on the server schema but not yet sync-mapped
          // into the local Client model. Render it as a placeholder ('—')
          // so the 2x2 grid is symmetric; flips to the real value the day
          // the model gains the field.
          _KpiCell(
            label: context.tr('payment_balance'),
            amount: null,
            tokens: tokens,
            formatter: formatter,
            currencyId: client.currencyId,
          ),
        ],
      ),
    );
  }
}

/// 2x2 grid with `InSpacing.md` gap between cells. Uses a `Row` of two
/// `Column`s rather than `GridView` so that the cells size to their content
/// (works correctly inside a card whose height is content-driven).
class _Grid extends StatelessWidget {
  const _Grid({required this.cells});
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
            const SizedBox(width: InSpacing.md),
            Expanded(child: cells[1]),
          ],
        ),
        const SizedBox(height: InSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cells[2]),
            const SizedBox(width: InSpacing.md),
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
    required this.tokens,
    required this.formatter,
    required this.currencyId,
    this.highlightWhenPositive,
  });

  final String label;

  /// Null means "not yet wired" — rendered as `—`.
  final Decimal? amount;
  final InTheme tokens;
  final Formatter? formatter;
  final String currencyId;
  final Color? highlightWhenPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = this.amount;
    final isZero = amount == null || amount == Decimal.zero;
    final formatted = amount == null
        ? ''
        : (formatter?.money(amount, clientCurrencyId: currencyId) ?? '');
    final value = (isZero || formatted.isEmpty) ? '—' : formatted;
    final valueColor = isZero
        ? tokens.ink3
        : (highlightWhenPositive != null && amount > Decimal.zero
              ? highlightWhenPositive!
              : tokens.ink);
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
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
