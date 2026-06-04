/// Stable identifiers for the supported gateway providers, matching the
/// legacy admin-portal `lib/constants.dart` definitions. Each constant is a
/// 32-character hex hash that the server uses as the `key` for that gateway
/// type — it's stable across all deployments. UI code that needs to special-
/// case a provider (OAuth setup, Stripe import/verify, custom-gateway
/// affordances) compares against these.
library;

const String kGatewayStripe = 'd14dd26a37cecc30fdd65700bfb55b23';
const String kGatewayStripeConnect = 'd14dd26a47cecc30fdd65700bfb67b34';
const String kGatewayPayPalRest = '80af24a6a691230bbec33e930ab40665';
const String kGatewayPayPalPlatform = '80af24a6a691230bbec33e930ab40666';
// Real hash confirmed via live demo API; earlier value was a leftover
// placeholder string. (Square's `*baz` hash *is* real — that one stays.)
const String kGatewayPayPalExpress = '38f2c48af60c7dd69e04248cbb24c36e';
// PayPal PPCP shares paypal_platform's gateway key (…ab40666) — there is no
// distinct PPCP key on the wire, so `kGatewayPayPalPlatform` covers it
// everywhere (OAuth detection, setup URL, logo). The earlier standalone
// `kGatewayPayPalPpcp` constant held a fabricated hash that matched no gateway.
const String kGatewayAuthorizeNet = '3b6621f970ab18887c4f6dca78d3f8bb';
const String kGatewayCheckoutCom = '3758e7f7c6f4cecf0f4f348b9a00f456';
const String kGatewayWePay = '8fdeed552015b3c7b44ed6c8ebd9e992';
const String kGatewayGoCardlessOAuth = 'b9886f9257f0c6ee7c302f1c74475f6c';
const String kGatewaySquare = '65faab2ab6e3223dbe848b1686490baz';
const String kGatewayBraintree = 'f7ec488676d310683fb51802d076d713';
// Real hash confirmed via live demo API; earlier value was off by one
// character (last char `d` vs the live `a`). Used by `CompanyGateway.isCustom`.
const String kGatewayCustom = '54faab2ab6e3223dbe848b1686490baa';
const String kGatewayMollie = '1bd651fb213ca0c9d66ae3c336dc77e8';
const String kGatewayRazorpay = 'hxd6gwg3ekb9tb3v9lptgx1mqyg69zu9';
const String kGatewayForte = 'kivcvjexxvdiyqtj3mju5d6yhpeht2xs';
const String kGatewayPaytrace = 'bbd736b3254b0aabed6ad7fda1298c88';
const String kGatewayPayfast = 'd6814fc83f45d2935e7777071e629ef9';
const String kGatewayEway = '944c20175bbe6b9972c05bcfe294c2c7';
const String kGatewayBtcpay = 'vpyfbmdrkqcicpkjqdusgjfluebftuva';
const String kGatewayBlockonomics = 'wbhf02us6owgo7p4nfjd0ymssdshks4d';
const String kGatewayRotessa = '91be24c7b792230bced33e930ac61676';
const String kGatewayCbaPowerboard = 'b67581d804dbad1743b61c57285142ad';

/// Gateway types that require an OAuth-driven setup flow (external redirect,
/// per-type custom UI). The Credentials tab on the edit screen substitutes a
/// stub card for these; Phase 2 implements the real flows. Lookup is by
/// `Gateway.id` (the same value stored on `CompanyGateway.gatewayKey`).
const Set<String> kOAuthGatewayKeys = <String>{
  kGatewayStripeConnect,
  kGatewayPayPalPlatform,
  kGatewayWePay,
  kGatewayGoCardlessOAuth,
  kGatewaySquare,
};

/// `CompanyGateway.acceptedCreditCards` is a bitmask. Each constant maps a
/// card brand to its bit value; helpers on the domain model wrap the bitwise
/// math.
const int kCardTypeVisa = 1;
const int kCardTypeMasterCard = 2;
const int kCardTypeAmEx = 4;
const int kCardTypeDiners = 8;
const int kCardTypeDiscover = 16;

/// Order matters: this is the UI order on the Settings tab.
const List<int> kCardTypeBits = <int>[
  kCardTypeVisa,
  kCardTypeMasterCard,
  kCardTypeAmEx,
  kCardTypeDiners,
  kCardTypeDiscover,
];

/// Localization key per card-type bit. Caller renders `context.tr(...)`.
const Map<int, String> kCardTypeLabelKey = <int, String>{
  kCardTypeVisa: 'visa',
  kCardTypeMasterCard: 'mastercard',
  kCardTypeAmEx: 'amex',
  kCardTypeDiners: 'diners',
  kCardTypeDiscover: 'discover',
};

/// `CompanyGateway.tokenBilling` accepted values. Matches the legacy
/// `kAutoBill*` constants on the company model — the server normalizes
/// these to the same wire strings.
const String kAutoBillAlways = 'always';
const String kAutoBillOptOut = 'optout';
const String kAutoBillOptIn = 'optin';
const String kAutoBillOff = 'off';

