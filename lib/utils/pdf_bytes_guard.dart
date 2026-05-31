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
/// The check is a cheap header sniff: every PDF starts with the 5-byte magic
/// `%PDF-` (0x25 0x50 0x44 0x46 0x2D). It deliberately does not parse the
/// document, so a truncated-but-headered PDF could still fail downstream —
/// but the empty / wrong-content-type cases that produce the logged
/// RangeError are caught, which is the bug this guards.
bool isRenderablePdf(Uint8List? bytes) {
  if (bytes == null || bytes.length < 5) return false;
  return bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46 && // F
      bytes[4] == 0x2D; //  -
}
