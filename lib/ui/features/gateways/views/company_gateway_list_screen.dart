import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/company_gateway_dao.dart';
import 'package:admin/data/models/domain/company_gateway.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/gateways/view_models/company_gateway_list_view_model.dart';
import 'package:admin/ui/features/gateways/widgets/company_gateway_actions.dart';
import 'package:admin/ui/features/gateways/widgets/company_gateway_list_empty_state.dart';
import 'package:admin/ui/features/gateways/widgets/company_gateway_list_tile.dart';
import 'package:admin/ui/features/gateways/widgets/company_gateway_token_search_field.dart';
import 'package:admin/ui/features/gateways/widgets/reorder_gateways_sheet.dart';

/// Labels surfaced on the list screen for the in-app settings search index.
const kCompanyGatewayListSearchKeys = <String>[
  'label',
  'gateway_type',
  'last_updated',
  'add_gateway',
];

/// Company gateways list screen — pure config + per-entity widgets. Mirrors
/// `ProjectListScreen` / `ProductListScreen`; the screen-level chrome lives
/// in `EntityListScreenScaffold`.
class CompanyGatewayListScreen extends StatelessWidget {
  const CompanyGatewayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<
      CompanyGateway,
      CompanyGatewayListViewModel
    >(
      titleKey: 'company_gateways',
      newRoute: '/settings/company_gateways/new',
      newLabelKey: 'new_company_gateway',
      emptyIcon: Icons.account_balance_wallet_outlined,
      emptyTitleKey: 'no_company_gateways_yet',
      buildVm: (services, companyId) => CompanyGatewayListViewModel(
        repo: services.companyGateways,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
      ),
      sortOptions: (context) => [
        SortOption(
          id: CompanyGatewayFieldIds.label,
          label: context.tr('label'),
        ),
        SortOption(
          id: CompanyGatewayFieldIds.gatewayKey,
          label: context.tr('gateway_type'),
        ),
        SortOption(
          id: CompanyGatewayFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          CompanyGatewayTokenSearchField(vm: vm, wide: wide),
      extraAppBarActions: (context, vm, wide) => [
        if (vm.items.length > 1)
          IconButton(
            icon: const Icon(Icons.reorder),
            tooltip: context.tr('reorder'),
            onPressed: () =>
                openReorderGatewaysSheet(context, gateways: vm.items),
          ),
      ],
      emptyStateBuilder: (context, vm) => CompanyGatewayListEmptyState(vm: vm),
      tileBuilder: (context, vm, gateway, index, options) =>
          CompanyGatewayListTile(
            gateway: gateway,
            columns: options.wide ? vm.columns : const [],
            wide: options.wide,
            isLast: options.isLast,
            selecting: options.selecting,
            selected: vm.isSelected(gateway.id),
            onTap: options.selecting
                ? () => vm.toggleSelected(gateway.id)
                : () => context.go('/settings/company_gateways/${gateway.id}'),
            onLongPress: () => vm.toggleSelected(gateway.id),
            onSelectTap: () => vm.toggleSelected(gateway.id),
            onAction: options.selecting
                ? null
                : (action) => CompanyGatewayActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    gateway,
                    action,
                  ),
          ),
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_company_gateway',
          pluralSuccessKey: 'archived_company_gateways',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_company_gateway',
          pluralSuccessKey: 'restored_company_gateways',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
