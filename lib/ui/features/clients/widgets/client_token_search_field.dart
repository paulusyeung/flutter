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
      stream: services.company.watchCompany(vm.companyId),
      builder: (context, companySnap) {
        // Outer StreamBuilders keep live `id → name` maps so the
        // `group:` / `assigned:` chips render the name on first paint
        // instead of the raw id (a freshly-built key instance can't own
        // a stream cache). Mirrors `InvoiceTokenSearchField`'s
        // client-name wiring.
        return StreamBuilder<Map<String, String>>(
          stream: services.groupSettings
              .watchAll(companyId: vm.companyId)
              .map((rows) => {
                    for (final g in rows)
                      if (g.name.isNotEmpty) g.id: g.name,
                  }),
          builder: (context, groupSnap) {
            final groupNames = groupSnap.data ?? const <String, String>{};
            return StreamBuilder<Map<String, String>>(
              stream: services.user
                  .watchAllForPicker(companyId: vm.companyId)
                  .map((rows) => {
                        for (final u in rows)
                          if (u.displayName.isNotEmpty) u.id: u.displayName,
                      }),
              builder: (context, userSnap) {
                final userNames = userSnap.data ?? const <String, String>{};
                final keys = buildClientFilterKeys(
                  company: companySnap.data,
                  statics: services.statics,
                  groups: services.groupSettings,
                  users: services.user,
                  companyId: vm.companyId,
                  nameForGroupId: (id) => groupNames[id],
                  nameForAssignedId: (id) => userNames[id],
                );
                return TokenSearchField(
                  vm: vm,
                  filterKeys: keys,
                  wide: wide,
                  hintKey: 'search_clients_or_filter_hint',
                );
              },
            );
          },
        );
      },
    );
  }
}
