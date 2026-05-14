import 'package:flutter/material.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/ui/features/projects/view_models/project_edit_view_model.dart';
import 'package:admin/ui/features/projects/widgets/edit/project_edit_budget_section.dart';
import 'package:admin/ui/features/projects/widgets/edit/project_edit_custom_fields_section.dart';
import 'package:admin/ui/features/projects/widgets/edit/project_edit_details_section.dart';
import 'package:admin/ui/features/projects/widgets/edit/project_edit_notes_section.dart';

/// Lays out the project edit cards (Details, Budget, Notes, Custom Fields)
/// using the same `1fr` main + fixed-width sidebar pattern as
/// `ClientEditLayout` / `ProductEditLayout`.
///
/// - ≥1100 px: two columns. Left holds Details + Budget; right holds Notes
///   + Custom Fields.
/// - <1100 px: single scrolling column.
class ProjectEditLayout extends StatelessWidget {
  const ProjectEditLayout({super.key, required this.vm});

  final ProjectEditViewModel vm;

  static const double _twoColumnBreakpoint = 1100;
  static const double _sidebarWidth = 360;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= _twoColumnBreakpoint;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(InSpacing.lg),
              child: twoCol ? _wide() : _narrow(),
            );
          },
        );
      },
    );
  }

  Widget _wide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProjectEditDetailsSection(vm: vm),
              const SizedBox(height: InSpacing.md),
              ProjectEditBudgetSection(vm: vm),
            ],
          ),
        ),
        const SizedBox(width: InSpacing.md),
        SizedBox(
          width: _sidebarWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProjectEditNotesSection(vm: vm),
              const SizedBox(height: InSpacing.md),
              ProjectEditCustomFieldsSection(vm: vm),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectEditDetailsSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ProjectEditBudgetSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ProjectEditNotesSection(vm: vm),
        const SizedBox(height: InSpacing.md),
        ProjectEditCustomFieldsSection(vm: vm),
      ],
    );
  }
}
