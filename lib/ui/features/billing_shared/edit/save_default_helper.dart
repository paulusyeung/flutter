import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// Persist a single field on `company.settings` to use as the new
/// company-level default. Used by the billing-doc edit screens'
/// "Save as default" buttons next to the Terms / Footer markdown
/// fields.
///
/// The [updater] receives the current [CompanySettings] and returns
/// the modified copy — typically a single `copyWith(...)` call
/// targeting the entity-specific key (`invoiceTerms`, `quoteFooter`,
/// `creditTerms`, `purchaseOrderFooter`, …).
///
/// Reads the active company once via [CompanyRepository.get], applies
/// the update, writes back via [CompanyRepository.updateCompany]
/// (optimistic Drift write + outbox `PUT /companies/{id}`). The
/// in-progress invoice draft is untouched — saving the field as a
/// default is independent of saving the invoice itself.
///
/// Surfaces `Notify.success` on the localized `updated_settings` key
/// when the optimistic write returns; `Notify.error` on failure.
Future<void> saveBillingDocDefault(
  BuildContext context, {
  required String companyId,
  required CompanySettings Function(CompanySettings settings) updater,
}) async {
  final services = context.read<Services>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final company = await services.company.get(companyId);
    if (company == null) {
      if (context.mounted) {
        Notify.error(
          context,
          context.tr('could_not_save'),
          messenger: messenger,
        );
      }
      return;
    }
    final nextSettings = updater(company.settings);
    await services.company.updateCompany(
      draft: company.copyWith(settings: nextSettings),
    );
    if (!context.mounted) return;
    Notify.success(
      context,
      context.tr('updated_settings'),
      messenger: messenger,
    );
  } catch (e) {
    if (!context.mounted) return;
    Notify.error(
      context,
      context.tr('could_not_save'),
      error: e,
      messenger: messenger,
    );
  }
}
