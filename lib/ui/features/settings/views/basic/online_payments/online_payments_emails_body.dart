import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';

/// Online Payments — Emails tab. Field labels surfaced by the in-app search.
const kOnlinePaymentsEmailsSearchKeys = <String>[
  'online_payment_email',
  'manual_payment_email',
  'mark_paid_payment_email',
  'send_emails_to',
];

class OnlinePaymentsEmailsBody extends StatelessWidget {
  const OnlinePaymentsEmailsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final allContacts = host.settings.paymentEmailAllContacts ?? false;

    return FormSection(
      title: context.tr('emails'),
      children: [
        OverridableSwitchField(
          label: context.tr('online_payment_email'),
          apiKey: 'client_online_payment_notification',
          subtitle: context.tr('online_payment_email_help'),
        ),
        OverridableSwitchField(
          label: context.tr('manual_payment_email'),
          apiKey: 'client_manual_payment_notification',
          subtitle: context.tr('manual_payment_email_help'),
        ),
        OverridableSwitchField(
          label: context.tr('mark_paid_payment_email'),
          apiKey: 'send_email_on_mark_paid',
          subtitle: context.tr('mark_paid_payment_email_help'),
        ),
        OverridableSwitchField(
          label: context.tr('send_emails_to'),
          apiKey: 'payment_email_all_contacts',
          // Reversed-meaning toggle mirrors the legacy admin-portal: the
          // *enabled* state means "send to ALL contacts" (true on the wire);
          // the *disabled* state means "primary contact only". The subtitle
          // makes that visible to the user.
          subtitle: allContacts
              ? context.tr('all_contacts')
              : context.tr('primary_contact'),
        ),
      ],
    );
  }
}
