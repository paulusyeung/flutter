import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Tasks expose state (active/archived/deleted) as their built-in
/// filter dimension. Status / client / billable filters can be added in
/// a follow-up — they need a `FilterKey` subclass that writes to
/// `vm.extraFilters` against the server keys (`status_id`, `client_id`,
/// `billable`).
List<FilterKey> buildTaskFilterKeys() => const <FilterKey>[IsFilterKey()];
