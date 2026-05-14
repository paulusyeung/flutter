import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/data/db/app_database.dart';

final _log = Logger('ThemeController');

/// Owns the user's theme preferences and persists them to `nav_state`:
/// the [ThemeMode] choice (System / Light / Dark) plus the two palette
/// sub-variants. The variant choices persist independently — System honors
/// both so the OS can flip brightness without losing either selection.
///
/// The app's [MaterialApp.router] binds to this controller via
/// [ListenableBuilder]. A change to any of the three fields rebuilds
/// `MaterialApp.router`'s `themeMode` / `theme` / `darkTheme`.
class ThemeController extends ChangeNotifier {
  ThemeController({
    required AppDatabase db,
    DateTime Function()? now,
    ThemeMode initialMode = ThemeMode.system,
    LightVariant initialLightVariant = LightVariant.sand,
    DarkVariant initialDarkVariant = DarkVariant.espresso,
  }) : _db = db,
       _now = now ?? DateTime.now,
       _themeMode = initialMode,
       _lightVariant = initialLightVariant,
       _darkVariant = initialDarkVariant;

  final AppDatabase _db;
  final DateTime Function() _now;

  ThemeMode _themeMode;
  LightVariant _lightVariant;
  DarkVariant _darkVariant;

  ThemeMode get themeMode => _themeMode;
  LightVariant get lightVariant => _lightVariant;
  DarkVariant get darkVariant => _darkVariant;

  /// Read every persisted theme field from Drift. Unknown / missing values
  /// fall through to the constructor defaults — the same behavior a fresh
  /// install gets.
  Future<void> restore() async {
    final row = await _db.navStateDao.current();
    if (row == null) return;
    final mode = _parseMode(row.themeMode);
    final light = _parseLightVariant(row.lightVariant);
    final dark = _parseDarkVariant(row.darkVariant);
    var changed = false;
    if (mode != null && mode != _themeMode) {
      _themeMode = mode;
      changed = true;
    }
    if (light != null && light != _lightVariant) {
      _lightVariant = light;
      changed = true;
    }
    if (dark != null && dark != _darkVariant) {
      _darkVariant = dark;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> setLightVariant(LightVariant variant) async {
    if (_lightVariant == variant) return;
    _lightVariant = variant;
    notifyListeners();
    await _persist();
  }

  Future<void> setDarkVariant(DarkVariant variant) async {
    if (_darkVariant == variant) return;
    _darkVariant = variant;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      // Read the existing row first so we don't blow away the other nav-state
      // fields (route, company, locale, filters, sidebar) — single-row table.
      final existing = await _db.navStateDao.current();
      await _db.navStateDao.save(
        currentRoute: existing?.currentRoute,
        selectedCompanyId: existing?.selectedCompanyId,
        locale: existing?.locale,
        themeMode: _serializeMode(_themeMode),
        lightVariant: _lightVariant.name,
        darkVariant: _darkVariant.name,
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

  static String _serializeMode(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
  };

  static ThemeMode? _parseMode(String? raw) => switch (raw) {
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => null,
  };

  static LightVariant? _parseLightVariant(String? raw) {
    if (raw == null) return null;
    for (final v in LightVariant.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  static DarkVariant? _parseDarkVariant(String? raw) {
    if (raw == null) return null;
    for (final v in DarkVariant.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
