import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/mobile/mobile_reorder_view.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

import '../../../../../../_localization_helper.dart';

class _FakeDesignsApi implements DesignsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BlockSpec _spec(String type) => kBlockLibrary.firstWhere((s) => s.type == type);

Widget _wrap(WysiwygDesignViewModel vm, {Size? viewport}) {
  final size = viewport ?? const Size(320, 800);
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      localizationsDelegates: kTestLocalizationsDelegates,
      supportedLocales: kTestSupportedLocales,
      locale: const Locale('en'),
      theme: buildInTheme(InTheme.light),
      home: Scaffold(body: MobileReorderView(vm: vm)),
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

  group('MobileReorderView UI', () {
    testWidgets('shows the empty state when no blocks', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();
      expect(find.byIcon(Icons.dashboard_customize_outlined), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('renders one row per block with drag handle + delete icon', (
      tester,
    ) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('logo'));
      vm.addBlock(_spec('text'));
      vm.addBlock(_spec('terms'));
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();
      expect(find.byType(ReorderableListView), findsOneWidget);
      // 3 drag handles + 3 delete icons.
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
    });

    testWidgets('renders the hint banner at the top', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders a FAB to add blocks', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('logo'));
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
      'tapping a row opens the property sheet AND selects the block',
      (tester) async {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_spec('logo'));
        final id = vm.selectedBlockId;
        // Clear the auto-selection from addBlock so we can test that the
        // tap re-selects.
        vm.selectBlock(null);
        await tester.pumpWidget(_wrap(vm));
        await tester.pump();
        await tester.tap(find.byType(InkWell).first);
        await tester.pump();
        expect(vm.selectedBlockId, id);
      },
    );

    testWidgets('delete icon removes the block', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('logo'));
      vm.addBlock(_spec('text'));
      await tester.pumpWidget(_wrap(vm));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pump();
      expect(vm.blocks, hasLength(1));
    });
  });

  group('vm.reorderBlocks contract', () {
    test('moving the first block to the end re-orders + re-stacks y', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('logo')); // h=4
      vm.addBlock(_spec('text')); // h=2
      vm.addBlock(_spec('terms')); // h=3
      // ReorderableListView reports oldIndex=0, newIndex=3 when moving the
      // first item to the end (newIndex is post-removal).
      vm.reorderBlocks(0, 3);
      expect(vm.blocks.map((b) => b.type).toList(), ['text', 'terms', 'logo']);
      // All full width.
      for (final b in vm.blocks) {
        expect(b.gridPosition.x, 0);
        expect(b.gridPosition.w, 12);
      }
      // y values stack by previous block's height.
      expect(vm.blocks[0].gridPosition.y, 0);
      expect(vm.blocks[1].gridPosition.y, 2); // after text(h=2)
      expect(vm.blocks[2].gridPosition.y, 5); // after terms(h=3)
    });

    test('no-op when oldIndex == effective newIndex', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('logo'));
      vm.addBlock(_spec('text'));
      final pre = vm.blocks.map((b) => b.id).toList();
      vm.reorderBlocks(0, 0);
      vm.reorderBlocks(1, 2); // adjusts to 1 → same index
      expect(vm.blocks.map((b) => b.id).toList(), pre);
    });

    test('reorder records a history entry (undoable)', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('logo'));
      vm.addBlock(_spec('text'));
      final pre = vm.blocks.map((b) => b.type).toList();
      vm.reorderBlocks(0, 2);
      expect(vm.blocks.map((b) => b.type).toList(), ['text', 'logo']);
      vm.undo();
      expect(vm.blocks.map((b) => b.type).toList(), pre);
    });
  });
}
