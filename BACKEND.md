# Backend API gaps — list filter & sort

Hand-edited tracker of gaps between what the Invoice Ninja list endpoints
honor and what the v2 Flutter admin needs. Basis for an upstream PR against
`invoiceninja`. Companion to `FEATURES.md`.

**Provenance**
- **2026-05-15** — empirical curl probe against `demo.invoiceninja.com` (the
  per-endpoint tables below).
- **2026-05-17** — source-read of `app/Filters/*` in the backend repo +
  targeted re-probe. This **reclassified several rows**: many params reported
  "silently ignored" are not missing backend support — they are **client-side
  wire-format / param-name mismatches** against filters the base
  `QueryFilters` already provides, or **cross-entity contract
  inconsistencies**. Backend file:line citations below are from that read.
- This file merges and supersedes the former `docs/backend.md`.

Each backend ask cites the `app/Filters/...:line` to add to or mirror. Each
row is still reproducible: pick it, run its curl, change the value, watch the
response count/order. **The API returns 200 with the unfiltered set for every
unknown param and every invalid sort column** — silent-ignore is the failure
mode, which is exactly why this list (and the hygiene asks) exist.

## How to verify a row

Auth headers (canned demo creds — see `docs/probing-the-demo-api.md`):

```
X-API-SECRET: password
X-API-TOKEN: TOKEN
X-Requested-With: XMLHttpRequest
Content-Type: application/json
```

A row is **fixed** when changing the param value produces a corresponding
change — different result count, different order, or 422 on a malformed value.

## What the base `QueryFilters` already provides

`app/Filters/QueryFilters.php` is inherited by **every** per-entity
`*Filters` class. These params therefore work on **all** list endpoints today
(modulo the column-existence guards noted):

| Param | Behavior | Source |
|---|---|---|
| `status=active,archived,deleted` | Entity **lifecycle** (`deleted_at` / `is_deleted`). Separate param from computed `client_status`; the two never collide server-side. | `QueryFilters.php:172` |
| `created_at=<date\|ts>` | `created_at >= value`. **Plain value only** — `Carbon::parse` then `>=`; an operator suffix (`:gt`) throws and is swallowed → unfiltered. | `:238` |
| `updated_at=<date\|ts>` | `updated_at >= value`. Same plain-value contract. | `:257` |
| `created_between=<start>,<end>` | `whereBetween('created_at', …)`. **2-part.** No `updated_between` exists. | `:389` |
| `date_range=<start>,<end>` | `whereBetween('date', …)`. **2-part, base contract** (see arity inconsistency in Hygiene). | `:415` |
| `due_date_range=<start>,<end>` | `whereBetween('due_date', …)`. 2-part. | `:463` |
| `client_id=<id>` | single, exact. | `:294` |
| `client_ids=<id,id>` / `assigned_user_ids=<id,id>` | multi, CSV of encoded ids. | `:446` / `:435` |
| (dispatch) | Unknown param → `if (!method_exists(...)) continue;` — **silent 200**. Unknown/invalid `sort` → `ensureDefaultOrder()` → `id DESC`. | `:88` / `:123` |

`per_page` is capped `min(abs(input), 5000)`, default 20
(`app/Http/Controllers/BaseController.php:606`).

**Confirmed by 2026-05-17 re-probe** (baseline = 25 rows):
`clients?created_at=2030-01-01` → **0** (honored). `clients?created_at=2030-01-01:gt`
→ **25** (suffix swallowed → ignored). `clients?country_id=840` → **25**
(genuinely no method). `invoices?date_range=2100-01-01,2100-12-31` → **0**
(base 2-part `date_range` works on invoices — the prior "no closed range"
claim was wrong).

## Legend

- ✅ Works — server honors the param.
- ⚠️ Partial — works with unexpected semantics (exact where LIKE expected).
- ❌ Silently ignored — 200 OK, result set unchanged, **and no server method
  exists** (genuine backend gap).
