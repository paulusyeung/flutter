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

## Quick Index

| When you're doing… | Look at |
|---|---|
| Adding a new entity | § Adding a new entity + `docs/adding-an-entity.md` |
| Adding / editing a settings screen | § Settings screens + `docs/settings-screens.md` |
| Wiring a form field, picker, or Enter-to-save | § Forms |
| Anything money / date / parsing | § Strict rules + § Forms |
| Dialog buttons rendering stacked | § Design system (v2) |
| Sync / outbox / 401-403-404-409-412-422 behavior | § Sync — non-obvious rules |
| Bundled vs per-entity data loading | § Data loading — bundled vs per-entity |
| Architecture, write pipeline, project layout | § Architecture — at a glance + `docs/architecture.md` |
| Localization / Transifex import | § Localization |
| Cross-checking against legacy admin-portal / React / API docs | § Reference points |
| macOS entitlement, dev login pre-fill, platform targets | `docs/setup.md` |
| Probing the demo API for live response shapes | `docs/probing-the-demo-api.md` |
| Server-side filter gaps / required API changes | `BACKEND.md` |
| Debugging a runtime error or stale outbox row | § Diagnostics log |
| Checking what's built vs what's left | `FEATURES.md` (kept current — see § Strict rules) |

## Strict rules

These are the rules that turn into bugs or CI failures if I forget them. Read this block first.

- **No Redux. No bloc. No Riverpod.** `ChangeNotifier` only. If you're tempted to add one, talk to the team first.
- **No `per_page=999999`.** Lists fetch one page at a time (50 rows default). The ViewModel calls `repo.ensurePageLoaded(N)` near the scroll edge; the repo writes the page to Drift; the UI reacts via the watch stream. A CI lint test grep-fails the build if the literal appears in `lib/`.
- **Money is `Decimal`, never `double`.** Enforced by a CI test (greps entity models).
- **Date-only is the custom `Date` type; `DateTime` is for timestamps only.** Mixing them silently breaks invoice math.
- **Drift is the only thing the UI reads from.** The network writes to Drift; the UI watches Drift. Never read API responses straight into UI state.
- **Auth user data flows in through `/refresh`, not `GET /users/{id}`.** `_persistAndActivate` upserts each `data[N].user` block into the `users` Drift table on every login and refresh. `GET /users/{id}` is 412-gated (password-required). Use `auth.refresh()` for a fresh session snapshot — it runs a full `_persistAndActivate`, so don't fire it for incidental work. Never call `UsersApi.get` from incidental paths.
- **Every write goes through the outbox.** Repositories never call mutation endpoints directly.
- **Every list query is scoped by `company_id`.** Use `CompanyScopedDao` — direct table access bypassing the DAO fails a lint check.
- **Idempotency keys are stable across retries** — generated when the outbox row is created, reused on every retry.
- **Format money / dates / addresses through `Formatter`** (`lib/utils/formatting.dart`). Use `Formatter.money(amount, clientCurrencyId: ...)` (runs the per-client → company currency cascade + Euro override) and `Formatter.date(date.toIso())` for user-visible dates (honors company `date_format_id`). Never render `Date.toIso()`, `DateFormat`, or `MaterialLocalizations.formatMediumDate` directly — `toIso()` is for storage/API/Drift keys only. Build the `Formatter` once per screen via `services.formatterFor(companyId)` and pass it down. Parse user input via `parseDecimal(input, useCommaAsDecimalPlace: ...)`.
- **No `vm.<entityName>` / `vm.<entityName>s` aliases on list / detail VMs.** Canonical accessors are `vm.item` (detail) and `vm.items` (list) — defined on the generic bases.
- **Imports**: always `package:admin/...`, never relative (`../`, `./`, or bare). Enforced by `always_use_package_imports` in `analysis_options.yaml`.
- **Never run integration tests locally** — they steal focus from the developer's session. Let CI run them; see § Integration tests.
- **`FEATURES.md` is the parity tracker — keep it current.** It compares every user-facing feature across React (`/Users/hillel/Code/react`), Flutter v1 (`/Users/hillel/Code/admin-portal`), and this rebuild. When you ship a feature that flips a row from ❌ or 🟡 to ✅ in the Flutter v2 column, update the row in the same PR. When you add a feature that didn't exist in React or v1, append a new row with `—` / `—` / `✅`. When you start a screen that's still incomplete, set it to 🟡 (UI scaffolded, not yet functional) rather than leaving it ❌. The file is hand-edited; don't try to generate it. Status legend: ✅ done end-to-end, 🟡 partial / scaffolded, ❌ not implemented, — N/A for that platform.
- **Pub packages OK; npm / pip / brew etc. require explicit approval.** Adding a Dart/Flutter dep via `pubspec.yaml` + `flutter pub get` is fine — that's the package surface this project ships through, and reviewers see the `pubspec.yaml` / `pubspec.lock` diff. For anything outside that (`npm install`, `pip install`, `brew install`, `gem install`, `cargo add`, system-level installers) stop and ask before running. The risk is a stray tool sneaking onto the dev machine and silently shifting the build environment.

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

