# Integration tests

`integration_test/app_smoke_test.dart` boots the real `InvoiceNinjaApp` with in-memory Drift + `InMemoryTokenStorage` and a `MockClient`. Scenarios cover: boot to `/login` with no creds, boot to `/lock` when biometric is enabled, lock-screen sign-out, post-auth redirect to `/dashboard` vs `/clients` (driven by `view_dashboard` permission), and a full login → refresh round-trip. Guards the DI graph, router, theme, and localization wiring.

**Don't run integration tests locally unless the user explicitly asks** — they take over the foreground app and interrupt the developer's session. Never run them proactively or as incidental verification. When the user explicitly asks, run them in an isolated worktree (see **Running locally on request** below). CI runs them on every PR via `.github/workflows/ci.yaml`: the full suite on **macOS desktop** (`-d macos`, incl. the live `demo/*` files when reachable), plus `app_smoke_test.dart` on **Chrome** (`-d web-server --browser-name=chrome`) to guard the web build. The live `demo/*` suite and any filesystem/secure-storage/`pruneBrokenDbFiles` unit tests are `@TestOn('vm')` / macOS-only — they don't run under the web job.

**Local runs can't use the CI command.** `flutter test integration_test/ -d macos` only ever works for the *first* file on desktop — [flutter/flutter#135673](https://github.com/flutter/flutter/issues/135673): the tool reuses a debug-connection stream that breaks on the second app launch, so every later file dies with `Error waiting for a debug connection: The log reader stopped unexpectedly, or never started.` → `Unable to start the app on the device.` CI survives the same command only because its runner can't reach `demo.invoiceninja.com`, so the `demo/*` live files self-skip (`skipIfUnreachable`, `integration_test/support/demo_harness.dart`) and `app_smoke_test.dart` is the lone app launch. Locally the demo server *is* reachable, so it bites. For deliberate local verification use `tools/run_integration_local.sh` (one `flutter test` invocation per file = the upstream workaround; mocked suite only by default, `--include-demo` adds the live `demo/*` files).

**Running locally on request.** Only when the user explicitly asks. The run is long (tens of minutes with `--include-demo`) and the repo is live-edited during sessions, so run against an isolated git worktree on a throwaway branch — concurrent edits to the main checkout then can't perturb the code under test — and tear the worktree + branch down afterward, even on failure. Note the macOS run still grabs the foreground app window; the worktree isolates the *code*, not the screen, so it's still strictly on-request.

```bash
ts=$(date +%Y%m%d-%H%M%S)
root=$(git rev-parse --show-toplevel)
wt="$root/../in-itest-$ts"          # sibling of the main checkout, not nested in it
br="itest/$ts"
# Non-destructive WIP snapshot: `git stash create` does NOT touch the working
# tree or the stash list (this is NOT `git stash` — see the "never git stash to
# experiment" rule). Empty when the tree is clean → falls back to HEAD.
snap=$(git -C "$root" stash create)
git -C "$root" worktree add -b "$br" "$wt" "${snap:-HEAD}"
# `git stash create` omits untracked-but-not-ignored files — copy them in too:
git -C "$root" ls-files --others --exclude-standard -z \
  | rsync -a --from0 --files-from=- "$root/" "$wt/"
# Guarantee teardown even on failure / interrupt:
trap 'git -C "$root" worktree remove --force "$wt"; git -C "$root" branch -D "$br"' EXIT
( cd "$wt" && flutter pub get && bash tools/run_integration_local.sh --include-demo )
```

Run it as a script (so the `trap` fires) or, if invoking step-by-step, always finish with `git worktree remove --force "$wt" && git branch -D "$br"` even when the run fails. `git worktree list` afterward must not show a leftover `in-itest-*`. This worktree-on-a-temp-branch flow is the **sole exception** to the "never create/switch branches in this checkout" strict rule — it branches inside an isolated sibling worktree, never the main checkout.

Stable widget keys (`login_submit`, `lock_unlock`, `lock_sign_out`) keep assertions locale-independent. Add similar keys when extending the test.

When adding scenarios, mock both `/api/v1/login` and `/api/v1/refresh` if the flow authenticates — `_persistAndActivate` calls refresh after a successful login, and `restore()` fires a best-effort refresh too. The shared `_silentNetwork()` helper returns a 500-MockClient for scenarios that don't care about the wire.
