/// The minimum set of credentials the API client needs to make an
/// authenticated request. The auth layer (M1.8) populates this; the API
/// client only reads it.
class ApiCredentials {
  const ApiCredentials({
    required this.baseUrl,
    required this.token,
    this.apiSecret = '',
    this.isHosted = false,
  });

  /// e.g. `https://invoicing.co` or a self-hosted URL.
  final String baseUrl;

  /// The user's API token. Empty means unauthenticated.
  final String token;

  /// `X-API-SECRET` value — sent on hosted builds only.
  final String apiSecret;

  /// True when talking to the hosted Invoice Ninja server.
  final bool isHosted;

  bool get isAuthenticated => token.isNotEmpty && baseUrl.isNotEmpty;
}
