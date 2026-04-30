#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="SpeakDash"
APP_BUNDLE="$ROOT_DIR/dist/${APP_NAME}.app"
DMG_PATH="$ROOT_DIR/dist/${APP_NAME}.dmg"

cd "$ROOT_DIR"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "App bundle not found at: $APP_BUNDLE"
  echo "Building app bundle first..."
  /bin/zsh "$ROOT_DIR/scripts/build_app_bundle.sh"
fi

RW_DMG="$(mktemp -u)/${APP_NAME}.rw.dmg"
STAGING_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$STAGING_DIR" >/dev/null 2>&1 || true
  rm -f "$RW_DMG" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s "/Applications" "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
rm -f "$RW_DMG"

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDRW "$RW_DMG" >/dev/null
MOUNT_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")"
DEVICE="$(echo "$MOUNT_OUTPUT" | awk 'NR==1{print $1}')"
MOUNT_POINT="$(echo "$MOUNT_OUTPUT" | awk 'END{print $NF}')"

osascript <<EOF >/dev/null
tell application "Finder"
  tell disk "${APP_NAME}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 200, 720, 520}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 96
    set text size of viewOptions to 12
    set position of item "${APP_NAME}.app" of container window to {180, 170}
    set position of item "Applications" of container window to {520, 170}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
EOF

sync
hdiutil detach "$DEVICE" >/dev/null
hdiutil convert "$RW_DMG" -format UDZO -ov -o "$DMG_PATH" >/dev/null

echo "Built DMG: $DMG_PATH"

