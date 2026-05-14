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
const String kGatewayPayPalExpress = '54faab2ab6e3223dbe848b1686490baz';
const String kGatewayPayPalPpcp = 'b9886f9257f0c6ee7c302f1c74475f6b';
const String kGatewayAuthorizeNet = '3b6621f970ab18887c4f6dca78d3f8bb';
const String kGatewayCheckoutCom = '3758e7f7c6f4cecf0f4f348b9a00f456';
const String kGatewayWePay = '8fdeed552015b3c7b44ed6c8ebd9e992';
const String kGatewayGoCardlessOAuth = 'b9886f9257f0c6ee7c302f1c74475f6c';
const String kGatewaySquare = '65faab2ab6e3223dbe848b1686490baz';
const String kGatewayBraintree = 'f7ec488676d310683fb51802d076d713';
const String kGatewayCustom = '54faab2ab6e3223dbe848b1686490bad';
const String kGatewayMollie = '1bd651fb213ca0c9d66ae3c336dc77e8';
const String kGatewayRazorpay = 'b9d8c5f157a7d39afe04d8a8edbbc0eb';
const String kGatewayForte = 'kivcvjexxvdiyqtj3mju5d6yhpeht2xs';

/// Gateway types that require an OAuth-driven setup flow (external redirect,
/// per-type custom UI). The Credentials tab on the edit screen substitutes a
/// stub card for these; Phase 2 implements the real flows. Lookup is by
/// `Gateway.id` (the same value stored on `CompanyGateway.gatewayKey`).
const Set<String> kOAuthGatewayKeys = <String>{
  kGatewayStripeConnect,
  kGatewayPayPalPlatform,
  kGatewayPayPalPpcp,
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
