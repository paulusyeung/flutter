import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/utils/formatting.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/core/list/entity_active_filters_strip.dart';
import 'package:admin/ui/features/clients/widgets/client_list_top_row.dart';
import 'package:admin/ui/features/clients/widgets/client_filter_bottom_bar.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  // Not `final` — these are rebuilt on company switch via [_onSessionChanged].
  // The screen survives a company switch because the Clients branch's
  // Navigator has a `GlobalKey` (`router.dart:_shellKey`), which preserves
  // `State` across the rebuild. So this screen has to track `auth.session`
  // itself and re-bind its VM to the new company id.
  late ClientListViewModel _vm;
  late final Services _services;
  late String _companyId;
  final ScrollController _scroll = ScrollController();

  /// Horizontal scroll for the wide table. Shared between the header strip
  /// and the rows so they pan in lock-step.
  final ScrollController _hScroll = ScrollController();

  /// Built once in `initState`. While the future is pending, money columns
  /// render as `—` (same path as zero amounts) so the list still appears
  /// instead of flashing a spinner.
  Formatter? _formatter;

  /// Above this width the list switches to the v2 "table" treatment: a
  /// bordered card with a `surfaceAlt` column header strip above the rows.
  /// Matches the breakpoint used elsewhere (NavigationRail vs NavigationBar).
  static const double _wideBreakpoint = 600;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    final session = _services.auth.session.value;
    // A null session here means the router failed its redirect — but the
    // screen is built lazily, so by the time we reach here the session
    // value is always set. Bang-asserting matches that invariant.
    _companyId = session!.currentCompanyId;
    _vm = _buildVm();
    _scroll.addListener(_onScroll);
    _services.auth.session.addListener(_onSessionChanged);
    _loadFormatter();
  }

  ClientListViewModel _buildVm() => ClientListViewModel(
    repo: _services.clients,
    navStateDao: _services.db.navStateDao,
    userSettings: _services.userSettings,
    companyId: _companyId,
  );

  void _loadFormatter() {
    final loadingFor = _companyId;
    _services.formatterFor(loadingFor).then((f) {
      // Discard the result if the user switched company while the future
      // was in flight — otherwise the new company would briefly render
      // with the previous company's currency settings.
      if (!mounted || loadingFor != _companyId) return;
      setState(() => _formatter = f);
    });
  }

  void _onSessionChanged() {
    final s = _services.auth.session.value;
    if (s == null || s.currentCompanyId == _companyId) return;
    final oldVm = _vm;
    setState(() {
      _companyId = s.currentCompanyId;
      _formatter = null;
      _vm = _buildVm();
    });
    // Dispose AFTER swapping in the new VM so any in-flight rebuild keyed on
    // the old `_vm` reference has already moved on.
    oldVm.dispose();
    _loadFormatter();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      _vm.loadMore();
    }
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _hScroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _handleAction(
    BuildContext context,
    String clientId,
    ClientRowAction action,
  ) async {
    switch (action) {
      case ClientRowAction.view:
        context.go('/clients/$clientId');
      case ClientRowAction.edit:
        context.go('/clients/$clientId/edit');
      case ClientRowAction.archive:
        await _runMutation(
          context,
          () => _services.clients.archive(companyId: _companyId, id: clientId),
          successMsg: context.tr('archived_client'),
        );
      case ClientRowAction.restore:
        await _runMutation(
          context,
          () => _services.clients.restore(companyId: _companyId, id: clientId),
          successMsg: context.tr('restored_client'),
        );
    }
  }

  Future<void> _runMutation(
    BuildContext context,
    Future<void> Function() op, {
    required String successMsg,
  }) async {
    try {
      await op();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMsg)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('failed_with_error', {'error': e.toString()}),
          ),
        ),
      );
    }
  }

  Future<void> _onBulkArchive() async {
    final result = await _vm.bulkArchive();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _bulkMessage(
            successKey: 'archived_clients',
            singleKey: 'archived_client',
            nothingKey: 'nothing_to_archive',
            result: result,
          ),
        ),
      ),
    );
  }

  Future<void> _onBulkRestore() async {
    final result = await _vm.bulkRestore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _bulkMessage(
            successKey: 'restored_clients',
            singleKey: 'restored_client',
            nothingKey: 'nothing_to_restore',
            result: result,
          ),
        ),
      ),
    );
  }

  /// Build the bulk-action SnackBar copy from localized parts.
  /// `successKey` is the plural success string (":count clients"), `singleKey`
  /// is the single-row variant, `nothingKey` is the "nothing matched" fallback.
  String _bulkMessage({
    required String successKey,
    required String singleKey,
    required String nothingKey,
    required ({int ok, int skipped, int failed}) result,
  }) {
    final parts = <String>[];
    if (result.ok > 0) {
      // `archived_clients` uses `:count`; `restored_clients` uses `:value`.
      // Pass both so whichever the locale references gets substituted.
      final base = result.ok == 1
          ? context.tr(singleKey)
          : context.tr(successKey, {
              'count': result.ok.toString(),
              'value': result.ok.toString(),
            });
      parts.add(base);
    }
    if (result.skipped > 0) {
      parts.add(
        context.tr('count_skipped', {'count': result.skipped.toString()}),
      );
    }
    if (result.failed > 0) {
      parts.add(
        context.tr('count_failed', {'count': result.failed.toString()}),
      );
    }
    if (parts.isEmpty) return context.tr(nothingKey);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        // One-shot transient notices (e.g. "Showing active" after the user
        // unchecks the last state) flow through here. Schedule the SnackBar
        // for the next frame so the rebuild that surfaced the notice
        // finishes first.
        final notice = _vm.consumeTransientNotice();
        if (notice != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(notice)));
          });
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideBreakpoint;
            final selecting = _vm.isInMultiselect;
            return Scaffold(
              // On narrow widths, the shell's company switcher + branch nav
              // live in this drawer. On wide widths the persistent rail
              // handles both, so no drawer here (and no hamburger below).
              drawer: wide ? null : const AppDrawer(),
              // Wide hosts an inline "New client" button inside the top
              // row, so the FAB is mobile-only. Selection mode hides it
              // either way.
              floatingActionButton: (selecting || wide)
                  ? null
                  : FloatingActionButton(
                      tooltip: context.tr('new_client'),
                      onPressed: () => context.go('/clients/new'),
                      child: const Icon(Icons.add),
                    ),
              // endFloat lifts the FAB above our bottom filter bar on mobile.
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              appBar: selecting
                  ? _selectionAppBar()
                  : _normalAppBar(wide: wide),
              bottomNavigationBar: (!wide && !selecting)
                  ? ClientFilterBottomBar(vm: _vm)
                  : null,
              body: Column(
                children: [
                  // Wide folds title + search + state/custom filters +
                  // columns + Add into the AppBar's `title` row, so the
                  // body has no separate filter bar above the list.
                  if (!selecting && !wide) EntityActiveFiltersStrip(vm: _vm),
                  Expanded(child: _body(context, wide: wide)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _normalAppBar({required bool wide}) {
    if (wide) {
      // Wide: title + search + filters + columns + "New client" all on
      // one row. Rendered via `flexibleSpace` (NOT `title`) because
      // `_RenderAppBarTitleBox` lays out its title with unbounded width
      // first, which blows up `Expanded` inside our search row.
      // `flexibleSpace` receives the AppBar's full bounded width and
      // lays out flex children correctly.
      return AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Center(child: ClientListTopRow(vm: _vm)),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.tr('search_clients'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 12,
              ),
            ),
            onChanged: _vm.setSearch,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _selectionAppBar() {
    // While a bulk op is in flight, gray out the destructive actions so a
    // double-tap can't fire the same batch twice. Cancel + Select-all stay
    // live — they're synchronous and safe.
    final busy = _vm.bulkInFlight;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: context.tr('cancel'),
        onPressed: _vm.clearSelection,
      ),
      title: Text(
        context.tr('count_selected', {'count': _vm.countSelected.toString()}),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.checklist_outlined),
          tooltip: context.tr('select_all_visible'),
          onPressed: _vm.selectAllVisible,
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined),
          tooltip: context.tr('archive'),
          onPressed: busy ? null : _onBulkArchive,
        ),
        IconButton(
          icon: const Icon(Icons.unarchive_outlined),
          tooltip: context.tr('restore'),
          onPressed: busy ? null : _onBulkRestore,
        ),
      ],
    );
  }

  Widget _body(BuildContext context, {required bool wide}) {
    if (_vm.initialError != null && _vm.clients.isEmpty) {
      return ErrorView(
        message: context.tr('failed_to_load_with_error', {
          'error': _vm.initialError!,
        }),
        onRetry: _vm.retryInitial,
      );
    }
    if (_vm.clients.isEmpty && !_vm.isLoadingPage) {
      return RefreshIndicator(
        // `refresh` does a full server-side sweep across every state — it
        // intentionally ignores the current filter selection so the local
        // cache stays complete. Don't "fix" this to honor the filter.
        onRefresh: _vm.refresh,
        child: ListView(
          // RefreshIndicator needs a scrollable child; a single sliver-free
          // ListView with one centered tile gives the empty state without
          // breaking pull-to-refresh.
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: _emptyState(),
            ),
          ],
        ),
      );
    }

    final list = RefreshIndicator(
      onRefresh: _vm.refresh,
      child: ListView.builder(
        controller: _scroll,
        itemCount: _vm.clients.length + 1, // + 1 for the footer
        itemBuilder: (context, index) {
          if (index >= _vm.clients.length) return _footer();
          final c = _vm.clients[index];
          final selecting = _vm.isInMultiselect;
          return ClientListTile(
            client: c,
            formatter: _formatter,
            wide: wide,
            columns: wide ? _vm.columns : const <ClientColumn>[],
            isLast: index == _vm.clients.length - 1,
            selecting: selecting,
            selected: _vm.isSelected(c.id),
            onTap: selecting
                ? () => _vm.toggleSelected(c.id)
                : () => context.go('/clients/${c.id}'),
            onLongPress: () => _vm.toggleSelected(c.id),
            // Desktop entry point: hover reveals a checkbox in the leading
            // slot, click here enters multi-select. Same handler as long-
            // press (touch entry).
            onSelectTap: () => _vm.toggleSelected(c.id),
            onAction: selecting
                ? null
                : (action) => _handleAction(context, c.id, action),
          );
        },
      ),
    );

    if (!wide) return list;

    // Wide: wrap the list in the v2 card chrome with a column header strip
    // above the rows. Mirrors `docs/design/v2/screens.jsx:557-601`.
    //
    // The header + rows live inside a horizontal `SingleChildScrollView` so
    // the table can pan sideways when the selected columns sum to wider
    // than the viewport. A `SizedBox(width: tableWidth)` gives the inner
    // `Column` bounded width regardless of viewport — without it, the row
    // `Flexible`s and `SizedBox`es would lay out against an unbounded
    // parent and the nested Flex Row would overflow.
    final tokens = context.inTheme;
    final columns = _vm.columns;
    final minWidth = _computeTableMinWidth(columns);
    return Padding(
      padding: const EdgeInsetsDirectional.all(24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(InRadii.r3),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final tableWidth = math.max(c.maxWidth, minWidth);
            return Scrollbar(
              controller: _hScroll,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _hScroll,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _ColumnHeaders(vm: _vm),
                      Expanded(child: list),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Total minimum width the table row needs to lay out without overflowing.
  /// Matches the slot widths used by `_ColumnHeaders` and `ClientListTile._wide`.
  double _computeTableMinWidth(List<ClientColumn> columns) {
    var total = kColLeadingWidth + kColCellGap; // avatar/checkbox + gap
    for (final c in columns) {
      total += c.isFlex ? kColumnFlexMinWidth : c.width!;
      total += kColCellGap;
    }
    total += kColWPillSlot + kColWMoreMenu;
    // Mirror the row padding (`EdgeInsetsDirectional.fromSTEB(16, _, 16, _)`).
    return total + 32;
  }

  /// Pick the empty-state copy + CTA based on what the user is looking at.
  /// Truly-empty (defaults applied) shows the "create your first client"
  /// nudge; a non-default filter that yields zero rows offers a "Clear
  /// filters" escape hatch; archived/deleted-only filters get their own
  /// non-CTA copy so the user doesn't think the app is broken.
  EmptyState _emptyState() {
    if (!_vm.hasActiveFilters) {
      return EmptyState(
        icon: Icons.people_outline,
        title: context.tr('no_clients_yet'),
        subtitle: context.tr('create_your_first_client_placeholder'),
      );
    }
    final onlyArchived =
        _vm.states.length == 1 &&
        _vm.states.contains(EntityState.archived) &&
        _vm.customFilters.isEmpty &&
        _vm.search.isEmpty;
    final onlyDeleted =
        _vm.states.length == 1 &&
        _vm.states.contains(EntityState.deleted) &&
        _vm.customFilters.isEmpty &&
        _vm.search.isEmpty;
    if (onlyArchived) {
      return EmptyState(
        icon: Icons.archive_outlined,
        title: context.tr('no_archived_clients'),
      );
    }
    if (onlyDeleted) {
      return EmptyState(
        icon: Icons.delete_outline,
        title: context.tr('no_deleted_clients'),
      );
    }
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: context.tr('no_clients_match_filters'),
      action: OutlinedButton.icon(
        onPressed: _vm.clearAllFilters,
        icon: const Icon(Icons.close),
        label: Text(context.tr('clear_filters')),
      ),
    );
  }

  Widget _footer() {
    if (_vm.isLoadingPage) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!_vm.hasMore && _vm.clients.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            context.tr('end_of_list'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Uppercase eyebrow column labels above the table rows at wide widths.
/// Iterates the VM's current `columns` so header widths and labels stay in
/// lock-step with whatever the user has chosen via the column picker.
///
/// Doubles as the desktop sort control: every header is clickable and the
/// active one shows a ↑/↓ indicator. Backed by the DAO's `json_extract`
/// fallback so any visible column can be sorted, including payload-only
/// fields like contact name or city.
class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.vm});

  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: tokens.ink3,
    );
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Row(
        children: [
          // Leading 32-px avatar/checkbox slot + 12 gap. Mirrors the row.
          // On desktop, hovering this slot reveals a select-all checkbox.
          SizedBox(
            width: kColLeadingWidth,
            child: _HeaderSelectAllSlot(vm: vm),
          ),
          const SizedBox(width: kColCellGap),
          for (final col in vm.columns) ...[
            _HeaderCell(column: col, labelStyle: labelStyle, vm: vm),
            const SizedBox(width: kColCellGap),
          ],
          // Pill + more columns: reserved, unlabeled.
          const SizedBox(width: kColWPillSlot),
          const SizedBox(width: kColWMoreMenu),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.labelStyle,
    required this.vm,
  });
  final ClientColumn column;
  final TextStyle labelStyle;
  final ClientListViewModel vm;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final isActive = vm.sortField == column.id;
    final activeStyle = labelStyle.copyWith(color: tokens.ink2);
    final text = Text(
      context.tr(column.labelKey).toUpperCase(),
      style: isActive ? activeStyle : labelStyle,
    );
    final arrow = isActive
        ? Padding(
            // Hair of breathing room between label and arrow.
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            child: Icon(
              vm.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: tokens.ink2,
            ),
          )
        : const SizedBox.shrink();
    // Trailing-edge arrow: after the text for start-aligned, before for
    // end-aligned. Keeps the label aligned with the cell contents below.
    final isEnd = column.align == ColumnAlign.end;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: isEnd ? [arrow, text] : [text, arrow],
    );
    final content = InkWell(
      onTap: () => vm.setSort(
        field: column.id,
        // Flip direction only when the active field is tapped again;
        // switching field keeps the current direction.
        ascending: isActive ? !vm.sortAscending : vm.sortAscending,
      ),
      child: Align(
        alignment: isEnd
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
          child: row,
        ),
      ),
    );
    if (column.isFlex) return Expanded(child: content);
    return SizedBox(width: column.width, child: content);
  }
}

