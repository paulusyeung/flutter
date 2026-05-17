import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';
import 'package:admin/ui/core/list/entity_actions_popup_button.dart';
import 'package:admin/ui/core/widgets/bank_account_name_label.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_actions.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_match_panel.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_matched_entities.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_status_pill.dart';

/// Read-only detail screen for a bank transaction. Header surfaces the
/// identity + status, then either the match panel (Unmatched/Matched) or
/// the matched-entities chip row (Converted). Actions row in the AppBar
/// dispatches edit / convert / unlink / archive / restore / delete.
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({required this.id, super.key});

  final String id;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late final GenericDetailViewModel<BankTransaction> _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = GenericDetailViewModel<BankTransaction>.bound(
      _services.bankTransactions.watch(companyId: _companyId, id: widget.id),
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityDetailScaffold<BankTransaction>(
      vm: _vm,
      emptyIcon: Icons.swap_horiz,
      emptyTitle: context.tr('transaction_not_found'),
      actionsForItem: (context, tx) => _ActionsRow(transaction: tx),
      bodyBuilder: (context, tx) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(transaction: tx),
              SizedBox(height: InSpacing.lg(context)),
              if (tx.isUnmatched || tx.isMatched)
                TransactionMatchPanel(transaction: tx),
              if (tx.isMatched || tx.isConverted) ...[
                SizedBox(height: InSpacing.lg(context)),
                _Section(
                  title: context.tr(
                    tx.isConverted ? 'converted' : 'matched',
                  ),
                  child: TransactionMatchedEntities(transaction: tx),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.transaction});
  final BankTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final tx = transaction;
    final amountText = tx.amount.toStringAsFixed(2);
    final sign = tx.isWithdrawal ? '-' : '+';
    final amountColor = tx.isWithdrawal ? tokens.overdue : tokens.paid;
    return Container(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TransactionStatusPill(statusId: tx.statusId, dotSize: 10),
              const Spacer(),
              Text(
                '$sign${tx.currencyId.isEmpty ? '' : '${tx.currencyId} '}$amountText',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tx.participantName.isNotEmpty) ...[
            Text(
              tx.participantName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (tx.description.isNotEmpty)
            Text(
              tx.description,
              style: TextStyle(color: tokens.ink2),
            ),
          const SizedBox(height: 12),
          _MetaRow(
            label: context.tr('date'),
            value: tx.date?.toIso() ?? '—',
          ),
          if (tx.bankAccountId.isNotEmpty)
            _MetaRow(
              label: context.tr('bank_account'),
              valueChild: BankAccountNameLabel(
                bankAccountId: tx.bankAccountId,
                link: true,
                style: TextStyle(color: context.inTheme.ink),
              ),
            ),
          if (tx.participant.isNotEmpty)
            _MetaRow(
              label: context.tr('participant'),
              value: tx.participant,
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    this.value = '',
    this.valueChild,
  });
  final String label;
  final String value;

  /// When provided, rendered instead of the [value] string (used for
  /// reference rows that resolve a name via a `*NameLabel`).
  final Widget? valueChild;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final valueWidget =
        valueChild ?? Text(value, style: TextStyle(color: tokens.ink));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: tokens.ink3, fontSize: 13),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: EdgeInsets.all(InSpacing.lg(context)),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(InRadii.r3),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.transaction});
  final BankTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [
        EntityActionsPopupButton<TransactionAction>(
          icon: Icons.more_vert,
          items: TransactionActions.itemsFor(
            context,
            transaction,
            (action) => TransactionActions.dispatch(
              context,
              services,
              companyId,
              transaction,
              action,
            ),
          ),
        ),
      ],
    );
  }
}
