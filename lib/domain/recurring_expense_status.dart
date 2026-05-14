import 'package:flutter/material.dart';

/// Recurring expense status discriminator constants. Mirror admin-portal
/// `constants.dart:548-559`. `'1'..'4'` are stored on the server; `'-1'`
/// is the client-derived "Pending" state (statusId == Active but the
/// schedule hasn't fired yet — `lastSentDate == null`).
const String kRecurringExpenseStatusDraft = '1';
const String kRecurringExpenseStatusActive = '2';
const String kRecurringExpenseStatusPaused = '3';
const String kRecurringExpenseStatusCompleted = '4';
const String kRecurringExpenseStatusPending = '-1';

/// Localization keys for each status — resolved via
/// `context.tr(kRecurringExpenseStatusLabelKey[id]!)` in tile + detail pill.
const Map<String, String> kRecurringExpenseStatusLabelKey = {
  kRecurringExpenseStatusDraft: 'draft',
  kRecurringExpenseStatusActive: 'active',
  kRecurringExpenseStatusPaused: 'paused',
  kRecurringExpenseStatusCompleted: 'completed',
  kRecurringExpenseStatusPending: 'pending',
};

/// Shared color mapping used by both list-tile and detail-header status
/// pills. Single source so the two surfaces never drift apart. Muted
/// Material 3 hues — metadata, not a CTA.
const Map<String, Color> kRecurringExpenseStatusColors = {
  kRecurringExpenseStatusDraft: Color(0xFF9E9E9E), // Grey 500
  kRecurringExpenseStatusActive: Color(0xFF4CAF50), // Green 500
  kRecurringExpenseStatusPaused: Color(0xFFFF9800), // Orange 500
  kRecurringExpenseStatusCompleted: Color(0xFF2196F3), // Blue 500
  kRecurringExpenseStatusPending: Color(0xFFFFC107), // Amber 500
};
