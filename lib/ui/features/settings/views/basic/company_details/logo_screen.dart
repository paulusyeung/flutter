import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/utils/url_safety.dart';

/// Searchable label keys rendered by this tab. See
/// `kCompanyDetailsDetailsSearchKeys` for the colocation pattern.
const kCompanyDetailsLogoSearchKeys = <String>['logo'];

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
    // Reject non-https / malformed URLs server-side could otherwise set — we
    // don't want a hostile server tracking renders or downgrading to plain
    // http. Cache-bust on `updatedAt` so replacing the logo invalidates
    // Flutter's image cache (the server keeps the same URL across uploads).
    final displayUrl = isSafeHttpsUrl(logoUrl)
        ? '$logoUrl${logoUrl!.contains('?') ? '&' : '?'}v=${vm.draft?.updatedAt ?? 0}'
        : null;
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
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  icon: const Icon(Icons.upload),
                  label: Text(context.tr('upload_logo_short')),
                  onPressed: () => _pickAndUpload(context, services, vm),
                ),
                if (logoUrl != null && logoUrl.isNotEmpty) ...[
                  const SizedBox(width: InSpacing.md),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 40),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(context.tr('remove')),
                    onPressed: () =>
                        vm.updateSettings((s) => s.copyWith(companyLogo: '')),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Defence in depth: ImagePicker filters to images at the OS level, but a
  /// re-check on the Dart side bounds file size and rejects formats the
  /// server can't render (e.g. HEIC on some iOS pickers).
  static const _kMaxLogoBytes = 5 * 1024 * 1024;
  static const _kLogoExts = {'.png', '.jpg', '.jpeg', '.gif', '.webp'};

  Future<void> _pickAndUpload(
    BuildContext context,
    Services services,
    CompanyDetailsViewModel vm,
  ) async {
    final successText = context.tr('uploaded_logo');
    final invalidTypeText = context.tr('dropzone_invalid_file_type');
    final tooLargeText = context.tr('upload_too_large_with_size', {
      'size': '${_kMaxLogoBytes ~/ (1024 * 1024)}',
    });
    final uploadFailedTitle = context.tr('error_uploading_logo');
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final ext = p.extension(picked.path).toLowerCase();
      if (!context.mounted) return;
      if (!_kLogoExts.contains(ext)) {
        Notify.warning(context, invalidTypeText);
        return;
      }
      final size = await File(picked.path).length();
      if (!context.mounted) return;
      if (size > _kMaxLogoBytes) {
        Notify.warning(context, tooLargeText);
        return;
      }
      await services.company.uploadLogo(
        companyId: vm.companyId,
        localPath: picked.path,
      );
      if (!context.mounted) return;
      Notify.success(context, successText);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, uploadFailedTitle, error: e);
    }
  }
}
