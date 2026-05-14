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
| Two-factor SMS verification | ✅ | ✅ | ❌ |
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
| Delta chip (period-over-period change) | ✅ | ✅ | 🟡 |
| Sparkline charts on KPIs | ✅ | ✅ | 🟡 |
| Recent payments card | ✅ | ✅ | ✅ |
| Upcoming invoices card | ✅ | ✅ | 🟡 |
| Upcoming quotes card | ✅ | ✅ | 🟡 |
| Upcoming recurring invoices card | ✅ | ✅ | 🟡 |
| Expired quotes card | ✅ | ✅ | 🟡 |
| Past-due invoices card | ✅ | ✅ | 🟡 |
| Needs-attention auto-detected items | ✅ | ✅ | 🟡 |
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
| Client — clone | ✅ | ❌ | ❌ |
| Client — merge two clients | ✅ | ❌ | 🟡 |
| Client — statement PDF | ✅ | ✅ | ✅ |
| Client — comments / internal notes | ✅ | ✅ | ✅ |
| Client — documents / attachments | ✅ | ✅ | ✅ |
| Client — activity / audit feed | ✅ | ✅ | ✅ |
| Client — email history | ✅ | ✅ | ❌ |
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
| Client — import (CSV / JSON) | ✅ | 🟡 | ❌ |
| Client — cross-entity "New invoice / quote / task" | ✅ | ✅ | 🟡 |

---

## Invoices

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Invoice — list | ✅ | ✅ | ❌ |
| Invoice — detail | ✅ | ✅ | ❌ |
| Invoice — edit (line items, dates, totals) | ✅ | ✅ | ❌ |
| Invoice — create | ✅ | ✅ | ❌ |
| Invoice — clone to new invoice | ✅ | ✅ | ❌ |
| Invoice — clone to quote | ✅ | ✅ | ❌ |
| Invoice — clone to credit | ✅ | ❌ | ❌ |
| Invoice — clone to recurring invoice | ✅ | ✅ | ❌ |
| Invoice — clone to purchase order | ✅ | ❌ | ❌ |
| Invoice — mark sent | ✅ | ✅ | ❌ |
| Invoice — mark paid | ✅ | ✅ | ❌ |
| Invoice — mark partial payment | ✅ | ✅ | ❌ |
| Invoice — refund / credit application | ✅ | ✅ | ❌ |
| Invoice — cancel | ✅ | ✅ | ❌ |
| Invoice — rectify (reversal / correction) | ✅ | ❌ | ❌ |
| Invoice — email to client | ✅ | ✅ | ❌ |
| Invoice — schedule email (delayed send) | ✅ | ❌ | ❌ |
| Invoice — change template / design | ✅ | ✅ | ❌ |
| Invoice — auto-bill with gateway | ✅ | ✅ | ❌ |
| Invoice — view / download PDF | ✅ | ✅ | ❌ |
| Invoice — print | ✅ | ✅ | ❌ |
| Invoice — audit trail / history | ✅ | ✅ | ❌ |
| Invoice — email history | ✅ | ✅ | ❌ |
| Invoice — activities | ✅ | ✅ | ❌ |
| Invoice — payment schedule view | ✅ | ✅ | ❌ |
| Invoice — unapplied payments view | ✅ | ✅ | ❌ |
| Invoice — documents / attachments | ✅ | ✅ | ❌ |
| Invoice — e-invoice (UBL / Factur-X) | ✅ | ❌ | ❌ |
| Invoice — Peppol delivery | ✅ | ❌ | ❌ |
| Invoice — Verifactu (Spain) compliance | ✅ | ❌ | ❌ |
| Invoice — archive / restore / delete | ✅ | ✅ | ❌ |
| Invoice — bulk actions | ✅ | ✅ | ❌ |
| Invoice — import (CSV) | ✅ | 🟡 | ❌ |
| Invoice — custom fields | ✅ | ✅ | ❌ |

---

