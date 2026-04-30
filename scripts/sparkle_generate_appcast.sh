#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-ed25519}"
UPDATES_DIR="${1:-$ROOT_DIR/release/updates}"
TOOL="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_appcast"

if [[ ! -x "$TOOL" ]]; then
  echo "Sparkle tools not found. Build once first:"
  echo "  cd \"$ROOT_DIR\" && zsh scripts/build_app_bundle.sh"
  exit 2
fi

mkdir -p "$UPDATES_DIR"
echo "Generating appcast in: $UPDATES_DIR"
"$TOOL" --account "$ACCOUNT" "$UPDATES_DIR"
echo "Done. Upload the whole folder (dmg/zip + appcast.xml + deltas)."

