import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/dao/quote_dao.dart';
import 'package:admin/data/models/domain/quote.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/quotes/view_models/quote_list_view_model.dart';
import 'package:admin/ui/features/quotes/widgets/quote_actions.dart';
import 'package:admin/ui/features/quotes/widgets/quote_list_empty_state.dart';
import 'package:admin/ui/features/quotes/widgets/quote_list_tile.dart';
import 'package:admin/ui/features/quotes/widgets/quote_token_search_field.dart';

class QuoteListScreen extends StatelessWidget {
  const QuoteListScreen({
    super.key,
    this.clientId,
    this.embedded = false,
  });

  /// When set, the list is filtered to one client.
  final String? clientId;

  /// True when this list lives inside another screen's body (e.g. the
  /// quotes tab on `ClientDetailScreen`).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<Quote, QuoteListViewModel>(
      titleKey: 'quotes',
      newRoute: '/quotes/new',
      newLabelKey: 'new_quote',
      emptyIcon: Icons.request_quote_outlined,
      emptyTitleKey: 'no_quotes_yet',
      wantsFormatter: true,
      embedded: embedded,
      buildVm: (services, companyId) => QuoteListViewModel(
        repo: services.quotes,
        companyId: companyId,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        savedViews: services.savedViews,
        clientId: clientId,
      ),
      sortOptions: (context) => [
        SortOption(id: QuoteFieldIds.number, label: context.tr('number')),
        SortOption(id: QuoteFieldIds.date, label: context.tr('quote_date')),
        SortOption(id: QuoteFieldIds.dueDate, label: context.tr('valid_until')),
        SortOption(id: QuoteFieldIds.amount, label: context.tr('amount')),
        SortOption(id: QuoteFieldIds.clientId, label: context.tr('client')),
        SortOption(id: QuoteFieldIds.status, label: context.tr('status')),
        SortOption(
          id: QuoteFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          QuoteTokenSearchField(vm: vm, wide: wide),
      emptyStateBuilder: (context, vm) => QuoteListEmptyState(vm: vm),
      tileBuilder: (context, vm, quote, index, options) {
        final isUrlSelected = options.selectedId == quote.id;
        return QuoteListTile(
          quote: quote,
          columns: options.wide ? vm.columns : const [],
          wide: options.wide,
          isLast: options.isLast,
          selecting: options.selecting,
          selected: vm.isSelected(quote.id) || isUrlSelected,
          urlSelected: isUrlSelected,
          onTap: options.selecting
              ? () => vm.toggleSelected(quote.id)
              : isUrlSelected
              ? () => MasterDetailNavScope.requestClose(
                  context,
                  basePath: '/quotes',
                )
              : () => goEntityRecord(context, vm.entityType, quote.id),
          onLongPress: () => vm.toggleSelected(quote.id),
          onSelectTap: () => vm.toggleSelected(quote.id),
          onAction: options.selecting
              ? null
              : (action) => QuoteActions.dispatch(
                    context,
                    context.read<Services>(),
                    vm.companyId,
                    quote,
                    action,
                  ),
        );
      },
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_quote',
          pluralSuccessKey: 'archived_quotes',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_quote',
          pluralSuccessKey: 'restored_quotes',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }
}
