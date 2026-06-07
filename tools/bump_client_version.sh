#!/usr/bin/env bash
set -euo pipefail

# Bump the client version constant (AppVersion.kClientVersion) in
# lib/app/version.dart.
#
# kClientVersion is the version this client claims to the server: sent as the
# X-CLIENT-VERSION header on every request, drives the server's
# x-minimum-client-version handshake, tags Sentry releases, and supplies the
# trailing build digit in the About dialog's combined version string
# (v<server>-<platform><build>). Bump it on every release.
#
# Does NOT touch pubspec.yaml's version (a separate placeholder) or
# kMinServerVersion (bumped only when depending on a server change).
#
# Usage:
#   tools/bump_client_version.sh <version>     # e.g. 5.1.1
#   tools/bump_client_version.sh               # prints the current version

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

file="lib/app/version.dart"

current="$(sed -n "s/.*kClientVersion = '\([^']*\)'.*/\1/p" "$file")"
if [[ -z "$current" ]]; then
  echo "!! could not find kClientVersion in $file" >&2
  exit 1
fi

new_version="${1:-}"
if [[ -z "$new_version" ]]; then
  echo "current kClientVersion: $current"
  echo "usage: tools/bump_client_version.sh <version>   (e.g. 5.1.1)"
  exit 0
fi

if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "!! '$new_version' is not MAJOR.MINOR.PATCH (e.g. 5.1.1)" >&2
  exit 1
fi

if [[ "$new_version" == "$current" ]]; then
  echo "==> kClientVersion already $current — nothing to do"
  exit 0
fi

perl -i -pe "s/(kClientVersion = ')[^']*(')/\${1}${new_version}\${2}/" "$file"

updated="$(sed -n "s/.*kClientVersion = '\([^']*\)'.*/\1/p" "$file")"
if [[ "$updated" != "$new_version" ]]; then
  echo "!! update failed — $file still reads '$updated'" >&2
  exit 1
fi

echo "==> kClientVersion: $current -> $new_version"
echo "    next: flutter analyze $file && flutter test test/app/version_test.dart"
