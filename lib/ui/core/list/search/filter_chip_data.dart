import 'package:flutter/foundation.dart';

import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_token.dart';

/// One chip in the applied-filter strip.
///
/// Most keys map 1:1 — one applied value → one chip ([aggregate] false,
/// [rawValues] a single element). `checkboxMultiSelect` keys with more than
/// one applied value collapse into a single [aggregate] chip whose [token]
/// carries a combined display value (`status draft, paid, sent`) and whose
/// [rawValues] lists every member so `×` can clear them in one write.
///
/// Named `ActiveFilterChip` (not `FilterChip`) to avoid colliding with
/// Material's `FilterChip` in files that import `package:flutter/material`.
@immutable
class ActiveFilterChip {
  const ActiveFilterChip({
    required this.key,
    required this.token,
    required this.rawValues,
    required this.aggregate,
  });

  /// The filter dimension this chip belongs to.
  final FilterKey key;

  /// Display payload for [FilterTokenChip]. For an [aggregate] chip this is
  /// synthetic: real `displayKey`, combined `displayValue`, empty `rawValue`.
  final FilterToken token;

  /// Every applied raw value this chip stands for. Length 1 for a
  /// non-[aggregate] chip; the whole set for an aggregate one.
  final List<String> rawValues;

  /// True when this single chip represents more than one applied value.
  final bool aggregate;
}
