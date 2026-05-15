# Backend API gaps — filter & sort

Hand-edited tracker of gaps between what list endpoints currently honor and what the v2 Flutter admin app needs. Last probed **2026-05-15** against `demo.invoiceninja.com`. Companion to `FEATURES.md`.

Each row is reproducible. Backend devs: pick a row, run its curl, change the param value, observe the response. If the result count or order changes, the param is honored; if not, the row is real.

## How to verify a row

Auth headers (canned demo creds — see `docs/probing-the-demo-api.md`):

```
X-API-SECRET: password
X-API-TOKEN: <demo token>
X-Requested-With: XMLHttpRequest
Content-Type: application/json
```

A row is **fixed** when changing the param value produces a corresponding change in the response — different result count, different order, or 422 on a malformed value. Today the API returns 200 with the unfiltered set for almost every unknown param, which is why this list exists.

## Legend

- ✅ Works — server honors the param, results change as expected.
- ⚠️ Partial — works but with unexpected semantics (exact match where LIKE expected, etc.).
- ❌ Silently ignored — server accepts the param and returns 200 OK, but result set is unchanged.
- 🚫 Not implemented in API.
- **untested** — Flutter app sends or wants to send this; we haven't run a controlled probe yet.

## Priority — fix order

Ordered by user pain. Numbers are referenced from per-endpoint tables below.

1. **Tasks: `project_id` + `status_id`** — visible token filters today that produce zero server-side narrowing. Users pick a project / status, list doesn't change. Highest-impact bug surfaced by this audit.
2. **Universal `updated_at` / `created_at` range filtering** (operator-suffix `updated_at=2025-01-01:gt`, or separate `gte` / `lte` params). Sort works; filter form does not.
3. **`status_id` on `/quotes`, `/credits`, `/payments`.** Works on `/invoices`. Asymmetry blocks status chips on three list screens.
4. **Date range (`start_date` / `end_date`) on document entities** — `/invoices`, `/quotes`, `/credits`, `/payments`, `/expenses`, `/recurring_invoices`, `/purchase_orders`. Legacy admin-portal supported these.
5. **`custom_value1..4` filtering** on every entity with custom fields. Currently silently ignored everywhere.
6. **Clients enum filters**: `country_id`, `industry_id`, `size_id`, `currency_id`, `language_id`, `group_settings_id`, `assigned_user_id`, `classification`. Eight params, all silently ignored.
7. **`vat_number` / `id_number` substring on `/clients` and `/vendors`.** Accountant workflow.
8. **Expenses: `category_id`, `project_id`, `vendor_id`.** Today only `client_id` works.
9. **`number=<value>` → LIKE, not exact.** `number=000` should return all `0001..0099`. Today returns 0.
10. **API hygiene**: return 422 (or a `warnings` envelope) on unknown filter params, and publish a per-endpoint filter contract.

## Per-endpoint gaps

Skipping the small reference tables (designs, payment_terms, tax_rates, webhooks, tokens, schedulers, subscriptions, company_gateways, expense_categories, transaction_rules) — they only expose state filtering today and have no pending filter requests.

### GET /api/v1/clients

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ LIKE on `name` only | Could OR across name + number + contact name + contact email for parity with how users search | — |
| `name=<text>` | ✅ LIKE | Keep | — |
| `client_status=active,archived,deleted` | ✅ Honored | Keep | — |
| `number=<value>` | ⚠️ Exact match — `number=000` → 0 | LIKE / prefix match | 9 |
| `id_number=<value>` | ❌ Silently ignored | LIKE substring | 7 |
| `email=<value>` | ⚠️ Likely exact (untested) | LIKE on primary contact email | — |
| `balance=<n>:gt\|lt\|gte\|lte\|eq\|ne` | ✅ Suffix-operator syntax honored. `between` 🚫. | Keep | — |
| `custom_value1` / `custom_value2` / `custom_value3` / `custom_value4` | ❌ Silently ignored | LIKE substring | 5 |
| `country_id=<id>` | ❌ Silently ignored | Exact match (CSV for multi-value) | 6 |
| `industry_id=<id>` | ❌ Silently ignored | Exact match (CSV) | 6 |
| `size_id=<id>` | ❌ Silently ignored | Exact match (CSV) | 6 |
| `currency_id=<id>` | ❌ Silently ignored | Exact match (CSV) | 6 |
| `language_id=<id>` | ❌ Silently ignored | Exact match (CSV) | 6 |
| `group_settings_id=<id>` | ❌ Silently ignored | Exact match (CSV) | 6 |
| `assigned_user_id=<id>` | ❌ Silently ignored (returns all 25) | Exact match (CSV) — must be distinct from `user_id` (owner) | 6 |
| `vat_number=<value>` | ❌ Silently ignored | LIKE substring | 7 |
| `classification=<value>` | ❌ Silently ignored | Exact match (CSV) | 6 |
| `created_at=<date>:gt\|lt` | ❌ Silently ignored | Operator-suffix range, same shape as `balance` | 2 |
| `updated_at=<date>:gt\|lt` | ❌ Silently ignored | Operator-suffix range | 2 |
| `user_id=<id>` | ⚠️ Accepted but doesn't narrow (returns all 25) | Either filter by owner distinctly from `assigned_user_id`, or deprecate one | 10 |
| `is_deleted=<bool>` | ❌ Silently ignored | Either honor or remove from docs | 10 |

