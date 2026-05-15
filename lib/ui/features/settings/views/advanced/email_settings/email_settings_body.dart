import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/env.dart';
import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/email_settings/widgets/oauth_user_picker.dart';
import 'package:admin/ui/features/settings/views/advanced/email_settings/widgets/smtp_mail_driver_card.dart';
import 'package:admin/ui/features/settings/view_models/email_settings_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_markdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Brand colors for the provider dropdown's leading dot. Not theme-aware —
/// vendor-owned brand marks should not shift between light and dark mode.
/// Kept here (rather than on `InTheme`) so the design-token surface stays
/// limited to theme-responsive colors.
const _kBrandDotColors = <String, Color>{
  'postmark': Color(0xFFFFE067),
  'mailgun': Color(0xFFE32A6F),
  'ses': Color(0xFFFF9900),
  'gmail': Color(0xFFEA4335),
  'microsoft': Color(0xFF0078D4),
  'brevo': Color(0xFF0B996E),
  'smtp': Color(0xFF6B7280),
};

/// Field labels exposed by the in-app settings search for the Email Settings
/// page. Keep in sync with `kSettingsSearchCatalog['email_settings']` —
/// `search_catalog_consistency_test` asserts every entry is actually
/// rendered.
const kEmailSettingsSearchKeys = <String>[
  'email_provider',
  'gmail_user',
  'microsoft_user',
  'api_token',
  'api_key',
  'secret',
  'domain',
  'endpoint',
  'secret_key',
  'access_key',
  'region',
  'topic_arn',
  'from_address',
  'host',
  'port',
  'encryption',
  'username',
  'password',
  'local_domain',
  'verify_peer',
  'send_test_email',
  'from_email',
  'from_name',
  'reply_to_email',
  'reply_to_name',
  'bcc_email',
  'send_time',
  'email_design',
  'email_alignment',
  'email_style_custom',
  'email_signature',
  'show_email_footer',
  'attach_pdf',
  'attach_documents',
  'attach_ubl',
];

/// Body for Settings → Email Settings. Mounted by [EmailSettingsScreen]
/// inside [CascadeSettingsScaffold] — the scaffold owns the cascade VM and
/// provides it via Provider.
///
/// Layout:
///   * Section 1 — Email Provider: just the method dropdown.
///   * Section 2 — Provider Configuration: revealed conditionally based on
///     the active method (Gmail/Microsoft picker, Postmark/Brevo single key,
///     Mailgun trio, SES five fields, SMTP card via [SmtpMailDriverCard]).
///   * Section 3 — Identity & Delivery: from/reply/bcc/send-time, plus the
///     inline "Sync to existing entities" checkbox when send-time is dirty.
///   * Section 4 — Email Design: style + alignment + custom body + signature
///     + show footer toggle, with a live `$body` validation chip when the
///     style is `custom`.
///   * Section 5 — Attachments: three overridable switches.
class EmailSettingsBody extends StatelessWidget {
  const EmailSettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final scope = context.watch<SettingsLevelController>();
    final services = context.read<Services>();
    final session = services.auth.session.value;
    final isHosted = session?.isHosted ?? false;
    final isProOrEnterprise = session?.isProPlan ?? false;
    final isCompanyScope = scope.level == SettingsLevel.company;
    final method = host.settings.emailSendingMethod ?? 'default';

