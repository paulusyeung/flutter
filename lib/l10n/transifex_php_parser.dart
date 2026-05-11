/// Pure-Dart parser for Invoice Ninja's Transifex zip files.
///
/// Each file is shaped like:
///
/// ```php
/// <?php
///
/// $lang = array(
///     'key' => 'value',
///     'another' => 'it\'s an example',
///     // 'commented_out' => 'nope',
/// );
///
/// return $lang;
/// ```
///
/// The parser walks the body, ignores comments and PHP wrapper, and emits a
/// `{ key: value }` map. Escaped single quotes (`\'`) and backslashes
/// (`\\`) inside string literals are unescaped per PHP single-quote rules
/// (only those two escapes are honored — `\n`, `\t`, etc. stay literal,
/// matching PHP's single-quote semantics).
class TransifexPhpParser {
  /// Parse the file contents into a key→value map. Throws [FormatException]
  /// if the file doesn't match the expected shape.
  Map<String, String> parse(String input) {
    final out = <String, String>{};
    var i = 0;
    final n = input.length;

    bool startsWithAt(int idx, String s) {
      if (idx + s.length > n) return false;
      for (var k = 0; k < s.length; k++) {
        if (input.codeUnitAt(idx + k) != s.codeUnitAt(k)) return false;
      }
      return true;
    }

    void skipWhitespaceAndComments() {
      while (i < n) {
        final c = input[i];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
          i++;
        } else if (startsWithAt(i, '//') || startsWithAt(i, '#')) {
          while (i < n && input[i] != '\n') {
            i++;
          }
        } else if (startsWithAt(i, '/*')) {
          i += 2;
          while (i + 1 < n && !(input[i] == '*' && input[i + 1] == '/')) {
            i++;
          }
          if (i + 1 < n) i += 2;
        } else {
          return;
        }
      }
    }

    String readQuotedString() {
      if (i >= n || (input[i] != "'" && input[i] != '"')) {
        throw FormatException(
          'Expected quote at offset $i, got "${i < n ? input[i] : 'EOF'}"',
        );
      }
      // Real-world Transifex output uses `"..."` when the value contains
      // a single quote (e.g. `"Tongan Pa'anga"`). Both flavors are
      // accepted; escape rules are the conservative subset PHP shares
      // between them: `\<quote>` → quote, `\\` → backslash, everything
      // else literal.
      final quote = input[i];
      i++;
      final buf = StringBuffer();
      while (i < n) {
        final c = input[i];
        if (c == '\\' && i + 1 < n) {
          final next = input[i + 1];
          if (next == quote || next == r'\') {
            buf.write(next);
            i += 2;
            continue;
          }
          buf.write(c);
          i++;
          continue;
        }
        if (c == quote) {
          i++;
          return buf.toString();
        }
        buf.write(c);
        i++;
      }
      throw const FormatException('Unterminated string literal');
    }

    // Advance past everything up to `array(`.
    final arrayIdx = input.indexOf('array(');
    if (arrayIdx < 0) {
      throw const FormatException('No `array(` found in PHP file');
    }
    i = arrayIdx + 'array('.length;

    while (i < n) {
      skipWhitespaceAndComments();
      if (i >= n) break;
      if (input[i] == ')') {
        i++;
        break;
      }
      // Trailing comma already consumed by the loop.
      final key = readQuotedString();
      skipWhitespaceAndComments();
      if (i + 1 >= n || input[i] != '=' || input[i + 1] != '>') {
        throw FormatException('Expected `=>` after key "$key" at offset $i');
      }
      i += 2;
      skipWhitespaceAndComments();
      final value = readQuotedString();
      out[key] = value;
      skipWhitespaceAndComments();
      if (i < n && input[i] == ',') {
        i++;
      }
    }
    return out;
  }
}
