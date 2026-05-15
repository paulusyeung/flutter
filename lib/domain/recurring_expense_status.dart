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
