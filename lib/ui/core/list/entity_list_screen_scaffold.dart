import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/list/entity_bulk_message.dart';
import 'package:admin/ui/core/list/entity_list_app_bar.dart';
import 'package:admin/ui/core/list/entity_list_column_headers.dart';
import 'package:admin/ui/core/list/entity_list_constants.dart';
import 'package:admin/ui/core/list/entity_list_footer.dart';
import 'package:admin/ui/core/list/entity_sort_filter_sheet.dart';
import 'package:admin/ui/core/list/generic_list_view_model.dart';
import 'package:admin/ui/core/widgets/empty_state.dart';
import 'package:admin/ui/core/widgets/error_view.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/shell/widgets/app_drawer.dart';
import 'package:admin/utils/formatting.dart';

// ─── Callbacks ───────────────────────────────────────────────────────────

/// Builds the concrete [GenericListViewModel] for an entity list screen.
/// Called from `initState` and from the company-switch listener.
typedef EntityVmBuilder<T, VM extends GenericListViewModel<T>> =
    VM Function(Services services, String companyId);

/// Renders one row in the list. Pulled out as a builder (rather than a
/// `Widget`) so the scaffold can supply per-row state — wide/narrow,
/// whether this row is the last, and the resolved currency formatter (null
/// when [EntityListScreenScaffold.wantsFormatter] is false).
typedef EntityTileBuilder<T, VM extends GenericListViewModel<T>> =
    Widget Function(
      BuildContext context,
      VM vm,
      T item,
      int index,
      EntityListTileOptions options,
    );

/// Builds the per-entity token search field. Lives outside the scaffold
/// because every entity has a different `FilterKey` set.
typedef EntitySearchFieldBuilder<VM> =
    Widget Function(BuildContext context, VM vm, bool wide);

/// Builds the localized list of sort options. Called every build so locale
/// changes take effect without a hot reload.
typedef EntitySortOptionsBuilder =
    List<SortOption> Function(BuildContext context);

/// Overrides the default "no rows" widget. Use this when an entity has
/// filter-aware empty copy ("no clients match these filters" vs "no clients
/// yet"); most entities can rely on the default ([EmptyState] with the
/// supplied icon + title key).
typedef EntityEmptyStateBuilder<VM> =
    Widget Function(BuildContext context, VM vm);

/// Overrides the default wide-mode column header strip. Defaults to
/// [EntityListColumnHeaders<T>]; supply only when the entity needs a custom
/// header row (e.g. typedef'd wrapper like `ClientListColumnHeaders`).
typedef EntityWideColumnHeadersBuilder<VM> =
    Widget Function(BuildContext context, VM vm);

// ─── Config records ──────────────────────────────────────────────────────

/// Per-row state supplied to the [EntityTileBuilder] every build.
@immutable
class EntityListTileOptions {
  const EntityListTileOptions({
    required this.wide,
    required this.isLast,
    required this.selecting,
    required this.formatter,
  });

  final bool wide;

  /// True for the row at index `items.length - 1`. The tile uses this to
  /// suppress its bottom border so the table doesn't double-line.
  final bool isLast;

  /// True when the screen is in multi-select mode. Convenience flag so the
  /// tile doesn't have to call `vm.isInMultiselect` itself.
  final bool selecting;

  /// Resolved currency formatter, or null when the scaffold wasn't asked
  /// to load one (`wantsFormatter: false`) or while the future is in
  /// flight. Tiles that render money use this; tiles that don't can ignore.
  final Formatter? formatter;
}

/// One bulk action surfaced in the selection-mode AppBar. The scaffold
/// looks up the matching [BulkAction] on the VM by [actionId], invokes
/// `applyBulkAction(...)`, and renders the localized result via
/// [formatBulkMessage].
@immutable
class EntityListBulkAction {
  const EntityListBulkAction({
    required this.actionId,
    required this.icon,
    required this.tooltipKey,
    required this.singleSuccessKey,
    required this.pluralSuccessKey,
    required this.nothingKey,
  });

  /// Must match a `BulkAction.id` registered on `vm.bulkActions`. Stable
  /// across locales (`archive`, `restore`, `delete`, …).
  final String actionId;

