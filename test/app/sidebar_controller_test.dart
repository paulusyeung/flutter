import 'package:admin/app/sidebar_controller.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests target the SidebarController persistence contract:
///   * toggle() writes to nav_state.sidebar_collapsed
///   * restore() round-trips the stored value on next launch
///   * setting the same value twice doesn't notify
///
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
    'toggle() writes the collapsed flag for restore on next launch',
    () async {
      final controller = SidebarController(db: db);
      expect(controller.value, isFalse, reason: 'default is expanded');
      await controller.toggle();

      final row = await db.navStateDao.current();
      expect(row?.sidebarCollapsed, isTrue);

      // Next launch: a fresh controller reads it back via restore().
      final fresh = SidebarController(db: db);
      expect(fresh.value, isFalse, reason: 'before restore');
      await fresh.restore();
      expect(fresh.value, isTrue);
    },
  );

  test('set() does not notify when the same value is chosen twice', () async {
    final controller = SidebarController(db: db);
    var notifications = 0;
    controller.addListener(() => notifications++);
    await controller.set(false);
    expect(notifications, 0, reason: 'identical value is a no-op');
    await controller.set(true);
    expect(notifications, 1);
  });
}