    return SettingsFormShell(
      sections: [
        // ── Section 1 — Email Provider ────────────────────────────────────
        FormSection(
          title: context.tr('email_provider'),
          children: [
            OverridableDropdownField<String>(
              label: context.tr('email_provider'),
              apiKey: 'email_sending_method',
              value: method,
              items: _providerOptions(
                context,
                isHosted: isHosted,
                isProOrEnterprise: isProOrEnterprise,
                isCompanyScope: isCompanyScope,
              ),
              onChanged: (v) => host.updateSettings(
                (s) => s.copyWith(emailSendingMethod: v),
              ),
            ),
          ],
        ),

        // ── Section 2 — Provider Configuration (conditional) ──────────────
        ..._providerConfigSections(
          context,
          method: method,
          isCompanyScope: isCompanyScope,
          isProOrEnterprise: isProOrEnterprise,
        ),

        // ── Section 3 — Identity & Delivery ───────────────────────────────
        FormSection(
          title: context.tr('details'),
          children: [
            if (_needsCustomSendingEmail(method))
              OverridableTextField(
                label: context.tr('from_email'),
                apiKey: 'custom_sending_email',
                keyboardType: TextInputType.emailAddress,
              ),
            OverridableTextField(
              label: context.tr('from_name'),
              apiKey: 'email_from_name',
            ),
            OverridableTextField(
              label: context.tr('reply_to_email'),
              apiKey: 'reply_to_email',
              keyboardType: TextInputType.emailAddress,
            ),
            OverridableTextField(
              label: context.tr('reply_to_name'),
              apiKey: 'reply_to_name',
            ),
            OverridableTextField(
              label: context.tr('bcc_email'),
              apiKey: 'bcc_email',
              keyboardType: TextInputType.emailAddress,
              helperText: context.tr('comma_sparated_list'),
            ),
            _SendTimeRow(host: host),
          ],
        ),

        // ── Section 4 — Email Design ──────────────────────────────────────
        FormSection(
          title: context.tr('email_design'),
          children: [
            OverridableDropdownField<String>(
              label: context.tr('email_style'),
              apiKey: 'email_style',
              value: host.settings.emailStyle ?? 'plain',
              items: [
                DropdownMenuItem(
                  value: 'plain',
                  child: Text(context.tr('plain')),
                ),
                DropdownMenuItem(
                  value: 'light',
                  child: Text(context.tr('light')),
                ),
                DropdownMenuItem(
                  value: 'dark',
                  child: Text(context.tr('dark')),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text(context.tr('custom')),
                ),
              ],
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(emailStyle: v)),
            ),
            OverridableDropdownField<String>(
              label: context.tr('email_alignment'),
              apiKey: 'email_alignment',
              // Pass through null — admin-portal default was "no selection"
              // until the user picked. Forcing 'center' here would silently
              // mutate the field on the first unrelated save.
              value: host.settings.emailAlignment,
              items: [
                DropdownMenuItem(
                  value: 'left',
                  child: Text(context.tr('left')),
                ),
                DropdownMenuItem(
                  value: 'center',
                  child: Text(context.tr('center')),
                ),
                DropdownMenuItem(
                  value: 'right',
                  child: Text(context.tr('right')),
                ),
              ],
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(emailAlignment: v)),
            ),
            if (host.settings.emailStyle == 'custom') ...[
              OverridableTextField(
                label: context.tr('custom'),
                apiKey: 'email_style_custom',
                maxLines: 6,
                hintText: context
                    .tr('add_body_variable_message')
                    .replaceAll(':body', r'$body'),
              ),
              _BodyVariableChip(value: host.settings.emailStyleCustom ?? ''),
            ],
            OverridableMarkdownField(
              label: context.tr('signature'),
              apiKey: 'email_signature',
            ),
            OverridableSwitchField(
              label: context.tr('show_email_footer'),
              apiKey: 'show_email_footer',
            ),
          ],
        ),

