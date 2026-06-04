import 'package:decimal/decimal.dart';

import 'package:admin/data/models/api/document_api_model.dart';
import 'package:admin/data/models/domain/document.dart';

/// Epoch seconds (Invoice Ninja's wire convention for all timestamps) → UTC
/// [DateTime]. Mirrors the `_seconds(int)` helper that every entity's
/// `fromApi` used to declare privately.
DateTime epochSecondsToUtc(int s) =>
    DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);

/// Same as [epochSecondsToUtc] but returns null when [seconds] is <= 0.
/// Matches the server convention where `archived_at = 0` means "not
/// archived" — the domain model carries `archivedAt: null` for that case.
DateTime? epochSecondsToUtcOrNull(int seconds) =>
    seconds > 0 ? epochSecondsToUtc(seconds) : null;

/// `num` → `Decimal` via string round-trip. Used for non-money numeric
/// fields (tax rates, inventory quantities) where IEEE-754 doubles would
/// lose precision. Money goes through `parseMoney` in `money.dart`.
Decimal numToDecimal(num n) => Decimal.parse(n.toString());

/// The literal placeholder the server returns for a contact's `password`
/// when one is set — it never sends the real hash (see
/// `ClientContactTransformer`/`VendorContactTransformer`). It must never be
/// written back: echoing it fails the backend's password validation
/// (`min:7` + lower/upper/digit regexes) with a 422 the user can't see or
/// clear. Treat it as "no change" — blanked on the way in (`fromApi`), never
/// serialized on the way out (`toApiJson`).
const String kMaskedPassword = '**********';

/// Lift the optional API `documents` list into the non-nullable domain
/// list. The DTO is nullable so it can distinguish JSON-omitted from
/// JSON-empty; the domain model is non-nullable so the UI never has to
/// null-check the list.
List<Document> mapDocuments(List<DocumentApi>? raw) =>
    (raw ?? const <DocumentApi>[])
        .map(Document.fromApi)
        .toList(growable: false);
