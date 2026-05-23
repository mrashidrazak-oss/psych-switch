#!/usr/bin/env bash
#
# distribute-beta.sh — one-command Firebase App Distribution drop.
#
# Builds a signed release APK and uploads it to the closed-beta tester
# group on Firebase App Distribution. Testers receive an email with an
# install link; existing testers see a "new build available" notification
# in the App Tester app.
#
# Usage:
#   bash scripts/distribute-beta.sh "Release notes text"
#   bash scripts/distribute-beta.sh "Release notes" --skip-build  # use existing APK
#   bash scripts/distribute-beta.sh "Release notes" --group hima  # different tester group
#
# Defaults:
#   - Builds a fresh release APK (skip with --skip-build)
#   - Distributes to the `closed-beta` tester group (override with --group)
#   - Reads notes from $1 (defaults to "Closed beta build" if absent)
#
# Prereqs (one-time):
#   1. Firebase CLI authed:   `firebase login`
#   2. Signing keys in place: android/key.properties + ~/psychswitch-upload.jks
#   3. Tester group created in Firebase Console → App Distribution →
#      Testers & Groups → New group → alias `closed-beta`
#
# This script is checked in; it contains no secrets. The keystore +
# key.properties stay gitignored.

set -uo pipefail
# Don't `set -e` — we want to inspect firebase's exit code so we can
# show a friendly hint when the group doesn't exist yet (the first-
# run gotcha — see the "404 → create group" handling below).

# ── Config ──────────────────────────────────────────────────────────
APP_ID="1:166044970078:android:d3c3d570489f8940c058cf"
PROJECT_ID="psychswi"
DEFAULT_GROUP="closed-beta"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# ── Arg parsing ─────────────────────────────────────────────────────
NOTES="${1:-Closed beta build}"
SKIP_BUILD=false
GROUP="$DEFAULT_GROUP"

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=true; shift ;;
    --group) GROUP="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Run from the flutter_app/ directory so relative paths resolve.
cd "$(dirname "$0")/.."

# ── Build ──────────────────────────────────────────────────────────
if [[ "$SKIP_BUILD" == "false" ]]; then
  echo "▶ Building signed release APK…"
  flutter build apk --release
else
  echo "▶ --skip-build set; using existing $APK_PATH"
  if [[ ! -f "$APK_PATH" ]]; then
    echo "✗ No APK at $APK_PATH — drop --skip-build to build one." >&2
    exit 1
  fi
fi

# ── Distribute ──────────────────────────────────────────────────────
echo "▶ Uploading to Firebase App Distribution → group: $GROUP"
DIST_LOG=$(mktemp)
firebase appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --project "$PROJECT_ID" \
  --release-notes "$NOTES" \
  --groups "$GROUP" 2>&1 | tee "$DIST_LOG"
DIST_EXIT=${PIPESTATUS[0]}

echo ""
if [[ "$DIST_EXIT" -eq 0 ]]; then
  echo "✔ Build uploaded + distributed to group: $GROUP"
elif grep -q "Requested entity was not found" "$DIST_LOG"; then
  # Upload itself succeeded — only the group-distribute step 404'd
  # because the group doesn't exist yet. Friendly hint, exit 0.
  cat <<EOF

⚠  Build uploaded to App Distribution, but the group "$GROUP" doesn't
   exist yet — that's why the final step 404'd. The release IS live in
   the console.

   One-time fix (~2 min):
     1. Open https://console.firebase.google.com/project/$PROJECT_ID/appdistribution
     2. Testers & Groups → Add group → alias: $GROUP
     3. Add tester emails to the group
     4. Re-run this script with --skip-build to push to the new group:
          bash scripts/distribute-beta.sh "Notes" --skip-build

✔ Build is safely uploaded — no need to re-build.
EOF
  exit 0
else
  echo "✗ Distribution failed — see log above."
  rm -f "$DIST_LOG"
  exit "$DIST_EXIT"
fi
rm -f "$DIST_LOG"

echo "  Console: https://console.firebase.google.com/project/$PROJECT_ID/appdistribution"
