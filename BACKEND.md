# Invoice Ninja — list filter & sort gaps (backend PR spec)

This file is the spec for an upstream PR against the Invoice Ninja API. It
finishes the datatable **search / filter / sort** feature: the official
clients expose filter UI for many params the list endpoints silently ignore.

**Read this first:** the actionable work is in
[§ Requested backend changes](#requested-backend-changes-pr-scope). The
per-endpoint tables and curls below are the supporting evidence. A separate
[§ Client-side mismatches — FIXED](#client-side-mismatches--fixed-not-part-of-this-pr)
section lists symptoms that were *client* bugs (already fixed and shipped in
the Flutter app) so they are explicitly **out of scope** here.

**Provenance**
- **2026-05-15** — empirical curl probe vs `demo.invoiceninja.com`.
- **2026-05-17** — source-read of `app/Filters/*`; reclassified rows.
- **2026-05-17 (rev 2)** — every `app/Filters/...:line` citation
  re-verified TRUE against current source; client-side items confirmed
  fixed & shipped; restructured into this PR-scope spec; live re-probe
  refreshed the appendix to behavioral assertions.
- **2026-05-17 (rev 3)** — full 33-file `app/Filters` inventory +
  `app/Models/Client.php` schema cross-check. Corrected three claims:
  `currency_id`/`language_id` are `settings` JSON, not columns (§ A2);
  `assigned_user_id` already works via the column-guarded base
  `assigned_user_ids` (§ A3); expense `vendor_id` works via base, only
  `project_ids` is a real gap (§ C). All other claims (every
  `client_status` value set, the four `date_range` contracts, `status_id`
  Invoice-only, the ClientFilters/ExpenseFilters/TaskFilters method lists,
  `next_send_between` dual separator) verified TRUE.

The root failure mode: **`QueryFilters::apply()` does
`if (!method_exists($this,$name)) continue;`** — every unknown filter param
and every invalid `sort` column returns `200` with the unfiltered/default
set. Nothing 422s, so a client can't tell a typo/missing-filter from a real
empty result. That is why this list is needed and why the hygiene item is #1.

---

## Requested backend changes (PR scope)

Each row: **R**equired / **O**ptional · target file · what to add · one
acceptance check. IDs in Invoice Ninja are Hashids — a CSV id filter must
decode via `$this->transformKeys(explode(',', $value))` (multi) or
`$this->decodePrimaryKey($value)` (single); see the existing
`QueryFilters::client_ids():446` / `ClientFilters::group():109` for the
pattern.

### A. `app/Filters/ClientFilters.php` — add the missing id/enum filters

`ClientFilters` has only `name`, `balance`, `between_balance`, `email`,
`client_id`, `id_number`, `number`, `group`, `filter`.

**A1 — Required: real-column filters that genuinely have no method.**
`clients.country_id`, `industry_id`, `size_id` (plain int FKs),
`classification`, `vat_number` (strings) are real columns
(`app/Models/Client.php` `$fillable`) with no filter method:

```php
public function country_id(string $value = ''): Builder
{
    if (strlen($value) == 0) return $this->builder;
    return $this->builder->whereIn('country_id', explode(',', $value)); // int FK, no decode
}
// same shape (int FK, no decode): industry_id, size_id
public function classification(string $value = ''): Builder
{
    if (strlen($value) == 0) return $this->builder;
    return $this->builder->whereIn('classification', explode(',', $value)); // string column
}
public function vat_number(string $value = ''): Builder
{
    if (strlen($value) == 0) return $this->builder;
    return $this->builder->where('vat_number', 'like', "%{$value}%");
}
```
- **R.** Make `id_number` and `number` LIKE/prefix (today `where('id_number',$v)`
  / `where('number',$v)` are exact — `number=000` returns 0, not `0001..`).
- **R (CSV gap).** `group_settings_id` — a single decoded `group=<hashid>`
  already works (`ClientFilters::group():109`); add a multi `group_settings_id`
  (`whereIn('group_settings_id', $this->transformKeys(explode(',', $v)))`).
- Accept: `clients?country_id=<id>` returns fewer rows than `clients` (today:
  unchanged — no method).

**A2 — `currency_id` / `language_id` are NOT columns.** Invoice Ninja stores
client currency/language inside the `clients.settings` JSON blob (`Client.php`
casts `settings => object`; there is no `currency_id`/`language_id` column).
A `whereIn('currency_id', …)` would error. Filtering these requires a JSON
path (`where('settings->currency_id', $v)`) **and** only matches clients with
an *explicit per-client override* — it does not reflect the
group→company settings cascade, so it's semantically partial. Treat as an
**Optional design decision**, not a one-line `whereIn`. (The Flutter client
gates these filters off until resolved.)

**A3 — `assigned_user_id` is NOT absent.** The inherited base
`QueryFilters::assigned_user_ids():435` is column-guarded and
`clients.assigned_user_id` exists, so
`clients?assigned_user_ids=<hashid,…>` **already filters today** (just
undocumented). **Optional:** add a singular `assigned_user_id` alias and
document it distinctly from the owner `user_id` (today both are conflated).
No Required backend work — the client can adopt `assigned_user_ids` now
(see § Client-side).

### B. Universal `custom_value1..4` filtering — **R**

No `custom_value*` filter method exists on the base or any entity (it's only
referenced inside `filter()` free-text search). Add to a shared trait / the
base so every entity with `custom_value1..4` columns (client, invoice, quote,
credit, payment, expense, PO, recurring, project, task, vendor) gets:

```php
public function custom_value1(string $v=''): Builder
{ return strlen($v)==0 ? $this->builder : $this->builder->where('custom_value1','like',"%$v%"); }
// custom_value2, custom_value3, custom_value4
```
- Accept: `invoices?custom_value1=<known>` narrows.

### C. `app/Filters/ExpenseFilters.php`

`categories` already exists (`:185`, CSV→`whereIn('category_id', transformKeys)`).
Inherited base methods already cover **single** `vendor_id`
(`QueryFilters:303`, decoded, column-guarded), `client_id` (`:294`) and CSV
`client_ids` (`:446`) — expenses have those columns, so those filters work
today. The genuine gap is **project filtering** — no `project_*` method
exists on `ExpenseFilters` or the base.

**R.** Add `project_ids` (the real gap):
```php
public function project_ids(string $v=''): Builder
{ if(strlen($v)==0) return $this->builder; return $this->builder->whereIn('project_id', $this->transformKeys(explode(',', $v))); }
```
**O.** Add a CSV `vendor_ids` convenience (single `vendor_id` already works
via base — this is only for multi-select):
```php
public function vendor_ids(string $v=''): Builder
{ if(strlen($v)==0) return $this->builder; return $this->builder->whereIn('vendor_id', $this->transformKeys(explode(',', $v))); }
```
- Accept: `expenses?project_ids=<id>` narrows (today: unchanged — no method);
  `expenses?vendor_id=<hashid>` already narrows via base.

### D. `app/Filters/ProjectFilters.php` — **R**

Add `assigned_user` / `assigned_user_ids` (mirror base
`QueryFilters::assigned_user_ids():435`). Accept: `projects?assigned_user_ids=<id>`
narrows.

### E. Base — `updated_between` — **R**

Only `created_between` exists (`QueryFilters:389`, 2-part on `created_at`).
Add the symmetric `updated_between` (2-part `start,end`, `whereBetween('updated_at',…)`).

### E2. Comparable date / numeric operators — **SHIPPED in this fork**

`feat/list-filter-sort-gaps` now carries `QueryFilters::comparableDate()`
and rewires `created_at` / `updated_at` (base) + `date` / `due_date`
(`InvoiceFilters`, and new methods on `QuoteFilters` / `CreditFilters`)
through it. Contract the Flutter client relies on:

- **Canonical wire = PREFIX `op:value`** (`created_at=gte:2026-01-01`,
  `balance=gt:5000`). `op ∈ {lt,gt,lte,gte,eq}` via the existing
  `split()` / `operatorConvertor()`. `ClientFilters::balance()` already
  used this — the client now sends it (fixes the prior suffix
  `value:op` → `where(col,'=','op')` zero-row bug).
- **Bare value (no op prefix) keeps the historical default** — the date
  filters default to `>=`, so legacy `created_at=<date>` and other API
  clients are unchanged.
- **`whereDate` calendar-day semantics** for date-only values: `eq` is
  "that calendar day", `before`/`after` are day-granular. A value
  carrying a time component uses an exact `where`.
- **Malformed input is a silent no-op** (returns the unfiltered set, no
  422 — matches the framework's `method_exists` skip contract).
  `due_date()` previously had no try/catch and would 500 on an
  `op:value` wire; `comparableDate()` fixes that.
- **`split()` colon invariant:** a value must not itself contain `:`
  (the date filters use `explode(':', $v, 2)`; `balance` uses the
  unlimited `split()`). The client guarantees date-only / numeric
  values. The rolling **`rel:` relative token is resolved to an
  absolute value client-side** and never reaches the API.

Tests: `tests/Feature/QueryFilterEnhancementsTest.php` (created_at
gt/lte/eq-calendar-day, plain-date still `>=`, balance prefix, invoice
date/due_date, quote/credit date, malformed-is-safe).

### E3. `date_range` / `due_date_range` standardization — **SHIPPED in this fork**

`feat/list-filter-sort-gaps` standardized the date-window filters on the
**base** `QueryFilters` so every entity behaves identically (resolves the
G.3 punch-list item below; the per-entity overrides described in the
Hygiene detail no longer apply on this branch):

- **`QueryFilters::date_range()`** (`:501`) is now arity-tolerant +
  column-aware: 2-part `start,end` → `whereBetween('date', …)`; 3-part
  `column,start,end` → `whereBetween(column, …)` when `column` is a real
  table column; 3-part placeholder `_,start,end` → defaults to `date`
  (absorbs the old Payment / Project / RecurringExpense contracts).
  Silent no-op on a non-existent column or unparseable bound.
- **`QueryFilters::due_date_range()`** (`:603`) now mirrors `date_range()`
  exactly, defaulting the column to `due_date`. This fixes the prior
  2-part-only guard that silently dropped the Flutter client's canonical
  3-part `due_date_range=due_date,<start>,<end>`. Inherited by
  Invoices / Quotes / Credits; no per-entity override needed.
- Flutter client wire: `date` "between" → `date_range=date,<s>,<e>`;
  `due_date` "between" → `due_date_range=due_date,<s>,<e>` (legacy 2-part
  `<s>,<e>` still parsed both client- and server-side).

Tests: `tests/Feature/QueryFilterEnhancementsTest.php` —
`testDateRange{Legacy,CanonicalThreePart}*`, `testPaymentLegacyThreePart*`,
`testDueDateRange{LegacyTwoPart,CanonicalThreePart,ThreePartOnQuotesAndCredits,MalformedIsSafeNoOp}`.

### F. `status_id` parity — **O**

`status_id` is defined **only** in `InvoiceFilters:148`. Optional: add the
same `whereIn('status_id', explode(',', $v))` to Quote/Credit/Payment/
PurchaseOrder/RecurringInvoice filters for cross-entity consistency. Low
priority — the official clients use the computed `client_status` for these.

### F1. `QuoteFilters::client_status` — missing `rejected` — **O**

`client_status` handles `sent / draft / approved / expired / upcoming /
converted` but has **no `rejected` branch**, so `client_status=rejected`
hits the global silent-no-op (returns the unfiltered set). Quotes do carry
`STATUS_REJECTED = 5` (set when a client rejects in the portal), and the
official clients expose a "Rejected" filter chip. Requested: add
`if (in_array('rejected', $status_parameters)) $query->orWhere('status_id',
Quote::STATUS_REJECTED);`. Low priority — the v2 client already filters
`rejected` **locally** as a deliberate approximation (the chip narrows
cached rows), so this only improves server-side narrowing for large lists.

### G. Hygiene — highest leverage

1. **R (non-breaking first).** Unknown filter param → surface in a
   `meta.warnings: []` envelope key (always-on, additive, safe). Then add an
   **opt-in strict mode** (`?strict=true` or `X-Strict-Filters: 1`) that
   `422`s on unknown param / invalid sort. A hard 422 by default would break
   existing integrations that lean on silent-ignore — ship the warning
   envelope first.
2. **R.** Invalid/unknown `sort` column: same — echo the applied sort in
   `meta` and/or warn; today it silently falls back to
   `ensureDefaultOrder()` → `orderByDesc(getQualifiedKeyName())`
   (effectively `<table>.id DESC`), so the client can't detect disagreement.
3. ~~**R.** Standardize `date_range` to **one** contract — recommend 3-part
   `column,start,end` with `column` defaulting to `date` — and apply it on
   the base so all entities behave identically.~~ **SHIPPED in this fork —
   see § E3** (`date_range` + `due_date_range` now unified on the base;
   the four-contract divergence below is the pre-fork state).
4. **O.** `filter=<text>` OR-scope: today LIKE on the primary display column
   only; users expect e.g. an invoice search to match the client name.
5. **O.** Honor `*` as a wildcard in LIKE filters (or document that values
   are always `%v%`-wrapped) — `name=Bob*` returns 0 today (literal `*`).
6. **R.** Publish the per-endpoint **filter + sortable-column contract** in
   the public API reference (today aspirational on most list endpoints) and
   document `status` (lifecycle) vs `client_status` (computed business
   status) — the overload is correct server-side but undocumented and the
   official clients historically conflated them.

**Compatibility constraint:** the official React client already emits
`project_ids`, `assigned_user_ids`, `client_ids`, `categories`,
`date_range` (with column), `created_between`, lifecycle on `status`. Prefer
these exact names for any new param — see [§ React-parity](#react-parity-note).

See [§ Acceptance & rollout](#acceptance--rollout) for done-criteria.

---

## How to verify a row

Self-contained — runs against the public demo (canned read-only creds; the
demo dataset resets periodically so assert **behavior** — "narrows vs
baseline" / "unchanged" / "422" — not exact counts):

```
BASE=https://demo.invoiceninja.com/api/v1
curl "$BASE/clients?per_page=100" \
  -H "Content-Type: application/json" \
  -H "X-API-SECRET: password" \
  -H "X-API-TOKEN: TOKEN" \
  -H "X-Requested-With: XMLHttpRequest"
```

A row is **fixed** when changing the param value changes the response
(different count/order, or 422 on a malformed value). Today almost every
unknown param returns 200 with the unfiltered set — that's the bug class.

## What the base `QueryFilters` already provides

`app/Filters/QueryFilters.php` is inherited by **every** per-entity
`*Filters`. Each method is **column-guarded** (`in_array('<col>',
Schema::getColumnListing($table))`) → it works on **any** entity whose table
has that column, even with no entity-specific method. This is load-bearing:
it means `assigned_user_ids` already filters clients, `vendor_id` already
filters expenses, etc. — those are *not* gaps.

| Param | Behavior | Source |
|---|---|---|
| `status=active,archived,deleted` | Entity **lifecycle** (`deleted_at`/`is_deleted`). Distinct param from computed `client_status`; never collide server-side. | `QueryFilters.php:172` |
| `created_at=<date\|ts>` | `created_at >= Carbon::parse(value)`. **Plain value only** — an operator suffix (`:gt`) throws and is swallowed → unfiltered. | `:238` |
| `updated_at=<date\|ts>` | `updated_at >= value`. Same plain-value contract. | `:257` |
| `created_between=<start>,<end>` | `whereBetween('created_at', …)`. **2-part.** No `updated_between` exists. | `:389` |
| `date_range=<start>,<end>` | `whereBetween('date', …)`. **2-part, base contract** (overridden inconsistently — see Hygiene). | `:415` |
| `due_date_range=<start>,<end>` | `whereBetween('due_date', …)`. 2-part. | `:463` |
| `client_id=<id>` | single, decoded hashid, column-guarded. | `:294` |
| `vendor_id=<id>` | single, decoded hashid, column-guarded → **filters expenses/POs today**. | `:303` |
| `client_ids` / `assigned_user_ids` | multi, CSV of **hashids** (`transformKeys`), column-guarded → `assigned_user_ids` **filters clients today** (clients.assigned_user_id exists). | `:446` / `:435` |
| (dispatch) | Unknown param → `if (!method_exists(...)) continue;` (**silent 200**). Invalid `sort` → `ensureDefaultOrder()` → `orderByDesc(getQualifiedKeyName())` ≈ `<table>.id DESC`. | `:88` / `:123` |

`per_page` is capped `min(abs(input), 5000)`, default 20
(`app/Http/Controllers/BaseController.php:606`).

## Legend

- ✅ Works — server honors the param.
- ⚠️ Partial — works with unexpected semantics (exact where LIKE expected).
- ❌ Silently ignored — 200 OK, set unchanged, **no server method exists**
  (genuine backend gap → in PR scope).
- 🔁 Historical — server supports it; the symptom was a *client* wire-format
  / param-name mismatch, **already fixed & shipped client-side** (see
  § Client-side — FIXED). **No backend action.**
- 🚫 Not implemented.
- **untested** — wanted by the app; no controlled probe yet.

## Per-endpoint evidence (supporting detail)

Skipping small reference endpoints (designs, payment_terms, tax_rates,
webhooks, tokens, schedulers, subscriptions, company_gateways,
expense_categories, transaction_rules) — state filtering only.

### GET /api/v1/clients — `app/Filters/ClientFilters.php`

`ClientFilters` adds only `name`, `balance`, `between_balance`, `email`,
`client_id`, `id_number`, `number`, `group`, `filter`. Rest is inherited or
absent (→ § A).

| Param | Current | Backend ask |
|---|---|---|
| `filter=<text>` | ✅ LIKE on `name` | OR name + number + contact name/email (G.4) |
| `name=<text>` | ✅ LIKE | keep |
| `status=active,archived,deleted` | ✅ base `:172` lifecycle | keep (correct lifecycle param) |
| `number=<value>` | ⚠️ exact (`number=000`→0) | LIKE/prefix (§ A) |
| `id_number=<value>` | ⚠️ exact (`:91`) | LIKE substring (§ A) |
| `email=<value>` | ⚠️ exact, via `whereHas('contacts', email = v)` relationship (`:71`) | LIKE substring on the contact email |
| `balance=<n>:gt\|lt\|gte\|lte\|eq` | ✅ suffix-operator (`ClientFilters::balance:43`); `between_balance` uses `min:max` (`:60`) | keep; document both shapes |
| `created_at=<date>` plain | ✅ base `:238` | keep |
| `created_between` | ✅ base `:389` | keep |
| `country_id` `industry_id` `size_id` | ❌ no method (real int-FK columns) | § A1 (Required) |
| `classification` `vat_number` | ❌ no method (real string columns) | § A1 (Required) |
| `group_settings_id` | ⚠️ single decoded `group=` works (`:109`); no CSV | § A1 (CSV gap) |
| `currency_id` `language_id` | 🚫 not columns — in `clients.settings` JSON | § A2 (Optional, JSON, partial) |
| `assigned_user_id` | ⚠️ works via inherited base `assigned_user_ids` (`QueryFilters:435`, column-guarded); undocumented | § A3 (Optional alias only) |
| `custom_value1..4` | ❌ no method anywhere | § B (Required) |
| `user_id` vs `assigned_user_id` | ⚠️ both unchanged | disambiguate owner vs assignee, or deprecate one |

### GET /api/v1/invoices — `app/Filters/InvoiceFilters.php`

| Param | Current | Backend ask |
|---|---|---|
| `filter` | ✅ LIKE on `number` | OR + client name + po_number (G.4) |
| `client_id`/`client_ids` · `status_id` (`:148`) · `client_status` (draft\|paid\|unpaid\|overdue\|cancelled) · `overdue` · `status` lifecycle · `date`/`due_date` `>=` · `due_date_range` | ✅ | keep |
| `overdue` (note) | ✅ `InvoiceFilters::overdue():197` is a **no-arg** method; the dispatcher calls it whenever `overdue` is present and **ignores the value** (`overdue=false` still filters to overdue). Send only when active. | keep |
| `date_range=<s>,<e>` 2-part | ✅ inherits base `:415` (re-probed: far-future range → 0) | keep; standardize arity (G.3) |
| `project_id`/`project_ids` | ❌ no method | add `project_ids` (hashid CSV) |
| `start_date`/`end_date` | 🔁 no such method — the window is `date_range` (historical client naming; now sends `date_range`) | none (use `date_range`); optional aliases |
| `custom_value1..4` | ❌ | § B |

### GET /api/v1/quotes · /credits — `Quote/CreditFilters.php`

`filter`, `client_id`, `status` lifecycle, `created_between`, `client_status`
(quote `draft\|sent\|approved\|expired\|upcoming\|converted`; credit
`draft\|sent\|partial\|applied`), `date_range` (base 2-part) → ✅ keep.
`status_id` ❌ → § F (optional). `custom_value1..4` ❌ → § B.

### GET /api/v1/payments — `app/Filters/PaymentFilters.php`

`filter`, `client_id`, `status` lifecycle, `client_status`
(`pending\|cancelled\|failed\|completed\|partially_refunded\|refunded\|partially_unapplied`)
→ ✅. `date_range` ⚠️ **3-part** `_,start,end` (`PaymentFilters:275`, uses
`$parts[1]`,`$parts[2]`, `isset($parts[2])` required; a 2-part value
silently no-ops) → standardize (G.3). `status_id` ❌ → § F. `custom_value*`
❌ → § B.

### GET /api/v1/expenses — `app/Filters/ExpenseFilters.php`

`filter`, `client_id`, `status` lifecycle, `client_status`,
`payment_type`, `amount`, `number`, `has_invoices`, `match_transactions`
→ ✅. `categories=<id,id>` ✅ (`:185`, hashid CSV→`whereIn('category_id',…)`;
canonical name — `category_id` was never a method; the client now sends
`categories`, fixed). `project_ids`/`vendor_ids` ❌ → § C.
`custom_value1..4` ❌ → § B.

### GET /api/v1/tasks — `app/Filters/TaskFilters.php`

Canonical server names: `project_tasks=<hashid>` (single, `:97`,
`where('project_id', decode)`) ✅; `task_status=<hashid,…>` (CSV, `:236`,
`whereIn('status_id', transformKeys)` **plus `whereNull('invoice_id')`** —
filtering by status also hides invoiced tasks, server-side) ✅;
`client_status=invoiced\|uninvoiced\|is_running` ✅; `assigned_user`,
`user_id`, `hash`, `number` ✅. `project_id`/`status_id` 🔁 — no such method;
this was the headline "visible UI bug" but it was a *client* param-name
mismatch, **fixed & shipped** (client now sends `project_tasks`/`task_status`).
Optional: add `project_ids`/`status_id` aliases for cross-entity
consistency. `custom_value1..4` ❌ → § B.

### GET /api/v1/projects — `app/Filters/ProjectFilters.php`

`filter`, `client_id`, `number`, `status` lifecycle → ✅.
`date_range=<col>,<start>,<end>` ⚠️ **3-part with explicit column**
(`ProjectFilters:152`, `$parts[0]` must be a real column) → standardize
(G.3). `assigned_user`/`assigned_user_ids` ❌ → § D.

### GET /api/v1/recurring_invoices · /recurring_expenses

`filter`, `client_id`, `status` lifecycle, `client_status` ✅.
`next_send_between` ✅ but accepts **both** `|` and `,` separators — pick one
+ document. `frequency_id`, `product_key` (rec. invoices) ✅. `date_range`
(recurring_expenses) ⚠️ **2-part `$parts[0],$parts[1]`**
(`RecurringExpenseFilters:243`) — a *fourth* contract → standardize (G.3).
`custom_value1..4` ❌ → § B.

### GET /api/v1/purchase_orders · /vendors · /products · /bank_transactions

| Endpoint | Notable gaps |
|---|---|
| purchase_orders | `status_id` ❌ (use `client_status=draft\|sent\|accepted\|cancelled`; § F optional); `start_date/end_date` 🔁 (use base `date_range`); `custom_value1..4` ❌ (§ B) |
| vendors | `number` ⚠️ exact; `vat_number`/`id_number` substring ❌; `country_id`/`currency_id`/`assigned_user_id`/`custom_value1..4` ❌ — mirror § A |
| products | `product_key` ✅ exact; `filter` ✅ LIKE on product_key/notes; no enum filters needed |
| bank_transactions | `name` ✅; `client_status=unmatched\|matched\|converted\|deposits\|withdrawals` ✅; `bank_integration_ids` ✅; `date_range` ⚠️ Payment-style 3-part → standardize (G.3) |

## Client-side mismatches — FIXED (not part of this PR)

These were **Flutter client** bugs (wrong param name / wire format) against
already-working server params — all fixed & committed 2026-05-17. Listed so
the backend reviewer knows they need **no backend work**. *(Flutter-repo
context — not required to action this PR.)*

1. ✅ Lifecycle now sent on `status` (was `client_status` on Client/Vendor,
   nothing elsewhere — archived/deleted views were silently empty).
   Resolves the quote/payment `client_status` collision.
2. ✅ Client `created`/`updated` send a plain date (no `:gt`); server `>=`.
3. ✅ Tasks send `project_tasks` (single) + `task_status`.
4. ✅ Expenses send `categories` (CSV). Expense **`vendor_id`** (single) and
   `client_id`/`client_ids` already work via the inherited base methods;
   only `project_ids` is a real backend gap → § C.
5. ✅ Invoices/quotes send the (working) 2-part `date_range`; the dashboard
   invoice KPI sends a closed `date_range`.

**Available with no backend change (client can adopt now):**
`assigned_user_ids` (CSV hashids) already filters **clients** and any entity
whose table has `assigned_user_id`, via the column-guarded base
`QueryFilters::assigned_user_ids:435`. Single `vendor_id` already filters
**expenses**. These need only a client-side wiring change, not a PR.

## Sort

App sends `sort=<field>|asc|desc`. Confirmed honored: `name`, `number`,
`updated_at`, `created_at`, `balance`, `amount`, `date`, `product_key`.
Per-entity `sort()` validates against `Schema::getColumnListing` +
`client.`/`contact.`/`documents` prefixes; **unknown column → silent
`ensureDefaultOrder()`** (`QueryFilters:123`). Clients sort the cache
locally, so server disagreement is invisible → see Hygiene G.2.

Unverified columns the app sends: Clients `paid_to_date`, `contact_*`,
`last_login_at`, `custom1..4`; document entities `due_date`,
`partial_due_date`, `paid_to_date`, `po_number`, `assigned_user_id`,
`custom_value1..4`; Recurring `next_send_date`, `frequency_id`,
`remaining_cycles`; Payments `applied`, `refunded`, `type_id`; Expenses
`payment_date`, `category_id`; Tasks `task_status_id`; Projects `due_date`,
`budgeted_hours`. Invoice `status_id` sort renders a *computed* status
client-side — expose `calculated_status_id` server-side or document the
mismatch.

## Cross-cutting API hygiene

1. Unknown filter param: `meta.warnings[]` (non-breaking), then opt-in
   strict `422` (`QueryFilters::apply:88`). **The single highest-leverage
   change.**
2. Invalid sort column: warn / echo applied sort (`:123`).
3. **`date_range` has four incompatible contracts** — standardize (3-part
   `column,start,end`, default `date`):
   - base `QueryFilters::date_range:415` — 2-part `start,end`, hard `date`.
   - `PaymentFilters::date_range:275` — 3-part `_,start,end`.
   - `ProjectFilters::date_range:152` — 3-part `column,start,end`.
   - `RecurringExpenseFilters::date_range:243` — 2-part `$parts[0],$parts[1]`.
4. `number=<value>` → LIKE/prefix across entities (currently exact).
5. `filter=<text>` OR-scope beyond the primary display column.
6. `*` wildcard in LIKE (`name=Bob*` → 0 today).
7. `updated_between` (only `created_between` exists).
8. Uniform hashid CSV multi-value across all id filters.
9. Document `status` vs `client_status` + per-endpoint contract publicly.

## React-parity note

The official React client emits, per its DataTable: `per_page`, `page`,
`filter`, `sort=<f>|<dir>`, `status` (lifecycle), `include`,
`without_deleted_clients`; Tasks `project_ids`/`assigned_user_ids`/
`client_ids`; Expenses `categories`; date pickers `date_range` (with
column) + `created_between`. **New params must use these exact names** so
both official clients converge.

## Acceptance & rollout

- **Per change:** the acceptance curl in § A–F changes the result set
  (narrows / 422 on malformed) where today it is unchanged. Add/extend the
  backend's own filter feature tests alongside.
- **Hygiene 422:** ship `meta.warnings[]` (additive, no version bump) first;
  gate hard `422` behind opt-in (`?strict=true` / header) so existing API
  consumers don't break. Document in the API changelog.
- **`date_range` standardization:** keep accepting the legacy per-entity
  shapes for one deprecation cycle (parse 2-part *and* 3-part); log a
  deprecation warning via the `meta.warnings[]` channel.
- **Naming:** match the React param names (§ React-parity) so the PR doesn't
  fork client behavior.

## Appendix — reproducible curls (behavioral)

Auth headers from § How to verify. Demo resets — assert the **direction**,
not the count. Last reproduced 2026-05-17: clients/invoices/tasks baseline
≈25, expenses ≈72.

```bash
# Genuine gaps — param has no method, set is UNCHANGED vs baseline:
curl "$BASE/clients?per_page=100&country_id=840"          # unchanged  → § A
curl "$BASE/clients?per_page=100&custom_value1=zzz"       # unchanged  → § B
curl "$BASE/expenses?per_page=100&project_ids=<id>"       # unchanged  → § C
# Base filters that DO work (regression guards, keep working):
curl "$BASE/clients?per_page=100&created_at=2030-01-01"   # → 0 (>=)
curl "$BASE/invoices?per_page=100&date_range=2100-01-01,2100-12-31" # → 0
curl "$BASE/tasks?per_page=100&project_tasks=<projectId>" # narrows
curl "$BASE/expenses?per_page=100&categories=<catId>"     # narrows (source-verified; demo had no category data to probe)
# Hygiene target — today returns 200 + unfiltered; after PR: meta.warnings[] / 422 in strict mode:
curl "$BASE/clients?per_page=100&bogus_param=1"           # 200 unchanged (the bug)
```

`<id>`/`<projectId>`/`<catId>` = a value from a `?per_page=1` baseline call.

## OAuth — Microsoft / Azure (client-side gap, not a server gap)

FEATURES.md line 65 stays ❌ deliberately. The `/api/v1/oauth_login` and
`/api/v1/connected_account?provider=microsoft` exchanges already work
(identical to the shipped Google/Apple path — `AuthService.oauthLogin`,
`UsersApi.connectOauth`). The blocker is **client-side token acquisition**:
there is no maintained native Flutter MSAL SDK (admin-portal is web-only
`msal_js`; `aad_oauth` is deprecated/unmaintained, webview-based). Until a
stable native Flutter MSAL option exists, Microsoft sign-in cannot be
shipped to the verified standard Google/Apple were — so it is NOT flipped.
No server change is required; this note exists only so the gap is traceable.

---

## Web platform CORS — `Idempotency-Key` not allow-listed — **R (server gap, blocks web writes)**

**Provenance** — 2026-05-19, live `OPTIONS` preflight probe vs
`demo.invoiceninja.com` while adding the web platform target.

The web build runs at a browser origin and calls the API cross-origin, so
every request is subject to CORS preflight. `ApiClient._buildHeaders`
(`lib/data/services/api_client.dart:756-768`) sends `Idempotency-Key` on
**every outbox write** (stable per outbox row, the M1 retry-safety
contract — see CLAUDE.md § Sync). The demo server's preflight response
does **not** allow that header:

```
$ curl -s -i -X OPTIONS 'https://demo.invoiceninja.com/api/v1/clients' \
    -H 'Origin: https://admin.example.com' \
    -H 'Access-Control-Request-Method: POST' \
    -H 'Access-Control-Request-Headers: idempotency-key'
access-control-allow-origin: *
access-control-allow-methods: POST, GET, OPTIONS, PUT, DELETE
access-control-allow-headers: X-CLIENT-PLATFORM,X-React,X-API-PASSWORD-BASE64,
  X-API-COMPANY-KEY,X-CLIENT-VERSION,X-API-SECRET,X-API-TOKEN,X-API-PASSWORD,
  DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,
  Content-Disposition,Range,X-CSRF-TOKEN,X-XSRF-TOKEN,X-LIVEWIRE,X-Socket-ID
```

`Idempotency-Key` is absent → the browser blocks every web write
(create/update/delete) at preflight. All other admin-client headers
(`X-API-TOKEN`, `X-API-PASSWORD-BASE64`, `X-CLIENT-*`, `X-API-SECRET`,
`X-Requested-With`, `Content-Type`) **are** allowed, so reads and login
work; only writes are blocked.

**Required change** — add `Idempotency-Key` to the API's CORS
`Access-Control-Allow-Headers` list (the middleware/config that produces
the header set above; mirror how `X-API-TOKEN` is registered).

**Optional, same change site** — add
`Access-Control-Expose-Headers: X-MINIMUM-CLIENT-VERSION`. There is no
`Access-Control-Expose-Headers` in the response today, so the
`x-minimum-client-version` response header (read on every request to throw
`ClientTooOldException` — CLAUDE.md § Sync) is invisible to JS on web. It
fails open (the min-version gate silently never trips on web) rather than
breaking anything, so this is **O**, not **R**. Pagination needs nothing
here — the keyset cursor reads `data.last` from the body, not a header.

**Acceptance** — re-run the curl above with
`Access-Control-Request-Headers: idempotency-key`; `Idempotency-Key` must
appear in the returned `access-control-allow-headers`. Then a web build
create/edit/delete must complete instead of failing with a console CORS
preflight error.

Until this ships, web is **read + login only**; outbox drains will fail at
the network layer (surfaced as transient sync errors). Client code needs
no change — `Idempotency-Key` stays sent unconditionally; it is correct
and required for retry safety on every platform.