## Quotes

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Quote — list | ✅ | ✅ | ❌ |
| Quote — detail | ✅ | ✅ | ❌ |
| Quote — edit | ✅ | ✅ | ❌ |
| Quote — create | ✅ | ✅ | ❌ |
| Quote — clone to quote | ✅ | ✅ | ❌ |
| Quote — clone to invoice | ✅ | ✅ | ❌ |
| Quote — convert / approve to invoice | ✅ | ✅ | ❌ |
| Quote — mark sent | ✅ | ✅ | ❌ |
| Quote — email to client | ✅ | ✅ | ❌ |
| Quote — schedule email | ✅ | ❌ | ❌ |
| Quote — change template / design | ✅ | ✅ | ❌ |
| Quote — view / download PDF | ✅ | ✅ | ❌ |
| Quote — activities | ✅ | ✅ | ❌ |
| Quote — email history | ✅ | ✅ | ❌ |
| Quote — documents / attachments | ✅ | ✅ | ❌ |
| Quote — archive / restore / delete | ✅ | ✅ | ❌ |
| Quote — bulk actions | ✅ | ✅ | ❌ |
| Quote — import (CSV) | ✅ | 🟡 | ❌ |
| Quote — custom fields | ✅ | ✅ | ❌ |

---

## Credits

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Credit — list | ✅ | ✅ | ❌ |
| Credit — detail | ✅ | ✅ | ❌ |
| Credit — edit | ✅ | ✅ | ❌ |
| Credit — create | ✅ | ✅ | ❌ |
| Credit — clone to credit | ✅ | ✅ | ❌ |
| Credit — clone to invoice | ✅ | ❌ | ❌ |
| Credit — apply to invoice | ✅ | ✅ | ❌ |
| Credit — email to client | ✅ | ✅ | ❌ |
| Credit — change template / design | ✅ | ✅ | ❌ |
| Credit — view / download PDF | ✅ | ✅ | ❌ |
| Credit — activities | ✅ | ✅ | ❌ |
| Credit — e-invoice / Peppol | ✅ | ❌ | ❌ |
| Credit — documents / attachments | ✅ | ✅ | ❌ |
| Credit — archive / restore / delete | ✅ | ✅ | ❌ |
| Credit — bulk actions | ✅ | ✅ | ❌ |
| Credit — custom fields | ✅ | ✅ | ❌ |

---

## Recurring invoices

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Recurring invoice — list | ✅ | ✅ | ❌ |
| Recurring invoice — detail | ✅ | ✅ | ❌ |
| Recurring invoice — edit | ✅ | ✅ | ❌ |
| Recurring invoice — create | ✅ | ✅ | ❌ |
| Recurring invoice — clone | ✅ | ✅ | ❌ |
| Recurring invoice — start / activate | ✅ | ✅ | ❌ |
| Recurring invoice — stop / pause | ✅ | ✅ | ❌ |
| Recurring invoice — send now | ✅ | ✅ | ❌ |
| Recurring invoice — change template / design | ✅ | ✅ | ❌ |
| Recurring invoice — view next-occurrence schedule | ✅ | ✅ | ❌ |
| Recurring invoice — view / download PDF | ✅ | ✅ | ❌ |
| Recurring invoice — activities | ✅ | ✅ | ❌ |
| Recurring invoice — email history | ✅ | ✅ | ❌ |
| Recurring invoice — documents / attachments | ✅ | ✅ | ❌ |
| Recurring invoice — e-invoice | ✅ | ❌ | ❌ |
| Recurring invoice — archive / restore / delete | ✅ | ✅ | ❌ |
| Recurring invoice — bulk actions | ✅ | ✅ | ❌ |
| Recurring invoice — import | ✅ | 🟡 | ❌ |
| Recurring invoice — custom fields | ✅ | ✅ | ❌ |

---

## Payments

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Payment — list | ✅ | ✅ | ❌ |
| Payment — detail | ✅ | ✅ | ❌ |
| Payment — edit | ✅ | ✅ | ❌ |
| Payment — record manual payment | ✅ | ✅ | ❌ |
| Payment — apply to specific invoice | ✅ | ✅ | ❌ |
| Payment — refund (partial / full) | ✅ | ✅ | ❌ |
| Payment — email receipt | ✅ | ✅ | ❌ |
| Payment — view payment method / gateway used | ✅ | ✅ | ❌ |
| Payment — activities / audit trail | ✅ | ✅ | ❌ |
| Payment — documents / attachments | ✅ | ✅ | ❌ |
| Payment — archive / restore / delete | ✅ | ✅ | ❌ |
| Payment — bulk actions | ✅ | ✅ | ❌ |
| Payment — import (CSV) | ✅ | 🟡 | ❌ |
| Payment — custom fields | ✅ | ✅ | ❌ |

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
| Project — invoice project (bill all tasks) | ✅ | ✅ | 🟡 |
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
| Task — invoice from task | ✅ | ✅ | 🟡 |
| Task — status colors | ✅ | ✅ | ✅ |
| Task — assignee | ✅ | ✅ | ✅ |
| Task — link to project (with project rate) | ✅ | ✅ | ✅ |
| Task — link to client | ✅ | ✅ | ✅ |
| Task — documents / attachments | ✅ | ✅ | ✅ |
| Task — activities | ✅ | ✅ | ✅ |
| Task — custom fields | ✅ | ✅ | ✅ |
| Task — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Task — bulk actions | ✅ | ✅ | ✅ |
| Task — import (CSV) | ✅ | 🟡 | ❌ |

