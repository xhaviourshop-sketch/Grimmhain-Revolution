# 01 · Bestandsaufnahme des aktuellen Systems

**Stand:** 2026-09-26 · Branch `claude/admiring-albattani-e0lh76` · Commits `c506cfd` (Import) und `2109445` (Audit-Brief)
**Art:** Read-only-Analyse. Kein Code wurde verändert.

**Kennzeichnung in allen Dokumenten dieses Ordners**

| Marke | Bedeutung |
|---|---|
| **[B]** Beobachtung | Direkt im Code, in Dateien oder per Kommando nachgewiesen (Fundstelle angegeben) |
| **[S]** Schlussfolgerung | Aus Beobachtungen abgeleitet, nicht zur Laufzeit geprüft |
| **[E]** Empfehlung | Vorschlag für die Godot-Migration |

Pfad-Kurzformen: `core` = `js/ui/core.js`, `night` = `js/core/night.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `roles` = `js/core/roles.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben beziehen sich auf den oben genannten Commit.

---

## 1. Prüfumfang und Grenzen

- Vollständig gelesen: `js/core/*.js`, `js/ui/core.js`, `js/ui/audio.js`, `js/ui/gamelog.js`, die Adapter-Schicht `app/src/adapter/**`, Build-Dateien, alle Root-Berichte.
- `game.html`, `setup.html`, `index.html` und die React-Komponenten wurden abschnittsweise mit Zeilenbezug ausgewertet.
- Ausgeführt: `node tests/smoke.js` (OK), `node tools/compare-i18n.js` (0/0 fehlende Schlüssel), Knoten-Skripte zur Zählung von Rollen, Karten und Übersetzungsabdeckung.
- **Nicht** ausgeführt: Browser-Durchlauf, Gerätetest, `tsc` für `app/` (kein `app/node_modules`).
- `GRIMMHAIN-ANALYSE-UND-ROADMAP-2026-09-15.md` bezieht sich teils auf lokale Ordner des Product Owners (`C:/Users/Marku/...`), die nicht im Repository liegen (BotC-Referenzprojekte, `production-pilot` mit 72 Porträts). Aussagen dazu sind hier nicht prüfbar.

### 1.1 Abgleich mit der Analyse vom 15.09.2026

| Aussage der Analyse | Ergebnis der Prüfung |
|---|---|
| W01: Web liefert `app/dist`, Capacitor liefert `dist` mit Legacy-UI | **Bestätigt** [B] `vercel.json`, `capacitor.config.ts`, `tools/copy-dist.js:16` |
| W02: `sw.js` ohne Cache | **Bestätigt** [B] `sw.js:1-9` |
| W03: Speicherfehler nur Console-Warnung | **Bestätigt** [B] `state:111-115`, `state:121-130` |
| W04: Undo = ein `lastSnapshot` im RAM | **Bestätigt und verschärft**: Der 5-Schritt-Undo in `gh:2251-2315` ist wirkungslos, weil `gh:371` `let state` deklariert und der Wrapper `window.state` liest [B] |
| W05/W06: Frankenstein-`select` nicht gespiegelt, `dead=false` vor Bestätigung | **Bestätigt** [B] `chunk:70,81`, `app/src/adapter/legacy/domMirror.ts:57-59` |
| W08: Namen nur kommagetrennt | **Bestätigt** [B] `setup.html:783-787` |
| W09: Gate < 900×600 | **Bestätigt** [B] `app/src/components/OrientationGate.tsx:8-19` |
| W10: Smoke-Test prüft nur Dateitext | **Bestätigt** [B] `tests/smoke.js` (8 String-Prüfungen) |
| W12: Speichern löst Spielfolgen aus | **Bestätigt** [B] `state:76-119` (Jäger-Queue, Prophet, `checkTeamWin`) |
| „72 Rollendefinitionen" | **Bestätigt** [B] `roles:1`, 72 eindeutige Einträge |
| „Totenkarten" als Spielsystem | **Präzisiert**: 80 Karten, aber **kein Karteneffekt ist automatisiert** [B] (Abschnitt 4.6) |
| „Rückgängig mit Klartext" (React) | Klartext ja (`legacyAdapter.ts:195-238`), fachlich aber nur 1 Schritt [B] |

---

## 2. Verzeichnis- und Modulübersicht