- **DI**: `Services` (`lib/app/services.dart`) — singleton bag built once in `main.dart`, exposed via `Provider<Services>.value`. Screens read via `context.read<Services>()`; ViewModels take repos by constructor injection.
- **State**: `ChangeNotifier` + `ListenableBuilder`. No Redux/bloc/Riverpod.
- **Models**: `freezed` + `json_serializable`. API DTOs in `lib/data/models/api/`, domain models in `lib/data/models/domain/`.
- **Persistence**: Drift on SQLCipher; encrypted-at-rest with a per-install key in `flutter_secure_storage` under `invoiceninja.db.key.v1`. Tests use `NativeDatabase.memory()`.

See `docs/architecture.md` for the offline-first write pipeline (Drift→outbox→drain→apply, with `tmp_<uuid>` + `id_remap` for offline creates), the on-disk project layout, and the full coding-conventions checklist.

## Design system (v2)

Token-based visual language. The source of truth and the Dart port are deliberately split:

- `docs/design/v2/tokens.jsx` — **the source of truth** for colors, radii, shadows, type, button variants. When in doubt, read this file first.
- `docs/design/v2/{screens,patterns,design-canvas}.jsx` + `index.html` — reference mockups.
- `lib/app/design_tokens.dart` — Dart port. Read tokens via `context.inTheme.<name>` (e.g. `context.inTheme.surface`). **Do not introduce new color constants** outside `InTheme`. `InRadii` / `InSpacing` are static (brightness-independent).
- `lib/app/theme.dart` — wires `InTheme.light` / `InTheme.dark` into `ThemeData`.

When styling a page: read `tokens.jsx`, reuse `InTheme`, and prefer `Theme.of(context).colorScheme` + `context.inTheme` over hardcoded `Color(0x…)`.

**Always use rounded rectangles, never pills.** Use `RoundedRectangleBorder(borderRadius: BorderRadius.circular(InRadii.r2))` (or `.r1` / `.r3` per size) — never `StadiumBorder`, never `BorderRadius.circular(999)`. Material 3 defaults `SegmentedButton`, `Chip`, `FloatingActionButton.extended` to pills, so `lib/app/theme.dart` registers the rounded shape on every relevant component theme. New widgets inherit it automatically. Add new component themes to `theme.dart` rather than overriding inline.

**Pair related action buttons side-by-side**, not stacked. Render two-button rows in a `Row` with `SizedBox(width: InSpacing.md)` between them. Cancel sits next to the primary action, never above it.

**Spacing tokens are responsive.** `InSpacing.md` and `InSpacing.lg` are now context-aware static methods (`lib/app/design_tokens.dart`), not const doubles. They return wider values on desktop and tighter ones on mobile:

| Token | narrow (<600 px) | wide (≥600 px) |
|-------|------------------|----------------|
| `md`  | 8 px             | 12 px          |
| `lg`  | 12 px            | 16 px          |

Call them with a `BuildContext`: `EdgeInsets.all(InSpacing.lg(context))`, `SizedBox(width: InSpacing.md(context))`. **Drop `const` from any wrapping `EdgeInsets` / `SizedBox` / `Padding` literal** that wraps these calls — the value is no longer compile-time const. Element reuse doesn't depend on `const`, so the performance impact is effectively zero (Flutter's `Element.canUpdate` matches on `runtimeType + key`, not `==`); the GC handles short-lived `EdgeInsets` allocations.

`InSpacing.sm = 8 px` stays `const` for math contexts (`kKanbanCardWidth = kKanbanColumnWidth - InSpacing.sm * 2`, `_gap = InSpacing.sm`) and small inter-icon gaps. `InSpacing.xs`, `xl`, `xxl` likewise stay const — they aren't part of the responsive system.

**Bordered-card form sections use `InSpacing.lg(context)` interior padding by default.** That's what `FormSection` (`lib/ui/features/settings/widgets/form_section.dart`), `DashboardCardShell` (`lib/ui/features/dashboard/widgets/card_shell.dart`), and the task edit's identity card use. New one-off bordered cards (a `Container` with `tokens.border` + `BorderRadius.circular(InRadii.r3)`) match: `padding: EdgeInsets.all(InSpacing.lg(context))`. Column-aligned interior surfaces (table headers + rows + add-row tiles) match the horizontal value (`horizontal: InSpacing.lg(context)`) so cells line up with the section title above. Card-to-card visual consistency is the point — the inset stays the same across the screen no matter which widget owns the card chrome, and shrinks together on mobile.

