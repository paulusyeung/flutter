import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/services/upload_source.dart';
import 'package:admin/ui/core/widgets/file_drop_zone.dart';

/// `FileDropZone`'s drop/pick gestures can't be simulated in a widget test, so
/// the value is in the pure conversion core every entry point funnels through.
void main() {
  group('uploadSourceFromParts', () {
    test('native path → streaming FileUploadSource (no bytes copied)', () {
      final src = uploadSourceFromParts(
        path: '/tmp/a/report.pdf',
        name: 'report.pdf',
      );
      expect(src, isNotNull);
      expect(src!.fileName, 'report.pdf');
      // Path form carries `local_path` in the outbox payload, not base64 bytes.
      expect(src.toPayload(), {'local_path': '/tmp/a/report.pdf'});
    });

    test('bytes without a path → in-memory BytesUploadSource', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final src = uploadSourceFromParts(bytes: bytes, name: 'logo.png');
      expect(src, isA<BytesUploadSource>());
      expect(src!.fileName, 'logo.png');
      expect(src.toPayload().containsKey('upload_bytes_b64'), isTrue);
    });

    test('a real path wins over bytes on native', () {
      final src = uploadSourceFromParts(
        path: '/tmp/x.pdf',
        bytes: Uint8List.fromList([9]),
        name: 'x.pdf',
      );
      expect(src!.toPayload().containsKey('local_path'), isTrue);
    });

    test('neither a usable path nor bytes → null (skipped by callers)', () {
      expect(uploadSourceFromParts(name: 'x.pdf'), isNull);
      expect(uploadSourceFromParts(path: '', name: 'x.pdf'), isNull);
    });
  });
}
