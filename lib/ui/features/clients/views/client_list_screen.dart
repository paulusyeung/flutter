import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_list_screen_scaffold.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/client_list_column_headers.dart';
import 'package:admin/ui/features/clients/widgets/client_list_empty_state.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';
import 'package:admin/ui/features/clients/widgets/client_token_search_field.dart';

/// Clients list screen — pure config + per-entity widgets. The screen-level
/// chrome (Scaffold / AppBar / FAB / drawer / body switching / bulk dispatch
/// / company-switch tracking / formatter wiring) lives in
/// [EntityListScreenScaffold]; this class just plugs Clients-specific bits
/// into it.
class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntityListScreenScaffold<Client, ClientListViewModel>(
      titleKey: 'clients',
      newRoute: '/clients/new',
      newLabelKey: 'new_client',
      // Money columns — let the scaffold wire `FormatterHostMixin` so the
      // tile renders the per-client currency cascade.
      wantsFormatter: true,
      buildVm: (services, companyId) => ClientListViewModel(
        repo: services.clients,
        navStateDao: services.db.navStateDao,
        userSettings: services.userSettings,
        companyId: companyId,
      ),
      sortOptions: (context) => [
        SortOption(id: ClientFieldIds.name, label: context.tr('name')),
        SortOption(id: ClientFieldIds.number, label: context.tr('number')),
        SortOption(id: ClientFieldIds.balance, label: context.tr('balance')),
        SortOption(
          id: ClientFieldIds.updatedAt,
          label: context.tr('last_updated'),
        ),
        SortOption(id: ClientFieldIds.createdAt, label: context.tr('created')),
      ],
      searchFieldBuilder: (context, vm, wide) =>
          ClientTokenSearchField(vm: vm, wide: wide),
      // Filter-aware empty copy ("no clients yet" vs "no clients match
      // these filters") — wrapper has the branch logic inside.
      emptyStateBuilder: (context, vm) => ClientListEmptyState(vm: vm),
      // Typedef wrapper; equivalent to `EntityListColumnHeaders<Client>`.
      wideColumnHeadersBuilder: (context, vm) =>
          ClientListColumnHeaders(vm: vm),
      tileBuilder: (context, vm, client, index, options) => ClientListTile(
        client: client,
        formatter: options.formatter,
        wide: options.wide,
        columns: options.wide ? vm.columns : const <ClientColumn>[],
        isLast: options.isLast,
        selecting: options.selecting,
        selected: vm.isSelected(client.id),
        onTap: options.selecting
            ? () => vm.toggleSelected(client.id)
            : () => context.go('/clients/${client.id}'),
        onLongPress: () => vm.toggleSelected(client.id),
        // Desktop entry point: hover reveals a checkbox in the leading
        // slot, click here enters multi-select. Same handler as
        // long-press (touch entry).
        onSelectTap: () => vm.toggleSelected(client.id),
        onAction: options.selecting
            ? null
            : (action) => _onAction(context, vm, client.id, action),
      ),
      bulkActions: const [
        EntityListBulkAction(
          actionId: 'archive',
          icon: Icons.archive_outlined,
          tooltipKey: 'archive',
          singleSuccessKey: 'archived_client',
          pluralSuccessKey: 'archived_clients',
          nothingKey: 'nothing_to_archive',
        ),
        EntityListBulkAction(
          actionId: 'restore',
          icon: Icons.unarchive_outlined,
          tooltipKey: 'restore',
          singleSuccessKey: 'restored_client',
          pluralSuccessKey: 'restored_clients',
          nothingKey: 'nothing_to_restore',
        ),
      ],
    );
  }

  Future<void> _onAction(
    BuildContext context,
    ClientListViewModel vm,
    String clientId,
    ClientRowAction action,
  ) async {
    final services = vm.repo;
    switch (action) {
      case ClientRowAction.view:
        context.go('/clients/$clientId');
      case ClientRowAction.edit:
        context.go('/clients/$clientId/edit');
      case ClientRowAction.archive:
        await _runMutation(
          context,
          () => services.archive(companyId: vm.companyId, id: clientId),
          successMsg: context.tr('archived_client'),
        );
      case ClientRowAction.restore:
        await _runMutation(
          context,
          () => services.restore(companyId: vm.companyId, id: clientId),
          successMsg: context.tr('restored_client'),
        );
    }
  }

  /// Runs a repo mutation and surfaces success / failure. Mirrors the
  /// helper that lived on the previous list screen; lifted onto the
  /// StatelessWidget so it stays close to its single caller. If a second
  /// screen ever needs the same pattern, promote it to a top-level
  /// `lib/ui/core/widgets/notify_async.dart` helper.
  Future<void> _runMutation(
    BuildContext context,
    Future<void> Function() op, {
    required String successMsg,
  }) async {
    try {
      await op();
      if (!context.mounted) return;
      Notify.success(context, successMsg);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, context.tr('could_not_save'), error: e);
    }
  }
}
