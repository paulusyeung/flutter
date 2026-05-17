import 'package:drift/drift.dart';

/// Builds a case-insensitive LIKE over one or more JSON keys dug out of an
/// entity's `payload` blob with SQLite's JSON1 `json_extract`.
///
/// `needle` is bound as a `?` variable by Drift's `.like()` — it is **never**
/// string-interpolated into the SQL text, so a `'` (or any other character) in
/// the user's search term is treated as a literal, not as SQL. The JSON keys
/// are hardcoded call-site literals, never user input, so interpolating them
/// into the path is safe.
///
/// Replaces the hand-built per-DAO helpers that concatenated the raw search
/// term straight into a `LIKE` clause in the SQL text, which both broke on
/// apostrophes and was injectable.
Expression<bool> payloadJsonLike(String needle, List<String> jsonKeys) {
  Expression<bool> likeKey(String key) => CustomExpression<String>(
    "lower(COALESCE(json_extract(payload, '\$.$key'), ''))",
  ).like(needle);

  return jsonKeys.map(likeKey).reduce((a, b) => a | b);
}