**Side-by-side dialog actions need a per-call `minimumSize` override.** When you place a `FilledButton` / `FilledButton.tonal` / `OutlinedButton` inside `AlertDialog.actions` (or any `Row`), pass `style: FilledButton.styleFrom(minimumSize: const Size(64, 44))` (Outlined uses `Size(64, 40)`). The themes default to `Size.fromHeight(44)` = infinite width, which is right for column-stacked form buttons but wrong in any horizontal context — `Row` crashes layout and `AlertDialog.actions` silently stacks via `OverflowBar`. Canonical example: `lib/ui/features/shell/widgets/company_picker.dart:118-125`. Inline comments in `lib/app/theme.dart` explain why.

**Centered single-action buttons must constrain their own width too.** The `FilledButton` theme default (`Size.fromHeight(44)` = `Size(double.infinity, 44)`) makes a bare `FilledButton` stretch full-width — correct for column-stacked form buttons, wrong for an `EmptyState` action or any centered call-to-action, where it renders as one giant edge-to-edge bar. Pass `style: FilledButton.styleFrom(minimumSize: const Size(64, 44))` so the button sizes to its content; `EmptyState`'s centered column then centers it. Don't create new full-width `FilledButton`s outside a deliberately column-stacked form/footer context. Reference: the Reports empty-state "Run report" action in `lib/ui/features/reports/widgets/reports_body.dart`.

## Forms

### Enter to save

Pressing **Enter** in a single-line text field submits the surrounding form. Multi-line fields keep Enter for newlines — never submit from `maxLines > 1`.

Wiring: every edit/settings screen wraps its form body in `FormSaveScope` (`lib/ui/core/widgets/form_save_scope.dart`):

```dart
FormSaveScope(
  onSubmit: _onSave,     // same callback the Save button calls
  enabled: canSave,      // same flag — gates Enter while busy/invalid
  child: <form body>,
)
```

Reusable field widgets read the scope from their `onSubmitted` automatically — see `OverridableTextField` and `ClientEditField`. Raw `TextField`s in new code should read `FormSaveScope.maybeOf(context)` when `maxLines == 1`, set `textInputAction: TextInputAction.done`, and pipe `onSubmitted` to `scope.trySubmit()`.

Dialogs with a single text input + primary action: wrap the dialog body in `FormSaveScope` so Enter fires the primary action. Login's password field is wired explicitly (`_PasswordField` in `lib/ui/features/auth/views/login_screen.dart`) — it bridges email + password submit.

### Empty for blank numeric fields

Numeric edit fields seeded from a non-nullable `Decimal` must render **empty for zero**, not `"0"`. Use `decimalInputText(value)` (`lib/utils/formatting.dart`) when feeding a `Decimal` into an `EntityEditField`'s `initial:` — don't reach for `.toString()`. Reference: price / cost / quantity fields on `lib/ui/features/products/views/product_edit_screen.dart`.

For money values, prefer `Formatter.inputMoney(value, currencyId: ...)` (returns `''` for zero). `Formatter.inputAmount(value)` is the same pattern for `num`-typed inputs without forced precision.

### Searchable pickers

Any dropdown bound to a long list (countries, currencies, languages, industries, timezones — anything past ~20 options) **must** support type-to-search.

- **Plain pickers**: `SearchableDropdownField<T>` (`lib/ui/core/widgets/searchable_dropdown_field.dart`). Generic on the item type; takes `displayString` + `idOf` projections.
- **Settings pickers with cascade-override**: `OverridableSearchableDropdownField<T>` (`lib/ui/features/settings/widgets/overridable_searchable_dropdown_field.dart`). Same shape as `OverridableDropdownField` — use on settings pages.

Do **not** introduce new `DropdownButtonFormField`s for long lists. They're fine for short, fixed enums (~10 items max — Classification, Size, Custom Field Type).

### Two-choice fields → radio, not dropdown

A fixed field with exactly two choices (occasionally up to ~4) uses a **radio group, not a dropdown** — both options stay visible instead of hiding one behind a tap. For cascade-aware settings use `OverridableRadioField<T>` (`lib/ui/features/settings/widgets/overridable_radio_field.dart`); reference the `empty_columns` field on Invoice Design → General. Don't add new two-choice `DropdownButtonFormField` / `OverridableDropdownField`s. Dropdowns stay correct for longer fixed enums (~10 items); past ~20 options it must be a searchable picker (above).

### Date and time fields

