import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
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
    final services = context.read<Services>();
    return StreamBuilder<Map<String, String>>(
      stream: services.clients
          .watchActiveNames(companyId: vm.companyId)
          .map((rows) => {
                for (final r in rows)
                  if (r.name.isNotEmpty) r.id: r.name,
              }),
      builder: (context, snap) {
        final names = snap.data ?? const <String, String>{};
        return TokenSearchField(
          vm: vm,
          filterKeys: buildQuoteFilterKeys(
            clients: services.clients,
            companyId: vm.companyId,
            nameForClientId: (id) => names[id],
          ),
          wide: wide,
          hintKey: 'search_quotes_or_filter_hint',
        );
      },
    );
  }
}
