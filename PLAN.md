# PLAN — Grimmhain Spielleiter-App zur echten Cross-Platform-App

**Stand:** 2026-05-30
**Grundlage:** `AUDIT.md` (Ist-Stand) + abgestimmtes Ziel (Soll-Stand)
**Repo:** `Grimmhain/` (bestätigt als aktives Repo)

---

## Ziel (Soll)

Eine vollständige, hochwertige **Single-Device-Spielleiter-App**, die als echte App auf
iOS- und Android-Tablets läuft und später als Vorlage für eine Steam-Desktop-Version dient.
Premium-Optik, besonders der Dorfplatz. **Kein** Online/Multiplayer, **keine** Game-Engine.

## Gelockte Entscheidungen

| Thema | Entscheidung | Warum |
|---|---|---|
| Codebasis | Eine Web-Codebasis bleibt Single Source of Truth | wird für alle Targets gewrappt |
| Mobile-Packaging | Capacitor → iOS + Android | bewährt, du kennst es |
| Steam-Packaging | Electron (später) | derselbe Build, Desktop-Webview |
| Renderer Spielfeld | **PixiJS** (Canvas/WebGL-2D) | echtes Game-Feel, Animation, Licht |
| Architektur | saubere Naht State ↔ View, **kein** Komplett-Refactor vorab | Renderer austauschbar, sauberes Wrappen |
| Verworfen | "core DOM-frei machen" | alle drei Targets haben einen DOM, unnötig |
| Verworfen | Online/Multiplayer, 3D-Engine | nicht das Produkt |

## Querschnitt-Track: Art-Pipeline (läuft ab Tag 1 parallel)

Die Premium-Optik ist zu ~70% Art-Direction. Produziert parallel zur Code-Arbeit in Midjourney,
im gelockten Kartenstil (dunkles Märchen-Ölbild, Chiaroscuro, `--ar` passend, `--style raw`):
- Board-Background Dorfplatz, je eine Variante für **Portrait und Landscape**
- Sitz-Tokens: transparente PNGs in **festem Rahmenformat** (Portrait/Wappen je Fraktion)
- Atmosphäre: Vignette, Nebel-Layer, Tag/Nacht (vorhandene `Tag.png`/`Nacht.png` als Basis)
- Alles am Ende in einen **Atlas/Spritesheet** packen (Tablet-Performance)

---

## Phase 0 — Repo-Hygiene & Quick-Win-Bugs

*Kleiner Aufwand, sofortiger Effekt, sauberer Startpunkt. Unabhängig vom Rest.*

- [ ] Capacitor-Lage klären: existiert ein Wrapper im/zum Repo? Wenn nein, wird er in Phase 4 frisch aufgesetzt.
- [ ] Fehlende Sounds beheben (`audio.js:3-13`): `Alarm.mp3`, `WahnsinnigKutscher.mp3`, `Loki.mp3` ergänzen ODER auf vorhandene Dateien mappen. **Live-kritisch** (Nachtwächter-Alarm).
- [ ] Toten `Totenrat-Führer`-UI-Zweig entfernen/auf `Nekromant` umstellen (`ui.js:243-250`, Buttons in `game.html`).
- [ ] `tools/compare-i18n.js` reparieren (vm-`window` stubben), DE↔EN-Drift einmal messen.
- [ ] `ROADMAP.md`/`CLAUDE.md`: erledigte Punkte (doppelte Asset-Ordner) als done markieren.

**Done wenn:** Sounds spielen, kein toter UI-Code, i18n-Tool läuft, Smoketest grün.

## Phase 1 — Naht State ↔ View

*Der eine strukturelle Schritt, der dich vor Rework schützt. Eng gefasst, kein Monolith-Refactor.*

- [ ] State = einzige Wahrheit definieren: dokumentiere die State-Form, die das Spielfeld liest.
- [ ] Lese-API: eine klar definierte Funktion/Objekt, über das die View den Sitz-/Spielzustand bezieht (keine `window`-Direktzugriffe der View in die Logik).
- [ ] Intent-Richtung zurück: View meldet Aktionen (Sitz getippt, Lynch) über definierte Events/Callbacks an die Logik, nicht umgekehrt verdrahtet.
- [ ] Logik berührt **kein** DOM und **keinen** Renderer mehr (für den Spielfeld-Pfad).

**Done wenn:** Das aktuelle SVG-`draw()` ließe sich austauschen, ohne Spiellogik anzufassen.

## Phase 2 — Pixi-Dorfplatz + responsives Layout (ein Pass)

*Die große visuelle Phase. Spielfeld neu, Layout für beide Lagen, in einem Durchgang.*

- [ ] PixiJS einbinden, Stage mit **resize-Hook + Layout-Funktion** (Portrait + Landscape).
- [ ] Spielfeld in Pixi neu, liest über die Phase-1-Naht aus dem State:
  - Board-Background, Sitz-Tokens als Art statt Punkte, Fraktions-Theming
  - Auswahl-/Todes-Animationen (Tween), Tag/Nacht-Wechsel, Vignette/Nebel
- [ ] Altes `ui.js`-`draw()`/`autoFit()` durch die Pixi-View ersetzen, Spiellogik unverändert.
- [ ] Art-Assets aus dem Querschnitt-Track integrieren (Atlas laden).

**Done wenn:** Dorfplatz sieht premium aus, läuft flüssig auf Tablet in Portrait + Landscape, alle Spielfunktionen wie vorher.

## Phase 3 — UI-Politur (Rest der Oberfläche)

- [ ] Modals/Overlays, SL-Assistent, Timer, Suche auf denselben visuellen Standard.
- [ ] Touch-first: große Trefferflächen, Einhand-Bedienung, Lesbarkeit im Halbdunkel.
- [ ] Touch-Tooltips (Tap/Long-Press statt nur Hover).
- [ ] Leere `catch`-Blöcke an spielentscheidenden Stellen sichtbar machen (keine stummen Fehler in der Session).

**Done wenn:** kein "6.-Klasse-HTML"-Eindruck mehr, gesamte App aus einer Welt.

## Phase 4 — Packaging Mobile (Capacitor)

- [ ] Capacitor aufsetzen/aktualisieren, `capacitor.config`, Web-Build → `www/` → `cap sync`.
- [ ] iOS-Build (Xcode, Signing) + Android-Build (Studio).
- [ ] Test auf echtem Tablet, beide Lagen, Audio/Performance prüfen.

**Done wenn:** installierbare App auf iPad und Android-Tablet, fühlt sich nativ an.

## Phase 5 — Steam (später)

- [ ] Electron-Wrapper um denselben Build, Fenster-/Vollbild-Handling Desktop.
- [ ] Steam-Build/Depot. Erst nach Mobile-Release.

---

## Reihenfolge & Parallelität

```
Art-Pipeline (Midjourney) ........... läuft ab Phase 0 durchgehend parallel
Phase 0  Bugs/Hygiene
   ↓
Phase 1  State↔View-Naht
   ↓
Phase 2  Pixi-Dorfplatz + responsive   ← Hauptphase, braucht Art aus dem Track
   ↓
Phase 3  UI-Politur
   ↓
Phase 4  Capacitor (iOS + Android)
   ↓
Phase 5  Electron (Steam)  — später
```

**Leitplanke:** "Einmal richtig" = richtiger Renderer + saubere View-Naht.
NICHT = Architektur perfektionieren, bevor eine Runde spielbar ist.