const List<String> kAutoBillOptions = <String>[
  kAutoBillAlways,
  kAutoBillOptOut,
  kAutoBillOptIn,
  kAutoBillOff,
];

/// Fees/limits sentinel — the server uses `-1` to mean "no limit set" on
/// both `min_limit` and `max_limit`. Treating literal `0` as "no limit"
/// would block all transactions.
const double kGatewayLimitDisabled = -1.0;

/// Gateway provider key → bundled logo asset path.
///
/// Mirrors the React app's `gatewaysDetails` array in
/// `react/src/pages/settings/gateways/create/Create.tsx:63-82`, which is
/// the upstream source of truth for the hash → display-name mapping. We
/// take the same hashes and map to asset paths under `assets/images/gateway_logos/`.
/// Some hashes share a logo (Stripe / Stripe Connect both use stripe.svg;
/// PayPal Rest / PayPal Platform / PayPal PPCP all use paypal.png).
///
/// Mollie was originally absent (React renders it from a custom
/// `MollieIcon` component). We extracted that single-path SVG, converted
/// it to PNG, and ship it now too. Rotessa uses the brand favicon from
/// rotessa.com; CBA PowerBoard uses the CommBank-PowerBoard GitHub org
/// avatar. `GatewayLogo` falls back to the wallet icon for any provider
/// key not in this map (the `Custom` gateway type today — no real
/// provider to brand).
const Map<String, String> kGatewayLogoByKey = <String, String>{
  kGatewayStripe: 'assets/images/gateway_logos/stripe.png',
  kGatewayStripeConnect: 'assets/images/gateway_logos/stripe.png',
  kGatewayPayPalRest: 'assets/images/gateway_logos/paypal.png',
  kGatewayPayPalPlatform: 'assets/images/gateway_logos/paypal.png',
  kGatewayPayPalExpress: 'assets/images/gateway_logos/paypal.png',
  kGatewayMollie: 'assets/images/gateway_logos/mollie.png',
  kGatewayBraintree: 'assets/images/gateway_logos/braintree.svg.png',
  kGatewayAuthorizeNet: 'assets/images/gateway_logos/authorize-net.png',
  kGatewayGoCardlessOAuth: 'assets/images/gateway_logos/gocardless.png',
  kGatewayForte: 'assets/images/gateway_logos/forte.png',
  kGatewayRazorpay: 'assets/images/gateway_logos/razorpay.png',
  kGatewaySquare: 'assets/images/gateway_logos/square.svg.png',
  kGatewayPaytrace: 'assets/images/gateway_logos/paytrace.png',
  kGatewayCheckoutCom: 'assets/images/gateway_logos/checkout.jpg',
  kGatewayPayfast: 'assets/images/gateway_logos/payfast.png',
  kGatewayEway: 'assets/images/gateway_logos/eway.png',
  kGatewayBtcpay: 'assets/images/gateway_logos/btcpay.png',
  kGatewayBlockonomics: 'assets/images/gateway_logos/blockonomics.png',
  kGatewayWePay: 'assets/images/gateway_logos/wepay.png',
  kGatewayRotessa: 'assets/images/gateway_logos/rotessa.png',
  kGatewayCbaPowerboard: 'assets/images/gateway_logos/cba-powerboard.png',
};

/// Stable catalog of payment-method type ids used as keys on `Gateway.options`
/// and as keys of `CompanyGateway.feesAndLimits`. The server does **not**
/// return this catalog via `/api/v1/statics` — it's a fixed list both the
/// legacy admin-portal (`admin-portal/lib/constants.dart` lines 622-680)
/// and the React app hardcode app-side.
///
/// Values are localization keys; the matching translations
/// (`credit_card`, `bank_transfer`, `paypal`, …) already live in
/// `assets/i18n/en.json`. Call sites resolve via `context.tr(...)`.
const Map<String, String> kGatewayTypeLabelKey = <String, String>{
  '1': 'credit_card',
  '2': 'bank_transfer',
  '3': 'paypal',
  '4': 'crypto',
  '5': 'custom',
  '6': 'alipay',
  '7': 'sofort',
  '8': 'apple_pay',
  '9': 'sepa',
  '10': 'credit',
  '11': 'kbc',
  '12': 'bancontact',
  '13': 'ideal',
  '14': 'hosted',
  '15': 'giropay',
  '16': 'przelewy24',
  '17': 'eps',
  '18': 'direct_debit',
  '19': 'acss',
  '20': 'becs',
  '21': 'instant_bank_pay',
  '22': 'fpx',
  '23': 'klarna',
  '24': 'bacs',
  '25': 'venmo',
  '26': 'mercado_pago',
  '27': 'mybank',
  '28': 'pay_later',
  '29': 'advanced_cards',
};
