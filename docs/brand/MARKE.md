# Marke Grimmhain (Kurzfassung)

Quellen: Design-Tafel `C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/marke/design-tafel.png` und das Projekt-Dokument "marken-blatt-grimmhain" (Markus). Das Dokument war beim Anlegen dieser Datei nicht lesbar; die Kurzfassung stützt sich auf die Tafel und die bestehenden ThemeTokens. Bei Abweichungen gilt das Marken-Blatt. Alle Texte und Assets folgen dieser Datei.

## Gefühl
Düstere Nacht, kalter Mond, Dornen und Eisen. Ernst, ruhig, bedrohlich, nie albern. Das Dorf schläft, etwas Altes erwacht. Untertitel der Tafel: "The Night Begins".

## Zeichen
- **Wortmarke** GRIMMHAIN: gotische Mondstahl-Schrift mit Dornenranken. `godot/assets/brand/wortmarke.webp`. Ersetzt `start-logo` überall (Start, Hauptmenü, Ladebild).
- **Siegel**: Wolfskopf im Dornenkranz. `godot/assets/brand/siegel.webp`. Klein über der Wortmarke im Ladebild, Grundlage des App-Symbols.
- **App-Symbol** auf nachtschwarzem rundem Grund, `godot/assets/app/app-symbol-*.png`. Bis 120 px die Klein-Fassung (Kopf größer, nur Ring, Kontrast höher), ab 144 px das Siegel unverändert.
- Wortmarke und Siegel nicht verzerren, nicht einfärben, nicht auf hellen Grund setzen.

## Farben (= ThemeTokens, `godot/app/theme/theme_tokens.gd`)
| Tafel | Token |
|---|---|
| Nachtschwarz | `BG_APP` #0b0d14 |
| Nachtblau | `NIGHT_BACKDROP` #0a1022, `BOARD_NIGHT` #0e1530 |
| Mondsilber | `MOON_SILVER` #c5cddb |
| Blutrot | `BLOOD_RED` #b3242d (nur Aktives und Hauptaktion) |
| Dorf | `TEAM_PLATE_VILLAGE`, `GLOW_VILLAGE` (kühles Mondblau) |
| Wölfe | `TEAM_PLATE_WOLVES`, `GLOW_WOLVES` (dunkles Blutrot) |
| Einzelgänger | `TEAM_PLATE_SOLO` (gedämpftes Violett) |

Keine neuen Farbwerte im Code, nur Tokens.

## Material
Eisen (dunkel, gehämmert, Sterne und Kreuz), Wurzeln und Dornen, Silber (kühl, rissig), Glut (rotes Leuchten in dunklem Gestein). Rahmen sind Dornen und Eisen, Leisten mit rotem Rubin als Mitte.

## Schrift
Gotische Wortmarke nur als Bild, nie als Fließtext. Untertitel und Zeilen in geweiteter, ruhiger Serifenlose; Fließtext in der Projektschrift der Oberfläche (gut lesbar auf dem Tablet).

## Bildstil
Düstere Ölmalerei bei Nacht: Vollmond, Fachwerkdorf, nasses Kopfsteinpflaster, einzelne warme Laternen als einziger warmer Punkt. Symbole als Reliefs aus Silber und Eisen (Haus, Wolfskopf, Kapuzengestalt). Dunkle Vignette, wo Schrift auf Bild liegt.

## Sprache: kurz und klar
Kurze Sätze, direkte Anrede, Verben vorn, keine Füllwörter, kein Fachjargon im Spieltext. Eine Anweisung pro Satz.

Beispiel Loki (aus `docs/content-drafts/GUIDE-TEXTS.md`):
- Spielleiter-Hinweis: "Nur Nacht 1: Frag, welche zwei Personen Liebende oder Rivalen werden."
- Private Information: "Du und {name} seid Liebende: Stirbt eine Person, stirbt die andere."
