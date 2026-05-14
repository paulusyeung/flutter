# Probing the demo API

Companion to CLAUDE.md § Reference points. The main file lists the legacy code pointers; this doc carries the live-server probe workflow.

`demo.invoiceninja.com` accepts canned credentials for unauthenticated read probes — useful for confirming filter shapes and response payloads against a live server before wiring code to expectations:

```
curl "https://demo.invoiceninja.com/api/v1/clients?per_page=1" \
  -H "Content-Type: application/json" \
  -H "X-API-SECRET: password" \
  -H "X-API-TOKEN: TOKEN" \
  -H "X-Requested-With: XMLHttpRequest"
```

Dataset is seeded with ~27 clients and resets periodically. Use it for read probes; don't run writes against it from automated tests. Doc claims that don't match live behavior should defer to what the live server actually does — e.g. `name=Bob*` is documented as a wildcard but is in fact matched literally; the server does an implicit SQL `LIKE %value%` on `name` and ignores `*`.

**Heads-up on password-gated GETs**: `/api/v1/users/{id}?include=company_user` returns **HTTP 412** with `{"message":"Invalid Password"}` unless the request carries `X-API-PASSWORD-BASE64`. That's the server-side signal `ApiClient._raiseFromResponse` maps to `PasswordRequiredException`. Read the auth user record from `/refresh` instead; reserve `GET /users/{id}` for password-primed flows.

## Demo login credentials

For probes that need a real session token (anything beyond the unauthenticated read probes above — `/refresh`, `/login`, write endpoints, password-gated reads):

```
URL:      demo.invoiceninja.com
Email:    demo@invoiceninja.com
Password: Password0
```

`POST /api/v1/login` with those credentials in the JSON body returns the standard `LoginResponseApi` envelope; add `?include_static=true&first_load=true` to get the `static` blob and bundled per-company reference data alongside. Example:

```
curl -s -X POST "https://demo.invoiceninja.com/api/v1/login?include_static=true&first_load=true" \
  -H "Content-Type: application/json" \
  -H "X-Requested-With: XMLHttpRequest" \
  -d '{"email":"demo@invoiceninja.com","password":"Password0"}'
```

The shared demo account is reset periodically. Don't lean on data persistence across runs.
