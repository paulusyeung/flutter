import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';

/// "Logo" tab — shows the current logo (if any), lets the user replace or
/// remove it. Uploads go through the outbox (`upload_logo` action) so they
/// survive offline.
class CompanyDetailsLogoScreen extends StatelessWidget {
  const CompanyDetailsLogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CompanyDetailsViewModel>();
    final services = context.read<Services>();
    final logoUrl = vm.settings.companyLogo;
    // Cache-bust on `updatedAt` so replacing the logo invalidates Flutter's
    // image cache — the server keeps the same URL across uploads.
    final displayUrl = (logoUrl == null || logoUrl.isEmpty)
        ? null
        : '$logoUrl${logoUrl.contains('?') ? '&' : '?'}v=${vm.draft?.updatedAt ?? 0}';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('logo'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: 320,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: displayUrl != null
                ? Image.network(displayUrl, fit: BoxFit.contain)
                : Text(
                    context.tr('no_record_selected'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.upload),
                label: Text(context.tr('upload')),
                onPressed: () => _pickAndUpload(context, services, vm),
              ),
              const SizedBox(width: 12),
              if (logoUrl != null && logoUrl.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.tr('remove_logo')),
                  onPressed: () =>
                      vm.updateSettings((s) => s.copyWith(companyLogo: '')),
                ),
            ],
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await services.company.uploadLogo(
      companyId: vm.companyId,
      localPath: picked.path,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('uploaded_logo'))));
  }
}
