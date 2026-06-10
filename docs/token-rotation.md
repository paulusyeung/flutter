# API token rotation (is_system UI token)

**Status: blocked on server.** Implement the client side once the backend ships
`POST /api/v1/tokens/rotate`. No client work has landed yet.

## Why

`is_system=true` UI/session tokens are long-lived and stored in plaintext on the
server (`company_tokens.token`) — a risk if a token leaks or the DB is hijacked.
React rotates transparently every 30 days *on login*. Mobile/desktop apps may
never log out, so they must drive rotation themselves on a schedule. The backend
will also progressively hash tokens at rest; rotation is the migration on-ramp
(each rotation can write a hashed row, since the client only needs the plaintext
at the moment it is issued).

Server side is owned by the backend partner — this doc tracks only the client work.

## Server contract (confirm when it lands)

- `POST /api/v1/tokens/rotate`, authenticated with the current (old) token.
- Returns the **new token string** (plus its id/name if available).
- Per-company: one `is_system` token per company; rotate each independently.
- The server must **not** hard-expire the old token on a clock. The rotate call
  retires it, and only **a bit after** the new token is issued — so requests
  already in flight or queued offline under the old token don't 401. An app that
  was offline/closed past the rotation window must still be able to authenticate
  with its old token to make the rotate call itself, or the user is force-logged-out.

## Client work — two pieces: trigger (new) + swap (mostly exists)

### New app (`/Users/hillel/Code/admin`)

- **Trigger:** a timer in `AuthRepository` — on launch + on an interval (e.g. a
  daily check) while online — calls the rotate endpoint for the active company's
  token. Offline → retry at next online opportunity. Let the server own the real
  30-day policy; the client just guarantees it asks often enough.
- **Swap:** the token lives in the per-company `_tokensByCompany` map →
  `kAuthTokensKey` (`invoiceninja.tokens.v1`) secure storage, surfaced via
  `_credentials.value`. Reuse the existing token-merge path in
  `_persistAndActivate` (`auth_repository.dart:861-876`, write `:1176`, credential
  `:1253-1257`) to persist the new value and refresh live credentials.
- **Safe by construction:** `ApiClient` reads the token per-request from live
  credentials (`_buildHeaders`), and the outbox captures **no** token at enqueue
  (reads current at dispatch) — so a mid-session swap is safe for in-flight and
  queued mutations.
- **Optional header path:** if the server prefers to rotate opportunistically on
  any request, detect an `X-New-Token` response header in `ApiClient._postFlight`
  next to the `x-minimum-client-version` check (`api_client.dart:~654`) and swap
  there.

### Old app (`/Users/hillel/Code/admin-portal`, Redux)

- **Trigger:** periodic dispatch from app init (mirrors the existing refresh tick).
- **Swap:** persist the new token to SharedPreferences (`kSharedPrefToken` =
  `checksum`, base64-obscured — same path as `app_middleware.dart:451/537`) and
  update Redux credentials via the path `_createDataRefreshed` already uses
  (`app_middleware.dart:532-539`).
- **Optional header path:** detect `X-New-Token` in `web_client._checkResponse`
  (the version-negotiation block, `web_client.dart:236-259`) and dispatch a small
  `TokenRotated` action that persists + updates Redux credentials.

## Verification

- Timer rotates with the app left open (no manual action); new token persisted
  and used on subsequent requests (new app: `kAuthTokensKey`; old app: `checksum`).
- App offline/closed past the rotation window reconnects with its old token,
  rotates, and is **not** force-logged-out.
- An in-flight request and a queued outbox row issued under the old token still
  succeed during the grace window.
- Multi-company: each company's token rotates independently.
- Header path (if built): a response with `X-New-Token` swaps the token without a
  401 or logout.

## Checklist

- [ ] Server ships `POST /api/v1/tokens/rotate` (backend partner)
- [ ] Confirm final response shape + grace/no-hard-expiry behavior
- [ ] New app: trigger + swap
- [ ] Old app: trigger + swap
- [ ] (Optional) `X-New-Token` header path
- [ ] Update `FEATURES.md` row when shipped
