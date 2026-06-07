import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/value/date.dart';
import 'package:admin/utils/formatting.dart';

/// Shared building blocks for billing-doc detail headers (Invoice / Quote /
/// Credit). The headers themselves stay per-entity (lock banner, status pill,
/// and field set differ), but the money-metric strip and the dates/overdue
/// caption are identical in shape — unified here so the three read as one
/// design and format money/dates through the same path.

/// One money metric in a [BillingDocKpiStrip].
class BillingMetric {
  const BillingMetric({
    required this.label,
    required this.amount,
    this.highlightWhenPositive = false,
  });

  final String label;

  /// Null renders as `—`; zero also renders as `—` (the detail-screen KPI
  /// convention shared with the Client/Payment strips).
  final Decimal? amount;

  /// Paint the value in `overdue` red when the amount is positive — used for a
  /// past-due balance.
  final bool highlightWhenPositive;
}

/// Money-metric strip for a billing-doc detail header. Mirrors the
/// Client/Payment detail KPI strips: a divided horizontal row when the cells
/// fit, wrapping two-up on a narrow detail panel. Money formats via
/// [formatter] + [currencyId]; null/zero renders as `—`.
class BillingDocKpiStrip extends StatelessWidget {
  const BillingDocKpiStrip({
    super.key,
    required this.metrics,
    this.formatter,
    this.currencyId,
  });

  final List<BillingMetric> metrics;
  final Formatter? formatter;
  final String? currencyId;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cells = [for (final m in metrics) _cell(m, tokens)];
        final perCell = constraints.maxWidth / cells.length;
        if (cells.length <= 1 || perCell >= 130) {
          final children = <Widget>[];
          for (var i = 0; i < cells.length; i++) {
            if (i > 0) {
              children.add(
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: InSpacing.lg(context),
                  ),
                  child: SizedBox(
                    width: 1,
                    height: 32,
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
        final gap = InSpacing.md(context);
        final cellW = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: InSpacing.md(context),
          children: [
            for (final cell in cells) SizedBox(width: cellW, child: cell),
          ],
        );
      },
    );
  }

  Widget _cell(BillingMetric m, InTheme tokens) {
    final amount = m.amount;
    final isZero = amount == null || amount == Decimal.zero;
    final formatted = amount == null
        ? ''
        : (formatter?.money(amount, clientCurrencyId: currencyId) ?? '');
    final value = (isZero || formatted.isEmpty) ? '—' : formatted;
    final color = isZero
        ? tokens.ink3
        : (m.highlightWhenPositive && amount > Decimal.zero
              ? tokens.overdue
              : tokens.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: tokens.ink3,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: moneyTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Dates + overdue/expired caption shown under the client name in a billing-doc
/// header. Renders `Issued <date> · <secondaryLabel> <date>`, with a red
/// `<overduePrefix> · Nd` suffix when [overdueDays] is set (the caller passes
/// it only when the doc is actually past-due / expired). Formats through
/// [formatter]; falls back to ISO when it hasn't loaded yet.
class BillingDatesCaption extends StatelessWidget {
  const BillingDatesCaption({
    super.key,
    this.formatter,
    required this.issuedLabel,
    required this.issued,
    required this.secondaryLabel,
    required this.secondary,
    this.overduePrefix,
    this.overdueDays,
  });

  final Formatter? formatter;
  final String issuedLabel;
  final Date? issued;
  final String secondaryLabel;
  final Date? secondary;

  /// Localized "Overdue" / "Expired"; paired with [overdueDays].
  final String? overduePrefix;

  /// Whole days past the secondary date. When non-null and positive, the red
  /// `<prefix> · Nd` chip renders.
  final int? overdueDays;

  String _fmt(Date d) => formatter?.date(d.toIso()) ?? d.toIso();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final past = (overdueDays ?? 0) > 0;
    final muted = TextStyle(fontSize: 12.5, color: tokens.ink3);
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (issued != null) Text('$issuedLabel ${_fmt(issued!)}', style: muted),
        if (secondary != null)
          Text(
            '$secondaryLabel ${_fmt(secondary!)}',
            style: past
                ? muted.copyWith(
                    color: tokens.overdue,
                    fontWeight: FontWeight.w600,
                  )
                : muted,
          ),
        if (past && overduePrefix != null)
          Text(
            '$overduePrefix · ${overdueDays}d',
            style: TextStyle(
              fontSize: 12.5,
              color: tokens.overdue,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
