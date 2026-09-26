# Grimmhain Tablet — Asset-Vertrag (Phase 1)

**Stand:** 2026-06-12, abgeleitet aus dem funktionierenden Phase-1-Layout
(`app/`, Branch `codex/tablet-shell-phase1`) und dem Referenzdesign
`Grimmhain Assets/Spielfeld.png`.

**Grundregeln (gelten für alle Assets):**
- Keine Texte in Bildern — alle Beschriftungen rendert React bzw. Pixi-Text.
- Kein UI-Chrome in Bildern — Buttons, Panels, Leisten sind Code (React/CSS).
- Lieferformat: **WebP (lossy, Qualität 80-90)** für Flächen/Porträts,
  **PNG-32** nur wo harte Alpha-Kanten nötig sind (Ringe, Marker).
- Farbraum sRGB. Keine eingebetteten ICC-Profile.
- Dateinamen: `kebab-case`, ASCII, Muster siehe je Asset-Typ.
  Rollen-IDs werden transliteriert (`ä→ae` usw.), z. B.
  `rachsuechtiger-wolf`, `koenig-lykaon`, `dr-victor-frankenstein`.

---

## 1. Dorfplatz-Hintergrund (Tag/Nacht)

Der Pixi-Canvas füllt die Bühne zwischen Nachtleiste (oben, ~76 px) und
PhaseControls (unten, ~56 px). Gemessene Canvas-Flächen:

| Gerät | Viewport | Canvas (Bühne) |
|---|---|---|
| iPad 4:3 | 1024×768 | 1024×600 (≈ 1.71:1) |
| Android 16:10 | 1280×800 | 1280×632 (≈ 2.03:1) |

**Anforderung:**
- 1 Master pro Phase: `board-bg-day.webp`, `board-bg-night.webp`
- **Maße: 2560×1600 px** (deckt 2× Retina des breitesten Falls)
- **Sicherer Inhaltsbereich:** zentrale Ellipse ~70 % Breite × 80 % Höhe —
  dort liegen Sitzkreis und Aktionsfenster; keine wichtigen Bilddetails
  außerhalb, da beide Seiten je nach Aspekt beschnitten werden
  (`cover`-Skalierung, Anchor Mitte 0.5/0.5)
- Kein Alpha (volle Deckung), Vignette zum Rand hin erwünscht
  (Drawer-Tabs liegen darüber)
- Varianten: `day`, `night` (Pflicht); optional `dawn` für Übergänge

## 2. Spielertoken-Porträts

Tokens sind kreisrunde Medaillons; Durchmesser dynamisch (computeGeometry):

| Spielerzahl | Token-⌀ bei 1024×600 | Token-⌀ bei 1280×632 |
|---|---|---|
| 12 | ~100 px | ~110 px |
| 18 | ~76 px | ~86 px |
| 24 | ~56 px | ~66 px |

**Anforderung:**
- 1 Porträt pro Rolle: `portrait-<rollen-id>.webp` (72 Rollen)
- **Maße: 512×512 px**, quadratisch
- **Sicherer Bereich: einbeschriebener Kreis ⌀ 460 px** — alles außerhalb
  wird von der Kreismaske abgeschnitten (Pixi-Circle-Mask)
- Gesicht/Motiv mittig, Augenlinie bei ~40 % Höhe (Badge sitzt oben am Rand)
- Kein Alpha nötig (wird maskiert); kein Rahmen/Ring im Bild (kommt als
  eigenes Asset bzw. Code)
- Anchor/Pivot: Mitte (0.5/0.5)
- Skalierung: bilinear herunter bis ⌀ 56 px — Motive kontrastreich genug
  für 56 px wählen (Test: bei 24 Spielern auf 4:3)
- Statusvarianten: **nicht als separate Porträts** — tot/ausgegraut macht
  der Renderer (Desaturierung + Alpha)

## 3. Token-Ringe (Fraktion/Status)

Aktuell Code-gezeichnet; als Asset optional für die finale Gestaltung:
- `ring-dorf.png`, `ring-wolf.png`, `ring-solo.png`, `ring-dead.png`,
  `ring-target.png` (Zielmarker), `ring-selected.png`
- **Maße: 512×512 px, PNG-32 mit Alpha**, Ringstärke 7-9 % des Durchmessers
- Innendurchmesser ≥ 86 % (Porträt bleibt sichtbar), Anchor Mitte
- `ring-target` darf nach außen glühen: Zeichnung bis max. 600×600 in einer
  512er-Box NICHT erlaubt — stattdessen Canvas 640×640 liefern und im Code
  auf 1.18× Token-⌀ skaliert (so rendert es der Platzhalter heute)

## 4. Sitznummern-Badge

Code-gerendert (Kreis + Zahl). Als Asset optional:
- `badge-seat.png`, 128×128 px, PNG-32, Alpha, Anchor Mitte;
  Zahl bleibt IMMER Text (kein Asset mit eingebackener Zahl)

## 5. Nachtleisten-Medaillons

Die Leiste oben zeigt pro Nachtrolle ein rundes Icon (36 px CSS ≙ 72 px @2x):
- `night-icon-<rollen-id>.webp`, **256×256 px**, kreissicherer Bereich ⌀ 230
- Monochrom/duoton bevorzugt (aktiver Zustand wird per CSS-Glow markiert)
- Statusvarianten nicht nötig (aktiv/erledigt/Tarnung macht CSS)

## 6. Aktionsfenster-Schmuck

Das zentrale Panel ist React/CSS. Erlaubt als Assets:
- `panel-frame.png` (9-Slice-fähiger Zierrahmen, 512×512, PNG-32,
  Slice-Ränder 64 px) — KEIN kompletter Panel-Screenshot
- `divider-ornament.png` (Trennlinie, 512×64, Alpha)

## 7. Atmosphäre/Effekte (Pixi)

- Partikel-Sprites: `fx-ember.png`, `fx-fog.png` — 128×128, PNG-32,
  weiche Alpha, additiv-tauglich (keine harten Kanten)
- Werden ausschließlich auf dem Board gerendert (Pixi-Scope)

## 8. Anforderungen je Aspekt & Spielerzahl

- Alle Assets müssen in BEIDEN Bühnenformaten funktionieren
  (1.71:1 und 2.03:1) — der Hintergrund wird `cover`-beschnitten,
  Tokens/Icons sind formatunabhängig (rund)
- Porträts müssen bei ⌀ 56 px (24 Spieler auf iPad) noch lesbar sein —
  Abnahmekriterium: Testansicht `?players=24` bei 1024×768
- Bei 24 Spielern beträgt der Abstand Token-Rand ↔ Nachbar-Badge ~8-10 px:
  Ringe/Glows dürfen 1.18× Token-⌀ nicht überschreiten

## 9. Ablage & Pipeline

```
app/public/assets/
├── board/      board-bg-day.webp, board-bg-night.webp
├── portraits/  portrait-<rollen-id>.webp   (72×)
├── rings/      ring-*.png
├── night/      night-icon-<rollen-id>.webp
├── panel/      panel-frame.png, divider-ornament.png
└── fx/         fx-*.png
```

- Quelldateien (PSD/AI/4K-Master) NICHT ins Repo — nur Exporte
- Export-Empfehlung: WebP `-q 85`, PNG via oxipng/pngquant
- Jede Lieferung gegen die drei Testansichten (12/18/24) und beide
  Viewports (1024×768, 1280×800) prüfen, bevor sie übernommen wird