---

## Vendors

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Vendor — list | ✅ | ✅ | ✅ |
| Vendor — detail | ✅ | ✅ | ✅ |
| Vendor — edit | ✅ | ✅ | ✅ |
| Vendor — create | ✅ | ✅ | ✅ |
| Vendor — clone | ✅ | ❌ | ❌ |
| Vendor — comments / internal notes | ✅ | ✅ | ✅ |
| Vendor — documents / attachments | ✅ | ✅ | ✅ |
| Vendor — activities | ✅ | ✅ | ✅ |
| Vendor — "New expense" shortcut (prefills vendor) | ✅ | ✅ | 🟡 |
| Vendor — custom fields | ✅ | ✅ | ✅ |
| Vendor — view vendor expenses / POs / recurring expenses | ✅ | ✅ | 🟡 |
| Vendor — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Vendor — bulk actions | ✅ | ✅ | ✅ |
| Vendor — import (CSV) | ✅ | 🟡 | ❌ |

---

## Purchase orders

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Purchase order — list | ✅ | ✅ | ❌ |
| Purchase order — detail | ✅ | ✅ | ❌ |
| Purchase order — edit | ✅ | ✅ | ❌ |
| Purchase order — create | ✅ | ✅ | ❌ |
| Purchase order — clone | ✅ | ✅ | ❌ |
| Purchase order — convert to expense | ✅ | ✅ | ❌ |
| Purchase order — email to vendor | ✅ | ✅ | ❌ |
| Purchase order — schedule email | ✅ | ❌ | ❌ |
| Purchase order — mark sent | ✅ | ✅ | ❌ |
| Purchase order — accept (vendor side) | ✅ | ❌ | ❌ |
| Purchase order — change template / design | ✅ | ✅ | ❌ |
| Purchase order — view / download PDF | ✅ | ✅ | ❌ |
| Purchase order — activities | ✅ | ✅ | ❌ |
| Purchase order — email history | ✅ | ✅ | ❌ |
| Purchase order — documents / attachments | ✅ | ✅ | ❌ |
| Purchase order — archive / restore / delete | ✅ | ✅ | ❌ |
| Purchase order — bulk actions | ✅ | ✅ | ❌ |
| Purchase order — import | ✅ | 🟡 | ❌ |
| Purchase order — custom fields | ✅ | ✅ | ❌ |

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
| Expense — convert / add to invoice | ✅ | ✅ | 🟡 |
| Expense — documents / receipts attachment | ✅ | ✅ | ✅ |
| Expense — comments | ✅ | ✅ | ✅ |
| Expense — activities | ✅ | ✅ | ✅ |
| Expense — custom fields | ✅ | ✅ | ✅ |
| Expense — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Expense — bulk actions | ✅ | ✅ | ✅ |
| Expense — import (CSV) | ✅ | 🟡 | ❌ |

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
| Bank transaction — list | ✅ | ❌ | ❌ |
| Bank transaction — create | ✅ | ❌ | ❌ |
| Bank transaction — edit / categorize | ✅ | ❌ | ❌ |
| Bank transaction — import (CSV) | ✅ | ❌ | ❌ |
| Bank transaction — import (OFX / QIF / QFX) | ✅ | ❌ | ❌ |
| Bank transaction — match to invoice | ✅ | ❌ | ❌ |
| Bank transaction — match to expense | ✅ | ❌ | ❌ |
| Bank transaction — transaction rules (auto-match) | ✅ | ❌ | ❌ |
| Bank transaction — bulk actions | ✅ | ❌ | ❌ |

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
| Product — tax category | ✅ | ✅ | 🟡 |
| Product — stock / inventory tracking | ✅ | 🟡 | 🟡 |
| Product — custom fields | ✅ | ✅ | ✅ |
| Product — activities | ✅ | ✅ | ✅ |
| Product — archive / restore / delete / purge | ✅ | ✅ | ✅ |
| Product — bulk actions | ✅ | ✅ | ✅ |
| Product — import (CSV) | ✅ | 🟡 | ❌ |

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
| Report — activity | ✅ | ✅ | ❌ |
| Report — client | ✅ | ✅ | ❌ |
| Report — contact | ✅ | ✅ | ❌ |
| Report — credit | ✅ | ✅ | ❌ |
| Report — document | ✅ | 🟡 | ❌ |
| Report — expense | ✅ | ✅ | ❌ |
| Report — invoice | ✅ | ✅ | ❌ |
| Report — invoice item | ✅ | ✅ | ❌ |
| Report — quote | ✅ | ✅ | ❌ |
| Report — quote item | ✅ | ✅ | ❌ |
| Report — recurring invoice | ✅ | ✅ | ❌ |
| Report — recurring invoice item | ✅ | 🟡 | ❌ |
| Report — payment | ✅ | ✅ | ❌ |
| Report — product | ✅ | ✅ | ❌ |
| Report — product sales | ✅ | ✅ | ❌ |
| Report — task | ✅ | ✅ | ❌ |
| Report — vendor | ✅ | ✅ | ❌ |
| Report — purchase order | ✅ | ✅ | ❌ |
| Report — purchase order item | ✅ | 🟡 | ❌ |
| Report — profit / loss | ✅ | ✅ | ❌ |
| Report — client balance | ✅ | ✅ | ❌ |
| Report — client sales | ✅ | ✅ | ❌ |
| Report — aged receivable (detailed) | ✅ | ✅ | ❌ |
| Report — aged receivable (summary) | ✅ | ✅ | ❌ |
| Report — user sales | ✅ | 🟡 | ❌ |
| Report — tax summary | ✅ | ✅ | ❌ |
| Report — tax period | ✅ | ❌ | ❌ |
| Report — project | ✅ | ✅ | ❌ |
| Report — custom column selection | ✅ | ✅ | ❌ |
| Report — date range filters (preset + custom) | ✅ | ✅ | ❌ |
| Report — export to PDF / CSV | ✅ | ✅ | ❌ |
| Report — email-scheduled delivery | ✅ | 🟡 | ❌ |
| Report — grouping by dimension | ✅ | ✅ | ❌ |
| Report — multi-entity filtering | ✅ | ✅ | ❌ |

