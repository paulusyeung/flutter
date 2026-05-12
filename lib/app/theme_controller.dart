import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';

final _log = Logger('ThemeController');

/// Owns the user's theme preference and persists it to `nav_state.theme_mode`
/// so it survives restarts. The app's [MaterialApp.router] binds to
/// [mode] via [ValueListenableBuilder].
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({
    required AppDatabase db,
    DateTime Function()? now,
    ThemeMode initial = ThemeMode.system,
  }) : _db = db,
       _now = now ?? DateTime.now,
       super(initial);

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Read the persisted theme from Drift; falls back to current value if
  /// nothing is stored yet.
  Future<void> restore() async {
    final row = await _db.navStateDao.current();
    final raw = row?.themeMode;
    if (raw == null) return;
    final restored = _parse(raw);
    if (restored != null) value = restored;
  }

  ValueListenable<ThemeMode> get mode => this;

  Future<void> set(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    try {
      // Single-row table — saveRoute pattern. The other nav-state fields
      // stay untouched because insertOnConflictUpdate leaves absent values
      // alone on conflict.
      final existing = await _db.navStateDao.current();
      await _db.navStateDao.save(
        currentRoute: existing?.currentRoute,
        selectedCompanyId: existing?.selectedCompanyId,
        locale: existing?.locale,
        themeMode: _serialize(mode),
        filtersJson: existing?.filtersJson,
        sidebarCollapsed: existing?.sidebarCollapsed,
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      // A failed write doesn't roll back the in-memory toggle — the user
      // still sees their chosen theme until next launch.
      _log.warning('Failed to persist theme', e, st);
    }
  }

  static String _serialize(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
  };

  static ThemeMode? _parse(String raw) => switch (raw) {
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => null,
  };
}
