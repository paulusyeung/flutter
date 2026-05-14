import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/payment_term.dart';
import 'package:admin/data/models/value/payment_type.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';

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
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final statics = services.statics;
    final host = context.watch<SettingsDraftHost>();

    final paymentTypes = statics.paymentTypes.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return StreamBuilder<List<PaymentTerm>>(
      stream: services.paymentTerms.watchAll(companyId: companyId),
      builder: (context, snapshot) {
        final terms = snapshot.data ?? const <PaymentTerm>[];
        // Server-default terms ship pre-named ("Net 30"), so we lead with the
        // name and only fall back to the numeric form for unnamed entries.
        // Without the fallback, the picker would render "Net 30 (30 Days)"
        // — redundant — for the typical case.
        String termDisplay(PaymentTerm t) {
          final name = t.name.trim();
          return name.isEmpty ? '${t.numDays} ${context.tr('days')}' : name;
        }

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
            // Stored as the term's `num_days` (a numeric string like "30"),
            // matching the legacy admin-portal. The same per-company list
            // powers both the invoice and quote dropdowns. When the list is
            // empty (brand-new company), the field renders disabled with
            // the `no_payment_terms` hint — the "Configure payment terms"
            // button below is the create path.
            OverridableSearchableDropdownField<PaymentTerm>(
              label: context.tr('invoice_payment_terms'),
              apiKey: 'payment_terms',
              value: host.settings.paymentTerms,
              items: terms,
              displayString: termDisplay,
              idOf: (t) => t.numDays.toString(),
              emptyHintKey: 'no_payment_terms',
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(paymentTerms: v)),
            ),
            OverridableSearchableDropdownField<PaymentTerm>(
              label: context.tr('quote_valid_until'),
              apiKey: 'valid_until',
              value: host.settings.validUntil,
              items: terms,
              displayString: termDisplay,
              idOf: (t) => t.numDays.toString(),
              emptyHintKey: 'no_payment_terms',
              onChanged: (v) =>
                  host.updateSettings((s) => s.copyWith(validUntil: v)),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/settings/payment_terms'),
                icon: const Icon(Icons.schedule_outlined, size: 18),
                label: Text(context.tr('configure_payment_terms')),
              ),
            ),
          ],
        );
      },
    );
  }
}
