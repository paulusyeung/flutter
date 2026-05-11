import 'package:admin/app/theme_controller.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests target ThemeController's persistence contract:
///   * setting a mode writes to nav_state.theme_mode
///   * restore() round-trips the stored mode on next launch
///   * no notification fires when the same mode is set twice
/// They don't re-test Drift or ValueNotifier itself.

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  test(
    'set() writes the theme to nav_state for restore on next launch',
    () async {
      final controller = ThemeController(db: db);
      await controller.set(ThemeMode.dark);

      final row = await db.navStateDao.current();
      expect(row?.themeMode, 'dark');

      // Next launch: a fresh controller reads it back via restore().
      final fresh = ThemeController(db: db);
      expect(fresh.value, ThemeMode.system, reason: 'before restore');
      await fresh.restore();
      expect(fresh.value, ThemeMode.dark);
    },
  );

  test('set() does not notify when the same mode is chosen twice', () async {
    final controller = ThemeController(db: db, initial: ThemeMode.light);
    var notifications = 0;
    controller.addListener(() => notifications++);
    await controller.set(ThemeMode.light);
    expect(notifications, 0, reason: 'identical value is a no-op');
    await controller.set(ThemeMode.dark);
    expect(notifications, 1);
  });
}
