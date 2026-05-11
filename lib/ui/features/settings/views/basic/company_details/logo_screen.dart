import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

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
    final tokens = context.inTheme;

    return SettingsFormShell(
      child: FormSection(
        title: context.tr('logo'),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Match the React reference's 16:10 preview while clamping to
              // the form's available width on narrow viewports.
              final width = min<double>(360, constraints.maxWidth);
              final height = width * 0.6;
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.border),
                  borderRadius: BorderRadius.circular(InRadii.r2),
                ),
                alignment: Alignment.center,
                child: displayUrl != null
                    ? Image.network(
                        displayUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: tokens.ink3,
                        ),
                      )
                    : Text(
                        context.tr('no_logo_uploaded'),
                        style: TextStyle(color: tokens.ink3),
                      ),
              );
            },
          ),
          const SizedBox(height: InSpacing.lg),
          Wrap(
            spacing: InSpacing.md,
            runSpacing: InSpacing.sm,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.upload),
                label: Text(context.tr('upload_logo_short')),
                onPressed: () => _pickAndUpload(context, services, vm),
              ),
              if (logoUrl != null && logoUrl.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.tr('remove')),
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
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.tr('uploaded_logo');
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      await services.company.uploadLogo(
        companyId: vm.companyId,
        localPath: picked.path,
      );
      messenger.showSnackBar(SnackBar(content: Text(successText)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
