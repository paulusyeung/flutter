import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';

/// Enforces the per-company **idle session timeout** (Account → Security →
/// "Web Session Timeout", stored as `company.sessionTimeout` in ms; `0` =
/// Never). The setting UI + persistence already existed; this is the missing
/// enforcement: after the configured span of no user interaction the session
/// is logged out (the router then redirects to `/login`).
///
/// Design mirrors [SyncLifecycleObserver]/[PasswordCacheLifecycleObserver]:
/// the controller owns only timing state; the actual work delegates to
/// [AuthRepository.logout]. Activity is fed in via [poke] (wired to a
/// root-level `Listener` in `main.dart`); a low-frequency periodic check
/// compares elapsed-since-last-activity against the timeout so pointer
/// events stay cheap. App-resume runs the check immediately so time spent
/// backgrounded counts toward the timeout.
class IdleTimeoutController with WidgetsBindingObserver {
  IdleTimeoutController({
    required this.auth,
    required this.company,
    DateTime Function() now = DateTime.now,
  }) : _now = now {
    _lastActivity = _now();
    auth.session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  final AuthRepository auth;
  final CompanyRepository company;
  final DateTime Function() _now;

  StreamSubscription<void>? _companySub;
  Timer? _ticker;
  DateTime _lastActivity = DateTime.fromMillisecondsSinceEpoch(0);
  int _timeoutMs = 0;
  String? _watchedCompanyId;

  /// Record user activity. Cheap — just stamps the clock; the periodic
  /// [_check] reads it. Safe to call on every pointer event.
  void poke() => _lastActivity = _now();

  void _onSessionChanged() {
    final id = auth.session.value?.currentCompanyId;
    if (id == null || id.isEmpty) {
      _disable();
      return;
    }
    if (id == _watchedCompanyId) return;
    _watchedCompanyId = id;
    _companySub?.cancel();
    _companySub = company.watchCompany(id).listen((c) {
      _timeoutMs = c?.sessionTimeout ?? 0;
      _rearm();
    });
  }

  void _disable() {
    _watchedCompanyId = null;
    _companySub?.cancel();
    _companySub = null;
    _ticker?.cancel();
    _ticker = null;
    _timeoutMs = 0;
  }

  void _rearm() {
    _ticker?.cancel();
    if (_timeoutMs <= 0) {
      _ticker = null;
      return;
    }
    // Reset the activity clock when (re)arming so a freshly-loaded or
    // changed timeout doesn't fire against stale inactivity.
    _lastActivity = _now();
    // Check often enough to be timely without being chatty: at most every
    // 30 s, at least every 5 s, never longer than the timeout itself.
    final intervalMs = _timeoutMs.clamp(5000, 30000);
    _ticker = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _check(),
    );
  }

  void _check() {
    if (_timeoutMs <= 0) return;
    if (auth.session.value == null) return;
    final idleMs = _now().difference(_lastActivity).inMilliseconds;
    if (idleMs < _timeoutMs) return;
    // Expired. Stop the ticker first so a slow logout can't double-fire,
    // then log out (fire-and-forget — lifecycle/timer callbacks must never
    // throw; the router redirects to /login when the session clears).
    _ticker?.cancel();
    _ticker = null;
    unawaited(auth.logout());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Time spent backgrounded counts as idle — check immediately on resume
    // rather than waiting for the next tick.
    _check();
  }

  void dispose() {
    auth.session.removeListener(_onSessionChanged);
    _companySub?.cancel();
    _ticker?.cancel();
  }
}
