import 'package:flutter/foundation.dart';

/// Coarse type of a [FilterKey]'s value. Drives the chip rendering and the
/// type label shown next to each key in the suggestion list.
enum FilterValueType {
  /// One of a small set of values (e.g. status: active|archived|deleted).
  /// Suggestion menu shows the values verbatim; chips render the localized
  /// value label.
  enumeration,

  /// Free-form string matched against a backing list (custom field values,
  /// country names). Suggestion menu fuzzy-filters as the user types.
  string,

  /// ISO date / datetime. Reserved for invoices and future entities — not
  /// used in v1.
  date,
}

/// A single value currently applied for a [FilterKey], rendered as a chip
/// inside the token search field.
@immutable
class FilterToken {
  const FilterToken({
    required this.keyId,
    required this.displayKey,
    required this.rawValue,
    required this.displayValue,
    this.displayComparator,
    this.valueTooltip,
  });

  /// The [FilterKey.id] this token belongs to (`is`, `custom1`, `country`).
  /// Used to route remove/cycle actions back to the owning key.
  final String keyId;

  /// User-facing key label resolved for the current locale + company
  /// settings (`status` for `is`, the configured "Region" label for
  /// `custom1`, etc.).
  final String displayKey;

  /// Canonical value the server filter expects (state.serverName, country
  /// id, custom-field value verbatim).
  final String rawValue;

  /// User-facing value label (`Active`, `United States`, …). Falls back to
  /// [rawValue] when the key has no value-side rendering. For a
  /// [ComparableFilterKey] this is the bare value (no operator) so the
  /// chip can render the comparator as its own segment.
  final String displayValue;

  /// Already-localized comparator label for comparable keys — the math
  /// symbol (`≥`) for numbers, the phrase (*is on or after*) for dates.
  /// Null for non-comparable keys, which render `<key> <value>` as before.
  final String? displayComparator;

  /// Optional tooltip for the value segment. Used to reveal the resolved
  /// absolute date behind a rolling relative value ("7 days ago" →
  /// "2026-05-11"). Null when the value is already self-explanatory.
  final String? valueTooltip;
}

/// One row in the value suggestion list. `displayLabel` is what the user
/// sees; `rawValue` is what the [FilterKey] applies.
@immutable
class FilterValueSuggestion {
  const FilterValueSuggestion({
    required this.rawValue,
    required this.displayLabel,
    this.secondaryLabel,
  });

  final String rawValue;
  final String displayLabel;

  /// Optional muted text rendered after [displayLabel] (e.g. the ISO code
  /// next to a country name). Null when there's nothing useful to show.
  final String? secondaryLabel;
}
