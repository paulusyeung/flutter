import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/models/domain/client.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/clients/widgets/detail/client_detail_info_row.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/utils/formatting.dart';

/// "Standing" card on the client detail screen — paid_to_date, balance,
/// credit_balance. Money formats via the screen's [Formatter] when available;
/// falls back to `—` while the formatter future is in flight (matches the
/// pattern in `client_list_tile.dart` so the screen never blocks on it).
///
/// The Client model doesn't yet carry `payment_balance` — that field lives
/// on the server schema but isn't sync-mapped here. Until it is, this card
/// shows the 3 metrics we actually have.
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
    final balance = client.balance;
    final paid = client.paidToDate;
    final credit = client.creditBalance;

    return DashboardCardShell(
      title: context.tr('standing'),
      child: ClientDetailRowStack(
        children: [
          _row(
            context,
            label: context.tr('paid_to_date'),
            amount: paid,
            tokens: tokens,
          ),
          _row(
            context,
            label: context.tr('balance'),
            amount: balance,
            tokens: tokens,
            // Outstanding balance gets the overdue tint when positive — a
            // small cue the user can spot without scanning the number.
            valueColorWhenPositive: tokens.overdue,
          ),
          _row(
            context,
            label: context.tr('credit_balance'),
            amount: credit,
            tokens: tokens,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required Decimal amount,
    required InTheme tokens,
    Color? valueColorWhenPositive,
  }) {
    final isZero = amount == Decimal.zero;
    final formatted =
        formatter?.money(amount, clientCurrencyId: client.currencyId) ?? '';
    final value = (isZero || formatted.isEmpty) ? '—' : formatted;
    final color = isZero
        ? tokens.ink3
        : (valueColorWhenPositive != null && amount > Decimal.zero
              ? valueColorWhenPositive
              : tokens.ink);
    return ClientDetailInfoRow(
      label: label,
      value: value,
      monospace: true,
      valueColor: color,
    );
  }
}