```
/                      Vanilla-Web-App (Legacy-Referenz)
├─ index.html          Start: Spielerzahl 4–40, Akt I–IV/Custom, Sprache, Fortsetzen
├─ setup.html          3 Schritte: Namen → Rollen-Chips → Übersicht; Verteilung zufällig/manuell
├─ game.html           Spielleiter-Oberfläche (2633 Z., ~35 Inline-Skripte, viele Patch-Schichten)
├─ css/                tokens.css (Design-Tokens), main.css, screens.css
├─ js/core/            "Kern" – NICHT DOM-frei (night.js rendert #order, abilities* nutzen #overlay)
│  ├─ roles.js         ALL_ROLES (72), ORDER_BASE (50), WOLF_ROLES_SET (19), SOLO (14), Texte DE/EN
│  ├─ abilities*.js    Fähigkeits-Handler, Totenkarten-Overlay, Waldhexe-/Sensenträger-Flows
│  ├─ night.js         Nachtreihenfolge, Nacht-/Tagwechsel, Nachtauflösung, Lynch, SL-Assistent
│  ├─ cards.js         80 Totenkarten (nur DE), Ziehlogik
│  ├─ akte.js          4 kuratierte Akte + Custom
│  ├─ state.js         createState, migrateState, save/load (localStorage), 1-Schritt-Undo
│  └─ i18n.js          322 Schlüssel DE/EN + Laufzeit-Substring-Übersetzung per MutationObserver
├─ js/ui/              core.js (isWolf, applyKill, Siegprüfungen), ui.js, audio.js, gamelog.js,
│                      field-viewmodel.js, field-pixi.js, touch-tooltips.js
├─ js/vendor/pixi.min.js
├─ app/                React 19 + Vite + TS: Tablet-Shell über Legacy-Engine (Adapter via verstecktem DOM)
├─ assets/             Karten (2×73 WebP), Sounds (10 MP3), Fonts (4 TTF), Icons
├─ tools/              compare-i18n, convert-cards, copy-dist, Python-Einmalskripte
├─ tests/smoke.js      Datei-Grep-Test
└─ docs/               ASSETS.md, architecture/tablet-asset-spec.md, screenshots
```

### 2.1 Laufzeit-Zusammenspiel [B]

- Die Legacy-Skripte teilen sich den **globalen Scope** (`state`, `draw`, `save`, `center`, `startPick` usw.). Ladereihenfolge: `gh:26-43`.
- `game.html` überschreibt Kernfunktionen mehrfach per Monkey-Patch (`draw` und `rebuildOrder` je bis zu vier Wrapper, `save` durch Undo-Wrapper). [B] Siehe Abschnitt 7.
- Die React-App lädt dieselben Skripte als klassische Skripte in ein **verstecktes Off-Screen-DOM** (`app/src/adapter/legacy/legacyEnv.ts:48-67,101-111`), liest Overlays und Pick-Leiste per `MutationObserver` aus (`domMirror.ts`) und klickt versteckte Buttons. Spielentscheidungen werden also aus gerendertem Text und DOM abgeleitet. [B]

### 2.2 Auslieferung [B]

| Ziel | Mechanismus | Tatsächlich ausgelieferte Oberfläche |
|---|---|---|
| Web (Vercel) | `vercel.json` baut `app/dist` | React-Spielbrett + Legacy `index.html`/`setup.html` als `legacy-setup/` |
| Capacitor | `tools/copy-dist.js` → `dist/` | Legacy `index.html` → `setup.html` → `game.html` (kein React) |
| PWA | `manifest.json`, `sw.js` ohne Fetch-Handler | Kein Offline-Cache; im Vercel-Build fehlen `sw.js`/`manifest.json` (404) |

[S] Web und App zeigen zwei verschiedene UIs derselben Engine. Für Godot entfällt dieses Problem, weil es nur eine Oberfläche geben wird.

---

## 3. Tatsächlich implementierte Funktionen

