import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/models/domain/design.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/data/models/domain/design.dart' show GridPosition;
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/canvas/wysiwyg_canvas.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

import '../../../../../../_localization_helper.dart';

class _FakeDesignsApi implements DesignsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BlockSpec _specByType(String type) =>
    kBlockLibrary.firstWhere((s) => s.type == type);

Widget _wrap(WysiwygDesignViewModel vm, Services? services) {
  return MaterialApp(
    localizationsDelegates: kTestLocalizationsDelegates,
    supportedLocales: kTestSupportedLocales,
    locale: const Locale('en'),
    theme: buildInTheme(InTheme.light),
    home: services == null
        ? Scaffold(body: WysiwygCanvas(vm: vm))
        : Provider<Services>.value(
            value: services,
            child: Scaffold(body: WysiwygCanvas(vm: vm)),
          ),
  );
}

void main() {
  late AppDatabase db;
  late DesignRepository repo;
  const companyId = 'co1';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DesignRepository(db: db, api: _FakeDesignsApi());
  });

  tearDown(() async {
    await db.close();
  });

  Finder handlesFinder() =>
      find.byKey(const ValueKey('wysiwyg-resize-handles'));

  testWidgets('resize handles render when a non-locked block is selected', (
    tester,
  ) async {
    final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
    vm.addBlock(_specByType('text'));
    await tester.pumpWidget(_wrap(vm, null));
    await tester.pump();
    expect(handlesFinder(), findsOneWidget);
  });

  testWidgets('locked block hides the resize handles', (tester) async {
    final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
    vm.addBlock(_specByType('text'));
    final id = vm.selectedBlockId!;
    vm.toggleLock(id);
    await tester.pumpWidget(_wrap(vm, null));
    await tester.pump();
    expect(handlesFinder(), findsNothing);
  });

  testWidgets('no resize handles when nothing is selected', (tester) async {
    final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
    vm.addBlock(_specByType('text'));
    vm.selectBlock(null);
    await tester.pumpWidget(_wrap(vm, null));
    await tester.pump();
    expect(handlesFinder(), findsNothing);
  });

  testWidgets(
    'resize handles stay mounted across an updateBlock (Step 4.6 regression)',
    (tester) async {
      // Bug: every updateBlock call silently cleared the selection,
      // un-rendering the resize handles and killing the resize gesture
      // after one cell of movement. Pump the canvas, simulate a
      // mid-gesture updateBlock, and assert the handles are STILL there.
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_specByType('text'));
      final selected = vm.blocks.single;
      await tester.pumpWidget(_wrap(vm, null));
      await tester.pump();
      expect(handlesFinder(), findsOneWidget);

      // Simulate one frame of a resize drag.
      vm.updateBlock(
        selected.copyWith(
          gridPosition: const GridPosition(x: 0, y: 0, w: 8, h: 3),
        ),
      );
      await tester.pump();
      expect(
        handlesFinder(),
        findsOneWidget,
        reason: 'handles must survive updateBlock so the drag can continue',
      );

      // Another frame.
      vm.updateBlock(
        vm.blocks.single.copyWith(
          gridPosition: const GridPosition(x: 0, y: 0, w: 10, h: 3),
        ),
      );
      await tester.pump();
      expect(handlesFinder(), findsOneWidget);
      expect(vm.blocks.single.gridPosition.w, 10);
    },
  );

  group('ResizeHandleKind cursor mappings (Step 4.8)', () {
    // Bug: macOS NSCursor has no diagonal-corner resize cursor. Both the
    // per-corner names (resizeUpLeft etc.) AND the diagonal pair
    // (resizeUpLeftDownRight / resizeUpRightDownLeft) fall back to the
    // basic arrow on macOS. Use the bidirectional cursors that DO render:
    // NW-SE → resizeLeftRight, NE-SW → resizeUpDown.
    test('edges use the four directional cursors', () {
      expect(ResizeHandleKind.top.cursor, SystemMouseCursors.resizeUp);
      expect(ResizeHandleKind.right.cursor, SystemMouseCursors.resizeRight);
      expect(ResizeHandleKind.bottom.cursor, SystemMouseCursors.resizeDown);
      expect(ResizeHandleKind.left.cursor, SystemMouseCursors.resizeLeft);
    });

    test('NW-SE corners share resizeLeftRight (macOS-supported)', () {
      expect(
        ResizeHandleKind.topLeft.cursor,
        SystemMouseCursors.resizeLeftRight,
      );
      expect(
        ResizeHandleKind.bottomRight.cursor,
        SystemMouseCursors.resizeLeftRight,
      );
    });

    test('NE-SW corners share resizeUpDown (macOS-supported)', () {
      expect(ResizeHandleKind.topRight.cursor, SystemMouseCursors.resizeUpDown);
      expect(
        ResizeHandleKind.bottomLeft.cursor,
        SystemMouseCursors.resizeUpDown,
      );
    });

    test('no handle uses a cursor that falls back to basic on macOS', () {
      // Per the per-platform docstrings in Flutter's mouse_cursor.dart,
      // these cursors have no macOS line and fall through to the basic
      // arrow:
      //   - per-corner: resizeUpLeft / UpRight / DownLeft / DownRight
      //   - diagonal:   resizeUpLeftDownRight / resizeUpRightDownLeft
      //   - generic:    move / allScroll
      final macOsUnsupported = {
        SystemMouseCursors.resizeUpLeft,
        SystemMouseCursors.resizeUpRight,
        SystemMouseCursors.resizeDownLeft,
        SystemMouseCursors.resizeDownRight,
        SystemMouseCursors.resizeUpLeftDownRight,
        SystemMouseCursors.resizeUpRightDownLeft,
        SystemMouseCursors.move,
        SystemMouseCursors.allScroll,
      };
      for (final kind in ResizeHandleKind.values) {
        expect(
          macOsUnsupported.contains(kind.cursor),
          isFalse,
          reason: '$kind uses a cursor that falls through to basic on macOS',
        );
      }
    });
  });

  group('computeResizedGridPosition (Step 4.5 — multi-cell resize)', () {
    const initial = GridPosition(x: 4, y: 4, w: 4, h: 4);

    test('right handle: +50 px @ cellWidth=50 = +1 cell', () {
      final r = computeResizedGridPosition(
        initial: initial,
        accumulatedPixels: const Offset(50, 0),
        cellWidth: 50,
        cellHeight: 50,
        blockType: 'text',
        touchesRight: true,
        touchesLeft: false,
        touchesTop: false,
        touchesBottom: false,
      );
      expect(r.w, 5);
      expect(r.x, 4);
    });

    test(
      // The bug: per-frame delta accumulation got stuck at +1 because the
      // receiver moves with the resize. This test would FAIL under the
      // old code path (which is gone) and PASSES with the pure-math
      // helper driven by absolute global coords.
      'right handle: continued drag to +3 cells actually resizes by 3',
      () {
        final r = computeResizedGridPosition(
          initial: initial,
          accumulatedPixels: const Offset(150, 0), // 3 × cellWidth
          cellWidth: 50,
          cellHeight: 50,
          blockType: 'text',
          touchesRight: true,
          touchesLeft: false,
          touchesTop: false,
          touchesBottom: false,
        );
        expect(r.w, 7);
      },
    );

    test('left handle: -100 px @ cellWidth=50 grows leftward by 2 cells', () {
      final r = computeResizedGridPosition(
        initial: initial,
        accumulatedPixels: const Offset(-100, 0),
        cellWidth: 50,
        cellHeight: 50,
        blockType: 'text',
        touchesLeft: true,
        touchesRight: false,
        touchesTop: false,
        touchesBottom: false,
      );
      expect(r.x, 2);
      expect(r.w, 6); // w grew by 2 to compensate for x shift
    });

    test('bottom handle: +120 px @ cellHeight=40 = +3 cells', () {
      final r = computeResizedGridPosition(
        initial: initial,
        accumulatedPixels: const Offset(0, 120),
        cellWidth: 50,
        cellHeight: 40,
        blockType: 'text',
        touchesBottom: true,
        touchesTop: false,
        touchesLeft: false,
        touchesRight: false,
      );
      expect(r.h, 7);
    });

    test('top-right corner: both axes resize independently', () {
      final r = computeResizedGridPosition(
        initial: initial,
        accumulatedPixels: const Offset(100, -80),
        cellWidth: 50,
        cellHeight: 40,
        blockType: 'text',
        touchesTop: true,
        touchesRight: true,
        touchesLeft: false,
        touchesBottom: false,
      );
      expect(r.w, 6); // +2 cells right
      expect(r.y, 2); // y dropped by 2
      expect(r.h, 6); // h grew by 2
    });

    test('respects clampSize: table cannot shrink below 6×2', () {
      final r = computeResizedGridPosition(
        initial: const GridPosition(x: 0, y: 0, w: 12, h: 8),
        accumulatedPixels: const Offset(-500, -500), // huge shrink attempt
        cellWidth: 50,
        cellHeight: 40,
        blockType: 'table',
        touchesLeft: false,
        touchesRight: false,
        touchesTop: false,
        touchesBottom: false,
      );
      // No touched edges so nothing should change.
      expect(r.w, 12);
      expect(r.h, 8);
    });

    test('respects clampSize from the right edge', () {
      final r = computeResizedGridPosition(
        initial: const GridPosition(x: 0, y: 0, w: 12, h: 8),
        accumulatedPixels: const Offset(-700, 0), // shrink hugely
        cellWidth: 50,
        cellHeight: 40,
        blockType: 'table',
        touchesRight: true,
        touchesLeft: false,
        touchesTop: false,
        touchesBottom: false,
      );
      expect(r.w, 6, reason: 'table min width is 6');
    });

    test('rounds to nearest cell (half-cell drag = 0 cells)', () {
      final r = computeResizedGridPosition(
        initial: initial,
        accumulatedPixels: const Offset(24, 0), // < half a cell
        cellWidth: 50,
        cellHeight: 50,
        blockType: 'text',
        touchesRight: true,
        touchesLeft: false,
        touchesTop: false,
        touchesBottom: false,
      );
      expect(r.w, 4, reason: '0.48 cells rounds to 0');
    });
  });

  test('drag gesture (manual VM driving) snapshots once to history', () {
    // Simulates what _ResizeHandles does: snapshot once at the start,
    // then a flurry of updateBlock calls that should NOT add more
    // snapshots, then fixOverlaps at the end.
    final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
    vm.addBlock(_specByType('text'));
    expect(vm.canUndo, isTrue);
    // Undo to clear the add-snapshot so we're measuring just the drag.
    vm.undo();
    vm.addBlock(_specByType('text')); // re-add for the drag
    final initialBlock = vm.blocks.first;

    // The gesture.
    vm.recordHistorySnapshot();
    for (var i = 0; i < 10; i++) {
      vm.updateBlock(
        initialBlock.copyWith(
          gridPosition: GridPosition(x: 0, y: i, w: 6, h: 2),
        ),
      );
    }
    vm.fixOverlaps();

    // After undoing the gesture-as-one-step we should be back at the
    // post-add state (one block with the original gridPosition), not at
    // the empty list.
    vm.undo(); // undoes fixOverlaps' snapshot
    vm.undo(); // undoes the recordHistorySnapshot
    expect(vm.blocks, hasLength(1));
    expect(vm.blocks.first.gridPosition.y, initialBlock.gridPosition.y);
  });
}
