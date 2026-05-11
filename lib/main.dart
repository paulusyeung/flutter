import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app/logging.dart';
import 'app/nav_state_persister.dart';
import 'app/router.dart';
import 'app/services.dart';
import 'data/db/app_database.dart';
import 'l10n/localization.dart';
import 'l10n/supported_locales.dart';

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

  // Resume where you left off: pick the persisted route if we have one and
  // the user is still authenticated. Unauthenticated → /login regardless.
  final navState = await opened.db.navStateDao.current();
  final initialLocation = services.auth.isAuthenticated
      ? (navState?.currentRoute ?? '/clients')
      : '/login';

  runApp(
    InvoiceNinjaApp(
      services: services,
      dbWasReset: opened.wasReset,
      initialLocation: initialLocation,
    ),
  );
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
    refreshListenable: widget.services.auth.credentials,
    initialLocation: widget.initialLocation,
  );

  late final NavStatePersister _navPersister = NavStatePersister.fromRouter(
    router: _router,
    db: widget.services.db,
  );

  @override
  void initState() {
    super.initState();
    // Force-construct the persister so it attaches its listener.
    _navPersister;
    if (widget.dbWasReset) {
      debugPrint('Drift was reset on open — user should re-login and re-sync.');
    }
  }

  @override
  void dispose() {
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
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
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
