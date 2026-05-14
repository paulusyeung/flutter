import 'package:flutter/material.dart';

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
    return TokenSearchField(
      vm: vm,
      filterKeys: buildProjectFilterKeys(),
      wide: wide,
      hintKey: 'search_projects_or_filter_hint',
    );
  }
}
