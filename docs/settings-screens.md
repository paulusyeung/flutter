# Settings screens

Companion to CLAUDE.md § Settings screens. The main file carries the 5-second decision tree, the three style names, and the User-Details anti-pattern. This doc carries the page skeletons (one recipe per style), the tabbed-shell pattern, and the rule for screens that mix top-level and cascade-aware fields.

## Smallest new-page skeleton

Each shape collapses to a short recipe. Don't write more than this — every other concern (Save button, dirty guard, FormSaveScope, override checkbox, company-switch rebuild, scope banner) already lives in the scaffold or the field widgets.

### Cascade-aware (`company.settings.*`)

Reference: `lib/ui/features/settings/views/basic/localization/localization_screen.dart`.

1. Add bindings for any new `company.settings.*` keys to `lib/ui/features/settings/widgets/settings_field_bindings.dart` (the `(read, write)` projection pair). Skip if the key is already there.
2. Write a one-line VM subclass: `class FooViewModel extends SettingsDraftViewModel { FooViewModel({required super.repo, required super.companyId}); }` — usually no body needed.
3. Build the screen as a `StatelessWidget` returning `CascadeSettingsScaffold(titleKey: 'foo', companyVmFactory: ({required repo, required companyId}) => FooViewModel(repo: repo, companyId: companyId), body: const _FooBody())`. **If your screen also touches top-level `company.*` fields (`sizeId`, `industryId`, anything not under `company.settings.*`), switch to the company-only skeleton instead** — `CascadeSettingsScaffold` swaps in `ClientSettingsDraftViewModel` at client scope where `updateCompany` is a no-op, so top-level edits would be silently dropped. See § Mixing both kinds of fields on one screen below.
4. The body is `SettingsFormShell(sections: [FormSection(title: ..., children: [OverridableTextField(apiKey: ..., label: ...), OverridableSearchableDropdownField<…>(apiKey: ..., ...), ...])])`. Drop in any `Overridable*` widget — the cascade-override semantics are wired by `OverridableField.bind` inside.
5. Export `const kFooSearchKeys = <String>[...]` from the screen file and add `'foo': [...kFooSearchKeys]` to `kSettingsSearchCatalog` in `lib/ui/features/settings/settings_search_catalog.dart`. `search_catalog_consistency_test` will fail until both ends match.
6. Register the sidebar entry in `kSettingsSections` (also in `settings_search_catalog.dart`).

### Company-only (`company.*` top-level, no cascade)

Also the right pick when the page mixes `company.*` *and* `company.settings.*`. Reference: `lib/ui/features/settings/views/basic/company_details/company_details_screen.dart` + `company_details_shell.dart`.

1. Subclass `SettingsDraftViewModel` (same one-liner as above). The company-only VM is just a `SettingsDraftViewModel` — `updateCompany` is already on the base.
2. Wrap in `SettingsCompanyScopedHost<FooViewModel>(create: …, builder: (context, vm) => SettingsPageScaffold<FooViewModel>(titleKey: 'foo', viewModel: vm, body: const _FooBody()))`. The host owns the company-switch rebuild; do not use `CascadeSettingsScaffold` here.
3. Body uses plain `TextField` / `DropdownButtonFormField` / `SearchableDropdownField` that call `vm.updateCompany((c) => c.copyWith(...))`. No `Overridable*` widgets — top-level fields don't cascade.
4. Group cascade-aware (`company.settings.*`) and company-only fields into separate `FormSection`s if the page touches both, so the override-checkbox visibility lines up at client scope.
5. Search catalog + sidebar entry same as cascade-aware (steps 5–6).

### Device-local (no server, no VM)

Reference: `lib/ui/features/settings/views/basic/device_settings_screen.dart`.

1. Build the screen as a `StatelessWidget` returning `SettingsScreenScaffold(titleKey: 'foo', body: SettingsFormShell(sections: [FormSection(title: ..., children: [ThemeTile(), BiometricToggleTile(), ...])]))`. No VM, no `Provider`, no Save button.
2. Each tile reads + writes its own controller directly (`services.theme`, `services.locale`, `services.biometric`, …). New tiles belong as their own typed widget (`FooTile`) in `lib/ui/features/settings/widgets/`, not as inline `ListTile`s.
3. Pass `spacing: 0` to `FormSection` only when the tiles want their own row separators (a `Divider(height: 1)` between them, like `preferences_screen.dart`). Otherwise let `FormSection` auto-spacing handle it.
4. Search catalog + sidebar entry same as the server-backed shapes.

### Tabbed shells

Reference: `lib/ui/features/settings/views/basic/company_details/company_details_shell.dart`.

