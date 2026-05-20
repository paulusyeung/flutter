import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/link_text.dart';
import 'package:admin/ui/features/settings/state/settings_level_controller.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/certificate_card.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/e_invoice_constants.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/payment_means_card.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/peppol_onboarding_card.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/peppol_preferences_card.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/tax_identifiers_card.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';
import 'package:admin/ui/features/settings/widgets/overridable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_switch_field.dart';
import 'package:admin/ui/features/settings/widgets/overridable_text_field.dart';
import 'package:admin/ui/features/settings/widgets/plan_gate_banner.dart';
import 'package:admin/ui/features/settings/widgets/settings_form_shell.dart';

/// Field labels exposed by the in-app settings search for the E-Invoice
/// page. Keep in sync with `kSettingsSearchCatalog['e_invoice']` —
/// `search_catalog_consistency_test` asserts every entry is actually
/// rendered.
const kEInvoiceSearchKeys = <String>[
  'e_invoice_type',
  'enable_e_invoice',
  'merge_e_invoice_to_pdf',
  'e_quote_type',
  'e_invoice_forward_email',
  'e_expense_forward_email',
  'skip_automatic_email_with_peppol',
  'certificate_passphrase',
  'payment_means',
  'additional_tax_identifiers',
  'act_as_sender',
  'act_as_receiver',
];

/// Body for Settings → E-Invoice. Mounted by [EInvoiceScreen] inside
/// [CascadeSettingsScaffold] — the scaffold owns the cascade VM and provides
/// it via Provider.
///
/// Layout mirrors admin-portal `lib/ui/settings/e_invoice_settings.dart` and
/// React `pages/settings/e-invoice/EInvoice.tsx`, with two UX improvements:
///   * The type dropdown uses [OverridableSearchableDropdownField] — the
///     option list is ~20 entries long, past the project rule's
///     type-to-search threshold.
///   * The body opens with a [LinkText] linking to the user-guide docs so
///     users can find background on the field set in one tap.
///
/// Five sub-features live on this page. The cascade-friendly fields
/// (type, enable-toggle, merge-to-PDF, quote type, forward emails, skip
/// email) bind through `Overridable*` widgets and ride the page Save
/// button. The four company-only blocks ([CertificateCard],
/// [PeppolOnboardingCard] / [PeppolPreferencesCard], [PaymentMeansCard],
/// [TaxIdentifiersCard]) gate themselves with `scope.isCompany` and fire
/// their own outbox rows on action.
class EInvoiceBody extends StatelessWidget {
  const EInvoiceBody({super.key});

