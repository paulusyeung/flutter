import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/services/upload_source.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/file_drop_zone.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/views/basic/company_details/logo_crop_screen.dart';
import 'package:admin/ui/features/settings/view_models/company_details_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';
import 'package:admin/utils/url_safety.dart';

/// Searchable label keys rendered by this tab. See
/// `kCompanyDetailsDetailsSearchKeys` for the colocation pattern.
const kCompanyDetailsLogoSearchKeys = <String>['logo'];

/// "Logo" tab — shows the current logo (if any), lets the user drop a file or
/// click to replace it, or remove it. Uploads go through the outbox
/// (`upload_logo` action) so they survive offline.
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
    // Flutter's image cache (the server reuses the same URL across uploads).
    final displayUrl = isSafeHttpsUrl(logoUrl)
        ? '$logoUrl${logoUrl!.contains('?') ? '&' : '?'}v=${vm.draft?.updatedAt ?? 0}'
        : null;
    final tokens = context.inTheme;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return SettingsFormShell(
      sections: [
        FormSection(
          title: context.tr('logo'),
          children: [
            FileDropZone(
              allowedExtensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp'],
              idleLabelKey: 'drop_your_logo_here',
              preview: displayUrl != null
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 140),
                      child: Image.network(
                        displayUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: tokens.ink3,
                        ),
                      ),
                    )
                  : null,
              onFiles: (sources) => _processLogo(context, services, vm, sources),
            ),
            if (hasLogo) ...[
              SizedBox(height: InSpacing.md(context)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.tr('remove')),
                  onPressed: () =>
                      vm.updateSettings((s) => s.copyWith(companyLogo: '')),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Defence in depth: the picker filters to images at the OS level, but a
  /// re-check on the Dart side bounds file size and rejects formats the
  /// server can't render (e.g. HEIC on some pickers).
  static const _kMaxLogoBytes = 5 * 1024 * 1024;
  static const _kLogoExts = {'.png', '.jpg', '.jpeg', '.gif', '.webp'};

  /// Shared validate → crop → upload tail for both the dropped and the
  /// click-picked file (a logo is single-image, so we take the first source).
  Future<void> _processLogo(
    BuildContext context,
    Services services,
    CompanyDetailsViewModel vm,
    List<UploadSource> sources,
  ) async {
    if (sources.isEmpty) return;
    final source = sources.first;
    final successText = context.tr('uploaded_logo');
    final invalidTypeText = context.tr('dropzone_invalid_file_type');
    final tooLargeText = context.tr('upload_too_large_with_size', {
      'size': '${_kMaxLogoBytes ~/ (1024 * 1024)}',
    });
    final uploadFailedTitle = context.tr('error_uploading_logo');
    try {
      final ext = p.extension(source.fileName).toLowerCase();
      if (!_kLogoExts.contains(ext)) {
        Notify.warning(context, invalidTypeText);
        return;
      }
      final size = await source.length();
      if (!context.mounted) return;
      if (size > _kMaxLogoBytes) {
        Notify.warning(context, tooLargeText);
        return;
      }
      final sourceBytes = await source.readRange(0, size);
      if (!context.mounted) return;
      // Crop step (React parity: logo is cropped before upload).
      final cropped = await showLogoCropScreen(context, sourceBytes);
      if (cropped == null || !context.mounted) return;
      // Re-validate the CROPPED output: `crop_your_image` re-encodes the crop
      // region as PNG (no downscale), which can exceed the limit even when the
      // source passed.
      if (cropped.lengthInBytes > _kMaxLogoBytes) {
        Notify.warning(context, tooLargeText);
        return;
      }
      // The cropped logo is already fully in memory, so carry the bytes
      // straight to the outbox (base64 in the mutation payload) on every
      // platform.
      await services.company.uploadLogo(
        companyId: vm.companyId,
        source: BytesUploadSource(cropped, 'logo.png'),
      );
      if (!context.mounted) return;
      Notify.success(context, successText);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, uploadFailedTitle, error: e);
    }
  }
}
