# P2-Mockup (Wiederverwendung für P3)

**Keine Laufzeitassets, nicht in `godot/`.** Ergebnis der P2-Ausführung (2026-10-01): Zuschnitte, freigestellte Symbole, reparierte Teile und das Mockup-Skript V3. Alle Bilder sind Entwicklungsmaterial ohne Veröffentlichungsfreigabe (Herkunft: `../ORIGIN-NOTES-NIGHT-BOARD.md`, Abschnitt 5).

| Pfad | Inhalt |
|---|---|
| `faces/face-01..24.png` | 24 eindeutige Platzporträts (256 px). Quelle: A (6), B (4, ohne zwei Duplikate), C (8), D (6, zwei als zu ähnlich aussortiert) |
| `badges/badge-01..06.png` | Statusabzeichen, freigestellt, 192 px: 1 Schutz, 2 Gift, 3 Markiert, 4 Stumm, 5 Tot, 6 Sonder |
| `emblems/emblem-NN.png` | Rollensymbole aus dem Probeblatt, freigestellt, 256 px. Nummer 6 (Wolf mit Zipfelmütze) fehlt absichtlich: neu erzeugen |
| `night-icons-circle/*.webp` | alle 72 Nacht-Rollenbilder als Kreisausschnitt ohne Kartenecken (128 px), Übergangslösung bis zum Emblemsatz |
| `parts/` | reparierte Teile: `tab-protocol.png`, `tab-options.png` (beide textfrei, Zahnrad per Skript gezeichnet), `slot-active/done/inactive.png` (ohne Säume, Nummernsockel dunkel), `action-frame-night.png` (Platte transparent) |
| `mockup3.gd` | Mockup V3 (Leiste voll und eingeklappt, 24 Gesichter, Abzeichen an vier Plätzen, Emblem-Leiste) |
| `tools/` | Python-Skripte: `crop_faces.py` (Gesichtsausschnitte), `p2_assets.py` (Auswahl, Kontaktblatt, Magenta-Freistellung), `p2_repair.py` (Slots, Rahmen, Laschen) |

Die Knöpfe „Nächster Schritt“ und „Rückgängig“ kommen unverändert aus `../p1-mockup/echt2/`.

## Ausführen

```text
godot --path godot --rendering-driver opengl3 --audio-driver Dummy -s ../docs/assets/p2-mockup/mockup3.gd -- [--only=V3-A-leiste-voll] [--sizes=1024x768]
```

**Maschinenabhängig:** `WK`, `BG_G1` und `OUT` in `mockup3.gd` sowie die Pfade am Anfang der Python-Skripte zeigen auf Ordner dieses Rechners (`C:/Users/Marku/...`).

## Bekannte Grenzen

- Auswahl der Gesichter: Kontaktblatt im Übergabeordner `mockup-v3/P2-kontaktblatt-gesichter-24.png`. Fünf Paare bleiben grenzwertig ähnlich (siehe `../P2-GRAFIKLISTE.md`).
- Der Zahnrad-Ersatz in `tab-options.png` ist eine einfache gezeichnete Form, kein KI-Bild.
- „Rückgängig“ überlappt bei 1024 × 768 die Tippfläche des Platzes 11 knapp (Layout aus V2, in P3 zu lösen).
