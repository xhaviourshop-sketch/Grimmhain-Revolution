# Herkunftsnotizen: Nachtbrett-Mockups (P1)

**Stand:** 2026-10-01 · **Status aller Dateien:** Entwicklungsmaterial, **keine Veröffentlichungsfreigabe** · Register: `docs/masterplan/asset-register.csv` (nur versionierte Dateien, siehe `ASSET-REGISTER.md`)

## 1. Eigene Designteile (Markus)

Markus bestätigt am 2026-10-01, dass er diese Grafiken selbst per KI-Werkzeug hat erstellen lassen. Dienst, Modell, Tarif und Prompt sind **nicht belegt**. Das ist eine Nutzerangabe, kein Herkunftsnachweis im Sinn des Registers; der Status bleibt `ungeklärt`, die Freigabe setzt nur der Product Owner.

Quelle der Layout-Vorlage: `Grimmhain-Werwolf/Grimmhain Assets/Assets/Spielfeld.png` (Gesamtbrett) und `Full UI.png` (Komponentenblatt). Einzelteile liegen in `Grimmhain Assets/`. Dateien, die schon unter `app/public/assets/ui/` versioniert sind, tragen den Vermerk in ihrer Registerzeile (44 Zeilen `ui-*`, SHA-256 identisch). Alle anderen sind nicht versioniert und stehen deshalb hier statt im Register.

Nicht verwenden: alles aus „Blood on the Clocktower“ / „Botc-react“ (anderes Spiel, fremde Marken). `Solo_*.png` und `Wolf_Male.png` nie als Platzporträt.

## 2. ChatGPT-Kandidaten (P1)

ChatGPT-Bildgenerierung am 2026-10-01 durch Markus, Prompts aus `BRIEFINGS-FUER-CHATGPT.md` (Übergabeordner). G1 mit `03-ziel-nacht.png` als Stimmungsreferenz, G2A und G3 mit G1 als Stilreferenz, G2B im selben Chat wie G2A. Bearbeitung im Mockup: G1 abgedunkelt und warme Reflexe per Shader gedämpft, G2 zugeschnitten (10 von 12 Gesichtern), G3 vom Magenta freigestellt und verkleinert.

## 3. Im Mockup V2 verwendete Dateien (SHA-256, erste 16 Zeichen)

| Datei | SHA-256 |
|---|---|
| `player-frame-neutral.png` | `5eb16ce18b0d2d6d` |
| `ring-marked.png` | `abbee34d548c7f52` |
| `ring-poisoned.png` | `b81bb78726ea091c` |
| `ring-silenced.png` | `25486ef2548290da` |
| `overlay-target.png` | `102a0aa1150d7b41` |
| `overlay-active.png` | `fc1318f681d276a7` |
| `overlay-protected.png` | `15b1ffe059459442` |
| `overlay-selected.png` | `14a8df96a20e21f8` |
| `overlay-dead.png` | `7a3324bc516e3887` |
| `protocol-tab-de.png` | `592a3e6a767ed4ab` |
| `options-tab.png` | `f7a9706c9473618f` |
| `panel-protocol-open.png` | `de7f3b5397371885` |
| `panel-options-open.png` | `5e641b3945a270eb` |
| `action-frame-night.png` | `95bf3449c64ac7ae` |
| `tooltip-frame.png` | `84bfc7033e43cc0e` |
| `clock-cartouche.png` | `e11964fd603cbeb0` |
| `btn-next-step.png` | `508e185e6a832325` |
| `btn-undo.png` | `74d6ec06ca55667c` |
| `nightorder-bar-frame.png` | `8fccc30e56fe7be8` |
| `nightorder-slot-active.png` | `c13a49e2f4c6616a` |
| `nightorder-slot-done.png` | `4755a98108b9464f` |
| `nightorder-slot-inactive.png` | `b74733a7980cac64` |
| `Assets/Spielfeld.png` | `93d74cbcfa2e234b` |
| `Assets/Full UI.png` | `1ca82df6b13843b1` |
| `production-pilot/role-art/portraits-512/portrait-werwolf.webp` | `2ae6308fa1df3ae7` |
| `G1-village-night-v1.png` (Downloads) | `8386a51d8cee23fd` |
| `G2A-portraits-v1.png` (Downloads) | `d20352b43d7863b5` |
| `G2B-portraits-v1.png` (Downloads) | `f4f2892faa05a7d6` |
| `G3-frame-action-card-v1.png` (Downloads) | `426d602bc5007f6b` |

## 4. Qualitätsbefunde an den Teilen (für die Produktion)

- `nightorder-slot-*.png`: Die Nummernsockel sind weiß gefüllt (im Mockup in einer Kopie dunkel ersetzt), am Rand weiße Säume und vereinzelte Pixelpunkte.
- Rollen-Nachtsymbole (`night-icon-*.webp`): farbige Eckmarken von Karten sind noch sichtbar.
- `options-tab.png` trägt den Text „OPTION“ (nicht „OPTIONEN“) im Bild, die Protokoll-Lasche den Text „PROTOKOLL“ (DE) bzw. „PROTOCOL“ (EN). Texte im Bild widersprechen der Roadmap (kein Text in generierten Bildern, DE/EN über Lokalisierung).
- `portrait-werwolf.webp` (Rollenbild) ist nur vorläufig (`PILOT-STATUS.md`).
