# CLAUDE.md – Grimmhain: Werewolf Reckoning

---

## ⚡ BEIM START EINER NEUEN SESSION — IMMER ZUERST LESEN

**Lies `ROADMAP.md` im Hauptordner `Werwolf/` bevor du anfängst.**
Die Roadmap enthält den vollständigen Projektstand, alle erledigten Aufgaben und die priorisierten nächsten Schritte. Starte dort weiter wo die letzte Session aufgehört hat.

```
Werwolf/ROADMAP.md  ← Immer zuerst öffnen
```

Wenn Marcus keine konkrete Aufgabe nennt → nächsten offenen Punkt aus der Roadmap vorschlagen.
Wenn eine Aufgabe abgeschlossen wird → Checkbox in ROADMAP.md von `[ ]` auf `[x]` setzen.

---

## Arbeitsregeln für Claude

- **Immer fragen, bevor Änderungen gemacht werden.** Keine Datei verändern ohne explizite Bestätigung.
- Claude hat vollen Lese- und Schreibzugriff auf alle Dateien innerhalb des `Werwolf/`-Ordners.
- Vorschläge klar und verständlich formulieren — der Entwickler ist kein erfahrener Programmierer.
- Bei Fehlern oder Bugs: erst analysieren, dann Lösung vorschlagen, dann warten auf Freigabe.
- Code soll sauber, lesbar und kommentiert bleiben (Deutsch oder Englisch).

---

## Projektvision

**Grimmhain – Werewolf Reckoning** ist ein digitaler Spielleiter-Assistent für das Werwolf/Mafia-Kartenspiel.

