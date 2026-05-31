import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/theme.dart';
import 'package:admin/data/db/app_database.dart';
import 'package:admin/data/repositories/design_repository.dart';
import 'package:admin/data/services/designs_api.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/block_library.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/cell_typography_editor.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_editors/info_block_properties.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_editors/table_block_properties.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_editors/text_block_properties.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_editors/total_block_properties.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/property_panel/property_inputs.dart';
import 'package:admin/ui/features/settings/views/advanced/invoice_design/wysiwyg/wysiwyg_design_view_model.dart';

import '../../../../../../_localization_helper.dart';

class _FakeDesignsApi implements DesignsApi {
  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

BlockSpec _spec(String type) =>
    kBlockLibrary.firstWhere((s) => s.type == type);

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: kTestLocalizationsDelegates,
  supportedLocales: kTestSupportedLocales,
  locale: const Locale('en'),
  theme: buildInTheme(InTheme.light),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

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

  group('TableBlockProperties', () {
    testWidgets('lists each column with delete + drag handle', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('table'));
      final block = vm.blocks.single;
      await tester.pumpWidget(_wrap(TableBlockProperties(vm: vm, block: block)));
      await tester.pump();
      // Default products table ships 5 columns.
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(5));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(5));
    });

    testWidgets('delete removes the column from properties', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('table'));
      final initial = (vm.blocks.single.properties['columns'] as List).length;
      await tester.pumpWidget(_wrap(
        TableBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pump();
      final after = (vm.blocks.single.properties['columns'] as List).length;
      expect(after, initial - 1);
    });

    testWidgets('shows an Add column button', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('table'));
      await tester.pumpWidget(_wrap(
        TableBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      expect(find.text('Add Column'), findsOneWidget);
    });
  });

  group('TotalBlockProperties', () {
    testWidgets('lists each item with show toggle + drag handle', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('total'));
      await tester.pumpWidget(_wrap(
        TotalBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      // 6 default items.
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(6));
      // Switch widgets for show toggle (one per item).
      expect(find.byType(Switch), findsAtLeastNWidgets(6));
    });

    testWidgets('renders the Show labels toggle', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('total'));
      await tester.pumpWidget(_wrap(
        TotalBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      expect(find.text('Show labels'), findsOneWidget);
    });
  });

  group('InfoBlockProperties — Add field flow', () {
    testWidgets('lists each fieldConfig with hide + delete', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('client-info'));
      await tester.pumpWidget(_wrap(
        InfoBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      // Default client-info ships 5 fieldConfigs.
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(5));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(5));
    });

    testWidgets('renders the Add field button', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('client-info'));
      await tester.pumpWidget(_wrap(
        InfoBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      expect(find.text('Add Field'), findsOneWidget);
    });

    testWidgets('toggling hide-if-empty updates the field', (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('client-info'));
      await tester.pumpWidget(_wrap(
        InfoBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      // Phase 7c moved the hide-if-empty toggle into the per-row
      // expansion: tap the chevron to expand the first row, then flip
      // the Switch.
      final firstExpand = find.byIcon(Icons.expand_more).first;
      await tester.tap(firstExpand);
      await tester.pump();
      final hideSwitch = find
          .ancestor(
            of: find.text('Hide if Empty'),
            matching: find.byType(SwitchListTile),
          )
          .first;
      await tester.tap(hideSwitch);
      await tester.pump();
      final fields =
          vm.blocks.single.properties['fieldConfigs'] as List;
      expect((fields.first as Map)['hideIfEmpty'], isFalse);
    });
  });

  group('Phase 8a — PxInput clamping (table border width)', () {
    testWidgets('PxInput maxPx clamps to the cap', (tester) async {
      String? captured;
      await tester.pumpWidget(_wrap(PxInput(
        labelKey: 'width',
        value: null,
        maxPx: 20,
        onChanged: (v) => captured = v,
      )));
      await tester.enterText(find.byType(TextField), '999');
      expect(captured, '20px');

      await tester.enterText(find.byType(TextField), '15');
      expect(captured, '15px');
    });

    testWidgets('PxInput minPx floors low values', (tester) async {
      String? captured;
      await tester.pumpWidget(_wrap(PxInput(
        labelKey: 'width',
        value: null,
        minPx: 0,
        maxPx: 20,
        onChanged: (v) => captured = v,
      )));
      // Negative not parseable as int; '0' clamps in-bounds.
      await tester.enterText(find.byType(TextField), '0');
      expect(captured, '0px');
    });
  });

  group('Phase 8d — Total per-item CellTypographyEditor', () {
    testWidgets(
      'expansion renders a CellTypographyEditor sub-card with italic toggle',
      (tester) async {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_spec('total'));
        await tester.pumpWidget(_wrap(
          TotalBlockProperties(vm: vm, block: vm.blocks.single),
        ));
        await tester.pump();
        // Expand the first item row.
        final firstExpand = find.byIcon(Icons.expand_more).first;
        await tester.tap(firstExpand);
        await tester.pumpAndSettle();
        // Sub-card lands.
        expect(find.byType(CellTypographyEditor), findsOneWidget);
        // Italic toggle inside the sub-card flips fontStyle.
        final italic = find
            .ancestor(of: find.text('Italic'), matching: find.byType(OutlinedButton))
            .first;
        await tester.tap(italic);
        await tester.pump();
        final items = vm.blocks.single.properties['items'] as List;
        expect((items.first as Map)['fontStyle'], 'italic');
      },
    );
  });

  group('Phase 8c — Text content 300 ms debounce', () {
    testWidgets(
      'typing does not commit until the 300ms timer fires',
      (tester) async {
        final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
        vm.addBlock(_spec('text'));
        await tester.pumpWidget(_wrap(
          TextBlockProperties(vm: vm, block: vm.blocks.single),
        ));
        await tester.pump();
        // Find the multi-line content TextField (the only one with
        // OutlineInputBorder + no labelText is the content field).
        final contentField = find.byType(TextField).first;
        await tester.enterText(contentField, 'h');
        await tester.enterText(contentField, 'hi');
        await tester.pump(const Duration(milliseconds: 100));
        // Still within the debounce window — nothing committed yet.
        expect(vm.blocks.single.properties['content'], isNot('hi'));
        // Past the debounce — the latest value commits exactly once.
        await tester.pump(const Duration(milliseconds: 250));
        expect(vm.blocks.single.properties['content'], 'hi');
      },
    );
  });

  group('Phase 8j — Total keepTogether switch', () {
    testWidgets('toggling the keep-together switch writes the boolean',
        (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('total'));
      await tester.pumpWidget(_wrap(
        TotalBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      // Defaults to false; tap the switch via its title text. Editor
      // is tall — scroll the switch into the visible viewport first.
      final pageBreakSwitch = find
          .ancestor(
            of: find.text('Force page break before this block'),
            matching: find.byType(SwitchListTile),
          )
          .first;
      await tester.ensureVisible(pageBreakSwitch);
      await tester.pump();
      await tester.tap(pageBreakSwitch);
      await tester.pump();
      expect(vm.blocks.single.properties['keepTogether'], isTrue);
    });
  });

  group('Phase 9b — Total block-level fontSize', () {
    testWidgets('selecting a font-size chip writes the block-level value',
        (tester) async {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.addBlock(_spec('total'));
      await tester.pumpWidget(_wrap(
        TotalBlockProperties(vm: vm, block: vm.blocks.single),
      ));
      await tester.pump();
      // FontSizeInput exposes presets as ChoiceChips. Pick 18px.
      final chip = find.widgetWithText(ChoiceChip, '18px').first;
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();
      expect(vm.blocks.single.properties['fontSize'], '18px');
    });
  });

  group('Phase 9c/9d — embedDocuments + hideEmptyColumns setting', () {
    // The PropertyPanel's document form has pre-existing layout density
    // (font dropdowns overflow when squeezed into the panel's 280 px
    // width during widget tests). The UI wiring is a trivial
    // `onChanged: (v) => vm.setDocumentSettings(ds.copyWith(...))` —
    // assert directly on the VM that both new fields round-trip
    // through `setDocumentSettings + copyWith`.
    test('setDocumentSettings round-trips embedDocuments', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      expect(vm.documentSettings.embedDocuments, isFalse);
      vm.setDocumentSettings(
        vm.documentSettings.copyWith(embedDocuments: true),
      );
      expect(vm.documentSettings.embedDocuments, isTrue);
    });

    test('setDocumentSettings round-trips hideEmptyColumns', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      expect(vm.documentSettings.hideEmptyColumns, isFalse);
      vm.setDocumentSettings(
        vm.documentSettings.copyWith(hideEmptyColumns: true),
      );
      expect(vm.documentSettings.hideEmptyColumns, isTrue);
    });

    test('toggling one flag leaves the other untouched', () {
      final vm = WysiwygDesignViewModel(repo: repo, companyId: companyId);
      vm.setDocumentSettings(
        vm.documentSettings.copyWith(embedDocuments: true),
      );
      expect(vm.documentSettings.embedDocuments, isTrue);
      expect(vm.documentSettings.hideEmptyColumns, isFalse);
      vm.setDocumentSettings(
        vm.documentSettings.copyWith(hideEmptyColumns: true),
      );
      expect(vm.documentSettings.embedDocuments, isTrue);
      expect(vm.documentSettings.hideEmptyColumns, isTrue);
    });
  });
}
