import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/adaptive.dart';
import 'package:admin/ui/core/list/master_detail_layout.dart';
import 'package:admin/ui/features/tasks/view_models/kanban_view_model.dart';
import 'package:admin/ui/features/tasks/views/task_list_screen.dart';
import 'package:admin/ui/features/tasks/widgets/kanban/kanban_board.dart';
import 'package:admin/ui/features/tasks/widgets/kanban/kanban_filter_bar.dart';
import 'package:admin/ui/features/tasks/widgets/tasks_view_toggle.dart';

/// Top-level kanban screen. Mounts its own [KanbanViewModel] (separate from
/// the list VM) and renders the board. AppBar carries the same toggle the
/// list screen has so the user can flip back.
class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  late final Services _services;
  late String _companyId;
  late KanbanViewModel _vm;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = KanbanViewModel(
      repo: _services.tasks,
      statusRepo: _services.taskStatuses,
      companyId: _companyId,
    );
    _services.auth.session.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    final s = _services.auth.session.value;
    if (s == null || s.currentCompanyId == _companyId) return;
    final old = _vm;
    setState(() {
      _companyId = s.currentCompanyId;
      _vm = KanbanViewModel(
        repo: _services.tasks,
        statusRepo: _services.taskStatuses,
        companyId: _companyId,
      );
    });
    old.dispose();
  }

  @override
  void dispose() {
    _services.auth.session.removeListener(_onSessionChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.wide;
    return Scaffold(
      // Mirror the list view's wide AppBar chrome: same `toolbarHeight`,
      // same `flexibleSpace` + `Padding(horizontal: 24)` wrapper, same
      // trailing `TasksViewToggle`. Anchored right at exactly 24 px from
      // the screen edge so the toggle's pixel position matches the list
      // screen — switching list ↔ kanban no longer shifts the affordance.
      // Narrow falls back to a plain AppBar.actions so the title + toggle
      // sit on a single compact row.
      appBar: wide
          ? AppBar(
              toolbarHeight: 64,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              flexibleSpace: SafeArea(
                bottom: false,
                child: Padding(
                  // Horizontal 24 aligns with the kanban body's outer
                  // gutters; vertical 12 centers the 40 px Row inside
                  // the 64 px toolbar so the toggle gets breathing room
                  // above + below instead of hugging the top edge.
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        context.tr('tasks'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TasksViewToggle(active: TasksViewMode.kanban, wide: true),
                    ],
                  ),
                ),
              ),
            )
          : AppBar(
              title: Text(context.tr('tasks')),
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: TasksViewToggle(
                    active: TasksViewMode.kanban,
                    wide: false,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: context.tr('new_task'),
        onPressed: () => goToCreateRoute(context, '/tasks/new'),
        child: const Icon(Icons.add),
      ),
      body: ChangeNotifierProvider<KanbanViewModel>.value(
        value: _vm,
        child: Column(
          children: [
            KanbanFilterBar(companyId: _vm.companyId),
            const Expanded(child: KanbanBoard()),
          ],
        ),
      ),
    );
  }
}
