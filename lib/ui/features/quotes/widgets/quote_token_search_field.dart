import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/quotes/view_models/quote_list_view_model.dart';
import 'package:admin/ui/features/quotes/widgets/quote_filter_keys.dart';

class QuoteTokenSearchField extends StatelessWidget {
  const QuoteTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final QuoteListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildQuoteFilterKeys(),
      wide: wide,
      hintKey: 'search_quotes_or_filter_hint',
    );
  }
}
