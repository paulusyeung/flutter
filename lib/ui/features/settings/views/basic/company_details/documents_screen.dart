import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/services/upload_source.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/utils/formatting.dart';

/// Searchable label keys rendered by this tab. See
/// `kCompanyDetailsDetailsSearchKeys` for the colocation pattern.
const kCompanyDetailsDocumentsSearchKeys = <String>['documents'];

/// "Documents" tab — list of file attachments on the company, plus an
/// "Upload" affordance. Documents arrive on the company envelope and are
/// persisted in the `companies.documents` JSON column; the tab watches the
/// company stream so the list rebuilds when an upload's server response
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
          trailing: FilledButton.icon(
            icon: const Icon(Icons.upload),
            label: Text(context.tr('upload')),
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => _pickAndUpload(context, services, vm),
          ),
          children: [
            if (documents.isEmpty)
              _EmptyState(tokens: tokens)
            else
              _DocumentList(documents: documents, tokens: tokens),
          ],
        ),
      ],
    );
  }

  /// Allowlist of extensions the server accepts as documents (mirrors what
  /// admin-portal allows). Sent to the picker as a hard filter and re-checked
  /// after pick to guard against pickers that ignore the filter on some
  /// platforms.
  static const _kDocExts = <String>[
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'rtf',
    'odt',
    'ods',
    'odp',
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'heic',
    'svg',
  ];
  static const _kMaxDocBytes = 25 * 1024 * 1024;

  Future<void> _pickAndUpload(
    BuildContext context,
    Services services,
    CompanyDetailsViewModel vm,
  ) async {
    final successText = context.tr('uploaded_document');
    final invalidTypeText = context.tr('dropzone_invalid_file_type');
    final tooLargeText = context.tr('upload_too_large_with_size', {
      'size': '${_kMaxDocBytes ~/ (1024 * 1024)}',
    });
    final uploadFailedTitle = context.tr('error_uploading_document');
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _kDocExts,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final path = file.path;
      final name = file.name;
      final ext = name.substring(name.lastIndexOf('.') + 1).toLowerCase();
      if (!context.mounted) return;
      if (!_kDocExts.contains(ext)) {
        Notify.warning(context, invalidTypeText);
        return;
      }
      if (file.size > _kMaxDocBytes) {
        Notify.warning(context, tooLargeText);
        return;
      }
      final UploadSource source;
      if (!kIsWeb && path != null) {
        source = fileUploadSource(path);
      } else if (file.bytes != null) {
        source = BytesUploadSource(file.bytes!, name);
      } else {
        return;
      }
      await services.company.uploadDocument(
        companyId: vm.companyId,
        source: source,
      );
      if (!context.mounted) return;
      Notify.success(context, successText);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, uploadFailedTitle, error: e);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});

  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InSpacing.xl,
        vertical: InSpacing.xxl,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
      child: Column(
        children: [
          Icon(Icons.upload_file_outlined, size: 36, color: tokens.ink3),
          const SizedBox(height: InSpacing.sm),
          Text(
            context.tr('no_documents_found'),
            style: TextStyle(color: tokens.ink3),
          ),
        ],
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({required this.documents, required this.tokens});

  final List<Document> documents;
  final InTheme tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < documents.length; i++) ...[
          if (i > 0) const SizedBox(height: InSpacing.sm),
          _DocumentRow(doc: documents[i], tokens: tokens),
        ],
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.doc, required this.tokens});

  final Document doc;
  final InTheme tokens;

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
        ],
      ),
    );
  }
}
