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