Single-date and single-time-of-day inputs go through `InDateField` (`lib/ui/core/widgets/in_date_field.dart`) and `InTimeField` (`lib/ui/core/widgets/in_time_field.dart`). They wrap a typed `TextField` with a trailing picker icon — users can type shortcuts *or* tap the icon for the standard Material modal:

- Date shortcuts: `today` / `tomorrow` / `yesterday` / `now`; signed offsets `+1`, `-7`; bare day `14`; short slash `5/14` (current year, US/EU order from the active pattern); compact `051426` (with 2-digit year heuristic); plus ISO `2026-05-14`, the company's active format, and the usual short and long fallbacks.
- Time shortcuts: bare hour `9` → `9:00`; compact `930` → `9:30`; AM/PM suffix `9p` / `9am`; plus `HH:mm`, `H:mm`, `h:mm a`.

Commit-on-blur + Enter; silent revert on parse failure (no red border noise — the picker icon is the fallback). The placeholder hint and display format come from the active company `Formatter` (`formatter.settings.dateFormatId`, `formatter.settings.enableMilitaryTime`); without a `Formatter` the field falls back to ISO date display and `HH:MM` time. **Parsing** of typed input is the same in either locale — `9` always means `9:00`, `9p` always means `21:00`; only display rendering switches between `HH:MM` and `h:mm AM`.

**Don't reach for `showDatePicker` / `showTimePicker` directly** for form fields. The only place that's still appropriate is one-tap *range* filters where a single text field doesn't fit the model (see `DateRangePickerButton` in `lib/ui/features/dashboard/widgets/filters/`). Reference call sites for typed single-date / single-time inputs: time-log table (`lib/ui/features/tasks/widgets/edit/time_entry_table.dart`), time-entry editor sheet, project due-date field.

Parsing rules live in `parseDateInput` and `parseTimeInput` in `lib/utils/formatting.dart` — if you need the same shortcuts without the field chrome (e.g. URL-driven date filter, programmatic edge case), reuse those functions directly rather than re-implementing.

## Settings screens

Most new settings panels should look like **Company Details** or **Device Settings** — never like User Details. Both are FormSection-card layouts inside `SettingsFormShell(sections: [...])`; the only difference is whether they're VM-backed and cascade-aware.

### Decision tree (5-second routing)

Ask: **"Does this field write to the server (`/api/v1/companies/...` or similar)?"**

- Field writes to server `company.settings.*` → **Company Details style** + `CascadeSettingsScaffold` + `Overridable*` widgets.
- Field writes to server `company.*` (top-level) → **Company Details style** + `SettingsPageScaffold` + plain widgets.
- Field writes only to a local controller (theme, locale, biometric, …) → **Device Settings style** + `SettingsScreenScaffold`, no VM.
- Never the user-details `ListTile` shape (see anti-pattern below).

If you're building a *custom* shell (e.g. tabbed like Company Details), reach for `SettingsCompanyScopedHost` instead of re-rolling the company-switch listener inline.

### Three styles, summarized

- **Cascade-aware** (`company.settings.*`): `CascadeSettingsScaffold` + a one-line `SettingsDraftViewModel` subclass + body of `OverridableTextField` / `OverridableDropdownField` / `OverridableSearchableDropdownField` / `OverridableMarkdownField`. The scaffold picks the right VM for the active `SettingsLevelController` (your factory at company scope; shared `ClientSettingsDraftViewModel` at client scope). Reference: `lib/ui/features/settings/views/basic/localization/localization_screen.dart`.
- **Company-only** (`company.*` top-level, or mixed top-level + `company.settings.*`): `SettingsCompanyScopedHost<V>` → `SettingsPageScaffold<V>` directly. Plain `TextField` / `DropdownButtonFormField` / `SearchableDropdownField` calling `vm.updateCompany((c) => c.copyWith(...))`. Do **not** use `CascadeSettingsScaffold` here — it swaps to a client-scope VM where `updateCompany` is a no-op and edits get silently dropped. Reference: `lib/ui/features/settings/views/basic/company_details/company_details_shell.dart`.
- **Device Settings** (no server, no VM): `SettingsScreenScaffold` + `SettingsFormShell` + typed tiles (`ThemeTile`, `BiometricToggleTile`, …) that write directly to local controllers. Reference: `lib/ui/features/settings/views/basic/device_settings_screen.dart`.

Full skeletons (cascade-aware, company-only, device-local, tabbed shells, mixing both kinds of fields) live in `docs/settings-screens.md`.

### Width cap: every body under `/settings/...` goes through `SettingsFormShell`