---

## Settings — Basic

### Company Details

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Company name / legal name / ID number / VAT | ✅ | ✅ | ✅ |
| Company address | ✅ | ✅ | ✅ |
| Company logo upload + crop | ✅ | ✅ | ✅ |
| Company website / phone / email | ✅ | ✅ | ✅ |
| Company defaults (terms, design, language) | ✅ | ✅ | ✅ |
| Company documents | ✅ | ✅ | ✅ |
| Company custom fields | ✅ | ✅ | ✅ |
| Country-specific fields (Swiss QR IBAN, BESR ID) | ✅ | ✅ | ✅ |

### User Details

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| User profile (name / email / phone) | ✅ | ✅ | ✅ |
| User password change | ✅ | ✅ | ✅ |
| Two-factor authentication setup / disable | ✅ | ✅ | ✅ |
| User signature image upload | ✅ | ✅ | ✅ |
| Document language preference | ✅ | ✅ | ✅ |
| Email notification preferences | ✅ | ✅ | ✅ |
| Connected OAuth accounts | ✅ | ✅ | 🟡 |
| User preferences (defaults / UI) | ✅ | ✅ | ✅ |

### Localization

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Default currency | ✅ | ✅ | ✅ |
| Currency display format (symbol / position / decimals) | ✅ | ✅ | ✅ |
| UI language selection | ✅ | ✅ | ✅ |
| Timezone | ✅ | ✅ | ✅ |
| Date format | ✅ | ✅ | ✅ |
| Military / 24-hour time | ✅ | ✅ | ✅ |
| Decimal separator (period / comma) | ✅ | ✅ | ✅ |
| First month of year (fiscal start) | ✅ | ✅ | ✅ |
| Custom label overrides | ✅ | ✅ | ✅ |

