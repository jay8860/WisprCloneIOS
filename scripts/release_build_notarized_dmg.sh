#!/bin/zsh
set -euo pipefail

# This script is intended for production releases.
# It requires a Developer ID Application cert in your Keychain and Apple notarization credentials.
#
# Required env vars:
# - DEVELOPER_ID_APP: e.g. "Developer ID Application: Your Company (TEAMID)"
# - APPLE_ID: Apple ID email
# - APPLE_TEAM_ID: Team ID
# - APPLE_APP_SPECIFIC_PASSWORD: app-specific password
#
# Optional:
# - APP_VERSION, APP_BUILD_NUMBER

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Wispr Clone Gemini"
APP_BUNDLE="$ROOT_DIR/dist/${APP_NAME}.app"
DMG_PATH="$ROOT_DIR/dist/${APP_NAME}.dmg"

DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_SPECIFIC_PASSWORD="${APPLE_APP_SPECIFIC_PASSWORD:-}"

if [[ -z "$DEVELOPER_ID_APP" ]]; then
  echo "Missing DEVELOPER_ID_APP"
  exit 2
fi
if [[ -z "$APPLE_ID" || -z "$APPLE_TEAM_ID" || -z "$APPLE_APP_SPECIFIC_PASSWORD" ]]; then
  echo "Missing notarization env vars: APPLE_ID / APPLE_TEAM_ID / APPLE_APP_SPECIFIC_PASSWORD"
  exit 2
fi

cd "$ROOT_DIR"

echo "Building app bundle (release)…"
SIGNING_IDENTITY="$DEVELOPER_ID_APP" /bin/zsh "$ROOT_DIR/scripts/build_app_bundle.sh"

echo "Creating DMG…"
/bin/zsh "$ROOT_DIR/scripts/build_dmg.sh"

echo "Notarizing DMG…"
SUBMISSION_ID="$(xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --wait \
  --output-format json | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin).get(\"id\",\"\"))')"

if [[ -z "$SUBMISSION_ID" ]]; then
  echo "Notarization submission failed."
  exit 3
fi

echo "Stapling notarization ticket…"
xcrun stapler staple "$DMG_PATH"

echo "Notarized DMG ready: $DMG_PATH"

