import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:admin/l10n/supported_locales.dart';

/// In-memory localization for a single locale. Keys map straight to strings;
/// placeholder interpolation uses the `:name` syntax that matches what the
/// existing admin-portal app uses (`activity_149` etc.).
class Localization {
  Localization._(
    this._strings, {
    Map<String, String>? fallback,
    Map<String, String>? pending,
  }) : _fallback = fallback ?? const {},
       _pending = pending ?? const {};

  final Map<String, String> _strings;
  final Map<String, String> _fallback;
  // App-local strings not yet submitted to Transifex. Loaded from
  // `assets/i18n/_app_pending.json`. Only consulted when neither the active
  // locale nor the Transifex English fallback has the key, so Transifex wins
  // automatically once it catches up.
  final Map<String, String> _pending;

  /// Lookup a key with optional `:name` placeholders.
  ///
  /// Missing keys return the raw key so a typo is immediately visible in
  /// the UI rather than silently rendering blank.
  String lookup(String key, [Map<String, String>? params]) {
    final raw = _strings[key] ?? _fallback[key] ?? _pending[key] ?? key;
    if (params == null || params.isEmpty) return raw;
    var out = raw;
    for (final entry in params.entries) {
      out = out.replaceAll(':${entry.key}', entry.value);
    }
    return out;
  }

  static Localization? of(BuildContext context) =>
      Localizations.of<Localization>(context, Localization);

  static const LocalizationsDelegate<Localization> delegate =
      _LocalizationDelegate();

  /// English fallback — loaded once via [_loadEnglishOnce] so every other
  /// locale can layer on top.
  static Map<String, String>? _englishCache;
  static Future<Map<String, String>>? _englishLoad;

  static Future<Map<String, String>> _loadEnglishOnce(AssetBundle bundle) {
    final cached = _englishCache;
    if (cached != null) return Future.value(cached);
    final inFlight = _englishLoad;
    if (inFlight != null) return inFlight;
    final fut = _loadAsset(bundle, 'en')
        .then((map) {
          _englishCache = map;
          _englishLoad = null;
          return map;
        })
        .catchError((Object e) {
          _englishLoad = null;
          // If English isn't bundled we still want the app to start — return
          // an empty map so every lookup falls through to the key.
          return <String, String>{};
        });
    _englishLoad = fut;
    return fut;
  }

  static Map<String, String>? _pendingCache;
  static Future<Map<String, String>>? _pendingLoad;

  static Future<Map<String, String>> _loadPendingOnce(AssetBundle bundle) {
    final cached = _pendingCache;
    if (cached != null) return Future.value(cached);
    final inFlight = _pendingLoad;
    if (inFlight != null) return inFlight;
    final fut = bundle
        .loadString('assets/i18n/_app_pending.json')
        .then((raw) => compute(_decodeStringMap, raw))
        .then((map) {
          _pendingCache = map;
          _pendingLoad = null;
          return map;
        })
        .catchError((Object e) {
          _pendingLoad = null;
          return <String, String>{};
        });
    _pendingLoad = fut;
    return fut;
  }

  static Future<Map<String, String>> _loadAsset(
    AssetBundle bundle,
    String localeKey,
  ) async {
    final raw = await bundle.loadString('assets/i18n/$localeKey.json');
    // Large files — decode off the main isolate when possible.
    final decoded = await compute(_decodeStringMap, raw);
    return decoded;
  }

  // Test seam: lets the in-memory parser run without bundle plumbing.
  @visibleForTesting
  static Localization forTesting({
    required Map<String, String> strings,
    Map<String, String>? fallback,
    Map<String, String>? pending,
  }) => Localization._(strings, fallback: fallback, pending: pending);
}

Map<String, String> _decodeStringMap(String raw) {
  final json = jsonDecode(raw);
  if (json is! Map) {
    throw FormatException('Expected JSON object, got ${json.runtimeType}');
  }
  return json.map((k, v) => MapEntry(k.toString(), v.toString()));
}

class _LocalizationDelegate extends LocalizationsDelegate<Localization> {
  const _LocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return kSupportedLocales.any(
      (l) =>
          l.languageCode == locale.languageCode &&
          (l.countryCode == null || l.countryCode == locale.countryCode),
    );
  }

  @override
  Future<Localization> load(Locale locale) async {
    final fallback = await Localization._loadEnglishOnce(rootBundle);
    final pending = await Localization._loadPendingOnce(rootBundle);
    final key = localeKey(locale);
    if (key == 'en') {
      return Localization._(fallback, pending: pending);
    }
    try {
      final strings = await Localization._loadAsset(rootBundle, key);
      return Localization._(strings, fallback: fallback, pending: pending);
    } catch (_) {
      // Locale bundled in supported list but file missing (e.g. importer
      // not yet run) — fall back to English so the app still renders.
      return Localization._(fallback, pending: pending);
    }
  }

  @override
  bool shouldReload(_LocalizationDelegate old) => false;
}

extension LocalizationContext on BuildContext {
  /// Shorthand: `context.tr('save')` instead of
  /// `Localization.of(context)!.lookup('save')`.
  String tr(String key, [Map<String, String>? params]) =>
      Localization.of(this)?.lookup(key, params) ?? key;

  /// Optional shorthand: returns the localized string when the key is
  /// defined, or `null` when the bundle has no entry for it (the `lookup`
  /// default of returning the raw key would render the snake_case slug to
  /// the user — useless for optional help-text subtitles).
  ///
  /// Used by settings screens that want to surface a `*_help` line under a
  /// toggle when the translation exists, and render the toggle cleanly
  /// without a subtitle otherwise.
  String? trIfDefined(String key, [Map<String, String>? params]) {
    final loc = Localization.of(this);
    if (loc == null) return null;
    final raw = loc.lookup(key, params);
    if (raw == key) return null;
    return raw;
  }
}
