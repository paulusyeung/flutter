import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company.dart';
import 'package:admin/data/repositories/auth/auth_session.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/features/settings/settings_actions.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

const String _kWhiteLabelUrl =
    'https://invoiceninja.com/self-host-white-label/';

/// Account Management → Overview. Five cards:
///   1. Plan info (plan name, trial countdown OR expiry, hosted client cap).
///   2. Account info (account ID, account email — copy-to-clipboard tiles).
///   3. Default company (Set as default button when not already default).
///   4. Company toggles (activate, PDF/email markdown, include drafts/deleted).
///   5. Data (Force Full Resync — pre-existing).
class AccountManagementOverviewScreen extends StatefulWidget {
  const AccountManagementOverviewScreen({super.key});

  @override
  State<AccountManagementOverviewScreen> createState() =>
      _AccountManagementOverviewScreenState();
}

class _AccountManagementOverviewScreenState
    extends State<AccountManagementOverviewScreen> {
  bool _resyncing = false;
  bool _settingDefault = false;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    final session = services.auth.session;
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: session,
      builder: (context, value, _) {
        if (value == null || value.currentCompanyId.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<Company?>(
          stream: services.company.watchCompany(value.currentCompanyId),
          builder: (context, snapshot) {
            final company = snapshot.data;
            if (company == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return SettingsFormShell(
              sections: [
                _PlanCard(session: value),
                if (!value.isHosted) const _SelfHostedLicenseCard(),
                _AccountInfoCard(session: value),
                if (value.defaultCompanyId != value.currentCompanyId)
                  _DefaultCompanySection(
                    busy: _settingDefault,
                    onPressed: _onSetDefaultCompany,
                  ),
                _CompanyTogglesCard(company: company),
                _DataCard(resyncing: _resyncing, onResync: _onForceResync),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onForceResync() async {
    setState(() => _resyncing = true);
    await SettingsActions.forceResync(context);
    if (mounted) setState(() => _resyncing = false);
  }

  Future<void> _onSetDefaultCompany() async {
    final services = context.read<Services>();
    final session = services.auth.session.value;
    final companyId = session?.currentCompanyId;
    if (companyId == null || companyId.isEmpty) return;
    setState(() => _settingDefault = true);
    try {
      await services.auth.setDefaultCompany(companyId);
      if (!mounted) return;
      Notify.success(context, context.tr('saved_settings'));
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, context.tr('error_refresh_page'), error: e);
    } finally {
      if (mounted) setState(() => _settingDefault = false);
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final planLabel = _planLabel(context, session);
    final secondary = _secondaryLine(context, session);

    return FormSection(
      title: context.tr('plan'),
      spacing: 0,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                  if (secondary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.ink2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (session.isTrial) ...[
          SizedBox(height: InSpacing.md(context)),
          _TrialProgress(session: session),
        ],
      ],
    );
  }

  String _planLabel(BuildContext context, AuthSession s) {
    final base = s.plan.isEmpty
        ? context.tr('free')
        : context.tr(s.plan); // matches `pro`, `enterprise`, etc.
    if (s.isTrial) return '$base • ${context.tr('free_trial')}';
    return base;
  }

  String _secondaryLine(BuildContext context, AuthSession s) {
    if (!s.isHosted) return '';
    if (s.isTrial || s.plan.isEmpty) {
      // On free / trial, show client cap if known.
      if (s.hostedClientCount > 0) {
        return '${context.tr('clients')}: 0 / ${s.hostedClientCount}';
      }
      return '';
    }
    if (s.planExpires.isNotEmpty) {
      // Treat as ISO-date or "yyyy-MM-dd" prefix. Strip time-of-day for clean
      // display; downstream Formatter could fully localize, but the
      // formatter requires a per-company snapshot and this is a read-only
      // label.
      final display = s.planExpires.split(' ').first;
      return '${context.tr('expires_on')} $display';
    }
    return '';
  }
}

class _TrialProgress extends StatelessWidget {
  const _TrialProgress({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final total = session.numTrialDays <= 0 ? 1 : session.numTrialDays;
    final remaining = session.trialDaysRemaining;
    final progress = ((total - remaining) / total).clamp(0.0, 1.0);
    final label = context
        .tr('days_left')
        .replaceAll(':days', remaining.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(InRadii.r1),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: tokens.border,
          ),
        ),
        SizedBox(height: InSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.ink2),
        ),
      ],
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('details'),
      spacing: 0,
      children: [
        _CopyableTile(
          icon: Icons.fingerprint,
          label: context.tr('account_id'),
          value: session.accountId,
        ),
        Divider(color: context.inTheme.border, height: 1),
        _CopyableTile(
          icon: Icons.email_outlined,
          label: context.tr('email'),
          value: session.userEmail,
        ),
      ],
    );
  }
}

class _CopyableTile extends StatelessWidget {
  const _CopyableTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.inTheme;
    final disabled = value.isEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: disabled ? tokens.ink3 : tokens.ink2),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: disabled ? tokens.ink3 : tokens.ink,
        ),
      ),
      trailing: disabled
          ? null
          : Icon(Icons.content_copy, size: 18, color: tokens.ink3),
      onTap: disabled
          ? null
          : () async {
              final msg = context
                  .tr('copied_to_clipboard')
                  .replaceAll(':value', value);
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              Notify.success(context, msg);
            },
    );
  }
}

