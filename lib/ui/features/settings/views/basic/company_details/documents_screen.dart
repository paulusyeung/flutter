import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// "Documents" tab — list of file attachments on the company, plus an
/// "Upload" affordance. Document listing arrives on the company envelope
/// (server-side), but until we wire a documents table to Drift the list is
/// rendered from whatever the latest /auth/me payload returned. Upload
/// itself is fully implemented via the outbox.
class CompanyDetailsDocumentsScreen extends StatelessWidget {
  const CompanyDetailsDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final services = context.read<Services>();
    final tokens = context.inTheme;

    return SettingsFormShell(
      child: FormSection(
        title: context.tr('documents'),
        trailing: FilledButton.icon(
          icon: const Icon(Icons.upload),
          label: Text(context.tr('upload')),
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => _pickAndUpload(context, services, vm),
        ),
        children: [
          Container(
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
                Icon(
                  Icons.upload_file_outlined,
                  size: 36,
                  color: tokens.ink3,
                ),
                const SizedBox(height: InSpacing.sm),
                Text(
                  context.tr('no_documents_found'),
                  style: TextStyle(color: tokens.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Allowlist of extensions the server accepts as documents (mirrors what
  /// admin-portal allows). Sent to the picker as a hard filter and re-checked
  /// after pick to guard against pickers that ignore the filter on some
  /// platforms.
  static const _kDocExts = <String>[
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'csv', 'rtf', 'odt', 'ods', 'odp',
    'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'svg',
  ];
  static const _kMaxDocBytes = 25 * 1024 * 1024;

  Future<void> _pickAndUpload(
    BuildContext context,
    Services services,
    CompanyDetailsViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.tr('uploaded_document');
    final invalidTypeText = context.tr('dropzone_invalid_file_type');
    final tooLargeText = context.tr('upload_too_large_with_size', {
      'size': '${_kMaxDocBytes ~/ (1024 * 1024)}',
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _kDocExts,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final path = file.path;
      if (path == null) return;
      final ext = path
          .substring(path.lastIndexOf('.') + 1)
          .toLowerCase();
      if (!_kDocExts.contains(ext)) {
        messenger.showSnackBar(SnackBar(content: Text(invalidTypeText)));
        return;
      }
      final size = file.size > 0 ? file.size : await File(path).length();
      if (size > _kMaxDocBytes) {
        messenger.showSnackBar(SnackBar(content: Text(tooLargeText)));
        return;
      }
      await services.company.uploadDocument(
        companyId: vm.companyId,
        localPath: path,
      );
      messenger.showSnackBar(SnackBar(content: Text(successText)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