| Bereich | Implementiert [B] | Nicht implementiert [B] |
|---|---|---|
| Vorbereitung | Spielerzahl 4–40 (`index.html:326,348-352`); Akt-Auswahl (`index.html:305-310`); DE/EN; Namen kommagetrennt, Anzahl muss passen (`setup.html:783-787,853-856`); Rollenchips mit Obergrenzen Werwolf 5, Dorfbewohner 10, Die Gebundenen 6, sonst 1 (`setup.html:793-798`); zufällige oder manuelle Verteilung (`setup.html:1103-1162`); Pflichtpaar Schwarze Witwe → Loki (`setup.html:1111-1117`); Rollenvorschau-Sequenz (`gh:1208-1250`) | Zeilengetrennte Namen; gespeicherte Gruppen; Setup-Validierung über Paarungen hinaus; Balance-/Komplexitätsanzeige |
| Nacht | Dynamische Reihenfolge aus `ORDER_BASE` (`night:22-128`); Rollen-Handler (`chunk`, `ab`); Zielwahl `startPick`/`startMulti`; SL-Assistent „Weiter" (`night:586-733`); Nachtauflösung bei Tagesbeginn (`night:177-398`) | Persistenz des Assistenten-Fortschritts; Aktionsvorschau vor Bestätigung; Abbruch ohne Teilzustand |
| Tod | Zentrale `applyKill` mit 15 Schritten (`core:102-216`), 28 Todesursachen, Folgehaken `postDeathHooks` (`core:361-414`), Liebende, Wolfskind/Lehrling-Verwandlung, Sensenträger-Warteschlange, Morgen-Todeszusammenfassung | Schutz (`flags.protected`) ist **nicht** in `applyKill`, sondern nur im Werwolf-Handler (`chunk:162`) |
| Tag | Lynch als **direkte SL-Auswahl** (`night:421-504`) mit 11 Sonderzweigen; `finalizeLynch` für Henker/LynchCount (`night:404-419`); Nominierung als manuelles Flag (`gh:274,429`); Countdown-Timer 2:00 (`js/ui/audio.js:29-70`) | **Keine Stimmabgabe, keine Stimmzählung, keine Gleichstandsregel, kein Bürgermeister**; `voteWeight` (`js/ui/ui.js:18`) nur als Marker |
| Sieg | `checkWinConditions` (`core:218-239`), `checkTeamWin` (`core:287-337`), Sonder-Siege Pest, Rattenfänger, Hades, Kartenschlucker, Todesprediger, Selbstmörder, Nekromant, Manipulator, Parasit, Doppelspion | Solo-Siege für Prophet, Feuerteufel, Voodoo-Priester, Grabräuber, Die Ewigen, Rachsüchtiger Wolf (siehe `04`) |
| Totenkarten | Vergabe (`help:5-20`, `core:190-207`), Anzeige per Button am toten Sitz, „ausgespielt"-Flag, Kartenschlucker-Tausch | **Kein** Karteneffekt automatisiert (0 Referenzen auf Karten-IDs außerhalb `cards.js`) |
| Persistenz | `localStorage` Schlüssel `uw_custom_v16`; Migration alter Rollennamen (`state:16-45`) | Schemaversion, Import/Export, Backup, sichtbare Fehler, mehrere Spielstände |
| Undo | 1 Snapshot im RAM bei Nachtzeilen-Klick und Lynch-Start (`state:133-135`) | Mehrstufig, Redo, Undo über Neustart, Protokoll-Rücknahme |
| Protokoll | `gameLog` im RAM, gefiltert auf Tod/Phase/Lynch (`js/ui/gamelog.js:17-29`), Kopieren | Persistenz; Fähigkeiten, Nominierungen, Kartenspiele werden nicht protokolliert |
| Audio | Nachtmusik mit Positionsspeicher (`night:149-154,180-188`), Timer-Endton `Ruhe.mp3` | Rollen-SFX: `queueSfxKey` ist No-op (`js/ui/audio.js:12`) |
| i18n | DE/EN-Wörterbuch (322 Schlüssel), Rollennamen/-texte EN (`roles:137-285`) | EN für Totenkarten (nur 46/80 Namen gemappt, Substring-Ersetzung erzeugt Mischtexte) |
| Layout | SVG/Pixi-Ring (Legacy), DOM-Ring mit Kollisionsmessung (React `DomBoard.tsx`) | Portrait-Modus; Geräte < 900×600 |

---

## 4. Datenmodelle und Zustandsflüsse

### 4.1 Spielzustand (`localStorage["uw_custom_v16"]`) [B]

```
state = {
  seats: [{ id (1..n, = Index+1), name, role (deutscher Anzeigename als ID),
            flags: { dead, protected, protectedCount, targeted, inlove, rival, werewolf, vorbild,
                     nominated, charmed, poisoned, burned, puppet, hmark, deadVoteStripped },
            meta:  { deathProcessed, hunterQueued, hunterShot, cerbHeads, killedTonight,
                     cursedWolfAura, rivalId, loverId, unholy, blockedTonight, lastKillCause,
                     rkLink, appleBuff, parasiteHostId, shadowSwapPartnerId, schmiedWeapon,
                     giftwolfDieOnMorning, packfatherPierce, spMirrorUsed, ritterRetaliated,
                     fakeWolfSignal, ... } }],
  once: { ~35 Startschlüssel + ~40 zur Laufzeit angelegte Schlüssel
          (Used{role_*}, totenkarten{seatId:{karteId,gespielt,shown}}, TeamWinner,
           LynchCount, MorningCount, OldDebuff, VoodooCooldown, Hades*, Kartenschlucker*, ...) },
  dark: bool, nightCount: number (nicht in createState, gh:372), fenrirStage, fenrirSaved,
  files: { night, nightPos, alarm }, font, pending{judgeAsk}, ui{judgeAsk, ghostCasting},
  layout: { scale, ratio, offx, offy }
}
```

