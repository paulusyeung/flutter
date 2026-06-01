import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/design_api_model.dart';
import 'package:admin/data/models/domain/design.dart';

void main() {
  group('DesignApi ↔ Design round-trip', () {
    test('fromApi projects entities CSV to a list', () {
      const api = DesignApi(
        id: 'd1',
        name: 'Plain',
        isCustom: false,
        isActive: true,
        isTemplate: false,
        isFree: true,
        entities: 'invoice,quote,credit',
        design: DesignTemplateApi(body: '<body/>'),
        createdAt: 100,
        updatedAt: 200,
        archivedAt: 0,
        isDeleted: false,
      );
      final domain = Design.fromApi(api);
      expect(domain.id, 'd1');
      expect(domain.entities, ['invoice', 'quote', 'credit']);
      expect(domain.template.body, '<body/>');
      expect(domain.isFree, isTrue);
      expect(domain.isDirty, isFalse);
      expect(domain.archivedAt, isNull);
    });

    test('empty entities CSV projects to an empty list (not [\'\'])', () {
      const api = DesignApi(
        id: 'd2',
        name: 'Empty',
        entities: '',
        design: DesignTemplateApi(),
        updatedAt: 1,
      );
      expect(Design.fromApi(api).entities, isEmpty);
    });

    test('toApiJson re-joins the entities list with commas', () {
      final api = DesignApi(
        id: 'd3',
        name: 'Custom',
        isCustom: true,
        entities: 'invoice,credit',
        design: const DesignTemplateApi(body: '<x/>'),
        updatedAt: 5,
      );
      final json = Design.fromApi(api).toApiJson(preserveTempId: true);
      expect(json['entities'], 'invoice,credit');
      expect(json['name'], 'Custom');
      expect(json['is_custom'], isTrue);
    });

    test('tmp_ ids are dropped from toApiJson unless preserveTempId', () {
      final domain = Design.fromApi(
        const DesignApi(
          id: 'tmp_abc',
          name: 'Draft',
          design: DesignTemplateApi(),
          updatedAt: 1,
        ),
      );
      expect(
        domain.toApiJson()['id'],
        isNull,
        reason: 'tmp_ id stripped by default so create POST gets no id',
      );
      expect(domain.toApiJson(preserveTempId: true)['id'], 'tmp_abc');
    });

    test('DesignTemplate.toApi round-trips every section', () {
      const template = DesignTemplate(
        body: 'B',
        header: 'H',
        footer: 'F',
        includes: 'I',
        product: 'P',
        task: 'T',
      );
      final api = template.toApi();
      expect(api.body, 'B');
      expect(api.header, 'H');
      expect(api.footer, 'F');
      expect(api.includes, 'I');
      expect(api.product, 'P');
      expect(api.task, 'T');
    });

    test(
      'WYSIWYG: blocks + documentSettings round-trip preserves every field',
      () {
        // Mirrors the demo-server probe (Phase 0): the new fields are camelCase
        // on the wire and survive PUT → GET unchanged. Locking down the field
        // names here keeps the schema bridge in sync with the React contract.
        final json = <String, dynamic>{
          'id': 'designer-1',
          'name': 'Builder Test',
          'is_custom': true,
          'is_active': true,
          'is_template': false,
          'is_free': false,
          'entities': 'invoice',
          'design': <String, dynamic>{
            'body': '',
            'header': '',
            'footer': '',
            'includes': '',
            'product': '',
            'task': '',
            'blocks': [
              <String, dynamic>{
                'id': 'logo-abc-123',
                'type': 'logo',
                'gridPosition': {'x': 0, 'y': 0, 'w': 4, 'h': 2},
                'properties': {
                  'source': r'$company.logo',
                  'align': 'left',
                  'maxWidth': '200px',
                },
                'locked': true,
              },
              <String, dynamic>{
                'id': 'text-def-456',
                'type': 'text',
                'gridPosition': {'x': 4, 'y': 0, 'w': 8, 'h': 2},
                'properties': {'content': 'INVOICE', 'fontSize': '24px'},
              },
            ],
            'documentSettings': {
              'pageLayout': 'portrait',
              'pageSize': 'A4',
              'globalFontSize': 12,
              'primaryFont': 'Roboto',
              'secondaryFont': 'Roboto',
              'showPaidStamp': false,
              'showShippingAddress': true,
              'embedDocuments': false,
              'hideEmptyColumns': true,
              'pageNumbering': false,
              'pageMarginTop': 5,
              'pageMarginRight': 6,
              'pageMarginBottom': 7,
              'pageMarginLeft': 8,
              'pagePaddingTop': 30,
              'pagePaddingRight': 30,
              'pagePaddingBottom': 30,
              'pagePaddingLeft': 30,
            },
          },
          'updated_at': 1700000000,
          'created_at': 1700000000,
          'archived_at': 0,
          'is_deleted': false,
        };

        // Read in
        final api = DesignApi.fromJson(json);
        final domain = Design.fromApi(api);
        expect(domain.template.blocks, hasLength(2));
        expect(domain.template.blocks[0].id, 'logo-abc-123');
        expect(domain.template.blocks[0].type, 'logo');
        expect(domain.template.blocks[0].gridPosition.x, 0);
        expect(domain.template.blocks[0].gridPosition.w, 4);
        expect(domain.template.blocks[0].properties[r'$company.logo'], isNull);
        expect(
          domain.template.blocks[0].properties['source'],
          r'$company.logo',
        );
        expect(domain.template.blocks[0].locked, isTrue);
        expect(domain.template.blocks[1].locked, isFalse);
        final ds = domain.template.documentSettings!;
        expect(ds.pageLayout, 'portrait');
        expect(ds.globalFontSize, 12);
        expect(ds.showShippingAddress, isTrue);
        expect(ds.hideEmptyColumns, isTrue);
        expect(ds.pageMarginTop, 5);
        expect(ds.pageMarginLeft, 8);

        // Write out — every field survives. Round-trip through jsonEncode +
        // jsonDecode so nested typed objects are flattened to Maps the way
        // the network layer (jsonEncode in the repo) actually serializes them.
        final wire =
            jsonDecode(jsonEncode(domain.toApiJson(preserveTempId: true)))
                as Map<String, dynamic>;
        final designOut = wire['design'] as Map<String, dynamic>;
        final blocksOut = designOut['blocks'] as List<dynamic>;
        expect(blocksOut, hasLength(2));
        final firstBlockOut = blocksOut.first as Map<String, dynamic>;
        expect(firstBlockOut['id'], 'logo-abc-123');
        expect(firstBlockOut['type'], 'logo');
        expect(firstBlockOut['gridPosition'], {'x': 0, 'y': 0, 'w': 4, 'h': 2});
        expect(firstBlockOut['properties'], isA<Map<String, dynamic>>());
        expect(firstBlockOut['locked'], isTrue);
        final secondBlockOut = blocksOut[1] as Map<String, dynamic>;
        expect(
          secondBlockOut.containsKey('locked'),
          isFalse,
          reason:
              'locked=false → toApi() emits null, jsonEncode drops null keys via includeIfNull',
        );
        final dsOut = designOut['documentSettings'] as Map<String, dynamic>;
        expect(dsOut['pageLayout'], 'portrait');
        expect(dsOut['pageMarginTop'], 5);
        expect(dsOut['pageMarginLeft'], 8);
        expect(dsOut['globalFontSize'], 12);
      },
    );

    test('DesignTemplate.toApi() injects rowAlign/rowWidth/colStart/colSpan '
        'into every block at save time', () {
      // Regression for Phase 1.5 bug #1: the server needs these four
      // fields on every saved block to place them in flex rows. Without
      // them all blocks render as left-aligned regardless of grid x.
      final template = DesignTemplate(
        blocks: [
          DesignBlock(
            id: 'logo-1',
            type: 'logo',
            gridPosition: const GridPosition(x: 0, y: 0, w: 4, h: 2),
          ),
          DesignBlock(
            id: 'totals-1',
            type: 'total',
            gridPosition: const GridPosition(x: 8, y: 4, w: 4, h: 4),
          ),
        ],
      );

      final wire =
          jsonDecode(jsonEncode(template.toApi().toJson()))
              as Map<String, dynamic>;
      final blocks = wire['blocks'] as List<dynamic>;
      expect(blocks, hasLength(2));

      final logo = blocks[0] as Map<String, dynamic>;
      expect(logo['rowAlign'], 'left');
      expect(logo['rowWidth'], '33.333333%');
      expect(logo['colStart'], 1);
      expect(logo['colSpan'], 4);

      final totals = blocks[1] as Map<String, dynamic>;
      expect(totals['rowAlign'], 'right');
      expect(totals['rowWidth'], '33.333333%');
      expect(totals['colStart'], 9);
      expect(totals['colSpan'], 4);
    });

    test(
      'DesignTemplate.toApi() on legacy design (no blocks) is unchanged',
      () {
        const template = DesignTemplate(body: '<body/>');
        final wire =
            jsonDecode(jsonEncode(template.toApi().toJson()))
                as Map<String, dynamic>;
        expect(wire['blocks'], isEmpty);
        // No annotation pollution on the legacy path.
        expect(wire.containsKey('documentSettings'), isFalse);
      },
    );

    test(
      'design without blocks/documentSettings stays minimal on the wire',
      () {
        // Existing built-in designs (e.g. "Calm") return the design.* fields
        // only — no blocks, no documentSettings. The Dart model must not
        // ship documentSettings on the wire when unset; blocks may serialize
        // as [] (server preserves it and existing read paths ignore it).
        const domain = DesignTemplate(body: 'B');
        final wire =
            jsonDecode(jsonEncode(domain.toApi().toJson()))
                as Map<String, dynamic>;
        expect(
          wire.containsKey('documentSettings'),
          isFalse,
          reason: 'includeIfNull=false drops the key when unset',
        );
        expect(wire['blocks'], isA<List<dynamic>>());
        expect(wire['blocks'], isEmpty);
      },
    );

    test('DesignApi parses the live `/api/v1/designs` envelope shape', () {
      final json = <String, dynamic>{
        'id': 'VolejRejNm',
        'name': 'Clean',
        'is_custom': false,
        'is_active': true,
        'is_template': false,
        'is_free': true,
        'entities': 'invoice,quote,credit,purchase_order',
        'design': <String, dynamic>{
          'body': '<table/>',
          'header': '',
          'footer': '',
          'includes': '<style/>',
          'product': '',
          'task': '',
        },
        'updated_at': 1700000000,
        'created_at': 1600000000,
        'archived_at': 0,
        'is_deleted': false,
      };
      final api = DesignApi.fromJson(json);
      expect(api.id, 'VolejRejNm');
      expect(api.entities, 'invoice,quote,credit,purchase_order');
      expect(api.design.body, '<table/>');
      final domain = Design.fromApi(api);
      expect(domain.entities, hasLength(4));
      expect(domain.template.includes, '<style/>');
    });
  });
}
