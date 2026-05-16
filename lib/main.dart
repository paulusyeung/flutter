import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/debug_capture_store.dart';
import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/diagnostics_log.dart';
import 'package:admin/app/logging.dart';
import 'package:admin/app/native_splash.dart';
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
  // Wrap everything past `ensureInitialized` in `runZonedGuarded` so async
  // errors that escape the Flutter tree (timers, untracked Futures) hit our
  // diagnostics log AND the in-memory debug-capture ring. The diagnostics log
  // is debug-only; the capture store lives in release too so the hidden Debug
  // Panel can show what went wrong in prod when capture is enabled.
  await runZonedGuarded(_bootstrap, (error, stack) {
    _diagnosticsLogRef?.recordError(error, stack, context: 'runZonedGuarded');
    _debugCaptureStoreRef?.recordError(
      error,
      stack,
      context: 'runZonedGuarded',
    );
  });
}

/// Module-private reference so the `runZonedGuarded` error handler can reach
/// the [DiagnosticsLog] without smuggling it through a closure. Set during
/// [_bootstrap] before `runApp`; remains `null` in release builds.
DiagnosticsLog? _diagnosticsLogRef;

/// Mirror of [_diagnosticsLogRef] for the always-on debug-capture store.
/// Set during [_bootstrap]; null until then.
DebugCaptureStore? _debugCaptureStoreRef;

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();
  // Dart hot-restart preserves static fields, so without this reset the iOS
  // SplashOverlay would see `dismissed` already true on the second run and
  // skip its entry. Stripped from release builds via `assert`.
  assert(() {
    NativeSplash.dismissed.value = false;
    return true;
  }());

  // Debug-only cold-start instrumentation. Each stage logs its own
  // duration and the cumulative time-to-here so a regression in any one
  // boot phase (secure-storage key fetch, DB open, session restore,
  // statics warm) is attributable from the console without a profiler.
  // Compiled out of release builds (`kDebugMode` is a const false there).
  final bootSw = Stopwatch()..start();
  var lastMs = 0;
  void mark(String stage) {
    if (!kDebugMode) return;
    final now = bootSw.elapsedMilliseconds;
    Logger('main.boot').info('$stage: ${now - lastMs}ms (t+${now}ms)');
    lastMs = now;
  }

  final diag = await _initDiagnostics();
  _diagnosticsLogRef = diag;
  mark('diagnostics');

  final opened = await openAppDatabase();
  mark('db-open (incl. secure-storage key)');
  final services = Services.build(db: opened.db, diagnosticsLog: diag);
  _debugCaptureStoreRef = services.debugCaptureStore;
  _installCaptureHandlers(services.debugCaptureStore);
  await Future.wait([
    services.auth.restore(),
    services.theme.restore(),
    services.locale.restore(),
    services.sidebar.restore(),
  ]);
  mark('restore (auth/theme/locale/sidebar)');

  // Warm the statics cache before any screen mounts so dropdowns reading
  // `Services.statics` (Company Details size/industry, Localization currency/
  // language/country, …) render populated on first frame instead of flashing
  // "loading". Reads from the Drift cache when fresh (≤ TTL); only the rare
  // stale/empty case pays a network round-trip.
  if (services.auth.isAuthenticated) {
    await services.statics.ensureLoaded();
    mark('statics warm');
  }

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
  // Strip any entity-row segment from the restored URL so cold-start
  // lands on the bare entity list rather than the last-viewed row.
  // `/clients/c_42` → `/clients`; `/clients/new` and `/settings/...`
  // pass through unchanged (see `companySafeLocation`).
  final restored = navState?.currentRoute;
  final initialLocation = services.auth.isAuthenticated
      ? (restored == null
            ? defaultPostLoginRoute(services.auth.session.value)
            : companySafeLocation(
                restored,
                services.entityRegistry.uiRoutePaths,
              ))
      : '/login';

  mark('nav-state + route resolve');
  runApp(
    InvoiceNinjaApp(
      services: services,
      dbWasReset: opened.wasReset,
      initialLocation: initialLocation,
    ),
  );
}

