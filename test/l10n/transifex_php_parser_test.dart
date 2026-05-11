import 'package:admin/l10n/transifex_php_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests target the PHP parser's job: given Transifex output, return
/// the right key→value map. They use a hand-written subset of the real
/// `textsphp-en_au.php` format so we don't depend on a shipped zip.

const _simple = '''
<?php

\$lang = array(
    'organization' => 'Organisation',
    'name' => 'Name',
);

return \$lang;
''';

const _withEscapes = r"""
<?php
$lang = array(
    'apostrophe' => 'it\'s fine',
    'backslash' => 'C:\\Users',
    // a comment between entries
    'plain' => 'plain',
    # also a comment
    'no_trailing_comma' => 'last'
);
""";

const _blockComment = r"""
<?php
$lang = array(
    /* multi
       line
       comment */
    'kept' => 'survives',
);
""";

void main() {
  final parser = TransifexPhpParser();

  group('basic shape', () {
    test('parses a flat key→value map', () {
      final map = parser.parse(_simple);
      expect(map, {'organization': 'Organisation', 'name': 'Name'});
    });

    test('throws when array() opener is missing', () {
      expect(
        () => parser.parse('<?php return 1;'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PHP escape rules (single-quoted strings)', () {
    test(r"unescapes \' to ' and \\ to \", () {
      final map = parser.parse(_withEscapes);
      expect(map['apostrophe'], "it's fine");
      expect(map['backslash'], r'C:\Users');
    });

    test('preserves all other backslash sequences literally', () {
      final map = parser.parse(r"""
<?php
$lang = array(
    'kept' => 'line\nbreak',
);
""");
      // PHP single-quote rule: \n is literally backslash-n, not a newline.
      expect(map['kept'], r'line\nbreak');
    });
  });

  group('double-quoted strings (mixed with single)', () {
    test(
      "real Transifex output mixes 'single' and \"double\" quotes — both parse",
      () {
        // From textsphp-en.php: when the value contains a single quote
        // (e.g. "Pa'anga"), Transifex emits the entry with double quotes
        // around both key and value.
        final map = parser.parse(r'''
<?php
$lang = array(
    "currency_tongan_pa_anga" => "Tongan Pa'anga",
    'plain' => 'still works',
);
''');
        expect(map['currency_tongan_pa_anga'], "Tongan Pa'anga");
        expect(map['plain'], 'still works');
      },
    );

    test('double-quoted string can contain unescaped single quotes', () {
      final map = parser.parse(r'''
<?php
$lang = array(
    "msg" => "it's mixed",
);
''');
      expect(map['msg'], "it's mixed");
    });
  });

  group('comments + trailing commas', () {
    test('ignores // and # line comments between entries', () {
      final map = parser.parse(_withEscapes);
      expect(
        map.keys,
        containsAll(['apostrophe', 'plain', 'no_trailing_comma']),
      );
    });

    test('ignores /* block comments */', () {
      final map = parser.parse(_blockComment);
      expect(map, {'kept': 'survives'});
    });

    test('allows the last entry to omit the trailing comma', () {
      final map = parser.parse(_withEscapes);
      expect(map['no_trailing_comma'], 'last');
    });
  });
}
