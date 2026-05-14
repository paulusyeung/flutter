import 'package:admin/data/models/api/activity_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// API for the `/api/v1/activities/*` family. Two endpoints, neither
/// rooted on a per-entity path — `BaseEntityApi` doesn't fit, so this
/// service wraps `ApiClient` directly.
///
/// The endpoints differ in the singular/plural form of `entity`:
/// `/notes` (the write) wants `"clients"`; `/entity` (the read) wants
/// `"client"`. Confirmed against demo.invoiceninja.com and matches both
/// legacy admin-portal and the React reference client.
class ActivitiesApi {
  ActivitiesApi(this.client);

  final ApiClient client;

  /// `POST /api/v1/activities/notes` — append a user comment to [entity]'s
  /// activity stream. The server creates an Activity row with
  /// `activity_type_id = 141`. Response body is discarded.
  Future<void> addNote({
    required String entity,
    required String entityId,
    required String notes,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'POST',
      path: '/api/v1/activities/notes',
      idempotencyKey: idempotencyKey,
      body: {'entity': entity, 'entity_id': entityId, 'notes': notes},
    );
  }

  /// `POST /api/v1/activities/entity` — fetch the activity stream for a
  /// single entity. Returns the rich denormalized form with `user.label`,
  /// `client.label`, `invoice.label` populated, so callers can render names
  /// without joining against a users table.
  Future<List<ActivityApi>> fetchForEntity({
    required String entity,
    required String entityId,
  }) async {
    final raw = await client.postJson(
      '/api/v1/activities/entity',
      readOnly: true,
      body: {'entity': entity, 'entity_id': entityId},
    );
    if (raw is! Map<String, dynamic>) return const [];
    final parsed = ActivityListApi.fromJson(raw);
    return parsed.data;
  }
}
