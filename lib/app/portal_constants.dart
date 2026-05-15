/// Constants for the Client Portal settings screen.
///
/// Mirror admin-portal `lib/utils/constants.dart` (kClientPortalMode*) and the
/// React `helpers/portal.ts` shape so the wire values agree across clients.
library;

/// `Company.portalMode` value indicating the portal lives at
/// `<subdomain>.invoicing.co`. Hosted-only.
const kClientPortalModeSubdomain = 'subdomain';

/// `Company.portalMode` value indicating the portal lives at a CNAME the
/// account owner configured (e.g. `billing.example.com`). Hosted enterprise +
/// self-hosted.
const kClientPortalModeDomain = 'domain';

/// Docs URL surfaced by the "View Docs" button on the Settings tab when the
/// account is on enterprise + hosted + domain mode. Mirrors admin-portal
/// `kDocsCustomDomainUrl`.
const kDocsCustomDomainUrl =
    'https://invoiceninja.github.io/docs/hosted/hosted-custom-domain';

/// Twenty registration-form fields the Client Portal Registration tab exposes
/// as a hide/optional/require matrix. Order matches React `Registration.tsx`
/// — first/last name, contact, address, custom, public notes, VAT. Key
/// strings are the wire keys persisted on `company.client_registration_fields`.
const kClientRegistrationFieldKeys = <String>[
  'first_name',
  'last_name',
  'email',
  'phone',
  'password',
  'name',
  'website',
  'address1',
  'address2',
  'city',
  'state',
  'postal_code',
  'country_id',
  'currency_id',
  'custom_value1',
  'custom_value2',
  'custom_value3',
  'custom_value4',
  'public_notes',
  'vat_number',
];
