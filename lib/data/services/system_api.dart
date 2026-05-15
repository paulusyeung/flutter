import 'package:admin/data/models/api/health_check_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// HTTP service for the self-hosted server diagnostic endpoints surfaced by
/// the Health Check dialog: `/health_check`, `/ping?clear_cache=true`, and
/// `/last_error`. All three are read-only (or read-only-in-effect) and
/// bypass the outbox — the Health Check dialog owns its own loading state.
class SystemApi {
  SystemApi(this._client);

  final ApiClient _client;

  Future<HealthCheckResponse> getHealthCheck() async {
    final raw = await _client.getOne('/api/v1/health_check');
    return HealthCheckResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<void> clearCache() {
    return _client.getOneWithQuery(
      '/api/v1/ping',
      query: const {'clear_cache': 'true'},
    );
  }

  Future<HealthCheckLastErrorResponse> getLastError() async {
    final raw = await _client.getOne('/api/v1/last_error');
    return HealthCheckLastErrorResponse.fromJson(raw as Map<String, dynamic>);
  }
}
