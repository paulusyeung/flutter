import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/webhook_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'webhook.freezed.dart';

/// Default values used when creating a new webhook.
const String kWebhookDefaultFormat = 'JSON';
const String kWebhookDefaultRestMethod = 'post';

/// Allowed HTTP verbs the server accepts on `/api/v1/webhooks`. Drives the
/// REST-method selector in the edit screen. Stored lowercase to match the
/// server's case-sensitive `rest_method => required|in:post,put` validation
/// (PATCH is not supported); the UI uppercases them for display only.
const List<String> kWebhookRestMethods = <String>['post', 'put'];

/// Server-side webhook event IDs and their human-readable wire names. The
/// server stores `event_id` as the numeric string (e.g. `'1'`); the value
/// here is the event-name (e.g. `'create_client'`) used both in the picker
/// label and as the localization key. Mirrors `webhook_model.dart`'s
/// `EVENT_MAP` in admin-portal — kept in sync manually as new events ship.
const Map<String, String> kWebhookEventNames = <String, String>{
  '1': 'create_client',
  '10': 'update_client',
  '37': 'archive_client',
  '45': 'restore_client',
  '11': 'delete_client',
  '2': 'create_invoice',
  '60': 'sent_invoice',
  '8': 'update_invoice',
  '22': 'late_invoice',
  '24': 'remind_invoice',
  '33': 'archive_invoice',
  '41': 'restore_invoice',
  '9': 'delete_invoice',
  '3': 'create_quote',
  '61': 'sent_quote',
  '6': 'update_quote',
  '21': 'approve_quote',
  '23': 'expired_quote',
  '64': 'remind_quote',
  '34': 'archive_quote',
  '42': 'restore_quote',
  '7': 'delete_quote',
  '27': 'create_credit',
  '62': 'sent_credit',
  '28': 'update_credit',
  '35': 'archive_credit',
  '43': 'restore_credit',
  '29': 'delete_credit',
  '4': 'create_payment',
  '31': 'update_payment',
  '32': 'archive_payment',
  '40': 'restore_payment',
  '12': 'delete_payment',
  '5': 'create_vendor',
  '13': 'update_vendor',
  '48': 'archive_vendor',
  '49': 'restore_vendor',
  '14': 'delete_vendor',
  '15': 'create_expense',
  '16': 'update_expense',
  '39': 'archive_expense',
  '47': 'restore_expense',
  '17': 'delete_expense',
  '18': 'create_task',
  '19': 'update_task',
  '36': 'archive_task',
  '44': 'restore_task',
  '20': 'delete_task',
  '25': 'create_project',
  '26': 'update_project',
  '38': 'archive_project',
  '46': 'restore_project',
  '30': 'delete_project',
  '50': 'create_product',
  '51': 'update_product',
  '54': 'archive_product',
  '53': 'restore_product',
  '52': 'delete_product',
  '55': 'create_purchase_order',
  '63': 'sent_purchase_order',
  '56': 'update_purchase_order',
  '59': 'archive_purchase_order',
  '58': 'restore_purchase_order',
  '57': 'delete_purchase_order',
  '65': 'accept_purchase_order',
};

/// Domain `Webhook` (wire entity: `webhook`). Settings-area entity reached
/// via Settings → Integrations → API Webhooks. Server fires the configured
/// event to [targetUrl] using [restMethod] and the provided [headers].
@freezed
abstract class Webhook with _$Webhook {
  const Webhook._();

  const factory Webhook({
    required String id,
    required String eventId,
    required String targetUrl,
    required String format,
    required String restMethod,
    @Default(<String, String>{}) Map<String, String> headers,
    required bool isDeleted,
    required DateTime updatedAt,
    required DateTime createdAt,
    required DateTime? archivedAt,
    @Default(false) bool isDirty,
  }) = _Webhook;

  factory Webhook.fromApi(WebhookApi a) => Webhook(
    id: a.id,
    eventId: a.eventId,
    targetUrl: a.targetUrl,
    format: a.format.isEmpty ? kWebhookDefaultFormat : a.format,
    // Normalize to lowercase: the server only accepts/stores `post`/`put`, but
    // a row created before that was enforced may carry a legacy uppercase
    // value. Lowercasing keeps the domain value canonical so the edit screen's
    // SegmentedButton highlights the right segment.
    restMethod: a.restMethod.isEmpty
        ? kWebhookDefaultRestMethod
        : a.restMethod.toLowerCase(),
    headers: Map<String, String>.from(a.headers),
    isDeleted: a.isDeleted,
    updatedAt: epochSecondsToUtc(a.updatedAt),
    createdAt: epochSecondsToUtc(a.createdAt),
    archivedAt: epochSecondsToUtcOrNull(a.archivedAt),
  );

  Map<String, dynamic> toApiJson({bool preserveTempId = false}) {
    final json = WebhookApi(
      id: id,
      eventId: eventId,
      targetUrl: targetUrl,
      format: format,
      restMethod: restMethod,
      headers: headers,
      isDeleted: isDeleted,
      updatedAt: updatedAt.millisecondsSinceEpoch ~/ 1000,
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
      archivedAt: archivedAt == null
          ? 0
          : archivedAt!.millisecondsSinceEpoch ~/ 1000,
    ).toJson();
    if (!preserveTempId && id.startsWith('tmp_')) {
      json.remove('id');
    }
    return json;
  }
}