### GET /api/v1/invoices

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ LIKE on `number` only | Could OR across number + client name + PO number | — |
| `client_id=<id>` | ✅ Exact match (`client_id=oBDbDxbl2E` → 3) | Keep | — |
| `status_id=<n>` | ✅ Exact match (`status_id=4` → 19) | Keep | — |
| `is:active\|archived\|deleted` (entity state) | ✅ Honored via `client_status`-style param | Keep | — |
| `project_id=<id>` | ❌ Silently ignored | Exact match (CSV) | 10 |
| `vendor_id=<id>` | **untested** | Exact match (CSV) | — |
| `user_id=<id>` | ⚠️ Accepted, no narrowing | Filter by owner | 10 |
| `invoice_status=<string>` | ❌ Silently ignored | Either honor (with `draft\|sent\|paid\|partial\|overdue`) or remove — `status_id` numeric works fine | 10 |
| `start_date=<YYYY-MM-DD>` | ❌ Silently ignored | Filter by invoice date `>=` | 4 |
| `end_date=<YYYY-MM-DD>` | ❌ Silently ignored | Filter by invoice date `<=` | 4 |
| `updated_at=<ts>` (filter, not sort) | ❌ Silently ignored | Operator-suffix range | 2 |
| `custom_value1..4` | ❌ Silently ignored | LIKE substring | 5 |

### GET /api/v1/quotes

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works (LIKE on number) | Keep | — |
| `client_id=<id>` | ✅ Exact match (`client_id=yMYerEdOBQ` → 2) | Keep | — |
| `status_id=<n>` | ❌ Silently ignored (`status_id=2` → 25 unchanged) | Exact match (CSV) | 3 |
| `is:active\|archived\|deleted` | ✅ Honored | Keep | — |
| `project_id=<id>` | **untested**, expected ignored | Exact match (CSV) | 10 |
| `start_date` / `end_date` | **untested**, expected ignored | Date filter | 4 |
| `custom_value1..4` | ❌ Silently ignored | LIKE substring | 5 |

### GET /api/v1/credits

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works | Keep | — |
| `client_id=<id>` | ✅ Exact match (`client_id=q9wdLwbjPX` → 2) | Keep | — |
| `status_id=<n>` | **untested**, mirrors Quotes — expected ignored | Exact match (CSV) | 3 |
| `is:*` | ✅ Honored | Keep | — |
| `start_date` / `end_date` | **untested** | Date filter | 4 |
| `custom_value1..4` | ❌ Silently ignored | LIKE substring | 5 |

### GET /api/v1/recurring_invoices

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works | Keep | — |
| `client_id=<id>` | ✅ Exact match (`client_id=oBDbDxbl2E` → 3) | Keep | — |
| `is:*` | ✅ Honored | Keep | — |
| `frequency_id` | **untested**, not exposed | Exact match (CSV) | — |
| `status_id` / status | **untested** | Exact match (CSV) | 3 |
| `next_send_date` range | **untested** | Operator-suffix range | 2 / 4 |
| `remaining_cycles` | **untested** | Operator-suffix range | — |
| `auto_bill=<bool>` | **untested** | Exact bool | — |

### GET /api/v1/purchase_orders

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works | Keep | — |
| `vendor_id=<id>` | **untested** (no vendor PO data in demo) | Exact match (CSV) | — |
| `client_id=<id>` | **untested** | Exact match (CSV) | — |
| `status_id=<n>` | **untested** | Exact match (CSV) | 3 |
| `is:*` | ✅ Honored | Keep | — |
| `start_date` / `end_date` | **untested** | Date filter | 4 |

### GET /api/v1/payments

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works | Keep | — |
| `client_id=<id>` | ✅ Exact match (`client_id=oBDbDxbl2E` → 3) | Keep | — |
| `status_id=<n>` | ❌ Silently ignored (returns all 19) | Exact match (CSV) | 3 |
| `is:active\|archived` | ⚠️ Works, but **no `deleted` state available** for payments | Add `deleted` state | — |
| `company_gateway_id` | **untested** | Exact match (CSV) | — |
| `type_id` | **untested** | Exact match (CSV) | — |
| `has_unapplied_funds=<bool>` | **untested** (UI has dedicated toggle) | Boolean filter | — |
| `start_date` / `end_date` | **untested** | Date filter | 4 |

