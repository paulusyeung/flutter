import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/ui/features/settings/views/advanced/email_settings/email_settings_body.dart'
    show kEmailSettingsSearchKeys;

/// Guards that every localization key rendered by Settings → Email Settings
/// resolves to a real string — either in `assets/i18n/en.json` (the Transifex
/// source of truth) or `assets/i18n/_app_pending.json` (app-local strings not
/// yet in Transifex). `context.tr()` returns the raw snake_case key when a key
/// is missing from BOTH, so a gap here ships developer slugs to users.
///
/// This is the safety net the pre-launch review was missing: `gmail_user` /
/// `microsoft_user` (the OAuth user-picker label) had slipped through.
///
/// Unlike `tax_settings_localization_test.dart`, the "used" set is **scanned
/// from source** rather than hand-listed, so new `tr('…')` keys are covered
/// automatically. (Every email-settings `tr()` call uses a string literal —
/// no `tr(variable)` — so the literal scan is complete; the search-key union
/// is belt-and-suspenders for the labels the settings search surfaces.)
void main() {
  test('every Email Settings localization key resolves', () async {
    final available = await _loadAllAvailableKeys();

    final scanned = _trKeysFromSources(const [
      'lib/ui/features/settings/views/advanced/email_settings_screen.dart',
      'lib/ui/features/settings/views/advanced/email_settings/email_settings_body.dart',
      'lib/ui/features/settings/views/advanced/email_settings/widgets/smtp_mail_driver_card.dart',
      'lib/ui/features/settings/views/advanced/email_settings/widgets/oauth_user_picker.dart',
    ]);

    // Sanity floor: guards against a silently-broken regex (or moved files)
    // making the scan return nothing — which would let the assertion below pass
    // vacuously since `kEmailSettingsSearchKeys` already all resolve. The screen
    // renders ~50 distinct keys today.
    expect(
      scanned.length,
      greaterThan(40),
      reason: 'tr() scan returned ${scanned.length} keys — likely broken',
    );

    final used = <String>{...scanned, ...kEmailSettingsSearchKeys};
    final missing = used.where((k) => !available.contains(k)).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason:
          'Email Settings uses these keys but neither en.json nor '
          '_app_pending.json defines them — they would render as raw slugs. '
          'Add them to assets/i18n/_app_pending.json:\n${missing.join('\n')}',
    );
  });
}

/// Extracts the keys from every `context.tr('key')` / `.tr("key")` literal in
/// [paths]. Only matches a constant string argument (snake_case key); dynamic
/// `tr(variable)` calls are intentionally skipped (none exist on this screen).
Set<String> _trKeysFromSources(List<String> paths) {
  final re = RegExp('''\\.tr\\(\\s*(['"])([A-Za-z0-9_]+)\\1''');
  final keys = <String>{};
  for (final path in paths) {
    final src = File(path).readAsStringSync();
    for (final m in re.allMatches(src)) {
      keys.add(m.group(2)!);
    }
  }
  return keys;
}

Future<Set<String>> _loadAllAvailableKeys() async {
  final keys = <String>{};
  for (final path in const [
    'assets/i18n/en.json',
    'assets/i18n/_app_pending.json',
  ]) {
    final raw = await File(path).readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    keys.addAll(json.keys);
  }
  return keys;
}
