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

**Always use rounded rectangles, never pills.** The v2 design system rounds buttons, chips, segmented controls, snackbars, etc. with `RoundedRectangleBorder(borderRadius: BorderRadius.circular(InRadii.r2))` (or `.r1` / `.r3` per size) — never `StadiumBorder` and never `BorderRadius.circular(999)`. Material 3 defaults several widgets to pills (`SegmentedButton`, `Chip`, `FloatingActionButton.extended`), so `lib/app/theme.dart` registers the rounded shape on every relevant component theme (`filledButtonTheme`, `outlinedButtonTheme`, `segmentedButtonTheme`, `cardTheme`, `snackBarTheme`, `inputDecorationTheme`). New `SegmentedButton`s / `FilledButton`s etc. inherit the shape automatically — don't re-apply per call. If you introduce a Material widget not yet covered (e.g. `Chip`, `FloatingActionButton`), add its theme to `theme.dart` rather than overriding inline.

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

## Forms — Enter to save

Pressing **Enter** in a single-line text field submits the surrounding form (calls the same method the Save button would). Multi-line fields keep Enter for newlines — never submit from `maxLines > 1`.

Wiring: every edit/settings screen wraps its form body in `FormSaveScope` (`lib/ui/core/widgets/form_save_scope.dart`):

```dart
FormSaveScope(
  onSubmit: _onSave,     // same callback the Save button calls
  enabled: canSave,      // same flag — gates Enter while busy/invalid
  child: <form body>,
)
```

Reusable field widgets read the scope from their `onSubmitted` automatically — see `OverridableTextField` (`lib/ui/features/settings/widgets/overridable_text_field.dart`) and `ClientEditField` (`lib/ui/features/clients/widgets/edit/client_edit_field.dart`). Raw `TextField`s in new feature code should do the same:

```dart
final scope = widget.maxLines == 1 ? FormSaveScope.maybeOf(context) : null;
TextField(
  // ...
  textInputAction:
      widget.maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
  onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
)
```

Dialogs with a single text input + primary action: wrap the dialog body in `FormSaveScope` so Enter fires the primary action. Login's password field is wired explicitly (`_PasswordField` in `lib/ui/features/auth/views/login_screen.dart`) — it bridges email + password submit and doesn't use the scope.

## Forms — empty for blank numeric fields

Numeric edit fields seeded from a non-nullable `Decimal` must render **empty for zero**, not `"0"`. Forcing the user to clear a stray `0` before typing is the kind of micro-annoyance we explicitly avoid.

Use `decimalInputText(value)` (in `lib/utils/formatting.dart`) when feeding a `Decimal` into `EntityEditField`'s `initial:` (or any `TextEditingController`). Don't reach for `.toString()` directly. Reference: the price / cost / quantity fields on `lib/ui/features/products/views/product_edit_screen.dart`.

For money values where you want company-currency precision and locale-aware decimal separators, prefer `Formatter.inputMoney(value, currencyId: ...)` — it already returns `''` for zero. `Formatter.inputAmount(value)` is the same pattern for `num`-typed inputs without a forced precision.

## Forms — searchable pickers

Any dropdown bound to a long list (countries, currencies, languages, industries, timezones — anything past ~20 options) **must** support type-to-search. Defaults:

- **Plain pickers**: `SearchableDropdownField<T>` (`lib/ui/core/widgets/searchable_dropdown_field.dart`). Generic on the item type; takes `displayString` + `idOf` projections. Reference: Country on Client Edit (`lib/ui/features/clients/widgets/edit/client_edit_country_field.dart`), Industry on Company Details > Details (`lib/ui/features/settings/views/basic/company_details/company_details_screen.dart`), Currency on Dashboard filter (`lib/ui/features/dashboard/widgets/filters/settings_popover.dart`).
- **Settings pickers with cascade-override**: `OverridableSearchableDropdownField<T>` (`lib/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart`). Same shape as `OverridableDropdownField` (`apiKey`, `value` as `String?`, 422 field-error display, `OverridableField` wrapper at group/client level) — use this on settings pages. Reference: Currency / Language / Country on Localization (`lib/ui/features/settings/views/basic/localization/localization_screen.dart`), Country on Company Details > Address (`lib/ui/features/settings/views/basic/company_details/address_screen.dart`).