- 🔁 Misframed — server *does* support this; symptom is a client-side
  wire-format / param-name mismatch (→ see § Client-side mismatches; **not**
  in this PR's scope).
- 🚫 Not implemented in API.
- **untested** — wanted by the app; no controlled probe yet.

## Priority — fix order (backend PR)

1. **API hygiene: stop silently ignoring unknown filter params and invalid
   sort columns.** Return `422` (or a `meta.warnings[]` envelope) listing
   skipped params, and reject unknown sort columns. This is the meta-bug: it
   hid the Tasks param-name mismatch for a full release and makes every other
   row in this file undetectable from a client. (`QueryFilters.php:88,123`)
2. **Standardize the `date_range` contract** (four incompatible
   implementations today — see § Hygiene). One documented shape across all
   entities.
3. **Clients enum filters** — `country_id`, `industry_id`, `size_id`,
   `currency_id`, `language_id`, `group_settings_id`, `assigned_user_id`,
   `classification`. Eight params, all genuinely absent from `ClientFilters`.
4. **Universal `custom_value1..4` filtering** — no filter method on any
   entity.
5. **`vat_number` / `id_number` substring** on `/clients` and `/vendors`
   (accountant workflow; `ClientFilters` has exact `id_number` only).
6. **Expenses `project_ids` / `vendor_ids`** — genuinely absent
   (`categories` already exists; that's a client fix, not a backend one).
7. **`updated_between`** on the base (symmetry with `created_between`).
8. **`number=<value>` → LIKE/prefix**, not exact (`number=000` → all
   `0001..0099`).
9. **`status_id` parity** on `/quotes /credits /payments /purchase_orders
   /tasks /recurring_invoices` (Invoice-only today). Lower priority —
   `client_status` covers the user-facing cases.
10. **Publish the per-endpoint filter + sortable-column contract** in the
    public API docs (today aspirational on most list endpoints).

## Per-endpoint gaps

Skipping the small reference endpoints (designs, payment_terms, tax_rates,
webhooks, tokens, schedulers, subscriptions, company_gateways,
expense_categories, transaction_rules) — state filtering only, no pending
requests.

### GET /api/v1/clients — `app/Filters/ClientFilters.php`

`ClientFilters` adds only `name`, `balance`, `between_balance`, `email`,
`client_id`, `id_number`, `number`, `group`, `filter`. Everything else is
inherited from the base (so `status`, `created_at/updated_at`,
`created_between` work — see below) or genuinely absent.

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `filter=<text>` | ✅ LIKE on `name` | OR across name + number + contact name/email (matches user expectation) | 10 |
| `name=<text>` | ✅ LIKE | keep | — |
| `status=active,archived,deleted` | ✅ base `:172` (lifecycle) | keep — **this is the correct lifecycle param** (the client wrongly sends lifecycle on `client_status`; § Client-side) | — |
| `number=<value>` | ⚠️ exact (`number=000` → 0) | LIKE/prefix | 8 |
| `id_number=<value>` | ⚠️ exact (`ClientFilters` has its own exact `id_number`) | add LIKE substring | 5 |
| `email=<value>` | ⚠️ exact on contact email | LIKE substring | — |
| `balance=<n>:gt\|lt\|gte\|lte\|eq` | ✅ suffix-operator (`ClientFilters::balance`); `between` 🚫 (`between_balance` uses `min:max`) | keep; document the two shapes | — |
| `created_at=<date>` (plain) | ✅ base `:238` — **honored** (re-probe: `2030-01-01` → 0) | keep | — |
| `created_at=<date>:gt` | 🔁 swallowed (`Carbon::parse` throws) | client must send plain value or `created_between` (§ Client-side). Optionally: backend accepts an operator-suffix form for parity with `balance`. | 7 |
| `updated_at` (filter) | ✅ plain `:257` / 🔁 `:gt` | as above | 7 |
| `created_between=<s>,<e>` | ✅ base `:389` | keep | — |
| `country_id` | ❌ no method (re-probe: `840` → 25) | `whereIn('country_id', explode(','))`, mirror `group()` | 3 |
| `industry_id` | ❌ no method | mirror | 3 |
| `size_id` | ❌ no method | mirror | 3 |
| `currency_id` | ❌ no method | mirror | 3 |
| `language_id` | ❌ no method | mirror | 3 |
| `group_settings_id` | ❌ (only single `group=` exists, decoded) | CSV multi | 3 |
| `assigned_user_id` | ❌ no method on `ClientFilters` (base has `assigned_user_ids` CSV — clients could inherit/expose it) | expose `assigned_user_id`/`_ids` distinct from owner `user_id` | 3 |
| `classification` | ❌ no method | exact / CSV | 3 |
| `vat_number` | ❌ no method | LIKE substring | 5 |
| `custom_value1..4` | ❌ no method anywhere | LIKE substring | 4 |
| `user_id` vs `assigned_user_id` | ⚠️ both return all 25 | disambiguate owner vs assignee or deprecate one | 10 |

### GET /api/v1/invoices — `app/Filters/InvoiceFilters.php`

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `filter=<text>` | ✅ LIKE on `number` | OR number + client name + po_number | 10 |
| `client_id` / `client_ids` | ✅ base | keep | — |
| `status_id=<n>` | ✅ exact (Invoice-only filter) | keep | — |
| `client_status=draft\|paid\|unpaid\|overdue\|cancelled` | ✅ computed | keep | — |
| `overdue=true` | ✅ `InvoiceFilters::overdue` | keep | — |
| `status` (lifecycle) | ✅ base `:172` | keep | — |
| `date` / `due_date` | ✅ `>=` (Invoice-specific) | keep | — |
| `date_range=<s>,<e>` (2-part) | ✅ inherits base `:415` — **honored** (re-probe → 0/baseline). *Was misfiled as "start_date/end_date silently ignored."* | keep; client should send it; **standardize arity** (§ Hygiene) | 2 |
| `due_date_range=<s>,<e>` | ✅ base `:463` | keep | — |
| `project_id` | ❌ no method | add `project_id`/`project_ids` (CSV, decoded) | 9 |
| `start_date` / `end_date` | 🔁 no such method — the closed window is `date_range` (above), not these names | client sends `date_range`; backend may add `start_date`/`end_date` aliases | 2 |
| `custom_value1..4` | ❌ no method | LIKE substring | 4 |

### GET /api/v1/quotes · /credits — `Quote/CreditFilters.php`

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `filter`, `client_id`, `status` (lifecycle), `created_between` | ✅ | keep | — |
| `client_status` | ✅ quote: `draft\|sent\|approved\|expired\|upcoming\|converted`; credit: `draft\|sent\|partial\|applied` | keep | — |
| `status_id=<n>` | ❌ no method (Invoice-only) | add for parity (client already uses `client_status`, so low-pri) | 9 |
| `date_range` | ✅ inherits base 2-part `:415` | keep; standardize arity | 2 |
| `custom_value1..4` | ❌ | LIKE substring | 4 |

### GET /api/v1/payments — `app/Filters/PaymentFilters.php`

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `filter`, `client_id`, `status` (lifecycle) | ✅ | keep | — |
| `client_status=pending\|cancelled\|failed\|completed\|partially_refunded\|refunded\|partially_unapplied` | ✅ | keep | — |
| `date_range` | ⚠️ **3-part** `_,start,end` — `PaymentFilters::date_range:275` overrides the base 2-part (uses `$parts[1]`,`$parts[2]`, requires `isset($parts[2])`; a 2-part value **silently no-ops**) | standardize to one contract (§ Hygiene) | 2 |
| `status_id=<n>` | ❌ no method | parity add | 9 |
| `custom_value1..4` | ❌ | LIKE substring | 4 |

### GET /api/v1/expenses — `app/Filters/ExpenseFilters.php`

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `filter`, `client_id`, `status` (lifecycle), `client_status` | ✅ | keep | — |
| `categories=<id,id>` | ✅ encoded CSV → `whereIn('category_id', …)` (`ExpenseFilters.php:185`) | keep — **client must use `categories`, not `category_id`** (§ Client-side) | — |
| `category_id` | 🔁 no such method — canonical name is `categories` | client fix | — |
| `project_ids` | ❌ no method | add (mirror `categories`, `whereIn('project_id', …)`) | 6 |
| `vendor_ids` | ❌ no method | add (mirror `categories`, `whereIn('vendor_id', …)`) | 6 |
| `payment_type`, `amount`, `number`, `has_invoices`, `match_transactions` | ✅ | keep | — |
| `custom_value1..4` | ❌ | LIKE substring | 4 |

### GET /api/v1/tasks — `app/Filters/TaskFilters.php`

The May-2026 "project_id / status_id silently ignored — visible UI bug" was a
**param-name mismatch**, not absence. Canonical server names:

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `project_tasks=<encoded project id>` | ✅ single, decoded (`TaskFilters.php:97`) | keep — **client must send `project_tasks`, not `project_id`** (§ Client-side) | — |
| `task_status=<encoded id,id>` | ✅ CSV, decoded, also requires `invoice_id IS NULL` (`:236`) | keep — **client must send `task_status`, not `status_id`** | — |
| `project_id` / `status_id` | 🔁 no such method | client fix; backend *may* add `project_ids`/`status_id` aliases for cross-entity consistency | 9 |
| `client_status=invoiced\|uninvoiced\|is_running` | ✅ | keep | — |
| `assigned_user`, `user_id`, `hash`, `number` | ✅ | keep | — |
| `custom_value1..4` | ❌ | LIKE substring | 4 |

### GET /api/v1/projects — `app/Filters/ProjectFilters.php`

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `filter`, `client_id`, `number`, `status` (lifecycle) | ✅ | keep | — |
| `date_range=<col>,<start>,<end>` | ⚠️ **3-part with explicit column** (`ProjectFilters.php:152`: validates `$parts[0]` is a real column, `whereBetween($parts[0], …)`) — yet another contract | standardize (§ Hygiene) | 2 |
| `assigned_user` / `assigned_user_ids` | ❌ no method | add (mirror base `assigned_user_ids`) | 6 |
| `client_status` (lifecycle-aware) | ❌ no method | optional | — |

### GET /api/v1/recurring_invoices · /recurring_expenses

| Param | Current | Expected / backend ask | Pri |
|---|---|---|---|
| `filter`, `client_id`, `status` (lifecycle), `client_status` | ✅ | keep | — |
| `next_send_between` | ✅ accepts **both** `\|` and `,` separators (recurring_invoices) | pick one separator + document | 10 |
| `frequency_id`, `product_key` (rec. invoices) | ✅ | keep | — |
| `date_range` (recurring_expenses) | ⚠️ **2-part but `$parts[0],$parts[1]`** (`RecurringExpenseFilters.php:243`) — a *fourth* `date_range` contract | standardize (§ Hygiene) | 2 |
| `custom_value1..4` | ❌ | LIKE substring | 4 |

### GET /api/v1/purchase_orders · /vendors · /products · /bank_transactions

| Endpoint | Notable gaps | Pri |
|---|---|---|
| purchase_orders | `status_id` ❌ (use `client_status=draft\|sent\|accepted\|cancelled`); `start_date/end_date` 🔁 (use base `date_range`); `custom_value1..4` ❌ | 4/9 |
| vendors | `number` ⚠️ exact; `vat_number`/`id_number` substring ❌; `country_id`/`currency_id`/`assigned_user_id`/`custom_value1..4` ❌ (mirror the Clients asks) | 3/5 |
| products | `product_key` ✅ exact; `filter` ✅ LIKE on product_key/notes; no enum filters needed | — |
| bank_transactions | `name` ✅; `client_status=unmatched\|matched\|converted\|deposits\|withdrawals` ✅; `bank_integration_ids` ✅; `date_range` ⚠️ (Payment-style 3-part) | 2 |

## Client-side mismatches — NOT in this PR's scope

These are **Flutter rebuild** bugs, not backend changes. Listed so the PR
author scopes correctly and so the client work can be tracked separately.
Cross-ref `lib/ui/features/*/widgets/*_filter_keys.dart` and
`lib/data/repositories/client_repository.dart` `stateQueryParams`
(memory `api-filter-sort-audit-may-2026`).

1. **Lifecycle sent on the wrong param.** `stateQueryParams()` emits
   `client_status=active,…`. Server lifecycle is `status`; `client_status`
   is computed business status. Works today only because list endpoints
   default to non-deleted. Fix: send lifecycle on `status`.
2. **Date filters use a `:gt` suffix the server can't parse.** Send a plain
   value (`created_at=2026-01-01`, server does `>=`) or `created_between` /
   `date_range`.
3. **Tasks send `project_id`/`status_id`.** Switch to `project_tasks`
   (single encoded) + `task_status` (encoded CSV).
4. **Expenses send `category_id`.** Switch to `categories` (encoded CSV).
5. **Invoices/quotes never send the (working) `date_range`.** Wire it.
6. Re-enable each gated `FilterKey` (`isAvailable => true`) only after the
   matching backend method ships **and** is curl-verified.

## Sort

App sends `sort=<field>|asc|desc`. Confirmed honored: `name`, `number`,
`updated_at`, `created_at`, `balance`, `amount`, `date`, `product_key`.
Per-entity `sort()` validates against `Schema::getColumnListing` +
`client.`/`contact.`/`documents` prefixes; **unknown column → silent
`id DESC`** (`ensureDefaultOrder`, `QueryFilters.php:123`). The app sorts the
Drift cache client-side, so server disagreement is invisible.

Unverified columns the app sends (per endpoint): Clients `paid_to_date`,
`contact_*`, `last_login_at`, `custom1..4`; document entities `due_date`,
`partial_due_date`, `paid_to_date`, `po_number`, `assigned_user_id`,
`custom_value1..4`; Recurring `next_send_date`, `frequency_id`,
`remaining_cycles`; Payments `applied`, `refunded`, `type_id`; Expenses
`payment_date`, `category_id`; Tasks `task_status_id`; Projects `due_date`,
`budgeted_hours`. **Ask:** publish the honored sortable-column list per
endpoint **and** 422 on unknown sort (priority #1).

Note: Invoice `status_id` renders a *computed* status client-side
(`calculatedStatusId`); raw `status_id` sort won't match the UI. Expose
`calculated_status_id` server-side or document the discrepancy.

## Cross-cutting API hygiene

1. **422 / `meta.warnings[]` on unknown filter params** (`QueryFilters::apply`
   `:88`). The single highest-leverage change — silent-200 hid the Tasks
   mismatch for a release and makes this whole file necessary.
2. **`date_range` has four incompatible contracts.** Standardize on one
   documented shape (recommend 3-part `column,start,end`, default
   `column=date`, used everywhere; deprecate the others):
   - base `QueryFilters::date_range:415` — 2-part `start,end`, hard `date`.
   - `PaymentFilters::date_range:275` — 3-part `_,start,end`
     (`$parts[1]`,`$parts[2]`; 2-part silently no-ops).
   - `ProjectFilters::date_range:152` — 3-part `column,start,end`
     (`$parts[0]` must be a real column).
   - `RecurringExpenseFilters::date_range:243` — 2-part `start,end`
     (`$parts[0]`,`$parts[1]`).
3. **Document `status` (lifecycle) vs `client_status` (computed) explicitly**
   in the public API reference — the overload is correct server-side but
   undocumented, and the official clients conflate them.
4. **Reject unknown sort columns** (or echo applied sort in `meta`).
5. **`number=<value>` → LIKE/prefix** across entities (currently exact).
6. **`filter=<text>` OR-scope.** Today LIKE on the primary display column
   only; users expect client-name matches in document searches.
7. **`*` in LIKE** — `name=Bob*` returns 0 (literal). Honor or document.
8. **`updated_between`** (only `created_between` exists).
9. **Uniform CSV multi-value** across all id filters.

## React-parity note

The official React client (`/Users/hillel/Code/react`) sends, per its
DataTable: `per_page`, `page`, `filter`, `sort=<f>|<dir>`, `status`
(lifecycle), `include`, `without_deleted_clients`. Tasks: `project_ids`,
`assigned_user_ids`, `client_ids`. Expenses: `categories`. Date pickers:
`date_range` (with column) + `created_between`. **Any new/renamed backend
param must stay compatible with these** — prefer adding the names React
already emits (`project_ids`, `assigned_user_ids`, `client_ids`,
`categories`) over inventing new ones.

## Appendix — reproducible curls

Auth headers from § How to verify. `→ N` = row count observed
2026-05-15/17; baseline ≈ 25 clients / 25 invoices (demo resets
periodically).

```bash
# Clients — created_at PLAIN is honored (server >=)
curl ".../clients?per_page=100&created_at=2030-01-01"     # -> 0   (honored)
# Clients — created_at:gt suffix is swallowed (wire-format mismatch)
curl ".../clients?per_page=100&created_at=2030-01-01:gt"  # -> 25  (ignored)
# Clients — country_id genuinely absent
curl ".../clients?per_page=100&country_id=840"            # -> 25  (no method)
# Invoices — base 2-part date_range IS honored on invoices
curl ".../invoices?per_page=100&date_range=2100-01-01,2100-12-31"  # -> 0
curl ".../invoices?per_page=100&date_range=1900-01-01,2100-12-31"  # -> 25
# Invoices — status_id works (Invoice-only)
curl ".../invoices?status_id=4&per_page=50"               # -> subset
# Quotes/Payments — status_id has no method (use client_status)
curl ".../quotes?status_id=2&per_page=50"                 # -> 25 (unchanged)
curl ".../payments?status_id=4&per_page=50"               # -> unchanged
# Tasks — project_id/status_id are the WRONG names (use project_tasks/task_status)
curl ".../tasks?project_id=<id>&per_page=50"              # -> 25 (unchanged)
curl ".../tasks?project_tasks=<encoded id>&per_page=50"   # -> subset (works)
# Expenses — category_id is the WRONG name (use categories)
curl ".../expenses?category_id=<id>&per_page=50"          # -> 50 (unchanged)
curl ".../expenses?categories=<encoded id>&per_page=50"   # -> subset (works)
```

Replace `<id>` / `<encoded id>` with a value from a `?per_page=1` baseline.
A param is still broken if the count is unchanged from baseline; fixed if it
shifts or returns 422.