`SettingsFormShell` (`lib/ui/features/settings/widgets/settings_form_shell.dart`) does the centering + max-width (720 px) + outer scroll + outer padding. **Any screen routed under `/settings/...` renders its body through it.** That includes tab bodies inside an entity-edit scaffold — the gateway-edit tabs (Credentials / Settings / Required Fields / Limits & Fees) live under `/settings/company_gateways/.../edit` and use `EntityEditScreenScaffold` for chrome, but their tab bodies still wrap in `SettingsFormShell` so they don't stretch full-width on a wide window like Clients / Products / Tasks do (which is correct *for* Clients / Products / Tasks since those live outside `/settings/...`). The gateway edit screen is the precedent that bit us; don't re-introduce raw `ListView(padding: ...)` as the top-level body for a screen the user reaches from the settings sidebar.

### Anti-pattern: User Details ListView+ListTile shape

Do not introduce raw `ListView` + `ListTile` layouts for new settings panels. Even single toggles or actions belong inside a `FormSection` so the whole sidebar reads as one design system. A `ListTile` *itself* is fine when wrapped in a typed control widget and dropped inside a `FormSection`; the anti-pattern is the unwrapped `ListView`-of-bare-`ListTile`s with no card chrome. Read-only diagnostic screens and action-only screens follow the same rule — see `views/basic/account_management/overview_screen.dart` and `views/advanced/system_logs_screen.dart`.

## Adding a new entity

The generic stack does most of the work. Five layers do the heavy lifting — touch them only when extending the framework, never to bend it for one entity:

- `BaseEntityApi<TList, TItem>` (`lib/data/services/base_entity_api.dart`)
- `BaseEntityRepository<TDomain, TApi>` (`lib/data/repositories/base_entity_repository.dart`)
- `BaseEntitySyncDispatcher<TItem, TInner>` (`lib/domain/sync/base_entity_sync_dispatcher.dart`) — wired in `wireEntities()` (`lib/app/services_entity_wiring.dart`), no per-entity subclass. Document-bearing entities spread `documentMutationHandlers<TInner>(...)` (`lib/app/services_document_handlers.dart`) into their `customActions` map instead of hand-rolling the upload/delete/visibility trio.
- `GenericListViewModel<T>` (`lib/ui/core/list/generic_list_view_model.dart`)
- `EntityListScreenScaffold<T, VM>` / `EntityDetailScaffold<T>` / `EntityEditScreenScaffold<T, VM>`

`EntityRegistry` (`lib/domain/entity_registry.dart`) is the orchestrator: one entry per entity in `kWiredEntityModules` / `kDisabledEntityModules` (`lib/app/entity_modules.dart`) declares path, route, icon, parent/children, password-required mutations, sidebar metadata, and the four screen builders. Both files are entity-agnostic — adding an entity touches the module specs only.

Contract tests live in `test/data/repositories/_base_entity_repository_contract.dart` — register the fixture at the top of your `<entity>_repository_test.dart` and inherit the universal coverage for free.

### The 13-step recipe (summary)

1. API DTO (`<entity>_api_model.dart`)
2. Domain model (`<entity>.dart`)
3. Drift table (`<entity>_table.dart`)
4. DAO + `CompanyScopedDao` mixin
5. Service (`<entity>s_api.dart` — plural)
6. Repository
7. List + Detail + Edit ViewModels
8. List + Detail + Edit screens (thin wrappers around the generic scaffolds)
9. Entity module spec in `kWiredEntityModules` (`lib/app/entity_modules.dart`)
10. DI: one block in `wireEntities()` in `lib/app/services_entity_wiring.dart` — `final fooApi = FooApi(ctx.apiClient); final fooRepo = FooRepository(...); wire<FooItemApi, FooApi>(type: EntityType.foo, api: fooApi, repo: fooRepo, customActions: ...)`. If document-bearing, set `customActions: documentMutationHandlers<FooApi>(...)`. If bundled, append a closure to `bundleAppliers`. The plain `services.dart` is no longer per-entity; it builds `EntityWiringContext` once and consumes the result.
11. Branch order in `kBranchOrder` (append-only)
12. Actions + 7 translation keys (entity translation completeness test enforces)
13. Tests: contract fixture + entity-specific mapper / filter / conflict tests

Full step-by-step shapes, "Standard action helpers" factories, the "Non-standard actions" pattern (e.g. Invoice `markPaid` via `customActions:`), and the bundled-entity alternative all live in `docs/adding-an-entity.md`. The Clients and Products screens are the reference invocations to mirror.

## Sync — non-obvious rules

