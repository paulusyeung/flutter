/// Stored status discriminator on every recurring invoice. Wire ids are
/// `'1'..'4'`. Mirrors admin-portal `kRecurringInvoiceStatus*` constants.
///
/// Computed-only pseudo-statuses (`pending`) are derived on the client when
/// next_send_date is in the future — see
/// [RecurringInvoiceCalculation.calculatedStatusId].
enum RecurringInvoiceStatus {
  draft('1'),
  active('2'),
  paused('3'),
  completed('4');

  const RecurringInvoiceStatus(this.wireId);

  final String wireId;

  static RecurringInvoiceStatus fromWire(String? raw) => switch (raw) {
    '2' => RecurringInvoiceStatus.active,
    '3' => RecurringInvoiceStatus.paused,
    '4' => RecurringInvoiceStatus.completed,
    _ => RecurringInvoiceStatus.draft,
  };

  String get labelKey => switch (this) {
    RecurringInvoiceStatus.draft => 'draft',
    RecurringInvoiceStatus.active => 'active',
    RecurringInvoiceStatus.paused => 'paused',
    RecurringInvoiceStatus.completed => 'completed',
  };
}

/// Computed pseudo-statuses (never stored on the wire).
class RecurringInvoiceStatusComputed {
  const RecurringInvoiceStatusComputed._();

  static const String pending = '-1';
}

String recurringInvoiceStatusLabelKey(String id) => switch (id) {
  RecurringInvoiceStatusComputed.pending => 'pending',
  _ => RecurringInvoiceStatus.fromWire(id).labelKey,
};