Quellen: `state:3-14` (Defaults), `state:47-74` (Migration), Laufzeitschlüssel in `gh:522-525` (`clearRolesNewRound`).

**Schwächen des Modells [B/S]**

1. **Rollen-ID = deutscher Anzeigename** (`"Das Orakel"`, `"Dr. Victor Frankenstein"`). Umbenennungen erfordern Migration (`state:16-45` hat bereits 13 Umbenennungen).
2. **Sitzposition = ID.** Nachbarn werden als `(id-1±1) mod n` berechnet (Wahnsinniger Kutscher, Feuerteufel, Fährtenleser, Detektiv, Blutwolf, `spreadPoison`, `findNearestWolf`, `doBearPing`). Umsetzen von Spielern ist dadurch fachlich unmöglich.
3. **`once` ist ein untypisierter Sack** aus Einmal-Flags, Zählern, Warteschlangen, Transientem (`_inNightResolution`, `_shadowApplying`) und Sieger. Rücksetzen bei neuer Runde driftet (`ChroniclerShown`, `GiftwolfUses` werden nicht zurückgesetzt, siehe `04`).
4. **Keine Schemaversion**, keine Regelversion.
5. **Effekte ohne Quelle und Dauer.** `flags.protected` weiß nicht, wer schützte und bis wann. Laufzeiten sind in `onNightStart`/`onDayStart` verstreut.
6. **UI-Zustand im Spielzustand** (`layout`, `font`, `files`). `files.night` kann eine `blob:`-URL sein, die nach Neustart ungültig ist (`gh:559-564`).

### 4.2 Phasen- und Auflösungsfluss [B]

```
[Setup] --setup.html schreibt state, dark=true--> [Nacht N]
  onNightStart (night:130-175): dark=true; Resets (protected außer Der Weise, targeted, nominated,
      burned, blockedTonight, killedTonight); Cerberus-Köpfe+1; Fenrir-Stufe+1; Schmied+1; Musik an
  SL klickt Nachtzeilen → onOrderClick(role) (ab:71-125) → Handler setzt Flags ODER tötet sofort
      (Waldhexe-Gift, Verdammniswächter, Hades, Kartenschlucker, Prophet, Blutpriester, Amalia, Kriegerin)
[SL drückt "Tag"] onDayStart (night:177-283)
  MorningCount+1 → Witwen-Tode → Giftwolf-Tode → Zähler (OldDebuff, Voodoo) → Ziele sammeln
  → (Rudelvater-Zusatzopfer) → Dorfwache-Filter → Voodoo-Umlenkung → Märtyrerin-Dialog
  → resolveDayKills (night:322-398): Zeitwächter-Einfrieren? → Gift verbreiten → Pest-Sieg?
      → blockierte raus → je Ziel: Der Weise → Nekromant-Umlenkung → Schmied-Waffe → applyKill
      → Brand-Ausbreitung → Ritter → Dämonen-Fluch → Besessener Wolf → postDeathHooks
      → dark=false, nightCount+1 → Todeszusammenfassung → Sensenträger-Queue
[Tag] Nominieren (Flag) · Lynch: doLynchFlow (night:421-504) · Timer · [SL drückt "Nacht"]
```

**Kritische Eigenschaften [S]**

- Die Auflösung ist **callback-verkettet** über UI-Dialoge (`startPick`, `#overlay`). Zwischenstände liegen im Speicher, nicht im Zustand. Ein Reload mitten in der Auflösung hinterlässt einen halb angewandten Zustand.
- Tode durch Nachtfähigkeiten passieren **sofort beim Klick**, Wolfstode erst **am Morgen**. Diese Asymmetrie ist fachlich relevant (Verdammniswächter, Zeitwächter) und muss in Godot explizit modelliert werden.
- `save()` ist nicht rein: Es verarbeitet Sensenträger-Warteschlange, Prophet-Freischaltung und Siegprüfung (`state:76-119`).
- Zufall über `Math.random` an 20 Stellen (`chunk` 12, `cards.js` 5, `night` 1, `core` 2) [B]. Nicht reproduzierbar, nicht testbar.

### 4.3 Todes-Pipeline `applyKill(seat, cause)` (`core:102-216`) [B]

Reihenfolge: bereits tot → Parasit-Immunität → Rudelvater-Erstrettung → Schattenwanderer-Umlenkung → Nekromant-Schild (global!) → Kartenschlucker-Schild → Hades-Barriere → `dead=true` → Seuchenwolf/FirstThreeDeadIds/Schutzgeist/Detektiv/Todesprediger → Parasit stirbt mit Wirt → Rotkäppchen-Kette → Besessener-Wolf-Warteschlange → Totenkarte ziehen → Hades-Lichter → `checkWinConditions`.

