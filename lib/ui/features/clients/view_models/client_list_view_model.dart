import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/domain/client.dart';
import '../../../../data/repositories/client_repository.dart';

/// Drives the read-only Clients list screen.
///
/// Owns three pieces of state the view binds to:
///   * [clients] — current Drift-emitted page contents (1..[loadedPages]).
///   * [isLoadingPage] — true while a network page is in flight.
///   * [initialError] — non-null after the first page fails (for `ErrorView`).
///
/// All API access goes through [ClientRepository]; the network never writes
/// to UI state directly. Each user action either triggers an `ensurePage…`
/// call or adjusts the watched window — the Drift stream pushes the result
/// back in via [_onClients].
class ClientListViewModel extends ChangeNotifier {
  ClientListViewModel({
    required this.repo,
    required this.companyId,
    Duration searchDebounce = const Duration(milliseconds: 250),
  }) : _searchDebounce = searchDebounce {
    _subscribe();
    unawaited(_loadInitialPage());
  }

  final ClientRepository repo;
  final String companyId;
  final Duration _searchDebounce;

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

  List<Client> _clients = const [];
  List<Client> get clients => _clients;

  StreamSubscription<List<Client>>? _watchSub;
  Timer? _searchTimer;

  /// Pull-to-refresh / foreground-resume entry point.
  Future<void> refresh() async {
    try {
      await repo.refreshAll(companyId: companyId);
    } catch (e) {
      // Refresh failures don't blow away the existing local data; the
      // screen just shows what we have. The SnackBar surfaces detail.
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
      );
      // Only widen the local watch window on a successful fetch.
      loadedPages += 1;
      hasMore = more;
    } catch (e) {
      _flashError('Couldn\'t load more: $e');
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
    loadedPages = 1;
    hasMore = true;
    _resubscribe();
    isLoadingPage = true;
    initialError = null;
    notifyListeners();
    try {
      hasMore = await repo.ensurePageLoaded(
        companyId: companyId,
        page: 1,
        search: _search.isEmpty ? null : _search,
      );
    } catch (e) {
      initialError = 'Search failed: $e';
    } finally {
      isLoadingPage = false;
      notifyListeners();
    }
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
      hasMore = await repo.ensurePageLoaded(
        companyId: companyId,
        page: 1,
        search: _search.isEmpty ? null : _search,
      );
    } catch (e) {
      initialError = e.toString();
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

  String? _transientError;
  String? get transientError => _transientError;

  void _flashError(String message) {
    _transientError = message;
    notifyListeners();
    // Consumers can read once then clear; clearing is a no-op the next
    // notify swallows. Kept simple — no separate Stream needed for M1.10a.
    _transientError = null;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _watchSub?.cancel();
    super.dispose();
  }
}
