# Invoice Ninja — Flutter App (rebuild)

This is a clean-room rebuild of `/Users/hillel/Code/admin-portal`. Read this file before changing anything substantial.

## What this app is

A multi-platform Invoice Ninja admin client. Replaces the Redux-based admin-portal with three goals:
1. **Page-by-page data loading** — never `per_page=999999`.
2. **True offline editing** — every change lands in a local mutation outbox and syncs when online.
3. **No Redux** — plain Flutter state management.

Plus two non-negotiables carried from admin-portal:
- App restart restores exactly where the user left off (route, company, filters).
- Multi-company support.

## Platform targets

- **Now**: iOS, macOS.
- **Later**: Android, Windows, Linux.
- **Never**: Web (the `web/` folder is deliberately absent).

When adding back Android/Windows/Linux, regenerate with `flutter create --platforms=android,windows,linux`. Notes: Android needs `<uses-permission android:name="android.permission.INTERNET" />`; Linux requires `libsecret-1-dev` for `flutter_secure_storage`; Windows uses DPAPI per-user.

### macOS setup notes

The sandboxed macOS build needs four entitlements (see `macos/Runner/{DebugProfile,Release}.entitlements`):

- `com.apple.security.app-sandbox` — on by default.
- `com.apple.security.network.client` — outbound HTTP. Added in M1.1.
- `keychain-access-groups` — required by `flutter_secure_storage`. Value: `$(AppIdentifierPrefix)com.invoiceninja.admin`. Without it, the first `auth.login` throws `PlatformException -34018 (errSecMissingEntitlement)`.
- `com.apple.security.files.user-selected.read-write` — required by `image_picker` + `file_picker` (Company Details: Logo, Documents tabs). Without it the sandbox blocks the open panels and the plugins log `NSCocoaErrorDomain` errors.

Any new package that touches Keychain (OAuth, biometric login, etc.) is already covered by the keychain entitlement — don't add another. If we ever change the bundle id from `com.invoiceninja.admin`, update the `keychain-access-groups` entries to match.

### Dev-machine login pre-fill

To avoid retyping credentials on every fresh launch:

1. Copy `dev.json.example` → `dev.json` (gitignored) and fill in `IN_DEV_EMAIL` / `IN_DEV_PASSWORD`.
2. Run with `flutter run --dart-define-from-file=dev.json`.

The pre-fill happens in `LoginViewModel`'s constructor and is guarded by `!kReleaseMode`, so debug *and* profile builds prefill (handy for perf testing) while release builds tree-shake the branch — credentials cannot leak into a shipped binary even if you accidentally pass the file at build. Keys are `String.fromEnvironment` reads in `lib/app/env.dart` (`Env.devEmail`, `Env.devPassword`).

## Architecture — at a glance

Layered MVVM:

```
View (StatelessWidget)
  └─ ViewModel (ChangeNotifier)
       └─ Repository (single source of truth for an entity)
            ├─ Drift database (local state, watched by streams)
            ├─ Outbox (mutation queue)
            └─ Service (HTTP client → /api/v1/...)
```

- **DI**: `Services` (`lib/app/services.dart`) is a plain bag of singletons built once in `main.dart` and exposed to the widget tree via `Provider<Services>.value`. Screens grab dependencies with `context.read<Services>()`; ViewModels take their repos by constructor injection.
- **Routing**: `go_router` with a `StatefulShellRoute.indexedStack` for the authenticated shell (NavigationRail on ≥600 px, NavigationBar on <600 px).
- **State**: `ChangeNotifier` + `ListenableBuilder` in views. **No Redux. No flutter_bloc. No Riverpod.** If you're tempted to add one, talk to the team first.
- **Models**: `freezed` + `json_serializable`. API DTOs in `lib/data/models/api/`, clean domain models in `lib/data/models/domain/`. Domain models are what flow up to ViewModels.
- **Persistence**: Drift on top of SQLCipher (`sqlcipher_flutter_libs`). The DB file is encrypted at rest with a per-install 256-bit key held in `flutter_secure_storage` under `invoiceninja.db.key.v1`. Drift's reactive streams drive the UI — the network layer only writes; the UI only reads from Drift. Tests use `NativeDatabase.memory()` (unencrypted, no PRAGMA key) — SQLCipher's binary accepts both.
- **HTTP**: `package:http`. Large list parses go through `compute()`.

## Design system (v2)

Token-based visual language. The source of truth and the Dart port are deliberately split:

