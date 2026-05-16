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

  test(
    'custom palette: variant=custom + overrides round-trip through restore()',
    () async {
      final controller = ThemeController(db: db);
      await controller.setLightVariant(LightVariant.custom);
      await controller.setDarkVariant(DarkVariant.custom);
      await controller.setCustomLightBase(LightVariant.paper);
      await controller.setCustomDarkBase(DarkVariant.midnight);
      await controller.setCustomOverride(
        Brightness.light,
        CustomToken.background,
        const Color(0xFF112233),
      );
      await controller.setCustomOverride(
        Brightness.dark,
        CustomToken.accent,
        const Color(0xFFAABBCC),
      );

      final row = await db.navStateDao.current();
      expect(row?.lightVariant, 'custom');
      expect(row?.darkVariant, 'custom');
      expect(row?.customThemeJson, isNotNull);

      final fresh = ThemeController(db: db);
      await fresh.restore();
      expect(fresh.lightVariant, LightVariant.custom);
      expect(fresh.darkVariant, DarkVariant.custom);
      expect(fresh.customTheme.lightBase, LightVariant.paper);
      expect(fresh.customTheme.darkBase, DarkVariant.midnight);
      expect(
        fresh.customTheme.lightOverrides[CustomToken.background],
        const Color(0xFF112233),
      );
      expect(fresh.customDarkAccent, const Color(0xFFAABBCC));
      // The non-accent override is baked into the resolved tokens; accent is
      // exposed separately for buildInTheme's accentOverride.
      expect(fresh.lightTokens.bg, const Color(0xFF112233));
    },
  );

  test('lightTokens/darkTokens have stable identity until they change', () {
    final controller = ThemeController(db: db);

    // Preset side returns the const singleton every call.
    expect(identical(controller.lightTokens, controller.lightTokens), isTrue);
    expect(controller.lightTokens, same(InTheme.lightSand));

    controller.setLightVariant(LightVariant.custom);
    final a = controller.lightTokens;
    final b = controller.lightTokens;
    expect(identical(a, b), isTrue, reason: 'memoised across unrelated reads');

    controller.setCustomOverride(
      Brightness.light,
      CustomToken.surface,
      const Color(0xFF010203),
    );
    expect(
      identical(controller.lightTokens, a),
      isFalse,
      reason: 'cache invalidated when the custom palette changes',
    );
  });

  test('clearCustomSide reverts a side to its base preset', () async {
    final controller = ThemeController(db: db);
    await controller.setLightVariant(LightVariant.custom);
    await controller.setCustomOverride(
      Brightness.light,
      CustomToken.ink,
      const Color(0xFF445566),
    );
    expect(controller.customTheme.lightOverrides, isNotEmpty);

    await controller.clearCustomSide(Brightness.light);
    expect(controller.customTheme.lightOverrides, isEmpty);
    expect(controller.lightTokens.ink, InTheme.lightSand.ink);

    final fresh = ThemeController(db: db);
    await fresh.restore();
    expect(fresh.customTheme.lightOverrides, isEmpty);
  });

  test('selecting a preset variant restores the const singleton', () async {
    final controller = ThemeController(db: db);
    await controller.setLightVariant(LightVariant.custom);
    await controller.setCustomOverride(
      Brightness.light,
      CustomToken.background,
      const Color(0xFF000001),
    );
    expect(controller.lightTokens, isNot(same(InTheme.lightMist)));

    await controller.setLightVariant(LightVariant.mist);
    expect(controller.lightTokens, same(InTheme.lightMist));
  });

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
