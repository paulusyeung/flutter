/// Pure-Dart mapping of `<locale_key>` → `textsphp-XX.php` file basename in
/// the Transifex zip. Kept Flutter-free so the importer CLI
/// (`tools/import_transifex_zip.dart`) can use it via `dart run` without
/// pulling in the Flutter framework.
///
/// `supported_locales.dart` re-exports this map for the runtime side.
const Map<String, String> kTransifexFileNames = {
  'en': 'textsphp-en.php',
  'en_AU': 'textsphp-en_au.php',
  'en_GB': 'textsphp-en_gb.php',
  'es': 'textsphp-es.php',
  'fr': 'textsphp-fr.php',
  'de': 'textsphp-de.php',
  'it': 'textsphp-it.php',
  'nl': 'textsphp-nl.php',
  'pt_BR': 'textsphp-pt_br.php',
  'ja': 'textsphp-ja.php',
  'zh_CN': 'textsphp-zh_cn.php',
};