- Outbox FIFO is **per company, strict global id order** in M1 (only one entity type exists). The plan's stronger "per (company, entity_type)" guarantee is needed when M2+ introduces cross-entity references with retry-driven head-of-line blocking — revisit `OutboxDao.nextReady` then.
- Every outbound request sends `Idempotency-Key: <uuid from the outbox row>` so retries are safe. Generated once when the row is created; never regenerated.
- Logout / company-switch with pending non-dead outbox rows **prompts** the user (sync now / discard / cancel). Never silently drops user data.
- Destructive ops (delete, purge, password change) require `X-API-PASSWORD-BASE64`. Password is captured by `ConfirmPasswordSheet` and held in a 5-min in-memory cache.
- **412 Precondition Failed = password-required.** Body is `{"message":"Invalid Password", …}`. `ApiClient._raiseFromResponse` maps it to `PasswordRequiredException`; `SyncEventListener` surfaces `ConfirmPasswordSheet` for outbox-parked mutations. The 403 password-message sniff stays as a defensive fallback. `GET /api/v1/users/{id}` is 412-gated — User Details routes around it via `/refresh` (see § Strict rules).
- 401 forces `AuthRepository.logout()` and a redirect to `/login`. **Single-flight**: parallel 401s wait on the same logout future.
- The `x-minimum-client-version` response header is checked on every request; below threshold throws `ClientTooOldException`.
- 422 validation errors carry `Map<String, List<String>> fieldErrors`. Edit forms surface these inline.
- **409 conflicts** are parked far in the future (1 year) instead of auto-retried. The `ConflictResolutionSheet` either re-enqueues a fresh mutation or discards.
- **404 on outbox drain** is treated as a conflict: the entity was deleted server-side while we held a pending mutation locally. Same `Conflict` path applies — the sheet offers "delete locally" / "recreate".
- **Server-side list ordering is assumed ascending `updated_at`** — the keyset cursor in `ApiClient.getList` reads `data.last` as the high-water mark. Matches Invoice Ninja's default list endpoints.
- The local `is_dirty` flag is **layered onto the domain model** in `<Repository>._fromRow` (e.g. `ClientRepository._fromRow`) — `<Entity>.fromApi` defaults to `false`, and the repo overlays the value from the Drift row. Without this overlay, an unsaved edit shows up as clean after app restart.

## Data loading — bundled vs per-entity

Before adding a new module, decide how its data is fetched. Two buckets:

- **Bundled with the company on auth.** `/login` and `/refresh` accept `first_load=true`, which makes the server include company-scoped reference data alongside each company: tax rates, groups, designs, payment terms, expense categories, task statuses, subscriptions, schedulers, etc. The static catalog (currencies, countries, languages, industries, gateway types, date formats) is also returned under `staticData` (request with `include_static=true`). `/refresh` already sends both. When adding data that fits this bucket, consume it from the existing login/refresh response — do not write a separate fetcher.
- **Loaded by their own routes.** High-volume, user-browsable entities: clients, invoices, products, payments, expenses, tasks, projects, quotes, credits, vendors, purchase orders, recurring invoices, etc. Full `BaseEntityApi` + page-by-page + Drift + outbox stack. Never try to bundle these into `first_load`.

Rule of thumb when adding a new entity:
- Small, mostly read, shared across the whole company, rarely paginated (≲ a few hundred rows) → **bundled**. Follow the three-step seam in `docs/adding-an-entity.md` § Bundled entities (`CompanyEnvelopeApi` field + repo `applyBundle` + `AuthRepository.onPersistBundles` fan-out).
- The kind of list a user scrolls, searches, and filters → **own route**, full per-entity stack.

If unsure, probe `/api/v1/refresh?first_load=true&include_static=true` against the demo API — anything already in that payload belongs in the bundled bucket.

**Bundled today**: the auth user record (via `data[N].user`, written directly in `_persistAndActivate`), `task_statuses`, `company_gateways`. `applyBundle` is **upsert-only — never deletes** (rows with `is_dirty=true` keep their outbox-bound payload until the next real sync); advances the keyset cursor with `wasFullSync: true` so the screen's first `ensurePageLoaded` short-circuits.

## Localization

- Source of truth: **Transifex** (`explore.transifex.com/invoice-ninja/invoice-ninja`).
- Files in the zip are PHP arrays (`textsphp-<locale>.php`).
- `tools/import_transifex_zip.dart <zip>` parses those PHP files for locales in `kSupportedLocales` and writes `assets/i18n/<locale>.json`.
- Workflow per release: download zip → run the importer → commit the changed JSONs.
- Runtime: `Localization` loads the active locale's JSON from `rootBundle`. English is always loaded as a fallback. There is **no** server fetch and **no** override table — the bundle is the only source.
- Adding a locale = (a) add it to `kSupportedLocales`, (b) re-run the importer.

## Rich text editing

`lib/ui/core/widgets/markdown_text_field.dart` is the shared WYSIWYG editor for markdown-bearing settings (e.g. email/invoice template overrides). It wraps `super_editor` and `super_editor_markdown` — both pulled from a pinned git ref via `dependency_overrides` so the editor and markdown serializer stay on the same monorepo HEAD.

