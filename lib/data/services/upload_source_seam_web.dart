import 'package:admin/data/services/upload_source.dart';

/// Web stub: there is no filesystem, so a `local_path` upload source can
/// never exist on web. Web screens always build a [BytesUploadSource], and
/// web outbox rows always carry `upload_bytes_b64` (never `local_path`), so
/// this is unreachable in practice — it throws to make a regression loud
/// instead of silently misbehaving.
UploadSource fileUploadSource(String path) => throw StateError(
  'fileUploadSource is not available on web (no filesystem); '
  'web uploads use BytesUploadSource. path=$path',
);
