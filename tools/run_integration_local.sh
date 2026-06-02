#!/usr/bin/env bash
set -euo pipefail

# Run the integration suite locally, ONE FILE PER `flutter test` INVOCATION,
# each bounded by a per-file timeout.
#
# Why one file per invocation: `flutter test integration_test/ -d macos`
# (the bare-glob form) cannot run multiple integration files on desktop —
# flutter/flutter#135673. The tool reuses a debug-connection stream that
# breaks on the second app launch, so only the FIRST file gets a working
# app; every later file dies with "Error waiting for a debug connection:
# The log reader stopped unexpectedly, or never started." → "Unable to
# start the app on the device." One invocation per file is the
# upstream-recommended workaround.
#
# Why the per-file timeout: macOS desktop integration is flaky (e.g.
# "Failed to foreground app; open returned 1"); a wedged file otherwise
# hangs the whole sequential run indefinitely. Each file gets a hard
# wall-clock budget (default 900 s, override with INTEGRATION_FILE_TIMEOUT);
# on overrun the invocation + its app/test processes are killed and the run
# moves on, recording the file as TIMEOUT. No `timeout(1)` dependency
# (macOS lacks it) — a background watcher does the kill.
#
# CI uses THIS script — the `apple` job in .github/workflows/ci.yaml runs
# `run_integration_local.sh --include-demo` — so #135673 can't bite there
# regardless of demo reachability: every file is its own invocation. The
# integration_test/demo/* live files self-skip (skipIfUnreachable, see
# integration_test/support/demo_harness.dart) when demo.invoiceninja.com is
# unreachable, and otherwise run + write to the shared demo account on each
# manual dispatch.
#
# WARNING: integration tests take over the foreground app — same rule as
# CLAUDE.md § Integration tests. This is a deliberate, manual escape hatch
# for local verification; never run it during a focused dev session. The
# demo files also write to the live demo server, so they are SKIPPED unless
# --include-demo (or explicit file args) select them.
#
# Usage:
#   bash tools/run_integration_local.sh                 # mocked suite only
#   bash tools/run_integration_local.sh --include-demo  # also the live demo/*
#   bash tools/run_integration_local.sh <file> [<file>] # exactly these files
#   bash tools/run_integration_local.sh --device web-server  # web instead of macOS
#   INTEGRATION_FILE_TIMEOUT=1500 bash tools/run_integration_local.sh ...
#
# --device defaults to `macos` (preserves the original behavior + the
# #135673 caveat below). Pass `--device web-server` to run the mocked suite
# under headless Chrome locally — mirrors the CI `integration-web` job; needs
# chromedriver on :4444 and the `--browser-name`/`--driver` flags below.
#
# Exit code is non-zero if any file failed or timed out.

include_demo=false
device=macos
explicit_files=()
while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    --include-demo) include_demo=true ;;
    --device)
      shift
      device="${1:?--device needs a value (e.g. macos, web-server)}"
      ;;
    -h | --help)
      sed -n '4,52p' "$0"
      exit 0
      ;;
    -*)
      echo "Unknown flag: $arg (use --include-demo, --device, --help, or file paths)" >&2
      exit 2
      ;;
    *) explicit_files+=("$arg") ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Hard per-file wall-clock budget. 900 s comfortably covers the slowest
# file (demo/crud_test.dart) while bounding a wedged launch.
file_timeout="${INTEGRATION_FILE_TIMEOUT:-900}"

selected=()
if [[ ${#explicit_files[@]} -gt 0 ]]; then
  # Caller named exact files — run precisely those, demo gate not applied.
  for f in "${explicit_files[@]}"; do
    if [[ ! -f "$f" ]]; then
      echo "No such test file: $f" >&2
      exit 2
    fi
    selected+=("$f")
  done
else
  # Same discovery as CI's `integration_test/` glob, sorted for
  # deterministic order. demo/* are the live-server files; everything
  # else is the mocked suite.
  all_files=()
  while IFS= read -r f; do
    all_files+=("$f")
  done < <(find integration_test -name '*_test.dart' | sort)
  for f in "${all_files[@]}"; do
    if [[ "$f" == integration_test/demo/* ]] && [[ "$include_demo" != true ]]; then
      echo "skip (live demo, use --include-demo): $f"
      continue
    fi
    selected+=("$f")
  done
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  echo "No integration test files selected." >&2
  exit 2
fi

# Clean device state between invocations: a stale app/test process holding
# the desktop "device" is itself a #135673 trigger. Harmless if nothing
# matches.
kill_stragglers() {
  pkill -f "Invoice Ninja.app" 2>/dev/null || true
  pkill -f flutter_tester 2>/dev/null || true
}

# Run one file under a hard timeout. A background watcher SIGTERM/SIGKILLs
# the `flutter test` process group if it overruns; a flag file distinguishes
# a timeout kill from an ordinary non-zero exit. Returns 0=pass, 2=timeout,
# 1=fail.
run_one() {
  local f="$1"
  local flag
  flag="$(mktemp -t inttest_timeout.XXXXXX)"
  rm -f "$flag"

  if [[ "$device" == "macos" ]]; then
    flutter test "$f" -d macos &
  else
    # Web (and any non-desktop device): the integration_test web path goes
    # through `flutter drive` + the standard test_driver, headless Chrome.
    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target="$f" \
      -d "$device" \
      --browser-name=chrome \
      --headless &
  fi
  local pid=$!

  (
    sleep "$file_timeout"
    if kill -0 "$pid" 2>/dev/null; then
      : >"$flag"
      echo ""
      echo "‼ TIMEOUT: $f exceeded ${file_timeout}s — killing the invocation"
      kill -TERM "$pid" 2>/dev/null || true
      sleep 3
      kill -KILL "$pid" 2>/dev/null || true
    fi
  ) &
  local watcher=$!

  local rc=0
  wait "$pid" 2>/dev/null || rc=$?

  kill "$watcher" 2>/dev/null || true
  wait "$watcher" 2>/dev/null || true

  if [[ -f "$flag" ]]; then
    rm -f "$flag"
    return 2
  fi
  rm -f "$flag"
  return "$rc"
}

declare -a results=()
overall=0
for f in "${selected[@]}"; do
  kill_stragglers
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "▶ $f  on -d ${device}   (budget ${file_timeout}s)"
  echo "════════════════════════════════════════════════════════════════"
  rc=0
  run_one "$f" || rc=$?
  case "$rc" in
    0) results+=("PASS     $f") ;;
    2)
      results+=("TIMEOUT  $f")
      overall=1
      ;;
    *)
      results+=("FAIL     $f")
      overall=1
      ;;
  esac
  kill_stragglers
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Integration summary (one invocation per file — #135673 workaround)"
echo "════════════════════════════════════════════════════════════════"
for r in "${results[@]}"; do
  echo "  $r"
done

exit "$overall"
