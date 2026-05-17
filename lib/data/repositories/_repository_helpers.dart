import 'dart:convert';

import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/api/location_api_model.dart';
import 'package:admin/data/models/domain/document.dart';
import 'package:admin/data/models/domain/location.dart';

/// `DateTime` → epoch seconds (Invoice Ninja's wire convention). Inverse of
/// `epochSecondsToUtc` in `models/value/parsing.dart`. Used by repository
/// `_apiToCompanion` builders when persisting timestamp columns.
int dateToEpochSeconds(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

/// Decode a Drift `documents` text column back into typed domain
/// [Document]s. Empty/malformed strings return `const <Document>[]` so the
/// repository's `_fromRow` can overlay a non-nullable list without
/// guarding the caller. Mirrors the lift in `models/value/parsing.dart`
/// `mapDocuments(...)` — this one starts from a JSON-encoded string, not
/// a `List<DocumentApi>?`.
List<Document> decodeDocumentsColumn(String? raw) {
  if (raw == null || raw.isEmpty) return const <Document>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => Document.fromApi(DocumentApi.fromJson(m)))
          .toList(growable: false);
    }
  } catch (_) {}
  return const <Document>[];
}

/// Decode a Drift client `locations` text column back into typed domain
/// [Location]s. Empty/malformed → `const <Location>[]` so `_fromRow` can
/// overlay a non-nullable list without guarding the caller. Mirrors
/// [decodeDocumentsColumn]; the column is JSON-encoded `List<LocationApi>`.
List<Location> decodeLocationsColumn(String? raw) {
  if (raw == null || raw.isEmpty) return const <Location>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => Location.fromApi(LocationApi.fromJson(m)))
          .toList(growable: false);
    }
  } catch (_) {}
  return const <Location>[];
}

/// Decode a Drift `documents` text column into the *API* DTO type, used
/// by document-mutation flows (add/delete/visibility) that need to rewrite
/// the wire-shape array before re-encoding it back into the column. The
/// growable return is deliberate — callers mutate the list.
List<DocumentApi> decodeRawDocumentsColumn(String? raw) {
  if (raw == null || raw.isEmpty) return const <DocumentApi>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(DocumentApi.fromJson)
          .toList(growable: true);
    }
  } catch (_) {}
  return <DocumentApi>[];
}
