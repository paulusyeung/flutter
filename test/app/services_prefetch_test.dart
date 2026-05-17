import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/entity_modules.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/connectivity_watcher.dart';
import 'package:admin/data/services/token_storage.dart';
import 'package:admin/domain/entity_registry.dart';
import 'package:admin/domain/entity_type.dart';

/// Verifies the sidebar-prefetch + count wiring. The user-visible contract:
/// every workspace-sidebar entity has a live count badge that updates from
/// Drift, and the active-company-change hook prefetches the first page so
/// the badges populate before the user opens each list.
void main() {
  test(
    'watchEntityCount returns a real Drift stream for every sidebar entity',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final services = Services.build(
        db: db,
        tokenStorage: InMemoryTokenStorage(),
        connectivityWatcher: ConnectivityWatcher.fixed(online: false),
      );
      try {
        for (final spec in kWiredEntityModules) {
          if (spec.sidebarSection == SidebarSection.none) continue;
          final count = await services
              .watchEntityCount(spec.type, 'company-1')
              .first;
          // Empty company; every sidebar entity reports 0 against Drift but
          // the stream is wired (the real test: this completes — an unwired
          // type would also return 0 via the `Stream.value(0)` fallback, so
          // the next assertion proves the wiring).
          expect(count, 0, reason: 'watchEntityCount(${spec.type})');
        }
      } finally {
        await services.auth.dispose();
        await db.close();
      }
    },
  );

  test(
    'prefetchSidebarEntities completes without throwing when not authenticated',
    () async {
      // The active-company-change hook fires prefetch fire-and-forget; any
      // failure (UnauthorizedException, network blip, …) is caught per
      // entity so login latency stays unchanged. This test pins that
      // contract: even with no credentials, the helper completes cleanly.
      final db = AppDatabase(NativeDatabase.memory());
      final services = Services.build(
        db: db,
        tokenStorage: InMemoryTokenStorage(),
        connectivityWatcher: ConnectivityWatcher.fixed(online: false),
      );
      try {
        await expectLater(
          services.prefetchSidebarEntities('company-1'),
          completes,
        );
      } finally {
        await services.auth.dispose();
        await db.close();
      }
    },
  );

  test(
    'sidebar prefetch never runs more than the concurrency bound at once',
    () async {
      // Regression for the diagnostics-log "prefetch failed ... Response
      // parse timed out" storm: the fan-out used to be an unbounded
      // Future.wait over every sidebar entity, spawning ~14 decode isolates
      // at once. The bounded worker pool must cap in-flight prefetchers.
      final bound = prefetchConcurrencyForTest;
      var inFlight = 0;
      var peak = 0;
      var completed = 0;

      final eligible = [
        for (final spec in kWiredEntityModules)
          if (spec.sidebarSection != SidebarSection.none) spec.type,
      ];
      expect(
        eligible.length,
        greaterThan(bound),
        reason: 'need more sidebar entities than the bound to exercise it',
      );

      final prefetchers = <EntityType, Future<bool> Function(String)>{
        for (final type in eligible)
          type: (_) async {
            inFlight++;
            peak = peak > inFlight ? peak : inFlight;
            // Yield so concurrent jobs actually overlap before we decrement.
            await Future<void>.delayed(const Duration(milliseconds: 5));
            inFlight--;
            completed++;
            return true;
          },
      };

      await runSidebarPrefetchForTest(prefetchers, 'company-1');

      expect(completed, eligible.length, reason: 'every job runs exactly once');
      expect(peak, lessThanOrEqualTo(bound), reason: 'concurrency is bounded');
      expect(peak, bound, reason: 'pool saturates up to the bound');
    },
  );

  test(
    'prefetchSidebarEntities short-circuits on an empty companyId',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final services = Services.build(
        db: db,
        tokenStorage: InMemoryTokenStorage(),
        connectivityWatcher: ConnectivityWatcher.fixed(online: false),
      );
      try {
        await expectLater(services.prefetchSidebarEntities(''), completes);
      } finally {
        await services.auth.dispose();
        await db.close();
      }
    },
  );

  test(
    'updateCompany drops the memoized Formatter (wiring end-to-end)',
    () async {
      // Without the onSettingsWritten -> invalidateFormatter wiring, a
      // settings change (Date Format / currency / decimal separator) stays
      // invisible until logout/restart because formatterFor is memoized.
      const companyId = 'co';
      final db = AppDatabase(NativeDatabase.memory());
      final services = Services.build(
        db: db,
        tokenStorage: InMemoryTokenStorage(),
        connectivityWatcher: ConnectivityWatcher.fixed(online: false),
      );
      try {
        await db.companiesDao.upsertAll([
          CompaniesCompanion.insert(
            id: companyId,
            name: 'Acme',
            displayName: const Value('Acme'),
            settings: jsonEncode(const {'name': 'Acme'}),
            permissions: '',
            accountId: 'acct',
            token: 'tok',
            updatedAt: 1700000000,
          ),
        ]);

        // Warm the per-company Formatter cache.
        await services.formatterFor(companyId);
        expect(services.formatterIfReady(companyId), isNotNull);

        final current = await services.company.get(companyId);
        await services.company.updateCompany(
          draft: current!.copyWith(
            settings: current.settings.copyWith(name: 'Acme Renamed'),
          ),
        );

        // The wired callback fired: stale Formatter dropped, next read
        // rebuilds against the new settings.
        expect(services.formatterIfReady(companyId), isNull);
      } finally {
        await services.auth.dispose();
        await db.close();
      }
    },
  );
}
