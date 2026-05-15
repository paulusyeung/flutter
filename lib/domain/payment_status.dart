/// Payment status discriminator constants. Mirrors admin-portal
/// `constants.dart:982-999`. The two negative ids are virtual states
/// computed client-side via [Payment.calculatedStatusId]:
///
///   * `-1` unapplied            → `applied == 0`
///   * `-2` partially unapplied  → `0 < applied < amount`
///
/// Persisted status drives Drift queries; the getter drives the pill.
const String kPaymentStatusPartiallyUnapplied = '-2';
const String kPaymentStatusUnapplied = '-1';
const String kPaymentStatusPending = '1';
const String kPaymentStatusCancelled = '2';
const String kPaymentStatusFailed = '3';
const String kPaymentStatusCompleted = '4';
const String kPaymentStatusPartiallyRefunded = '5';
const String kPaymentStatusRefunded = '6';

/// Localization keys for each status.
const Map<String, String> kPaymentStatusLabels = {
  kPaymentStatusPartiallyUnapplied: 'partially_unapplied',
  kPaymentStatusUnapplied: 'unapplied',
  kPaymentStatusPending: 'pending',
  kPaymentStatusCancelled: 'cancelled',
  kPaymentStatusFailed: 'failed',
  kPaymentStatusCompleted: 'completed',
  kPaymentStatusPartiallyRefunded: 'partially_refunded',
  kPaymentStatusRefunded: 'refunded',
};
