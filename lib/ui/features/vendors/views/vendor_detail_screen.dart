import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/vendor.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/detail/entity_detail_scaffold.dart';
import 'package:admin/ui/core/detail/entity_detail_tabs.dart';
import 'package:admin/ui/core/detail/entity_documents_tab.dart';
import 'package:admin/ui/core/widgets/formatter_host_mixin.dart';
import 'package:admin/ui/features/vendors/view_models/vendor_detail_view_model.dart';
import 'package:admin/ui/features/vendors/widgets/detail/vendor_detail_actions_row.dart';
import 'package:admin/ui/features/vendors/widgets/detail/vendor_detail_cards.dart';
import 'package:admin/ui/features/vendors/widgets/detail/vendor_detail_header.dart';

class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen>
    with FormatterHostMixin {
  late final VendorDetailViewModel _vm;
  late final Services _services;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _services = context.read<Services>();
    _companyId = _services.auth.session.value!.currentCompanyId;
    _vm = VendorDetailViewModel(
      repo: _services.vendors,
      companyId: _companyId,
      id: widget.id,
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
    return EntityDetailScaffold<Vendor>(
      vm: _vm,
      emptyIcon: Icons.store_outlined,
      emptyTitle: context.tr('vendor_not_found'),
      emptySubtitle: context.tr('vendor_not_found_subtitle'),
      actionsForItem: (context, v) => VendorDetailActionsRow(
        vendor: v,
        services: _services,
        companyId: _companyId,
      ),
      bodyBuilder: (context, v) {
        final docCount = v.documents.length;
        final docsLabel = docCount > 0
            ? context.tr('documents_with_count', {'count': '$docCount'})
            : context.tr('documents');
        return SingleChildScrollView(
          padding: EdgeInsets.all(InSpacing.lg(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VendorDetailHeader(vendor: v, formatter: formatter),
              const SizedBox(height: InSpacing.xl),
              EntityDetailTabs(
                tabs: [
                  EntityDetailTab(
                    label: context.tr('overview'),
                    icon: Icons.dashboard_outlined,
                    bodyBuilder: (_) => Padding(
                      padding: EdgeInsets.all(InSpacing.lg(context)),
                      child: VendorDetailCards(
                        vendor: v,
                        companyId: _companyId,
                        formatter: formatter,
                      ),
                    ),
                  ),
                  EntityDetailTab(
                    label: docsLabel,
                    icon: Icons.description_outlined,
                    bodyBuilder: (_) => EntityDocumentsTab(
                      entityId: v.id,
                      documents: v.documents,
                      formatter: formatter,
                      onUpload: (paths) async {
                        for (final path in paths) {
                          await _services.vendors.uploadDocument(
                            companyId: _companyId,
                            vendorId: v.id,
                            localPath: path,
                          );
                        }
                      },
                      onDelete: (doc) async {
                        await _services.vendors.deleteDocument(
                          companyId: _companyId,
                          vendorId: v.id,
                          documentId: doc.id,
                        );
                      },
                      onToggleVisibility: (doc) async {
                        await _services.vendors.setDocumentVisibility(
                          companyId: _companyId,
                          vendorId: v.id,
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
