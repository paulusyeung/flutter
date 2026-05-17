import 'package:admin/data/models/api/search_result_api_model.dart';

/// Flattened global-search hit. [group] is the response map key the hit
/// came from (`clients`, `client_contacts`, `invoices`, `settings`, …) —
/// it's the unambiguous discriminator for routing (the per-item `type` is
/// noisier). [path] is the server-supplied destination (used as-is for
/// settings hits; entity hits route via the entity registry by [group]).
class SearchResult {
  const SearchResult({
    required this.group,
    required this.name,
    required this.id,
    required this.path,
  });

  final String group;
  final String name;
  final String id;
  final String path;

  factory SearchResult.fromApi(String group, SearchResultApi a) =>
      SearchResult(group: group, name: a.name, id: a.id, path: a.path);

  bool get isSettings => group == 'settings';
}
