import 'package:flutter/material.dart';

import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/client_list_top_row.dart';
import 'package:admin/ui/features/clients/widgets/client_token_search_field.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';

/// AppBar shown when the user isn't in multi-select.
///
/// Wide: title + search + filters + columns + "New client" all on one row
/// (rendered via `flexibleSpace` because `AppBar.title` lays out its child
/// with unbounded width first, which blows up `Expanded` inside our search
/// row). Narrow: hamburger + title + sort action, with the token search
/// field hanging below in `bottom`.
class ClientListNormalAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ClientListNormalAppBar({
    super.key,
    required this.vm,
    required this.wide,
  });

  final ClientListViewModel vm;
  final bool wide;

  @override
  Size get preferredSize => wide
      ? const Size.fromHeight(64)
      : const Size.fromHeight(kToolbarHeight + 56);

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            child: Center(child: ClientListTopRow(vm: vm)),
          ),
        ),
      );
    }
    return AppBar(
      // Hamburger on narrow only — wide has the persistent rail. Selection
      // mode swaps to a different AppBar (Cancel-X leading), so this only
      // shows when neither selecting nor wide.
      leading: const DrawerHamburger(),
      title: Text(context.tr('clients')),
      actions: [
        IconButton(
          tooltip: context.tr('sort'),
          icon: const Icon(Icons.sort),
          onPressed: () => _openSortSheet(context),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        // The token search field carries every filter dimension; tapping it
        // opens the full-screen `FilterEntrySheet` for editing.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ClientTokenSearchField(vm: vm, wide: false),
        ),
      ),
    );
  }

  Future<void> _openSortSheet(BuildContext context) async {
    final options = <SortOption>[
      SortOption(id: ClientFieldIds.name, label: context.tr('name')),
      SortOption(id: ClientFieldIds.number, label: context.tr('number')),
      SortOption(id: ClientFieldIds.balance, label: context.tr('balance')),
      SortOption(
        id: ClientFieldIds.updatedAt,
        label: context.tr('last_updated'),
      ),
      SortOption(id: ClientFieldIds.createdAt, label: context.tr('created')),
    ];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => EntitySortFilterSheet(
        initialField: vm.sortField,
        initialAscending: vm.sortAscending,
        options: options,
        onApply: ({required field, required ascending}) =>
            vm.setSort(field: field, ascending: ascending),
      ),
    );
  }
}

/// AppBar shown while the user is in multi-select. Cancel-X leading,
/// "N selected" title, and bulk actions on the trailing edge.
class ClientListSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ClientListSelectionAppBar({
    super.key,
    required this.vm,
    required this.onBulkArchive,
    required this.onBulkRestore,
  });

  final ClientListViewModel vm;
  final VoidCallback onBulkArchive;
  final VoidCallback onBulkRestore;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // While a bulk op is in flight, gray out the destructive actions so a
    // double-tap can't fire the same batch twice. Cancel + Select-all stay
    // live — they're synchronous and safe.
    final busy = vm.bulkInFlight;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: context.tr('cancel'),
        onPressed: vm.clearSelection,
      ),
      title: Text(
        context.tr('count_selected', {'count': vm.countSelected.toString()}),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.checklist_outlined),
          tooltip: context.tr('select_all_visible'),
          onPressed: vm.selectAllVisible,
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined),
          tooltip: context.tr('archive'),
          onPressed: busy ? null : onBulkArchive,
        ),
        IconButton(
          icon: const Icon(Icons.unarchive_outlined),
          tooltip: context.tr('restore'),
          onPressed: busy ? null : onBulkRestore,
        ),
      ],
    );
  }
}