Außerhalb von `applyKill` (nur in bestimmten Aufrufern): Schutzengel/Dorfwache (Werwolf-Handler), Der Weise/Nekromant-Umlenkung/Schmied (`processOne`), Voodoo, Märtyrerin, Cerberus, Fenrir, Spiegelwolf, Liebende (`postDeathHooks`).

[S] Schutzwirkungen sind damit **ursachenabhängig verstreut**. Eine Godot-Tötungs-Pipeline braucht eine einzige, explizit geordnete Liste von Abfangregeln (siehe `03`, Abschnitt 5.4).

Alle 28 Todesursachen mit Fundstellen: siehe `04-rules-migration-matrix.md`, Abschnitt C.

### 4.4 Nachtreihenfolge [B]

`ORDER_BASE` (`roles:3-61`) enthält 50 Einträge mit `tier` 0.1 bis 9.9 in 7 Gruppen (A: einmalig Nacht 1, B: vor den Wölfen, C: Wolfsphase, D: Reaktion, E: Dorf, F: Spezialisten, G: letztes Wort). 22 Rollen haben keinen Eintrag (passiv). Die vollständige Tabelle steht in `04`, Abschnitt B.

Filterregeln in `rebuildOrder` (`night:56-85`): nur lebende Rolleninhaber; Henker erst ab `LynchCount>=3`; `once`-Rollen nach Nutzung weg; Frankenstein nach Nutzung weg; Schicksalswolf nur Nacht 1 und ab Nacht 4 mit Bonus; Prophet erst nach Freischaltung; Kutscher erst ab 10 Toten. Zusätzlich eine synthetische Werwolf-Zeile, wenn kein „Werwolf" lebt, aber eine der 10 Rollen aus `WOLF_KILL_ROLES` (`night:50`).

### 4.5 Siegprüfung [B]

Zwei Prüfer mit unterschiedlicher Logik:

| | `checkWinConditions` (`core:218-239`) | `checkTeamWin` (`core:287-337`) |
|---|---|---|
| Aufruf | nach jedem erfolgreichen `applyKill` | nach jedem `save()` |
| Guard „Rollen vergeben" | nein | ja |
| Manipulator, Parasit | ja | nein |
| Kartenschlucker | nein | ja |
| Wolfsstärke | Siegreicher Wolf = 2 | Siegreicher Wolf = 2 |

`triggerWin` (`core:85-100`) prüft nicht, ob bereits ein Sieger feststeht. Spätere Aufrufe überschreiben (`ab:52`, `gh:552`, Manipulator→Parasit). [B]

### 4.6 Totenkarten [B]

- 80 Karten in 6 Kategorien: SEGEN 14, SCHICKSAL 14, FLUCH 13, WENDE 12, LOKI 13, SOLO 14 (`js/core/cards.js:2-571`). Felder: `id`, `kategorie`, `name`, Text (`wolf`+`dorf` | `neutral` | `solo`), optional `deathCardRequirements` (4 Karten).
- Vergabe: Nicht-Wölfe beim Spielstart (`help:5-20`), Wölfe beim Tod (`core:190-207`). Gewichtung nach „wer liegt zurück" wird dadurch beim Spielstart statt beim Tod ausgewertet. [S] Design-Lücke.
- Anzeige nur auf Knopfdruck des SL (`js/ui/ui.js:130-133` → `help:100-195`). „Ausspielen" setzt nur `gespielt=true`.
- **Keine einzige Karte ist mechanisch automatisiert.** Etwa 40 der 80 Karten setzen ein Abstimmungssystem voraus, das nicht existiert.
- Doppelter Name „Anarchie" (`schicksal_10`, `loki_07`).
- **Es gibt keine Totenkarten-Bilder.** `assets/cards/*` sind Rollenkarten.

### 4.7 Protokoll und Undo [B]

- `gameLog.entries` im RAM, max. 500, Filter auf Icons/Schlüsselwörter (`js/ui/gamelog.js:17-57`). Nicht im Zustand, nicht im Undo, nach Reload verloren.
- Undo: `snapshot()` nur in `onOrderClick` und `doLynchFlow`. `undoOnce` stellt den gesamten Zustand wieder her. Der „v2"-Stapel in `gh:2251-2315` ist durch `let state` vs. `window.state` inert. Der Tooltip verspricht „Bis zu 5 Schritte" (`gh:94`, `js/core/i18n.js:117,441`).

---

## 5. Regeln und Sonderfälle mit Fundstellen

