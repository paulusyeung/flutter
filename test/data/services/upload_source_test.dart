@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:admin/data/services/upload_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BytesUploadSource', () {
    final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));
    final src = BytesUploadSource(bytes, 'photo.png');

    test('fileName / length', () async {
      expect(src.fileName, 'photo.png');
      expect(await src.length(), 64);
    });

    test('readRange returns the requested slice', () async {
      final slice = await src.readRange(10, 20);
      expect(slice, bytes.sublist(10, 20));
    });

    test('toMultipartFile carries field, length and filename', () async {
      final mp = await src.toMultipartFile('documents[]');
      expect(mp.field, 'documents[]');
      expect(mp.length, 64);
      expect(mp.filename, 'photo.png');
    });

    test('exists is always true (bytes are self-contained)', () async {
      expect(await src.exists(), isTrue);
    });

    test('toPayload ↔ fromPayload round-trips the bytes', () {
      final payload = src.toPayload();
      expect(payload['file_name'], 'photo.png');
      final restored = UploadSource.fromPayload(payload);
      expect(restored, isA<BytesUploadSource>());
      expect((restored as BytesUploadSource).bytes, bytes);
      expect(restored.fileName, 'photo.png');
    });
  });

  group('UploadSource.fromPayload', () {
    test(
      'local_path → native FileUploadSource (back-compat with old rows)',
      () {
        final src = UploadSource.fromPayload({
          'local_path': '/tmp/a/backup.zip',
        });
        // Don't depend on the private type name; assert observable behaviour.
        expect(src.fileName, 'backup.zip');
        expect(src.toPayload(), {'local_path': '/tmp/a/backup.zip'});
      },
    );

    test('upload_bytes_b64 → BytesUploadSource', () {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      final src = UploadSource.fromPayload({
        'upload_bytes_b64': base64Encode(data),
        'file_name': 'x.bin',
      });
      expect(src, isA<BytesUploadSource>());
      expect((src as BytesUploadSource).bytes, data);
      expect(src.fileName, 'x.bin');
    });

    test('missing both keys throws ArgumentError', () {
      expect(
        () => UploadSource.fromPayload(const {'entity_id': 'e1'}),
        throwsArgumentError,
      );
    });
  });

  group('fileUploadSource (native streaming, byte-identical path)', () {
    test('reads ranges off disk and reports basename', () async {
      final tmp = await Directory.systemTemp.createTemp('upload_source_test_');
      addTearDown(() => tmp.delete(recursive: true));
      final f = File('${tmp.path}/doc.pdf');
      final data = Uint8List.fromList(List<int>.generate(200, (i) => i & 0xff));
      await f.writeAsBytes(data);

      final src = fileUploadSource(f.path);
      expect(src.fileName, 'doc.pdf');
      expect(await src.length(), 200);
      expect(await src.readRange(0, 50), data.sublist(0, 50));
      expect(await src.readRange(128, 200), data.sublist(128, 200));
      expect(await src.exists(), isTrue);
      expect(src.toPayload(), {'local_path': f.path});

      await f.delete();
      expect(await src.exists(), isFalse);
    });
  });
}
