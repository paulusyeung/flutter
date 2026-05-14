import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin/app/entity_modules.dart';

/// Asserts that every entity registered in [kWiredEntityModules] +
/// [kDisabledEntityModules] has the standard set of localization keys
/// available in `assets/i18n/en.json` (the Transifex source of truth) or
/// `assets/i18n/_app_pending.json` (app-local pre-Transifex strings).
///
/// Required keys per entity (uses [EntityModuleSpec.wireName] as the
/// singular form and [EntityModuleSpec.labelKey] as the plural):
///
/// 1. `<wireName>` — "Client"
/// 2. `<labelKey>` — "Clients" (plural sidebar label)
/// 3. `new_<wireName>` — "New Client"
/// 4. `edit_<wireName>` — "Edit Client"
/// 5. `archived_<wireName>` — toast on archive success
/// 6. `restored_<wireName>` — toast on restore success
/// 7. `deleted_<wireName>` — toast on delete success
///
/// `purged_<wireName>` is NOT enforced — purge is a rare legal-compliance
/// action that admin-portal only exposes for clients; per-entity opt-in.
void main() {
  test('every entity has the standard set of translation keys', () async {
    final keys = await _loadAllAvailableKeys();
    final missing = <String>[];
    final modules = [...kWiredEntityModules, ...kDisabledEntityModules];
    for (final m in modules) {
      final wireName = m.wireName;
      final plural = m.labelKey;
      final required = <String>[
        wireName,
        plural,
        'new_$wireName',
        'edit_$wireName',
        'archived_$wireName',
        'restored_$wireName',
        'deleted_$wireName',
      ];
      for (final key in required) {
        if (!keys.contains(key)) {
          missing.add('${m.type}: $key');
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'Missing translation keys for some entities — add them to '
          'assets/i18n/_app_pending.json (or wait for the next Transifex '
          'import to land them in en.json). Missing:\n${missing.join('\n')}',
    );
  });
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