Conventions:
- **One-way data flow.** Parent owns the markdown string and feeds `initialValue` + `externalValueKey`. The widget debounces edits (default 300 ms) and emits the serialized markdown through `onChanged`. To force a reseed after an external write (e.g. override toggle resets to a cascaded parent value), change `externalValueKey`. The `(apiKey, value, isOverridden)` hash works well; see `lib/ui/features/settings/widgets/overridable_markdown_field.dart`.
- **Server content is safe by construction.** `super_editor` deserializes markdown into Flutter's widget AST — no HTML/JS execution context. The `_sanitize` helper strips `<p>`, `<div>`, `<br>` residue from legacy Quill data.
- **No new editor instances.** Don't reach for `TextField` + markdown post-processing for a free-text field that needs formatting — reuse `MarkdownTextField`.

## Widget previews

The four widgets in `lib/ui/core/widgets/` (`EmptyState`, `ErrorView`, `StatusPill`, `LinkText`) carry `@Preview` annotations that wire through `appPreviewTheme()` in `widget_preview_support.dart`, so previews render against the real `InTheme` tokens. Launch via the IDE's "Flutter Widget Preview" tab or `flutter widget-preview start`. Add new previews to design-system widgets only — feature screens depend on `Services` via `Provider` and aren't preview-friendly without scaffolding.

## Integration tests

`integration_test/app_smoke_test.dart` boots the real `InvoiceNinjaApp` with in-memory Drift + `InMemoryTokenStorage` and a `MockClient`. Scenarios cover: boot to `/login` with no creds, boot to `/lock` when biometric is enabled, lock-screen sign-out, post-auth redirect to `/dashboard` vs `/clients` (driven by `view_dashboard` permission), and a full login → refresh round-trip. Guards the DI graph, router, theme, and localization wiring.

**Never run integration tests locally.** They steal focus from the developer's session. CI runs them on every PR via `.github/workflows/ci.yaml` against macOS desktop.

**Local runs can't use the CI command.** `flutter test integration_test/ -d macos` only ever works for the *first* file on desktop — [flutter/flutter#135673](https://github.com/flutter/flutter/issues/135673): the tool reuses a debug-connection stream that breaks on the second app launch, so every later file dies with `Error waiting for a debug connection: The log reader stopped unexpectedly, or never started.` → `Unable to start the app on the device.` CI survives the same command only because its runner can't reach `demo.invoiceninja.com`, so the `demo/*` live files self-skip (`skipIfUnreachable`, `integration_test/support/demo_harness.dart`) and `app_smoke_test.dart` is the lone app launch. Locally the demo server *is* reachable, so it bites. For deliberate local verification use `tools/run_integration_local.sh` (one `flutter test` invocation per file = the upstream workaround; mocked suite only by default, `--include-demo` adds the live `demo/*` files). Same focus-stealing caveat applies — not during a focused session.

Stable widget keys (`login_submit`, `lock_unlock`, `lock_sign_out`) keep assertions locale-independent. Add similar keys when extending the test.

When adding scenarios, mock both `/api/v1/login` and `/api/v1/refresh` if the flow authenticates — `_persistAndActivate` calls refresh after a successful login, and `restore()` fires a best-effort refresh too. The shared `_silentNetwork()` helper returns a 500-MockClient for scenarios that don't care about the wire.

## Diagnostics log

Debug-only on-disk capture so future Claude sessions can read what went wrong without the user copy-pasting console output. Wired in `lib/app/diagnostics_log.dart` + `lib/main.dart`; surfaced in Settings → Advanced → System Logs. **Release builds disable this entirely** (`Services.diagnosticsLog == null`, no handlers registered).

What's captured automatically (debug only):
- Uncaught Flutter errors via `FlutterError.onError`.
- Uncaught async errors via `PlatformDispatcher.instance.onError` + `runZonedGuarded`.
- Every `Logger` record at `WARNING` or higher (uses the same `redact()` helper as `lib/app/logging.dart`).

What the user can trigger explicitly:
- **Append outbox snapshot** button on System Logs — dumps stale rows for the active company (dead + in_flight + pending parked > 24 h). Uses `OutboxDao.staleRowsForCompany`. Payload bodies are intentionally omitted (only `payload_size` is written) to keep the file small.

