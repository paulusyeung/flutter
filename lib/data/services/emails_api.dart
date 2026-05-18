import 'package:admin/data/models/api/email_history_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// API for the email-history read and the bounce-reactivation write. Neither
/// endpoint is rooted on a per-entity CRUD path, so this wraps [ApiClient]
/// directly (same shape as [ActivitiesApi]).
class EmailsApi {
  EmailsApi(this.client);

  final ApiClient client;

  /// `POST /api/v1/emails/clientHistory/{clientId}` — every email sent to the
  /// client's contacts with its delivery events. Returns a **bare JSON array**
  /// (no `{data: [...]}` envelope), so we map the list directly. A client with
  /// no sends yields `[]`.
  Future<List<EmailHistoryRecordApi>> clientHistory({
    required String clientId,
  }) async {
    final raw = await client.postJson(
      '/api/v1/emails/clientHistory/$clientId',
      readOnly: true,
      body: const {},
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(EmailHistoryRecordApi.fromJson)
        .toList();
  }

  /// `POST /api/v1/reactivate_email/{id}` — clears the bounce/spam suppression
  /// for a Postmark message id (the invitation `message_id` / email-event
  /// `bounce_id`). Empty body; the server returns no entity payload we apply
  /// locally. Driven through the outbox so it retries offline.
  Future<void> reactivateEmail({
    required String messageId,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'POST',
      path: '/api/v1/reactivate_email/$messageId',
      idempotencyKey: idempotencyKey,
    );
  }
}
