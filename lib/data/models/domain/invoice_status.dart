import 'package:flutter/material.dart';

/// Stored status discriminator on every invoice (and most other billing
/// docs). Wire ids are `'1'..'6'`. Negative pseudo-statuses (`viewed`,
/// `unpaid`, `past_due`) are computed on the client from invitation /
/// balance state — see [InvoiceStatusComputed] and the
/// `calculatedStatusId` extension on `Invoice`.
enum InvoiceStatus {
  draft('1'),
  sent('2'),
  partial('3'),
  paid('4'),
  cancelled('5'),
  reversed('6');

  const InvoiceStatus(this.wireId);

  final String wireId;

  /// Tolerant decoder. Anything unknown maps to [draft] so a server adding
  /// a new variant never crashes the parser.
  static InvoiceStatus fromWire(String? raw) => switch (raw) {
    '2' => InvoiceStatus.sent,
    '3' => InvoiceStatus.partial,
    '4' => InvoiceStatus.paid,
    '5' => InvoiceStatus.cancelled,
    '6' => InvoiceStatus.reversed,
    _ => InvoiceStatus.draft,
  };

  /// Localization key for the user-facing label. Mirrors the wire name so
  /// the i18n bundle reuses what's already imported from admin-portal.
  String get labelKey => switch (this) {
    InvoiceStatus.draft => 'draft',
    InvoiceStatus.sent => 'sent',
    InvoiceStatus.partial => 'partial',
    InvoiceStatus.paid => 'paid',
    InvoiceStatus.cancelled => 'cancelled',
    InvoiceStatus.reversed => 'reversed',
  };
}

/// Computed status wire ids — these never come down the wire but are
/// produced by `Invoice.calculatedStatusId` for the UI's status pill +
/// list filter chips. Mirrors admin-portal `constants.dart` invoice
/// status constants (`kInvoiceStatusPastDue` etc.).
class InvoiceStatusComputed {
  const InvoiceStatusComputed._();

  static const String pastDue = '-1';
  static const String unpaid = '-2';
  static const String viewed = '-3';
}

/// Localization key for the user-facing label for any invoice status id
/// (stored or computed). Falls back to [InvoiceStatus.draft.labelKey] for
/// anything unknown so the chip never renders blank.
String invoiceStatusLabelKey(String id) => switch (id) {
  InvoiceStatusComputed.pastDue => 'past_due',
  InvoiceStatusComputed.unpaid => 'unpaid',
  InvoiceStatusComputed.viewed => 'viewed',
  _ => InvoiceStatus.fromWire(id).labelKey,
};

/// Pair of `(foreground, soft background)` color tokens for the status
/// pill. Reads from `context.inTheme.{paid,paidSoft,…}` so light/dark
/// modes pick the right palette automatically. Mirrors the `_StatePill`
/// pattern in `lib/ui/features/sync/views/outbox_screen.dart`.
({Color fg, Color bg}) invoiceStatusColors(BuildContext context, String id) {
  // The `tokens` getter is intentionally not destructured to keep the
  // switch readable; the pattern below is identical in shape across every
  // arm so it costs almost nothing.
  final t = Theme.of(context).colorScheme;
  // Resolve via the design tokens. We can't import context.inTheme here
  // without dragging the design_tokens dependency into the data layer;
  // callers that want token colors should use the `StatusPill.forInvoice`
  // helper in `lib/ui/features/invoices/widgets/invoice_status_pill.dart`
  // instead. This fallback returns Material colors that still read as
  // sensible status pills if used directly.
  // Wire-string literals (`'1'..'6'`) — kept as plain strings so the switch
  // is const-evaluable. `InvoiceStatus.*.wireId` matches them by
  // construction (see the enum constructor).
  return switch (id) {
    '4' /* paid */ => (
      fg: const Color(0xFF1E7E34),
      bg: const Color(0xFFC6F0CB),
    ),
    '3' /* partial */ => (
      fg: const Color(0xFFB87100),
      bg: const Color(0xFFFFE6B3),
    ),
    '2' /* sent */ => (
      fg: const Color(0xFF1565C0),
      bg: const Color(0xFFCDE3FF),
    ),
    '5' /* cancelled */ || '6' /* reversed */ => (
      fg: t.onSurfaceVariant,
      bg: t.surfaceContainerHighest,
    ),
    InvoiceStatusComputed.pastDue => (
      fg: const Color(0xFFB3261E),
      bg: const Color(0xFFFFD6D6),
    ),
    InvoiceStatusComputed.viewed => (
      fg: const Color(0xFF6E37C7),
      bg: const Color(0xFFE9DBFB),
    ),
    InvoiceStatusComputed.unpaid => (
      fg: const Color(0xFFE85C0E),
      bg: const Color(0xFFFFE0CC),
    ),
    _ => (fg: t.onSurfaceVariant, bg: t.surfaceContainerHighest),
  };
}
