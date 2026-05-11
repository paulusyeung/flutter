// Shared sync Localization delegate for widget tests.
//
// The production `Localization.delegate` loads via `rootBundle` asynchronously,
// which keeps `MaterialApp`'s child tree hidden until the future resolves —
// `pumpAndSettle` doesn't always reliably await that load. Reading the bundled
// JSON directly off disk and returning a `SynchronousFuture` sidesteps that
// problem and matches what production renders for English users.

import 'dart:convert';
import 'dart:io';

import 'package:admin/l10n/localization.dart';
import 'package:admin/l10n/supported_locales.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SyncLocalizationDelegate extends LocalizationsDelegate<Localization> {
  const SyncLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Localization> load(Locale locale) => SynchronousFuture(
    Localization.forTesting(strings: _enStrings(), pending: _pendingStrings()),
  );

  @override
  bool shouldReload(LocalizationsDelegate<Localization> old) => false;
}

/// All localization delegates a widget test needs to render English strings
/// from `en.json` (and any keys not yet in Transifex from `_app_pending.json`).
const List<LocalizationsDelegate<dynamic>> kTestLocalizationsDelegates = [
  SyncLocalizationDelegate(),
];

final List<Locale> kTestSupportedLocales = kSupportedLocales;

Map<String, String>? _enStringsCache;
Map<String, String> _enStrings() {
  final cached = _enStringsCache;
  if (cached != null) return cached;
  final raw = File('assets/i18n/en.json').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final map = decoded.map((k, v) => MapEntry(k, v.toString()));
  _enStringsCache = map;
  return map;
}

Map<String, String>? _pendingStringsCache;
Map<String, String> _pendingStrings() {
  final cached = _pendingStringsCache;
  if (cached != null) return cached;
  final raw = File('assets/i18n/_app_pending.json').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final map = decoded.map((k, v) => MapEntry(k, v.toString()));
  _pendingStringsCache = map;
  return map;
}
