/// Wire-string discriminator on every `LineItem`. Mirrors admin-portal
/// `InvoiceItemEntity.TYPE_*` constants (`'1'..'5'`).
///
/// `standard` is the default for user-entered rows. `task` / `unpaidFee` /
/// `paidFee` / `lateFee` are produced server-side when an invoice was
/// generated from a task time-log or a fee-policy hook — these come down
/// the wire on existing invoices and must round-trip through edit/save.
enum LineItemType {
  standard('1'),
  task('2'),
  unpaidFee('3'),
  paidFee('4'),
  lateFee('5');

  const LineItemType(this.wireId);

  final String wireId;

  /// Tolerant decoder — anything unknown (including `''` / null) maps to
  /// [standard] so a server adding a new variant never crashes the parser.
  static LineItemType fromWire(String? raw) => switch (raw) {
    '2' => LineItemType.task,
    '3' => LineItemType.unpaidFee,
    '4' => LineItemType.paidFee,
    '5' => LineItemType.lateFee,
    _ => LineItemType.standard,
  };
}
