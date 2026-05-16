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
    CustomTheme initialCustomTheme = defaultCustomTheme,
  }) : _db = db,
       _now = now ?? DateTime.now,
       _themeMode = initialMode,
       _lightVariant = initialLightVariant,
       _darkVariant = initialDarkVariant,
       _customTheme = initialCustomTheme;

  final AppDatabase _db;
  final DateTime Function() _now;

  ThemeMode _themeMode;
  LightVariant _lightVariant;
  DarkVariant _darkVariant;
  CustomTheme _customTheme;

  // Memoised resolved custom palettes. Recomputed lazily and cleared whenever
  // [_customTheme] changes, so [lightTokens] / [darkTokens] return a stable
  // instance across unrelated rebuilds (locale / accent notifies). Without
  // this, `MaterialApp` would see a fresh `InTheme` every build (it has no
  // `==`) and fire a spurious 200ms theme animation each time.
  InTheme? _cachedCustomLight;
  InTheme? _cachedCustomDark;

  ThemeMode get themeMode => _themeMode;
  LightVariant get lightVariant => _lightVariant;
  DarkVariant get darkVariant => _darkVariant;
  CustomTheme get customTheme => _customTheme;

  /// Tokens for the light side — the user's custom palette when the light
  /// variant is `custom`, otherwise the selected preset's const singleton.
  InTheme get lightTokens => _lightVariant == LightVariant.custom
      ? (_cachedCustomLight ??= _customTheme.resolveLight())
      : _lightVariant.tokens;

  /// Tokens for the dark side — see [lightTokens].
  InTheme get darkTokens => _darkVariant == DarkVariant.custom
      ? (_cachedCustomDark ??= _customTheme.resolveDark())
      : _darkVariant.tokens;

  /// Per-side accent override (only when that side is a custom palette with
  /// an accent token set) — fed to `buildInTheme`'s `accentOverride:` so the
  /// soft / ink shades re-derive. Null lets the per-user accent stand.
  Color? get customLightAccent =>
      _lightVariant == LightVariant.custom ? _customTheme.lightAccent : null;
  Color? get customDarkAccent =>
      _darkVariant == DarkVariant.custom ? _customTheme.darkAccent : null;

  void _setCustomTheme(CustomTheme next) {
    if (next == _customTheme) return;
    _customTheme = next;
    _cachedCustomLight = null;
    _cachedCustomDark = null;
  }

  /// Read every persisted theme field from Drift. Unknown / missing values
  /// fall through to the constructor defaults — the same behavior a fresh
  /// install gets.
  Future<void> restore() async {
    final row = await _db.navStateDao.current();
    if (row == null) return;
    final mode = _parseMode(row.themeMode);
    final light = _parseLightVariant(row.lightVariant);
    final dark = _parseDarkVariant(row.darkVariant);
    final customJson = row.customThemeJson;
    var changed = false;
    if (customJson != null) {
      final parsed = CustomTheme.fromJson(customJson);
      if (parsed != _customTheme) {
        _setCustomTheme(parsed);
        changed = true;
      }
    }
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

  Future<void> setCustomLightBase(LightVariant base) async {
    if (base == LightVariant.custom || _customTheme.lightBase == base) return;
    _setCustomTheme(_customTheme.copyWith(lightBase: base));
    notifyListeners();
    await _persist();
  }

  Future<void> setCustomDarkBase(DarkVariant base) async {
    if (base == DarkVariant.custom || _customTheme.darkBase == base) return;
    _setCustomTheme(_customTheme.copyWith(darkBase: base));
    notifyListeners();
    await _persist();
  }

  Future<void> setCustomOverride(
    Brightness side,
    CustomToken token,
    Color color,
  ) async {
    final next = _customTheme.withOverride(side, token, color);
    if (next == _customTheme) return;
    _setCustomTheme(next);
    notifyListeners();
    await _persist();
  }

  Future<void> clearCustomOverride(Brightness side, CustomToken token) async {
    final next = _customTheme.withoutOverride(side, token);
    if (next == _customTheme) return;
    _setCustomTheme(next);
    notifyListeners();
    await _persist();
  }

  /// Drop every override on [side] — reverts that side to its base preset.
  Future<void> clearCustomSide(Brightness side) async {
    final next = side == Brightness.dark
        ? _customTheme.copyWith(darkOverrides: const {})
        : _customTheme.copyWith(lightOverrides: const {});
    if (next == _customTheme) return;
    _setCustomTheme(next);
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
        customThemeJson: _customTheme.toJson(),
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
