import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/filter_keys_common.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/transactions/view_models/transaction_list_view_model.dart';

/// Search field for the transactions list. Starts with the standard
/// `is:archived`/`is:active` state filter; entity-specific facets (status,
/// type, bank-account) are wired through the filter chip row above the
/// list rather than into the token search field.
class TransactionTokenSearchField extends StatelessWidget {
  const TransactionTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final TransactionListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: const <FilterKey>[IsFilterKey()],
      wide: wide,
      hintKey: 'search_transactions_or_filter_hint',
    );
  }
}
