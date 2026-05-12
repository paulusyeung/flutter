import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/logging.dart';
import 'package:admin/app/native_window_theme.dart';
import 'package:admin/app/nav_state_persister.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/services/password_cache.dart';
import 'package:admin/data/services/sync_lifecycle_observer.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/l10n/supported_locales.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';

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
    services.sidebar.restore(),
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

/// Drop dead outbox rows older than 90 days. Errors are logged but swallowed —
/// startup must continue even if this housekeeping query fails.
Future<void> _pruneDeadOutbox(AppDatabase db) async {
  const ttl = Duration(days: 90);
  try {
    final cutoff = DateTime.now().subtract(ttl).millisecondsSinceEpoch;
    final removed = await db.outboxDao.pruneDead(olderThanMs: cutoff);
    if (removed > 0) {
      Logger('main').info('Pruned $removed dead outbox row(s).');
    }
  } catch (e, st) {
    Logger('main').warning('Dead-outbox prune failed', e, st);
  }
}

/// Top-level widget. Built once at boot from a fully-initialised [Services]
/// graph and a resolved [initialLocation].
///
/// Responsibilities:
///   - Build the [GoRouter] from `Services` (auth, client-version, biometric
///     gating; nothing app-wide is built lower in the tree).
///   - Attach a [NavStatePersister] so the user's last route survives restart.
///   - Register two [WidgetsBindingObserver]s — password-cache wipe on
///     background, sync drain on resume.
///   - Render [MaterialApp.router], rebuilt only when the persisted theme or
///     locale changes (see `build` below).
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
  // Owned for the app's lifetime: router, nav-state persister, and lifecycle
  // observers. All four are `late final` so they're built once on first access
  // and torn down in `dispose`.
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
    // Reference `_navPersister` so its `late final` initializer runs now — the
    // constructor attaches a router listener, and we never call methods on it.
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
    // The nested builders rebuild `MaterialApp.router` when the persisted
    // theme or locale changes, so a settings toggle takes effect without a
    // restart. `ListenableBuilder` reacts to any of `ThemeController`'s
    // three fields (themeMode + light/dark variant) so picking a sub-palette
    // repaints immediately.
    final theme = widget.services.theme;
    return MultiProvider(
      providers: [
        Provider<Services>.value(value: widget.services),
        // Mount the settings-edit scope once at the root so every settings
        // page reads the same instance via `context.watch<…>()` without
        // having to thread it through the route tree. The same controller
        // lives on `Services.settingsLevel` for non-widget callers (e.g.
        // the client detail screen's action handler).
        ChangeNotifierProvider<SettingsLevelController>.value(
          value: widget.services.settingsLevel,
        ),
      ],
      child: ListenableBuilder(
        listenable: theme,
        builder: (context, _) => ValueListenableBuilder<Locale?>(
          valueListenable: widget.services.locale,
          builder: (context, locale, _) => MaterialApp.router(
            title: 'Invoice Ninja',
            debugShowCheckedModeBanner: false,
            themeMode: theme.themeMode,
            locale: locale,
            theme: buildInTheme(theme.lightVariant.tokens),
            darkTheme: buildInTheme(theme.darkVariant.tokens),
            supportedLocales: kSupportedLocales,
            localizationsDelegates: const [
              Localization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            // Push the resolved variant's bg/ink to the native macOS
            // titlebar. `Theme.of(context)` here is already resolved (system
            // → light/dark via MediaQuery), so this picks up live OS-Dark
            // flips under `ThemeMode.system` for free. `apply` dedupes, so
            // the per-rebuild cost is negligible.
            builder: (context, child) {
              final tokens = Theme.of(context).extension<InTheme>();
              if (tokens != null) {
                scheduleMicrotask(() {
                  NativeWindowTheme.instance.apply(
                    background: tokens.bg,
                    title: tokens.ink,
                    brightness: tokens.brightness,
                  );
                });
              }
              return child ?? const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
