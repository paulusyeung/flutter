import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../../data/db/dao/nav_state_dao.dart';
import '../../../../data/models/domain/client.dart';
import '../../../../data/repositories/client_repository.dart';
import '../../../../data/repositories/user_settings_repository.dart';
import '../../../../domain/columns/client_columns.dart';
import '../../../../domain/entity_state.dart';
import '../../../../domain/entity_type.dart';

final _log = Logger('ClientListViewModel');

/// Drives the read-only Clients list screen.
///
/// Owns three pieces of state the view binds to:
///   * [clients] — current Drift-emitted page contents (1..[loadedPages]).
///   * [isLoadingPage] — true while a network page is in flight.
///   * [initialError] — non-null after the first page fails (for `ErrorView`).
///
/// Filter state ([states], [sortField], [sortAscending], [customFilters]) is
/// persisted into `nav_state.filters_json` keyed by `companyId` so that app
/// restart and company switching restore the right view per
/// `CLAUDE.md`'s "restart restores where the user left off" guarantee.
///
/// All API access goes through [ClientRepository]; the network never writes
/// to UI state directly. Each user action either triggers an `ensurePage…`
/// call or adjusts the watched window — the Drift stream pushes the result
/// back in via [_onClients].
class ClientListViewModel extends ChangeNotifier {
  ClientListViewModel({
    required this.repo,
    required this.companyId,
    required this.navStateDao,
    required this.userSettings,
    Duration searchDebounce = const Duration(milliseconds: 250),
    Duration persistDebounce = const Duration(milliseconds: 500),
    DateTime Function()? now,
  }) : _searchDebounce = searchDebounce,
       _persistDebounce = persistDebounce,
       _now = now ?? DateTime.now {
    // Show a spinner from the very first frame; hydration + initial fetch
    // both clear it.
    isLoadingPage = true;
    unawaited(_init());
  }

  final ClientRepository repo;
  final String companyId;
  final NavStateDao navStateDao;
  final UserSettingsRepository userSettings;
  final Duration _searchDebounce;
  final Duration _persistDebounce;
  final DateTime Function() _now;

  /// 1-based; bumped by [loadMore]. Determines the slice of the Drift watch
  /// stream we surface to the view (1 = first page only, 2 = first two
  /// pages contiguously, …).
  int loadedPages = 1;

  /// Set after a page returns fewer rows than the page size.
  bool hasMore = true;

  bool isLoadingPage = false;
  String? initialError;

  String _search = '';
  String get search => _search;

  Set<EntityState> _states = const {EntityState.active};
  Set<EntityState> get states => _states;

  /// Wire id of the column the list is sorted by. Matches a key in
  /// `clientColumnsById` — anything outside that allowlist is rejected by
  /// [setSort] and ignored during hydration so the DAO's `json_extract`
  /// fallback never sees an untrusted value.
  String _sortField = ClientFieldIds.name;
  String get sortField => _sortField;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  Map<int, Set<String>> _customFilters = const {};
  Map<int, Set<String>> get customFilters => _customFilters;

  /// True when any filter is non-default. Drives the "active filters" strip
  /// and the filtered-empty-state copy.
  bool get hasActiveFilters {
    if (_states.length != 1 || !_states.contains(EntityState.active)) {
      return true;
    }
    if (_sortField != ClientFieldIds.name || !_sortAscending) return true;
    for (final values in _customFilters.values) {
      if (values.isNotEmpty) return true;
    }
    return _search.isNotEmpty;
  }

  List<Client> _clients = const [];
  List<Client> get clients => _clients;

  /// Transient one-shot message for the view to surface as a SnackBar.
  /// The view reads it via [consumeTransientNotice] which atomically returns
  /// and clears.
  String? _transientNotice;
  String? consumeTransientNotice() {
    final n = _transientNotice;
    _transientNotice = null;
    return n;
  }

  StreamSubscription<List<Client>>? _watchSub;
  StreamSubscription<List<String>?>? _columnsSub;
  Timer? _searchTimer;
  Timer? _persistTimer;
  bool _hydrated = false;

  /// Active column ids. Hydrates from the user_settings stream and defaults
  /// to [kDefaultClientColumns] until that stream emits.
  List<String> _columnIds = List<String>.from(kDefaultClientColumns);

  /// Renderable column list (unknown ids dropped — but unknown ids are still
  /// preserved in the underlying storage so they round-trip).
  List<ClientColumn> get columns => resolveClientColumns(_columnIds);

  /// Raw column id list — the storage representation. Use this to drive the
  /// column picker so the user sees ids they haven't customised yet.
  List<String> get columnIds => List.unmodifiable(_columnIds);