### Workflow Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Invoice workflow (auto-archive, partial allowed) | ✅ | ✅ | 🟡 |
| Quote workflow (auto-convert, approval) | ✅ | ✅ | 🟡 |
| Recurring workflow defaults | ✅ | ✅ | 🟡 |
| Document workflow (auto-attach) | ✅ | ✅ | 🟡 |

### Online Payments

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Online payments general toggle | ✅ | ✅ | ✅ |
| Default payment method | ✅ | ✅ | ✅ |
| Allow partial / over payments | ✅ | ✅ | ✅ |
| Payment notification emails | ✅ | ✅ | ✅ |
| Payment method branding (logos, names) | ✅ | ✅ | ✅ |

### Tax Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Default invoice tax rate | ✅ | ✅ | ✅ |
| Default item tax rate | ✅ | ✅ | ✅ |
| Default expense tax rate | ✅ | ✅ | ✅ |
| Inclusive vs exclusive taxes | ✅ | ✅ | ✅ |
| Calculate taxes (auto/manual) | ✅ | ✅ | ✅ |
| Tax rate CRUD (manage rate list) | ✅ | ✅ | ❌ |
| Seller subregion (EU VAT, etc.) | ✅ | ✅ | ✅ |
| Reduced tax rate toggle | ✅ | ✅ | ✅ |

### Product Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Default product tax rate | ✅ | ✅ | ✅ |
| Product unit cost / margin tracking | ✅ | ✅ | ✅ |
| Product field visibility | ✅ | ✅ | ✅ |
| Stock notification threshold | ✅ | ✅ | 🟡 |

### Task Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Default task billable rate | ✅ | ✅ | ✅ |
| Task status configuration | ✅ | ✅ | ✅ |
| Task timer increment default | ✅ | ✅ | ✅ |
| Calculate / round tax on tasks | ✅ | ✅ | ✅ |

### Expense Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Default expense category | ✅ | ✅ | ✅ |
| Expense tax rate defaults | ✅ | ✅ | ✅ |
| Mark expenses invoiceable by default | ✅ | ✅ | ✅ |
| Add expense docs to invoice by default | ✅ | ✅ | ✅ |

### Account Management

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Plan / subscription overview | ✅ | ✅ | 🟡 |
| Activate / deactivate company | ✅ | ✅ | ✅ |
| Force full data resync | ✅ | ✅ | ✅ |
| Enabled modules toggle | ✅ | ✅ | ✅ |
| API tokens management | ✅ | ✅ | ✅ |
| API webhooks configuration | ✅ | ✅ | ✅ |
| Analytics integration (Google Analytics) | ✅ | ✅ | ✅ |
| Password timeout setting | ✅ | ✅ | 🟡 |
| Markdown toggle for emails / invoices | ✅ | ✅ | 🟡 |
| Include drafts / deleted in lists | ✅ | ✅ | 🟡 |
| Referral / affiliate program | ✅ | ✅ | ✅ |
| Danger zone (delete company, etc.) | ✅ | ✅ | 🟡 |

### Backup & Restore

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Backup company data | ✅ | ✅ | ✅ |
| Restore from backup | ✅ | 🟡 | ✅ |
| Export company data | ✅ | 🟡 | ✅ |
| Export invoice data (CSV / PDF) | ✅ | ✅ | ✅ |

### Device Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Theme selection (light / dark / auto) | — | ✅ | ✅ |
| Biometric unlock toggle | — | ✅ | ✅ |
| Manual data refresh / resync | — | ✅ | ✅ |

---

## Settings — Advanced

### Invoice Design

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Choose invoice design template | ✅ | ✅ | 🟡 |
| Per-section layout (client / company / address) | ✅ | ✅ | 🟡 |
| Invoice / quote / credit / vendor / PO header layout | ✅ | ✅ | 🟡 |
| Product / quote-product / task column selection | ✅ | ✅ | 🟡 |
| Total fields selection | ✅ | ✅ | 🟡 |
| Custom design creation (header / body / footer) | ✅ | ✅ | 🟡 |
| Page size (A4 / Letter / etc.) | ✅ | ✅ | 🟡 |
| Font and color settings | ✅ | ✅ | 🟡 |
| Design template management (save / switch) | ✅ | ✅ | 🟡 |
| Custom design includes / variables | ✅ | ✅ | 🟡 |

