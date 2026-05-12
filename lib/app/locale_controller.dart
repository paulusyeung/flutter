import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';
import 'package:admin/l10n/supported_locales.dart';

final _log = Logger('LocaleController');

/// Owns the user's locale preference and persists it to `nav_state.locale`.
/// `null` means "follow the device locale" — Flutter's
/// [MaterialApp.locale] parameter treats null the same way.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController({required AppDatabase db, DateTime Function()? now})
    : _db = db,
      _now = now ?? DateTime.now,
      super(null);

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> restore() async {
    final row = await _db.navStateDao.current();
    final raw = row?.locale;
    if (raw == null || raw.isEmpty) return;
    final restored = _parse(raw);
    if (restored != null) value = restored;
  }

  Future<void> set(Locale? locale) async {
    if (value == locale) return;
    value = locale;
    try {
      final existing = await _db.navStateDao.current();
      await _db.navStateDao.save(
        currentRoute: existing?.currentRoute,
        selectedCompanyId: existing?.selectedCompanyId,
        locale: locale == null ? '' : localeKey(locale),
        themeMode: existing?.themeMode,
        filtersJson: existing?.filtersJson,
        sidebarCollapsed: existing?.sidebarCollapsed,
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      _log.warning('Failed to persist locale', e, st);
    }
  }

  static Locale? _parse(String raw) {
    if (raw.isEmpty) return null;
    final parts = raw.split('_');
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }
}
