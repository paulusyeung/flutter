import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/project.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_actions_row.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/entity_documents_tab.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/projects/view_models/project_detail_view_model.dart';
import 'package:admin/ui/features/projects/widgets/detail/project_detail_cards_grid.dart';
import 'package:admin/ui/features/projects/widgets/detail/project_detail_header.dart';
import 'package:admin/ui/features/projects/widgets/detail/project_progress_card.dart';
import 'package:admin/ui/features/projects/widgets/project_actions.dart';

/// Read-only Project detail screen.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with FormatterHostMixin {
  late final ProjectDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = ProjectDetailViewModel.bound(
      _services.projects.watch(companyId: _companyId, id: widget.id),
    );
    loadFormatter(_services, _companyId);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntityDetailScaffold<Project>(
      vm: _vm,
      emptyIcon: Icons.work_outline,
      emptyTitle: context.tr('project_not_found'),
      actionsForItem: (context, p) => EntityDetailActionsRow<ProjectAction>(
        items: ProjectActions.itemsFor(
          context,
          p,
          (a) => ProjectActions.dispatch(context, _services, _companyId, p, a),
        ),
      ),
      bodyBuilder: (context, p) {
        final docCount = p.documents.length;
        final docsLabel = docCount > 0
            ? context.tr('documents_with_count', {'count': '$docCount'})
            : context.tr('documents');
        return SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProjectDetailHeader(project: p, formatter: formatter),
              const SizedBox(height: InSpacing.xl),
              ProjectProgressCard(
                project: p,
                companyId: _companyId,
                formatter: formatter,
              ),
              const SizedBox(height: InSpacing.xl),
              EntityDetailTabs(
                tabs: [
                  EntityDetailTab(
                    label: context.tr('overview'),
                    icon: Icons.dashboard_outlined,
                    bodyBuilder: (_) => Padding(
                      padding: EdgeInsets.all(InSpacing.lg(context)),
                      child: ProjectDetailCardsGrid(
                        project: p,
                        companyId: _companyId,
                        formatter: formatter,
                      ),
                    ),
                  ),
                  EntityDetailTab(
                    label: docsLabel,
                    icon: Icons.description_outlined,
                    bodyBuilder: (_) => EntityDocumentsTab(
                      entityId: p.id,
                      documents: p.documents,
                      formatter: formatter,
                      onUpload: (paths) async {
                        for (final path in paths) {
                          await _services.projects.uploadDocument(
                            companyId: _companyId,
                            projectId: p.id,
                            localPath: path,
                          );
                        }
                      },
                      onDelete: (doc) async {
                        await _services.projects.deleteDocument(
                          companyId: _companyId,
                          projectId: p.id,
                          documentId: doc.id,
                        );
                      },
                      onToggleVisibility: (doc) async {
                        await _services.projects.setDocumentVisibility(
                          companyId: _companyId,
                          projectId: p.id,
                          documentId: doc.id,
                          isPublic: !doc.isPublic,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
