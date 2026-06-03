import 'dart:typed_data';

/// Whether [bytes] look like a renderable PDF document.
///
/// `printing`'s rasterizer (`PdfPreviewRaster._raster`) throws
/// `RangeError (index): Invalid value: Valid value range is empty: 0` when
/// handed an empty or zero-page document — e.g. when a preview endpoint
/// returns an empty body, an HTML/JSON error page, or any non-PDF payload
/// that slipped past content-type checks. Call this before feeding bytes to
/// a `PdfPreview(build: ...)` and route a `false` result to the surrounding
/// error / empty state instead of the rasterizer.
///
/// The check is a cheap sniff, not a full parse: a renderable PDF (a) starts
/// with the 5-byte magic `%PDF-` (0x25 0x50 0x44 0x46 0x2D) and (b) ends with
/// the `%%EOF` marker the spec mandates as the file's last line. A truncated
/// download passes (a) but fails (b) — and a header-valid-but-truncated body is
/// exactly what parses to zero pages and trips the rasterizer's
/// `RangeError ... range is empty: 0`. Empty / wrong-content-type payloads fail
/// (a). The EOF marker is found by scanning only the final kilobyte, so the
/// cost stays O(1) in document size and trailing newlines / incremental-save
/// markers don't cause a false miss.
bool isRenderablePdf(Uint8List? bytes) {
  if (bytes == null || bytes.length < 5) return false;
  final hasHeader =
      bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46 && // F
      bytes[4] == 0x2D; //  -
  return hasHeader && _hasEofMarker(bytes);
}

/// Whether the `%%EOF` marker (0x25 0x25 0x45 0x4F 0x46) appears in the final
/// kilobyte of [bytes] — present in any complete PDF, absent in a truncated one.
bool _hasEofMarker(Uint8List bytes) {
  const marker = [0x25, 0x25, 0x45, 0x4F, 0x46]; // %%EOF
  final from = bytes.length > 1024 ? bytes.length - 1024 : 0;
  outer:
  for (var i = bytes.length - marker.length; i >= from; i--) {
    for (var j = 0; j < marker.length; j++) {
      if (bytes[i + j] != marker[j]) continue outer;
    }
    return true;
  }
  return false;
}
