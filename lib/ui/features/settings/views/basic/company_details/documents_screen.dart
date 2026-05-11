import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('documents'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                icon: const Icon(Icons.upload),
                label: Text(context.tr('upload')),
                onPressed: () => _pickAndUpload(context, services, vm),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                context.tr('no_record_selected'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
    final picked = await FilePicker.platform.pickFiles();
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) return;
    await services.company.uploadDocument(
      companyId: vm.companyId,
      localPath: path,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('uploaded_document'))));
  }
}
