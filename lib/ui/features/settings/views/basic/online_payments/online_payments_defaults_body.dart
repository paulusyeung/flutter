import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/value/payment_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';

/// Online Payments — Defaults tab. Field labels surfaced by the in-app search.
const kOnlinePaymentsDefaultsSearchKeys = <String>[
  'default_payment_type',
  'default_expense_payment_type',
  'invoice_payment_terms',
  'quote_valid_until',
  'configure_payment_terms',
];

class OnlinePaymentsDefaultsBody extends StatelessWidget {
  const OnlinePaymentsDefaultsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final statics = context.read<Services>().statics;
    final host = context.watch<SettingsDraftHost>();

    final paymentTypes = statics.paymentTypes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return FormSection(
      title: context.tr('defaults'),
      children: [
        OverridableSearchableDropdownField<PaymentType>(
          label: context.tr('default_payment_type'),
          apiKey: 'payment_type_id',
          value: host.settings.paymentTypeId,
          items: paymentTypes,
          displayString: (p) => p.name,
          idOf: (p) => p.id,
          onChanged: (v) =>
              host.updateSettings((s) => s.copyWith(paymentTypeId: v)),
        ),
        OverridableSearchableDropdownField<PaymentType>(
          label: context.tr('default_expense_payment_type'),
          apiKey: 'default_expense_payment_type_id',
          value: host.settings.defaultExpensePaymentTypeId,
          items: paymentTypes,
          displayString: (p) => p.name,
          idOf: (p) => p.id,
          onChanged: (v) => host.updateSettings(
            (s) => s.copyWith(defaultExpensePaymentTypeId: v),
          ),
        ),
        // Payment terms / valid-until are looked up from the user's
        // per-company `PaymentTerm` list, which isn't bundled into the new
        // app yet. Until that ships, accept the raw value as text — typically
        // a number-of-days string like "30" or a named term. Promote to a
        // dropdown when the bundled list lands (see plan: future work).
        OverridableTextField(
          label: context.tr('invoice_payment_terms'),
          apiKey: 'payment_terms',
        ),
        OverridableTextField(
          label: context.tr('quote_valid_until'),
          apiKey: 'valid_until',
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: () =>
                _showComingSoon(context, 'configure_payment_terms'),
            icon: const Icon(Icons.schedule_outlined, size: 18),
            label: Text(context.tr('configure_payment_terms')),
          ),
        ),
      ],
    );
  }

  // The per-company payment-terms list isn't bundled into the new app yet
  // (see CLAUDE.md "Data loading — bundled vs per-entity"). Show a snackbar
  // so the button is acknowledged without navigating to a wrong screen.
  void _showComingSoon(BuildContext context, String featureKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('feature_coming_soon', {
            'feature': context.tr(featureKey),
          }),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
