import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/services/upload_source.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/file_drop_zone.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/utils/document_upload_validation.dart';
import 'package:admin/utils/formatting.dart';

/// Searchable label keys rendered by this tab. See
/// `kCompanyDetailsDetailsSearchKeys` for the colocation pattern.
const kCompanyDetailsDocumentsSearchKeys = <String>['documents'];

/// "Documents" tab — list of file attachments on the company, plus a shared
/// drop-or-click upload affordance. Documents arrive on the company envelope
/// and are persisted in the `companies.documents` JSON column; the tab watches
/// the company stream so the list rebuilds when an upload's server response
/// lands.
class CompanyDetailsDocumentsScreen extends StatelessWidget {
  const CompanyDetailsDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final services = context.read<Services>();
    final tokens = context.inTheme;
    final documents = vm.draft?.documents ?? const <Document>[];

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('documents'),
          children: [
            FileDropZone(
              allowedExtensions: kDocumentAllowedExtensions,
              allowMultiple: true,
              onFiles: (sources) =>
                  _validateAndUpload(context, services, vm, sources),
            ),
            if (documents.isNotEmpty) ...[
              SizedBox(height: InSpacing.lg(context)),
              _DocumentList(
                documents: documents,
                tokens: tokens,
                // Delete is password-gated server-side; the sync engine prompts
                // via ConfirmPasswordSheet when the row drains (no pre-confirm
                // dialog — typing the password is the confirmation, mirroring
                // EntityDocumentsTab). The row drops once the delete confirms.
                onDelete: (doc) => services.company.deleteDocument(
                  companyId: vm.companyId,
                  documentId: doc.id,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Validate each picked / dropped file against the shared allowlist + size
  /// cap, then upload the good ones. Identical reject toasts regardless of how
  /// the file arrived — mirrors `EntityDocumentsTab._validateAndUpload`.
  Future<void> _validateAndUpload(
    BuildContext context,
    Services services,
    CompanyDetailsViewModel vm,
    List<UploadSource> sources,
  ) async {
    if (sources.isEmpty) return;
    final good = <UploadSource>[];
    var sawWrongType = false;
    var sawTooLarge = false;
    for (final s in sources) {
      final result = await validateDocumentUpload(s);
      if (result.isOk) {
        good.add(s);
      } else {
        switch (result.issue) {
          case DocumentUploadIssue.wrongExtension:
            sawWrongType = true;
          case DocumentUploadIssue.tooLarge:
            sawTooLarge = true;
          case DocumentUploadIssue.unreadable:
            sawWrongType = true;
          case null:
            break;
        }
      }
    }
    if (!context.mounted) return;
    if (sawWrongType) {
      Notify.warning(context, context.tr('dropzone_invalid_file_type'));
    }
    if (sawTooLarge) {
      Notify.warning(
        context,
        context.tr('upload_too_large_with_size', {'size': '$kDocumentMaxMb'}),
      );
    }
    if (good.isEmpty) return;
    try {
      for (final s in good) {
        await services.company.uploadDocument(
          companyId: vm.companyId,
          source: s,
        );
      }
      if (!context.mounted) return;
      Notify.success(context, context.tr('uploaded_document'));
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, context.tr('error_uploading_document'), error: e);
    }
  }
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.documents,
    required this.tokens,
    required this.onDelete,
  });

  final List<Document> documents;
  final InTheme tokens;
  final Future<void> Function(Document doc) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < documents.length; i++) ...[
          if (i > 0) const SizedBox(height: InSpacing.sm),
          _DocumentRow(doc: documents[i], tokens: tokens, onDelete: onDelete),
        ],
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.doc,
    required this.tokens,
    required this.onDelete,
  });

  final Document doc;
  final InTheme tokens;
  final Future<void> Function(Document doc) onDelete;

  static const _imageExts = <String>{
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'heic',
    'svg',
    'bmp',
  };

  @override
  Widget build(BuildContext context) {
    final ext = doc.type.toLowerCase();
    final icon = _imageExts.contains(ext)
        ? Icons.image_outlined
        : Icons.description_outlined;
    final displayName = doc.name.isNotEmpty ? doc.name : doc.hash;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: InSpacing.lg(context),
        vertical: InSpacing.md(context),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tokens.ink2),
          SizedBox(width: InSpacing.md(context)),
          Expanded(
            child: Text(
              displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.ink),
            ),
          ),
          if (doc.size > 0) ...[
            SizedBox(width: InSpacing.md(context)),
            Text(formatSize(doc.size), style: TextStyle(color: tokens.ink3)),
          ],
          const SizedBox(width: InSpacing.sm),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: context.tr('delete'),
            visualDensity: VisualDensity.compact,
            color: tokens.ink3,
            onPressed: () => onDelete(doc),
          ),
        ],
      ),
    );
  }
}