Do **not** introduce new `DropdownButtonFormField`s for long lists — they have no keyboard search and force scroll-hunting (~250 countries × no search = a bad screen). `DropdownButtonFormField` is fine for short, fixed enums (~10 items max — Classification, Size, Custom Field Type). When in doubt, use the searchable variant.

## Settings screens — two reference shapes

Most new settings panels should look like **Company Details** or **Device Settings** — never like User Details. Both reference shapes are FormSection-card layouts inside `SettingsFormShell(sections: [...])`; the only difference is whether they're VM-backed and cascade-aware.

**Decision tree (5-second routing for a new screen):**

- Field writes to server `company.settings.*` → **Company Details style** + `CascadeSettingsScaffold` + `Overridable*` widgets.
- Field writes to server `company.*` (top-level) → **Company Details style** + `SettingsPageScaffold` + plain widgets.
- Field writes only to a local controller (theme, locale, biometric, …) → **Device Settings style** + `SettingsScreenScaffold`, no VM.

### Company Details style (default for anything that touches the server)

Use this for any setting whose value lives on the company (or cascades down to group/client). Compose:

- **Cascade-aware (fields on `company.settings.*`)** → wrap in `CascadeSettingsScaffold` (`lib/ui/features/settings/widgets/cascade_settings_scaffold.dart`). It picks the right VM for the active `SettingsLevelController` (your factory at company scope, the shared `ClientSettingsDraftViewModel` at client scope), delegates VM lifecycle (build, load, dispose, company-switch rebuild) to `SettingsCompanyScopedHost`, and hands the result to `SettingsPageScaffold`. Caller supplies just `titleKey`, `companyVmFactory`, and `body`. Reference: `lib/ui/features/settings/views/basic/localization/localization_screen.dart`.
- **Company-only (also touches top-level `Company` fields like `sizeId` / `industryId`)** → wrap in `SettingsPageScaffold<V>` directly with a company-only VM. The cascade scaffold isn't appropriate because the client scope wouldn't apply to top-level Company fields. Reference: `lib/ui/features/settings/views/basic/company_details/company_details_shell.dart` (which uses `SettingsCompanyScopedHost` directly because it needs to own its own `TabController` outside the scaffold).
- **Action-only sub-shape (no editable fields)**: some Company Details tabs render server state and trigger uploads instead of editing fields — `documents_screen.dart` and `logo_screen.dart` are the precedent. They're still Company Details style: same `SettingsFormShell` + `FormSection` chrome, same VM, same Save button (just no contribution to it). The async upload writes outside the outbox via `services.company.upload*()` because file uploads aren't replayable; that's a deliberate exception, not a third style.
- Body in either case: `SettingsFormShell(sections: [FormSection(title: ..., children: [...]), ...])`. The shell handles centering + max-width + padding; `FormSection` is the bordered card with header + divider + content column. **`FormSection` auto-inserts `InSpacing.lg` between adjacent children** — drop the manual `SizedBox(height: InSpacing.lg)` interleaves. Pass `spacing: 0` only when the section owns its own row separators (e.g. a `Divider` between tiles, like `preferences_screen.dart`).
- Field widgets — pick by **where the field is stored**:
  - `company.settings.*` (cascade-aware) → `OverridableTextField` / `OverridableDropdownField` / `OverridableSearchableDropdownField` / `OverridableMarkdownField`. They render the override checkbox at group/client scope and hide it at company scope, so one call site covers both.
  - `company.*` (top-level: `sizeId`, `industryId`, `customFields`, `legalEntityId`, …) → plain `DropdownButtonFormField` / `SearchableDropdownField` / `TextField` that call `vm.updateCompany((c) => c.copyWith(...))`. These do not cascade and do not get the override wrapper. Group cascade-aware and company-only fields into separate `FormSection`s when they're on the same screen — Company Details "Details" tab is the canonical example.