class _DefaultCompanySection extends StatelessWidget {
  const _DefaultCompanySection({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('set_default_company'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
            onPressed: busy ? null : onPressed,
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('set_default_company')),
          ),
        ),
      ],
    );
  }
}

class _CompanyTogglesCard extends StatelessWidget {
  const _CompanyTogglesCard({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('company'),
      spacing: 0,
      children: [
        _ToggleRow(
          titleKey: 'activate_company',
          subtitleKey: 'activate_company_help',
          value: !company.isDisabled,
          onChanged: (v) => _save(context, company.copyWith(isDisabled: !v)),
        ),
        _ToggleRow(
          titleKey: 'enable_pdf_markdown',
          subtitleKey: 'enable_markdown_help',
          value: company.markdownEnabled,
          onChanged: (v) =>
              _save(context, company.copyWith(markdownEnabled: v)),
        ),
        _ToggleRow(
          titleKey: 'enable_email_markdown',
          subtitleKey: 'enable_email_markdown_help',
          value: company.markdownEmailEnabled,
          onChanged: (v) =>
              _save(context, company.copyWith(markdownEmailEnabled: v)),
        ),
        _ToggleRow(
          titleKey: 'include_drafts',
          subtitleKey: 'include_drafts_help',
          value: company.reportIncludeDrafts,
          onChanged: (v) =>
              _save(context, company.copyWith(reportIncludeDrafts: v)),
        ),
        _ToggleRow(
          titleKey: 'include_deleted',
          subtitleKey: 'include_deleted_help',
          value: company.reportIncludeDeleted,
          onChanged: (v) =>
              _save(context, company.copyWith(reportIncludeDeleted: v)),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, Company draft) async {
    try {
      await context.read<Services>().company.updateCompany(draft: draft);
    } catch (e) {
      if (!context.mounted) return;
      Notify.error(context, context.tr('error_refresh_page'), error: e);
    }
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.titleKey,
    required this.subtitleKey,
    required this.value,
    required this.onChanged,
  });

  final String titleKey;
  final String subtitleKey;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(context.tr(titleKey)),
      subtitle: Text(context.tr(subtitleKey)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SelfHostedLicenseCard extends StatefulWidget {
  const _SelfHostedLicenseCard();

  @override
  State<_SelfHostedLicenseCard> createState() => _SelfHostedLicenseCardState();
}

class _SelfHostedLicenseCardState extends State<_SelfHostedLicenseCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return FormSection(
      title: context.tr('license'),
      children: [
        Wrap(
          spacing: InSpacing.md(context),
          runSpacing: InSpacing.sm,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('purchase_license')),
                  SizedBox(width: InSpacing.sm),
                  Icon(Icons.open_in_new, size: 16, color: tokens.ink3),
                ],
              ),
              onPressed: _busy ? null : () => _purchase(context),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
              onPressed: _busy ? null : () => _onApply(context),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('apply_license')),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _purchase(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final errorMsg =
        Localization.of(context)?.lookup('failed_to_open_url') ??
        'failed_to_open_url';
    final uri = Uri.parse(_kWhiteLabelUrl);
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
    } catch (_) {
      /* fall through */
    }
    if (messenger == null) return;
    // ignore: use_build_context_synchronously
    Notify.error(messenger.context, errorMsg, messenger: messenger);
  }

  Future<void> _onApply(BuildContext context) async {
    final licenseKey = await _promptLicenseKey(context);
    if (licenseKey == null || licenseKey.isEmpty) return;
    if (!context.mounted) return;
    final services = context.read<Services>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final successMsg = context.tr('bought_white_label');
    final errorMsg = context.tr('error_refresh_page');
    setState(() => _busy = true);
    try {
      await services.auth.applyLicense(licenseKey);
      if (!mounted) return;
      // The messenger is captured pre-await and Notify uses it directly;
      // the context arg is only consulted as a fallback.
      // ignore: use_build_context_synchronously
      Notify.success(context, successMsg, messenger: messenger);
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Notify.error(context, errorMsg, error: e, messenger: messenger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Inline single-field input dialog. Returns the trimmed entered value, or
/// null when the user cancels. Kept private to this screen — if a third
/// place ever needs it, lift to `lib/ui/core/widgets/`.
Future<String?> _promptLicenseKey(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      void submit() {
        final v = controller.text.trim();
        if (v.isEmpty) return;
        Navigator.of(ctx).pop(v);
      }

      return AlertDialog(
        title: Text(ctx.tr('apply_license')),
        content: SizedBox(
          width: 360,
          child: FormSaveScope(
            enabled: true,
            onSubmit: submit,
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: ctx.tr('license'),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: submit,
            child: Text(ctx.tr('submit')),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.resyncing, required this.onResync});

  final bool resyncing;
  final VoidCallback onResync;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: context.tr('data'),
      spacing: 0,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.refresh),
          title: Text(context.tr('force_full_resync')),
          subtitle: Text(context.tr('force_resync_description')),
          trailing: resyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: resyncing ? null : onResync,
        ),
      ],
    );
  }
}