  final IconData icon;
  final String tooltipKey;

  /// Locale key shown when exactly one row was affected (e.g. `archived_client`).
  final String singleSuccessKey;

  /// Locale key shown when more than one row was affected. The string
  /// should accept either `:count` or `:value` — the scaffold substitutes
  /// both so different locales can pick their preferred placeholder.
  final String pluralSuccessKey;

  /// Locale key shown when no eligible rows were affected (`nothing_to_archive`).
  final String nothingKey;
}

// ─── Scaffold ────────────────────────────────────────────────────────────

/// Generic list-screen chrome. Owns every piece of boilerplate that's the
/// same across entity list screens — VM lifecycle, scroll controllers,
/// company-switch tracking, Scaffold + AppBar + FAB + drawer, body
/// switching (error / loading / empty / wide table / narrow list),
/// bulk-action dispatch, and transient notice rendering.
///
/// The concrete list screen becomes a `StatelessWidget` that constructs
/// one of these with entity-specific config + callbacks. See
/// `client_list_screen.dart` and `product_list_screen.dart` for the two
/// reference invocations.
class EntityListScreenScaffold<T, VM extends GenericListViewModel<T>>
    extends StatefulWidget {
  const EntityListScreenScaffold({
    super.key,
    required this.titleKey,
    required this.newRoute,
    required this.newLabelKey,
    required this.buildVm,
    required this.sortOptions,
    required this.searchFieldBuilder,
    required this.tileBuilder,
    required this.bulkActions,
    this.emptyIcon,
    this.emptyTitleKey,
    this.emptyStateBuilder,
    this.wideColumnHeadersBuilder,
    this.wantsFormatter = false,
  });

  /// Localization key for the narrow-mode AppBar title (e.g. `clients`).
  final String titleKey;

  /// Route the wide-mode "New X" button + narrow-mode FAB navigate to
  /// (e.g. `/clients/new`).
  final String newRoute;

  /// Localization key for the "New X" button + FAB tooltip
  /// (e.g. `new_client`).
  final String newLabelKey;

  /// Constructs the VM. Called from `initState` with the resolved
  /// `Services` and the session's `currentCompanyId`; re-called on company
  /// switch.
  final EntityVmBuilder<T, VM> buildVm;

  /// Sort options shown in the narrow-mode sort sheet.
  final EntitySortOptionsBuilder sortOptions;

  /// Builds the entity-specific token search field.
  final EntitySearchFieldBuilder<VM> searchFieldBuilder;

  /// Builds each row. The scaffold supplies per-row state via
  /// [EntityListTileOptions].
  final EntityTileBuilder<T, VM> tileBuilder;

  /// Bulk actions exposed in the multi-select AppBar. Each entry maps a
  /// `BulkAction.id` on the VM to a button + locale keys.
  final List<EntityListBulkAction> bulkActions;

  /// Icon for the default `EmptyState`. Ignored when [emptyStateBuilder]
  /// is supplied.
  final IconData? emptyIcon;

  /// Localization key for the default `EmptyState` title. Ignored when
  /// [emptyStateBuilder] is supplied.
  final String? emptyTitleKey;

  /// Custom empty-state widget. Use this when the empty state needs to
  /// differ between "no rows at all" and "no rows match the active
  /// filters" — see `ClientListEmptyState` for the reference.
  final EntityEmptyStateBuilder<VM>? emptyStateBuilder;

  /// Custom wide-mode column header strip. Defaults to
  /// `EntityListColumnHeaders<T>(vm: vm)`; override only when the entity
  /// has a typedef'd wrapper.
  final EntityWideColumnHeadersBuilder<VM>? wideColumnHeadersBuilder;

  /// When `true`, the scaffold wires `FormatterHostMixin` and supplies the
  /// resolved [Formatter] to [tileBuilder] via [EntityListTileOptions].
  /// Flip this on for entities that render money (clients, invoices,
  /// payments, …). Off by default so non-financial entities aren't
  /// charged for the lookup.
  final bool wantsFormatter;

  @override
  State<EntityListScreenScaffold<T, VM>> createState() =>
      _EntityListScreenScaffoldState<T, VM>();
}

