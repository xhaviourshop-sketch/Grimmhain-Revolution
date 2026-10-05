---
name: grimmhain-deploy
description: Use to export the Godot web build and deploy it to the Vercel project grimmhain-ipad-test (production). Only on explicit order.
---

# Web-Export und Deploy (grimmhain-ipad-test)
Voraussetzung: Auftrag zum Deploy, Stand ist gemergt oder ausdrücklich freigegeben. Nie aus der Cloud.

1. Export (Windows): `"<GODOT_CONSOLE_EXE>" --headless --path godot --export-release "Web"`. Ziel laut `godot/export_presets.cfg`: `C:/Users/Marku/Downloads/Grimmhain-iPad-Web/index.html`. Godot-Konsolen-EXE: `C:/Users/Marku/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.
2. Staging-Ordner im Scratchpad, nicht im Repo: `index*` aus dem Exportordner kopieren (keine .bat/.png-Prüfbilder), `vercel.json` per `node -e` mit `JSON.stringify` schreiben (Heredoc verschluckt Backslashes): Header `Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp` für `/(.*)`, `Content-Type: application/wasm` für `/(.*)[.]wasm`.
3. `vercel link --yes --project grimmhain-ipad-test`, dann `vercel deploy --prod --yes` (Konto xhaviourshop-5645). Alias `https://grimmhain-ipad-test.vercel.app`.
4. Prüfen: `curl -sI https://grimmhain-ipad-test.vercel.app/index.pck` zeigt 200, gleiche Content-Length wie lokal, COOP/COEP-Header.
5. In `PROGRESS.md` eine Zeile: Deploy, `index.pck`-Größe. Nicht geprüft nennen: Safari/iPad.
