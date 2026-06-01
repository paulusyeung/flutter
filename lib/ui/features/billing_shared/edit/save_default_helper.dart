import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/notify.dart';

/// In-flight guard keyed by `"$companyId|$fieldKey"`. A second tap on
/// the same field's "Save as default" while the first write is still
/// round-tripping is a no-op (prevents duplicate outbox rows). Keyed on
/// the settings field — NOT the toast key — because the toast key is
/// shared across entities (every Terms button uses
/// `updated_default_terms`), which would otherwise let an invoice-terms
/// save block a near-simultaneous quote-terms save in the same company.
final Set<String> _inFlight = <String>{};

/// Persist a single field on `company.settings` to use as the new
/// company-level default. Used by the billing-doc edit screens'
/// "Save as default" buttons next to the Terms / Footer markdown
/// fields.
///
/// [value] is the field's current text (the caller flushes the editor
/// before invoking, so this is what's on screen — not a stale
/// debounced value). An empty / whitespace-only [value] is normalized
/// to `null` so the server clears the default rather than persisting a
/// literal empty block.
///
/// [apply] receives the current [CompanySettings] and the normalized
/// value, and returns the modified copy — typically
/// `(s, v) => s.copyWith(invoiceTerms: v)`.
///
/// [fieldKey] is the snake_case settings key (e.g. `invoice_terms`,
/// `quote_footer`) — used only as the in-flight guard dimension so a
/// rapid double-tap on the *same* button is deduped without blocking a
/// different field's save.
///
/// [successKey] is the localization key for the confirmation toast so
/// the message names the specific field ("Default terms saved").
///
/// Reads the active company once via [CompanyRepository.get], applies
/// the update, writes back via [CompanyRepository.updateCompany]
/// (optimistic Drift write + outbox `PUT /companies/{id}`). The
/// in-progress invoice draft is untouched — saving the field as a
/// default is independent of saving the invoice itself.
///
/// Always writes (no "already the default" short-circuit): the value
/// reaching this helper is the markdown editor's serialized form,
/// which is a normalized deserialize→serialize round-trip and rarely
/// byte-equals the raw stored `company.settings.<field>` even when
/// semantically unchanged — a value comparison here produces both
/// false negatives (writes when unchanged) and, worse, false
/// positives (skips a real change when the entity's terms were
/// overridden away from the company default). The outbox coalesces
/// redundant `PUT /companies` rows, so an occasional no-op write is
/// cheap and correct.
///
/// NOTE: [CompanyRepository.updateCompany] does NOT invalidate the
/// cached [Formatter]. That's fine for terms/footer (the formatter
/// doesn't read them). If this helper is ever reused for a
/// formatter-affecting field (currency, locale,
/// useCommaAsDecimalPlace, dateFormatId), call
/// `services.invalidateFormatter(companyId)` after the write.
Future<void> saveBillingDocDefault(
  BuildContext context, {
  required String companyId,
  required String fieldKey,
  required String value,
  required String successKey,
  required CompanySettings Function(CompanySettings settings, String? value)
  apply,
}) async {
  final guardKey = '$companyId|$fieldKey';
  if (_inFlight.contains(guardKey)) return;
  _inFlight.add(guardKey);
  final services = context.read<Services>();
  try {
    final company = await services.company.get(companyId);
    if (company == null) {
      if (context.mounted) {
        Notify.error(context, context.tr('could_not_save'));
      }
      return;
    }
    final normalized = value.trim().isEmpty ? null : value;
    final nextSettings = apply(company.settings, normalized);
    await services.company.updateCompany(
      draft: company.copyWith(settings: nextSettings),
    );
    if (!context.mounted) return;
    Notify.success(context, context.tr(successKey));
  } catch (e) {
    if (!context.mounted) return;
    Notify.error(context, context.tr('could_not_save'), error: e);
  } finally {
    _inFlight.remove(guardKey);
  }
}
