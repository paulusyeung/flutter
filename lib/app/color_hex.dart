/// `#RRGGBB` / `#AARRGGBB` ⇄ [Color] helpers. Foundational (no Flutter widget
/// or theme dependency) so both `design_tokens.dart` and the accent picker can
/// share one representation. The wire format Invoice Ninja / admin-portal /
/// React use for stored colours is opaque `#RRGGBB`.
library;

import 'package:flutter/painting.dart';

/// Parse `#RRGGBB` / `#AARRGGBB` (case-insensitive). Returns `null` for an
/// empty or malformed input.
Color? parseHexColor(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final raw = int.tryParse(cleaned, radix: 16);
  if (raw == null) return null;
  return Color(cleaned.length == 6 ? 0xFF000000 | raw : raw);
}

/// Inverse of [parseHexColor]: a `Color` → `#RRGGBB` (alpha dropped — the
/// stored format is opaque).
String formatHexColor(Color color) {
  int c(double v) => (v * 255.0).round() & 0xff;
  final rgb = (c(color.r) << 16) | (c(color.g) << 8) | c(color.b);
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
