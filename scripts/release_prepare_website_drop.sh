#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Wispr Clone Gemini"
UPDATES_DIR="$ROOT_DIR/release/updates"

APP_VERSION="${APP_VERSION:-$(git describe --tags --always 2>/dev/null | sed 's/^v//')}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"

mkdir -p "$UPDATES_DIR"

echo "Building signed app + DMG… version=$APP_VERSION build=$APP_BUILD_NUMBER"
export APP_VERSION APP_BUILD_NUMBER
/bin/zsh "$ROOT_DIR/scripts/build_app_bundle.sh"
/bin/zsh "$ROOT_DIR/scripts/build_dmg_pretty.sh"

DMG_SRC="$ROOT_DIR/dist/${APP_NAME}.dmg"
DMG_DEST="$UPDATES_DIR/${APP_NAME}-${APP_VERSION}.dmg"
cp -f "$DMG_SRC" "$DMG_DEST"

echo "Generating Sparkle appcast (requires you ran scripts/sparkle_generate_keys.sh once)…"
/bin/zsh "$ROOT_DIR/scripts/sparkle_generate_appcast.sh" "$UPDATES_DIR"

echo ""
echo "Website drop ready in:"
echo "  $UPDATES_DIR"
echo "Upload this folder to your downloads host (S3/R2/Cloudflare Pages)."

