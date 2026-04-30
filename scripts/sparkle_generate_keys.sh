#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ACCOUNT="${SPARKLE_KEYCHAIN_ACCOUNT:-ed25519}"
TOOL="$ROOT_DIR/.build/artifacts/sparkle/Sparkle/bin/generate_keys"

if [[ ! -x "$TOOL" ]]; then
  echo "Sparkle tools not found. Build once first:"
  echo "  cd \"$ROOT_DIR\" && zsh scripts/build_app_bundle.sh"
  exit 2
fi

echo "Generating/reading Sparkle Ed25519 keypair in Keychain (account=$ACCOUNT)…"
echo "Public key (add to SUPublicEDKey):"
"$TOOL" --account "$ACCOUNT"

