import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/idle_timeout_controller.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/company_repository.dart';
import 'package:admin/data/repositories/sync_repository.dart';

/// Unit tests for the idle-timeout preserve-vs-wipe DECISION
/// ([IdleTimeoutController.shouldPreserveOnTimeout]). This is the load-bearing
/// branch that decides whether an idle timeout keeps the user's unsynced offline
/// edits (re-lock) or does a destructive full logout. A regression here would
/// silently destroy offline work, so it is pinned directly.
///
/// The controller takes concrete repos; a `null` session keeps construction
/// inert (no company watch) so the decision method — which only reads `sync` —
/// can be exercised with a single fake.
void main() {
  late _FakeAuth auth;
  late _FakeCompany company;
  late _FakeSync sync;
  late IdleTimeoutController controller;

  setUp(() {
    auth = _FakeAuth();
    company = _FakeCompany();
    sync = _FakeSync();
    controller = IdleTimeoutController(
      auth: auth,
      company: company,
      sync: sync,
      now: () => DateTime.utc(2026),
    );
  });

  tearDown(() => controller.dispose());

  group('shouldPreserveOnTimeout', () {
    test('preserves when the active company has pending outbox rows', () async {
      sync.pending = 3;
      expect(await controller.shouldPreserveOnTimeout('co1'), isTrue);
    });

    test(
      'does NOT preserve (clean full logout) when nothing is pending',
      () async {
        sync.pending = 0;
        expect(await controller.shouldPreserveOnTimeout('co1'), isFalse);
      },
    );

    test('errs toward preserving when the pending-count read throws', () async {
      sync.throwOnCount = true;
      expect(await controller.shouldPreserveOnTimeout('co1'), isTrue);
    });

    test('does NOT preserve when there is no active company', () async {
      sync.pending = 5; // would preserve if a company were active
      expect(await controller.shouldPreserveOnTimeout(null), isFalse);
      expect(await controller.shouldPreserveOnTimeout(''), isFalse);
    });
  });
}

class _FakeAuth implements AuthRepository {
  // A null session makes the controller's constructor inert (it disables itself
  // without touching `company`), so the decision method can be tested alone.
  @override
  final ValueNotifier<AuthSession?> session = ValueNotifier<AuthSession?>(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCompany implements CompanyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSync implements SyncRepository {
  int pending = 0;
  bool throwOnCount = false;

  @override
  Future<int> pendingCountFor(String companyId) async {
    if (throwOnCount) throw StateError('pending count unavailable');
    return pending;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