### GET /api/v1/expenses

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works | Keep | — |
| `client_id=<id>` | ✅ Exact match (verified 3) | Keep | — |
| `vendor_id=<id>` | ⚠️ Likely ignored — `vendor_id=test` → 0, but demo has no vendor data | Exact match (CSV) | 8 |
| `category_id=<id>` | ❌ Silently ignored (returns all 50) | Exact match (CSV) | 8 |
| `project_id=<id>` | ❌ Silently ignored | Exact match (CSV) | 8 |
| `is:active\|archived` | ✅ Honored | Add `deleted` state if expenses support it | — |
| Expense status (paid / pending / etc.) | ❌ UI status chips above list not wired to API | New status filter param | — |
| `start_date` / `end_date` | **untested** | Date filter on expense date | 4 |
| `custom_value1..4` | ❌ Silently ignored | LIKE substring | 5 |

### GET /api/v1/recurring_expenses

No data in demo to probe. Expected gaps mirror Expenses + Recurring Invoices: status filter, frequency, `next_send_date` range, `remaining_cycles`. Status chips above list are UI-only today.

### GET /api/v1/tasks

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works | Keep | — |
| `project_id=<id>` | ❌ **Silently ignored — visible in UI today, users see no narrowing** | Exact match (CSV) | **1** |
| `status_id=<id>` | ❌ **Silently ignored — visible in UI today** | Exact match (CSV) | **1** |
| `client_id=<id>` | **untested** | Exact match (CSV) | — |
| `is:active\|archived\|deleted` | ✅ Honored | Keep | — |
| `start_date` / `end_date` | **untested** | Date filter on task date | 4 |
| `assigned_user_id` | **untested** | Exact match (CSV) | — |

### GET /api/v1/projects

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ Works | Keep | — |
| `client_id=<id>` | ✅ Exact match (verified 2) | Keep | — |
| `is:active\|archived` | ⚠️ Works, **no `deleted` state available** | Add `deleted` state | — |
| `assigned_user_id` | **untested** | Exact match (CSV) | — |
| `due_date` range | **untested** | Operator-suffix range | — |

### GET /api/v1/vendors

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `filter=<text>` | ✅ LIKE on `name` (`filter=Inc` → 4) | Keep | — |
| `is:*` | ✅ Honored | Keep | — |
| `name=<text>` | **untested** | LIKE substring | — |
| `number=<value>` | **untested** | LIKE / prefix match | 9 |
| `vat_number=<value>` | **untested** | LIKE substring | 7 |
| `id_number=<value>` | **untested** | LIKE substring | 7 |
| `country_id=<id>` | **untested** | Exact match (CSV) | 6 |
| `currency_id=<id>` | **untested** | Exact match (CSV) | 6 |
| `balance=<n>:gt\|lt` | **untested** | Operator-suffix syntax | — |
| `assigned_user_id` | **untested** | Exact match (CSV) | — |
| `custom_value1..4` | **untested** | LIKE substring | 5 |

### GET /api/v1/bank_transactions

| Param | Current API behavior | Expected | Priority |
|---|---|---|---|
| `bank_account_id=<id>` | ✅ Exact match | Keep | — |
| `status_id=<value>` (`unmatched\|matched\|converted`) | **untested** — needs probe | Exact match (CSV) | — |
| `base_type=<value>` (`deposit\|withdrawal`) | **untested** — needs probe | Exact match | — |
| `is:active\|archived\|deleted` | ✅ Honored | Keep | — |
| `category_id=<id>` | **untested** (commonly requested) | Exact match (CSV) | — |
| `date` range (`start_date` / `end_date`) | **untested** | Date filter | 4 |

## Sort

The Flutter app sends `sort=<field>|asc|desc` on every list call. Confirmed honored: `name`, `number`, `updated_at`, `created_at`, `balance`, `amount`, `date`, `product_key`.

