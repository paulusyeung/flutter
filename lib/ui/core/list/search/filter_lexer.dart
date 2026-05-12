import 'package:admin/ui/core/list/search/filter_key.dart';

/// Parsed result of a pasted search string: zero or more `(keyId, rawValue)`
/// tokens plus whatever free text didn't match any known filter key.
typedef LexResult = ({
  List<({String keyId, String rawValue})> tokens,
  String freeText,
});

/// Paste-time lexer for the token search field. Splits the input on
/// whitespace; each piece that looks like `<key>:<value>` (where `<key>` is
/// a known [FilterKey.id] or an alias) becomes a token, otherwise it joins
/// the free-text bucket. Quoted values (`country:"United States"`) are
/// unwrapped; comma-separated values (`is:active,archived`) split into
/// multiple tokens.
LexResult lexFilterInput(String input, List<FilterKey> filterKeys) {
  final tokens = <({String keyId, String rawValue})>[];
  final freeBuf = StringBuffer();

  final pieces = input.split(RegExp(r'\s+'));
  final knownIds = <String, String>{};
  for (final k in filterKeys) {
    knownIds[k.id] = k.id;
    for (final a in k.aliases) {
      knownIds[a] = k.id;
    }
  }

  for (final piece in pieces) {
    final colon = piece.indexOf(':');
    if (colon == -1) {
      if (piece.isNotEmpty) freeBuf.write('$piece ');
      continue;
    }
    final prefix = piece.substring(0, colon).toLowerCase();
    final id = knownIds[prefix];
    if (id == null) {
      if (piece.isNotEmpty) freeBuf.write('$piece ');
      continue;
    }
    var value = piece.substring(colon + 1);
    if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
      value = value.substring(1, value.length - 1);
    }
    if (value.isEmpty) continue;
    for (final v in value.split(',')) {
      final trimmed = v.trim();
      if (trimmed.isNotEmpty) {
        tokens.add((keyId: id, rawValue: trimmed));
      }
    }
  }
  return (tokens: tokens, freeText: freeBuf.toString().trim());
}
