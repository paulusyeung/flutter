/// Stored status discriminator on every purchase order. Wire ids are
/// `'1'..'5'`. Mirrors admin-portal `kPurchaseOrderStatus*` constants.
///
/// Computed-only pseudo-statuses (`viewed`) are derived on the client from
/// invitation state — see [PurchaseOrderCalculation.calculatedStatusId].
enum PurchaseOrderStatus {
  draft('1'),
  sent('2'),
  accepted('3'),
  received('4'),
  cancelled('5');

  const PurchaseOrderStatus(this.wireId);

  final String wireId;

  static PurchaseOrderStatus fromWire(String? raw) => switch (raw) {
        '2' => PurchaseOrderStatus.sent,
        '3' => PurchaseOrderStatus.accepted,
        '4' => PurchaseOrderStatus.received,
        '5' => PurchaseOrderStatus.cancelled,
        _ => PurchaseOrderStatus.draft,
      };

  String get labelKey => switch (this) {
        PurchaseOrderStatus.draft => 'draft',
        PurchaseOrderStatus.sent => 'sent',
        PurchaseOrderStatus.accepted => 'accepted',
        PurchaseOrderStatus.received => 'received',
        PurchaseOrderStatus.cancelled => 'cancelled',
      };
}

/// Computed pseudo-statuses (never stored on the wire).
class PurchaseOrderStatusComputed {
  const PurchaseOrderStatusComputed._();

  static const String viewed = '-1';
}

String purchaseOrderStatusLabelKey(String id) => switch (id) {
      PurchaseOrderStatusComputed.viewed => 'viewed',
      _ => PurchaseOrderStatus.fromWire(id).labelKey,
    };
