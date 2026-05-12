import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';

/// Picks a stable tint for an initials avatar. The same `seed` always maps to
/// the same colour so a given entity (client, company, contact) keeps the
/// same identity colour across screens.
///
/// Uses [InAvatarPalette.colors] in `lib/app/design_tokens.dart` — never
/// introduce a parallel palette in feature code.
Color avatarTintFor(String seed) {
  var hash = 0;
  for (final code in seed.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  final palette = InAvatarPalette.colors;
  return palette[hash % palette.length];
}