Die vollständige Regel-für-Regel-Zuordnung aller 72 Rollen, der Mechaniken und der Todesursachen steht in **`04-rules-migration-matrix.md`**. Hier nur die übergreifenden Sonderfälle, die die Architektur prägen:

| Sonderfall | Fundstelle [B] | Architekturfolge [E] |
|---|---|---|
| Wolfszugehörigkeit = Rollenmenge ODER `flags.werewolf` ODER `meta.cursedWolfAura`; fünf Solo-Rollen nie Wolf | `core:8-19` | Getrennte Attribute: `faction` (Sieg), `appears_as` (Informationsrollen), `counts_as_wolf` (Parität). Siehe Frage Q1 in `07` |
| Manche Handler prüfen `getFaction(role)` (Rollenname), andere `isWolf(seat)` | `help:276-288`, `chunk:262-287`, `chunk:109-127` | Eine einzige Abfrage-API im Core |
| Wächter am Tor wandelt neue Wölfe in Dorfbewohner | `core:41-56`, `core:387-389`, `chunk:85,385,763,847` | Zentrale Rollenwechsel-Funktion mit Abfangregeln |
| Rollenwechsel (Lehrling, Wolfskind, Lykaon, Seelentauscher, Frankenstein, Kutscher) setzen Einmal-Flags inkonsistent zurück | `core:339-359` (löscht `once[role+"Used"]`, genutzt wird aber `once.Used["role_*"]`) | Einmal-Nutzung pro **Sitz und Rolle** speichern, nicht global pro Rolle |
| Rolle mehrfach vergebbar (Werwolf ×5, Dorfbewohner ×10, Gebundene ×6), Handler nehmen aber `seats.find(role)` an | `setup.html:793-798`, zahlreiche `find` in `chunk` | Mehrfachrollen explizit modellieren; Einzigartigkeit als Rolleneigenschaft |
| Todesfolgen können weitere Entscheidungen auslösen (Besessener Wolf, Dämonischer Wolf, Sensenträger, Rudelvater) | `night:285-320`, `gh:1926-2042` | Reaktions-Warteschlange im Zustand (persistiert) |
| Einfrieren einer Nacht (Zeitwächter) greift nur teilweise | `night:323-331` | Klar definierter Nacht-Transaktionsbegriff |

---

## 6. Assets

### 6.1 Übersicht [B]

| Gruppe | Anzahl, Format, Maße | Größe | Herkunft / Lizenz | Godot-Wiederverwendung [E] |
|---|---|---|---|---|
| `assets/cards/de`, `/en` | je 73 WebP (72 Rollen + Rückseite), 839×1400 | je ~11 MB | Laut `ROADMAP.md:204` mit ChatGPT + Gemini erzeugt; Metadaten durch `tools/convert-cards.js` entfernt; PNG-Master gelöscht | **Übernehmen** für Prototyp; Dateinamen auf ASCII-IDs normalisieren; Text vermutlich eingebacken; `Rachsüchtiger_Wolf.webp` = `Vengeful_Wolf.webp` (md5 identisch) |
| `app/public/assets/bg` | 2 WebP 2560×1600 (Tag/Nacht) | 0,9 MB | unbekannt (keine Metadaten) | **Übernehmen** (passt zur Spezifikation) |
| `app/public/assets/markers` | 15 WebP mit Alpha, ~230×265 | 0,3 MB | unbekannt | **Übernehmen**, auf 256² vereinheitlichen |
| `app/public/assets/portraits` | 10 PNG 1254² (Archetypen) | 22 MB | **C2PA: OpenAI / GPT-4o** | Nur Platzhalter; auf 512² WebP re-exportieren; langfristig 72 Rollenporträts |
| `app/public/assets/ui` | 45 Dateien (26 PNG, 19 WebP, 7 Doppelungen) | 28 MB | unbekannt | **Neu aufbauen** als NinePatch/Theme; Tabs und Lynch mit eingebackenem DE/EN-Text; 6 Embleme und 2 Templates unbenutzt; 3 referenzierte Dateien fehlen (`app/src/assets/roleAssets.ts:12-13,20`) |
| `assets/Tag.png`, `Nacht.png`, `assets/icons/game|setup/*` | PNG 1–2,8 MB, zwei JPEG mit `.png`-Endung | ~45 MB | **C2PA: OpenAI** bei 24 Dateien | **Ersetzen** (Legacy-only, eingebackener Text) |
| `assets/icons/app` | 6 PNG, Icons 180–512 px, Logo 677×369 | 2,3 MB | teils C2PA OpenAI | Aus 1024²-Master neu erzeugen |
| `assets/fonts` | Cinzel Regular/Bold, IM Fell English Regular/Italic (TTF) | 0,5 MB | SIL OFL 1.1; **Lizenzdatei fehlt** | **Übernehmen** + `OFL.txt` beilegen; Cinzel Decorative wird in `app/index.html:16-21` vom Google-CDN geladen → lokal einbinden |
| `assets/sounds/Nachtmusik.mp3` | MP3 128 kbps, ~60 min | 57,7 MB (in Git, nicht LFS) | **Herkunft unbekannt** (nur Lavf-Tag) | Erst nach Lizenzklärung als OGG-Loop, sonst ersetzen |
| `assets/sounds/*` (9 SFX) | MP3, uneinheitlich 22–48 kHz, 56–320 kbps | 1,2 MB | vermutlich selbst aufgenommen (ID3 „Neue Aufnahme 66", „FL Studio 20") | Ersetzen; derzeit ohnehin stumm |

