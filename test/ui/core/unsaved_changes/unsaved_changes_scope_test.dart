import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_guard.dart';
import 'package:admin/ui/core/unsaved_changes/unsaved_changes_scope.dart';

class _DirtyNotifier extends ChangeNotifier {
  bool isDirty = false;
  int discardCount = 0;

  void markDirty() {
    isDirty = true;
    notifyListeners();
  }

  void reset() {
    isDirty = false;
    discardCount++;
    notifyListeners();
  }
}

class _FakeServices implements Services {
  _FakeServices(this.unsavedChangesGuard);
  @override
  final UnsavedChangesGuard unsavedChangesGuard;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets(
    'UnsavedChangesScope registers on mount, unregisters on dispose',
    (tester) async {
      final guard = UnsavedChangesGuard();
      final services = _FakeServices(guard);
      final src = _DirtyNotifier();

      Widget host(Widget child) => MaterialApp(
        home: Provider<Services>.value(value: services, child: child),
      );

      await tester.pumpWidget(
        host(
          UnsavedChangesScope(
            isDirty: () => src.isDirty,
            source: src,
            onDiscard: src.reset,
            child: const Scaffold(body: Text('mounted')),
          ),
        ),
      );
      expect(guard.registeredCount, 1);
      expect(guard.hasUnsaved, isFalse);
      src.markDirty();
      expect(guard.hasUnsaved, isTrue);

      // Replace with a tree that doesn't contain the scope — it should
      // unregister and the guard's count should drop back to 0.
      await tester.pumpWidget(host(const Scaffold(body: Text('replaced'))));
      expect(guard.registeredCount, 0);
      expect(guard.hasUnsaved, isFalse);
    },
  );

  testWidgets(
    'UnsavedChangesScope re-registers when its source is swapped in place',
    (tester) async {
      final guard = UnsavedChangesGuard();
      final services = _FakeServices(guard);
      final src1 = _DirtyNotifier();
      final src2 = _DirtyNotifier();

      Widget host(_DirtyNotifier src) => MaterialApp(
        home: Provider<Services>.value(
          value: services,
          child: UnsavedChangesScope(
            isDirty: () => src.isDirty,
            source: src,
            onDiscard: src.reset,
            child: const Scaffold(body: Text('mounted')),
          ),
        ),
      );

      await tester.pumpWidget(host(src1));
      expect(guard.registeredCount, 1);

      // Swap the backing source in place (same element position, no key) —
      // mirrors `SettingsCompanyScopedHost` rebuilding its ViewModel on a
      // company switch. The guard must follow the new source instead of
      // staying frozen on the old (disposed) one.
      await tester.pumpWidget(host(src2));
      expect(guard.registeredCount, 1);

      src2.markDirty();
      expect(
        guard.hasUnsaved,
        isTrue,
        reason: 'edits on the swapped-in source must be guarded',
      );

      src2.reset();
      src1.markDirty();
      expect(
        guard.hasUnsaved,
        isFalse,
        reason: 'the swapped-out source must no longer be consulted',
      );
    },
  );
}
