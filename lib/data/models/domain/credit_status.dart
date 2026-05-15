/// Stored status discriminator on every credit. Wire ids are `'1'..'4'`.
/// Mirrors admin-portal `kCreditStatus*` constants.
///
/// Computed-only pseudo-statuses (`viewed`) are derived on the client
/// from invitation state — see [CreditCalculation.calculatedStatusId].
enum CreditStatus {
  draft('1'),
  sent('2'),
  partial('3'),
  applied('4');

  const CreditStatus(this.wireId);

  final String wireId;

  static CreditStatus fromWire(String? raw) => switch (raw) {
    '2' => CreditStatus.sent,
    '3' => CreditStatus.partial,
    '4' => CreditStatus.applied,
    _ => CreditStatus.draft,
  };

  String get labelKey => switch (this) {
    CreditStatus.draft => 'draft',
    CreditStatus.sent => 'sent',
    CreditStatus.partial => 'partial',
    CreditStatus.applied => 'applied',
  };
}

/// Computed pseudo-statuses (never stored on the wire).
class CreditStatusComputed {
  const CreditStatusComputed._();

  static const String viewed = '-2';
}

String creditStatusLabelKey(String id) => switch (id) {
  CreditStatusComputed.viewed => 'viewed',
  _ => CreditStatus.fromWire(id).labelKey,
};
