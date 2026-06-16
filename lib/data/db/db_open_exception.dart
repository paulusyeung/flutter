/// Thrown by the native DB opener when the OS secret store (keychain /
/// keyring) is unreachable, so the per-install SQLCipher key can be neither
/// read nor written — e.g. a Linux snap whose `password-manager-service` plug
/// hasn't been connected (the keyring is locked / libsecret is unavailable).
///
/// Distinct from a corrupt or schema-drifted database: the open orchestrator
/// must NOT reset-and-reopen on this (resetting renames the user's DB file and
/// then re-throws here on the next key fetch, blanking the window on every
/// launch — the original Linux crash-loop). `main` catches it and renders an
/// actionable error screen instead.
class KeyringUnavailableException implements Exception {
  const KeyringUnavailableException(this.message, [this.stackTrace]);

  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => 'KeyringUnavailableException: $message';
}