  /// Persist [ids] as the new column order/selection. Writes locally and
  /// enqueues a server sync; the stream subscription folds the canonical
  /// value back in once the server responds.
  Future<void> setColumns(List<String> ids) async {
    final next = List<String>.unmodifiable(ids);
    if (listEquals(next, _columnIds)) return;
    _columnIds = next;
    notifyListeners();
    await userSettings.setColumns(
      companyId: companyId,
      entityType: EntityType.client,
      columns: next,
    );
  }

  /// Restore the registry default column list.
  Future<void> resetColumns() async {
    _columnIds = List<String>.from(kDefaultClientColumns);
    notifyListeners();
    await userSettings.resetColumns(
      companyId: companyId,
      entityType: EntityType.client,
    );
  }

  /// Async startup: hydrate persisted filters first, then subscribe to the
  /// Drift watch, then fetch page 1 from the server. The view sees one
  /// `isLoadingPage=true` from the constructor and a single notify when
  /// hydration completes.
  Future<void> _init() async {
    await _hydrate();
    _subscribeColumns();
    _subscribe();
    await _loadInitialPage();
  }

  void _subscribeColumns() {
    _columnsSub = userSettings
        .watchColumns(companyId: companyId, entityType: EntityType.client)
        .listen((ids) {
          final next = ids == null || ids.isEmpty
              ? List<String>.from(kDefaultClientColumns)
              : List<String>.from(ids);
          if (listEquals(next, _columnIds)) return;
          _columnIds = next;
          notifyListeners();
        });
  }

  Future<void> _hydrate() async {
    try {
      final row = await navStateDao.current();
      final raw = row?.filtersJson;
      if (raw == null || raw.isEmpty) {
        _hydrated = true;
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final company = decoded[companyId];
      if (company is! Map) return;
      final clients = company['clients'];
      if (clients is! Map) return;

      final search = clients['search'];
      if (search is String) _search = search;

      final statesList = clients['states'];
      if (statesList is List) {
        final hydrated = <EntityState>{};
        for (final name in statesList) {
          for (final s in EntityState.values) {
            if (s.name == name) hydrated.add(s);
          }
        }
        if (hydrated.isNotEmpty) _states = hydrated;
      }

      final sortField = clients['sortField'];
      if (sortField is String && clientColumnsById.containsKey(sortField)) {
        _sortField = sortField;
      }

      final ascending = clients['sortAscending'];
      if (ascending is bool) _sortAscending = ascending;

      final customs = clients['customFilters'];
      if (customs is Map) {
        final next = <int, Set<String>>{};
        customs.forEach((key, value) {
          final idx = int.tryParse(key.toString());
          if (idx == null || idx < 1 || idx > 4) return;
          if (value is List) {
            final values = value.whereType<String>().toSet();
            if (values.isNotEmpty) next[idx] = values;
          }
        });
        _customFilters = next;
      }
    } catch (e, st) {
      // Treat a corrupt blob as "no saved filters" — better to fall back to
      // defaults than to crash the list screen.
      _log.warning('Failed to hydrate filters_json; using defaults', e, st);
    } finally {
      _hydrated = true;
    }
  }

  /// Pull-to-refresh / foreground-resume entry point. Pulls every state into
  /// the local cache so the user can flip filters without a re-fetch.
  Future<void> refresh() async {
    try {
      await repo.refreshAll(companyId: companyId);
    } catch (e) {
      _flashError('Refresh failed: $e');
    }
  }

  /// Called by the view's ScrollController when within ~600 px of the end.
  Future<void> loadMore() async {
    if (isLoadingPage || !hasMore) return;
    isLoadingPage = true;
    notifyListeners();
    try {
      final more = await repo.ensurePageLoaded(
        companyId: companyId,
        page: loadedPages + 1,
        search: _search.isEmpty ? null : _search,
        states: _states,
      );
      // Only widen the local watch window on a successful fetch.
      loadedPages += 1;
      hasMore = more;
    } catch (e) {
      _flashError("Couldn't load more: $e");
    } finally {
      isLoadingPage = false;
      notifyListeners();
    }
  }

  /// Debounced — the view calls this on every keystroke. Resets the
  /// pagination window so search results don't bleed across.
  void setSearch(String value) {
    final next = value.trim();
    if (next == _search) return;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () => _applySearch(next));
  }

  Future<void> _applySearch(String value) async {
    _search = value;
    await _resetAndReload(ignoreCursor: false);
  }

  /// Replace the selected entity states. Empty set snaps back to
  /// `{active}` with a "Showing active" transient notice — letting the user
  /// uncheck every box would otherwise yield a confusing empty list.
  ///
  /// Widening the set (adding a state we didn't previously have) re-pulls
  /// page 1 with `ignoreCursor: true` so the server returns rows of the new
  /// state — the cached cursor only covered the prior state set.
  Future<void> setStates(Set<EntityState> next) async {
    var effective = next;
    if (effective.isEmpty) {
      effective = const {EntityState.active};
      _transientNotice = 'Showing active';
    }
    if (setEquals(effective, _states)) return;
    final isWidening = effective.difference(_states).isNotEmpty;
    _states = Set.unmodifiable(effective);
    await _resetAndReload(ignoreCursor: isWidening);
  }