### 6.2 Lizenz- und Herkunftsrisiken [B/S]

1. **KI-Herkunft teilweise nachgewiesen, teilweise nur dokumentiert.** 24 Dateien tragen OpenAI-C2PA-Manifeste; bei Karten und UI wurden Metadaten entfernt. [S] Steam verlangt eine Offenlegung KI-generierter Inhalte; urheberrechtlicher Schutz reiner KI-Ausgaben ist in EU und USA schwach. → Herkunftsprotokoll anlegen (Frage Q8 in `07`).
2. **Nachtmusik ohne Herkunft.** Größtes Audio-Risiko.
3. **OFL-Pflichtdatei fehlt** für beide Schriftfamilien.
4. **Blood on the Clocktower:** Kein BotC-Name, -Symbol oder -Text in Code, Daten oder Assets [B] (Suche nach `clocktower|botc|storyteller|grimoire|fabled|townsfolk|minion|imp|drunk`). Nur Dokumente erwähnen lokale BotC-Referenzprojekte. [S] Restrisiko liegt im Look-and-feel (Sitzkreis, Nachtleiste, Erinnerungsmarker). → Eigene Begriffe und Gestaltung, siehe `05`.
5. `.claude/skills/frontend-design.md` verweist auf ein fehlendes `LICENSE.txt` (fremder Skill, nicht Teil des Produkts).

---

## 7. Technische Schulden, Fehlerquellen, tote und doppelte Teile

### 7.1 Kritische Fehlerquellen (Auswahl, vollständig in `04`) [B]

| # | Befund | Fundstelle |
|---|---|---|
| F1 | Schutzgeist kann nie handeln (tote Rollen werden vor dem Sonderfall gefiltert) | `night:58` vs. `night:91-92` |
| F2 | Keine Wolfs-Tötungszeile, wenn nur Wölfe außerhalb `WOLF_KILL_ROLES` leben (z. B. Siegreicher Wolf, Giftwolf, verwandeltes Wolfskind) | `night:50-55` |
| F3 | Albtraumwolf-Blockade rettet das Opfer auch vor den Wölfen | `night:334` |
| F4 | Seelentauscher kann zwei Wölfe erzeugen (veraltetes `flags.werewolf`) | `chunk:782-783` |
| F5 | Toter Lehrling erbt trotzdem die Rolle | `core:389` |
| F6 | Manueller „tot"-Chip umgeht `applyKill` vollständig | `gh:429` |
| F7 | Zwei Siegprüfer mit verschiedener Logik; `triggerWin` überschreibt | `core:218-239`, `core:287-337`, `core:85-100` |
| F8 | 5-Schritt-Undo, `prophetProgressCheck` und Phasenanzeige lesen `window.state` (undefiniert) | `gh:371`, `gh:1874-1875`, `gh:2047`, `gh:2251-2315` |
| F9 | Frankenstein: Rollen-`select` im React-Dialog nicht bedienbar, Wiederbelebung vor Bestätigung | `chunk:54-103`, `domMirror.ts:57-59` |
| F10 | Der Weise doppelt geschützt, wenn Rolle per Popup gesetzt | `gh:450,646`, `night:145`, `night:359-364` |
| F11 | Detektiv zeigt wörtlich `{name}` (`t()` statt `tf()`) | `core:77-79`, `js/core/i18n.js:237,566` |
| F12 | i18n-Schlüssel `besessenerWolfDrag` undefiniert → Rohschlüssel in der Pick-Leiste | `night:312` |
| F13 | `showBlutwolfInfo` aufgerufen, aber nirgends definiert | `night:350` |
| F14 | `killedTonight` enthält auch Überlebende (Dämonen-Fluch, Seuchenwolf-Reset falsch ausgelöst) | `night:374,394` |
| F15 | Cerberus-/Fenrir-Lynchrettung überspringt `finalizeLynch` (LynchCount, Henker) | `night:448-449` |

