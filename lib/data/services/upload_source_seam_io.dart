import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:admin/data/services/upload_source.dart';

/// Native filesystem-backed [UploadSource]. This is the **byte-identical**
/// pre-web upload path: filename from `p.basename`, length from `File.length`,
/// range reads streamed in 64 KiB pages (lifted verbatim from the old
/// `ApiClient._readBytes`), and `MultipartFile.fromPath` for the simple
/// uploads (streams, doesn't buffer).
class FileUploadSource implements UploadSource {
  FileUploadSource(this.path) : _file = File(path);

  final String path;
  final File _file;

  @override
  String get fileName => p.basename(path);

  @override
  Future<int> length() => _file.length();

  @override
  Future<Uint8List> readRange(int start, int end) async {
    final out = Uint8List(end - start);
    var offset = 0;
    final stream = _file.openRead(start, end);
    await for (final block in stream) {
      out.setRange(offset, offset + block.length, block);
      offset += block.length;
    }
    return out;
  }

  @override
  Future<http.MultipartFile> toMultipartFile(String field) =>
      http.MultipartFile.fromPath(field, path);

  @override
  Future<bool> exists() => _file.exists();

  @override
  Map<String, dynamic> toPayload() => {'local_path': path};
}

UploadSource fileUploadSource(String path) => FileUploadSource(path);
