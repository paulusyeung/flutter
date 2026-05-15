import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/transactions/view_models/transaction_list_view_model.dart';
import 'package:admin/ui/features/transactions/widgets/transaction_filter_keys.dart';

/// Search field for the transactions list. Exposes free-text search +
/// the standard archive toggle (`is:archived`/`is:active`), plus
/// transaction-specific dimensions: `status:unmatched|matched|converted`
/// and `type:deposit|withdrawal`. Bank-account scoping rides the route
/// query string (`/transactions?bank_account_id=…`), not the token
/// search.
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
      filterKeys: buildTransactionFilterKeys(),
      wide: wide,
      hintKey: 'search_transactions_or_filter_hint',
    );
  }
}
