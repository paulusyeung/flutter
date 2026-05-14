import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the projects list's search field.
///
/// Projects use the same minimal filter surface as Products today: only the
/// state filter (`is:archived`, `is:active`). Adding a project-specific
/// dimension is a `FilterKey` subclass that writes to `vm.extraFilters`.
List<FilterKey> buildProjectFilterKeys() => const <FilterKey>[IsFilterKey()];
