import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CI lint: forbid hardcoded user-facing strings in `Text(...)` widgets under
/// `lib/ui/`. Every visible string must flow through `context.tr(...)` so it
/// is translatable (see CLAUDE.md § Localization). This is the i18n sibling of
/// `no_per_page_max_test.dart` / `decimal_money_test.dart`.
///
/// Unlike `no_per_page_max_test`, this cannot scan each file as one flat
/// string: the exemptions are positional. So [findHardcodedLines] walks line
/// by line, tracking comment scope and `@Preview` function scope. The scan is
/// extracted from `main()` so the state machine can be unit-tested directly
/// (see the "detector" group) rather than only against the live corpus.
///
/// Heuristic (deliberately conservative — only obvious offenders):
///   * Only `Text('literal')` / `Text("literal")` with a *constant* string
///     argument. `Text(context.tr(...))`, `Text('$x')`, `Text(variable)` do
///     not match.
///   * The literal must look like prose: starts with a capital letter, is
///     word-like (`^[A-Z][A-Za-z]+( [A-Za-z0-9'’]+)*$`). Money masks,
///     punctuation, format patterns, single symbols are ignored.
///
/// Exemptions:
///   * `// i18n-exempt: <reason>` on the offending line OR the line directly
///     above it (for brand names, protocol identifiers, etc.). This lookback
///     is intentionally only one line — it covers both real placements
///     (comment-inline and comment-directly-above, e.g. a `DropdownMenuItem`
///     whose `Text(...)` sits one line below the comment). Detected on the
///     RAW line, independent of comment stripping, so the two never interfere.
///   * Any line inside a `@Preview`-annotated function (block- *or*
///     expression-bodied), where literal sample text is intentional.
///   * `//` line comments and `/* … */` block comments are stripped before
///     matching, so a commented-out widget or an explanatory comment cannot
///     red the build.
///
/// The preview/comment state machine is **fail-open**: if a preview function's
/// body can't be resolved (malformed, or a heuristic miss) it resumes
/// checking rather than silently skipping the rest of the file — a guard that
/// goes quiet is worse than no guard.
///
/// Accepted limitations (documented so they aren't later mistaken for bugs):
///   1. `Text("Don't")` / escaped-quote literals are truncated or missed by
///      the `[^'"]*` capture — a rare false-negative.
///   2. A `Text(` substring *inside a Dart string literal* (not a comment)
///      can be a false-positive; remedy is `// i18n-exempt`.
///   3. Scoped to `Text(...)` only. `tooltip:` / `labelText:` / `hintText:`
///      literals are a known follow-up, not covered here.

final _textLiteral = RegExp(r'''Text\(\s*(['"])([^'"]*)\1''');
final _prose = RegExp(r"^[A-Z][A-Za-z]+( [A-Za-z0-9'’]+)*$");

/// Returns the 1-based line numbers in [lines] that hold a hardcoded
/// user-facing `Text('...')` string, applying the comment/preview/exempt
/// rules described above.
List<int> findHardcodedLines(List<String> lines) {
  final offenders = <int>[];

  // Comment scope (persists across lines for `/* … */`).
  var blockCommentDepth = 0;

  // @Preview function scope.
  var previewPending = false; // saw `@Preview`, body type not yet known
  var inBlockPreview = false; // inside a `{ … }` preview body
  var inExprPreview = false; // inside a `=> … ;` preview body
  var braceDepth = 0;
  var pendingFor = 0; // fail-open cap: lines spent unresolved in `pending`

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];

    // Strip comments first; everything below scans `code`, never `raw`
    // (except the i18n-exempt check, which is deliberately raw-line).
    final code = _stripComments(raw, () => blockCommentDepth, (v) {
      blockCommentDepth = v;
    });
    final trimmed = code.trimLeft();

    // ---- Fail-open safety: a new top-level `@`-annotation means any prior
    // preview function has ended. Reset so a malformed preview can never
    // swallow the rest of the file.
    final topLevelAnnotation =
        raw.isNotEmpty &&
        !raw.startsWith(' ') &&
        !raw.startsWith('\t') &&
        raw.trimLeft().startsWith('@');
    if (topLevelAnnotation &&
        (previewPending || inExprPreview || inBlockPreview)) {
      previewPending = inExprPreview = inBlockPreview = false;
      braceDepth = 0;
      pendingFor = 0;
    }

    if (trimmed.startsWith('@Preview')) {
      previewPending = true;
      pendingFor = 0;
      continue;
    }

    if (previewPending) {
      pendingFor++;
      final opens = '{'.allMatches(code).length;
      final closes = '}'.allMatches(code).length;
      if (opens > 0) {
        // Block-bodied preview.
        previewPending = false;
        braceDepth = opens - closes;
        inBlockPreview = braceDepth > 0;
        continue;
      }
      if (code.contains('=>')) {
        // Expression-bodied preview: skip until the terminating `;`.
        previewPending = false;
        inExprPreview = !code.trimRight().endsWith(';');
        continue;
      }
      // Still in a multi-line signature. Fail-open if it never resolves
      // (a real preview function signature is a handful of lines).
      if (pendingFor > 20) {
        previewPending = false;
      }
      continue;
    }

    if (inBlockPreview) {
      braceDepth += '{'.allMatches(code).length;
      braceDepth -= '}'.allMatches(code).length;
      if (braceDepth <= 0) inBlockPreview = false;
      continue;
    }

    if (inExprPreview) {
      if (code.trimRight().endsWith(';')) inExprPreview = false;
      continue;
    }

    // i18n-exempt is checked on the RAW line (and the raw line above) so
    // comment stripping can never sever it.
    final exemptHere = raw.contains('i18n-exempt');
    final exemptAbove = i > 0 && lines[i - 1].contains('i18n-exempt');
    if (exemptHere || exemptAbove) continue;

    for (final m in _textLiteral.allMatches(code)) {
      if (_prose.hasMatch(m.group(2)!)) {
        offenders.add(i + 1);
        break;
      }
    }
  }

  return offenders;
}

