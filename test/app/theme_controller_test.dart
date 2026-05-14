import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme_controller.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests target ThemeController's persistence contract:
///   * setting any of mode / lightVariant / darkVariant writes the matching
///     `nav_state` column and round-trips through `restore()` on next launch
///   * no notification fires when the same value is set twice
///   * `restore()` ignores unrecognized stored strings (forwards-compat for
///     a future palette rename)
/// They don't re-test Drift or ChangeNotifier itself.

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  test(
    'setThemeMode writes nav_state.theme_mode and round-trips on restore()',
    () async {
      final controller = ThemeController(db: db);
      await controller.setThemeMode(ThemeMode.dark);

      final row = await db.navStateDao.current();
      expect(row?.themeMode, 'dark');

      final fresh = ThemeController(db: db);
      expect(fresh.themeMode, ThemeMode.system, reason: 'before restore');
      await fresh.restore();
      expect(fresh.themeMode, ThemeMode.dark);
    },
  );

  test(
    'setLightVariant + setDarkVariant write their columns and round-trip',
    () async {
      final controller = ThemeController(db: db);
      await controller.setLightVariant(LightVariant.mist);
      await controller.setDarkVariant(DarkVariant.carbon);

      final row = await db.navStateDao.current();
      expect(row?.lightVariant, 'mist');
      expect(row?.darkVariant, 'carbon');

      final fresh = ThemeController(db: db);
      expect(fresh.lightVariant, LightVariant.sand, reason: 'before restore');
      expect(fresh.darkVariant, DarkVariant.espresso, reason: 'before restore');
      await fresh.restore();
      expect(fresh.lightVariant, LightVariant.mist);
      expect(fresh.darkVariant, DarkVariant.carbon);
    },
  );

  test(
    'restore() ignores unrecognized variant strings and keeps defaults',
    () async {
      // Seed a row with bogus variant names — a future rename would land
      // legacy installs in this state; the controller must not crash.
      await db.navStateDao.save(
        currentRoute: null,
        selectedCompanyId: null,
        locale: null,
        themeMode: 'light',
        lightVariant: 'no_such_variant',
        darkVariant: 'also_unknown',
        filtersJson: null,
        sidebarCollapsed: null,
        now: 1,
      );

      final controller = ThemeController(db: db);
      await controller.restore();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.lightVariant, LightVariant.sand);
      expect(controller.darkVariant, DarkVariant.espresso);
    },
  );

  test('setters are no-ops when the value is unchanged', () async {
    final controller = ThemeController(
      db: db,
      initialMode: ThemeMode.light,
      initialLightVariant: LightVariant.paper,
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setThemeMode(ThemeMode.light);
    await controller.setLightVariant(LightVariant.paper);
    expect(notifications, 0, reason: 'identical values must not notify');

    await controller.setThemeMode(ThemeMode.dark);
    await controller.setLightVariant(LightVariant.mist);
    expect(notifications, 2);
  });
}
