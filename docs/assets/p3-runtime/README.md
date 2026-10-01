# P3-Laufzeitassets (Nachtbrett)

Die Bilder des Nachtbretts liegen als Laufzeitassets unter `godot/assets/night/`. Sie sind **intern freigegeben** (Registerstatus `intern-freigegeben`, Entscheidung vom 01.10.2026 in `DECISIONS.md`): Markus bestätigt die Eigenerstellung per KI, die interne Nutzung ist erlaubt, **eine Veröffentlichung bleibt gesperrt**. `node tools/check-asset-register.js --release` meldet jede dieser Dateien als Befund und gehört zur Releasecheckliste.

| Ordner | Inhalt | Quelle |
|---|---|---|
| `bg/` | Dorfplatz bei Nacht (G1), WebP | ChatGPT-Kandidat G1 |
| `portraits/` | 24 neutrale Platzporträts, 256 px, WebP | Blätter A bis D (`../p2-mockup/faces/`) |
| `frames/` | Platzrahmen und Ringe (aktiv, gewählt, Ziel, tot, Schutz, Markiert, Gift, Stumm), 256 px | Grimmhain Assets |
| `badges/` | Zustandsabzeichen, 96 px, nach Art benannt | Blatt P2-3 |
| `emblems/` | Rollensymbole für die sieben Rollen der Nachtleiste mit Emblem, 128 px, nach Rollen-ID benannt | Blatt P2-4 |
| `role-circle/` | Kreisbild für alle 72 Rollen (Übergang), 128 px | `../p2-mockup/night-icons-circle/` |
| `role-art/` | vorläufiges Rollenbild für alle 72 Rollen, 512 px | `production-pilot/role-art/portraits-512` (laut `PILOT-STATUS.md` vorläufig) |
| `ui/` | Laschen, Slots, Rollenkartenrahmen, Knöpfe, Platten, Pfeile | reparierte Teile, `../p2-mockup/parts/` |

Neu erzeugen: `python docs/assets/p3-runtime/build_assets.py` (maschinenabhängige Pfade am Dateianfang). Rahmen, die als 9-Slice oder als ganze Fläche gestreckt werden, liegen in Anzeigegröße, weil Godot Ränder in Bildpunkten zeichnet.
Danach `godot --headless --path godot --import` (erzeugt die `.import`-Dateien, die mit eingecheckt werden) und die Registerzeilen in `docs/masterplan/asset-register.csv` aktualisieren (Größe und SHA-256 ändern sich).
