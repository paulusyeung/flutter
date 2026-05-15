import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/payments/view_models/payment_list_view_model.dart';
import 'package:admin/ui/features/payments/widgets/payment_filter_keys.dart';

class PaymentTokenSearchField extends StatelessWidget {
  const PaymentTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final PaymentListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return TokenSearchField(
      vm: vm,
      filterKeys: buildPaymentFilterKeys(
        clients: services.clients,
        companyId: vm.companyId,
      ),
      wide: wide,
      hintKey: 'search_payments',
    );
  }
}