### Device Settings style (for anything that doesn't touch the server)

Use this for app-local options: theme, language preference, "download all data" actions, biometric toggle. Same `SettingsFormShell(sections:)` + `FormSection` chrome — but no VM, no cascade, no Save button. Controls write directly to local stores (`ThemeController`, `LocaleController`, `BiometricService`, etc.). Compose `SettingsScreenScaffold` (lower-level chrome, no VM machinery) at the root. Reference: `lib/ui/features/settings/views/basic/device_settings_screen.dart`.

### Anti-pattern: User Details ListView+ListTile shape

Do not introduce raw `ListView` + `ListTile` layouts (icon-leading row tiles, dividers between rows) for new settings panels. Even simple toggles or single actions belong inside a `FormSection` so the whole settings sidebar reads as one design system. The User Details and Preferences screens use FormSection cards now too — they're the right precedent, not the old pre-conversion shape.

A `ListTile` *itself* is fine when wrapped in a typed control widget (`ThemeTile`, `BiometricToggleTile`, `_LocaleTile` in Preferences) and dropped inside a `FormSection`. The anti-pattern is the unwrapped `ListView`-of-bare-`ListTile`s with no card chrome — that's what the old User Details screen was, and that shape doesn't come back.

### Decision rule

When adding a new settings sidebar entry, ask: **"Does this field write to the server (`/api/v1/companies/...` or similar)?"**

- **Yes**, and the field is on `company.settings.*` → Company Details style with `CascadeSettingsScaffold` + `Overridable*` widgets.
- **Yes**, and the field is on `company.*` → Company Details style with `SettingsPageScaffold` + plain widgets.
- **No** (device-local or session-only) → Device Settings style with `SettingsScreenScaffold`, no VM.
- Never the user-details ListTile shape.

If you're building a *custom* shell (e.g. tabbed like Company Details, or anything else where you can't reach for `CascadeSettingsScaffold` / `SettingsPageScaffold` directly), reach for `SettingsCompanyScopedHost` instead of re-rolling the company-switch listener inline. It owns the build-VM / dispose-on-switch / rebuild-against-new-tenant lifecycle that both reference shapes already share.

### Mixing both kinds of fields on one screen

