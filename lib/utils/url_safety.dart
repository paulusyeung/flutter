/// Return true when [url] is safe to hand to `Image.network` or to a
/// `launchUrl(externalApplication)` call. We require:
///   * a parseable URI,
///   * https scheme (no plain http — the server controls the URL and we
///     don't want plaintext image fetches that leak the user's IP + UA),
///   * a non-empty host (catches `https://` typos that resolve to nothing),
///   * no embedded credentials (`userInfo`) — those would be sent to the
///     remote host on every request.
///
/// Why this matters: company logo / avatar URLs are server-controlled. A
/// compromised or hostile server can otherwise set the URL to an arbitrary
/// address, turning every page render into a tracking ping.
bool isSafeHttpsUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.scheme.toLowerCase() != 'https') return false;
  if (uri.host.isEmpty) return false;
  if (uri.userInfo.isNotEmpty) return false;
  return true;
}

/// Same shape as [isSafeHttpsUrl] but allows http alongside https — for
/// user-visible "open portal" / "open website" links where self-hosted
/// users on internal networks may legitimately use http. Still rejects
/// every dangerous scheme: `javascript:`, `file:`, `intent:`, `data:`,
/// `vnd.*://`, `mailto:`, `tel:`, etc.
///
/// Use [isSafeHttpsUrl] (https-only) for resource-fetching URLs (logos,
/// document downloads); use this for tap-to-open external links where
/// http is a real-world need.
bool isSafeWebUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'https' && scheme != 'http') return false;
  if (uri.host.isEmpty) return false;
  if (uri.userInfo.isNotEmpty) return false;
  return true;
}