File layout:
- Path: `getApplicationSupportDirectory()/claude-diagnostics.log` (next to the encrypted Drift DB).
- Rotation: at 512 KB, current file is renamed to `<name>.log.1` (one backup, overwritten on each rotation).
- Format: plain text, one record per line, ISO-8601 UTC timestamps, indented stack lines under the head line.
- gitignored as `claude-diagnostics.log*` (the rotated `.log.1` isn't caught by the generic `*.log` rule).

**To check the log in a future Claude session**, the user can say *"read the diagnostics log"*. The path isn't a constant — it resolves at runtime per platform — so Claude reads it from one of these sources (in order of cost):
1. Settings → Advanced → System Logs displays the absolute path with a copy button; the user can paste it.
2. Boot logs the path via `Logger('main').info('Diagnostics log open at <path>')` — visible in the Xcode/IDE console.
3. On macOS dev, the conventional path is `~/Library/Containers/<bundle-id>/Data/Library/Application Support/<bundle-id>/claude-diagnostics.log` (or, outside the App Sandbox, `~/Library/Application Support/<bundle-id>/`).

Once you have the path, `Read <path>` (or `Read <path>.1` for the rotated backup) ingests it. Lines are pre-redacted, but the file still contains real company/entity ids — treat as user data.

## Desktop window state

Each desktop runner persists window size, position, and fullscreen across launches via the host OS's native preference store. No Dart or Flutter package involvement — the goal is one short native function per platform, idiomatic to that platform's APIs.

**Contract** — every desktop runner does the same three things:
1. Read saved state at window-construction time, before the window is shown.
2. Write on every geometry change (move / resize) and on every fullscreen transition completion.
3. Fall back to the platform-native default frame on first launch (the values declared in the platform's window template — XIB on macOS, manifest / template on Windows, default size call on Linux).

**macOS** — `macos/Runner/MainFlutterWindow.swift` → `setUpWindowStatePersistence()`. Frame via `NSWindow.setFrameAutosaveName` (NSUserDefaults key `NSWindow Frame InvoiceNinjaMainWindow`, derived by AppKit); fullscreen bool via `NSWindowDelegate.windowDidEnter/ExitFullScreen` → NSUserDefaults key `ninja.window.isFullscreen`. `isRestorable = false` to keep AppKit's autosave as the only mechanism (otherwise Cocoa state restoration would override it after `awakeFromNib`).

**Windows** *(when added)* — `windows/runner/flutter_window.cpp` → `SetUpWindowStatePersistence()`. Use `WINDOWPLACEMENT` (covers normal-rect + maximized / minimized state in one struct) read & written under `HKCU\Software\InvoiceNinja\Window`. Persist on `WM_MOVE` / `WM_SIZE` / `WM_DESTROY`; restore in `OnCreate` via `SetWindowPlacement`. For fullscreen (Windows has no built-in fullscreen — it's a borderless window covering the monitor), persist a separate `Fullscreen` DWORD.

**Linux** *(when added)* — `linux/runner/my_application.cc` → `setup_window_state_persistence()`. Connect `configure-event` (geometry) and `window-state-event` (fullscreen / maximize); persist to `~/.config/invoice_ninja/window-state.ini` via `GKeyFile`. Restore in `activate` via `gtk_window_set_default_size` + `gtk_window_move` + `gtk_window_fullscreen` as appropriate.

## Reference points

Three read-only sources to mirror, never copy from:

- **`/Users/hillel/Code/admin-portal`** — the previous Flutter (Redux) admin app:
  - `lib/data/models/client_model.dart` — Client field set.
  - `lib/data/web_client.dart` — header set (213-231), version negotiation (245-258), demo mode (31, 266).
  - `lib/redux/auth/auth_middleware.dart` (102-120) — login response envelope.
  - `lib/redux/static/static_state.dart` — shape of the `/api/v1/statics` response.
  - `lib/redux/settings/settings_state.dart` (93-99) — settings cascade resolver.
  - `lib/data/models/entities.dart` — full EntityType enum + parent/child relationships.
- **`/Users/hillel/Code/react`** — the React web client. Useful as a second reference for entity shapes, request flows, and UI behaviors when admin-portal is unclear or out of date.
- **API reference** — <https://invoiceninja.github.io/docs/api-reference/invoice-ninja-api-reference>.

Live-server probes go through `demo.invoiceninja.com`'s canned read credentials — see `docs/probing-the-demo-api.md` for the curl recipe and the 412 password-gate heads-up.

## Settings search catalog

`lib/ui/features/settings/settings_search_catalog.dart` is the single source of truth for the settings sidebar (`kSettingsSections`) AND the in-app search (`kSettingsSearchCatalog`). Whenever you add / rename / remove a user-facing field under `lib/ui/features/settings/views/**`, update its `kSettingsSearchCatalog` entry — `search_catalog_consistency_test` enforces both ends match. Full conventions (section keys = route slugs, field entries = localization keys, the `kFooSearchKeys` co-location pattern) and the related "custom fields live in one home only" rule are in `docs/settings-screens.md`.