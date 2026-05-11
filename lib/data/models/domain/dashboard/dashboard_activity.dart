/// One row from `GET /api/v1/activities?reactv2`.
///
/// The dashboard renders these via `ActivityFormatter`, which interpolates the
/// `activity_<N>` localization key with `:user`, `:contact`, `:client`,
/// `:invoice`, etc. The raw payload is preserved so unknown activity types
/// still have a chance of rendering (fallback shows the activity id).
class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.activityTypeId,
    required this.createdAt,
    required this.userId,
    required this.clientId,
    required this.contactId,
    required this.invoiceId,
    required this.quoteId,
    required this.paymentId,
    required this.expenseId,
    required this.recurringInvoiceId,
    required this.notes,
    required this.raw,
  });

  final String id;
  final int activityTypeId;
  final int createdAt;
  final String? userId;
  final String? clientId;
  final String? contactId;
  final String? invoiceId;
  final String? quoteId;
  final String? paymentId;
  final String? expenseId;
  final String? recurringInvoiceId;
  final String notes;

  /// The full server JSON so a richer renderer can grab fields we don't
  /// destructure explicitly.
  final Map<String, dynamic> raw;

  static DashboardActivity fromJson(Map<String, dynamic> json) {
    int parseInt(Object? raw) {
      if (raw is int) return raw;
      return int.tryParse('$raw') ?? 0;
    }

    String? asId(Object? raw) {
      if (raw == null) return null;
      final s = raw.toString();
      return s.isEmpty ? null : s;
    }

    return DashboardActivity(
      id: (json['id'] ?? '').toString(),
      activityTypeId: parseInt(json['activity_type_id']),
      createdAt: parseInt(json['created_at']),
      userId: asId(json['user_id']),
      clientId: asId(json['client_id']),
      contactId: asId(json['contact_id']),
      invoiceId: asId(json['invoice_id']),
      quoteId: asId(json['quote_id']),
      paymentId: asId(json['payment_id']),
      expenseId: asId(json['expense_id']),
      recurringInvoiceId: asId(json['recurring_invoice_id']),
      notes: (json['notes'] ?? '').toString(),
      raw: json,
    );
  }

  static List<DashboardActivity> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Object>()
        .map((e) {
          if (e is Map<String, dynamic>) return DashboardActivity.fromJson(e);
          if (e is Map) {
            return DashboardActivity.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            );
          }
          return null;
        })
        .whereType<DashboardActivity>()
        .toList(growable: false);
  }
}
