/// Placeholder variables that the server expands when rendering a custom
/// design. Surfaced in the editor's Variables tab so authors can discover
/// and tap-to-insert them instead of memorising the list.
///
/// Ported from the React client
/// (`src/pages/settings/invoice-design/customize/common/variables.ts`) —
/// keep in sync when that list changes. Only the four entity-facing groups
/// are carried here; the `docu_*` template groups belong to a different
/// feature.
library;

/// One labelled group of variables. [titleKey] is a localization key.
class DesignVariableGroup {
  const DesignVariableGroup({required this.titleKey, required this.variables});

  final String titleKey;
  final List<String> variables;
}

const List<DesignVariableGroup> kDesignVariableGroups = [
  DesignVariableGroup(
    titleKey: 'invoice',
    variables: [
      r'$amount',
      r'$assigned_to_user',
      r'$balance',
      r'$created_by_user',
      r'$date',
      r'$discount',
      r'$due_date',
      r'$exchange_rate',
      r'$footer',
      r'$invoice',
      r'$invoices',
      r'$number',
      r'$payment_button',
      r'$payment_url',
      r'$payments',
      r'$po_number',
      r'$public_notes',
      r'$terms',
      r'$view_button',
      r'$view_url',
    ],
  ),
  DesignVariableGroup(
    titleKey: 'client',
    variables: [
      r'$client.address1',
      r'$client.address2',
      r'$client.city',
      r'$client.country',
      r'$client.credit_balance',
      r'$client.id_number',
      r'$client.name',
      r'$client.phone',
      r'$client.postal_code',
      r'$client.public_notes',
      r'$client.shipping_address1',
      r'$client.shipping_address2',
      r'$client.shipping_city',
      r'$client.shipping_country',
      r'$client.shipping_postal_code',
      r'$client.shipping_state',
      r'$client.state',
      r'$client.vat_number',
    ],
  ),
  DesignVariableGroup(
    titleKey: 'contact',
    variables: [
      r'$contact.email',
      r'$contact.first_name',
      r'$contact.last_name',
      r'$contact.phone',
    ],
  ),
  DesignVariableGroup(
    titleKey: 'company',
    variables: [
      r'$company.address1',
      r'$company.address2',
      r'$company.country',
      r'$company.email',
      r'$company.id_number',
      r'$company.name',
      r'$company.phone',
      r'$company.state',
      r'$company.vat_number',
      r'$company.website',
    ],
  ),
];
