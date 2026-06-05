/// Wire-string discriminator on every `LineItem`. Mirrors the server's
/// `InvoiceItem.type_id` constants (`'1'..'6'`).
///
/// `standard` is the default for user-entered rows. `task` / `unpaidFee` /
/// `paidFee` / `lateFee` / `expense` are produced server-side when an invoice
/// was generated from a task time-log, a fee-policy hook, or a billed expense
/// — these come down the wire on existing invoices and must round-trip
/// through edit/save. (Without `expense`, an expense-linked line item loaded
/// from the server was silently rewritten to `standard` on the next save.)
enum LineItemType {
  standard('1'),
  task('2'),
  unpaidFee('3'),
  paidFee('4'),
  lateFee('5'),
  expense('6');

  const LineItemType(this.wireId);

  final String wireId;

  /// Tolerant decoder — anything unknown (including `''` / null) maps to
  /// [standard] so a server adding a new variant never crashes the parser.
  static LineItemType fromWire(String? raw) => switch (raw) {
    '2' => LineItemType.task,
    '3' => LineItemType.unpaidFee,
    '4' => LineItemType.paidFee,
    '5' => LineItemType.lateFee,
    '6' => LineItemType.expense,
    _ => LineItemType.standard,
  };
}
