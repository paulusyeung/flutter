import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/credit_dao.dart';
import 'package:admin/data/models/domain/credit.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/credits/view_models/credit_list_view_model.dart';
import 'package:admin/ui/features/credits/widgets/credit_actions.dart';
import 'package:admin/ui/features/credits/widgets/credit_list_empty_state.dart';
import 'package:admin/ui/features/credits/widgets/credit_list_tile.dart';
import 'package:admin/ui/features/credits/widgets/credit_token_search_field.dart';

class CreditListScreen extends StatelessWidget {
  const CreditListScreen({
    super.key,
    this.clientId,
    this.embedded = false,
  });

  /// When set, the list is filtered to one client.
  final String? clientId;

  /// True when this list lives inside another screen's body.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<Credit, CreditListViewModel>(
      titleKey: 'credits',
      newRoute: '/credits/new',
      newLabelKey: 'new_credit',
      emptyIcon: Icons.assignment_return_outlined,
      emptyTitleKey: 'no_credits_yet',
      wantsFormatter: true,
      embedded: embedded,
      buildVm: (services, companyId) => CreditListViewModel(
        repo: services.credits,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
        clientId: clientId,
      ),
      sortOptions: (context) => [
        SortOption(id: CreditFieldIds.number, label: context.tr('number')),
        SortOption(id: CreditFieldIds.date, label: context.tr('credit_date')),
        SortOption(id: CreditFieldIds.dueDate, label: context.tr('due_date')),
        SortOption(id: CreditFieldIds.amount, label: context.tr('amount')),
        SortOption(id: CreditFieldIds.balance, label: context.tr('balance')),
        SortOption(id: CreditFieldIds.clientId, label: context.tr('client')),
        SortOption(id: CreditFieldIds.status, label: context.tr('status')),
        SortOption(
          id: CreditFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          CreditTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => CreditListEmptyState(vm: vm),
      tileBuilder: (context, vm, credit, index, options) {
        final isUrlSelected = options.selectedId == credit.id;
        return CreditListTile(
          credit: credit,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(credit.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(credit.id)
              : isUrlSelected
              ? () => MasterDetailNavScope.requestClose(
                  context,
                  basePath: '/credits',
                )
              : () => goEntityRecord(context, vm.entityType, credit.id),
          onLongPress: () => vm.toggleSelected(credit.id),
          onSelectTap: () => vm.toggleSelected(credit.id),
          onAction: options.selecting
              ? null
              : (action) => CreditActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    credit,
                    action,
                  ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_credit',
          pluralSuccessKey: 'archived_credits',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_credit',
          pluralSuccessKey: 'restored_credits',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
