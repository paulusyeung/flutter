import 'package:admin/data/models/api/location_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// Standalone `/api/v1/locations` resource. Client locations are
/// read-embedded on the client (`client.locations[]`) but written here as
/// their own REST entity (mirrors React's `LocationModal`). All three calls
/// go through `client.mutate` so they ride the outbox/idempotency contract;
/// the Client dispatcher's `customActions` invoke these then refresh the
/// parent client so the embedded list reflects the change.
class LocationsApi {
  LocationsApi(this.client);

  final ApiClient client;

  static const String _basePath = '/api/v1/locations';

  /// `POST /api/v1/locations` — body carries `client_id` + the address
  /// fields (see `Location.toApiJson`). Returns the created location.
  Future<LocationApi> create({
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'POST',
      path: _basePath,
      idempotencyKey: idempotencyKey,
      body: body,
    );
    return _parse(raw);
  }

  /// `PUT /api/v1/locations/{id}` — full location body. Returns the updated
  /// location.
  Future<LocationApi> update({
    required String id,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    final raw = await client.mutate(
      method: 'PUT',
      path: '$_basePath/$id',
      idempotencyKey: idempotencyKey,
      body: body,
    );
    return _parse(raw);
  }

  /// `DELETE /api/v1/locations/{id}`.
  Future<void> delete({
    required String id,
    required String idempotencyKey,
  }) async {
    await client.mutate(
      method: 'DELETE',
      path: '$_basePath/$id',
      idempotencyKey: idempotencyKey,
    );
  }

  LocationApi _parse(Object? raw) {
    final m = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final data = m['data'];
    return LocationApi.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }
}
