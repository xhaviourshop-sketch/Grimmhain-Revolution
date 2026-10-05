# Cloud-Sitzungen (aus CLAUDE.md ausgelagert)

- Godot kommt aus `tools/cloud/setup-godot.sh` (SessionStart-Hook in `.claude/settings.json`, nur bei `CLAUDE_CODE_REMOTE`): Godot 4.7.2 headless mit Prüfsumme nach `~/.local/godot`, Befehl `godot`, einmal `--import`. Fehlt `godot`, das Skript manuell starten.
- Testregeln wie in CLAUDE.md, Linux-Befehle aus `godot/README.md`.
- Kein Web-Export und kein Vercel-Deploy aus der Cloud.
- Screenshots headless nach `docs/screenshots/cloud/`.
- Immer eigener Branch, nie direkt auf `main`.
