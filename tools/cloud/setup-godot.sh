#!/usr/bin/env bash
# Installs the pinned Godot Linux build for cloud sessions and imports the project.
set -euo pipefail

VERSION="4.7.2-stable"
ZIP="Godot_v${VERSION}_linux.x86_64.zip"
SHA512="9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/${ZIP}"
DEST="$HOME/.local/godot"
BIN_DIR="$HOME/.local/bin"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ "$(tr -d '\r\n' < "$ROOT/godot/tools/godot-version.txt")" != "$VERSION" ]; then
  echo "setup-godot: godot-version.txt differs from $VERSION, update this script" >&2
  exit 1
fi

if [ ! -x "$DEST/Godot_v${VERSION}_linux.x86_64" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "$URL" -o "$tmp/$ZIP"
  echo "$SHA512  $tmp/$ZIP" | sha512sum -c - >/dev/null
  mkdir -p "$DEST"
  unzip -oq "$tmp/$ZIP" -d "$DEST"
  chmod +x "$DEST/Godot_v${VERSION}_linux.x86_64"
fi

mkdir -p "$BIN_DIR"
ln -sf "$DEST/Godot_v${VERSION}_linux.x86_64" "$BIN_DIR/godot"
export PATH="$BIN_DIR:$PATH"

# Make `godot` available to later Bash calls in this session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

cd "$ROOT/godot"
godot --headless --import >/dev/null 2>&1 || true
echo "setup-godot: $(godot --version)"