For company-only screens whose content is split across tabs, compose `TabbedSettingsShell<V>` (`lib/ui/features/settings/widgets/tabbed_settings_shell.dart`) with a `List<TabbedSettingsTab>` (each entry is `slug + labelKey + body` — the first tab uses an empty slug). Register the matching route entries with `tabbedSettingsRoutePair(...)` in `settings_routes.dart`. The shell owns the `TabController`, the URL ↔ tab-index sync, and the shared-page-key trick that keeps the draft VM alive across the bare-URL and per-tab routes — do not re-implement these inline. Per-screen specifics (e.g. Company Details' statics warm-up for the Size/Industry dropdowns) sit in a thin `StatefulWidget` wrapper around `TabbedSettingsShell`, not inside the shell itself.

## Mixing both kinds of fields on one screen

When a single page touches *both* `company.settings.*` (cascade-aware) and `company.*` (top-level) fields — e.g. Company Details "Details" tab — do **not** use `CascadeSettingsScaffold`. The cascade scaffold swaps in `ClientSettingsDraftViewModel` at client scope, where `updateCompany` is a no-op (top-level fields don't apply per-client) — the UI would silently drop the user's edits to those fields. Use `SettingsPageScaffold<V>` directly with a company-only VM (`SettingsDraftViewModel` subclass), the way `CompanyDetailsShell` does. Group cascade-aware and company-only fields into separate `FormSection`s so the override-checkbox visibility lines up; reference: `_SizeField` and `_IndustryField` under the "business" section in `lib/ui/features/settings/views/basic/company_details/company_details_screen.dart`.

Reminder: every new settings page must also contribute its field labels to `kSettingsSearchCatalog` — see CLAUDE.md § Settings search catalog.

## Company Details style — when each option applies

- **Cascade-aware (fields on `company.settings.*`)** → wrap in `CascadeSettingsScaffold` (`lib/ui/features/settings/widgets/cascade_settings_scaffold.dart`). It picks the right VM for the active `SettingsLevelController` (your factory at company scope, the shared `ClientSettingsDraftViewModel` at client scope), delegates VM lifecycle (build, load, dispose, company-switch rebuild) to `SettingsCompanyScopedHost`, and hands the result to `SettingsPageScaffold`. Caller supplies just `titleKey`, `companyVmFactory`, and `body`. Reference: `lib/ui/features/settings/views/basic/localization/localization_screen.dart`.
- **Company-only (also touches top-level `Company` fields like `sizeId` / `industryId`)** → wrap in `SettingsPageScaffold<V>` directly with a company-only VM. The cascade scaffold isn't appropriate because the client scope wouldn't apply to top-level Company fields. Reference: `lib/ui/features/settings/views/basic/company_details/company_details_shell.dart` (which uses `SettingsCompanyScopedHost` directly because it needs to own its own `TabController` outside the scaffold).
- **Action-only sub-shape (no editable fields)**: some Company Details tabs render server state and trigger uploads instead of editing fields — `documents_screen.dart` and `logo_screen.dart` are the precedent. They're still Company Details style: same `SettingsFormShell` + `FormSection` chrome, same VM, same Save button (just no contribution to it). The async upload writes outside the outbox via `services.company.upload*()` because file uploads aren't replayable; that's a deliberate exception, not a third style.
- Body in either case: `SettingsFormShell(sections: [FormSection(title: ..., children: [...]), ...])`. The shell handles centering + max-width + padding; `FormSection` is the bordered card with header + divider + content column. **`FormSection` auto-inserts `InSpacing.lg` between adjacent children** — drop the manual `SizedBox(height: InSpacing.lg)` interleaves. Pass `spacing: 0` only when the section owns its own row separators (e.g. a `Divider` between tiles, like `preferences_screen.dart`).
- Field widgets — pick by **where the field is stored**:
  - `company.settings.*` (cascade-aware) → `OverridableTextField` / `OverridableDropdownField` / `OverridableSearchableDropdownField` / `OverridableMarkdownField`. They render the override checkbox at group/client scope and hide it at company scope, so one call site covers both.
  - `company.*` (top-level: `sizeId`, `industryId`, `customFields`, `legalEntityId`, …) → plain `DropdownButtonFormField` / `SearchableDropdownField` / `TextField` that call `vm.updateCompany((c) => c.copyWith(...))`. These do not cascade and do not get the override wrapper. Group cascade-aware and company-only fields into separate `FormSection`s when they're on the same screen — Company Details "Details" tab is the canonical example.

## Anti-pattern: User Details ListView+ListTile shape (full version)

Do not introduce raw `ListView` + `ListTile` layouts (icon-leading row tiles, dividers between rows) for new settings panels. Even simple toggles or single actions belong inside a `FormSection` so the whole settings sidebar reads as one design system. The User Details and Preferences screens use FormSection cards now too — they're the right precedent, not the old pre-conversion shape.

A `ListTile` *itself* is fine when wrapped in a typed control widget (`ThemeTile`, `BiometricToggleTile`, `_LocaleTile` in Preferences) and dropped inside a `FormSection`. The anti-pattern is the unwrapped `ListView`-of-bare-`ListTile`s with no card chrome — that's what the old User Details screen was, and that shape doesn't come back.

This rule applies to **read-only diagnostic screens and action-only screens too**, not just editable forms. Even a single button or a list of key/value rows belongs inside a `FormSection` so the settings sidebar reads as one design system. References: `views/basic/account_management/overview_screen.dart` (single-action `FormSection` with `spacing: 0`) and `views/advanced/system_logs_screen.dart` (multiple `FormSection` cards of read-only rows, with a private `_DiagnosticRow` helper for the label/value layout).
