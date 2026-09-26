#!/usr/bin/env bash
# Führt alle headless Tests des Godot-Projekts aus.
# Nutzung (aus dem Repo-Wurzelordner):  godot/tests/run_all.sh
# GODOT_BIN überschreibt den Pfad zur Godot-Binärdatei; sonst wird die gepinnte
# Version über godot/tools/install_godot.sh bereitgestellt.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$("$PROJECT_DIR/tools/install_godot.sh")}"

# 1) Import: baut den Klassen-Cache (class_name) ohne Fenster auf.
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1

# 2) Tests. Skriptfehler (auch Parse-Fehler und Laufzeitfehler) machen den Lauf rot,
#    selbst wenn der Runner sie nicht abfangen kann.
LOG="$(mktemp)"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" -s res://tests/run_tests.gd -- "$@" 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" "$LOG"; then
  echo "Skriptfehler im Testlauf gefunden." >&2
  STATUS=1
fi
rm -f "$LOG"
exit "$STATUS"
