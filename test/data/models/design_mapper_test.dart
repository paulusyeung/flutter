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