  /// Toggle a single entity state. Convenience wrapper around [setStates]
  /// for the pill-chip widget.
  void toggleState(EntityState s) {
    final next = Set<EntityState>.from(_states);
    if (!next.remove(s)) next.add(s);
    unawaited(setStates(next));
  }

  Future<void> setSort({
    required String field,
    required bool ascending,
  }) async {
    // Allowlist check: the DAO interpolates the id into `json_extract` for
    // payload-backed fields, so callers can't pass an arbitrary string.
    if (!clientColumnsById.containsKey(field)) return;
    if (field == _sortField && ascending == _sortAscending) return;
    _sortField = field;
    _sortAscending = ascending;
    await _resetAndReload(ignoreCursor: false);
  }

  /// Replace the selected values for one custom column (1..4). Empty set
  /// removes the filter from that column.
  Future<void> setCustomFilter({
    required int columnIndex,
    required Set<String> values,
  }) async {
    assert(columnIndex >= 1 && columnIndex <= 4);
    final next = Map<int, Set<String>>.from(_customFilters);
    if (values.isEmpty) {
      if (next.remove(columnIndex) == null) return;
    } else {
      if (setEquals(next[columnIndex], values)) return;
      next[columnIndex] = Set.unmodifiable(values);
    }
    _customFilters = Map.unmodifiable(next);
    await _resetAndReload(ignoreCursor: false);
  }

  /// Reset every filter to its default. Hits the same path as `setStates`
  /// — one network fetch, one persistence write.
  Future<void> clearAllFilters() async {
    final wasActive = hasActiveFilters;
    _search = '';
    _states = const {EntityState.active};
    _sortField = ClientFieldIds.name;
    _sortAscending = true;
    _customFilters = const {};
    if (!wasActive) return;
    await _resetAndReload(ignoreCursor: false);
  }

  /// Distinct custom-field values for column [columnIndex] in this company,
  /// for the bottom-sheet / dropdown to render as filter options.
  Stream<List<String>> watchCustomValueOptions(int columnIndex) =>
      repo.watchDistinctCustomValues(
        companyId: companyId,
        columnIndex: columnIndex,
      );

  Future<void> retryInitial() async {
    initialError = null;
    notifyListeners();
    await _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    isLoadingPage = true;
    notifyListeners();
    try {
      hasMore = await repo.ensurePageLoaded(
        companyId: companyId,
        page: 1,
        search: _search.isEmpty ? null : _search,
        states: _states,
      );
    } catch (e) {
      initialError = e.toString();
    } finally {
      isLoadingPage = false;
      notifyListeners();
    }
  }

  /// Shared "filter changed" path. Pagination resets to page 1, the watch
  /// stream re-subscribes with the new filter, `isLoadingPage=true` is set
  /// BEFORE resubscribing so the view doesn't flash the small intersection
  /// Drift emits between the old subscription cancelling and the new one
  /// catching up.
  Future<void> _resetAndReload({required bool ignoreCursor}) async {
    // Filter changes invalidate the selection — previously-selected rows may
    // fall outside the new visible window, which would later look like a
    // confusing "N skipped" in the bulk-action SnackBar.
    _selectedIds.clear();
    loadedPages = 1;
    hasMore = true;
    isLoadingPage = true;
    initialError = null;
    _resubscribe();
    notifyListeners();
    _schedulePersist();
    try {
      hasMore = await repo.ensurePageLoaded(
        companyId: companyId,
        page: 1,
        search: _search.isEmpty ? null : _search,
        states: _states,
        ignoreCursor: ignoreCursor,
      );
    } catch (e) {
      initialError = 'Failed to load: $e';
    } finally {
      isLoadingPage = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _watchSub = repo
        .watchPage(
          companyId: companyId,
          loadedPages: loadedPages,
          search: _search.isEmpty ? null : _search,
          states: _states,
          sortField: _sortField,
          sortAscending: _sortAscending,
          customFilters: _customFilters,
        )
        .listen(_onClients);
  }

  void _resubscribe() {
    _watchSub?.cancel();
    _subscribe();
  }

  void _onClients(List<Client> next) {
    _clients = next;
    notifyListeners();
  }

  void _schedulePersist() {
    if (!_hydrated) return; // don't write back over a fresh hydration race
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _persist);
  }

