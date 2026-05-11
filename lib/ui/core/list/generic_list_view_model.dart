import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/dao/nav_state_dao.dart';
import 'package:admin/data/repositories/user_settings_repository.dart';
import 'package:admin/domain/columns/column_definition.dart';
import 'package:admin/domain/entity_state.dart';
import 'package:admin/domain/entity_type.dart';

final _log = Logger('GenericListViewModel');

/// One bulk operation entity list screens expose to the user (Archive,
/// Restore, Delete, future per-entity actions like "Mark Sent"). Each entity
/// declares its own set; the screen lays them out as the multiselect-AppBar
/// buttons and the generic base applies them via [GenericListViewModel.applyBulkAction].
@immutable
class BulkAction<T> {
  const BulkAction({
    required this.id,
    required this.labelKey,
    required this.eligible,
    required this.apply,
    this.requiresPassword = false,
  });

  /// Stable identifier used for logging + analytics (`archive`, `restore`,
  /// `mark_sent`). Not user-facing.
  final String id;

  /// Localization key for the user-facing label rendered on the AppBar button.
  /// Resolve via `context.tr(action.labelKey)`.
  final String labelKey;

  /// True when [item] is in a state where this action is legal. The base VM
  /// uses this to bucket the selection into eligible/skipped before firing
  /// the per-id mutations.
  final bool Function(T item) eligible;

  /// Per-id apply function — the concrete subclass binds this to its repo
  /// (e.g. `(id) => repo.archive(companyId: companyId, id: id)`).
  final Future<void> Function(String id) apply;

  /// True when the server requires `X-API-PASSWORD-BASE64`. Surfaced via
  /// the standard `ConfirmPasswordSheet` flow at the call site — the base VM
  /// just forwards the flag.
  final bool requiresPassword;
}

