import 'package:admin/data/services/api_client.dart';

/// Fetches `/api/v1/statics` (currencies, countries, payment types, gateways,
/// timezones, date formats, languages, industries, sizes). Returns the raw
/// JSON map; `StaticsRepository` is responsible for caching and key lookups.
class StaticsService {
  StaticsService(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> fetch() async {
    final raw = await _client.getOne('/api/v1/statics');
    if (raw is Map<String, dynamic>) return raw;
    throw StateError('Unexpected /api/v1/statics shape: ${raw.runtimeType}');
  }
}
