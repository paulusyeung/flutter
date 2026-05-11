/// Client-side version identifiers used in API request headers and the
/// version-negotiation handshake with the server.
///
/// Bump [kClientVersion] on every release. Bump [kMinServerVersion] only when
/// we start depending on a server API change.
///
/// We share Invoice Ninja's version envelope: see
/// `admin-portal/lib/constants.dart:9`. This rebuild speaks `/api/v1` the
/// same way admin-portal does, so claiming the same version keeps us inside
/// the server's `x-minimum-client-version` floor without forcing the server
/// team to special-case us.
class AppVersion {
  AppVersion._();

  /// Sent as `X-CLIENT-VERSION` on every request.
  static const String kClientVersion = '5.0.193';

  /// The minimum Invoice Ninja server version this client can talk to.
  ///
  /// The server returns `x-app-version` on every response; if it's below this
  /// we surface a "server needs upgrade" screen.
  static const String kMinServerVersion = '5.0.4';
}
