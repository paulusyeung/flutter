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
# Also bumps pubspec.yaml's version: keeps MAJOR.MINOR.PATCH in sync with
# kClientVersion and increments the build number (+N) by one, so the native
# build version (CFBundleVersion / versionCode, derived from pubspec) advances
# on every release.
#
# Does NOT touch kMinServerVersion (bumped only when depending on a server change).
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

# --- pubspec.yaml: keep MAJOR.MINOR.PATCH in sync, increment the build (+N) ---
pubspec="pubspec.yaml"

pubspec_line="$(sed -n 's/^version:[[:space:]]*\(.*\)$/\1/p' "$pubspec")"
if [[ -z "$pubspec_line" ]]; then
  echo "!! could not find a top-level 'version:' in $pubspec" >&2
  exit 1
fi

pubspec_build="${pubspec_line#*+}"           # 4   (or whole string if no +BUILD)
if [[ "$pubspec_build" == "$pubspec_line" ]]; then
  pubspec_build=0                            # no +BUILD present -> start from 0
fi
if [[ ! "$pubspec_build" =~ ^[0-9]+$ ]]; then
  echo "!! unexpected build '$pubspec_build' in $pubspec (want MAJOR.MINOR.PATCH+BUILD)" >&2
  exit 1
fi

new_build=$(( pubspec_build + 1 ))
new_pubspec="${new_version}+${new_build}"

perl -i -pe "s/^version:.*/version: ${new_pubspec}/" "$pubspec"

pubspec_updated="$(sed -n 's/^version:[[:space:]]*\(.*\)$/\1/p' "$pubspec")"
if [[ "$pubspec_updated" != "$new_pubspec" ]]; then
  echo "!! pubspec update failed — $pubspec still reads '$pubspec_updated'" >&2
  exit 1
fi

echo "==> kClientVersion: $current -> $new_version"
echo "==> pubspec version: $pubspec_line -> $new_pubspec"
echo "    next: flutter analyze $file && flutter test test/app/version_test.dart"