        // ── Section 5 — Attachments ───────────────────────────────────────
        FormSection(
          title: context.tr('attachments'),
          children: [
            OverridableSwitchField(
              label: context.tr('attach_pdf'),
              apiKey: 'pdf_email_attachment',
            ),
            OverridableSwitchField(
              label: context.tr('attach_documents'),
              apiKey: 'document_email_attachment',
            ),
            OverridableSwitchField(
              label: context.tr('attach_ubl'),
              apiKey: 'ubl_email_attachment',
            ),
          ],
        ),
      ],
    );
  }

  static bool _needsCustomSendingEmail(String method) =>
      method == 'client_mailgun' ||
      method == 'client_postmark' ||
      method == 'client_brevo' ||
      method == 'smtp';

  // ── Provider option helpers ────────────────────────────────────────────

  static List<DropdownMenuItem<String>> _providerOptions(
    BuildContext context, {
    required bool isHosted,
    required bool isProOrEnterprise,
    required bool isCompanyScope,
  }) {
    final items = <DropdownMenuItem<String>>[];
    if (isHosted) {
      items.add(_brandItem(context, value: 'default', label: 'Postmark (invoicing.co)', brandKey: 'postmark'));
      items.add(_brandItem(context, value: 'mailgun', label: 'Mailgun (invoicing.co)', brandKey: 'mailgun'));
      items.add(_brandItem(context, value: 'ses', label: 'Amazon SES (invoicing.co)', brandKey: 'ses'));
      items.add(_brandItem(context, value: 'gmail', label: 'Gmail', brandKey: 'gmail'));
    }
    items.add(_brandItem(context, value: 'office365', label: 'Microsoft', brandKey: 'microsoft'));
    items.add(_brandItem(context, value: 'client_postmark', label: 'Postmark', brandKey: 'postmark'));
    items.add(_brandItem(context, value: 'client_mailgun', label: 'Mailgun', brandKey: 'mailgun'));
    items.add(_brandItem(context, value: 'client_ses', label: 'Amazon SES', brandKey: 'ses'));
    items.add(_brandItem(context, value: 'client_brevo', label: 'Brevo', brandKey: 'brevo'));
    // SMTP is always offered; disabled when out of plan, demo, or off-scope.
    final smtpEnabled =
        isCompanyScope && isProOrEnterprise && !Env.demoMode;
    items.add(
      DropdownMenuItem(
        value: 'smtp',
        enabled: smtpEnabled,
        child: Row(
          children: [
            _BrandDot(color: _kBrandDotColors['smtp']!),
            const SizedBox(width: 8),
            Text(
              'SMTP',
              style: TextStyle(
                color: smtpEnabled ? null : Theme.of(context).disabledColor,
              ),
            ),
            if (!smtpEnabled) ...[
              const SizedBox(width: 8),
              const _ProChip(),
            ],
          ],
        ),
      ),
    );
    return items;
  }

  static DropdownMenuItem<String> _brandItem(
    BuildContext context, {
    required String value,
    required String label,
    required String brandKey,
  }) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          _BrandDot(color: _kBrandDotColors[brandKey]!),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  // ── Conditional provider config sections ───────────────────────────────

  static List<Widget> _providerConfigSections(
    BuildContext context, {
    required String method,
    required bool isCompanyScope,
    required bool isProOrEnterprise,
  }) {
    final host = context.watch<SettingsDraftHost>();
    if (method == 'gmail' || method == 'office365' || method == 'microsoft') {
      return [
        FormSection(
          title: context.tr('configuration'),
          children: [
            OauthUserPicker(
              provider: method == 'gmail' ? 'google' : 'microsoft',
            ),
          ],
        ),
      ];
    }
    if (method == 'client_postmark') {
      return [
        FormSection(
          title: context.tr('configuration'),
          children: [
            OverridableTextField(
              label: context.tr('api_token'),
              apiKey: 'postmark_secret',
              obscureToggle: true,
            ),
          ],
        ),
      ];
    }
    if (method == 'client_mailgun') {
      return [
        FormSection(
          title: context.tr('configuration'),
          children: [
            OverridableTextField(
              label: context.tr('api_key'),
              apiKey: 'mailgun_secret',
              obscureToggle: true,
            ),
            OverridableTextField(
              label: context.tr('domain'),
              apiKey: 'mailgun_domain',
            ),
            OverridableDropdownField<String>(
              label: context.tr('endpoint'),
              apiKey: 'mailgun_endpoint',
              value: host.settings.mailgunEndpoint ?? 'api.mailgun.net',
              items: const [
                DropdownMenuItem(
                  value: 'api.mailgun.net',
                  child: Text('api.mailgun.net'),
                ),
                DropdownMenuItem(
                  value: 'api.eu.mailgun.net',
                  child: Text('api.eu.mailgun.net'),
                ),
              ],
              onChanged: (v) => host.updateSettings(
                (s) => s.copyWith(mailgunEndpoint: v),
              ),
            ),
          ],
        ),
      ];
    }
    if (method == 'client_brevo') {
      return [
        FormSection(
          title: context.tr('configuration'),
          children: [
            OverridableTextField(
              label: context.tr('secret'),
              apiKey: 'brevo_secret',
              obscureToggle: true,
            ),
          ],
        ),
      ];
    }
    if (method == 'client_ses') {
      return [
        FormSection(
          title: context.tr('configuration'),
          children: [
            OverridableTextField(
              label: context.tr('secret_key'),
              apiKey: 'ses_secret_key',
              obscureToggle: true,
            ),
            OverridableTextField(
              label: context.tr('access_key'),
              apiKey: 'ses_access_key',
            ),
            OverridableTextField(
              label: context.tr('region'),
              apiKey: 'ses_region',
            ),
            OverridableTextField(
              label: context.tr('from_address'),
              apiKey: 'ses_from_address',
              keyboardType: TextInputType.emailAddress,
            ),
            OverridableTextField(
              label: context.tr('topic_arn'),
              apiKey: 'ses_topic_arn',
            ),
          ],
        ),
      ];
    }
    if (method == 'smtp' && isCompanyScope && isProOrEnterprise) {
      return const [SmtpMailDriverCard()];
    }
    return const <Widget>[];
  }
}