/// Returns [line] with `//` line-comment and `/* … */` block-comment content
/// removed. [getDepth]/[setDepth] thread the cross-line block-comment depth.
/// Does not understand `//`/`/*` *inside string literals* — an accepted
/// limitation that only ever reduces detection (never a false positive) and
/// has the `// i18n-exempt` escape hatch.
String _stripComments(
  String line,
  int Function() getDepth,
  void Function(int) setDepth,
) {
  final sb = StringBuffer();
  var depth = getDepth();
  var i = 0;
  while (i < line.length) {
    if (depth > 0) {
      final end = line.indexOf('*/', i);
      if (end == -1) {
        setDepth(depth);
        return sb.toString();
      }
      depth--;
      i = end + 2;
      continue;
    }
    if (i + 1 < line.length && line[i] == '/' && line[i + 1] == '/') {
      break; // line comment — ignore the rest
    }
    if (i + 1 < line.length && line[i] == '/' && line[i + 1] == '*') {
      depth++;
      i += 2;
      continue;
    }
    sb.write(line[i]);
    i++;
  }
  setDepth(depth);
  return sb.toString();
}

void main() {
  test('lib/ui contains no hardcoded user-facing Text() strings', () {
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
      for (final n in findHardcodedLines(lines)) {
        offenders.add('${entity.path}:$n  ${lines[n - 1].trim()}');
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

  group('detector state machine', () {
    test('flags a genuine hardcoded Text()', () {
      expect(findHardcodedLines(["child: Text('Save Changes'),"]), [1]);
    });

    test('ignores tr / interpolation / money mask / lowercase', () {
      expect(
        findHardcodedLines([
          "Text(context.tr('save'))",
          r"Text('$amount')",
          r"Text('\$1.00')",
          "Text('lowercase start')",
        ]),
        isEmpty,
      );
    });

    test(
      'R1: expression-bodied @Preview does NOT blind later real offenders',
      () {
        final lines = [
          '@Preview(name: "x")',
          "Widget previewFoo() => Bar(child: Text('Sample Text'));",
          '',
          "child: Text('Real Offender'),",
        ];
        // The preview literal on line 2 is exempt; the real one on line 4 is not.
        expect(findHardcodedLines(lines), [4]);
      },
    );

    test('R1: block-bodied @Preview body is exempt, code after it is not', () {
      final lines = [
        '@Preview(name: "y")',
        'Widget previewBar() {',
        "  return Text('Preview Sample');",
        '}',
        "Text('After Preview'),",
      ];
      expect(findHardcodedLines(lines), [5]);
    });

    test('R1: consecutive previews — second annotation resets state', () {
      final lines = [
        '@Preview()',
        "Widget a() => Text('Sample A');",
        '@Preview()',
        "Widget b() => Text('Sample B');",
        "Text('Tail Offender'),",
      ];
      expect(findHardcodedLines(lines), [5]);
    });

    test('R2: // line comment with Text() is not flagged', () {
      expect(
        findHardcodedLines(["// like child: Text('Bold') in the toolbar"]),
        isEmpty,
      );
    });

    test('R2: /* … */ block comment (multi-line) is not flagged', () {
      final lines = [
        '/* example:',
        "   child: Text('Commented Out'),",
        '*/',
        "child: Text('Live One'),",
      ];
      expect(findHardcodedLines(lines), [4]);
    });

    test(
      'R2/R3: i18n-exempt on the line above still skips (raw-line path)',
      () {
        final lines = [
          '// i18n-exempt: protocol identifier',
          "DropdownMenuItem(value: 'TLS', child: Text('TLS')),",
        ];
        expect(findHardcodedLines(lines), isEmpty);
      },
    );
  });
}
