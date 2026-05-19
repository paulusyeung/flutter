#!/usr/bin/env bash
set -euo pipefail

# Run the integration suite locally, ONE FILE PER `flutter test` INVOCATION.
#
# Why: `flutter test integration_test/ -d macos` (the CI command) cannot run
# multiple integration files on desktop — flutter/flutter#135673. The tool
# reuses a debug-connection stream that breaks on the second app launch, so
# only the FIRST file gets a working app; every later file dies with
# "Error waiting for a debug connection: The log reader stopped unexpectedly,
# or never started." → "Unable to start the app on the device." Running each
# file in its own invocation is the upstream-recommended workaround.
#
# CI is green despite the same command because its runner can't reach
# demo.invoiceninja.com, so the integration_test/demo/* live files self-skip
# (skipIfUnreachable, see integration_test/support/demo_harness.dart) and only
# app_smoke_test.dart launches the app once — within #135673's one-launch
# limit. Locally the demo server IS reachable, so it bites.
#
# WARNING: integration tests take over the foreground app — same rule as
# CLAUDE.md § Integration tests. This is a deliberate, manual escape hatch for
# local verification; never run it during a focused dev session. The demo
# files also write to the live demo server, so they are SKIPPED by default.
#
# Usage:
#   bash tools/run_integration_local.sh                # mocked suite only
#   bash tools/run_integration_local.sh --include-demo # also the live demo/*
#
# Exit code is non-zero if any file failed.

include_demo=false
for arg in "$@"; do
  case "$arg" in
    --include-demo) include_demo=true ;;
    -h | --help)
      sed -n '3,31p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg (use --include-demo or --help)" >&2
      exit 2
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Same discovery as CI's `integration_test/` glob, sorted for deterministic
# order. demo/* are the live-server files; everything else is the mocked suite.
all_files=()
while IFS= read -r f; do
  all_files+=("$f")
done < <(find integration_test -name '*_test.dart' | sort)

selected=()
for f in "${all_files[@]}"; do
  if [[ "$f" == integration_test/demo/* ]] && [[ "$include_demo" != true ]]; then
    echo "skip (live demo, use --include-demo): $f"
    continue
  fi
  selected+=("$f")
done

if [[ ${#selected[@]} -eq 0 ]]; then
  echo "No integration test files selected." >&2
  exit 2
fi

# Clean device state between invocations: a stale app/test process holding the
# desktop "device" is itself a #135673 trigger. Harmless if nothing matches.
kill_stragglers() {
  pkill -f "Invoice Ninja.app" 2>/dev/null || true
  pkill -f flutter_tester 2>/dev/null || true
}

declare -a results=()
overall=0
for f in "${selected[@]}"; do
  kill_stragglers
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "▶ flutter test $f -d macos"
  echo "════════════════════════════════════════════════════════════════"
  if flutter test "$f" -d macos; then
    results+=("PASS  $f")
  else
    results+=("FAIL  $f")
    overall=1
  fi
done
kill_stragglers

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Integration summary (one invocation per file — #135673 workaround)"
echo "════════════════════════════════════════════════════════════════"
for r in "${results[@]}"; do
  echo "  $r"
done

exit "$overall"