/// Generic list-screen ViewModel. Owns pagination, search, sort, filter,
/// multiselect, column selection, and the nav_state filter-persistence
/// machinery. Concrete subclasses (`ClientListViewModel`,
/// `InvoiceListViewModel`, …) plug in:
///   * the entity type + entity-specific column registry
///   * the repository calls (`fetchPage`, `watchPage`, `archive`, ...)
///   * the entity-specific eligibility predicates (via [bulkActions])
///   * the id / archived-at / is-deleted extractors
///
/// The base persists filters under `nav_state.filters_json` at
/// `companyId → <entityType.name> → {...}` so the shape lives in exactly one
/// place. Adding a new entity inherits restore-where-you-left-off for free.
abstract class GenericListViewModel<T> extends ChangeNotifier {
  GenericListViewModel({
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
    _sortField = defaultSortField;
    _columnIds = List<String>.from(defaultColumnIds);
    unawaited(_init());
  }

  // ── Configuration (provided by concrete subclasses) ─────────────────

  /// The entity this VM lists. Used as the persistence sub-key and the
  /// user-settings entity discriminator. Must match the value the entity
  /// declares in [EntityRegistry].
  EntityType get entityType;

  /// Every column the entity knows how to render — used by the column-picker
  /// and to validate persisted sort fields. Mirrors `kAllClientColumns`.
  List<ColumnDefinition<T>> get allColumns;

  /// Columns shown when the user has never customised. Order matters.
  /// Mirrors `kDefaultClientColumns`.
  List<String> get defaultColumnIds;

  /// Column the list sorts by when no persisted preference exists. Must be
  /// a key in [allColumns].
  String get defaultSortField;

  /// True when [field] is a column id this entity recognises. The base uses
  /// this both as a sort-allowlist check and during hydration so a stale
  /// persisted blob can't drive the DAO with a garbage column id.
  bool isValidColumnId(String field);

  /// Extract the entity's id (real or `tmp_`). Used by the multiselect set.
  String idOf(T item);

  /// `true` when the entity is active (eligible for "Archive"). The base
  /// uses this only for [hasActiveFilters] / debug — the per-action
  /// eligibility check lives on [BulkAction.eligible].
  bool isArchived(T item);
  bool isDeleted(T item);

  // ── Data-source hooks (provided by concrete subclasses) ─────────────

  /// Watch the first `loadedPages` worth of rows under the current filter
  /// state. Called whenever filters change; the base owns the subscription
  /// lifecycle.
  Stream<List<T>> watchPage();

  /// Fetch one page from the server and upsert into Drift. Returns true
  /// when more pages may exist.
  Future<bool> fetchPage({
    required int page,
    required String? search,
    required Set<EntityState> states,
    required bool ignoreCursor,
  });

  /// Pull-to-refresh entry point.
  Future<void> refreshAll();

  /// Distinct non-empty values for the `customValue<columnIndex>` column,
  /// used by the custom-filter dropdown.
  Stream<List<String>> watchDistinctCustomValues(int columnIndex);

  /// Bulk actions the entity exposes. Each entity declares its own; the
  /// base renders / applies them generically.
  Iterable<BulkAction<T>> get bulkActions;

  // ── Inputs ──────────────────────────────────────────────────────────

  final String companyId;
  final NavStateDao navStateDao;
  final UserSettingsRepository userSettings;
  final Duration _searchDebounce;
  final Duration _persistDebounce;
  final DateTime Function() _now;

  // ── State (read by the view) ────────────────────────────────────────

  int loadedPages = 1;
  bool hasMore = true;
  bool isLoadingPage = false;
  String? initialError;

  String _search = '';
  String get search => _search;

  Set<EntityState> _states = const {EntityState.active};
  Set<EntityState> get states => _states;

  late String _sortField;
  String get sortField => _sortField;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  Map<int, Set<String>> _customFilters = const {};
  Map<int, Set<String>> get customFilters => _customFilters;

  List<T> _items = const [];
  List<T> get items => _items;

  late List<String> _columnIds;
  List<ColumnDefinition<T>> get columns => _resolveColumns(_columnIds);
  List<String> get columnIds => List.unmodifiable(_columnIds);

  String? _transientNotice;
  String? get transientError => _transientError;
  String? _transientError;

  String? consumeTransientNotice() {
    final n = _transientNotice;
    _transientNotice = null;
    return n;
  }

  /// True when any filter is non-default. Drives the "active filters" strip
  /// and the filtered-empty-state copy.
  bool get hasActiveFilters {
    if (_states.length != 1 || !_states.contains(EntityState.active)) {
      return true;
    }
    if (_sortField != defaultSortField || !_sortAscending) return true;
    for (final values in _customFilters.values) {
      if (values.isNotEmpty) return true;
    }
    return _search.isNotEmpty;
  }

  // ── Internals ───────────────────────────────────────────────────────

  StreamSubscription<List<T>>? _watchSub;
  StreamSubscription<List<String>?>? _columnsSub;
  Timer? _searchTimer;
  Timer? _persistTimer;
  bool _hydrated = false;

  Future<void> _init() async {
    await _hydrate();
    _subscribeColumns();
    _subscribe();
    await _loadInitialPage();
  }

  void _subscribeColumns() {
    _columnsSub = userSettings
        .watchColumns(companyId: companyId, entityType: entityType)
        .listen((ids) {
          final next = ids == null || ids.isEmpty
              ? List<String>.from(defaultColumnIds)
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
      final entity = company[entityType.name];
      if (entity is! Map) return;

      final search = entity['search'];
      if (search is String) _search = search;

      final statesList = entity['states'];
      if (statesList is List) {
        final hydrated = <EntityState>{};
        for (final name in statesList) {
          for (final s in EntityState.values) {
            if (s.name == name) hydrated.add(s);
          }
        }
        _states = hydrated;
      }

      final sortField = entity['sortField'];
      if (sortField is String && isValidColumnId(sortField)) {
        _sortField = sortField;
      }

      final ascending = entity['sortAscending'];
      if (ascending is bool) _sortAscending = ascending;

      final customs = entity['customFilters'];
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

  // ── Public actions ──────────────────────────────────────────────────

  Future<void> refresh() async {
    try {
      await refreshAll();
    } catch (e) {
      // Store just the raw error — the UI looks up
      // `refresh_failed_with_error` and substitutes `:error` at render time.
      _flashError(e.toString());
    }
  }

  Future<void> loadMore() async {
    if (isLoadingPage || !hasMore) return;
    isLoadingPage = true;
    notifyListeners();
    try {
      final more = await fetchPage(
        page: loadedPages + 1,
        search: _search.isEmpty ? null : _search,
        states: _states,
        ignoreCursor: false,
      );
      loadedPages += 1;
      hasMore = more;
    } catch (e) {
      _flashError("Couldn't load more: $e");
    } finally {
      isLoadingPage = false;
      notifyListeners();
    }
  }

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

  Future<void> setStates(Set<EntityState> next) async {
    if (setEquals(next, _states)) return;
    final isWidening = next.isEmpty || next.difference(_states).isNotEmpty;
    _states = Set.unmodifiable(next);
    await _resetAndReload(ignoreCursor: isWidening);
  }

  void toggleState(EntityState s) {
    final next = Set<EntityState>.from(_states);
    if (!next.remove(s)) next.add(s);
    unawaited(setStates(next));
  }

  Future<void> setSort({required String field, required bool ascending}) async {
    if (!isValidColumnId(field)) return;
    if (field == _sortField && ascending == _sortAscending) return;
    _sortField = field;
    _sortAscending = ascending;
    await _resetAndReload(ignoreCursor: false);
  }

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

  Future<void> clearAllFilters() async {
    final wasActive = hasActiveFilters;
    _search = '';
    _states = const {EntityState.active};
    _sortField = defaultSortField;
    _sortAscending = true;
    _customFilters = const {};
    if (!wasActive) return;
    await _resetAndReload(ignoreCursor: false);
  }

  Stream<List<String>> watchCustomValueOptions(int columnIndex) =>
      watchDistinctCustomValues(columnIndex);

  Future<void> setColumns(List<String> ids) async {
    final next = List<String>.unmodifiable(ids);
    if (listEquals(next, _columnIds)) return;
    _columnIds = next;
    notifyListeners();
    await userSettings.setColumns(
      companyId: companyId,
      entityType: entityType,
      columns: next,
    );
  }

  Future<void> resetColumns() async {
    _columnIds = List<String>.from(defaultColumnIds);
    notifyListeners();
    await userSettings.resetColumns(
      companyId: companyId,
      entityType: entityType,
    );
  }

  Future<void> retryInitial() async {
    initialError = null;
    notifyListeners();
    await _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    isLoadingPage = true;
    notifyListeners();
    try {
      hasMore = await fetchPage(
        page: 1,
        search: _search.isEmpty ? null : _search,
        states: _states,
        ignoreCursor: false,
      );
    } catch (e) {
      initialError = e.toString();
    } finally {
      isLoadingPage = false;
      notifyListeners();
    }
  }

  Future<void> _resetAndReload({required bool ignoreCursor}) async {
    _selectedIds.clear();
    loadedPages = 1;
    hasMore = true;
    isLoadingPage = true;
    initialError = null;
    _resubscribe();
    notifyListeners();
    _schedulePersist();
    try {
      hasMore = await fetchPage(
        page: 1,
        search: _search.isEmpty ? null : _search,
        states: _states,
        ignoreCursor: ignoreCursor,
      );
    } catch (e) {
      // Store the raw error message; the UI prepends a localized
      // "Failed to load:" prefix when rendering.
      initialError = e.toString();
    } finally {
      isLoadingPage = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _watchSub = watchPage().listen(_onItems);
  }

  void _resubscribe() {
    _watchSub?.cancel();
    _subscribe();
  }

  void _onItems(List<T> next) {
    _items = next;
    notifyListeners();
  }

  void _schedulePersist() {
    if (!_hydrated) return;
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
        doc = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      }
      final companyBlob = doc[companyId];
      final companyMap = companyBlob is Map<String, dynamic>
          ? Map<String, dynamic>.from(companyBlob)
          : <String, dynamic>{};
      companyMap[entityType.name] = {
        'search': _search,
        'states': _states.map((s) => s.name).toList(),
        'sortField': _sortField,
        'sortAscending': _sortAscending,
        'customFilters': {
          for (final entry in _customFilters.entries)
            entry.key.toString(): entry.value.toList(),
        },
      };
      doc[companyId] = companyMap;
      await navStateDao.saveFilters(
        filtersJson: jsonEncode(doc),
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      _log.warning('Failed to persist filters_json', e, st);
    }
  }

  void _flashError(String message) {
    _transientError = message;
    notifyListeners();
    _transientError = null;
  }

  List<ColumnDefinition<T>> _resolveColumns(List<String> ids) {
    final byId = {for (final c in allColumns) c.id: c};
    final out = <ColumnDefinition<T>>[];
    for (final id in ids) {
      final col = byId[id];
      if (col != null) out.add(col);
    }
    return out;
  }

  /// Localization key for a column id, or the id itself if the registry
  /// doesn't recognise it (so a stale persisted value stays readable in
  /// active-filter chips). Used by [EntityActiveFiltersStrip] and tests —
  /// resolve via `context.tr(vm.columnLabelKeyById(id))` at render time.
  String columnLabelKeyById(String id) {
    for (final c in allColumns) {
      if (c.id == id) return c.labelKey;
    }
    return id;
  }

  // ── Multiselect / bulk actions ──────────────────────────────────────

  final Set<String> _selectedIds = <String>{};

  bool get isInMultiselect => _selectedIds.isNotEmpty;
  int get countSelected => _selectedIds.length;
  bool isSelected(String id) => _selectedIds.contains(id);

  bool _bulkInFlight = false;
  bool get bulkInFlight => _bulkInFlight;

  void toggleSelected(String id) {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  void selectAllVisible() {
    var changed = false;
    for (final item in _items) {
      if (_selectedIds.add(idOf(item))) changed = true;
    }
    if (changed) notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) return;
    _selectedIds.clear();
    notifyListeners();
  }

  /// Apply a [BulkAction] to every currently-selected entity that satisfies
  /// its predicate. Rows that are out of the visible window are counted as
  /// `skipped`; per-id failures bump `failed`. Selection is cleared on exit.
  Future<({int ok, int skipped, int failed})> applyBulkAction(
    BulkAction<T> action,
  ) async {
    if (_bulkInFlight || _selectedIds.isEmpty) {
      return (ok: 0, skipped: 0, failed: 0);
    }
    _bulkInFlight = true;
    notifyListeners();

    try {
      final selectedIds = Set<String>.from(_selectedIds);
      final byId = <String, T>{for (final item in _items) idOf(item): item};

      final eligible = <String>[];
      var skipped = 0;
      for (final id in selectedIds) {
        final item = byId[id];
        if (item == null) {
          skipped++;
          continue;
        }
        if (action.eligible(item)) {
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
            await action.apply(id);
            return true;
          } catch (e, st) {
            _log.warning('Bulk op ${action.id} failed for $id', e, st);
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
      _selectedIds.clear();
      notifyListeners();
    }
  }

  /// Lookup a bulk action by id — convenience for entities that expose
  /// keyed actions on the screen (e.g. an `archive` button that just looks
  /// up the registered `BulkAction.id == 'archive'`).
  BulkAction<T>? bulkActionById(String id) {
    for (final a in bulkActions) {
      if (a.id == id) return a;
    }
    return null;
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
