import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';

final _log = Logger('SidebarController');

/// Owns the user's "is the wide-layout sidebar collapsed?" preference and
/// persists it to `nav_state.sidebar_collapsed` so the rail renders at the
/// correct width on the first frame of the next launch — same single-row
/// persistence pattern as [ThemeController] and [LocaleController].
class SidebarController extends ValueNotifier<bool> {
  SidebarController({
    required AppDatabase db,
    DateTime Function()? now,
    bool initial = false,
  }) : _db = db,
       _now = now ?? DateTime.now,
       super(initial);

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> restore() async {
    final row = await _db.navStateDao.current();
    final stored = row?.sidebarCollapsed;
    if (stored == null) return;
    value = stored;
  }

  Future<void> toggle() => set(!value);

  Future<void> set(bool collapsed) async {
    if (value == collapsed) return;
    value = collapsed;
    try {
      final existing = await _db.navStateDao.current();
      await _db.navStateDao.save(
        currentRoute: existing?.currentRoute,
        selectedCompanyId: existing?.selectedCompanyId,
        locale: existing?.locale,
        themeMode: existing?.themeMode,
        filtersJson: existing?.filtersJson,
        sidebarCollapsed: collapsed,
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      // A failed write doesn't roll back the in-memory toggle — the user
      // still sees their chosen state until next launch.
      _log.warning('Failed to persist sidebar collapsed', e, st);
    }
  }
}
