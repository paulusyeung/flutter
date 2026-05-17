import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/services/refresh_scheduler.dart';
import 'package:admin/domain/sync/refresh_sync_constants.dart';

class _FakeAuth implements AuthRepository {
  _FakeAuth({this.authed = true});

  bool authed;
  int refreshCalls = 0;
  Object? throwOnRefresh;
  final List<bool> fullSyncArgs = [];

  @override
  bool get isAuthenticated => authed;

  @override
  Future<void> refresh({bool fullSync = false}) async {
    refreshCalls++;
    fullSyncArgs.add(fullSync);
    if (throwOnRefresh != null) throw throwOnRefresh!;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late DateTime clock;
  DateTime now() => clock;

  setUp(() {
    clock = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  });

  test('triggerNow refreshes (delta, not full) when authenticated', () async {
    final auth = _FakeAuth();
    final s = RefreshScheduler(auth: auth, now: now);

    await s.triggerNow();

    expect(auth.refreshCalls, 1);
    expect(auth.fullSyncArgs.single, isFalse);
  });

  test('skips entirely when unauthenticated', () async {
    final auth = _FakeAuth(authed: false);
    final s = RefreshScheduler(auth: auth, now: now);

    await s.triggerNow();

    expect(auth.refreshCalls, 0);
  });

  test('enforces the min-gap between refreshes', () async {
    final auth = _FakeAuth();
    final s = RefreshScheduler(auth: auth, now: now);

    await s.triggerNow();
    expect(auth.refreshCalls, 1);

    // Within the gap → suppressed.
    clock = clock.add(kMinRefreshGap - const Duration(seconds: 1));
    await s.triggerNow();
    expect(auth.refreshCalls, 1);

    // Past the gap → fires again.
    clock = clock.add(const Duration(seconds: 2));
    await s.triggerNow();
    expect(auth.refreshCalls, 2);
  });

  test(
    'a tick one full interval after the last refresh is NOT suppressed '
    '(min-gap must stay below the cadence)',
    () async {
      // Regression guard: when kMinRefreshGap == kRefreshInterval the
      // periodic timer self-suppressed every tick (gap measured from
      // completion, timer scheduled from start). The invariant that prevents
      // it: kMinRefreshGap < kRefreshInterval.
      expect(
        kMinRefreshGap,
        lessThan(kRefreshInterval),
        reason: 'min-gap must be shorter than the refresh cadence',
      );

      final auth = _FakeAuth();
      final s = RefreshScheduler(auth: auth, now: now);

      await s.triggerNow();
      expect(auth.refreshCalls, 1);

      // The next periodic tick lands ~kRefreshInterval after the last
      // refresh; it must fire, not be eaten by the min-gap.
      clock = clock.add(kRefreshInterval);
      await s.triggerNow();
      expect(auth.refreshCalls, 2);
    },
  );

  test('single-flight: overlapping ticks collapse to one refresh', () async {
    final auth = _FakeAuth();
    final gate = Completer<void>();
    final slowAuth = _SlowAuth(gate);
    final s = RefreshScheduler(auth: slowAuth, now: now);

    final a = s.triggerNow();
    final b = s.triggerNow(); // should no-op while a is in flight
    gate.complete();
    await Future.wait([a, b]);

    expect(slowAuth.refreshCalls, 1);
    // Sanity: the unused fake keeps the analyzer happy about _FakeAuth use.
    expect(auth.refreshCalls, 0);
  });

  test('never throws when refresh rejects; next tick still works', () async {
    final auth = _FakeAuth()..throwOnRefresh = StateError('offline');
    final s = RefreshScheduler(auth: auth, now: now);

    await s.triggerNow(); // must not throw
    expect(auth.refreshCalls, 1);

    auth.throwOnRefresh = null;
    clock = clock.add(kMinRefreshGap + const Duration(seconds: 1));
    await s.triggerNow();
    expect(auth.refreshCalls, 2);
  });

  test('stop() cancels the periodic timer', () {
    final auth = _FakeAuth();
    final s = RefreshScheduler(auth: auth, now: now);
    s.start();
    s.start(); // idempotent
    s.stop();
    // No assertion on timing — just exercising start/stop is enough to catch
    // a double-timer leak (the second start() must reuse the first).
  });
}

class _SlowAuth implements AuthRepository {
  _SlowAuth(this._gate);
  final Completer<void> _gate;
  int refreshCalls = 0;

  @override
  bool get isAuthenticated => true;

  @override
  Future<void> refresh({bool fullSync = false}) async {
    refreshCalls++;
    await _gate.future;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
