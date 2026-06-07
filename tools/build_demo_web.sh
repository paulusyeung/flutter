#!/usr/bin/env bash
set -euo pipefail

# Build (and optionally deploy) the pre-authenticated demo web app.
#
# Produces the Flutter WASM web build, based at /admin/ for GitHub Pages and
# pre-authenticated against demo.invoiceninja.com via the public system token
# `TOKEN` (see docs/probing-the-demo-api.md). On a fresh browser the build
# boots straight to the dashboard instead of /login — see `Env.demoApiToken`
# and the bootstrap hook in lib/main.dart.
#
# Usage:
#   tools/build_demo_web.sh [deploy_dir]
#
#   deploy_dir   Directory to rsync build/web/ into. Defaults to the sibling
#                checkout ../hillelcoren.github.io/admin. Pass "-" to build
#                only and skip the deploy.
#
# After deploying, commit & push the deploy repo to publish (GitHub Pages).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

deploy_dir="${1:-$repo_root/../hillelcoren.github.io/admin}"

echo "==> flutter build web --wasm (demo, base-href /admin/)"
# --no-web-resources-cdn bundles the CanvasKit/skwasm engine into build/web/
# (served from /admin/) instead of fetching it from www.gstatic.com at runtime,
# so the demo loads entirely from our own origin.
flutter build web --wasm --release \
  --no-web-resources-cdn \
  --base-href /admin/ \
  --dart-define=IN_DEMO_API_TOKEN=TOKEN

if [[ "$deploy_dir" == "-" ]]; then
  echo "==> build complete — build/web/ (deploy skipped)"
  exit 0
fi

if [[ ! -d "$deploy_dir" ]]; then
  echo "!! deploy dir not found: $deploy_dir" >&2
  echo "   build is in build/web/ — copy it manually or pass a valid path." >&2
  exit 1
fi

echo "==> deploying to $deploy_dir"
rsync -a --delete "$repo_root/build/web/" "$deploy_dir/"

# GitHub Pages runs Jekyll, which drops files whose names start with "_" —
# including assets/i18n/_app_pending.json (app-local strings). A .nojekyll at
# the Pages repo root disables Jekyll. Warn if it is missing.
pages_root="$(cd "$deploy_dir/.." && pwd)"
if [[ ! -f "$pages_root/.nojekyll" ]]; then
  echo "!! WARNING: $pages_root/.nojekyll is missing." >&2
  echo "   GitHub Pages will strip _app_pending.json and untranslated keys" >&2
  echo "   will render raw. Create an empty .nojekyll at that repo root." >&2
fi

echo "==> done. To publish, commit & push the deploy repo:"
echo "     git -C \"$pages_root\" add ."
echo "     git -C \"$pages_root\" commit -m 'Update admin demo build'"
echo "     git -C \"$pages_root\" push"
