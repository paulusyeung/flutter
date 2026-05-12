import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/logging.dart';
import 'package:admin/app/nav_state_persister.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/sync_lifecycle_observer.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/l10n/supported_locales.dart';

/// Bootstrap entry point.
///
/// Order:
///   1. ensureInitialized + logging
///   2. Open Drift (with `.broken.<ts>` recovery)
///   3. Build Services (DI graph) and restore any persisted session
///   4. Read persisted nav state so the app reopens where it left off
///   5. Run the app — the router watches `AuthRepository.credentials` and
///      flips between `/login` and the authenticated shell on its own.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();

  final opened = await openAppDatabase();
  final services = Services.build(db: opened.db);
  await Future.wait([
    services.auth.restore(),
    services.theme.restore(),
    services.locale.restore(),
  ]);

  // Bound how long dead outbox rows sit on disk. Fire-and-forget — the user
  // shouldn't wait for a cleanup query on startup, and a failure here is not
  // fatal (worst case: a few extra rows linger until next boot).
  unawaited(_pruneDeadOutbox(opened.db));

  // Resume where you left off: pick the persisted route if we have one and
  // the user is still authenticated. Unauthenticated → /login regardless.
  // When biometric is enabled, the router's redirect routes the deep link
  // through `/lock?from=<encoded>` and back out on unlock — we just feed it
  // the user's last route here.
  final navState = await opened.db.navStateDao.current();
  final initialLocation = services.auth.isAuthenticated
      ? (navState?.currentRoute ??
            defaultPostLoginRoute(services.auth.session.value))
      : '/login';

  runApp(
    InvoiceNinjaApp(
      services: services,
      dbWasReset: opened.wasReset,
      initialLocation: initialLocation,
    ),
  );
}

/// Drop dead outbox rows older than [_kOutboxDeadTtl]. Errors are logged but
/// swallowed — startup must continue.
const Duration _kOutboxDeadTtl = Duration(days: 90);

Future<void> _pruneDeadOutbox(AppDatabase db) async {
  try {
    final cutoff = DateTime.now()
        .subtract(_kOutboxDeadTtl)
        .millisecondsSinceEpoch;
    final removed = await db.outboxDao.pruneDead(olderThanMs: cutoff);
    if (removed > 0) {
      Logger('main').info('Pruned $removed dead outbox row(s).');
    }
  } catch (e, st) {
    Logger('main').warning('Dead-outbox prune failed', e, st);
  }
}

class InvoiceNinjaApp extends StatefulWidget {
  const InvoiceNinjaApp({
    required this.services,
    required this.dbWasReset,
    required this.initialLocation,
    super.key,
  });

  final Services services;
  final bool dbWasReset;
  final String initialLocation;

  @override
  State<InvoiceNinjaApp> createState() => _InvoiceNinjaAppState();
}

class _InvoiceNinjaAppState extends State<InvoiceNinjaApp> {
  late final GoRouter _router = buildRouter(
    isAuthenticated: () => widget.services.auth.isAuthenticated,
    postLoginRoute: () =>
        defaultPostLoginRoute(widget.services.auth.session.value),
    isClientTooOld: () => widget.services.clientTooOld.value != null,
    isBiometricLockRequired: () =>
        widget.services.auth.requiresBiometricUnlock.value,
    refreshListenable: Listenable.merge([
      widget.services.auth.credentials,
      widget.services.auth.requiresBiometricUnlock,
      widget.services.clientTooOld,
    ]),
    initialLocation: widget.initialLocation,
  );

  late final NavStatePersister _navPersister = NavStatePersister.fromRouter(
    router: _router,
    db: widget.services.db,
  );

  late final PasswordCacheLifecycleObserver _passwordCacheObserver =
      PasswordCacheLifecycleObserver(widget.services.passwordCache);

  late final SyncLifecycleObserver _syncObserver = SyncLifecycleObserver(
    auth: widget.services.auth,
    sync: widget.services.sync,
  );

  @override
  void initState() {
    super.initState();
    // Force-construct the persister so it attaches its listener.
    _navPersister;
    WidgetsBinding.instance.addObserver(_passwordCacheObserver);
    WidgetsBinding.instance.addObserver(_syncObserver);
    if (widget.dbWasReset) {
      debugPrint('Drift was reset on open — user should re-login and re-sync.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_syncObserver);
    WidgetsBinding.instance.removeObserver(_passwordCacheObserver);
    _navPersister.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<Services>.value(
      value: widget.services,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.services.theme,
        builder: (context, themeMode, _) => ValueListenableBuilder<Locale?>(
          valueListenable: widget.services.locale,
          builder: (context, locale, _) => MaterialApp.router(
            title: 'Invoice Ninja',
            debugShowCheckedModeBanner: kDebugMode,
            themeMode: themeMode,
            locale: locale,
            theme: buildInTheme(Brightness.light),
            darkTheme: buildInTheme(Brightness.dark),
            supportedLocales: kSupportedLocales,
            localizationsDelegates: const [
              Localization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
