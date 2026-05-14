import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/domain/document.dart';

void main() {
  group('Document mapper', () {
    test('Document.fromApi copies every field', () {
      const api = DocumentApi(
        id: '42',
        name: 'invoice.pdf',
        hash: 'abc123',
        type: 'pdf',
        url: 'https://example.com/abc.pdf',
        size: 12345,
        isPublic: false,
        createdAt: 1700000000,
        updatedAt: 1710000000,
      );
      final domain = Document.fromApi(api);
      expect(domain.id, '42');
      expect(domain.name, 'invoice.pdf');
      expect(domain.hash, 'abc123');
      expect(domain.type, 'pdf');
      expect(domain.url, 'https://example.com/abc.pdf');
      expect(domain.size, 12345);
      expect(domain.isPublic, isFalse);
      expect(domain.createdAt, 1700000000);
      expect(domain.updatedAt, 1710000000);
    });

    test(
      'Document.toApi round-trips through DocumentApi.toJson without loss',
      () {
        const original = DocumentApi(
          id: '42',
          name: 'pic.png',
          hash: 'h',
          type: 'png',
          url: 'https://example.com/h.png',
          size: 999,
          isPublic: true,
          createdAt: 1,
          updatedAt: 2,
        );
        final domain = Document.fromApi(original);
        final json = domain.toApi().toJson();
        final restored = DocumentApi.fromJson(json);
        expect(restored, original);
      },
    );

    test(
      'Document.fromApi defaults isPublic to true when DocumentApi default',
      () {
        const api = DocumentApi(id: '1');
        final domain = Document.fromApi(api);
        // `DocumentApi.isPublic` defaults to true; the domain mapping
        // preserves it.
        expect(domain.isPublic, isTrue);
      },
    );
  });
}
