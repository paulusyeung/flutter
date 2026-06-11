import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/tasks/task_filter_keys.dart';
import 'package:admin/ui/features/tasks/view_models/task_list_view_model.dart';

/// Thin wrapper that wires [TokenSearchField] for the tasks list. Mirrors
/// `ProductTokenSearchField` — the layout in `EntityListNormalAppBar`
/// stays entity-agnostic and only the filter keys / hint key change.
///
/// Stateful so the filter keys (and the company watch stream) are built
/// once and reused: `ProjectFilterKey` opens a Drift watch subscription in
/// its constructor, and rebuilding the key list on every list rebuild
/// leaked one live stream query per rebuild — hundreds over a normal
/// browsing session, each re-executed on every projects-table write.
class TaskTokenSearchField extends StatefulWidget {
  const TaskTokenSearchField({required this.vm, required this.wide, super.key});

  final TaskListViewModel vm;
  final bool wide;

  @override
  State<TaskTokenSearchField> createState() => _TaskTokenSearchFieldState();
}

class _TaskTokenSearchFieldState extends State<TaskTokenSearchField> {
  Stream<Company?>? _companyStream;
  String? _streamCompanyId;

  List<FilterKey>? _keys;
  String? _keysCompanyId;
  String? _keysLabelSignature;

  /// The only company-derived input the keys consume: the configured
  /// custom-field labels. Keys are rebuilt only when these change (or the
  /// company switches), not on every Drift company emission.
  static String _labelSignature(Company? c) => c == null
      ? ''
      : [for (var i = 1; i <= 4; i++) c.customFieldLabel('task$i')].join(' ');

  void _disposeKeys() {
    for (final k in _keys ?? const <FilterKey>[]) {
      k.dispose();
    }
    _keys = null;
  }

  List<FilterKey> _keysFor(Services services, Company? company) {
    final signature = _labelSignature(company);
    if (_keys != null &&
        _keysCompanyId == widget.vm.companyId &&
        _keysLabelSignature == signature) {
      return _keys!;
    }
    _disposeKeys();
    _keysCompanyId = widget.vm.companyId;
    _keysLabelSignature = signature;
    return _keys = buildTaskFilterKeys(
      projects: services.projects,
      statuses: services.taskStatuses,
      tags: services.tags,
      companyId: widget.vm.companyId,
      company: company,
    );
  }

  @override
  void dispose() {
    _disposeKeys();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    // Hoisted (not built inline in the StreamBuilder) so a parent rebuild
    // doesn't swap the subscription — the stable-stream rule from the
    // outbox-spinner bug class.
    if (_companyStream == null || _streamCompanyId != widget.vm.companyId) {
      _streamCompanyId = widget.vm.companyId;
      _companyStream = services.company.watchCompany(widget.vm.companyId);
    }
    return StreamBuilder<Company?>(
      stream: _companyStream,
      builder: (context, companySnap) {
        return TokenSearchField(
          vm: widget.vm,
          filterKeys: _keysFor(services, companySnap.data),
          wide: widget.wide,
          hintKey: 'search_tasks_or_filter_hint',
        );
      },
    );
  }
}
