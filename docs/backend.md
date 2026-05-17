# Backend API gaps (Invoice Ninja v2)

Server-side filter capabilities the Flutter v2 admin needs but the API
doesn't fully support yet. Each item is an actionable spec. Source of truth:
`app/Filters/*Filters.php` in `/Users/hillel/Code/invoiceninja`.

Context: dashboard panels deep-link into the matching datatable with filters
pre-set so the list shows the same records the panel showed (see
`lib/ui/core/list/deep_link_filter_intent.dart`). Most parity is achievable
with existing server params; the gaps below are where it isn't exact.

## 1. Invoice list: no closed date-range filter

`InvoiceFilters::date()` and `due_date()` apply `where('date'/'due_date',
'>=', $date)` — an **open-ended lower bound only**. There is no upper bound
and no range param.

The dashboard KPI cards (Outstanding, Overdue) are scoped to a closed
`[start, end]` window via `charts/totals_v2`. To match that window in the
invoice list we currently send only `date=<start>` (lower bound), so the
list can include rows newer than the KPI window.

**Spec:** add a `date_range` param to `InvoiceFilters` accepting the 3-part
value `"<label>,<start>,<end>"` (mirror `PaymentFilters::date_range`) and
apply `whereBetween('date', [$start, $end])`. Once shipped, change
`_invoiceKpiIntent` in `dashboard_screen.dart` to send the closed range
instead of the lower-bound `date`.

## 2. Lifecycle vs computed-status param collision (`client_status`)

Invoice Ninja exposes two independent params:

- `QueryFilters::status` — entity lifecycle (`active|archived|deleted`).
- `*Filters::client_status` — computed business status
  (invoice `unpaid|overdue|…`, quote `expired|upcoming|…`, payment
  `completed|…`).

The Flutter client emits **lifecycle** on `client_status`
(`stateQueryParams` in `client_repository.dart`). When a computed-status
filter (e.g. `client_status=expired` from the Expired-Quotes deep-link) is
also active, the repo's per-key comma-join makes the computed value win and
the lifecycle constraint is dropped server-side.

In practice the deep-link leaves lifecycle at its default (`{active}`) so
this is benign for the current panels, but it's a latent correctness bug.

**Spec (client-side, no server change required):** migrate
`stateQueryParams` to emit lifecycle on `status` (the
`QueryFilters::status` param) for invoices / quotes / payments / recurring,
freeing `client_status` for computed statuses only. Verify against the live
endpoints that `status=active,archived` filters lifecycle as expected before
flipping. Until then, `QuoteClientStatusFilterKey` /
`PaymentStatusFilterKey` are correct for the deep-link but should not be
combined with a non-default lifecycle filter.

## 3. Quote / recurring-invoice list: no date-range filter

`GET /api/v1/quotes` has no `date` / `date_range` filter.
`GET /api/v1/recurring_invoices` only has `next_send_between` (on
`next_send_date`), no `date_range`.

Not required for current dashboard parity — the Expired/Upcoming Quote and
Upcoming Recurring panels are not date-scoped — but recorded for future
date-scoped views.

**Spec:** add a `date_range` param (`"<label>,<start>,<end>"`,
`whereBetween('date', …)`) to `QuoteFilters` and `RecurringInvoiceFilters`,
mirroring `PaymentFilters::date_range`.

## 4. Payments: `status` vs `client_status` naming

The React client sends payment status as `status`; the server filter method
is `PaymentFilters::client_status` (the live one — confirmed by the May 2026
audit). The Flutter `PaymentStatusFilterKey` correctly writes
`client_status`. Recorded here so a future reader doesn't "fix" it to
`status` (which would silently no-op).
