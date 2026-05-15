import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/credits/view_models/credit_list_view_model.dart';
import 'package:admin/ui/features/credits/widgets/credit_filter_keys.dart';

class CreditTokenSearchField extends StatelessWidget {
  const CreditTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final CreditListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return TokenSearchField(
      vm: vm,
      filterKeys: buildCreditFilterKeys(
        clients: services.clients,
        companyId: vm.companyId,
      ),
      wide: wide,
      hintKey: 'search_credits_or_filter_hint',
    );
  }
}
