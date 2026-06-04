import 'package:admin/app/locale_controller.dart';
import 'package:admin/app/text_scale_controller.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TextScaleController's persistence contract:
///   * set() writes nav_state.text_scale and round-trips through restore()
///   * set() preserves the other nav_state columns (read-modify-write)
///   * a theme / locale write preserves text_scale (the `Value.absent` guard,
///     proving the contract holds in both directions)
///   * no notification fires when the value is unchanged
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  test(
    'set() writes nav_state.text_scale and round-trips on restore()',
    () async {
      final controller = TextScaleController(db: db);
      expect(controller.value, kTextScaleNormal);

      await controller.set(kTextScaleLarge);
      final row = await db.navStateDao.current();
      expect(row?.textScale, kTextScaleLarge);

      final fresh = TextScaleController(db: db);
      expect(fresh.value, kTextScaleNormal, reason: 'before restore');
      await fresh.restore();
      expect(fresh.value, kTextScaleLarge);
    },
  );

  test('set() preserves the other nav_state columns', () async {
    // Seed a fully populated row, then change only the text scale.
    await db.navStateDao.save(
      currentRoute: '/clients',
      selectedCompanyId: 'co_1',
      locale: 'fr',
      themeMode: 'dark',
      lightVariant: 'mist',
      darkVariant: 'carbon',
      filtersJson: '{"a":1}',
      sidebarCollapsed: true,
      customThemeJson: '{"x":1}',
      now: 1,
    );

    await TextScaleController(db: db).set(kTextScaleExtraLarge);

    final row = await db.navStateDao.current();
    expect(row?.textScale, kTextScaleExtraLarge);
    expect(row?.currentRoute, '/clients');
    expect(row?.selectedCompanyId, 'co_1');
    expect(row?.locale, 'fr');
    expect(row?.themeMode, 'dark');
    expect(row?.lightVariant, 'mist');
    expect(row?.darkVariant, 'carbon');
    expect(row?.filtersJson, '{"a":1}');
    expect(row?.sidebarCollapsed, true);
    expect(row?.customThemeJson, '{"x":1}');
  });

  test('a theme / locale write preserves text_scale', () async {
    await TextScaleController(db: db).set(kTextScaleSmall);

    // Unrelated writes through the other device-local controllers must not
    // null out text_scale (they omit it → Value.absent → preserved).
    await ThemeController(db: db).setThemeMode(ThemeMode.light);
    await LocaleController(db: db).set(const Locale('de'));

    final row = await db.navStateDao.current();
    expect(row?.themeMode, 'light');
    expect(row?.locale, 'de');
    expect(
      row?.textScale,
      kTextScaleSmall,
      reason: 'survives theme + locale writes',
    );

    final fresh = TextScaleController(db: db);
    await fresh.restore();
    expect(fresh.value, kTextScaleSmall);
  });

  test('set() is a no-op when the value is unchanged', () async {
    final controller = TextScaleController(db: db);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.set(kTextScaleNormal); // identical to the default
    expect(notifications, 0, reason: 'identical value must not notify');

    await controller.set(kTextScaleLarge);
    expect(notifications, 1);
  });

  test('textScaleLabelKey maps each factor to its label key', () {
    expect(textScaleLabelKey(kTextScaleSmall), 'small');
    expect(textScaleLabelKey(kTextScaleNormal), 'normal');
    expect(textScaleLabelKey(kTextScaleLarge), 'large');
    expect(textScaleLabelKey(kTextScaleExtraLarge), 'extra_large');
  });
}