When a single page touches *both* `company.settings.*` (cascade-aware) and `company.*` (top-level) fields — e.g. Company Details "Details" tab — do **not** use `CascadeSettingsScaffold`. The cascade scaffold swaps in `ClientSettingsDraftViewModel` at client scope, where `updateCompany` is a no-op (top-level fields don't apply per-client) — the UI would silently drop the user's edits to those fields. Use `SettingsPageScaffold<V>` directly with a company-only VM (`SettingsDraftViewModel` subclass), the way `CompanyDetailsShell` does. Group cascade-aware and company-only fields into separate `FormSection`s so the override-checkbox visibility lines up; reference: `_SizeField` and `_IndustryField` under the "business" section in `lib/ui/features/settings/views/basic/company_details/company_details_screen.dart`.

### Don't forget the search catalog

Every new settings page must contribute its field labels to `kSettingsSearchCatalog` (in `lib/ui/features/settings/settings_search_catalog.dart`) so they're discoverable from the sidebar search. Each tab/page also exports a `kFooSearchKeys` constant alongside its widget for colocation; the `search_catalog_consistency_test` enforces both. See the existing "Settings search catalog" section below for the mechanics.

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

## Data loading — bundled vs per-entity

Before adding a new module, decide how its data is fetched. There are two buckets:

- **Bundled with the company on auth.** `/login` and `/refresh` accept `first_load=true`, which makes the server include company-scoped reference data alongside each company in the response: tax rates, groups, designs, payment terms, expense categories, task statuses, subscriptions, schedulers, etc. The static catalog (currencies, countries, languages, industries, gateway types, date formats, …) is also returned in the auth envelope under `staticData` (request with `include_static=true`). `/refresh` already sends `first_load=true&include_static=true` — see the `refresh` call in `lib/data/repositories/auth_repository.dart`. When adding data that fits this bucket, consume it from the existing login/refresh response — do not write a separate fetcher.
- **Loaded by their own routes.** High-volume, user-browsable entities: clients, invoices, products, payments, expenses, tasks, projects, quotes, credits, vendors, purchase orders, recurring invoices, etc. These use the full `BaseEntityApi` + page-by-page + Drift + outbox stack documented under "Adding a new entity". Never try to bundle these into `first_load`.

Rule of thumb when adding a new entity:
- Small, mostly read, shared across the whole company, rarely paginated (≲ a few hundred rows total) → **bundled**, read from the login/refresh payload.
- The kind of list a user scrolls, searches, and filters → **own route**, full per-entity stack.

If you're unsure, check what the server returns when you hit `/api/v1/refresh?first_load=true&include_static=true` against the demo API — anything already present in that payload belongs in the bundled bucket.

## Adding a new entity (the Milestone 2+ pattern)

1. **API DTO**: `lib/data/models/api/<entity>_api_model.dart` — `@JsonSerializable`, mirror server JSON exactly.
2. **Domain model**: `lib/data/models/domain/<entity>.dart` — `@freezed`, plus `<Entity>.fromApi(...)`.
3. **Drift table**: `lib/data/db/tables/<entity>_table.dart` — id (TEXT PK, may be `tmp_`), `company_id`, `temp_id`, `updated_at`, `is_dirty`, `is_deleted`, `archived_at`, indexed columns we list/filter/search by, `payload` JSON for the rest.
4. **DAO**: queries + watches. Use `CompanyScopedDao` mixin.
5. **Service**: `<entity>s_api.dart` (plural — avoids colliding with the singular `*ApiModel` class) `extends BaseEntityApi<TList, TItem>` — supplies path + parsers only. M1 example: `ClientsApi`.
6. **Repository**: `<entity>_repository.dart extends BaseEntityRepository` — supplies DAO + entity-specific helpers (e.g. `watchForParent`). _Note: the base class is intentionally non-generic in M1; revisit generics in M2 when a second entity lands so we can tighten `applyCreateResponse` / `applyUpdateResponse` signatures._
7. **ViewModels**: `<Entity>ListVM`, `<Entity>DetailVM`, `<Entity>EditVM` — all `ChangeNotifier`.
8. **Views**: every screen wraps a generic scaffold. Don't reinvent Scaffold / AppBar / pagination / multiselect / dirty-guard — they're already there. The Clients and Products screens are the reference invocations.
   - **List screen** → wrap `EntityListScreenScaffold<T, VM>` (`lib/ui/core/list/entity_list_screen_scaffold.dart`) in a `StatelessWidget`. Required config: `titleKey`, `newRoute`, `newLabelKey`, `buildVm`, `sortOptions`, `searchFieldBuilder`, `tileBuilder`, `bulkActions` (list of `EntityListBulkAction` — match the `actionId` to a `BulkAction.id` registered on the VM). Optional hooks: `wantsFormatter: true` (entities that render money — wires `FormatterHostMixin` and feeds the resolved `Formatter` to the tile via `EntityListTileOptions.formatter`), `emptyStateBuilder` (filter-aware empty copy), `wideColumnHeadersBuilder` (custom header row). The scaffold owns the wide bordered-card chrome + `EntityListColumnHeaders<T>`, the narrow stacked list, the FAB / drawer / hamburger ternaries, the multi-select AppBar swap, the company-switch listener, and the transient-notice snackbar pump.
   - **Detail screen** → `EntityDetailScaffold<T>` (`lib/ui/core/detail/entity_detail_scaffold.dart`). Supply VM + `bodyBuilder` + optional `actionsForItem`. Owns Scaffold + AppBar + empty / loading / error states.
   - **Detail screen body** — every entity-detail body opens with the same identity stack before its entity-specific cards. The chrome (avatar/tint/initials, timestamp rendering, pill ladder, FilledButton/OutlinedButton choice, OverflowView→"More" menu, `coming_soon` tooltip) lives in two shared core widgets. Per entity you only contribute a thin wrapper that maps your domain fields to the shared widget's parameters:
     - `EntityDetailHeader` (`lib/ui/core/detail/entity_detail_header.dart`) — takes resolved fields directly: `seedForAvatar`, `displayName`, optional `number`, `createdAt`, `updatedAt`, `isDeleted`, `isArchived`, `isDirty`, `formatter`. Each entity adds an `<Entity>DetailHeader` (~25 lines) that resolves the display-name cascade and the optional `#<n>` subtitle. The screen must `with FormatterHostMixin` so the header gets a real `Formatter`. Reference: `lib/ui/features/clients/widgets/detail/client_detail_header.dart` (3-step name cascade + number) and `lib/ui/features/products/widgets/detail/product_detail_header.dart` (single-field name, no number).
     - `EntityDetailActionsRow<A>` + `EntityActionItem<A>` (`lib/ui/core/detail/entity_detail_actions_row.dart`) — takes a `List<EntityActionItem<A>>` keyed by the entity's action enum. Each entity defines a public `<Entity>Action` enum that lists every action the legacy admin-portal exposed (edit / clone / new-X / archive / restore / delete / purge / …) and an `<Entity>DetailActionsRow` (~50 lines) that returns the item list. Mark the hero action with `isPrimary: true` (Edit, by convention) — it renders as `FilledButton`; the rest are `OutlinedButton`. Set `enabled: false` on placeholders; the shared widget wraps them in the `coming_soon` tooltip. Reference: `lib/ui/features/clients/widgets/detail/client_detail_actions_row.dart` and `lib/ui/features/products/widgets/detail/product_detail_actions_row.dart`.
     - The screen's `_onAction(item, action)` switch must list every enum case so a missing future action fails analysis instead of silently no-op'ing — wired branches do work, placeholder branches `break;` with the same comment Clients uses.
     - Optional `<Entity>DetailKpiStrip` / `<Entity>DetailCardsGrid` / `<Entity>DetailTabs` — entity-specific. Add only when there are numbers / relationships worth pulling above the fold (Clients has all three; Products has none yet — a single Details card sits directly under the header).
   - **Edit / create screen** → `EntityEditScaffold<T>` (`lib/ui/core/edit/entity_edit_scaffold.dart`). Owns Scaffold + AppBar (Save button + spinner) + `FormSaveScope` for Enter-to-save. For 422 errors, pass `SaveFailedBanner(vm: vm, onDiscard: …)` as `topBanner`.
   - **Per-entity widgets you DO write** (every other piece is generic):
     - `<Entity>ListTile` — responsive: wide table row (column cells aligned to slots in `entity_list_constants.dart`) + narrow stacked card. Must accept `isLast` and render its own bottom border (the scaffold uses `ListView.builder`, not `ListView.separated`). See `client_list_tile.dart` / `product_list_tile.dart` for the anatomy. Use `LeadingSelectSlot` (`lib/ui/core/widgets/leading_select_slot.dart`) for the leading avatar/checkbox cell — it scopes hover-reveal to the 32×32 slot, owns the selection-mode swap, and keeps cursor + footprint consistent across entities. Do **not** wrap the row in a `MouseRegion` for selection purposes — that's the row-wide hover bug the widget exists to prevent.
     - `<entity>_filter_keys.dart` — returns the `List<FilterKey>` the token search exposes. At minimum register `IsFilterKey` (from `lib/ui/core/list/search/is_filter_key.dart`); it operates on `vm.states` and is shared across entities.
     - `<Entity>TokenSearchField` — thin `StatelessWidget` that wraps `TokenSearchField` (`lib/ui/core/list/search/token_search_field.dart`) with the entity's filter keys and a `search_<entity>_or_filter_hint` localization key.
9. **Entity module spec**: add one `EntityModuleSpec` entry to `kWiredEntityModules` in `lib/app/entity_modules.dart` — declares wireName, apiPath, routePath, icons (filled + outlined), labelKey, sidebarOrder, the four screen builders, and any `extraChildRoutes` (e.g. `/clients/:id/statement`). The router iterates this list to build its branches and the sidebar reads it for the nav rail — neither file needs an entity-specific touch. If your entity already has a `disabled: true` placeholder in `kDisabledEntityModules`, move it to `kWiredEntityModules` instead of adding a second entry.
10. **DI**: in `lib/app/services.dart`'s `Services.build`, construct the entity's `<Entity>sApi` + `<Entity>Repository` + `<Entity>SyncDispatcher` and register the dispatcher in the `dispatchers` map. The wired-modules loop picks it up automatically. Add a typed getter on `Services` (`final InvoiceRepository invoices;`) for convenient call-site reads.
11. **Branch order**: if this is the next *enabled* entity (typically a previously-disabled placeholder graduating), append an `EntityBranch(EntityType.<entity>)` to `kBranchOrder` in `entity_modules.dart`. Append — never reorder — so persisted nav state keeps working. Disabled entities don't appear in `kBranchOrder` because they have no routes to navigate to.
12. **Actions + translation keys**: the entity's `<Entity>Actions.itemsFor` should compose from the standard factories (`editActionItem`, `archiveActionItem`, `restoreActionItem`, `deleteActionItemPlaceholder`, `purgeActionItemPlaceholder` in `lib/ui/core/detail/standard_entity_action_items.dart`); the dispatch should call `StandardEntityActions.archive/restore/delete/purge` for those four cases. Both helpers derive translation keys from the entity's `wireName` — supply the 7 required keys in `assets/i18n/en.json` (or `_app_pending.json` for app-local strings not yet in Transifex): `<wireName>`, `<wireName>s` (plural label), `new_<wireName>`, `edit_<wireName>`, `archived_<wireName>`, `restored_<wireName>`, `deleted_<wireName>`. `purged_<wireName>` is optional. The `entity_translation_completeness_test` fails the build when any of the 7 is missing.
13. **Tests**: repository save/sync round-trip; mapper round-trip; conflict path.

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
- Models are immutable (`freezed`). Use `copyWith` for edits.
- Repositories return **streams** for "watch" methods and **futures** for "ensure"/mutation methods. ViewModels expose `ValueListenable`-style state.
- Views are `StatelessWidget` whenever possible. Side effects go in the ViewModel.
- Avoid `setState` inside ViewModel-backed features.
- **Imports**: always `package:admin/...`, never relative (`../`, `./`, or bare). Enforced by `always_use_package_imports` in `analysis_options.yaml`. Run `dart fix --apply` if a session slips up.
- Run `dart run build_runner watch --delete-conflicting-outputs` during development.
- Format with `dart format .`; analyze with `flutter analyze`.

## Widget previews

The four widgets in `lib/ui/core/widgets/` (`EmptyState`, `ErrorView`, `StatusPill`, `LinkText`) carry `@Preview` annotations that wire through `appPreviewTheme()` in `widget_preview_support.dart`, so previews render against the real `InTheme` tokens — not Material defaults. Launch via the IDE's "Flutter Widget Preview" tab or `flutter widget-preview start` from the project root. Add new previews to design-system widgets only — feature screens depend on `Services` via `Provider` and aren't preview-friendly without scaffolding.

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

There are five layers that you almost never override:
- `BaseEntityApi<TList, TItem>` — list/get/create/update/delete/action with the standard headers, idempotency keys, and error parsing. `<Entity>Api` only supplies the path and the parsers.
- `BaseEntityRepository<TDomain, TEntry>` — Drift round-tripping + outbox writing. `<Entity>Repository` only supplies the DAO and any entity-specific helpers (e.g. `watchForParent`).
- `EntityRegistry` (`lib/domain/entity_registry.dart`) — one entry per entity, declaring path, route, icon, parent/children, password-required mutations, sidebar metadata, and the four screen builders. Populated at app start from `kWiredEntityModules` + `kDisabledEntityModules` in `lib/app/entity_modules.dart`. The router iterates `registry.branchOrder` to build its `StatefulShellRoute` branches; the sidebar iterates `registry.sidebarTop` to render its workspace section. Both files are entity-agnostic — adding an entity touches the module specs only.
- `GenericListViewModel<T>` — the list screen's state: pagination, search, filter, sort, multiselect, column persistence, bulk-action dispatch. `<Entity>ListViewModel` only plugs in the repo, column registry, and bulk-action predicates.
- `EntityListScreenScaffold<T, VM>` — the list screen's chrome: Scaffold, AppBar (normal + selection variants), wide bordered-card table, narrow stacked list, FAB / drawer / hamburger ternaries, company-switch listener, transient-notice pump, formatter wiring. Plus `EntityDetailScaffold<T>`, `EntityEditScaffold<T>`, and `buildEntityRouteBlock(...)` from `lib/app/router.dart`. `<Entity>ListScreen` becomes a ~80-line `StatelessWidget` of config + a single `_onAction` helper.

The sync engine, the outbox screen, the permissions check, the router branches, and the shell navigation are all driven by the registry. Adding `Invoice` is: write `invoice_api_model.dart`, `invoice.dart`, `invoice_table.dart`, `invoices_api.dart`, `invoice_repository.dart`, `invoice_sync_dispatcher.dart`, `invoice_list_view_model.dart`, `invoice_columns.dart`, `invoice_list_tile.dart`, `invoice_filter_keys.dart`, `invoice_token_search_field.dart`, `invoice_detail_header.dart` (thin wrapper over `EntityDetailHeader`), `invoice_actions.dart` (action enum + `InvoiceActions.itemsFor`/`dispatch` — uses the standard action factories), the three thin screen widgets (each wraps a scaffold), and finally **one entry in `kWiredEntityModules`** plus the api/repo/dispatcher block in `services.dart`. The router, sidebar, sync engine, outbox screen, permissions, and saved views all light up automatically.

### Standard action helpers (Phase C of the 15-entity refactor)

Don't reimplement the archive/restore/delete/purge dispatch or the Edit/Archive/Restore/Delete/Purge `EntityActionItem` set per entity:

- `StandardEntityActions.archive/restore/delete/purge` (`lib/ui/core/detail/standard_entity_actions.dart`) — wraps `runMutationWithNotify` and derives the success toast key from `wireName` (`archived_<wireName>` etc.). The entity's `<Entity>Actions.dispatch()` calls these for the four universal mutations; only entity-specific actions (Client's `viewStatement`/`settings`, future Invoice's `email`/`markPaid`) need bespoke code.
- `editActionItem` / `archiveActionItem` / `restoreActionItem` / `deleteActionItemPlaceholder` / `purgeActionItemPlaceholder` (`lib/ui/core/detail/standard_entity_action_items.dart`) — factories that return `EntityActionItem<A>` with the right icon, label key, `isPrimary` flag, and (for archive/restore) the canArchive/canRestore visibility check. Use `?` collection-element syntax to spread the conditional results: `?archiveActionItem(...)`.

Reference: `lib/ui/features/clients/widgets/client_actions.dart` and `product_actions.dart`.

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
