import 'dart:async';

import 'package:logging/logging.dart';

import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/domain/sync/refresh_sync_constants.dart';

final _log = Logger('RefreshScheduler');

/// Foreground delta-refresh pump. While the app is active and authenticated
/// it fires `auth.refresh()` (a cheap `updated_at` delta after the first
/// full snapshot) every [kRefreshInterval], plus once on app-resume, so the
/// 13 bundled reference entities + auth/company/settings stay current without
/// the user touching anything. Mirrors the legacy admin-portal's 5-minute
/// `Timer.periodic` + resume refresh.
///
/// Not a [WidgetsBindingObserver] itself — lifecycle transitions are routed
/// in by `SyncLifecycleObserver` (one observer, one place) via [start] /
/// [stop] / [triggerNow]. Owned by `Services`; [stop] is chained into
/// `auth.onBeforeLogout` and [start] into `auth.onActiveCompanyChanged`.
class RefreshScheduler {
  RefreshScheduler({required AuthRepository auth, DateTime Function()? now})
    : _auth = auth,
      _now = now ?? DateTime.now;

  final AuthRepository _auth;
  final DateTime Function() _now;

  Timer? _timer;
  Future<void>? _inFlight;
  int _lastRefreshMs = 0;

  /// Begin (or keep) the periodic pump. Idempotent — repeated calls (login,
  /// company switch, resume) reuse the existing timer.
  void start() {
    // Fire-and-forget by design: `_tick` is internally gated + never throws
    // (`.catchError`). `unawaited` makes that explicit and satisfies the
    // codebase's discarded-future lint.
    _timer ??= Timer.periodic(kRefreshInterval, (_) => unawaited(_tick()));
  }

  /// Halt the pump. Called on logout and when the app backgrounds; a timer
  /// must never fire a network refresh while the user is signed out or away.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Deterministically cancel the timer on app teardown — mirrors
  /// `IdleTimeoutController.dispose()`. Just [stop]; there's no other state.
  void dispose() => stop();

  /// Immediate delta refresh on app-resume, subject to the same gating as a
  /// timer tick (min-gap, single-flight, authenticated).
  Future<void> triggerNow() => _tick();

  Future<void> _tick() async {
    if (!_auth.isAuthenticated) return;
    if (_inFlight != null) return; // single-flight
    final nowMs = _now().millisecondsSinceEpoch;
    if (nowMs - _lastRefreshMs < kMinRefreshGap.inMilliseconds) return;

    final future = _auth
        .refresh() // delta (fullSync:false) — cheap by design
        .catchError((Object e, StackTrace st) {
          // A scheduler tick must never throw (offline / 401-in-flight /
          // parse blip). The next tick retries; a real 401 already routes
          // through ApiClient → logout independently.
          _log.fine('scheduled refresh skipped', e, st);
        })
        .whenComplete(() {
          _lastRefreshMs = _now().millisecondsSinceEpoch;
          _inFlight = null;
        });
    _inFlight = future;
    await future;
  }
}
