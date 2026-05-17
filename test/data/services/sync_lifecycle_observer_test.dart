import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/sync_repository.dart';
import 'package:admin/data/services/refresh_scheduler.dart';
import 'package:admin/data/services/sync_lifecycle_observer.dart';

class _FakeAuth implements AuthRepository {
  final _session = ValueNotifier<AuthSession?>(
    const AuthSession(
      baseUrl: 'https://t',
      isHosted: false,
      accountId: 'acct',
      companies: [],
      currentCompanyId: 'co-A',
      plan: 'pro',
    ),
  );

  @override
  ValueListenable<AuthSession?> get session => _session;

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSync implements SyncRepository {
  final List<String> drained = [];

  @override
  Future<int> drainOnce({required String companyId}) async {
    drained.add(companyId);
    return 0;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Records scheduler calls without a real Timer.
class _SpyScheduler extends RefreshScheduler {
  _SpyScheduler() : super(auth: _FakeAuth());
  int starts = 0;
  int stops = 0;
  int triggers = 0;

  @override
  void start() => starts++;
  @override
  void stop() => stops++;
  @override
  Future<void> triggerNow() async => triggers++;
}

void main() {
  late _FakeAuth auth;
  late _FakeSync sync;
  late _SpyScheduler scheduler;
  late SyncLifecycleObserver obs;

  setUp(() {
    auth = _FakeAuth();
    sync = _FakeSync();
    scheduler = _SpyScheduler();
    obs = SyncLifecycleObserver(
      auth: auth,
      sync: sync,
      refreshScheduler: scheduler,
    );
  });

  test('inactive does NOT stop the scheduler (iOS transient blip)', () {
    obs.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(scheduler.stops, 0);
  });

  test('hidden does NOT stop the scheduler', () {
    obs.didChangeAppLifecycleState(AppLifecycleState.hidden);
    expect(scheduler.stops, 0);
  });

  test('paused stops the scheduler', () {
    obs.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(scheduler.stops, 1);
  });

  test('detached stops the scheduler', () {
    obs.didChangeAppLifecycleState(AppLifecycleState.detached);
    expect(scheduler.stops, 1);
  });

  test('resumed drains, triggers, and (re)starts the scheduler', () {
    obs.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(sync.drained, ['co-A']);
    expect(scheduler.triggers, 1);
    expect(scheduler.starts, 1);
    expect(scheduler.stops, 0);
  });

  test('resumed with no active company is a no-op', () {
    auth._session.value = null;
    obs.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(sync.drained, isEmpty);
    expect(scheduler.triggers, 0);
    expect(scheduler.starts, 0);
  });
}
