import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI lint: forbid hardcoded user-facing strings in `Text(...)` widgets under
/// `lib/ui/`. Every visible string must flow through `context.tr(...)` so it
/// is translatable (see CLAUDE.md § Localization). This is the i18n sibling of
/// `no_per_page_max_test.dart` / `decimal_money_test.dart`.
///
/// Unlike `no_per_page_max_test`, this cannot scan each file as one flat
/// string: the exemptions are positional (a `// i18n-exempt` comment on the
/// line or the line above; any line inside a `@Preview`-annotated function,
/// where literal sample text is intentional). So it walks line by line and
/// tracks `@Preview` function scope with a brace-depth counter.
///
/// Heuristic (deliberately conservative — only obvious offenders):
///   * Only `Text('literal')` / `Text("literal")` with a *constant* string
///     argument. `Text(context.tr(...))`, `Text('$x')`, `Text(variable)` do
///     not match.
///   * The literal must look like prose: starts with a capital letter, is
///     word-like (`^[A-Z][A-Za-z]+( [A-Za-z0-9'’]+)*$`). Money masks,
///     punctuation, format patterns, single symbols are ignored.
///
/// Escape hatch: put `// i18n-exempt: <reason>` on the offending line or the
/// line directly above it (for brand names, protocol identifiers, etc.).
///
/// NOTE: scoped to `Text(...)` only. `tooltip:` / `labelText:` / `hintText:`
/// literals are a known follow-up, not covered here.
void main() {
  test('lib/ui contains no hardcoded user-facing Text() strings', () {
    final textLiteral = RegExp(r'''Text\(\s*(['"])([^'"]*)\1''');
    final prose = RegExp(r"^[A-Z][A-Za-z]+( [A-Za-z0-9'’]+)*$");

    final offenders = <String>[];
    final uiDir = Directory('lib/ui');
    expect(uiDir.existsSync(), isTrue, reason: 'lib/ui should exist');

    for (final entity in uiDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.endsWith('.freezed.dart')) continue;
      if (entity.path.contains('widget_preview')) continue;
      if (entity.path.contains('preview_support')) continue;

      final lines = entity.readAsLinesSync();

      // @Preview-function scope tracking. A `@Preview` annotation precedes a
      // top-level function; everything from its opening `{` until the matching
      // `}` (brace depth back to 0) is preview sample code and is exempt.
      var previewPending = false;
      var inPreview = false;
      var depth = 0;

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();

        if (trimmed.startsWith('@Preview')) {
          previewPending = true;
          continue;
        }

        if (previewPending) {
          final opens = '{'.allMatches(line).length;
          final closes = '}'.allMatches(line).length;
          if (opens > 0) {
            depth += opens - closes;
            previewPending = false;
            inPreview = depth > 0;
          }
          continue;
        }

        if (inPreview) {
          depth += '{'.allMatches(line).length;
          depth -= '}'.allMatches(line).length;
          if (depth <= 0) inPreview = false;
          continue;
        }

        final exemptHere = line.contains('i18n-exempt');
        final exemptAbove = i > 0 && lines[i - 1].contains('i18n-exempt');
        if (exemptHere || exemptAbove) continue;

        for (final m in textLiteral.allMatches(line)) {
          final content = m.group(2)!;
          if (prose.hasMatch(content)) {
            offenders.add('${entity.path}:${i + 1}  ${trimmed.trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Hardcoded user-facing Text() strings found. Route them through '
          '`context.tr(...)` (add the key to assets/i18n/_app_pending.json if '
          'it is app-local), or annotate with `// i18n-exempt: <reason>` for '
          'brand names / protocol identifiers. Found:\n  '
          '${offenders.join('\n  ')}',
    );
  });
}