### Ziele (in Reihenfolge):
1. **Aktuelle Web-App** stabilisieren, optimieren und bugfrei machen (PWA)
2. **Cross-Platform App** bauen: iOS, Android, Windows/Mac/Linux Desktop
   - Geplante Technologie: [Capacitor](https://capacitorjs.com/) (für Mobile) + [Tauri](https://tauri.app/) oder Electron (für Desktop/Steam)
3. **Vorlage für Online-Version** vorbereiten: Multiplayer, Standalone-Release, Steam
   - Die `js/core/`-Schicht ist die Grundlage dafür — DOM-frei halten!

### Wichtig für alle Entscheidungen:
- Änderungen sollen die spätere App-Portierung nicht erschweren
- `js/core/` darf **kein DOM** enthalten — das ist die portable Spiellogik
- `js/ui/` ist der Web-Layer — wird später durch React Native / native Layer ersetzt

---

## Projekt starten

Kein Build-System erforderlich. Statisch serven:

```bash
python -m http.server 8080
# oder
npx serve .
# oder index.html direkt im Browser öffnen
```

Übersetzungsschlüssel prüfen:
```bash
node tools/compare-i18n.js
```

---

## Dateistruktur

```
Werwolf/
├── index.html          ← Startseite (Spielerzahl + Sprache)
├── setup.html          ← Namenseingabe, Rollenzuweisung, Review
├── game.html           ← Hauptinterface des Spielleiters
├── css/
│   ├── tokens.css      ← Design-Tokens (Farben, Fonts)
│   ├── main.css        ← CSS Grid Layout (5 Spalten)
│   └── screens.css     ← Screen-spezifische Styles
├── js/
│   ├── core/           ← PORTABLE Spiellogik (Ziel: kein DOM — aktuell noch verletzt, s.u.)
│   │   ├── state.js    ← GameState, localStorage (Key: uw_custom_v16), Migration, Undo-Snapshot
│   │   ├── roles.js    ← 72 Rollen, WOLF_ROLES_SET/SOLO_WIN_ROLES (autoritativ), Beschreibungen DE/EN
│   │   ├── abilities.js← Merge-Punkt + onOrderClick + Suche (~120 Zeilen)
│   │   ├── abilities-helpers.js ← Totenkarten-UI, Sensenträger, Waldhexe-Flow (~290 Zeilen)
│   │   ├── abilities-roles-chunk.js ← Fähigkeits-Handler der meisten Rollen (~860 Zeilen, Refactoring-Kandidat)
│   │   ├── role-abilities.js ← Fähigkeitstexte (DE) als Nachschlage-Objekt
│   │   ├── cards.js    ← Totenkarten-System (80 Karten, Post-Tod-Buffs)
│   │   ├── night.js    ← Nacht/Tag-Ablauf, Lynch (finalizeLynch), Order, SL-Assistent
│   │   ├── akte.js     ← Kuratierte Rollen-Sets / Akte (nur in setup.html geladen)
│   │   └── i18n.js     ← Übersetzungen DE/EN + Runtime-Übersetzung (translateRuntimeText/Observer)
│   └── ui/             ← Web-spezifischer Layer (DOM erlaubt)
│       ├── core.js     ← isWolf (autoritativ), applyKill, Tod-Hooks, Siegbedingungen
│       ├── ui.js       ← Rendering-Naht, SVG-Fallback, Pick-Bar, Tod-Overlays
│       ├── field-viewmodel.js ← ViewModel des Spielfelds (reine Daten)
│       ├── field-pixi.js ← PixiJS-Spielfeld-Renderer (bevorzugt)
│       ├── audio.js    ← Nachtmusik, Timer (Rollen-SFX deaktiviert, queueSfxKey = No-op)
│       ├── touch-tooltips.js ← Tap/Long-Press-Tooltips
│       └── gamelog.js  ← Recap-Spielprotokoll (gefiltert)
├── assets/             ← Fonts, Sounds, Icons (strukturiert)
├── tools/
│   └── compare-i18n.js ← Fehlende Übersetzungsschlüssel finden
└── docs/
    └── README.md
```

---

## State-Schema (localStorage `uw_custom_v16`)

```js
{
  seats: [{
    id, name, role,
    flags: { dead, protected, targeted, inlove, rival, werewolf,
             nominated, charmed, poisoned, burned, puppet, hmark },
    meta:  { cerbHeads, killedTonight, cursedWolfAura, rivalId,
             loverId, unholy, blockedTonight }
  }],
  once:       { /* Einmalige Spielzustände, Totenkarten-Mapping, Rollendaten */ },
  dark:       boolean,   // false = Tag, true = Nacht
  nightCount: number,
  layout:     { scale, ratio, offx, offy },
  files:      { nightAudio, alarmAudio }
}
```

---

## Konventionen

| Thema | Regel |
|-------|-------|
| Neue Rolle | In `roles.js` definieren (inkl. `WOLF_ROLES_SET`/`SOLO_WIN_ROLES` falls Wolf/Solo!) → Handler in `abilities-roles-chunk.js` → Nacht-Reihenfolge (`ORDER_BASE` in roles.js) |
| Wolf-Zugehörigkeit | NUR über `WOLF_ROLES_SET` + `flags.werewolf` (isWolf in `js/ui/core.js`). Keine Namens-Regex, keine Inline-Listen |
| Übersetzung | Schlüssel in beide Objekte (`de` + `en`) in `i18n.js` eintragen |
| Todes-Effekte | Vor Implementierung `cards.js` prüfen — könnte bereits behandelt werden |
| Styling | Design-Tokens aus `tokens.css` verwenden (Goldton: `#C9A84C`) |
| Mobile | Landscape-only, Safe-Area-Insets beachten |
| Fonts | Cinzel (Überschriften), IM Fell English (Fließtext) |

---

## Bekannte Schwachstellen / Aufgaben

- ~~`abilities.js` ist mit ~1150 Zeilen sehr groß~~ → ✅ längst gesplittet (abilities.js ~120 Z. + helpers + roles-chunk); `abilities-roles-chunk.js` (~860 Z.) bleibt Refactoring-Kandidat
- ~~Doppelte Asset-Ordner (`/icons` + `/assets/icons`, `/Sounds` + `/assets/sounds`)~~ → ✅ erledigt (2026-05-30): Root-Duplikate existieren nicht mehr, Assets nur unter `/assets/`
- `js/core/` ist NICHT DOM-frei (night.js rendert Order, abilities-* nutzen Overlays) → blockiert Portierung, großes Refactoring
- `game.html` enthält viele historische Inline-Patch-Schichten (3 konkurrierende Kreis-Verschiebe-Tools, Dynamic-Circle-Panel) → Aufräum-Lauf geplant
- Rollen-SFX deaktiviert (2026-06-12, `queueSfxKey` = No-op) → saubere Wiedereinbindung später; Aufruf-Stellen sind erhalten
- Totenkarten-EN fehlt (80 Karten nur DE) → separater Übersetzungslauf geplant
- Mobile-Unterstützung: aktuell nur Landscape → Portrait-Modus prüfen
- Kein echtes automatisches Testing (nur Datei-Grep-Smoketest `npm test`)
- Aktueller verifizierter Audit: `GRIMMHAIN_ANALYSE_2026-06-12.md`

---

## Cross-Platform Roadmap (Referenz)

```
Phase 1: Web-PWA (aktuell)
  └─ Vanilla HTML/CSS/JS, läuft im Browser

Phase 2: Mobile App
  └─ Capacitor um bestehenden Web-Code wrappen
     → iOS App Store + Google Play

Phase 3: Desktop App
  └─ Tauri (empfohlen, klein) oder Electron
     → Windows, macOS, Linux + Steam

Phase 4: Online-Version
  └─ Backend hinzufügen (Node.js / Supabase)
     → Multiplayer, Accounts, Lobbys
```