class _BrandDot extends StatelessWidget {
  const _BrandDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ProChip extends StatelessWidget {
  const _ProChip();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.accent,
        borderRadius: BorderRadius.circular(InRadii.r1),
      ),
      child: Text(
        context.tr('pro_plan'),
        style: TextStyle(
          color: tokens.accentInk,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// `entity_send_time` row: the dropdown + inline "Sync to existing entities"
/// checkbox that only appears when the draft value diverges from the loaded
/// baseline. Toggling the checkbox stashes a one-shot flag on the VM that
/// the next save injects into the outbox payload as `_sync_send_time`.
class _SendTimeRow extends StatelessWidget {
  const _SendTimeRow({required this.host});

  final SettingsDraftHost host;

  @override
  Widget build(BuildContext context) {
    final current = host.settings.entitySendTime;
    final initial = host.initialSettings.entitySendTime;
    final isDirty = current != initial;
    final emailVm = host is EmailSettingsViewModel
        ? host as EmailSettingsViewModel
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverridableDropdownField<int>(
          label: context.tr('send_time'),
          apiKey: 'entity_send_time',
          value: current,
          items: _sendTimeItems(context, host),
          onChanged: (v) =>
              host.updateSettings((s) => s.copyWith(entitySendTime: v)),
        ),
        if (isDirty && emailVm != null)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(context.tr('sync_send_time')),
            subtitle: Text(context.tr('sync_send_time_help')),
            value: emailVm.pendingSyncSendTime,
            onChanged: (v) => emailVm.setSyncSendTimeFlag(v ?? false),
          ),
      ],
    );
  }

  static List<DropdownMenuItem<int>> _sendTimeItems(
    BuildContext context,
    SettingsDraftHost host,
  ) {
    final military = host.settings.militaryTime ?? false;
    final items = <DropdownMenuItem<int>>[];
    for (var hour = 1; hour <= 24; hour++) {
      items.add(
        DropdownMenuItem(
          value: hour,
          child: Text(_formatHour(hour, military: military)),
        ),
      );
    }
    return items;
  }

  static String _formatHour(int hour, {required bool military}) {
    if (military) {
      final padded = hour.toString().padLeft(2, '0');
      return '$padded:00';
    }
    final h12 = hour == 24
        ? 12
        : hour == 12
            ? 12
            : hour > 12
                ? hour - 12
                : hour;
    final suffix = (hour >= 12 && hour < 24) ? 'PM' : 'AM';
    return '$h12:00 $suffix';
  }
}

/// Live validation chip for the `email_style_custom` textarea — flips
/// between a green "found" pill and a red "missing" pill based on whether
/// the body contains the literal `$body` placeholder. Cheap UX upgrade over
/// the legacy save-time check.
class _BodyVariableChip extends StatelessWidget {
  const _BodyVariableChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final present = value.contains(r'$body');
    final theme = Theme.of(context);
    final color = present
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
    final icon = present ? Icons.check_circle : Icons.error_outline;
    final label = present
        ? context.tr('add_body_variable_message')
        : context.tr('body_variable_missing');
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
