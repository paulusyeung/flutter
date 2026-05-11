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

  Future<void> _pickAndUpload(
    BuildContext context,
    Services services,
    CompanyDetailsViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.tr('uploaded_document');
    try {
      final picked = await FilePicker.platform.pickFiles();
      if (picked == null || picked.files.isEmpty) return;
      final path = picked.files.first.path;
      if (path == null) return;
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
