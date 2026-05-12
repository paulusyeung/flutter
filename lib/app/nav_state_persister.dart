import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';

final _log = Logger('NavStatePersister');

/// Watches the active route and persists it to `nav_state.current_route` so
/// the next launch lands on the same screen.
///
/// Decoupled from [GoRouter] for testability: takes a [Listenable] that
/// fires on each navigation and a `currentPath` callback that reads the
/// current location. The default factory [NavStatePersister.fromRouter]
/// wires it up to a [GoRouter].
///
/// Writes are debounced — rapid navigation (tapping through a list) produces
/// one write at the trailing edge. The `/login` route is filtered out so we
/// don't overwrite a previously-stored deep link during logout transitions.
class NavStatePersister {
  NavStatePersister({
    required Listenable changes,
    required String Function() currentPath,
    required this.db,
    Duration debounce = const Duration(milliseconds: 500),
    DateTime Function()? now,
  }) : _changes = changes,
       _currentPath = currentPath,
       _debounce = debounce,
       _now = now ?? DateTime.now {
    _changes.addListener(_onChange);
  }

  /// Convenience: build the persister bound to a [GoRouter].
  factory NavStatePersister.fromRouter({
    required GoRouter router,
    required AppDatabase db,
    Duration debounce = const Duration(milliseconds: 500),
    DateTime Function()? now,
  }) {
    return NavStatePersister(
      changes: router.routerDelegate,
      currentPath: () =>
          router.routerDelegate.currentConfiguration.uri.toString(),
      db: db,
      debounce: debounce,
      now: now,
    );
  }

  final Listenable _changes;
  final String Function() _currentPath;
  final AppDatabase db;
  final Duration _debounce;
  final DateTime Function() _now;

  Timer? _timer;
  String? _lastPersisted;

  void _onChange() {
    final uri = _currentPath();
    if (uri == _lastPersisted) return;
    if (uri == '/login') return; // never overwrite a deep link with /login
    // /lock is transient — a cold launch that hits the biometric gate will
    // route there via redirect, not from a saved nav state. Persisting it
    // would also poison the `?from=` round-trip in the router.
    if (uri == '/lock' || uri.startsWith('/lock?')) return;
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(_flush(uri)));
  }

  Future<void> _flush(String uri) async {
    _lastPersisted = uri;
    await db.navStateDao.saveRoute(
      route: uri,
      now: _now().millisecondsSinceEpoch,
    );
    _log.finer('persisted route=$uri');
  }

  void dispose() {
    _timer?.cancel();
    _changes.removeListener(_onChange);
  }
}