**Unverified** sort columns (per-endpoint; the app sends these but we haven't confirmed the server honors them — silent-ignore behavior on bad sorts means the response looks fine but ordering is server-default):

- Clients: `paid_to_date`, `credit_balance`, `contact_name`, `contact_email`, `contact_phone`, `last_login_at`, `id_number`, `vat_number`, `address1`, `address2`, `city`, `state`, `postal_code`, `phone`, `website`, `public_notes`, `private_notes`, `custom1..4`, `archived_at`.
- Invoices / Quotes / Credits / Recurring Invoices / Purchase Orders: `due_date`, `partial_due_date`, `balance`, `paid_to_date`, `partial`, `po_number`, `design_id`, `assigned_user_id`, `custom_value1..4`, plus on Recurring: `frequency_id`, `next_send_date`, `remaining_cycles`, `auto_bill`.
- Invoices: `status_id` — note this column renders a *computed* status (`calculatedStatusId`) client-side, so raw `status_id` sort won't match the UI. Either expose `calculated_status_id` server-side or document the discrepancy.
- Payments: `applied`, `refunded`, `type_id`, `company_gateway_id`, `transaction_reference`, `exchange_currency_id`.
- Expenses: `payment_date`, `category_id`, `invoice_id`, `currency_id`, status (string).
- Recurring Expenses: `frequency`, `next_send_date`, `last_sent_date`, `remaining_cycles`.
- Tasks: `description`, `rate`, `task_status_id`, `status_order`.
- Projects: `due_date`, `task_rate`, `budgeted_hours`, `current_hours`, `state`.
- Vendors: long list mirroring Clients.
- Bank Transactions: `description`, `participant_name`, `state`, `base_type`.

**Ask**: a documented list per endpoint of which sort columns are honored, so we can drop the unsupported ones from the UI sort menus.

## Cross-cutting API hygiene

1. **Return 422 (or a `warnings: []` envelope key) for unknown filter params.** Today every unknown param returns 200 with the unfiltered set, which makes client-side regressions invisible. This is what produced the Tasks bug: the UI happily sent `project_id`, got 200 OK back, and showed all 25 tasks.
2. **Publish a per-endpoint filter contract** in `https://invoiceninja.github.io/docs/api-reference/`. The current docs are aspirational on most list endpoints — e.g. the `/clients` page documents filtering by industry, country, etc., none of which work.
3. **Disambiguate `assigned_user_id` vs `user_id` on `/clients`.** Both currently return identical result sets in the demo. One should filter by owner, the other by assignee; or one should be deprecated.
4. **`filter=<text>` semantics**: the generic free-text param LIKE-matches only the primary display column (name on clients/vendors/projects, number on document entities). Users typing `Smith` in the Invoices search expect to find invoices for the client "Smith Co." — they don't. An OR across `(number, client_name, po_number)` would close this gap.
5. **`*` wildcards in LIKE.** Today `name=Bob*` returns 0 rows (treated as a literal char). Either honor `*` as a wildcard or document that values are always LIKE-wrapped.
6. **CSV multi-value support** should be uniform. Some filters appear to accept it (entity state via `client_status=active,archived`), others' behavior is untested.

## Appendix — reproducible curls

Each curl below is one row from the tables above. Run with the auth headers from the top of this file.

```bash
# Clients — filter=<text> LIKE works
curl "https://demo.invoiceninja.com/api/v1/clients?filter=Marks&per_page=50" ...  # → 3

# Clients — country_id silently ignored
curl "https://demo.invoiceninja.com/api/v1/clients?country_id=840&per_page=50" ...  # → 25 (unchanged baseline)

# Clients — custom_value1 silently ignored
curl "https://demo.invoiceninja.com/api/v1/clients?custom_value1=2022-02-08&per_page=20" ...  # → 20 (unchanged)

# Invoices — status_id works
curl "https://demo.invoiceninja.com/api/v1/invoices?status_id=4&per_page=50" ...  # → 19

# Invoices — start_date / end_date silently ignored
curl "https://demo.invoiceninja.com/api/v1/invoices?start_date=2025-01-01&end_date=2025-12-31&per_page=50" ...  # → 25 (unchanged)

# Invoices — project_id silently ignored
curl "https://demo.invoiceninja.com/api/v1/invoices?project_id=<id>&per_page=50" ...  # → 25 (unchanged)

# Quotes — status_id silently ignored
curl "https://demo.invoiceninja.com/api/v1/quotes?status_id=2&per_page=50" ...  # → 25 (unchanged)

# Payments — status_id silently ignored
curl "https://demo.invoiceninja.com/api/v1/payments?status_id=4&per_page=50" ...  # → 19 (unchanged)

# Expenses — category_id silently ignored
curl "https://demo.invoiceninja.com/api/v1/expenses?category_id=<id>&per_page=50" ...  # → 50 (unchanged)

# Expenses — project_id silently ignored
curl "https://demo.invoiceninja.com/api/v1/expenses?project_id=<id>&per_page=50" ...  # → 50 (unchanged)

# Tasks — project_id silently ignored (USER-VISIBLE BUG)
curl "https://demo.invoiceninja.com/api/v1/tasks?project_id=<id>&per_page=50" ...  # → 25 (unchanged)

# Tasks — status_id silently ignored (USER-VISIBLE BUG)
curl "https://demo.invoiceninja.com/api/v1/tasks?status_id=<id>&per_page=50" ...  # → 25 (unchanged)
```

To reproduce: replace `<id>` with any value from a successful `GET /<entity>?per_page=1` baseline call. The "→ N" annotation is the result count observed during the 2026-05-15 audit; any future probe should produce the same count if the param is still ignored, or a different count if the param is now honored.
