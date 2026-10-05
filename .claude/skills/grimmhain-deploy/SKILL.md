---
name: grimmhain-deploy
description: Use to export the Godot web build and deploy it to the Vercel project grimmhain-ipad-test (production). Only on explicit order.
---

# Web-Export und Deploy (grimmhain-ipad-test)
Voraussetzung: Auftrag zum Deploy, Stand ist committet und gemergt (der Hash auf dem Startbildschirm ist der Commit, `*` hinter dem Hash heißt uncommittete Änderungen). Nie aus der Cloud.

1. Export: `node tools/export-web.js` (schreibt Datum und Commit-Hash als `build_info.json` für den Startbildschirm, exportiert nach `C:/Users/Marku/Downloads/Grimmhain-iPad-Web/`, setzt die Build-Kennung in `index.html` und `version.json`, patcht den Service Worker auf sofortige Übernahme, kopiert `godot/web/vercel.json`). Nie von Hand eintragen.
2. Staging-Ordner im Scratchpad, nicht im Repo: `index*`, `version.json` und `vercel.json` aus dem Exportordner kopieren (keine .bat/.png-Prüfbilder).
3. `vercel link --yes --project grimmhain-ipad-test`, dann `vercel deploy --prod --yes` (Konto xhaviourshop-5645). Alias `https://grimmhain-ipad-test.vercel.app`.
4. Prüfen: `curl -sI https://grimmhain-ipad-test.vercel.app/index.pck` zeigt 200 und gleiche Content-Length wie lokal; `curl -s .../version.json` nennt die neue Kennung; `index.html`, `index.service.worker.js` und `index.manifest.json` kommen mit `Cache-Control: no-cache`.
5. Die App lädt bei veralteter Kennung selbständig neu (Service Worker und Caches werden verworfen). Auf einem iPad, das noch den alten Stand ohne diese Prüfung hat, einmal die App ganz schließen und zweimal öffnen.
6. In `PROGRESS.md` eine Zeile: Deploy, Hash, `index.pck`-Größe. Nicht geprüft nennen: Safari/iPad.
