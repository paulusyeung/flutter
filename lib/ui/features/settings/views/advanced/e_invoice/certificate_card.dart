import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

/// Settings → E-Invoice — Certificate card. Company-scope only (caller
/// gates with `scope.isCompany`).
///
/// Two pieces of state share the section:
///   * **Certificate file** — uploaded via [FilePicker], saved through a
///     dedicated outbox row (`MutationKind.uploadEInvoiceCertificate`).
///     Server flips `has_e_invoice_certificate` and the watch stream
///     pushes the new flag back. "Remove" clears the flag locally;
///     the next company PUT round-trips the cleared state.
///   * **Passphrase** — plain top-level company field
///     (`e_invoice_certificate_passphrase`). Edited locally, saved with
///     the page's main Save button. The server-set `has_*_passphrase`
///     flag drives the status indicator.
class CertificateCard extends StatelessWidget {
  const CertificateCard({super.key});

  /// Allowlist of certificate extensions the server accepts. Mirrors
  /// admin-portal `e_invoice_settings.dart:370-378` and React
  /// `EInvoice.tsx`. Hard-filtered through `FilePicker`; re-checked after
  /// pick to guard against pickers that ignore the filter.
  static const _kCertExts = <String>[
    'p12',
    'pfx',
    'pem',
    'cer',
    'crt',
    'der',
    'txt',
    'p7b',
    'spc',
    'bin',
  ];

  /// 5 MB. Certificates are tiny — a generous cap that catches user error
  /// (wrong file picked) without rejecting any legitimate format.
  static const _kMaxCertBytes = 5 * 1024 * 1024;

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final company = host.draft;
    if (company == null) return const SizedBox.shrink();

    return FormSection(
      title: context.tr('upload_certificate'),
      children: [
        _CertificateRow(
          isSet: company.hasEInvoiceCertificate,
          onUpload: () => _pickAndUpload(context),
          onRemove: () => host.updateCompany(
            (c) => c.copyWith(hasEInvoiceCertificate: false),
          ),
        ),
        _PassphraseRow(
          host: host,
          isSet: company.hasEInvoiceCertificatePassphrase,
        ),
      ],
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final services = context.read<Services>();
    final host = context.read<SettingsDraftHost>();
    final companyId = host.draft?.id;
    if (companyId == null) return;

    final successText = context.tr('uploaded_document');
    final invalidTypeText = context.tr('dropzone_invalid_file_type');
    final tooLargeText = context.tr('upload_too_large_with_size', {
      'size': '${_kMaxCertBytes ~/ (1024 * 1024)}',
    });
    final uploadFailedTitle = context.tr('error_uploading_document');

    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _kCertExts,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final path = file.path;
      if (path == null) return;
      final ext = path.substring(path.lastIndexOf('.') + 1).toLowerCase();
      if (!context.mounted) return;
      if (!_kCertExts.contains(ext)) {
        Notify.warning(context, invalidTypeText);
        return;
      }
      final size = file.size > 0 ? file.size : await File(path).length();
      if (!context.mounted) return;
      if (size > _kMaxCertBytes) {
        Notify.warning(context, tooLargeText);
        return;
      }
      await services.company.enqueueEInvoiceCertificateUpload(
        companyId: companyId,
        localPath: path,
      );
      if (!context.mounted) return;
      Notify.success(context, successText);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, uploadFailedTitle, error: e);
    }
  }
}

class _CertificateRow extends StatelessWidget {
  const _CertificateRow({
    required this.isSet,
    required this.onUpload,
    required this.onRemove,
  });

  final bool isSet;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isSet ? Icons.check_circle : Icons.cancel_outlined,
          color: isSet ? tokens.paid : tokens.ink3,
        ),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          child: Text(
            context.tr(isSet ? 'certificate_set' : 'certificate_not_set'),
            style: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink),
          ),
        ),
        OutlinedButton.icon(
          // Keep `.icon` for both states so the button width stays stable
          // when the user toggles set / not-set — different shapes would
          // shift the surrounding layout.
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          icon: Icon(isSet ? Icons.delete_outline : Icons.upload),
          label: Text(context.tr(isSet ? 'remove' : 'upload_certificate')),
          onPressed: isSet ? onRemove : onUpload,
        ),
      ],
    );
  }
}

class _PassphraseRow extends StatefulWidget {
  const _PassphraseRow({required this.host, required this.isSet});

  final SettingsDraftHost host;
  final bool isSet;

  @override
  State<_PassphraseRow> createState() => _PassphraseRowState();
}

class _PassphraseRowState extends State<_PassphraseRow> {
  late final TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.host.draft?.eInvoiceCertificatePassphrase ?? '',
    );
  }

  @override
  void didUpdateWidget(_PassphraseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hostValue = widget.host.draft?.eInvoiceCertificatePassphrase ?? '';
    if (_controller.text != hostValue) {
      _controller.value = TextEditingValue(
        text: hostValue,
        selection: TextSelection.collapsed(offset: hostValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final scope = FormSaveScope.maybeOf(context);
    final fieldErrors =
        widget.host.fieldErrors['e_invoice_certificate_passphrase'];
    final errorText = (fieldErrors != null && fieldErrors.isNotEmpty)
        ? fieldErrors.first
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          widget.isSet ? Icons.check_circle : Icons.cancel_outlined,
          color: widget.isSet ? tokens.paid : tokens.ink3,
        ),
        SizedBox(width: InSpacing.md(context)),
        Expanded(
          child: TextField(
            controller: _controller,
            obscureText: _obscured,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: context.tr('certificate_passphrase'),
              helperText: context.tr(
                widget.isSet ? 'passphrase_set' : 'passphrase_not_set',
              ),
              errorText: errorText,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            ),
            onChanged: (v) => widget.host.updateCompany(
              (c) => c.copyWith(eInvoiceCertificatePassphrase: v),
            ),
            onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
          ),
        ),
      ],
    );
  }
}