class _EntityListScreenScaffoldState<T, VM extends GenericListViewModel<T>>
    extends State<EntityListScreenScaffold<T, VM>>
    with FormatterHostMixin {
  late VM _vm;
  late final Services _services;
  late String _companyId;

  /// Vertical scroll. Triggers `loadMore()` when the viewport is within
  /// [_loadMoreThresholdPx] of the bottom — the next page is in flight
  /// before the user hits the spinner.
  final ScrollController _vScroll = ScrollController();

  /// Horizontal scroll for the wide-mode bordered card. Shared by the
  /// column header strip and the rows so they pan in lock-step.
  final ScrollController _hScroll = ScrollController();

  static const double _loadMoreThresholdPx = 600;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    // A null session here means the router failed its redirect — but the
    // screen is built lazily, so by the time we reach here the session
    // value is always set.
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = widget.buildVm(_services, _companyId);
    _vScroll.addListener(_onScroll);
    _services.auth.session.addListener(_onSessionChanged);
    if (widget.wantsFormatter) loadFormatter(_services, _companyId);
  }

  /// Rebuild the VM when the user switches workspaces. The screen survives
  /// a company switch because every entity branch's `Navigator` has a
  /// `GlobalKey` in `router.dart`, which preserves `State` across the
  /// rebuild — so the scaffold has to track `auth.session` itself.
  void _onSessionChanged() {
    final s = _services.auth.session.value;
    if (s == null || s.currentCompanyId == _companyId) return;
    final oldVm = _vm;
    setState(() {
      _companyId = s.currentCompanyId;
      _vm = widget.buildVm(_services, _companyId);
    });
    // Dispose AFTER swapping in the new VM so any in-flight rebuild keyed
    // on the old `_vm` reference has already moved on.
    oldVm.dispose();
    if (widget.wantsFormatter) {
      // Drop the previous company's formatter so money renders as `—`
      // while the new one resolves — otherwise the wrong currency briefly
      // shows.
      clearFormatter();
      loadFormatter(_services, _companyId);
    }
  }

  void _onScroll() {
    if (!_vScroll.hasClients) return;
    if (_vScroll.position.pixels >=
        _vScroll.position.maxScrollExtent - _loadMoreThresholdPx) {
      _vm.loadMore();
    }
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _vScroll.removeListener(_onScroll);
    _vScroll.dispose();
    _hScroll.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _onBulk(EntityListBulkAction action) async {
    final bulk = _vm.bulkActionById(action.actionId);
    if (bulk == null) return;
    final result = await _vm.applyBulkAction(bulk);
    if (!mounted) return;
    Notify.success(
      context,
      formatBulkMessage(
        context,
        singleKey: action.singleSuccessKey,
        pluralKey: action.pluralSuccessKey,
        nothingKey: action.nothingKey,
        result: result,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        // One-shot transient notices (e.g. "Showing active" after the user
        // unchecks the last state) flow through here. Schedule the
        // SnackBar for the next frame so the rebuild that surfaced the
        // notice finishes first.
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
            final globalNav = Breakpoints.isGlobalNavVisible(context);
            final selecting = _vm.isInMultiselect;
            return Scaffold(
              // The shell's company switcher + branch nav live in this
              // drawer when the global persistent rail isn't shown. Keying
              // off the *window* width (via [globalNav]) — not the local
              // [wide] — avoids a redundant hamburger at medium widths
              // where the rail is visible but our pane is < 600 px.
              drawer: globalNav ? null : const AppDrawer(),
              // Wide hosts an inline "New X" button inside the top row, so
              // the FAB is mobile-only. Selection mode hides it either way.
              floatingActionButton: (selecting || wide)
                  ? null
                  : FloatingActionButton(
                      tooltip: context.tr(widget.newLabelKey),
                      onPressed: () => context.go(widget.newRoute),
                      child: const Icon(Icons.add),
                    ),
              // endFloat lifts the FAB above the bottom filter bar on mobile.
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
              appBar: selecting
                  ? EntityListSelectionAppBar<T>(
                      vm: _vm,
                      actions: [
                        for (final a in widget.bulkActions)
                          EntitySelectionAction(
                            icon: a.icon,
                            tooltipKey: a.tooltipKey,
                            onPressed: () => _onBulk(a),
                          ),
                      ],
                    )
                  : EntityListNormalAppBar<T>(
                      vm: _vm,
                      wide: wide,
                      showHamburger: !globalNav,
                      titleKey: widget.titleKey,
                      newRoute: widget.newRoute,
                      newLabelKey: widget.newLabelKey,
                      sortOptions: widget.sortOptions(context),
                      searchField: widget.searchFieldBuilder(
                        context,
                        _vm,
                        wide,
                      ),
                    ),
              body: _body(context, wide: wide, selecting: selecting),
            );
          },
        );
      },
    );
  }

  Widget _body(
    BuildContext context, {
    required bool wide,
    required bool selecting,
  }) {
    if (_vm.initialError != null && _vm.items.isEmpty) {
      return ErrorView(
        message: context.tr('failed_to_load_with_error', {
          'error': _vm.initialError!,
        }),
        onRetry: _vm.retryInitial,
      );
    }
    if (_vm.items.isEmpty && !_vm.isLoadingPage) {
      return RefreshIndicator(
        // `refresh` does a full server-side sweep across every state — it
        // intentionally ignores the current filter selection so the local
        // cache stays complete.
        onRefresh: _vm.refresh,
        child: ListView(
          // RefreshIndicator needs a scrollable child; a single sliver-free
          // ListView with one centered tile gives the empty state without
          // breaking pull-to-refresh.
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: _emptyState(context),
            ),
          ],
        ),
      );
    }

    final list = RefreshIndicator(
      onRefresh: _vm.refresh,
      child: ListView.builder(
        controller: _vScroll,
        itemCount: _vm.items.length + 1, // +1 for the footer slot
        itemBuilder: (context, index) {
          if (index >= _vm.items.length) return _footer();
          final item = _vm.items[index];
          return widget.tileBuilder(
            context,
            _vm,
            item,
            index,
            EntityListTileOptions(
              wide: wide,
              isLast: index == _vm.items.length - 1,
              selecting: selecting,
              formatter: widget.wantsFormatter ? formatter : null,
            ),
          );
        },
      ),
    );

    if (!wide) return list;
    return _wideTable(context, list);
  }

  Widget _emptyState(BuildContext context) {
    final builder = widget.emptyStateBuilder;
    if (builder != null) return builder(context, _vm);
    // Default: a generic `EmptyState` driven by the icon + title key the
    // caller supplied. Entities with filter-aware copy supply
    // `emptyStateBuilder` instead.
    assert(
      widget.emptyIcon != null && widget.emptyTitleKey != null,
      'EntityListScreenScaffold needs either `emptyStateBuilder` or both '
      '`emptyIcon` and `emptyTitleKey`.',
    );
    return EmptyState(
      icon: widget.emptyIcon!,
      title: context.tr(widget.emptyTitleKey!),
    );
  }

  Widget _footer() {
    if (_vm.isLoadingPage) return const EntityListLoadingFooter();
    if (!_vm.hasMore && _vm.items.isNotEmpty) {
      return const EntityListEndOfListFooter();
    }
    return const SizedBox.shrink();
  }

  /// Wide: wrap the list in the v2 card chrome with a column header strip
  /// above the rows. Mirrors `docs/design/v2/screens.jsx:557-601`.
  ///
  /// The header + rows live inside a horizontal `SingleChildScrollView` so
  /// the table can pan sideways when the selected columns sum to wider
  /// than the viewport. A `SizedBox(width: tableWidth)` gives the inner
  /// `Column` bounded width regardless of viewport — without it, the row
  /// `Flexible`s and `SizedBox`es would lay out against an unbounded
  /// parent and the nested Flex Row would overflow.
  Widget _wideTable(BuildContext context, Widget list) {
    final tokens = context.inTheme;
    final columns = _vm.columns;
    final minWidth = computeTableMinWidth(columns);
    final headersBuilder = widget.wideColumnHeadersBuilder;
    final headers = headersBuilder != null
        ? headersBuilder(context, _vm)
        : EntityListColumnHeaders<T>(vm: _vm);
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
                      headers,
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
}
