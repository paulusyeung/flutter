import 'package:decimal/decimal.dart';

import 'package:admin/data/models/value/date.dart';
import 'package:admin/domain/reports/report_column_types.dart';

/// One column header in a [ReportPreview]. The `displayLabel` comes from the
/// server's per-locale label; `type` is inferred from the column identifier
/// so the local engine can sort/filter/aggregate without round-tripping
/// through the display string.
class ReportColumn {
  const ReportColumn({
    required this.identifier,
    required this.displayLabel,
    required this.type,
  });

  /// Stable id, e.g. `client.name` or `invoice.amount`. Used as the dictionary
  /// key for column filters, sort field, and column visibility.
  final String identifier;

  /// Locale-formatted human label from the server.
  final String displayLabel;

  final ReportColumnType type;

  @override
  bool operator ==(Object other) =>
      other is ReportColumn &&
      other.identifier == identifier &&
      other.displayLabel == displayLabel &&
      other.type == type;

  @override
  int get hashCode => Object.hash(identifier, displayLabel, type);
}

/// Sealed value carried by a single cell of a [ReportRow]. Carries:
/// - the **raw** typed value (for sort, filter, and aggregation)
/// - the server's pre-formatted **display value** (for rendering)
/// - the wire-format entity reference (for drill-down — `entityWire` is the
///   server's raw string, NOT an `EntityType` enum; mapping happens in
///   `resolveDrillTarget`).
///
/// Cell parsing happens in `ReportsRepository._parseCell`. Money uses
/// `parseMoney` from `lib/data/models/value/money.dart` (Decimal); dates use
/// `Date.tryParse` / `DateTime.tryParse`. `double` is forbidden for money by
/// the CI lint.
sealed class ReportCell {
  const ReportCell({this.entityWire, this.entityId, this.displayValue});

  /// Server wire string for the entity this cell belongs to (`client`,
  /// `invoice`, `invoice_item`, `activity`, …). Drill-down resolves this via
  /// `resolveDrillTarget` to find the navigable entity (item rows redirect
  /// to their parent; `activity` is non-clickable).
  final String? entityWire;

  /// Server id for the entity this cell belongs to. Combined with
  /// `entityWire`'s resolved [EntityHandlers.routePath] to build the drill
  /// target URL.
  final String? entityId;

  /// The server's pre-formatted display string. Used as a fallback when the
  /// local engine can't (or shouldn't) re-render — e.g. text columns where
  /// the server applied an i18n lookup we don't replicate locally.
  final String? displayValue;

  /// Key used by [ReportEngine] for sort and group buckets. `null` sorts
  /// last in ascending order, first in descending — matches v1's
  /// `ReportResult.sortReport` behavior.
  Object? get sortKey;

  /// Lower-case text representation used for substring filter matching on
  /// string columns. Numeric / date types ignore this — they filter via
  /// type-aware comparisons against `sortKey`.
  String get filterText => displayValue?.toLowerCase() ?? '';
}

class ReportStringCell extends ReportCell {
  const ReportStringCell({
    this.value,
    super.entityWire,
    super.entityId,
    super.displayValue,
  });

  final String? value;

  @override
  Object? get sortKey => value?.toLowerCase();

  @override
  String get filterText => (displayValue ?? value)?.toLowerCase() ?? '';
}

/// Numeric cell. For money columns set [isMoney] = true and supply
/// [currencyId]; the engine groups totals by currency. [exchangeRate] is the
/// row's exchange rate to the company currency when the server emits one —
/// used by the optional converted-totals calculation.
class ReportNumberCell extends ReportCell {
  const ReportNumberCell({
    this.value,
    this.isMoney = false,
    this.currencyId,
    this.exchangeRate,
    super.entityWire,
    super.entityId,
    super.displayValue,
  });

  final Decimal? value;
  final bool isMoney;
  final String? currencyId;
  final Decimal? exchangeRate;

  @override
  Object? get sortKey => value;

  /// Numeric value as `double` for chart axes — chart libraries expect
  /// doubles. **Not** used for totals (which stay in Decimal).
  double? get chartValue =>
      value == null ? null : double.parse(value!.toString());
}

class ReportDateCell extends ReportCell {
  const ReportDateCell({
    this.value,
    super.entityWire,
    super.entityId,
    super.displayValue,
  });

  /// Calendar date — no time, no timezone. `DateTime` would smuggle in
  /// timezone semantics; per CLAUDE.md, date-only columns must use [Date].
  final Date? value;

  @override
  Object? get sortKey => value;
}

class ReportDateTimeCell extends ReportCell {
  const ReportDateTimeCell({
    this.value,
    super.entityWire,
    super.entityId,
    super.displayValue,
  });

  /// Timestamp. Separate from [ReportDateCell] so the engine can't silently
  /// coerce between the two (CLAUDE.md strict rule).
  final DateTime? value;

  @override
  Object? get sortKey => value;
}

/// Age in days. `-1` is the legacy "paid" sentinel — admin-portal renders
/// it as the `paid` localization key, and the bucket filter offers "Paid"
/// as a discrete option.
class ReportAgeCell extends ReportCell {
  const ReportAgeCell({
    this.days,
    super.entityWire,
    super.entityId,
    super.displayValue,
  });

  final int? days;

  /// True when this cell represents the "paid" sentinel (no aging).
  bool get isPaid => days == -1;

  @override
  Object? get sortKey {
    if (days == null) return null;
    if (days == -1) return -1;
    return days;
  }
}

class ReportBoolCell extends ReportCell {
  const ReportBoolCell({
    this.value,
    super.entityWire,
    super.entityId,
    super.displayValue,
  });

  final bool? value;

  @override
  Object? get sortKey => value;
}

class ReportDurationCell extends ReportCell {
  const ReportDurationCell({
    this.seconds,
    super.entityWire,
    super.entityId,
    super.displayValue,
  });

  final int? seconds;

  @override
  Object? get sortKey => seconds;
}

/// One row of a [ReportPreview]. The first non-null cell's `entityWire` /
/// `entityId` is taken as the row's drill-down target.
class ReportRow {
  const ReportRow({required this.cells});

  final List<ReportCell> cells;

  String? get entityWire {
    for (final c in cells) {
      if (c.entityWire != null && c.entityWire!.isNotEmpty) return c.entityWire;
    }
    return null;
  }

  String? get entityId {
    for (final c in cells) {
      if (c.entityId != null && c.entityId!.isNotEmpty) return c.entityId;
    }
    return null;
  }
}

/// The decoded server response for one Run of a report — the column header
/// set + the row body. Held in memory on the ViewModel; all local sort /
/// filter / group / subtotal happens against this object via [ReportEngine].
class ReportPreview {
  const ReportPreview({required this.columns, required this.rows});

  final List<ReportColumn> columns;
  final List<ReportRow> rows;

  static const empty = ReportPreview(columns: [], rows: []);
}