### Custom Fields

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Custom fields — company | ✅ | ✅ | 🟡 |
| Custom fields — clients | ✅ | ✅ | 🟡 |
| Custom fields — products | ✅ | ✅ | 🟡 |
| Custom fields — invoices | ✅ | ✅ | 🟡 |
| Custom fields — payments | ✅ | ✅ | 🟡 |
| Custom fields — projects | ✅ | ✅ | 🟡 |
| Custom fields — tasks | ✅ | ✅ | 🟡 |
| Custom fields — vendors | ✅ | ✅ | 🟡 |
| Custom fields — expenses | ✅ | ✅ | 🟡 |
| Custom fields — quotes | ✅ | ✅ | 🟡 |
| Custom fields — credits | ✅ | ✅ | 🟡 |
| Custom fields — users | ✅ | ✅ | 🟡 |

### Generated Numbers

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Generated numbers — clients | ✅ | ✅ | ✅ |
| Generated numbers — invoices | ✅ | ✅ | ✅ |
| Generated numbers — recurring invoices | ✅ | ✅ | ✅ |
| Generated numbers — payments | ✅ | ✅ | ✅ |
| Generated numbers — quotes | ✅ | ✅ | ✅ |
| Generated numbers — credits | ✅ | ✅ | ✅ |
| Generated numbers — projects | ✅ | ✅ | ✅ |
| Generated numbers — tasks | ✅ | ✅ | ✅ |
| Generated numbers — vendors | ✅ | ✅ | ✅ |
| Generated numbers — purchase orders | ✅ | ✅ | ✅ |
| Generated numbers — expenses | ✅ | ✅ | ✅ |
| Generated numbers — recurring expenses | ✅ | ✅ | ✅ |
| Number pattern / padding width | ✅ | ✅ | ✅ |
| Reset counter value | ✅ | ✅ | ✅ |

### Client Portal

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Portal enable / disable | ✅ | ✅ | 🟡 |
| Portal mode (public / login / subdomain) | ✅ | ✅ | 🟡 |
| Custom subdomain / domain | ✅ | ✅ | 🟡 |
| Client self-registration toggle | ✅ | ✅ | 🟡 |
| Client profile self-edit toggle | ✅ | ✅ | 🟡 |
| Portal document uploads | ✅ | ✅ | 🟡 |
| Portal messaging / inbox | ✅ | ✅ | 🟡 |
| Portal custom CSS | ✅ | ✅ | 🟡 |
| Portal custom JS | ✅ | ✅ | 🟡 |
| Portal welcome / footer messages | ✅ | ✅ | 🟡 |

### Email Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| SMTP server configuration | ✅ | ✅ | 🟡 |
| Gmail integration (OAuth) | ✅ | ✅ | 🟡 |
| Postmark integration | ✅ | ✅ | 🟡 |
| Mailgun integration | ✅ | ✅ | 🟡 |
| Sender name / email override | ✅ | ✅ | 🟡 |
| Email signature | ✅ | ✅ | 🟡 |
| Email templates (per entity type) | ✅ | ✅ | 🟡 |
| Template variables reference | ✅ | ✅ | 🟡 |

### Templates & Reminders

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| First / second / third reminder rules | ✅ | ✅ | 🟡 |
| Endless reminder | ✅ | ✅ | 🟡 |
| Late fee auto-apply | ✅ | ✅ | 🟡 |
| Reminder schedule (days before / after due) | ✅ | ✅ | 🟡 |
| Recurring invoice reminder customization | ✅ | ✅ | 🟡 |
| Template variables editor | ✅ | ✅ | 🟡 |

### Bank Accounts

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Bank account list / connect (Yodlee / Plaid) | ✅ | 🟡 | 🟡 |
| Bank transaction import rules | ✅ | 🟡 | 🟡 |
| Auto-match rule creation | ✅ | 🟡 | 🟡 |
| Manual bank account fields | ✅ | ✅ | 🟡 |

