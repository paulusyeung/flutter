/// Client-side version identifiers used in API request headers and the
/// version-negotiation handshake with the server.
///
/// Bump [kClientVersion] on every release. Bump [kMinServerVersion] only when
/// we start depending on a server API change.
class AppVersion {
  AppVersion._();

  /// Sent as `X-CLIENT-VERSION` on every request.
  static const String kClientVersion = '1.0.0';

  /// The minimum Invoice Ninja server version this client can talk to.
  ///
  /// The server returns `x-app-version` on every response; if it's below this
  /// we surface a "server needs upgrade" screen.
  static const String kMinServerVersion = '5.10.0';
}
