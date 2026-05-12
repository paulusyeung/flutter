import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/domain/columns/client_columns.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';
import 'package:admin/ui/features/clients/widgets/client_list_app_bar.dart';
import 'package:admin/ui/features/clients/widgets/client_list_column_headers.dart';
import 'package:admin/ui/features/clients/widgets/client_list_empty_state.dart';
import 'package:admin/ui/features/clients/widgets/client_list_tile.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen>
    with FormatterHostMixin {
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

  /// Trigger `loadMore()` when the viewport gets within this many pixels of
  /// the scroll extent's end — so the next page is in flight before the
  /// user hits the bottom and sees an empty placeholder.
  static const double _loadMoreThresholdPx = 600;

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
    loadFormatter(_services, _companyId);
  }

  ClientListViewModel _buildVm() => ClientListViewModel(
    repo: _services.clients,
    navStateDao: _services.db.navStateDao,
    userSettings: _services.userSettings,
    companyId: _companyId,
  );

  void _onSessionChanged() {
    final s = _services.auth.session.value;
    if (s == null || s.currentCompanyId == _companyId) return;
    final oldVm = _vm;
    setState(() {
      _companyId = s.currentCompanyId;
      _vm = _buildVm();
    });
    // Dispose AFTER swapping in the new VM so any in-flight rebuild keyed on
    // the old `_vm` reference has already moved on.
    oldVm.dispose();
    // Drop the previous company's formatter so money renders as `—` while
    // the new one resolves — otherwise the wrong currency briefly shows.
    clearFormatter();
    loadFormatter(_services, _companyId);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - _loadMoreThresholdPx) {
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
      Notify.success(context, successMsg);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, context.tr('could_not_save'), error: e);
    }
  }

  Future<void> _onBulkArchive() async {
    final result = await _vm.bulkArchive();
    if (!mounted) return;
    Notify.success(
      context,
      _bulkMessage(
        successKey: 'archived_clients',
        singleKey: 'archived_client',
        nothingKey: 'nothing_to_archive',
        result: result,
      ),
    );
  }

  Future<void> _onBulkRestore() async {
    final result = await _vm.bulkRestore();
    if (!mounted) return;
    Notify.success(
      context,
      _bulkMessage(
        successKey: 'restored_clients',
        singleKey: 'restored_client',
        nothingKey: 'nothing_to_restore',
        result: result,
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
            Notify.info(context, notice);
          });
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = Breakpoints.isWide(constraints);
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
                  ? ClientListSelectionAppBar(
                      vm: _vm,
                      onBulkArchive: _onBulkArchive,
                      onBulkRestore: _onBulkRestore,
                    )
                  : ClientListNormalAppBar(vm: _vm, wide: wide),
              body: _body(context, wide: wide),
            );
          },
        );
      },
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
              child: ClientListEmptyState(vm: _vm),
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
            formatter: formatter,
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
                      ClientListColumnHeaders(vm: _vm),
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
  /// Matches the slot widths used by `ClientListColumnHeaders` and
  /// `ClientListTile._wide`.
  double _computeTableMinWidth(List<ClientColumn> columns) {
    var total = kColWMoreMenu + kColCellGap; // leading `…` actions + gap
    total += kColLeadingWidth + kColCellGap; // avatar/checkbox + gap
    for (final c in columns) {
      total += c.isFlex ? kColumnFlexMinWidth : c.width!;
      total += kColCellGap;
    }
    total += kColWPillSlot;
    // Mirror the row padding (`EdgeInsetsDirectional.fromSTEB(16, _, 16, _)`).
    return total + 32;
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
