import 'package:admin/data/models/api/system_log_api_model.dart';
import 'package:admin/data/services/api_client.dart';

/// One-shot read service for `/api/v1/system_logs`. Read-only — no writes,
/// no bulk actions, so we don't extend `BaseEntityApi`. The endpoint is
/// paginated server-side but the UI fetches a single fixed page (matches
/// React's `per_page=200, sort=created_at|DESC`); the keyset cursor
/// machinery in `ApiClient.getList` would be in the way.
class SystemLogsApi {
  SystemLogsApi(this._client);

  final ApiClient _client;

  Future<SystemLogListApi> fetchPage({
    int perPage = 200,
    String sort = 'created_at|DESC',
  }) async {
    final raw = await _client.getOneWithQuery(
      '/api/v1/system_logs',
      query: {'per_page': '$perPage', 'sort': sort},
    );
    return SystemLogListApi.fromJson(raw as Map<String, dynamic>);
  }
}
