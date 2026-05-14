import 'package:flutter/material.dart';

import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/tasks/task_filter_keys.dart';
import 'package:admin/ui/features/tasks/view_models/task_list_view_model.dart';

/// Thin wrapper that wires [TokenSearchField] for the tasks list. Mirrors
/// `ProductTokenSearchField` — the layout in `EntityListNormalAppBar`
/// stays entity-agnostic and only the filter keys / hint key change.
class TaskTokenSearchField extends StatelessWidget {
  const TaskTokenSearchField({required this.vm, required this.wide, super.key});

  final TaskListViewModel vm;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TokenSearchField(
      vm: vm,
      filterKeys: buildTaskFilterKeys(),
      wide: wide,
      hintKey: 'search_tasks_or_filter_hint',
    );
  }
}
