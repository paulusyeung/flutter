# Invoice Ninja — Flutter Admin (v2)

Clean-room rebuild of the Invoice Ninja admin client. Replaces the Redux-based
[`admin-portal`](https://github.com/invoiceninja/admin-portal) with three goals:

1. Page-by-page data loading (no `per_page=999999`)
2. True offline editing via a local mutation outbox
3. No Redux — plain `ChangeNotifier` state

Plus two non-negotiables carried from v1: app restart restores exactly where the
user left off, and full multi-company support.

## Feature parity

See **[FEATURES.md](FEATURES.md)** for the live tracker comparing every feature
across the React web client, Flutter v1 (admin-portal), and this rebuild.

## Architecture & contributing

`CLAUDE.md` at repo root is the primary architecture doc. See `docs/` for deep
dives on the offline write pipeline, adding entities, settings screens, and
probing the demo API.
