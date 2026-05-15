import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';

/// Build the filter keys exposed in the invoices list's search field.
///
/// Invoices launch with the same minimal surface as Expenses: only the
/// state filter (`is:archived`, `is:active`, `is:deleted`). M2+ adds
/// status chips (Draft/Sent/Partial/Paid/Past Due/Cancelled), client
/// picker, and the four custom-field filters as `FilterKey` subclasses
/// that write to `vm.extraFilters`.
List<FilterKey> buildInvoiceFilterKeys() => const <FilterKey>[IsFilterKey()];