  Future<void> _persist() async {
    try {
      final row = await navStateDao.current();
      final existing = row?.filtersJson;
      Map<String, dynamic> doc;
      if (existing == null || existing.isEmpty) {
        doc = <String, dynamic>{};
      } else {
        final decoded = jsonDecode(existing);
        doc = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{}; // ignore prior shape if it's not an object
      }
      doc[companyId] = {
        'clients': {
          'search': _search,
          'states': _states.map((s) => s.name).toList(),
          'sortField': _sortField,
          'sortAscending': _sortAscending,
          'customFilters': {
            for (final entry in _customFilters.entries)
              entry.key.toString(): entry.value.toList(),
          },
        },
      };
      await navStateDao.saveFilters(
        filtersJson: jsonEncode(doc),
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      _log.warning('Failed to persist filters_json', e, st);
    }
  }

  String? _transientError;
  String? get transientError => _transientError;

  void _flashError(String message) {
    _transientError = message;
    notifyListeners();
    _transientError = null;
  }

  // ─── Multiselect / bulk actions ─────────────────────────────────────
  // Selection mode is entered by long-pressing any row. While in the mode,
  // the screen swaps the AppBar to a contextual one with bulk-action
  // buttons. The selection itself lives here so it survives a rebuild
  // (e.g. when search/filter changes the visible window).

  final Set<String> _selectedIds = <String>{};

  bool get isInMultiselect => _selectedIds.isNotEmpty;
  int get countSelected => _selectedIds.length;
  bool isSelected(String id) => _selectedIds.contains(id);

  bool _bulkInFlight = false;

  /// True while a `bulkArchive` / `bulkRestore` is mid-flight. The screen
  /// disables the action buttons so a double-tap can't fire the same op
  /// twice (which would double-archive and queue duplicate outbox rows).
  bool get bulkInFlight => _bulkInFlight;

  void toggleSelected(String id) {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  void selectAllVisible() {
    var changed = false;
    for (final c in _clients) {
      if (_selectedIds.add(c.id)) changed = true;
    }
    if (changed) notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  /// Archive every selected client that's not already archived/deleted.
  Future<({int ok, int skipped, int failed})> bulkArchive() {
    return _bulkApply(
      predicate: (c) => c.archivedAt == null && !c.isDeleted,
      op: (id) => repo.archive(companyId: companyId, id: id),
    );
  }

  /// Restore every selected client that is currently archived or deleted.
  Future<({int ok, int skipped, int failed})> bulkRestore() {
    return _bulkApply(
      predicate: (c) => c.archivedAt != null || c.isDeleted,
      op: (id) => repo.restore(companyId: companyId, id: id),
    );
  }

  // TODO(bulk-endpoint): swap the per-id loop for a single
  // `POST /clients/bulk` once the outbox/sync engine grows a bulk
  // `MutationKind` + apply path. The UX is identical either way; this is a
  // pure perf upgrade.
  Future<({int ok, int skipped, int failed})> _bulkApply({
    required bool Function(Client) predicate,
    required Future<void> Function(String id) op,
  }) async {
    // Reentrancy + empty-selection guard. The screen also disables the
    // action buttons while `bulkInFlight`, but a synchronous double-tap can
    // beat the rebuild — belt-and-braces.
    if (_bulkInFlight || _selectedIds.isEmpty) {
      return (ok: 0, skipped: 0, failed: 0);
    }
    _bulkInFlight = true;
    notifyListeners();

    try {
      // Snapshot the selection + visible rows so concurrent toggles or list
      // updates can't desync mid-flight.
      final selectedIds = Set<String>.from(_selectedIds);
      final byId = <String, Client>{for (final c in _clients) c.id: c};

      final eligible = <String>[];
      var skipped = 0;
      for (final id in selectedIds) {
        final client = byId[id];
        if (client == null) {
          // Out of the visible window — skip rather than fire a mutation we
          // can't pre-screen. Rare in practice.
          skipped++;
          continue;
        }
        if (predicate(client)) {
          eligible.add(id);
        } else {
          skipped++;
        }
      }

      var ok = 0;
      var failed = 0;
      final results = await Future.wait(
        eligible.map((id) async {
          try {
            await op(id);
            return true;
          } catch (e, st) {
            _log.warning('Bulk op failed for $id', e, st);
            return false;
          }
        }),
      );
      for (final success in results) {
        if (success) {
          ok++;
        } else {
          failed++;
        }
      }
      return (ok: ok, skipped: skipped, failed: failed);
    } finally {
      _bulkInFlight = false;
      // clearSelection in finally so it still runs if a future throws past
      // our per-id catch (it shouldn't, but defence in depth).
      _selectedIds.clear();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _persistTimer?.cancel();
    _watchSub?.cancel();
    _columnsSub?.cancel();
    super.dispose();
  }
}