/// Wire up the debug-only Claude-readable diagnostics log. Returns `null`
/// in release builds — no file is created, no handlers are registered.
///
/// The handlers route uncaught Flutter/Dart errors and WARNING+ Logger
/// records into the same on-disk file. The path is surfaced in Settings →
/// Advanced → System Logs so Claude can be pointed at it.
Future<DiagnosticsLog?> _initDiagnostics() async {
  if (kReleaseMode) return null;
  try {
    final diag = await DiagnosticsLog.open();
    final priorFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      diag.recordError(
        details.exception,
        details.stack,
        context: details.context?.toString(),
      );
      if (priorFlutterOnError != null) {
        priorFlutterOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    final priorPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      diag.recordError(error, stack, context: 'PlatformDispatcher');
      return priorPlatformOnError?.call(error, stack) ?? false;
    };
    Logger.root.onRecord.listen((record) {
      if (record.level < Level.WARNING) return;
      diag.recordLog(record);
    });
    Logger('main').info('Diagnostics log open at ${diag.path}');
    return diag;
  } catch (e, st) {
    Logger('main').warning('Diagnostics log init failed', e, st);
    return null;
  }
}

/// Install error / log handlers that fan out into the [DebugCaptureStore].
/// These run in release builds too — they're the only error sink in prod.
/// Each handler chains to the existing one (which in debug already routes to
/// [DiagnosticsLog] from [_initDiagnostics]), so this never displaces the
/// Claude-readable file logger.
void _installCaptureHandlers(DebugCaptureStore store) {
  final priorFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    store.recordError(
      details.exception,
      details.stack,
      context: details.context?.toString(),
    );
    if (priorFlutterOnError != null) {
      priorFlutterOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  final priorPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    store.recordError(error, stack, context: 'PlatformDispatcher');
    return priorPlatformOnError?.call(error, stack) ?? false;
  };
  Logger.root.onRecord.listen((record) {
    if (record.level < Level.WARNING) return;
    store.recordLog(record);
  });
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
    isCompanySetupRequired: () =>
        isCompanySetupRequired(widget.services.auth.session.value),
    refreshListenable: Listenable.merge([
      widget.services.auth.credentials,
      // `session` fires on every Drift `companies`-table change (see the
      // `_companiesSub` watcher in `AuthRepository`), so the optimistic
      // settings.name write from the setup wizard releases the `/setup`
      // gate without waiting for the outbox PUT to round-trip.
      widget.services.auth.session,
      widget.services.auth.requiresBiometricUnlock,
      widget.services.clientTooOld,
    ]),
    registry: widget.services.entityRegistry,
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
    // Dismiss the splash once Flutter has actually painted — keeps the logo
    // on screen through the router redirect chain instead of a fixed timer.
    // Two-frame deferral: the first post-frame lets GoRouter's synchronous
    // redirect chain resolve and paint; the second gives the auth-restore
    // microtask one more frame to settle before we fade the overlay. Native
    // macOS side has a 6 s safety fallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => NativeSplash.dismiss(),
      );
    });
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
    // restart. `ListenableBuilder` reacts to `ThemeController` (mode +
    // light/dark variant + custom palette) so picking a sub-palette or
    // editing a custom colour repaints immediately. `lightTokens` /
    // `darkTokens` return memoised instances (the controller caches the
    // resolved custom palette) so unrelated rebuilds don't churn the theme.
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
        listenable: Listenable.merge([theme, widget.services.accentColor]),
        builder: (context, _) => ValueListenableBuilder<Locale?>(
          valueListenable: widget.services.locale,
          builder: (context, locale, _) => MaterialApp.router(
            title: 'Invoice Ninja',
            debugShowCheckedModeBanner: false,
            themeMode: theme.themeMode,
            locale: locale,
            // A per-side custom-palette accent supersedes the per-user
            // `accentColor` for that side only; any side not on a custom
            // palette (or whose custom palette has no accent override) still
            // follows the accent swatch picked on Preferences. Both
            // `theme:`/`darkTheme:` stay populated so `ThemeMode.system`
            // resolves correctly and the macOS titlebar (builder below, which
            // reads the resolved extension) keeps following OS brightness.
            theme: buildInTheme(
              theme.lightTokens,
              accentOverride:
                  theme.customLightAccent ?? widget.services.accentColor.value,
            ),
            darkTheme: buildInTheme(
              theme.darkTokens,
              accentOverride:
                  theme.customDarkAccent ?? widget.services.accentColor.value,
            ),
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
              // iOS: layer an animated splash overlay above all routes so
              // the storyboard → Flutter handoff has a gentle exit instead
              // of a hard cut. Passthrough on every other platform.
              return NativeSplash.wrap(child: child ?? const SizedBox.shrink());
            },
          ),
        ),
      ),
    );
  }
}
