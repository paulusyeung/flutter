// Shared constants + re-exports for per-entity filter-key files
// (`client_filter_keys.dart`, `product_filter_keys.dart`, …). New entities
// import this file alongside the entity-specific keys.

export 'package:admin/ui/core/list/search/is_filter_key.dart' show IsFilterKey;

/// Per-key cap on the synchronous `quickValueSuggestions` lookup powering
/// the key-mode picker's cross-key value matches. Three rows keeps any
/// single key from monopolising the picker when the user's query matches
/// many entries (e.g. `un` against countries: United States, United
/// Kingdom, United Arab Emirates, …). The menu applies a 6-row total cap
/// on top across all keys.
const int kQuickValueLimitPerKey = 3;
