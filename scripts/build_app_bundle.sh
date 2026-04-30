#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="SpeakDash"
APP_BUNDLE_ID="ai.quantsummit.speakdash"
APP_BUNDLE="$ROOT_DIR/dist/${APP_NAME}.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
BIN_NAME="SpeakDash"
APP_VERSION="${APP_VERSION:-1.0}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-1}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-https://speakdash.app/appcast.xml}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"

cp ".build/release/$BIN_NAME" "$MACOS_DIR/$BIN_NAME"
chmod +x "$MACOS_DIR/$BIN_NAME"

if [[ -d ".build/release/Sparkle.framework" ]]; then
  echo "Embedding Sparkle.framework"
  rsync -a ".build/release/Sparkle.framework" "$FRAMEWORKS_DIR/"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>speakdash</string>
  <key>CFBundleIdentifier</key>
  <string>ai.quantsummit.speakdash</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>SpeakDash</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>'"$APP_VERSION"'</string>
  <key>CFBundleVersion</key>
  <string>'"$APP_BUILD_NUMBER"'</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSMicrophoneUsageDescription</key>
  <string>Needed for dictation audio capture.</string>
  <key>SUFeedURL</key>
  <string>'"$SPARKLE_FEED_URL"'</string>
  <key>SUPublicEDKey</key>
  <string>'"$SPARKLE_PUBLIC_ED_KEY"'</string>
  <key>SUEnableAutomaticChecks</key>
  <true/>
</dict>
</plist>
PLIST

SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY="$(security find-identity -v -p codesigning 2>&1 | sed -n 's/.*"\(Apple Development:[^"]*\)".*/\1/p' | head -n 1)"
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  echo "Signing app with identity: $SIGNING_IDENTITY"
  if [[ "$SIGNING_IDENTITY" == Developer\ ID\ Application:* ]]; then
    codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" --identifier "$APP_BUNDLE_ID" "$APP_BUNDLE"
  else
    codesign --force --deep --sign "$SIGNING_IDENTITY" --identifier "$APP_BUNDLE_ID" "$APP_BUNDLE"
  fi
else
  echo "No Apple Development signing identity found, falling back to ad-hoc signing."
  codesign --force --deep --sign - --identifier "$APP_BUNDLE_ID" "$APP_BUNDLE"
fi

echo "Built app bundle: $APP_BUNDLE"