  @override
  Widget build(BuildContext context) {
    final host = context.watch<SettingsDraftHost>();
    final scope = context.watch<SettingsLevelController>();
    final settings = host.settings;
    final company = host.draft;
    final isCompany = scope.isCompany;

    final eInvoiceType = settings.eInvoiceType ?? kEInvoiceTypeEN16931;
    final isPeppol = eInvoiceType == kEInvoiceTypePEPPOL;
    final isVerifactu = eInvoiceType == kEInvoiceTypeVERIFACTU;
    final enableEInvoice = settings.enableEInvoice ?? false;

    // VERIFACTU is Spain-specific (AEAT registration). Hide the option
    // from the dropdown unless the company's country is Spain — keeps
    // users in other countries from picking a standard that won't work
    // for them. Already-selected VERIFACTU stays visible so the user
    // can switch away.
    final isSpain = settings.countryId == kEInvoiceCountryIdSpain;
    final dropdownItems = kEInvoiceTypes
        .where((t) => t != kEInvoiceTypeVERIFACTU || isSpain || isVerifactu)
        .toList(growable: false);

    return SettingsFormShell(
      sections: [
        // E-invoice is Enterprise on hosted (React `EInvoice.tsx` gates the
        // whole page at `enterprisePlan()`). Trial-aware; auto-hides on
        // access. The slug `e_invoice` is also in `kEnterpriseGatedSettings`
        // so the sidebar shows the lock + chip before the user taps in.
        const PlanGateBanner(
          style: PlanGateStyle.inset,
          level: PlanGateLevel.enterprise,
        ),
        // Help link — small, deliberate, sits above the first card. Same
        // affordance React ships at the top of EInvoice.tsx.
        const _HelpLinkRow(),

        // ── E-Invoice Type ─────────────────────────────────────────────
        FormSection(
          title: context.tr('e_invoice_type'),
          children: [
            OverridableSearchableDropdownField<String>(
              label: context.tr('e_invoice_type'),
              apiKey: 'e_invoice_type',
              value: settings.eInvoiceType ?? kEInvoiceTypeEN16931,
              items: dropdownItems,
              displayString: (t) => t,
              idOf: (t) => t,
              onChanged: (v) async {
                // Switch-type-away-while-connected guard. If the user
                // is moving off PEPPOL with an active legal entity bound
                // server-side, the binding would be orphaned — prompt
                // before committing.
                if (isPeppol &&
                    v != kEInvoiceTypePEPPOL &&
                    (company?.legalEntityId ?? 0) != 0) {
                  final proceed = await _confirmSwitchAwayFromPeppol(context);
                  if (proceed != true) return;
                }
                host.updateSettings((s) => s.copyWith(eInvoiceType: v));
              },
            ),
          ],
        ),

        // ── VERIFACTU info ──────────────────────────────────────────────
        // Spain-only standard; admin-portal shows a six-step authorization
        // instructions card alongside the dropdown. The dropdown above
        // already country-gates the VERIFACTU option to Spain (with a
        // carve-out for already-selected VERIFACTU), so this card mirrors
        // the user's current selection.
        if (isVerifactu && isCompany) const _VerifactuInfoCard(),

        // ── Enable E-Invoice + cascade-friendly toggles ────────────────
        if (!isPeppol)
          FormSection(
            title: context.tr('enable_e_invoice'),
            children: [
              OverridableSwitchField(
                label: context.tr('enable_e_invoice'),
                apiKey: 'enable_e_invoice',
              ),
              if (enableEInvoice) ...[
                OverridableSwitchField(
                  label: context.tr('merge_e_invoice_to_pdf'),
                  apiKey: 'merge_e_invoice_to_pdf',
                ),
                OverridableSwitchField(
                  label: context.tr('skip_automatic_email_with_peppol'),
                  apiKey: 'skip_automatic_email_with_peppol',
                  subtitle: context.tr('skip_automatic_email_with_peppol_help'),
                ),
                OverridableDropdownField<String>(
                  label: context.tr('e_quote_type'),
                  apiKey: 'e_quote_type',
                  value: settings.eQuoteType ?? kEQuoteTypeOrderX_Comfort,
                  items: kEQuoteTypes
                      .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      host.updateSettings((s) => s.copyWith(eQuoteType: v)),
                ),
                OverridableTextField(
                  label: context.tr('e_invoice_forward_email'),
                  apiKey: 'e_invoice_forward_email',
                  helperText: context.tr('e_invoice_forward_email_help'),
                  keyboardType: TextInputType.emailAddress,
                ),
                OverridableTextField(
                  label: context.tr('e_expense_forward_email'),
                  apiKey: 'e_expense_forward_email',
                  helperText: context.tr('e_expense_forward_email_help'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ],
          ),

        // ── Certificate card ─────────────────────────────────────────
        if (isCompany && !isPeppol && enableEInvoice && company != null)
          const CertificateCard(),

        // ── PEPPOL onboarding / preferences ─────────────────────────
        if (isCompany && isPeppol && company != null)
          (company.legalEntityId == 0)
              ? const PeppolOnboardingCard()
              : const PeppolPreferencesCard(),

        // ── Payment Means ────────────────────────────────────────────
        if (isCompany &&
            (enableEInvoice || isPeppol) &&
            company != null)
          const PaymentMeansCard(),

        // ── Additional Tax Identifiers ──────────────────────────────
        if (isCompany &&
            (enableEInvoice || isPeppol) &&
            company != null)
          const TaxIdentifiersCard(),
      ],
    );
  }
}

/// Confirmation dialog shown when the user changes `eInvoiceType` away
/// from PEPPOL while a `legalEntityId` is still bound server-side.
/// Returns `true` when the user wants to commit the switch anyway,
/// `false` (or `null`) to cancel. Side-by-side actions per the design
/// system; destructive button uses `tokens.overdue`.
Future<bool?> _confirmSwitchAwayFromPeppol(BuildContext context) {
  final tokens = context.inTheme;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.tr('switch_away_from_peppol_title')),
      content: Text(context.tr('switch_away_from_peppol_message')),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          autofocus: true,
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 44),
            backgroundColor: tokens.overdue,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(context.tr('switch_anyway')),
        ),
      ],
    ),
  );
}

/// Single-row link to the e-invoicing user guide. Sits above the first
/// `FormSection` and renders inside the `SettingsFormShell`'s outer
/// padding. Reuses the project's `LinkText` for hover + cursor behavior.
class _HelpLinkRow extends StatelessWidget {
  const _HelpLinkRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: InSpacing.lg(context)),
      child: Row(
        children: [
          Icon(Icons.help_outline, size: 18, color: tokens.ink2),
          SizedBox(width: InSpacing.sm),
          LinkText(
            label: context.tr('e_invoice_settings'),
            color: tokens.accent,
            style: theme.textTheme.bodyMedium,
            onTap: launchEInvoiceHelpUrl,
          ),
        ],
      ),
    );
  }
}

/// VERIFACTU info / authorization pointer. Renders a description card
/// when the type dropdown is set to `VERIFACTU` — the standard is
/// Spain-specific and requires off-app registration with AEAT before
/// submissions go through. Admin-portal renders six numbered
/// authorization steps from Transifex (`tax_authority_authorization_step_1..6`);
/// those keys aren't in our bundle yet, so we ship a short description
/// + a docs link. When the keys land via import, fan them back out as
/// numbered list items.
class _VerifactuInfoCard extends StatelessWidget {
  const _VerifactuInfoCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final theme = Theme.of(context);
    return FormSection(
      title: 'VeriFactu',
      children: [
        Text(
          context.tr('verifactu_description'),
          style: theme.textTheme.bodyMedium?.copyWith(color: tokens.ink),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: LinkText(
            label: context.tr('verifactu_learn_more'),
            color: tokens.accent,
            style: theme.textTheme.bodyMedium,
            onTap: launchEInvoiceHelpUrl,
          ),
        ),
      ],
    );
  }
}

