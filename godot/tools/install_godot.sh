#!/usr/bin/env bash
# Lädt die gepinnte Godot-Version (Linux x86_64, offizieller Build) herunter,
# prüft die SHA-512-Prüfsumme und legt die Binärdatei nach $GODOT_HOME ab.
# Nutzung: godot/tools/install_godot.sh   → gibt den Pfad der Binärdatei aus
set -euo pipefail

VERSION="$(tr -d '[:space:]' < "$(dirname "$0")/godot-version.txt")"
ASSET="Godot_v${VERSION}_linux.x86_64"
SHA512="9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"
GODOT_HOME="${GODOT_HOME:-$HOME/.local/godot}"
BIN="$GODOT_HOME/$ASSET"

if [ ! -x "$BIN" ]; then
  mkdir -p "$GODOT_HOME"
  curl -fsSL -o "$GODOT_HOME/$ASSET.zip" \
    "https://github.com/godotengine/godot/releases/download/${VERSION}/${ASSET}.zip"
  echo "${SHA512}  $GODOT_HOME/$ASSET.zip" | sha512sum -c - >&2
  unzip -o -q "$GODOT_HOME/$ASSET.zip" -d "$GODOT_HOME"
  rm "$GODOT_HOME/$ASSET.zip"
  chmod +x "$BIN"
fi
echo "$BIN"
