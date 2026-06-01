import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
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
    return StreamBuilder<Company?>(
      stream: services.company.watchCompany(vm.companyId),
      builder: (context, companySnap) {
        return StreamBuilder<Map<String, String>>(
          stream: services.clients
              .watchActiveNames(companyId: vm.companyId)
              .map(
                (rows) => {
                  for (final r in rows)
                    if (r.name.isNotEmpty) r.id: r.name,
                },
              ),
          builder: (context, snap) {
            final names = snap.data ?? const <String, String>{};
            return TokenSearchField(
              vm: vm,
              filterKeys: buildCreditFilterKeys(
                clients: services.clients,
                companyId: vm.companyId,
                company: companySnap.data,
                nameForClientId: (id) => names[id],
              ),
              wide: wide,
              hintKey: 'search_credits_or_filter_hint',
            );
          },
        );
      },
    );
  }
}