- `docs/design/v2/tokens.jsx` — **the source of truth** for colors, radii, shadows, type, button variants. When in doubt about a value or pattern, read this file first.
- `docs/design/v2/{screens,patterns,design-canvas}.jsx` + `index.html` — reference mockups (sidebar, dashboard, invoices list, mobile). Open `index.html` in a browser to view the canvas.
- `lib/app/design_tokens.dart` — Dart port. Read tokens via `context.inTheme.<name>` (e.g. `context.inTheme.surface`). **Do not introduce new color constants** outside `InTheme` — that's how light/dark drift starts. `InRadii` / `InSpacing` are static (brightness-independent).
- `lib/app/theme.dart` — wires `InTheme.light` / `InTheme.dark` into `ThemeData` per brightness.

When styling a page: read `tokens.jsx`, reuse `InTheme`, and prefer `Theme.of(context).colorScheme` + `context.inTheme` over hardcoded `Color(0x…)`.

**Pair related action buttons side-by-side**, not stacked. When two or more buttons act on the same content (e.g. Upload + Remove, Save + Cancel), render them in a `Row` with `SizedBox(width: InSpacing.md)` between them. Only fall back to `Wrap` if the labels can plausibly overflow on common widths (e.g. 3+ buttons, or long localized labels in a narrow container). This holds for dialogs too — **Cancel sits next to the primary action, never above it**.

**Default to side-by-side dialog actions.** When you place a `FilledButton`, `FilledButton.tonal`, or `OutlinedButton` inside `AlertDialog.actions` (or any `Row`), it **must** carry a per-call `minimumSize` override:

```dart
FilledButton(
  style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
  onPressed: ...,
  child: Text(...),
),
// OutlinedButton uses Size(64, 40)
```

