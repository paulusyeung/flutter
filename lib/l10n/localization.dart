import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'supported_locales.dart';

/// In-memory localization for a single locale. Keys map straight to strings;
/// placeholder interpolation uses the `:name` syntax that matches what the
/// existing admin-portal app uses (`activity_149` etc.).
class Localization {
  Localization._(this._strings, {Map<String, String>? fallback})
    : _fallback = fallback ?? const {};

  final Map<String, String> _strings;
  final Map<String, String> _fallback;

  /// Lookup a key with optional `:name` placeholders.
  ///
  /// Missing keys return the raw key so a typo is immediately visible in
  /// the UI rather than silently rendering blank.
  String lookup(String key, [Map<String, String>? params]) {
    final raw = _strings[key] ?? _fallback[key] ?? key;
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
  }) => Localization._(strings, fallback: fallback);
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
    final key = localeKey(locale);
    if (key == 'en') {
      return Localization._(fallback);
    }
    try {
      final strings = await Localization._loadAsset(rootBundle, key);
      return Localization._(strings, fallback: fallback);
    } catch (_) {
      // Locale bundled in supported list but file missing (e.g. importer
      // not yet run) — fall back to English so the app still renders.
      return Localization._(fallback);
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
}
