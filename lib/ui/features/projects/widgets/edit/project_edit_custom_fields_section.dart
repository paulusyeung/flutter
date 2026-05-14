import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/edit/entity_custom_fields_section.dart';
import 'package:admin/ui/features/dashboard/widgets/card_shell.dart';
import 'package:admin/ui/features/projects/view_models/project_edit_view_model.dart';

/// Wraps the generic [EntityCustomFieldsSection]. Hidden when the active
/// company hasn't configured any `projectN` custom-field labels.
class ProjectEditCustomFieldsSection extends StatelessWidget {
  const ProjectEditCustomFieldsSection({super.key, required this.vm});

  final ProjectEditViewModel vm;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final companyStream = services.company.watchCompany(vm.companyId);
    return StreamBuilder(
      stream: companyStream,
      builder: (context, snap) {
        final company = snap.data;
        final hasAny =
            company != null &&
            [
              1,
              2,
              3,
              4,
            ].any((i) => company.customFieldLabel('project$i').isNotEmpty);
        if (!hasAny) return const SizedBox.shrink();
        return DashboardCardShell(
          title: context.tr('custom_fields'),
          child: EntityCustomFieldsSection(
            keyPrefix: 'project',
            companyStream: companyStream,
            values: [
              vm.draft.customValue1,
              vm.draft.customValue2,
              vm.draft.customValue3,
              vm.draft.customValue4,
            ],
            onChanged: [
              vm.setCustomValue1,
              vm.setCustomValue2,
              vm.setCustomValue3,
              vm.setCustomValue4,
            ],
          ),
        );
      },
    );
  }
}
