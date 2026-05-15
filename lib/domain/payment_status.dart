import 'package:flutter/material.dart';

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

/// Shared color mapping used by both list-tile and detail-header status
/// pills. Defined once so the two surfaces don't drift apart.
///
/// Colors are muted Material 3 hues — the pill is metadata, not a CTA.
const Map<String, Color> kPaymentStatusColors = {
  // virtual: positive-but-incomplete states stay in the partial family
  kPaymentStatusPartiallyUnapplied: Color(0xFFFF9800), // Orange 500
  kPaymentStatusUnapplied: Color(0xFF03A9F4), // Light blue 500
  kPaymentStatusPending: Color(0xFF9E9E9E), // Grey 500
  kPaymentStatusCancelled: Color(0xFF607D8B), // Blue grey 500
  kPaymentStatusFailed: Color(0xFFE91E63), // Pink 500
  kPaymentStatusCompleted: Color(0xFF4CAF50), // Green 500
  kPaymentStatusPartiallyRefunded: Color(0xFFFF9800), // Orange 500
  kPaymentStatusRefunded: Color(0xFFF44336), // Red 500
};