Why: the themes in `lib/app/theme.dart` set `minimumSize: Size.fromHeight(44)` (resp. `Size.fromHeight(40)`) = `Size(double.infinity, …)`, which is the right default for column-stacked form buttons (login, settings) but is wrong in any horizontal context. Without the override, in a `Row` it crashes layout (non-flex child gets unbounded `maxWidth` and the button's infinite `minimumSize.width` violates `BoxConstraints`), and in `AlertDialog.actions` the `OverflowBar` silently wraps to vertical — the user reads "Cancel" / "Discard" stacked above a full-width primary button, which is the wrong UX default.

Canonical example: `lib/ui/features/shell/widgets/company_picker.dart:118-125`. The inline comments in `lib/app/theme.dart` say the same thing — read them before debugging stacked dialog buttons.

## The two ideas that shape everything

### 1. Pagination + infinite scroll

Lists fetch one page at a time (50 rows default). The ViewModel calls `repo.ensurePageLoaded(N)` near the scroll edge; the repo writes the page to Drift; the UI reacts via the watch stream.

`per_page=999999` is forbidden. A CI lint test grep-fails the build if the literal appears in `lib/`.

### 2. Offline-first with a mutation outbox

Every write goes through this pipeline:
1. Repository writes the change to Drift (`is_dirty = true`). UI updates instantly via stream.
2. Repository appends a row to the `outbox` table with an `idempotency_key`, `payload`, `mutation_kind`, and (if needed) `requires_password`.
3. `SyncRepository` drains the outbox in FIFO order **per (company, entity_type)**. Retries follow exponential backoff (5s → 30s → 2m → 10m, dead after 5 attempts).
4. On success, the row is removed; the server response upserts into Drift.
5. On `422`: row marked `dead` — shown on the Outbox screen for user action.
6. On `409` or stale-data: emits `Conflict` → `ConflictResolutionSheet` modal.
7. On `403 password-required`: emits `PasswordRequired` → `ConfirmPasswordSheet`.

**Offline create uses temp IDs** (`tmp_<uuid>`). When the server assigns a real ID, an `id_remap` row is written and any pending outbox payloads referencing the temp ID are rewritten before send. `Repository.watch(id)` resolves through `id_remap` so an open detail screen survives the swap without a URL change.

## Project layout

```
lib/
├── main.dart, app/            # bootstrap, DI, router, theme, logging, version, env
├── data/db/                   # Drift database + DAOs + tables/
├── data/services/             # api_client.dart + per-entity *_api.dart
├── data/repositories/         # one per entity + auth + sync + settings + statics + drafts
├── data/models/api/, domain/  # freezed models
├── domain/                    # entity_type.dart, entity_registry.dart, sync/
├── ui/core/widgets/           # AppScaffold, TwoPaneLayout, EmptyState, ErrorView,
│                              # OfflineBanner, ConfirmPasswordSheet, SyncStatusBadge
├── ui/features/<feature>/     # auth, shell, clients, settings, sync
└── l10n/                      # localization.dart + supported_locales.dart
assets/i18n/                   # bundled translation JSONs (one per supported locale)
tools/import_transifex_zip.dart
```

## Adding a new entity (the Milestone 2+ pattern)

1. **API DTO**: `lib/data/models/api/<entity>_api_model.dart` — `@JsonSerializable`, mirror server JSON exactly.
2. **Domain model**: `lib/data/models/domain/<entity>.dart` — `@freezed`, plus `<Entity>.fromApi(...)`.
3. **Drift table**: `lib/data/db/tables/<entity>_table.dart` — id (TEXT PK, may be `tmp_`), `company_id`, `temp_id`, `updated_at`, `is_dirty`, `is_deleted`, `archived_at`, indexed columns we list/filter/search by, `payload` JSON for the rest.
4. **DAO**: queries + watches. Use `CompanyScopedDao` mixin.
5. **Service**: `<entity>s_api.dart` (plural — avoids colliding with the singular `*ApiModel` class) `extends BaseEntityApi<TList, TItem>` — supplies path + parsers only. M1 example: `ClientsApi`.
6. **Repository**: `<entity>_repository.dart extends BaseEntityRepository` — supplies DAO + entity-specific helpers (e.g. `watchForParent`). _Note: the base class is intentionally non-generic in M1; revisit generics in M2 when a second entity lands so we can tighten `applyCreateResponse` / `applyUpdateResponse` signatures._
7. **ViewModels**: `<Entity>ListVM`, `<Entity>DetailVM`, `<Entity>EditVM` — all `ChangeNotifier`.
8. **Views**: list, view, edit — reuse `ui/core/widgets` for empty/error/offline states.
9. **EntityRegistry**: add one entry — declares path, route, icon, parent/children, password-required mutations. The sync engine, outbox screen, permissions, and shell nav all read from here.
10. **Router**: add the routes to the StatefulShellRoute branch.
11. **DI**: register the service + repository in `app/di.dart`.
12. **Tests**: repository save/sync round-trip; mapper round-trip; conflict path.

## Sync — non-obvious rules

- Outbox FIFO is **per company, strict global id order** in M1 (only one entity type exists). The plan's stronger "per (company, entity_type)" guarantee is needed when M2+ introduces cross-entity references with retry-driven head-of-line blocking — revisit `OutboxDao.nextReady` then. Today the simpler ordering naturally satisfies "a client must be created before an invoice referencing it" because the client's outbox row has a lower autoincrement id.
- Every outbound request sends `Idempotency-Key: <uuid from the outbox row>` so retries are safe. The key is generated once when the row is created and never regenerated.
- Logout / company-switch with pending non-dead outbox rows **prompts** the user (sync now / discard / cancel). Never silently drops user data.
- Destructive ops (delete, purge, password change) require the server's `X-API-PASSWORD-BASE64` header. Password is captured by `ConfirmPasswordSheet` and held in a short-lived in-memory cache (5 min).
- 401 responses force `AuthRepository.logout()` and a redirect to `/login`. **Single-flight**: parallel 401s wait on the same logout future, never trigger N logouts.
- The `x-minimum-client-version` response header is checked on every request; below threshold throws `ClientTooOldException` and shows a "please update" screen.
- 422 validation errors carry `Map<String, List<String>> fieldErrors`. Edit forms surface these inline.
- **409 conflicts** are parked far in the future (1 year) instead of auto-retried — auto-retry would just re-hit the same conflict. The `ConflictResolutionSheet` either re-enqueues a fresh mutation (and discards the parked row) or discards it outright.
- **404 on outbox drain** is treated as a conflict: the entity was deleted server-side while we held a pending mutation locally. The same `Conflict` path applies — the resolution sheet offers "delete locally" / "recreate" rather than silently retrying. Without this, a `delete`+`update` race against another device would loop forever.
- **Server-side list ordering is assumed ascending `updated_at`** — the keyset cursor in `ApiClient.getList` reads `data.last` and treats it as the high-water mark. Matches Invoice Ninja's default list endpoints (`admin-portal/lib/data/web_client.dart`).
- The local `is_dirty` flag is **layered onto the domain `Client`** in `ClientRepository._fromRow` — `Client.fromApi` defaults to `false`, and the repo overlays the value from the Drift row. Without this overlay, an unsaved edit shows up as clean after app restart.

## Localization

- Source of truth: **Transifex** (`explore.transifex.com/invoice-ninja/invoice-ninja`).
- Files in the zip are PHP arrays (`textsphp-<locale>.php`).
- `tools/import_transifex_zip.dart <zip>` parses those PHP files for locales in `kSupportedLocales` and writes `assets/i18n/<locale>.json`.
- Workflow per release: download zip → run the importer → commit the changed JSONs.
- Runtime: `Localization` loads the active locale's JSON from `rootBundle`. English is always loaded as a fallback. There is **no** server fetch and **no** override table — the bundle is the only source.
- Adding a locale = (a) add it to `kSupportedLocales`, (b) re-run the importer.

## Coding conventions

- **No Redux. No bloc. No Riverpod.** `ChangeNotifier` only.
- **No `per_page=999999`.** Enforced by a CI test (greps `lib/`).
- **Money is `Decimal`, never `double`.** Enforced by a CI test (greps entity models).
- **Format money / dates / addresses through `Formatter`** in `lib/utils/formatting.dart`. Don't reach for `NumberFormat` directly for money — `Formatter.money(amount, clientCurrencyId: ...)` runs the per-client → company currency cascade (incl. the Euro country-separator override) and renders symbol-vs-code per company setting. Build a `Formatter` once per screen via `services.formatterFor(companyId)` and pass it down. Parse user input via `parseDecimal(input, useCommaAsDecimalPlace: ...)`. **User-visible dates must always go through `Formatter.date(date.toIso())`** so they honor the company's `date_format_id` — never render `Date.toIso()`, `DateFormat`, or `MaterialLocalizations.formatMediumDate` directly. `toIso()` (`YYYY-MM-DD`) is for storage, API payloads, and Drift keys only.
- **Date-only is the custom `Date` type; `DateTime` is for timestamps only.** Mixing them silently breaks invoice math.
- **Drift is the only thing the UI reads from.** The network writes to Drift; the UI watches Drift. Never read API responses straight into UI state.
- **Every write goes through the outbox.** Repositories never call mutation endpoints directly.
- **Every list query is scoped by `company_id`.** Use `CompanyScopedDao` — direct table access bypassing the DAO fails a lint check.
- **Idempotency keys are stable across retries** — generated when the outbox row is created, reused on every retry.
- **401 handling is single-flight** (`synchronized` mutex). Don't let parallel requests trigger N logouts.
- Models are immutable (`freezed`). Use `copyWith` for edits.
- Repositories return **streams** for "watch" methods and **futures** for "ensure"/mutation methods. ViewModels expose `ValueListenable`-style state.
- Views are `StatelessWidget` whenever possible. Side effects go in the ViewModel.
- Avoid `setState` inside ViewModel-backed features.
- **Imports**: always `package:admin/...`, never relative (`../`, `./`, or bare). Enforced by `always_use_package_imports` in `analysis_options.yaml`. Run `dart fix --apply` if a session slips up.
- Run `dart run build_runner watch --delete-conflicting-outputs` during development.
- Format with `dart format .`; analyze with `flutter analyze`.

## Widget previews

The five widgets in `lib/ui/core/widgets/` (`EmptyState`, `ErrorView`, `StatusPill`, `LinkText`, `HoverHighlight`) carry `@Preview` annotations that wire through `appPreviewTheme()` in `widget_preview_support.dart`, so previews render against the real `InTheme` tokens — not Material defaults. Launch via the IDE's "Flutter Widget Preview" tab or `flutter widget-preview start` from the project root. Add new previews to design-system widgets only — feature screens depend on `Services` via `Provider` and aren't preview-friendly without scaffolding.

## Rich text editing

`lib/ui/core/widgets/markdown_text_field.dart` is the shared WYSIWYG editor for markdown-bearing settings (e.g. email/invoice template overrides). It wraps `super_editor` and `super_editor_markdown` — both pulled from a pinned git ref via `dependency_overrides` so the editor and markdown serializer stay on the same monorepo HEAD.

Conventions when wiring it up:
- **One-way data flow.** Parent owns the markdown string and feeds `initialValue` + `externalValueKey`. The widget debounces edits (default 300 ms) and emits the serialized markdown through `onChanged`. There is no two-way controller — to force a reseed after an external write (e.g. an override toggle resets the field to a cascaded parent value), change `externalValueKey`. The `(apiKey, value, isOverridden)` hash works well for the overridable-settings pattern; see `lib/ui/features/settings/widgets/overridable_markdown_field.dart`.
- **Server content is safe by construction.** `super_editor` deserializes markdown into Flutter's widget AST — there is no HTML/JS execution context, so a hostile server payload can only produce styled text/lists/formatting, never break out. The `_sanitize` helper additionally strips `<p>`, `<div>`, and `<br>` residue carried over from the legacy Quill data in admin-portal.
- **No new editor instances.** Don't reach for `TextField` + markdown post-processing for a free-text field that needs formatting — reuse `MarkdownTextField` so the toolbar / focus-flush / dispose semantics stay consistent.

## Integration tests

`integration_test/app_smoke_test.dart` boots the real `InvoiceNinjaApp` with in-memory Drift + `InMemoryTokenStorage` and asserts the login screen renders. The test guards the DI graph, router, theme, and localization wiring — bugs in any of those break boot, which unit tests miss. Run on a device with:

```
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_smoke_test.dart
```

The login submit button has `ValueKey('login_submit')` so the test stays locale-independent; add similar keys when extending the test to cover new flows.

## Adding entities — the generic stack does most of it

There are three layers that you almost never override:
- `BaseEntityApi<TList, TItem>` — list/get/create/update/delete/action with the standard headers, idempotency keys, and error parsing. `<Entity>Api` only supplies the path and the parsers.
- `BaseEntityRepository<TDomain, TEntry>` — Drift round-tripping + outbox writing. `<Entity>Repository` only supplies the DAO and any entity-specific helpers (e.g. `watchForParent`).
- `EntityRegistry` — one entry per entity, declaring path, route, icon, parent/children, password-required mutations.

The sync engine, the outbox screen, the permissions check, and the shell navigation are all driven by the registry. Adding `Invoice` is: write `invoice_api_model.dart`, `invoice.dart`, `invoice_table.dart`, `invoice_api.dart`, `invoice_repository.dart`, the views, and one `EntityRegistry` entry. Don't reinvent sync, outbox handling, conflict surfacing, or permissions per entity.

## Settings search catalog

`lib/ui/features/settings/settings_search_catalog.dart` is the single source of truth for both the settings sidebar layout (`kSettingsSections`) and the in-app settings search (`kSettingsSearchCatalog`). Whenever you add, rename, or remove a user-facing field on any screen under `lib/ui/features/settings/views/**`, update the matching section's entry in `kSettingsSearchCatalog` so the field is discoverable via search.

- Section keys are the route slugs (e.g. `company_details`, `online_payments`, `subscriptions`).
- Field entries are **localization keys** (not rendered labels) — search lowercases the resolved string per locale, so this stays locale-correct.
- Adding a brand-new settings section means adding both a `SettingsSectionDef` entry and a `kSettingsSearchCatalog` entry; the sidebar tile and the search index come from the same file.

## Reference points

Three read-only sources to mirror, never copy from:

- **`/Users/hillel/Code/admin-portal`** — the previous Flutter (Redux) admin app:
  - `lib/data/models/client_model.dart` — Client field set.
  - `lib/data/web_client.dart` — header set (lines 213-231), version negotiation (245-258), demo mode (31, 266).
  - `lib/redux/auth/auth_middleware.dart` (102-120) — login response envelope.
  - `lib/redux/static/static_state.dart` — shape of the `/api/v1/statics` response.
  - `lib/redux/settings/settings_state.dart` (93-99) — settings cascade resolver.
  - `lib/data/models/entities.dart` — full EntityType enum + parent/child relationships.
- **`/Users/hillel/Code/react`** — the React web client. Useful as a second reference for entity shapes, request flows, and UI behaviors when admin-portal is unclear or out of date.
- **API reference** — <https://invoiceninja.github.io/docs/api-reference/invoice-ninja-api-reference>. Canonical for endpoint paths, query params, and response shapes. Check here before adding a new entity service.

### Probing the demo API

`demo.invoiceninja.com` accepts canned credentials for unauthenticated read probes — useful for confirming filter shapes and response payloads against a live server before wiring code to expectations:

```
curl "https://demo.invoiceninja.com/api/v1/clients?per_page=1" \
  -H "Content-Type: application/json" \
  -H "X-API-SECRET: password" \
  -H "X-API-TOKEN: TOKEN" \
  -H "X-Requested-With: XMLHttpRequest"
```

Dataset is seeded with ~27 clients and resets periodically. Use it for read probes; don't run writes against it from automated tests. Doc claims that don't match live behavior should defer to what the live server actually does — e.g. `name=Bob*` is documented as a wildcard but is in fact matched literally; the server does an implicit SQL `LIKE %value%` on `name` and ignores `*`.

## The full plan

`~/.claude/plans/the-empty-flutter-warm-milner.md` has the complete design rationale, alternatives considered, verification matrix, and step-by-step milestone breakdown. Read it before significant changes.