### E-Invoice

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| E-invoice enable / disable | ✅ | ❌ | 🟡 |
| Peppol registration (CorpPass) | ✅ | ❌ | ❌ |
| E-invoice format selection (UBL / Factur-X / etc.) | ✅ | ❌ | 🟡 |
| Verifactu (Spain) configuration | ✅ | ❌ | ❌ |
| E-invoice compliance fields per entity | ✅ | ❌ | ❌ |

### Group Settings

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Group list | ✅ | ✅ | ✅ |
| Group create / edit | ✅ | ✅ | ✅ |
| Group archive / restore / delete | ✅ | ✅ | ✅ |
| Group permissions / settings | ✅ | ✅ | ✅ |
| Assign clients to group | ✅ | ✅ | ✅ |
| Group-level custom field values | ✅ | ✅ | ✅ |

### Subscriptions / Payment Links

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Subscription / payment link list | ✅ | ✅ | 🟡 |
| Create recurring payment link | ✅ | ✅ | 🟡 |
| Subscription pricing / frequency | ✅ | ✅ | 🟡 |
| Edit / cancel subscription | ✅ | ✅ | 🟡 |

### Schedules

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Schedule list | ✅ | ✅ | 🟡 |
| Create email schedule | ✅ | ✅ | 🟡 |
| Schedule frequency / timing | ✅ | ✅ | 🟡 |
| Report-delivery schedule | ✅ | ✅ | 🟡 |

### User Management

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| User list | ✅ | ✅ | 🟡 |
| Create / invite user | ✅ | ✅ | 🟡 |
| User role assignment (admin / staff) | ✅ | ✅ | 🟡 |
| Per-module permission grid | ✅ | ✅ | 🟡 |
| Edit user details (Enterprise) | ✅ | ✅ | 🟡 |
| Bulk user management | ✅ | ✅ | 🟡 |
| User activity log | ✅ | ✅ | 🟡 |
| Remove / revoke user | ✅ | ✅ | 🟡 |

### Payment Terms

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Payment term list | ✅ | ✅ | ✅ |
| Create / edit payment term | ✅ | ✅ | ✅ |
| Net-days / due-day configuration | ✅ | ✅ | ✅ |
| Archive / restore | ✅ | ✅ | ✅ |

### Task Statuses

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Task status list | ✅ | ✅ | ✅ |
| Create / edit task status | ✅ | ✅ | ✅ |
| Task status color picker | ✅ | ✅ | ✅ |
| Task status archive / restore | ✅ | ✅ | ✅ |

### Expense Categories

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| Expense category list | ✅ | ✅ | ✅ |
| Create / edit expense category | ✅ | ✅ | ✅ |
| Expense category archive / restore | ✅ | ✅ | ✅ |
| Expense category purge | ✅ | ✅ | ✅ |

### System Logs

| Feature | React | Flutter v1 | Flutter v2 |
|---|---|---|---|
| View system / error logs | ✅ | ✅ | ✅ |
| API call logs | ✅ | ✅ | 🟡 |
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
| Import customers from gateway | ✅ | ✅ | 🟡 |
| Verify customers at gateway | ✅ | ✅ | 🟡 |
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
| Keyboard shortcuts | ✅ | ✅ | 🟡 |
| Real-time WebSocket / Pusher notifications | ✅ | ✅ | ❌ |
| Live UI refresh on server-side change | ✅ | ✅ | ❌ |
| Push notifications (FCM / APNs) | 🟡 | ✅ | ❌ |
| Deep links | — | ✅ | ✅ |
| Native share sheet | — | ✅ | 🟡 |
| Responsive layout — mobile | ✅ | ✅ | ✅ |
| Responsive layout — tablet | ✅ | ✅ | ✅ |
| Responsive layout — desktop | ✅ | ✅ | ✅ |
| Column picker on lists | ✅ | ✅ | ✅ |
| Saved views (filter + sort + columns) | ✅ | ✅ | 🟡 |
| Bulk-actions framework | ✅ | ✅ | ✅ |
| PDF generation | ✅ | ✅ | 🟡 |
| In-app PDF preview / viewer | ✅ | ✅ | 🟡 |
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
| Help / tooltip system | ✅ | ✅ | 🟡 |
| Onboarding tour | ✅ | 🟡 | ❌ |
| Contact-us dialog | ✅ | ✅ | 🟡 |
| About dialog | ✅ | ✅ | ✅ |
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
