# Setup

Companion to CLAUDE.md (no longer carries a § Setup section — this doc is the canonical source).

## Platform targets

- **Now**: iOS, macOS.
- **Later**: Android, Windows, Linux.
- **Never**: Web (the `web/` folder is deliberately absent).

When adding back Android/Windows/Linux, regenerate with `flutter create --platforms=android,windows,linux`. Notes: Android needs `<uses-permission android:name="android.permission.INTERNET" />`; Linux requires `libsecret-1-dev` for `flutter_secure_storage`; Windows uses DPAPI per-user.

## macOS setup notes

The sandboxed macOS build needs four entitlements (see `macos/Runner/{DebugProfile,Release}.entitlements`):

- `com.apple.security.app-sandbox` — on by default.
- `com.apple.security.network.client` — outbound HTTP. Added in M1.1.
- `keychain-access-groups` — required by `flutter_secure_storage`. Value: `$(AppIdentifierPrefix)com.invoiceninja.admin`. Without it, the first `auth.login` throws `PlatformException -34018 (errSecMissingEntitlement)`.
- `com.apple.security.files.user-selected.read-write` — required by `image_picker` + `file_picker` (Company Details: Logo, Documents tabs). Without it the sandbox blocks the open panels and the plugins log `NSCocoaErrorDomain` errors.

Any new package that touches Keychain (OAuth, biometric login, etc.) is already covered by the keychain entitlement — don't add another. If we ever change the bundle id from `com.invoiceninja.admin`, update the `keychain-access-groups` entries to match.

## Dev-machine login pre-fill

To avoid retyping credentials on every fresh launch:

1. Copy `dev.json.example` → `dev.json` (gitignored) and fill in `IN_DEV_EMAIL` / `IN_DEV_PASSWORD`.
2. Run with `flutter run --dart-define-from-file=dev.json`.

The pre-fill happens in `LoginViewModel`'s constructor and is guarded by `!kReleaseMode`, so debug *and* profile builds prefill (handy for perf testing) while release builds tree-shake the branch — credentials cannot leak into a shipped binary even if you accidentally pass the file at build. Keys are `String.fromEnvironment` reads in `lib/app/env.dart` (`Env.devEmail`, `Env.devPassword`).
