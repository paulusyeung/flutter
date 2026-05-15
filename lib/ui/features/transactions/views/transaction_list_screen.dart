import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/bank_transaction_dao.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/transactions/view_models/transaction_list_view_model.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_actions.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_list_empty_state.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_list_tile.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_token_search_field.dart';

/// Search keys exported for the settings search catalog (Settings →
/// search). The transactions screen lives outside `/settings`, so these
/// only surface if the user types one of these terms in the global
/// search and we want to disambiguate.
const kTransactionListSearchKeys = <String>[
  'transactions',
  'transaction',
  'deposit',
  'withdrawal',
  'matched',
  'unmatched',
  'converted',
];

/// `/transactions` — top-level workspace list of every bank transaction.
/// The same widget powers the embedded list inside
/// `BankAccountDetailScreen`; pass [bankAccountId] to scope to one
/// integration, and the scaffold hides its AppBar + new CTA when in
/// embedded mode.
class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key, this.bankAccountId});

  /// When set, the list is filtered to a single bank integration. The
  /// embedded list inside `BankAccountDetailScreen` passes its account
  /// id here so users see only that account's transactions.
  final String? bankAccountId;

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<BankTransaction, TransactionListViewModel>(
      titleKey: 'transactions',
      newRoute: '/transactions/new',
      newLabelKey: 'new_transaction',
      emptyIcon: Icons.swap_horiz,
      emptyTitleKey: 'no_transactions_yet',
      wantsFormatter: true,
      buildVm: (services, companyId) => TransactionListViewModel(
        repo: services.bankTransactions,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
        bankAccountId: bankAccountId,
      ),
      sortOptions: (context) => [
        SortOption(
          id: BankTransactionFieldIds.date,
          label: context.tr('date'),
        ),
        SortOption(
          id: BankTransactionFieldIds.amount,
          label: context.tr('amount'),
        ),
        SortOption(
          id: BankTransactionFieldIds.participantName,
          label: context.tr('participant_name'),
        ),
        SortOption(
          id: BankTransactionFieldIds.description,
          label: context.tr('description'),
        ),
        SortOption(
          id: BankTransactionFieldIds.statusId,
          label: context.tr('status'),
        ),
        SortOption(
          id: BankTransactionFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          TransactionTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => TransactionListEmptyState(vm: vm),
      tileBuilder: (context, vm, transaction, index, options) =>
          TransactionListTile(
            transaction: transaction,
            columns: options.wide ? vm.columns : const [],
            wide: options.wide,
            isLast: options.isLast,
            selecting: options.selecting,
            selected: vm.isSelected(transaction.id),
            onTap: options.selecting
                ? () => vm.toggleSelected(transaction.id)
                : () => context.go('/transactions/${transaction.id}'),
            onLongPress: () => vm.toggleSelected(transaction.id),
            onSelectTap: () => vm.toggleSelected(transaction.id),
            onAction: options.selecting
                ? null
                : (action) => TransactionActions.dispatch(
                      context,
                      context.read<Services>(),
                      vm.companyId,
                      transaction,
                      action,
                    ),
          ),
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_transaction',
          pluralSuccessKey: 'archived_transactions',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_transaction',
          pluralSuccessKey: 'restored_transactions',
          nothingKey: 'nothing_to_restore',
        ),
        EntityListBulkAction(
          actionId: 'convert_matched',
          icon: Icons.auto_fix_high_outlined,
          tooltipKey: 'convert',
          singleSuccessKey: 'converted_transaction',
          pluralSuccessKey: 'converted_transactions',
          nothingKey: 'nothing_to_convert',
        ),
        EntityListBulkAction(
          actionId: 'unlink',
          icon: Icons.link_off,
          tooltipKey: 'unlink',
          singleSuccessKey: 'unlinked_transaction',
          pluralSuccessKey: 'unlinked_transactions',
          nothingKey: 'nothing_to_unlink',
        ),
      ],
    );
  }
}
