import 'package:flutter/material.dart';

/// Expense status discriminator constants. Mirrors admin-portal
/// `constants.dart:1002-1006`. Status string ids are persisted server-side
/// on a small `expense_statuses` static lookup; mostly we derive the active
/// status on the client via [Expense.calculatedStatusId] from the
/// invoice/payment state.
const String kExpenseStatusLogged = '1';
const String kExpenseStatusPending = '2';
const String kExpenseStatusInvoiced = '3';
const String kExpenseStatusUnpaid = '4';
const String kExpenseStatusPaid = '5';

/// Localization keys for each status — `<wireName>` style so tile + detail
/// pill resolve via `context.tr(kExpenseStatusLabels[id]!)`.
const Map<String, String> kExpenseStatusLabels = {
  kExpenseStatusLogged: 'logged',
  kExpenseStatusPending: 'pending',
  kExpenseStatusInvoiced: 'invoiced',
  kExpenseStatusUnpaid: 'unpaid',
  kExpenseStatusPaid: 'paid',
};

/// Shared color mapping used by both list-tile and detail-header status
/// pills. Defined once so the two surfaces don't drift apart (admin-portal
/// had subtle drift between them).
///
/// Colors are intentionally muted Material 3 hues — the status pill is
/// metadata, not a CTA.
const Map<String, Color> kExpenseStatusColors = {
  kExpenseStatusLogged: Color(0xFF9E9E9E), // Grey 500
  kExpenseStatusPending: Color(0xFFFF9800), // Orange 500
  kExpenseStatusInvoiced: Color(0xFF2196F3), // Blue 500
  kExpenseStatusUnpaid: Color(0xFFE91E63), // Pink 500
  kExpenseStatusPaid: Color(0xFF4CAF50), // Green 500
};
