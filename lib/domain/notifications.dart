/// Notification event ids + grouping for the User Management Notifications
/// tab. Stored on `company_user.notifications.email[]` with a 3-suffix
/// scheme:
///   * `<event>_all`   — receive notifications for every record of this type.
///   * `<event>_user`  — only records owned by this user.
///   * (absent)         — none.
///
/// A global selector at the top of the tab maps to two special tokens:
///   * `all_notifications`       — all records, all event types.
///   * `all_user_notifications`  — user-owned records only, all event types.
///
/// When either global token is present, the per-event rows are muted; the
/// global value dominates. Mirrors React's `Notifications.tsx`.
library;

/// One notification event with its localization-key label.
class NotificationEvent {
  const NotificationEvent({required this.id, required this.labelKey});
  final String id;
  final String labelKey;
}

/// One grouped section of related events (Invoices / Payments / Quotes / …).
class NotificationSection {
  const NotificationSection({required this.headerKey, required this.events});
  final String headerKey;
  final List<NotificationEvent> events;
}

/// The 21 events grouped by entity, mirroring React's flat list but
/// resequenced into related-event sections so the tab doesn't read as a
/// 21-toggle wall.
const List<NotificationSection> kNotificationSections = <NotificationSection>[
  NotificationSection(
    headerKey: 'invoices',
    events: <NotificationEvent>[
      NotificationEvent(id: 'invoice_created', labelKey: 'invoice_created'),
      NotificationEvent(
        id: 'invoice_sent',
        labelKey: 'invoice_sent_notification_label',
      ),
      NotificationEvent(id: 'invoice_viewed', labelKey: 'invoice_viewed'),
      NotificationEvent(id: 'invoice_late', labelKey: 'invoice_late'),
    ],
  ),
  NotificationSection(
    headerKey: 'payments',
    events: <NotificationEvent>[
      NotificationEvent(id: 'payment_success', labelKey: 'payment_success'),
      NotificationEvent(id: 'payment_failure', labelKey: 'payment_failure'),
      NotificationEvent(id: 'payment_manual', labelKey: 'manual_payment'),
    ],
  ),
  NotificationSection(
    headerKey: 'quotes',
    events: <NotificationEvent>[
      NotificationEvent(id: 'quote_created', labelKey: 'quote_created'),
      NotificationEvent(id: 'quote_sent', labelKey: 'quote_sent'),
      NotificationEvent(id: 'quote_viewed', labelKey: 'quote_viewed'),
      NotificationEvent(id: 'quote_approved', labelKey: 'quote_approved'),
      NotificationEvent(id: 'quote_expired', labelKey: 'quote_expired'),
    ],
  ),
  NotificationSection(
    headerKey: 'credits',
    events: <NotificationEvent>[
      NotificationEvent(id: 'credit_created', labelKey: 'credit_created'),
      NotificationEvent(id: 'credit_sent', labelKey: 'credit_sent'),
      NotificationEvent(id: 'credit_viewed', labelKey: 'credit_viewed'),
    ],
  ),
  NotificationSection(
    headerKey: 'purchase_orders',
    events: <NotificationEvent>[
      NotificationEvent(
        id: 'purchase_order_created',
        labelKey: 'purchase_order_created',
      ),
      NotificationEvent(
        id: 'purchase_order_sent',
        labelKey: 'purchase_order_sent',
      ),
      NotificationEvent(
        id: 'purchase_order_viewed',
        labelKey: 'purchase_order_viewed',
      ),
      NotificationEvent(
        id: 'purchase_order_accepted',
        labelKey: 'purchase_order_accepted',
      ),
    ],
  ),
  NotificationSection(
    headerKey: 'inventory',
    events: <NotificationEvent>[
      NotificationEvent(
        id: 'inventory_threshold',
        labelKey: 'inventory_threshold',
      ),
    ],
  ),
];

/// Flat list of every event in `kNotificationSections` (preserves order).
final List<NotificationEvent> kNotificationEvents = <NotificationEvent>[
  for (final s in kNotificationSections) ...s.events,
];

/// Special "set all" tokens written to `notifications.email[]` when the
/// global selector at the top of the tab is engaged.
const String kNotificationsAll = 'all_notifications';
const String kNotificationsAllUser = 'all_user_notifications';

/// 3-state choice for one event row. Maps to a token suffix on save.
enum NotificationChoice {
  /// All records of this type — token `<event>_all`.
  all,

  /// Records owned by this user — token `<event>_user`.
  user,

  /// No notification — no token emitted.
  none,
}

extension NotificationChoiceToken on NotificationChoice {
  String? tokenFor(String eventId) => switch (this) {
        NotificationChoice.all => '${eventId}_all',
        NotificationChoice.user => '${eventId}_user',
        NotificationChoice.none => null,
      };

  String get labelKey => switch (this) {
        NotificationChoice.all => 'all_records',
        NotificationChoice.user => 'owned_by_user',
        NotificationChoice.none => 'none',
      };
}

/// 3-state global selector at the top of the tab.
enum NotificationGlobal {
  /// Receive notifications for every event on every record.
  allRecords,

  /// Receive notifications only for records this user owns.
  ownedByUser,

  /// Use the per-event selections (custom mix).
  custom,
}

extension NotificationGlobalToken on NotificationGlobal {
  String? get token => switch (this) {
        NotificationGlobal.allRecords => kNotificationsAll,
        NotificationGlobal.ownedByUser => kNotificationsAllUser,
        NotificationGlobal.custom => null,
      };

  String get labelKey => switch (this) {
        NotificationGlobal.allRecords => 'all_records',
        NotificationGlobal.ownedByUser => 'owned_by_user',
        NotificationGlobal.custom => 'custom',
      };
}

/// Read the global selector state from the stored `notifications.email[]`.
NotificationGlobal globalFromTokens(List<String> tokens) {
  if (tokens.contains(kNotificationsAll)) return NotificationGlobal.allRecords;
  if (tokens.contains(kNotificationsAllUser)) {
    return NotificationGlobal.ownedByUser;
  }
  return NotificationGlobal.custom;
}

/// Read the per-event 3-state from the stored `notifications.email[]`.
NotificationChoice choiceFromTokens(String eventId, List<String> tokens) {
  if (tokens.contains('${eventId}_all')) return NotificationChoice.all;
  if (tokens.contains('${eventId}_user')) return NotificationChoice.user;
  return NotificationChoice.none;
}

/// Serialize the global + per-event selections back into the
/// `notifications.email[]` array.
List<String> tokensFor({
  required NotificationGlobal global,
  required Map<String, NotificationChoice> perEvent,
}) {
  final out = <String>[];
  if (global != NotificationGlobal.custom) {
    out.add(global.token!);
    return out;
  }
  for (final entry in perEvent.entries) {
    final t = entry.value.tokenFor(entry.key);
    if (t != null) out.add(t);
  }
  return out;
}