/// The wide-mode column header's leading slot. Empty by default; hovers on
/// desktop reveal an empty select-all checkbox (mouse entry to multi-select
/// via `vm.selectAllVisible()`). While in multi-select the checkbox is
/// always visible and reflects whether *every* visible row is selected —
/// clicking it then toggles between "select all" and "clear".
class _HeaderSelectAllSlot extends StatefulWidget {
  const _HeaderSelectAllSlot({required this.vm});
  final ClientListViewModel vm;

  @override
  State<_HeaderSelectAllSlot> createState() => _HeaderSelectAllSlotState();
}

class _HeaderSelectAllSlotState extends State<_HeaderSelectAllSlot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final selecting = vm.isInMultiselect;
    final allSelected =
        selecting &&
        vm.clients.isNotEmpty &&
        vm.countSelected == vm.clients.length;

    Widget child;
    VoidCallback? onTap;
    if (selecting) {
      child = SelectionCheckbox(checked: allSelected);
      onTap = () {
        if (allSelected) {
          vm.clearSelection();
        } else {
          vm.selectAllVisible();
        }
      };
    } else if (_isHovered && vm.clients.isNotEmpty) {
      child = const SelectionCheckbox(checked: false);
      onTap = vm.selectAllVisible;
    } else {
      child = const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: kColLeadingWidth,
          height: kColLeadingWidth,
          child: Center(child: child),
        ),
      ),
    );
  }
}
