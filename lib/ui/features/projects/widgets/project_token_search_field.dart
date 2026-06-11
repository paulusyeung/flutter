import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/models/domain/company_custom_fields.dart';
import 'package:admin/ui/core/list/search/filter_key.dart';
import 'package:admin/ui/core/list/search/token_search_field.dart';
import 'package:admin/ui/features/projects/project_filter_keys.dart';
import 'package:admin/ui/features/projects/view_models/project_list_view_model.dart';

/// Thin wrapper that wires [TokenSearchField] for the projects list.
///
/// Stateful so the filter keys (and the company watch stream) are built once
/// and reused: `TagFilterKey` opens a Drift watch subscription in its
/// constructor, and rebuilding the key list on every list rebuild leaked one
/// live stream query per rebuild (same leak class fixed for the task list —
/// see `TaskTokenSearchField`). The client-names map feeds the memoized
/// `ClientFilterKey` via a State field so chips stay current without
/// recreating the keys.
class ProjectTokenSearchField extends StatefulWidget {
  const ProjectTokenSearchField({
    required this.vm,
    required this.wide,
    super.key,
  });

  final ProjectListViewModel vm;
  final bool wide;

  @override
  State<ProjectTokenSearchField> createState() =>
      _ProjectTokenSearchFieldState();
}

class _ProjectTokenSearchFieldState extends State<ProjectTokenSearchField> {
  Stream<Company?>? _companyStream;
  Stream<Map<String, String>>? _namesStream;
  String? _streamCompanyId;

  /// Latest client id→name map, cached so the memoized `ClientFilterKey`'s
  /// `nameForClientId` closure resolves current names without rebuilding the
  /// keys. Updated in `build` from the names `StreamBuilder` (which already
  /// drives the rebuild that re-renders the chips).
  Map<String, String> _clientNames = const {};

  List<FilterKey>? _keys;
  String? _keysCompanyId;
  String? _keysLabelSignature;

  /// The only company-derived input the keys consume: the configured
  /// custom-field labels. Keys are rebuilt only when these change (or the
  /// company switches), not on every Drift company emission.
  static String _labelSignature(Company? c) => c == null
      ? ''
      : [
          for (var i = 1; i <= 4; i++) c.customFieldLabel('project$i'),
        ].join(' ');

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
    return _keys = buildProjectFilterKeys(
      clients: services.clients,
      tags: services.tags,
      companyId: widget.vm.companyId,
      company: company,
      // Reads the live State field, so the memoized key stays correct as the
      // names stream emits (chips re-render on the StreamBuilder rebuild).
      nameForClientId: (id) => _clientNames[id],
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
    // Hoist the streams so a parent rebuild doesn't swap the subscription —
    // the stable-stream rule from the outbox-spinner bug class.
    if (_streamCompanyId != widget.vm.companyId) {
      _streamCompanyId = widget.vm.companyId;
      _companyStream = services.company.watchCompany(widget.vm.companyId);
      _namesStream = services.clients
          .watchActiveNames(companyId: widget.vm.companyId)
          .map(
            (rows) => {
              for (final r in rows)
                if (r.name.isNotEmpty) r.id: r.name,
            },
          );
    }
    return StreamBuilder<Company?>(
      stream: _companyStream,
      builder: (context, companySnap) {
        return StreamBuilder<Map<String, String>>(
          stream: _namesStream,
          builder: (context, namesSnap) {
            if (namesSnap.hasData) _clientNames = namesSnap.data!;
            return TokenSearchField(
              vm: widget.vm,
              filterKeys: _keysFor(services, companySnap.data),
              wide: widget.wide,
              hintKey: 'search_projects_or_filter_hint',
            );
          },
        );
      },
    );
  }
}
