import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/projects/project_filter_keys.dart';
import 'package:admin/ui/features/projects/view_models/project_list_view_model.dart';

/// Thin wrapper that wires [TokenSearchField] for the projects list.
class ProjectTokenSearchField extends StatelessWidget {
  const ProjectTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final ProjectListViewModel vm;
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
              .map((rows) => {
                    for (final r in rows)
                      if (r.name.isNotEmpty) r.id: r.name,
                  }),
          builder: (context, snap) {
            final names = snap.data ?? const <String, String>{};
            return TokenSearchField(
              vm: vm,
              filterKeys: buildProjectFilterKeys(
                clients: services.clients,
                companyId: vm.companyId,
                company: companySnap.data,
                nameForClientId: (id) => names[id],
              ),
              wide: wide,
              hintKey: 'search_projects_or_filter_hint',
            );
          },
        );
      },
    );
  }
}