### 7.2 Tote und doppelte Teile [B]

| Teil | Fundstelle | Zustand |
|---|---|---|
| Kreis-Verschiebe-Werkzeuge: `centerDot`-Drag, `dragHandle`-Overlay | `gh:1444-1541`, `gh:2099-2247` | tot (suchen `<svg>` in `#stage`, das selbst `svg` ist) |
| Dynamic-Circle-Panel | `gh:1545-1606` | tot (Markup fehlt) |
| `globalPush` | `gh:1615-1661` | inert (Einstellung wird nie geschrieben) |
| `#controlHub`-Drag, `#tSound`-Picker, `fontPreset` | `gh:1664-1715`, `gh:1771-1799`, `gh:1729-1768` | tot |
| In-Page-Setup-Modal (~400 Zeilen, inkl. doppelter Wolf/Solo-Listen mit Altname „Totenrat-Führer") | `gh:780-1210`, `gh:888-889`, `gh:1018-1019` | unerreichbar |
| Undo-v2-Stapel, `prophetProgressCheck` | `gh:2251-2315`, `gh:2043-2069` | inert, doppelt zu `state:94-110` |
| `hardReset`/`clearRolesNewRound` | `gh:484-529` und `app/public/legacy-bridge.js:15-51` | wörtliche Kopie, driftgefährdet |
| `ghostCasting`-Zweige | `chunk:31,216,218`, `help:265,271`, `night:4-5`, `ab:78` | tot (Flag wird nie `true`) |
| `PackfatherBlockNextDay`, `pending.judgeAsk`, `GrabrauberStolenRole`, `GebundenShown`, `pushDeathHook` | diverse | nie gelesen bzw. ohne Aufrufer |
| Streunendes `</script>` | `gh:1611` | harmlos |
| `alarmAudio` | `js/ui/audio.js:6` | nie benutzt |
| 7 SFX-Dateien, 6 Setup-Bilder, 6 Embleme, 2 Templates | siehe 6.1 | unbenutzt |
| `app/src/pixi/boardLayout.ts` (`computeGeometry`, `DEFAULT_LAYOUT`) | `:23,39` | toter Code |
| `app/README.md` erwähnt `mockAdapter.ts` | – | Datei existiert nicht |

### 7.3 Strukturelle Schulden [S]

1. **Kein DOM-freier Kern.** Regelcode ruft `document`, `$()`, `#overlay`, `localStorage` direkt (`night`, `chunk`, `ab`, `help`, `roles`, `js/core/i18n.js`, `state`).
2. **Monkey-Patch-Stapel** auf `draw`, `rebuildOrder`, `save`, `onNightStart`.
3. **Leise Fehler:** über 100 `try{...}catch(e){}` ohne Meldung.
4. **Text als Schnittstelle.** Die React-Schicht interpretiert gerenderte Texte; die EN-Übersetzung ersetzt Teilstrings im DOM (`js/core/i18n.js:716-1152`) und erzeugt Mischtexte wie „deadngericht".
5. **Kein ausführbarer Test.** `tests/smoke.js` prüft 8 Textstellen; `puppeteer` ist installiert, aber ungenutzt.
6. **Dokumentation widersprüchlich:** `ROADMAP.md` (Website-first, „75+ Rollen"), `INSTALL.md` (falsche Größen, Nachtmusik angeblich gitignored), `CLAUDE.md` (verweist auf `Werwolf/ROADMAP.md`).

---

## 8. Konsequenzen für die Migration [E]

1. **Regelverhalten nicht blind portieren.** Etwa 15 Rollen weichen zwischen Beschreibung und Code ab, 6 Solo-Siege fehlen, mehrere Bugs sind im Code verankert. Die Migration braucht eine Regelentscheidung pro Abweichung (`04`, `07`).
2. **Der Legacy-Stand bleibt die Referenz für verifizierte Regeln.** Für diese lassen sich Szenario-Tests aus dem Legacy-Code ableiten (Puppeteer ist bereits als Abhängigkeit vorhanden).
3. **Stabile IDs, Sitzreihenfolge getrennt von Sitz-ID, typisierte Effekte mit Quelle und Dauer, persistente Reaktions-Warteschlange, gesäter Zufall.** Das sind die fünf Datenmodell-Korrekturen, ohne die Determinismus, Undo und spätere Online-Synchronisation nicht erreichbar sind.
4. **Totenkarten und Abstimmung** sind Produktentscheidungen, keine Portierungsaufgaben: Beides existiert heute nur als Text bzw. SL-Direktwahl.
