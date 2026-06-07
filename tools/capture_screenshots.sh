#!/usr/bin/env bash
set -euo pipefail

# Capture the README marketing screenshots.
#
# Boots the real app on web against demo.invoiceninja.com (the same baked-token
# bootstrap the public web demo uses) and writes one PNG per marketing screen
# into samples/screenshots/. Driven by integration_test/screenshots_test.dart +
# test_driver/screenshots_driver.dart (whose onScreenshot handler writes the
# bytes).
#
# WHY WEB: the integration_test plugin only implements takeScreenshot for
# Android/iOS/web — there is no macOS plugin, so `-d macos` throws
# MissingPluginException. Web is the only desktop-class, permission-free target.
#
# PREREQUISITE: a running chromedriver on :4444 (same as
# `run_integration_local.sh --device web-server`):
#     chromedriver --port=4444
#
# Usage:
#   tools/capture_screenshots.sh [token]
#
#   token   Demo API token. Defaults to $IN_DEMO_API_TOKEN, else the public
#           demo token "TOKEN" (the same one tools/build_demo_web.sh bakes in).
#
# This is a local, on-demand task — it is NOT run by CI or the integration
# suite (the test self-skips unless IN_DEMO_API_TOKEN is defined, and
# run_integration_local.sh excludes it).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

demo_token="${IN_DEMO_API_TOKEN:-${1:-TOKEN}}"
demo_url="${IN_DEMO_API_URL:-https://demo.invoiceninja.com}"

if ! curl -s -m 3 -o /dev/null "http://localhost:4444/status"; then
  echo "!! chromedriver is not reachable on :4444." >&2
  echo "   Start it in another terminal first:  chromedriver --port=4444" >&2
  exit 1
fi

mkdir -p samples/screenshots

echo "==> flutter drive (web) → samples/screenshots/"
flutter drive \
  --driver=test_driver/screenshots_driver.dart \
  --target=integration_test/screenshots_test.dart \
  -d web-server \
  --browser-name=chrome \
  --browser-dimension=1600x1000 \
  --dart-define=IN_DEMO_API_TOKEN="$demo_token" \
  --dart-define=IN_DEMO_API_URL="$demo_url"

echo "==> done. Wrote:"
ls -1 samples/screenshots/
