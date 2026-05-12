import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/clients/client_filter_keys.dart';
import 'package:admin/ui/features/clients/view_models/client_list_view_model.dart';

/// Thin wrapper that wires [TokenSearchField] for the clients list. Watches
/// the current `Company` so the configured custom-field labels feed into
/// the `CustomFieldFilterKey` instances. Lives in the clients feature so
/// the core `TokenSearchField` stays entity-agnostic.
class ClientTokenSearchField extends StatelessWidget {
  const ClientTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final ClientListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return StreamBuilder<Company?>(
      stream: services.company.watch(vm.companyId),
      builder: (context, snapshot) {
        final keys = buildClientFilterKeys(
          company: snapshot.data,
          statics: services.statics,
        );
        return TokenSearchField(
          vm: vm,
          filterKeys: keys,
          wide: wide,
          hintKey: 'search_clients_or_filter_hint',
        );
      },
    );
  }
}
