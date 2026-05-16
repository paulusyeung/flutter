# Feature parity tracker

Working tracker comparing every user-facing feature across the three Invoice Ninja admin clients:

- **React** — the web client at `/Users/hillel/Code/react`
- **Flutter v1** — the legacy Redux-based admin app at `/Users/hillel/Code/admin-portal`
- **Flutter v2** — this rebuild (`/Users/hillel/Code/admin`)

## Legend

| Symbol | Meaning |
|---|---|
| ✅ | Implemented end-to-end |
| 🟡 | Partial — UI scaffolded but missing functionality, gated by another module, or known-incomplete |
| ❌ | Not implemented (no screen, no model, no route) |
| — | N/A (feature doesn't apply to this app — e.g. biometric lock on the web, cookie banner on desktop) |

## Categories

1. [Authentication & session](#authentication--session)
2. [Dashboard](#dashboard)
3. [Clients](#clients)
4. [Invoices](#invoices)
5. [Quotes](#quotes)
6. [Credits](#credits)
7. [Recurring invoices](#recurring-invoices)
8. [Payments](#payments)
9. [Projects](#projects)
10. [Tasks](#tasks)
11. [Vendors](#vendors)
12. [Purchase orders](#purchase-orders)
13. [Expenses](#expenses)
14. [Recurring expenses](#recurring-expenses)
15. [Bank transactions](#bank-transactions)
16. [Products](#products)
17. [Documents (DocuNinja)](#documents-docuninja)
18. [Reports](#reports)
19. [Settings — Basic](#settings--basic)
20. [Settings — Advanced](#settings--advanced)
21. [Payment gateways](#payment-gateways)
22. [Sync & offline](#sync--offline)
23. [Cross-cutting](#cross-cutting)
24. [Platform / mobile specific](#platform--mobile-specific)

---

## Authentication & session

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Email / password login | ✅ | ✅ | ✅ |
| Signup / account creation | ✅ | ❌ | ❌ |
| OAuth — Google | ✅ | ❌ | ❌ |
| OAuth — Microsoft / Azure | ✅ | ❌ | ❌ |
| OAuth — Apple (Sign in with Apple) | ✅ | ✅ | ✅ |
| Two-factor authentication (TOTP / Google Authenticator) | ✅ | ✅ | ✅ |
| Two-factor SMS verification | ✅ | ✅ | ✅ |
| Password reset / recovery email | ✅ | ✅ | ✅ |
| Biometric lock (Touch ID / Face ID / fingerprint) | — | ✅ | ✅ |
| Demo-account access | ✅ | ✅ | ✅ |
| Logout | ✅ | ✅ | ✅ |
| Idle session timeout | ✅ | ✅ | 🟡 |
| Single-flight 401 → logout coordination | ✅ | ✅ | ✅ |
| Minimum-client-version gate | ✅ | ✅ | ✅ |
| Multi-company switching within session | ✅ | ✅ | ✅ |
| Password confirmation modal for destructive actions | ✅ | ✅ | ✅ |
| Password cache TTL (5 min) for chained destructive ops | ✅ | ✅ | ✅ |
| GDPR data export / account closure flow | ✅ | ❌ | ❌ |

---

## Dashboard

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Dashboard overview screen | ✅ | ✅ | ✅ |
| KPI strip (revenue / invoices / quotes / payments) | ✅ | ✅ | ✅ |
| Delta chip (period-over-period change) | ✅ | ✅ | ✅ |
| Sparkline charts on KPIs | ✅ | ✅ | ✅ |
| Recent payments card | ✅ | ✅ | ✅ |
| Upcoming invoices card | ✅ | ✅ | ✅ |
| Upcoming quotes card | ✅ | ✅ | ✅ |
| Upcoming recurring invoices card | ✅ | ✅ | ✅ |
| Expired quotes card | ✅ | ✅ | ✅ |
| Past-due invoices card | ✅ | ✅ | ✅ |
| Needs-attention auto-detected items | ✅ | ✅ | ✅ |
| Activity feed (recent entity changes) | ✅ | ✅ | ✅ |
| Dashboard date range filter | ✅ | ✅ | ✅ |
| Freshness label (last data update) | ❌ | ✅ | ✅ |
| Responsive single-column mobile layout | — | ✅ | ✅ |

---

## Clients

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Client — list | ✅ | ✅ | ✅ |
| Client — detail | ✅ | ✅ | ✅ |
| Client — edit | ✅ | ✅ | ✅ |
| Client — create | ✅ | ✅ | ✅ |
| Client — clone | ✅ | ❌ | ✅ |
| Client — merge two clients | ✅ | ❌ | 🟡 |
| Client — statement PDF | ✅ | ✅ | ✅ |
| Client — comments / internal notes | ✅ | ✅ | ✅ |
| Client — documents / attachments | ✅ | ✅ | ✅ |
| Client — activity / audit feed | ✅ | ✅ | ✅ |
| Client — email history | ✅ | ✅ | ✅ |
| Client — custom fields | ✅ | ✅ | ✅ |
| Client — group assignment | ✅ | ✅ | ✅ |
| Client — multiple contacts | ✅ | ✅ | ✅ |
| Client — multiple shipping / billing locations | ✅ | ❌ | ❌ |
| Client — payment terms override | ✅ | ✅ | ✅ |
| Client — currency override (cascade) | ✅ | ✅ | ✅ |
| Client — portal-access toggle / portal password | ✅ | ✅ | 🟡 |
| Client — archive | ✅ | ✅ | ✅ |
| Client — restore | ✅ | ✅ | ✅ |
| Client — delete | ✅ | ✅ | ✅ |
| Client — purge (hard delete, admin only) | ✅ | ✅ | ✅ |
| Client — bulk archive / restore / delete | ✅ | ✅ | ✅ |
| Client — import (CSV / JSON) | ✅ | 🟡 | ✅ |
| Client — cross-entity "New invoice / quote / task" | ✅ | ✅ | ✅ |
| Client — view client invoices / quotes / payments / credits / recurring / projects / tasks / expenses | ✅ | ✅ | ✅ |

---

## Invoices

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Invoice — list | ✅ | ✅ | ✅ |
| Invoice — detail | ✅ | ✅ | ✅ |
| Invoice — edit (line items, dates, totals) | ✅ | ✅ | ✅ |
| Invoice — create | ✅ | ✅ | ✅ |
| Invoice — clone to new invoice | ✅ | ✅ | ✅ |
| Invoice — clone to quote | ✅ | ✅ | ✅ |
| Invoice — clone to credit | ✅ | ❌ | ✅ |
| Invoice — clone to recurring invoice | ✅ | ✅ | ✅ |
| Invoice — clone to purchase order | ✅ | ❌ | ✅ |
| Invoice — mark sent | ✅ | ✅ | ✅ |
| Invoice — mark paid | ✅ | ✅ | ✅ |
| Invoice — mark partial payment | ✅ | ✅ | ✅ |
| Invoice — refund / credit application | ✅ | ✅ | ❌ |
| Invoice — cancel | ✅ | ✅ | ✅ |
| Invoice — rectify (reversal / correction) | ✅ | ❌ | ❌ |
| Invoice — email to client | ✅ | ✅ | ✅ |
| Invoice — schedule email (delayed send) | ✅ | ❌ | ✅ |
| Invoice — change template / design | ✅ | ✅ | ✅ |
| Invoice — auto-bill with gateway | ✅ | ✅ | ✅ |
| Invoice — view / download PDF | ✅ | ✅ | ✅ |
| Invoice — print | ✅ | ✅ | ✅ |
| Invoice — audit trail / history | ✅ | ✅ | ✅ |
| Invoice — email history | ✅ | ✅ | ✅ |
| Invoice — activities | ✅ | ✅ | ✅ |
| Invoice — payment schedule view | ✅ | ✅ | ❌ |
| Invoice — unapplied payments view | ✅ | ✅ | ❌ |
| Invoice — documents / attachments | ✅ | ✅ | ✅ |
| Invoice — e-invoice (UBL / Factur-X) | ✅ | ❌ | ✅ |
| Invoice — Peppol delivery | ✅ | ❌ | ❌ |
| Invoice — Verifactu (Spain) compliance | ✅ | ❌ | ❌ |
| Invoice — archive / restore / delete | ✅ | ✅ | ✅ |
| Invoice — bulk actions | ✅ | ✅ | 🟡 |
| Invoice — import (CSV) | ✅ | 🟡 | ✅ |
| Invoice — custom fields | ✅ | ✅ | ✅ |

---

## Quotes

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Quote — list | ✅ | ✅ | ✅ |
| Quote — detail | ✅ | ✅ | ✅ |
| Quote — edit | ✅ | ✅ | ✅ |
| Quote — create | ✅ | ✅ | ✅ |
| Quote — clone to quote | ✅ | ✅ | ✅ |
| Quote — clone to invoice | ✅ | ✅ | ✅ |
| Quote — convert / approve to invoice | ✅ | ✅ | ✅ |
| Quote — mark sent | ✅ | ✅ | ✅ |
| Quote — email to client | ✅ | ✅ | ✅ |
| Quote — schedule email | ✅ | ❌ | ✅ |
| Quote — change template / design | ✅ | ✅ | ✅ |
| Quote — view / download PDF | ✅ | ✅ | ✅ |
| Quote — activities | ✅ | ✅ | ✅ |
| Quote — email history | ✅ | ✅ | ✅ |
| Quote — documents / attachments | ✅ | ✅ | ✅ |
| Quote — archive / restore / delete | ✅ | ✅ | ✅ |
| Quote — bulk actions | ✅ | ✅ | 🟡 |
| Quote — import (CSV) | ✅ | 🟡 | ✅ |
| Quote — custom fields | ✅ | ✅ | ✅ |

---

## Credits

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Credit — list | ✅ | ✅ | ✅ |
| Credit — detail | ✅ | ✅ | ✅ |
| Credit — edit | ✅ | ✅ | ✅ |
| Credit — create | ✅ | ✅ | ✅ |
| Credit — clone to credit | ✅ | ✅ | ✅ |
| Credit — clone to invoice | ✅ | ❌ | ✅ |
| Credit — apply to invoice | ✅ | ✅ | ✅ |
| Credit — email to client | ✅ | ✅ | ✅ |
| Credit — change template / design | ✅ | ✅ | ✅ |
| Credit — view / download PDF | ✅ | ✅ | ✅ |
| Credit — activities | ✅ | ✅ | ✅ |
| Credit — e-invoice / Peppol | ✅ | ❌ | ❌ |
| Credit — documents / attachments | ✅ | ✅ | ✅ |
| Credit — archive / restore / delete | ✅ | ✅ | ✅ |
| Credit — bulk actions | ✅ | ✅ | ✅ |
| Credit — custom fields | ✅ | ✅ | ✅ |

---

## Recurring invoices

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Recurring invoice — list | ✅ | ✅ | ✅ |
| Recurring invoice — detail | ✅ | ✅ | ✅ |
| Recurring invoice — edit | ✅ | ✅ | ✅ |
| Recurring invoice — create | ✅ | ✅ | ✅ |
| Recurring invoice — clone | ✅ | ✅ | ✅ |
| Recurring invoice — start / activate | ✅ | ✅ | ✅ |
| Recurring invoice — stop / pause | ✅ | ✅ | ✅ |
| Recurring invoice — send now | ✅ | ✅ | ✅ |
| Recurring invoice — change template / design | ✅ | ✅ | ✅ |
| Recurring invoice — view next-occurrence schedule | ✅ | ✅ | ✅ |
| Recurring invoice — view / download PDF | ✅ | ✅ | ✅ |
| Recurring invoice — activities | ✅ | ✅ | ✅ |
| Recurring invoice — email history | ✅ | ✅ | ✅ |
| Recurring invoice — documents / attachments | ✅ | ✅ | ✅ |
| Recurring invoice — e-invoice | ✅ | ❌ | ❌ |
| Recurring invoice — archive / restore / delete | ✅ | ✅ | ✅ |
| Recurring invoice — bulk actions | ✅ | ✅ | ✅ |
| Recurring invoice — import | ✅ | 🟡 | ✅ |
| Recurring invoice — custom fields | ✅ | ✅ | ✅ |

---

## Payments

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Payment — list | ✅ | ✅ | ✅ |
| Payment — detail | ✅ | ✅ | ✅ |
| Payment — edit | ✅ | ✅ | ✅ |
| Payment — record manual payment | ✅ | ✅ | ✅ |
| Payment — apply to specific invoice | ✅ | ✅ | ✅ |
| Payment — refund (partial / full) | ✅ | ✅ | ✅ |
| Payment — email receipt | ✅ | ✅ | ✅ |
| Payment — view payment method / gateway used | ✅ | ✅ | ✅ |
| Payment — activities / audit trail | ✅ | ✅ | ✅ |
| Payment — documents / attachments | ✅ | ✅ | ✅ |
| Payment — archive / restore / delete | ✅ | ✅ | ✅ |
| Payment — bulk actions | ✅ | ✅ | ✅ |
| Payment — import (CSV) | ✅ | 🟡 | ✅ |
| Payment — custom fields | ✅ | ✅ | ✅ |

---

## Projects

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Project — list | ✅ | ✅ | ✅ |
| Project — detail | ✅ | ✅ | ✅ |
| Project — edit | ✅ | ✅ | ✅ |
| Project — create | ✅ | ✅ | ✅ |
| Project — clone | ✅ | ✅ | ✅ |
| Project — "New task" shortcut (prefills project) | ✅ | ✅ | ✅ |
| Project — view project tasks | ✅ | ✅ | ✅ |
| Project — invoice project (bill all tasks) | ✅ | ✅ | ✅ |
| Project — time summary | ✅ | ✅ | ✅ |
| Project — budget / hours-worked tracking | ✅ | ✅ | ✅ |
| Project — documents / attachments | ✅ | ✅ | ✅ |
| Project — activities | ✅ | ✅ | ✅ |
| Project — custom fields | ✅ | ✅ | ✅ |
| Project — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Project — bulk actions | ✅ | ✅ | ✅ |

---

## Tasks

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Task — list | ✅ | ✅ | ✅ |
| Task — kanban board view | ✅ | ✅ | ✅ |
| Task — detail | ✅ | ✅ | ✅ |
| Task — edit | ✅ | ✅ | ✅ |
| Task — create | ✅ | ✅ | ✅ |
| Task — clone | ✅ | ✅ | ✅ |
| Task — timer start | ✅ | ✅ | ✅ |
| Task — timer stop | ✅ | ✅ | ✅ |
| Task — timer resume from time log | ✅ | ✅ | ✅ |
| Task — time-log entries (edit each row) | ✅ | ✅ | ✅ |
| Task — kanban drag-to-reorder within status | ✅ | ✅ | ✅ |
| Task — kanban filter by project / client / assignee | ✅ | ✅ | 🟡 |
| Task — invoice from task | ✅ | ✅ | ✅ |
| Task — status colors | ✅ | ✅ | ✅ |
| Task — assignee | ✅ | ✅ | ✅ |
| Task — link to project (with project rate) | ✅ | ✅ | ✅ |
| Task — link to client | ✅ | ✅ | ✅ |
| Task — documents / attachments | ✅ | ✅ | ✅ |
| Task — activities | ✅ | ✅ | ✅ |
| Task — custom fields | ✅ | ✅ | ✅ |
| Task — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Task — bulk actions | ✅ | ✅ | ✅ |
| Task — import (CSV) | ✅ | 🟡 | ✅ |

---

## Vendors

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Vendor — list | ✅ | ✅ | ✅ |
| Vendor — detail | ✅ | ✅ | ✅ |
| Vendor — edit | ✅ | ✅ | ✅ |
| Vendor — create | ✅ | ✅ | ✅ |
| Vendor — clone | ✅ | ❌ | ✅ |
| Vendor — comments / internal notes | ✅ | ✅ | ✅ |
| Vendor — documents / attachments | ✅ | ✅ | ✅ |
| Vendor — activities | ✅ | ✅ | ✅ |
| Vendor — "New expense" shortcut (prefills vendor) | ✅ | ✅ | ✅ |
| Vendor — custom fields | ✅ | ✅ | ✅ |
| Vendor — view vendor expenses / POs / recurring expenses | ✅ | ✅ | ✅ |
| Vendor — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Vendor — bulk actions | ✅ | ✅ | ✅ |
| Vendor — import (CSV) | ✅ | 🟡 | ✅ |

---

## Purchase orders

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Purchase order — list | ✅ | ✅ | ✅ |
| Purchase order — detail | ✅ | ✅ | ✅ |
| Purchase order — edit | ✅ | ✅ | ✅ |
| Purchase order — create | ✅ | ✅ | ✅ |
| Purchase order — clone | ✅ | ✅ | ✅ |
| Purchase order — convert to expense | ✅ | ✅ | ✅ |
| Purchase order — email to vendor | ✅ | ✅ | ✅ |
| Purchase order — schedule email | ✅ | ❌ | ✅ |
| Purchase order — mark sent | ✅ | ✅ | ✅ |
| Purchase order — accept (vendor side) | ✅ | ❌ | ✅ |
| Purchase order — change template / design | ✅ | ✅ | ✅ |
| Purchase order — view / download PDF | ✅ | ✅ | ✅ |
| Purchase order — activities | ✅ | ✅ | ✅ |
| Purchase order — email history | ✅ | ✅ | ✅ |
| Purchase order — documents / attachments | ✅ | ✅ | ✅ |
| Purchase order — archive / restore / delete | ✅ | ✅ | ✅ |
| Purchase order — bulk actions | ✅ | ✅ | ✅ |
| Purchase order — import | ✅ | 🟡 | ✅ |
| Purchase order — custom fields | ✅ | ✅ | ✅ |

---

## Expenses

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Expense — list | ✅ | ✅ | ✅ |
| Expense — detail | ✅ | ✅ | ✅ |
| Expense — edit | ✅ | ✅ | ✅ |
| Expense — create | ✅ | ✅ | ✅ |
| Expense — clone | ✅ | ✅ | ✅ |
| Expense — clone to recurring expense | ✅ | ✅ | ✅ |
| Expense — categorize | ✅ | ✅ | ✅ |
| Expense — link to vendor | ✅ | ✅ | ✅ |
| Expense — link to project / client | ✅ | ✅ | ✅ |
| Expense — convert / add to invoice | ✅ | ✅ | ✅ |
| Expense — documents / receipts attachment | ✅ | ✅ | ✅ |
| Expense — comments | ✅ | ✅ | ✅ |
| Expense — activities | ✅ | ✅ | ✅ |
| Expense — custom fields | ✅ | ✅ | ✅ |
| Expense — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Expense — bulk actions | ✅ | ✅ | ✅ |
| Expense — import (CSV) | ✅ | 🟡 | ✅ |

---

## Recurring expenses

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Recurring expense — list | ✅ | ✅ | ✅ |
| Recurring expense — detail | ✅ | ✅ | ✅ |
| Recurring expense — edit | ✅ | ✅ | ✅ |
| Recurring expense — create | ✅ | ✅ | ✅ |
| Recurring expense — clone | ✅ | ✅ | ✅ |
| Recurring expense — clone to single expense | ✅ | ✅ | ✅ |
| Recurring expense — start / activate | ✅ | ✅ | ✅ |
| Recurring expense — stop / pause | ✅ | ✅ | ✅ |
| Recurring expense — frequency configuration | ✅ | ✅ | ✅ |
| Recurring expense — comments | ✅ | ✅ | ✅ |
| Recurring expense — documents | ✅ | ✅ | ✅ |
| Recurring expense — activities | ✅ | ✅ | ✅ |
| Recurring expense — custom fields | ✅ | ✅ | ✅ |
| Recurring expense — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Recurring expense — bulk actions | ✅ | ✅ | ✅ |

---

## Bank transactions

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Bank transaction — list | ✅ | ✅ | ✅ |
| Bank transaction — create | ✅ | ✅ | ✅ |
| Bank transaction — edit / categorize | ✅ | ✅ | ✅ |
| Bank transaction — import (CSV) | ✅ | ✅ | ❌ |
| Bank transaction — import (OFX / QIF / QFX) | ✅ | ✅ | ❌ |
| Bank transaction — match to invoice (Create Payment) | ✅ | ✅ | ✅ |
| Bank transaction — link existing payment | ✅ | ✅ | 🟡 |
| Bank transaction — match to expense | ✅ | ✅ | ✅ |
| Bank transaction — link existing expense | ✅ | ✅ | ✅ |
| Bank transaction — transaction rules (auto-match) | ✅ | ✅ | ✅ |
| Bank transaction — bulk archive / restore / delete | ✅ | ✅ | ✅ |
| Bank transaction — bulk convert / unlink | ✅ | ✅ | ✅ |
| Bank account — read-only detail with embedded transactions | ✅ | ✅ | ✅ |

---

## Products

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Product — list | ✅ | ✅ | ✅ |
| Product — detail | ✅ | ✅ | ✅ |
| Product — edit | ✅ | ✅ | ✅ |
| Product — create | ✅ | ✅ | ✅ |
| Product — clone | ✅ | ✅ | ✅ |
| Product — documents / attachments | ✅ | ✅ | ✅ |
| Product — tax category | ✅ | ✅ | ✅ |
| Product — stock / inventory tracking | ✅ | 🟡 | ✅ |
| Product — custom fields | ✅ | ✅ | ✅ |
| Product — activities | ✅ | ✅ | ✅ |
| Product — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Product — bulk actions | ✅ | ✅ | ✅ |
| Product — import (CSV) | ✅ | 🟡 | ✅ |

---

## Documents (DocuNinja)

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| DocuNinja — document list | ✅ | ❌ | ❌ |
| DocuNinja — create document | ✅ | ❌ | ❌ |
| DocuNinja — create blueprint / template | ✅ | ❌ | ❌ |
| DocuNinja — drag-and-drop document builder | ✅ | ❌ | ❌ |
| DocuNinja — signature field mapping | ✅ | ❌ | ❌ |
| DocuNinja — sign document | ✅ | ❌ | ❌ |
| DocuNinja — PDF preview / render | ✅ | ❌ | ❌ |
| DocuNinja — user management for docs | ✅ | ❌ | ❌ |
| DocuNinja — document email templates | ✅ | ❌ | ❌ |
| DocuNinja — delete document | ✅ | ❌ | ❌ |

---

## Reports

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Report — activity | ✅ | ✅ | ✅ |
| Report — client | ✅ | ✅ | ✅ |
| Report — contact | ✅ | ✅ | ✅ |
| Report — credit | ✅ | ✅ | ✅ |
| Report — document | ✅ | 🟡 | ✅ |
| Report — expense | ✅ | ✅ | ✅ |
| Report — invoice | ✅ | ✅ | ✅ |
| Report — invoice item | ✅ | ✅ | ✅ |
| Report — quote | ✅ | ✅ | ✅ |
| Report — quote item | ✅ | ✅ | ✅ |
| Report — recurring invoice | ✅ | ✅ | ✅ |
| Report — recurring invoice item | ✅ | 🟡 | ✅ |
| Report — payment | ✅ | ✅ | ✅ |
| Report — product | ✅ | ✅ | ✅ |
| Report — product sales | ✅ | ✅ | ✅ |
| Report — task | ✅ | ✅ | ✅ |
| Report — vendor | ✅ | ✅ | ✅ |
| Report — purchase order | ✅ | ✅ | ✅ |
| Report — purchase order item | ✅ | 🟡 | ✅ |
| Report — profit / loss | ✅ | ✅ | ✅ |
| Report — client balance | ✅ | ✅ | ✅ |
| Report — client sales | ✅ | ✅ | ✅ |
| Report — aged receivable (detailed) | ✅ | ✅ | ✅ |
| Report — aged receivable (summary) | ✅ | ✅ | ✅ |
| Report — user sales | ✅ | 🟡 | ✅ |
| Report — tax summary | ✅ | ✅ | ✅ |
| Report — tax period | ✅ | ❌ | ✅ |
| Report — project | ✅ | ✅ | ✅ |
| Report — custom column selection | ✅ | ✅ | ✅ |
| Report — date range filters (preset + custom) | ✅ | ✅ | ✅ |
| Report — export to PDF / CSV | ✅ | ✅ | ✅ |
| Report — email-scheduled delivery | ✅ | 🟡 | ✅ |
| Report — grouping by dimension | ✅ | ✅ | ✅ |
| Report — multi-entity filtering | ✅ | ✅ | ✅ |

---

## Settings — Basic

Field-level breakdown of every option under each settings panel. Source of truth for v2: `lib/ui/features/settings/settings_search_catalog.dart` and the per-screen `kFooSearchKeys` constants colocated next to each screen. Multi-tab panels are split per-tab.

### Company Details

#### Company Details — Details tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Name | ✅ | ✅ | ✅ |
| ID Number | ✅ | ✅ | ✅ |
| VAT Number | ✅ | ✅ | ✅ |
| QR IBAN (Swiss only) | ✅ | ✅ | ✅ |
| BESR ID (Swiss only) | ✅ | ✅ | ✅ |
| Website | ✅ | ✅ | ✅ |
| Email | ✅ | ✅ | ✅ |
| Phone | ✅ | ✅ | ✅ |
| Classification (dropdown) | ✅ | ✅ | ✅ |
| Size (dropdown) | ✅ | ✅ | ✅ |
| Industry (dropdown) | ✅ | ✅ | ✅ |

#### Company Details — Address tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Address 1 | ✅ | ✅ | ✅ |
| Address 2 | ✅ | ✅ | ✅ |
| City | ✅ | ✅ | ✅ |
| State / Province | ✅ | ✅ | ✅ |
| Postal Code | ✅ | ✅ | ✅ |
| Country | ✅ | ✅ | ✅ |

#### Company Details — Logo tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Logo upload | ✅ | ✅ | ✅ |
| Logo crop / size | ✅ | ✅ | ✅ |

#### Company Details — Defaults tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Invoice Terms (markdown) | ✅ | ✅ | ✅ |
| Invoice Footer (markdown) | ✅ | ✅ | ✅ |
| Quote Terms (markdown) | ✅ | ✅ | ✅ |
| Quote Footer (markdown) | ✅ | ✅ | ✅ |
| Credit Terms (markdown) | ✅ | ✅ | ✅ |
| Credit Footer (markdown) | ✅ | ✅ | ✅ |
| Purchase Order Terms (markdown) | ✅ | ✅ | ✅ |
| Purchase Order Footer (markdown) | ✅ | ✅ | ✅ |

#### Company Details — Documents tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Document upload | ✅ | ✅ | ✅ |
| Document list / preview | ✅ | ✅ | ✅ |
| Document download | ✅ | ✅ | ✅ |
| Document delete | ✅ | ✅ | ✅ |

#### Company Details — Custom Fields tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Custom Field 1 (label + type) | ✅ | ✅ | ✅ |
| Custom Field 2 (label + type) | ✅ | ✅ | ✅ |
| Custom Field 3 (label + type) | ✅ | ✅ | ✅ |
| Custom Field 4 (label + type) | ✅ | ✅ | ✅ |

### User Details

#### User Details — Details tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| First Name | ✅ | ✅ | ✅ |
| Last Name | ✅ | ✅ | ✅ |
| Email | ✅ | ✅ | ✅ |
| Phone | ✅ | ✅ | ✅ |
| Document Language | ✅ | ✅ | ✅ |
| Signature (image / text) | ✅ | ✅ | ✅ |
| Sign Out (action) | ✅ | ✅ | ✅ |

#### User Details — Password tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Current Password | ✅ | ✅ | ✅ |
| New Password | ✅ | ✅ | ✅ |
| Confirm Password | ✅ | ✅ | ✅ |

#### User Details — Connect tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Connect Google (OAuth) | ✅ | ✅ | ✅ |
| Connect Microsoft (OAuth) | ✅ | ✅ | ✅ |
| Connect Gmail (OAuth) | ✅ | ✅ | ✅ |
| Connect Email (OAuth) | ✅ | ✅ | ✅ |
| Disconnect | ✅ | ✅ | ✅ |

#### User Details — Two-Factor tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Enable Two-Factor Authentication | ✅ | ✅ | ✅ |
| Two-factor setup / verification | ✅ | ✅ | ✅ |

#### User Details — Notifications tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| All Events (master toggle) | ✅ | ✅ | ✅ |
| All Notifications (master toggle) | ✅ | ✅ | ✅ |
| User Logged In | ✅ | ✅ | ✅ |
| Task Assigned | ✅ | ✅ | ✅ |
| Disable Recurring Payment Notification | ✅ | ✅ | ✅ |
| E-Invoice Received | ✅ | ✅ | ✅ |
| Invoice Created | ✅ | ✅ | ✅ |
| Invoice Sent | ✅ | ✅ | ✅ |
| Invoice Viewed | ✅ | ✅ | ✅ |
| Invoice Late | ✅ | ✅ | ✅ |
| Payment Success | ✅ | ✅ | ✅ |
| Payment Failure | ✅ | ✅ | ✅ |
| Payment Manual | ✅ | ✅ | ✅ |
| Quote Created | ✅ | ✅ | ✅ |
| Quote Sent | ✅ | ✅ | ✅ |
| Quote Viewed | ✅ | ✅ | ✅ |
| Quote Approved | ✅ | ✅ | ✅ |
| Quote Expired | ✅ | ✅ | ✅ |
| Quote Rejected | ✅ | ✅ | ✅ |
| Credit Created | ✅ | ✅ | ✅ |
| Credit Sent | ✅ | ✅ | ✅ |
| Credit Viewed | ✅ | ✅ | ✅ |
| Purchase Order Created | ✅ | ✅ | ✅ |
| Purchase Order Sent | ✅ | ✅ | ✅ |
| Purchase Order Viewed | ✅ | ✅ | ✅ |
| Purchase Order Accepted | ✅ | ✅ | ✅ |
| Inventory Threshold | ✅ | ✅ | ✅ |

#### User Details — Preferences tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Theme (light / dark / system) | ✅ | ✅ | ✅ |
| Custom palette (adapt a preset, per light/dark) | — | — | ✅ |
| App Language | ✅ | ✅ | ✅ |
| Accent Color | ✅ | ✅ | ✅ |

### Localization

#### Localization — Settings tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Currency | ✅ | ✅ | ✅ |
| Currency Format (symbol / position / decimals) | ✅ | ✅ | ✅ |
| Language | ✅ | ✅ | ✅ |
| Timezone | ✅ | ✅ | ✅ |
| Date Format | ✅ | ✅ | ✅ |
| Military / 24-hour time | ✅ | ✅ | ✅ |
| Rappen Rounding (Swiss) | ✅ | ✅ | ✅ |
| Decimal Comma | ✅ | ✅ | ✅ |
| First Month of the Year (fiscal start) | ✅ | ✅ | ✅ |

#### Localization — Custom Labels tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Predefined label overrides (~40 keys: address, amount, balance, country, credit, date, description, discount, due date, email, hours, ID number, invoice, item, line total, paid to date, partial due, phone, PO number, product, quantity, quote, rate, statement, subtotal, surcharge, tax, terms, total, unit cost, valid until, VAT number, website, etc.) | ✅ | ✅ | ✅ |
| Free-form custom labels | ✅ | ✅ | ✅ |
| Country-specific label aliases | ✅ | ✅ | ✅ |

### Online Payments

#### Online Payments — General tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Auto Bill Standard Invoices | ✅ | ✅ | ✅ |
| Auto Bill Recurring Invoices | ✅ | ✅ | ✅ |
| Auto Bill On (dropdown) | ✅ | ✅ | ✅ |
| Use Available Payments | ✅ | ✅ | ✅ |
| Use Available Credits | ✅ | ✅ | ✅ |
| Configure Gateways (link) | ✅ | ✅ | ✅ |
| Admin Initiated Payments | ✅ | ✅ | ✅ |
| Client Initiated Payments | ✅ | ✅ | ✅ |
| Minimum Payment Amount | ✅ | ✅ | ✅ |
| Allow Over Payment | ✅ | ✅ | ✅ |
| Allow Under Payment | ✅ | ✅ | ✅ |
| Minimum Under Payment Amount | ✅ | ✅ | ✅ |
| Convert Currency | ✅ | ✅ | ✅ |
| One Page Checkout | ✅ | ✅ | ✅ |
| Unlock Invoice Documents After Payment | ✅ | ✅ | ✅ |

#### Online Payments — Defaults tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Default Payment Type | ✅ | ✅ | ✅ |
| Default Expense Payment Type | ✅ | ✅ | ✅ |
| Invoice Payment Terms | ✅ | ✅ | ✅ |
| Quote Valid Until | ✅ | ✅ | ✅ |
| Configure Payment Terms (link) | ✅ | ✅ | ✅ |

#### Online Payments — Emails tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Online Payment Email | ✅ | ✅ | ✅ |
| Manual Payment Email | ✅ | ✅ | ✅ |
| Mark Paid Payment Email | ✅ | ✅ | ✅ |
| Send Emails To (all contacts / primary) | ✅ | ✅ | ✅ |

### Tax Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Invoice Tax Rates (0 / 1 / 2 / 3) | ✅ | ✅ | ✅ |
| Invoice Item Tax Rates (0 / 1 / 2 / 3) | ✅ | ✅ | ✅ |
| Expense Tax Rates (0 / 1 / 2 / 3) | ✅ | ✅ | ✅ |
| Inclusive Taxes toggle | ✅ | ✅ | ✅ |
| Tax Name (per rate) | ✅ | ✅ | ✅ |
| Tax Rate percentage (per rate) | ✅ | ✅ | ✅ |
| Calculate Taxes (auto / manual) | ✅ | ✅ | ✅ |
| Seller Subregion (EU VAT) | ✅ | ✅ | ✅ |
| Reduced Rate (per region, when Calculate Taxes on) | ✅ | ✅ | ✅ |
| Tax rate CRUD (manage rate list) | ✅ | ✅ | ❌ |

### Product Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Track Inventory | ✅ | ✅ | ✅ |
| Stock Notifications | ✅ | ✅ | ✅ |
| Notification Threshold (when Stock Notifications on) | ✅ | ✅ | ✅ |
| Show Product Discount | ✅ | ✅ | ✅ |
| Show Product Cost | ✅ | ✅ | ✅ |
| Show Product Quantity | ✅ | ✅ | ✅ |
| Default Quantity | ✅ | ✅ | ✅ |
| Show Product Description | ✅ | ✅ | ✅ |
| Fill Products | ✅ | ✅ | ✅ |
| Update Products | ✅ | ✅ | ✅ |
| Convert Products | ✅ | ✅ | ✅ |
| Convert To (currency, when Convert Products on) | ✅ | ✅ | ✅ |

### Task Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Default Task Rate | ✅ | ✅ | ✅ |
| Auto Start Tasks | ✅ | ✅ | ✅ |
| Show Task End Date | ✅ | ✅ | ✅ |
| Show Task Item Description | ✅ | ✅ | ✅ |
| Show Task Billable | ✅ | ✅ | ✅ |
| Round Tasks | ✅ | ✅ | ✅ |
| Rounding Direction (up / down, when Round Tasks on) | ✅ | ✅ | ✅ |
| Task Round To Nearest (preset seconds / custom) | ✅ | ✅ | ✅ |
| Round To Seconds (when "Custom" selected) | ✅ | ✅ | ✅ |
| Configure Statuses (link) | ✅ | ✅ | ✅ |
| Show Tasks Table | ✅ | ✅ | ✅ |
| Invoice Task Datelog | ✅ | ✅ | ✅ |
| Invoice Task Timelog | ✅ | ✅ | ✅ |
| Invoice Task Hours | ✅ | ✅ | ✅ |
| Invoice Task Item Description | ✅ | ✅ | ✅ |
| Invoice Task Project | ✅ | ✅ | ✅ |
| Project Location | ✅ | ✅ | ✅ |
| Lock Invoiced Tasks | ✅ | ✅ | ✅ |
| Add Documents to Invoice | ✅ | ✅ | ✅ |
| Show Tasks in Client Portal | ✅ | ✅ | ✅ |
| Tasks Shown in Portal | ✅ | ✅ | ✅ |

### Expense Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Should Be Invoiced (default invoiceable) | ✅ | ✅ | ✅ |
| Mark Paid (default) | ✅ | ✅ | ✅ |
| Default Expense Payment Type | ✅ | ✅ | ✅ |
| Convert Currency | ✅ | ✅ | ✅ |
| Add Documents to Invoice | ✅ | ✅ | ✅ |
| Notify Vendor When Paid | ✅ | ✅ | ✅ |
| Expense Mailbox Active | ✅ | ✅ | ✅ |
| Expense Mailbox (email address) | ✅ | ✅ | ✅ |
| Inbound Mailbox — Allow Company Users | ✅ | ✅ | ✅ |
| Inbound Mailbox — Allow Vendors | ✅ | ✅ | ✅ |
| Inbound Mailbox — Allow Clients | ✅ | ✅ | ✅ |
| Inbound Mailbox — Whitelist | ✅ | ✅ | ✅ |
| Inbound Mailbox — Blacklist | ✅ | ✅ | ✅ |
| Inbound Mailbox — Allow Unknown | ✅ | ✅ | ✅ |
| Enter Taxes | ✅ | ✅ | ✅ |
| Inclusive Taxes | ✅ | ✅ | ✅ |
| Configure Categories (link) | ✅ | ✅ | ✅ |

### Workflow Settings

#### Workflow Settings — Invoices tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Auto Email Invoice | ✅ | ✅ | ✅ |
| Stop on Unpaid | ✅ | ✅ | ✅ |
| Auto Archive Paid Invoices | ✅ | ✅ | ✅ |
| Auto Archive Cancelled Invoices | ✅ | ✅ | ✅ |
| Lock Invoices (off / when sent / when paid / end of month) | ✅ | ✅ | ✅ |

#### Workflow Settings — Quotes tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Auto Convert Quote | ✅ | ✅ | ✅ |
| Auto Archive Quote | ✅ | ✅ | ✅ |
| Use Quote Terms | ✅ | ✅ | ✅ |

### Account Management

#### Account Management — Plan

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Plan tier (Free / Pro / Enterprise) | ✅ | ✅ | ✅ |
| Free trial banner | ✅ | ✅ | ✅ |
| Plan expires-on date | ✅ | ✅ | ✅ |
| Days-left countdown | ✅ | ✅ | ✅ |
| Change Plan (action) | ✅ | ✅ | ✅ |
| Upgrade Plan (action) | ✅ | ✅ | ✅ |
| Pro/Enterprise gating: advanced-settings banner + field disable | ✅ | ✅ | ✅ |
| Pro/Enterprise gating: sidebar lock icons + search-result tier chips | ✅ | — | ✅ |
| Trial-expires-soon urgent footer (≤3 days) | ✅ | ✅ | ✅ |

#### Account Management — Overview

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Account ID (read-only) | ✅ | ✅ | ✅ |
| Account email (read-only) | ✅ | ✅ | ✅ |
| Set Default Company | ✅ | ✅ | ✅ |
| Activate / deactivate company | ✅ | ✅ | ✅ |
| Enable PDF Markdown | ✅ | ✅ | ✅ |
| Enable Email Markdown | ✅ | ✅ | ✅ |
| Include Drafts in lists | ✅ | ✅ | ✅ |
| Include Deleted in lists | ✅ | ✅ | ✅ |
| Force Full Resync | ✅ | ✅ | ✅ |
| Purchase License | ✅ | ✅ | ✅ |
| Apply License | ✅ | ✅ | ✅ |

#### Account Management — Enabled Modules

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Module toggles (invoices, recurring, quotes, credits, projects, tasks, vendors, POs, expenses, recurring expenses) | ✅ | ✅ | ✅ |

#### Account Management — Integrations

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Google Analytics Tracking ID | ✅ | ✅ | ✅ |
| Matomo Site ID | ✅ | ✅ | ✅ |
| Matomo URL | ✅ | ✅ | ✅ |
| API Tokens (CRUD) | ✅ | ✅ | ✅ |
| API Webhooks (CRUD) | ✅ | ✅ | ✅ |
| API Docs (link) | ✅ | ✅ | ✅ |
| Zapier integration | ✅ | ✅ | 🟡 |
| QuickBooks integration | ✅ | ❌ | ✅ |

#### Account Management — Security

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Password Timeout | ✅ | ✅ | ✅ |
| Web Session Timeout | ✅ | ✅ | ✅ |
| Require Password with Social Login | ✅ | ✅ | ✅ |
| End All Sessions (action) | ✅ | ✅ | ✅ |

#### Account Management — Referral

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Referral Program (enable) | ✅ | ✅ | ✅ |
| Referral Code (read / copy) | ✅ | ✅ | ✅ |

#### Account Management — Danger Zone

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Purge Data (clear all company data) | ✅ | ✅ | ✅ |
| Delete Company | ✅ | ✅ | ✅ |
| Cancel Account (close account entirely) | ✅ | ✅ | ✅ |

### Backup & Restore

#### Backup & Restore — Backup tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Backup (email download link) | ✅ | ✅ | ✅ |

#### Backup & Restore — Restore tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Restore (.zip upload) | ✅ | 🟡 | ✅ |
| Export (action) | ✅ | 🟡 | ✅ |
| Import Settings (file upload) | ✅ | ❌ | ✅ |
| Import Data (file upload) | ✅ | 🟡 | ✅ |
| Company Backup File (display) | ✅ | 🟡 | ✅ |

### Import & Export

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Import (action) | ✅ | 🟡 | ✅ |
| Export (action) | ✅ | ✅ | 🟡 |

### Device Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Theme (light / dark / system, local) | — | ✅ | ✅ |
| Biometric Authentication toggle | — | ✅ | ✅ |
| Refresh Data (force resync) | — | ✅ | ✅ |

---

## Settings — Advanced

Field-level breakdown of every option under each advanced settings panel. Source of truth for v2: `lib/ui/features/settings/settings_search_catalog.dart` and per-screen `kFooSearchKeys` constants.

### Invoice Design

#### Invoice Design — General Settings tab

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Invoice Design (template picker) | ✅ | ✅ | ✅ |
| Quote Design | ✅ | ✅ | ✅ |
| Credit Design | ✅ | ✅ | ✅ |
| Purchase Order Design | ✅ | ✅ | ✅ |
| Delivery Note Design | ✅ | ✅ | ✅ |
| Statement Design | ✅ | ✅ | ✅ |
| Payment Receipt Design | ✅ | ✅ | ✅ |
| Payment Refund Design | ✅ | ✅ | ✅ |
| Page Layout (portrait / landscape) | ✅ | ✅ | ✅ |
| Page Size (A4 / Letter / etc.) | ✅ | ✅ | ✅ |
| Font Size | ✅ | ✅ | ✅ |
| Logo Size | ✅ | ✅ | ✅ |
| Primary Font | ✅ | ✅ | ✅ |
| Secondary Font | ✅ | ✅ | ✅ |
| Primary Color | ✅ | ✅ | ✅ |
| Secondary Color | ✅ | ✅ | ✅ |
| Show Paid Stamp | ✅ | ✅ | ✅ |
| Show Shipping Address | ✅ | ✅ | ✅ |
| Share Invoice Quote Columns | ✅ | ✅ | ✅ |
| Empty Columns (hide / show) | ✅ | ✅ | ✅ |
| Page Numbering | ✅ | ✅ | ✅ |
| Page Numbering Alignment | ✅ | ✅ | ✅ |
| Invoice Embed Documents | ✅ | ✅ | ✅ |

#### Invoice Design — PDF Variable tabs

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Client Details columns | ✅ | ✅ | ✅ |
| Company Details columns | ✅ | ✅ | ✅ |
| Company Address columns | ✅ | ✅ | ✅ |
| Invoice Details columns | ✅ | ✅ | ✅ |
| Quote Details columns | ✅ | ✅ | ✅ |
| Credit Details columns | ✅ | ✅ | ✅ |
| Vendor Details columns | ✅ | ✅ | ✅ |
| Purchase Order Details columns | ✅ | ✅ | ✅ |
| Product Columns selector | ✅ | ✅ | ✅ |
| Quote Product Columns selector | ✅ | ✅ | ✅ |
| Task Columns selector | ✅ | ✅ | ✅ |
| Total Fields selector | ✅ | ✅ | ✅ |
| Custom Designs (CRUD: header / body / footer / includes) | ✅ | ✅ | ✅ |

### Custom Fields

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Company custom fields (4 slots: label + type) | ✅ | ✅ | ✅ |
| Client custom fields (4 slots) | ✅ | ✅ | ✅ |
| Contact custom fields (4 slots) | ✅ | ✅ | ✅ |
| Location custom fields (4 slots) | ✅ | ✅ | ✅ |
| Product custom fields (4 slots) | ✅ | ✅ | ✅ |
| Invoice custom fields (4 slots) | ✅ | ✅ | ✅ |
| Invoice surcharge custom fields (4 slots, with Charge taxes toggle) | ✅ | ✅ | ✅ |
| Payment custom fields (4 slots) | ✅ | ✅ | ✅ |
| Project custom fields (4 slots) | ✅ | ✅ | ✅ |
| Task custom fields (4 slots) | ✅ | ✅ | ✅ |
| Vendor custom fields (4 slots) | ✅ | ✅ | ✅ |
| Vendor contact custom fields (4 slots) | ✅ | ✅ | ✅ |
| Expense custom fields (4 slots) | ✅ | ✅ | ✅ |
| Quote custom fields (4 slots) | ✅ | ✅ | ✅ |
| Credit custom fields (4 slots) | ✅ | ✅ | ✅ |
| User custom fields (4 slots) | ✅ | ✅ | ✅ |
| Custom field types (single line / multi line / switch / date / dropdown) | ✅ | ✅ | ✅ |
| Module-gated tabs (hide Tasks / Vendors / Expenses / Projects when module disabled) | — | ✅ | ✅ |
| Non-Pro plan banner with upgrade link | ✅ | — | ✅ |
| 422 field errors → auto-jump to offending tab | — | — | ✅ |

### Generated Numbers

#### Generated Numbers — Global

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Number Padding (digits) | ✅ | ✅ | ✅ |
| Number Counter (shared / per-entity) | ✅ | ✅ | ✅ |
| Recurring Prefix | ✅ | ✅ | ✅ |
| Reset Counter (frequency) | ✅ | ✅ | ✅ |

#### Generated Numbers — Per entity

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Client Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Invoice Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Recurring Invoice Number | ✅ | ✅ | ✅ |
| Quote Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Credit Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Payment Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Project Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Task Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Vendor Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Purchase Order Number | ✅ | ✅ | ✅ |
| Expense Number — pattern + counter + reset | ✅ | ✅ | ✅ |
| Recurring Expense Number | ✅ | ✅ | ✅ |

### Client Portal

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Client Portal (enable / disable) | ✅ | ✅ | ✅ |
| Dashboard (show in portal) | ✅ | ✅ | ✅ |
| Portal Mode (iframe / domain / subdomain) | ✅ | ✅ | ✅ |
| Subdomain | ✅ | ✅ | ✅ |
| Subdomain availability check (debounced) | ✅ | ✅ | ✅ |
| Domain (custom) | ✅ | ✅ | ✅ |
| Login URL display | ✅ | ✅ | ✅ |
| Client Document Upload | ✅ | ✅ | ✅ |
| Vendor Document Upload | ✅ | ✅ | ✅ |
| Accept Purchase Order Number | ✅ | ✅ | ✅ |
| Mobile Version | ✅ | ✅ | ✅ |
| Preference Product Notes For HTML View | ✅ | — | ✅ |
| Enable Client Profile Update | ✅ | ✅ | ✅ |
| Terms of Service / Privacy Policy | ✅ | ✅ | ✅ |
| Client Registration | ✅ | ✅ | ✅ |
| Registration Fields (20-field hide / optional / require matrix) | ✅ | ✅ | ✅ |
| Registration URL display | ✅ | ✅ | ✅ |
| Enable Portal Password | ✅ | ✅ | ✅ |
| Show Accept Invoice Terms | ✅ | ✅ | ✅ |
| Show Accept Quote Terms | ✅ | ✅ | ✅ |
| Require Invoice Signature | ✅ | ✅ | ✅ |
| Require Quote Signature | ✅ | ✅ | ✅ |
| Require Purchase Order Signature | ✅ | ✅ | ✅ |
| Signature on PDF | ✅ | ✅ | ✅ |
| Messages (welcome message editor) | ✅ | ✅ | ✅ |
| Header (HTML editor) | ✅ | ✅ | ✅ |
| Footer (HTML editor) | ✅ | ✅ | ✅ |
| Custom CSS | ✅ | ✅ | ✅ |
| Custom JavaScript | ✅ | ✅ | ✅ |

### Email Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Send From Gmail | ✅ | ✅ | ✅ |
| Microsoft / Outlook OAuth | ✅ | ✅ | ✅ |
| Postmark API key | ✅ | ✅ | ✅ |
| Mailgun API key + domain | ✅ | ✅ | ✅ |
| SMTP server configuration | ✅ | ✅ | ✅ |
| From Name | ✅ | ✅ | ✅ |
| Reply To Email | ✅ | ✅ | ✅ |
| Reply To Name | ✅ | ✅ | ✅ |
| BCC Email | ✅ | ✅ | ✅ |
| Attach PDF | ✅ | ✅ | ✅ |
| Attach Documents | ✅ | ✅ | ✅ |
| Attach UBL | ✅ | ✅ | ✅ |
| Email Signature (HTML editor) | ✅ | ✅ | ✅ |
| Email Design (template picker) | ✅ | ✅ | ✅ |
| Email Alignment | ✅ | ✅ | ✅ |
| Show Email Footer | ✅ | ✅ | ✅ |
| Enable E-Invoice (send UBL with email) | ✅ | ✅ | ✅ |
| Send Test Email button | ✅ | ✅ | ✅ |
| Send-Time sync to existing entities (inline checkbox) | ✅ | — | ✅ |
| Password / secret reveal toggle | — | — | ✅ |
| Inline `$body` validation chip on custom style | — | — | ✅ |
| Pro / Enterprise gating chip on SMTP option | — | — | ✅ |
| OAuth Connect (in-app callback) | ✅ | 🟡 | 🟡 |

### Templates & Reminders

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Template editor (subject + body, per entity type) | ✅ | ✅ | ✅ |
| Template variables reference | ✅ | ✅ | ✅ |
| First reminder rule (days before / after due + email) | ✅ | ✅ | ✅ |
| Second reminder rule | ✅ | ✅ | ✅ |
| Third reminder rule | ✅ | ✅ | ✅ |
| Endless reminder | ✅ | ✅ | ✅ |
| Quote reminder 1 | ✅ | ✅ | ✅ |
| Send Reminders (master toggle) | ✅ | ✅ | ✅ |
| Late Fees (auto-apply on reminder) | ✅ | ✅ | ✅ |
| Live HTML preview (mobile WebView) | ✅ | ✅ | ✅ |
| Markdown-rendered preview fallback (desktop) | — | ✅ | ✅ |
| Recurring invoice reminder customization | ✅ | ✅ | ✅ |

### Bank Accounts

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Bank account list | ✅ | 🟡 | ✅ |
| Connect bank (Yodlee / Plaid) | ✅ | 🟡 | ❌ |
| Manual bank account fields | ✅ | ✅ | ✅ |
| Edit / archive / delete bank account | ✅ | ✅ | ✅ |
| Transaction rules list | ✅ | 🟡 | ✅ |
| Create transaction rule (auto-match) | ✅ | 🟡 | ✅ |
| Reconnect (Yodlee / Nordigen OAuth) | ✅ | 🟡 | ❌ |
| Plan / feature gating (enterprise) | ✅ | 🟡 | ❌ |

### E-Invoice

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| E-Invoice Settings (format selection: UBL / Factur-X / etc.) | ✅ | ❌ | ✅ |
| Merge to PDF | ✅ | ❌ | ✅ |
| Peppol registration (EU countries) | ✅ | ❌ | ✅ |
| Peppol registration (Singapore CorpPass) | ✅ | ❌ | ❌ |
| Verifactu (Spain) configuration | ✅ | ❌ | 🟡 |
| E-invoice certificate upload + passphrase | ✅ | ❌ | ✅ |
| Payment means (IBAN / BIC / card) | ✅ | ❌ | ✅ |
| Additional tax identifiers | ✅ | ❌ | ✅ |
| E-invoice compliance fields per entity | ✅ | ❌ | ❌ |

### Group Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Group list (Groups) | ✅ | ✅ | ✅ |
| Group create / edit (Name) | ✅ | ✅ | ✅ |
| Group Currency override | ✅ | ✅ | ✅ |
| Group Language override | ✅ | ✅ | ✅ |
| Group Country override | ✅ | ✅ | ✅ |
| Group archive / restore / delete | ✅ | ✅ | ✅ |
| Assign clients to group | ✅ | ✅ | ✅ |
| Group-level cascading settings override | ✅ | ✅ | ✅ |

### Payment Links

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Payment link list | ✅ | ✅ | ✅ |
| Create recurring payment link | ✅ | ✅ | ✅ |
| Subscription pricing / frequency | ✅ | ✅ | ✅ |
| Edit / cancel subscription | ✅ | ✅ | ✅ |
| Configurable checkout flow (Steps) | ✅ | — | ✅ |
| Webhook configuration (URL + headers) | ✅ | ✅ | ✅ |

### Schedules

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Schedule list | ✅ | ✅ | ✅ |
| Create email schedule | ✅ | ✅ | ✅ |
| Schedule frequency / timing | ✅ | ✅ | ✅ |
| Report-delivery schedule | ✅ | ✅ | ✅ |
| Email-record schedule (single invoice / quote / credit / PO) | ✅ | ✅ | ✅ |
| Invoice-outstanding-tasks schedule | ✅ | ✅ | ✅ |
| Payment-schedule (split invoice into dated installments) | ✅ | ✅ | ✅ |
| Pause / resume schedule | — | — | ✅ |
| Starter cards on empty state | — | — | ✅ |

### User Management

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| User list | ✅ | ✅ | ✅ |
| Create / invite user | ✅ | ✅ | ✅ |
| User role assignment (admin / staff) | ✅ | ✅ | ✅ |
| Per-module permission grid | ✅ | ✅ | ✅ |
| Edit user details (Enterprise) | ✅ | ✅ | ✅ |
| Bulk user management | ✅ | ✅ | 🟡 |
| User activity log | ✅ | ✅ | 🟡 |
| Remove / revoke user | ✅ | ✅ | ✅ |

### Payment Terms

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Payment term list | ✅ | ✅ | ✅ |
| Create / edit payment term (Name) | ✅ | ✅ | ✅ |
| Net-days / due-day configuration | ✅ | ✅ | ✅ |
| Archive / restore / delete | ✅ | ✅ | ✅ |

### Task Statuses

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Task status list | ✅ | ✅ | ✅ |
| Create / edit task status (Name) | ✅ | ✅ | ✅ |
| Task status color picker | ✅ | ✅ | ✅ |
| Task status reordering | ✅ | ✅ | ✅ |
| Task status archive / restore / delete | ✅ | ✅ | ✅ |

### Expense Categories

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Expense category list | ✅ | ✅ | ✅ |
| Create / edit expense category (Name) | ✅ | ✅ | ✅ |
| Expense category color | ✅ | ✅ | ✅ |
| Expense category archive / restore / delete / purge | ✅ | ✅ | ✅ |

### System Logs

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| App Version (display) | ✅ | ✅ | ✅ |
| Server Version (display) | ✅ | ✅ | ✅ |
| Pending Outbox count (display) | — | ✅ | ✅ |
| Dead-letter count (display) | — | ✅ | ✅ |
| Full-sync status (display) | — | ✅ | ✅ |
| View system / error logs (server feed + local diagnostics) | ✅ | ✅ | ✅ |
| API call logs | ✅ | ✅ | ✅ |
| User action audit trail | ✅ | ✅ | 🟡 |
| Outbox / diagnostics snapshot export | — | 🟡 | ✅ |

---

## Payment gateways

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Gateway list | ✅ | ✅ | ✅ |
| Gateway detail | ✅ | ✅ | ✅ |
| Gateway edit | ✅ | ✅ | ✅ |
| Gateway create / add | ✅ | ✅ | ✅ |
| Gateway disconnect / deactivate | ✅ | ✅ | ✅ |
| Gateway archive / restore | ✅ | ✅ | ✅ |
| Gateway purge | ✅ | ✅ | ✅ |
| Import customers from gateway | ✅ | ✅ | ✅ |
| Verify customers at gateway | ✅ | ✅ | ✅ |
| OAuth setup launcher | ✅ | ✅ | ✅ |
| Stripe Connect flow | ✅ | ✅ | ✅ |
| Stripe (standard mode) | ✅ | ✅ | ✅ |
| PayPal | ✅ | ✅ | ✅ |
| Authorize.Net | ✅ | ✅ | 🟡 |
| Multi-gateway priority ordering | ✅ | ✅ | ✅ |

---

## Sync & offline

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Outbox queue UI (pending / in-flight / dead) | — | ✅ | ✅ |
| Manual retry of failed sync | — | ✅ | ✅ |
| Discard stuck / dead outbox rows | — | ✅ | ✅ |
| 409 conflict resolution sheet | — | 🟡 | ✅ |
| 412 password gate (re-prompt for password) | ✅ | ✅ | ✅ |
| 422 field-level validation errors | ✅ | ✅ | ✅ |
| Idempotency keys on mutations | ✅ | 🟡 | ✅ |
| Background outbox drain when online | — | ✅ | ✅ |
| Company-switch sync parity (prompt for pending) | — | ✅ | ✅ |
| Per-company FIFO outbox ordering | — | 🟡 | ✅ |
| Offline editing (full CRUD without network) | — | 🟡 | ✅ |
| Encrypted local database (SQLCipher) | — | ❌ | ✅ |

---

## Cross-cutting

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Global search / command palette | ✅ | ✅ | 🟡 |
| Settings search | ✅ | ✅ | ✅ |
| Dark mode / light mode toggle | ✅ | ✅ | ✅ |
| Multi-language UI (40+ locales) | ✅ | ✅ | ✅ |
| Company switcher | ✅ | ✅ | ✅ |
| Keyboard shortcuts | ✅ | ✅ | ✅ |
| Real-time WebSocket / Pusher notifications | ✅ | ✅ | ❌ |
| Live UI refresh on server-side change | ✅ | ✅ | ❌ |
| Push notifications (FCM / APNs) | 🟡 | ✅ | ❌ |
| Deep links | — | ✅ | ✅ |
| Native share sheet | — | ✅ | 🟡 |
| Responsive layout — mobile | ✅ | ✅ | ✅ |
| Responsive layout — tablet | ✅ | ✅ | ✅ |
| Responsive layout — desktop | ✅ | ✅ | ✅ |
| Column picker on lists | ✅ | ✅ | ✅ |
| Saved views (filter + sort + columns) | ✅ | ✅ | ✅ |
| Bulk-actions framework | ✅ | ✅ | ✅ |
| PDF generation | ✅ | ✅ | ✅ |
| In-app PDF preview / viewer | ✅ | ✅ | ✅ |
| CSV export | ✅ | ✅ | 🟡 |
| Sentry / error-tracking integration | ✅ | ✅ | ❌ |
| Per-entity activity / audit feed | ✅ | ✅ | ✅ |
| Per-entity comments / internal notes | ✅ | ✅ | ✅ |
| Unsaved-changes guard on navigation | ✅ | ✅ | ✅ |
| Phone-number input with validation | ✅ | ✅ | ✅ |
| Signature pad | ✅ | ✅ | 🟡 |
| Image crop editor | ✅ | ✅ | 🟡 |
| QR code generation | ✅ | ✅ | 🟡 |
| Accent color customization | ✅ | ✅ | ✅ |
| Help / tooltip system | ✅ | ✅ | ✅ |
| Onboarding tour | ✅ | 🟡 | ❌ |
| New-company setup wizard (name / currency / language) | ✅ | ✅ | ✅ |
| Contact-us dialog | ✅ | ✅ | ✅ |
| About dialog | ✅ | ✅ | ✅ |
| Health check dialog (self-hosted diagnostics) | ✅ | ✅ | ✅ |
| Trial-footer indicator | ✅ | ✅ | ❌ |
| Cookie / privacy banner | ✅ | — | — |
| Migration import from competitors (FreshBooks / Wave / CSV) | ✅ | ❌ | ❌ |
| Clipboard copy actions | ✅ | ✅ | ✅ |
| Toast notifications | ✅ | ✅ | ✅ |
| Markdown editor (rich text) | ✅ | ✅ | ✅ |
| Restore-on-restart (resume last screen) | 🟡 | ✅ | ✅ |
| Encrypted local persistence | — | ❌ | ✅ |

---

## Platform / mobile specific

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Biometric lock (Touch ID / Face ID / fingerprint) | — | ✅ | ✅ |
| Push notifications (FCM / APNs) | — | ✅ | ❌ |
| Native share sheet | — | ✅ | 🟡 |
| OS deep links / universal links | — | ✅ | ✅ |
| Native window-state persistence (macOS) | — | ❌ | ✅ |
| OAuth deep-link handler (callback URL) | — | ✅ | ✅ |
