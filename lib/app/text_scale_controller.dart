import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/db/app_database.dart';

final _log = Logger('TextScaleController');

/// The four discrete UI text-scale factors, mirroring the legacy app
/// (`PrefState.TEXT_SCALING_*`): Small / Normal / Large / Extra Large.
const double kTextScaleSmall = 0.8;
const double kTextScaleNormal = 1.0;
const double kTextScaleLarge = 1.2;
const double kTextScaleExtraLarge = 1.4;

const List<double> kTextScaleOptions = [
  kTextScaleSmall,
  kTextScaleNormal,
  kTextScaleLarge,
  kTextScaleExtraLarge,
];

/// Localization key for the label of a given scale factor. Threshold-based so
/// it stays robust against floating-point drift.
String textScaleLabelKey(double scale) {
  if (scale < kTextScaleNormal) return 'small';
  if (scale >= kTextScaleExtraLarge) return 'extra_large';
  if (scale >= kTextScaleLarge) return 'large';
  return 'normal';
}

/// Compose the device-local [factor] with the platform/OS text scaler [os] so
/// accessibility scaling is respected: at the default factor (1.0) this returns
/// the OS scale unchanged (pure passthrough); otherwise it multiplies. Applied
/// app-wide by `MaterialApp`'s builder in `main.dart`.
TextScaler composeTextScaler(TextScaler os, double factor) =>
    TextScaler.linear(os.scale(1.0) * factor);

/// Owns the user's UI text-scale preference and persists it to
/// `nav_state.text_scale`. `null` in the DB means "default" (1.0).
///
/// `MaterialApp`'s builder binds to this controller (merged into the theme
/// [Listenable]); a change rebuilds the app-wide `MediaQuery` `textScaler`
/// override in `main.dart`. Same device-local persistence pattern as
/// [LocaleController] / [ThemeController].
class TextScaleController extends ValueNotifier<double> {
  TextScaleController({required AppDatabase db, DateTime Function()? now})
    : _db = db,
      _now = now ?? DateTime.now,
      super(kTextScaleNormal);

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> restore() async {
    final row = await _db.navStateDao.current();
    final raw = row?.textScale;
    if (raw != null) value = raw;
  }

  Future<void> set(double scale) async {
    if (value == scale) return;
    value = scale;
    try {
      // Read-modify-write so we don't blow away the other nav-state fields —
      // single-row table. `textScale` is the only field we change.
      final existing = await _db.navStateDao.current();
      await _db.navStateDao.save(
        currentRoute: existing?.currentRoute,
        selectedCompanyId: existing?.selectedCompanyId,
        locale: existing?.locale,
        themeMode: existing?.themeMode,
        lightVariant: existing?.lightVariant,
        darkVariant: existing?.darkVariant,
        filtersJson: existing?.filtersJson,
        sidebarCollapsed: existing?.sidebarCollapsed,
        textScale: scale,
        now: _now().millisecondsSinceEpoch,
      );
    } catch (e, st) {
      // A failed write keeps the in-memory value — the user still sees their
      // chosen scale until next launch. Same trade-off as theme/locale.
      _log.warning('Failed to persist text scale', e, st);
    }
  }
}
