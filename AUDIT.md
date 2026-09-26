# AUDIT — Grimmhain Spielleiter-App

**Datum:** 2026-05-30
**Art:** Reine Bestandsaufnahme (read-only). Keine Code-Änderung.
**Audit-Verzeichnis:** `C:\Users\Marku\Desktop\Grimmhain` (Git-Branch `main`).

> Hinweis: Der Auftrag nennt `Desktop/Werwolf/`. Dieses Verzeichnis ist nicht das aktive Repo. Audit wurde im tatsächlichen Arbeits- und Git-Verzeichnis `Desktop/Grimmhain` durchgeführt (dort liegen `CLAUDE.md`, `.git`, der Quellcode). [unsicher: ob ein separates `Werwolf/` mit der Marketing-Website gemeint war — die hier auditierte App ist „Produkt 2" aus `ROADMAP.md`.]

---

## 1. Stack & Versionen

| Thema | Befund | Beleg |
|---|---|---|
| App-Typ | Statische Vanilla-HTML/CSS/JS-App, kein Framework, kein Build | `index.html`, `setup.html`, `game.html`; `CLAUDE.md` „Kein Build-System erforderlich" |
| 3 Seiten | `index.html` (442 Z.) Spielerzahl/Sprache → `setup.html` (1111 Z.) Akt/Rollen → `game.html` (2669 Z.) Spielleiter-Interface | `wc -l` |
| JS-Schichten | `js/core/` (portable Logik, 10 Dateien) + `js/ui/` (DOM-Layer, 4 Dateien) | Dateibaum |
| Persistenz | `localStorage`, Key `uw_custom_v16` | `js/core/state.js:1` |
| package.json | nur `test`-Script (`node tests/smoke.js`), eine devDep `puppeteer ^24.40.0` | `package.json:5-10` |
| Tests | 1 reiner Datei-Grep-Smoketest (kein Browser, nutzt **kein** puppeteer) | `tests/smoke.js` |
| Deployment | Vercel (`.vercel/`-Ordner, `.vercelignore` vorhanden) | Filesystem-Listing |
| Capacitor/iOS | **Kein Capacitor im Repo** — kein `capacitor.config.*`, kein `www/`, kein `ios/`, keine Capacitor-Dependency | `git ls-files`, `package.json` |
| i18n | Eigenes System, ~638 Schlüssel je Sprache, DE/EN | `js/core/i18n.js`; `grep -c` |

**Wertung:** Der im Auftrag genannte „drei-Lokationen-Sync (root → www/ → cap sync ios)" ist im auditierten Repo **nicht abgebildet**. Hier ist es eine reine statische Web-App mit Vercel-Deploy. [unsicher: Capacitor-Wrapper existiert evtl. in einem anderen Ordner außerhalb dieses Repos.]

---

## 2. Projektstruktur

```
Grimmhain/
├── index.html              Startseite (Spielerzahl + Sprache)
├── setup.html              Akt-Wahl, Namen, Rollenzuweisung, Review
├── game.html               Spielleiter-Hauptinterface (größte Datei, 2669 Z.)
├── js/
│   ├── core/               PORTABLE Logik (lädt teils DOM-abhängig, s. Abschnitt 6)
│   │   ├── state.js        (125) GameState, localStorage, Migration, Undo-Snapshot
│   │   ├── roles.js        (451) 72 Rollen, Fraktions-Sets, Beschreibungen DE/EN, Tags
│   │   ├── role-abilities.js(79) Fähigkeitstexte (DE) als Nachschlage-Objekt
│   │   ├── akte.js         (144) 4 Akt-Sets + Custom (nur in setup.html geladen)
│   │   ├── cards.js        (819) Totenkarten-Daten (80 Karten) + Helfer
│   │   ├── night.js        (664) Nacht/Tag-Ablauf, Lynch, Order-Render, SL-Assistent
│   │   ├── abilities.js    (121) Merge-Punkt + Rotkäppchen/Hades + Suche + onOrderClick
│   │   ├── abilities-helpers.js (287) Totenkarten-UI, Sensenträger, Waldhexe-Dialog
│   │   ├── abilities-roles-chunk.js (858) Fähigkeits-Handler der meisten Rollen
│   │   └── i18n.js         (1143) Übersetzungen DE/EN
│   └── ui/
│       ├── core.js         (443) isWolf, applyKill, Siegbedingungen, Tod-Hooks
│       ├── ui.js           (434) Sitzkreis (SVG), Pick-Bar, Tod-Overlays, draw()
│       ├── audio.js        (115) SFX-Queue, Nachtmusik, Timer
│       └── gamelog.js      (138) Recap-Spielprotokoll
├── css/  tokens.css(70) · main.css(1972) · screens.css(385)
├── assets/  cards/de(76 PNG) cards/en(72 PNG) · sounds(10) · fonts(4) · icons · Tag/Nacht.png
├── tools/  compare-i18n.js · create_role_doc.py · fix_v42_night_order.py · update_night_order_html.py
├── tests/  smoke.js
└── docs/   README.md · ASSETS.md
```

**Skript-Ladereihenfolge** (entscheidend, da alles über globale Symbole läuft):
- `game.html:26-38`: i18n → roles → role-abilities → cards → state → ui/core → ui/audio → ui/ui → abilities-helpers → abilities-roles-chunk → abilities → night → gamelog.
- `setup.html:557-561`: i18n → roles → **akte** → cards → state.
- `index.html:257-260`: i18n → roles → cards → state.

`akte.js` wird **nur** in `setup.html:559` geladen (Akt-System gehört zur Rollenauswahl, nicht zur Spielsteuerung) — korrekt, nicht fehlend.

---

## 3. Feature-Inventar (im Code real vorhanden)

| Feature | Status | Beleg |
|---|---|---|
| Rollenlogik (72 Rollen) | vorhanden | `js/core/roles.js:1` (`ALL_ROLES`), Handler in `js/core/abilities-roles-chunk.js` |
| Nacht-Reihenfolge (automatisch, tier-basiert) | vorhanden | `roles.js:3` `ORDER_BASE`; Aufbau in `night.js:22` `rebuildOrder()` |
| Akt-System Akt I–IV + Custom | vorhanden | `js/core/akte.js:6` `AKTE` (akt1–akt4 + custom) |
| Totenreichkarten (Post-Tod-Buffs, 80 Karten) | vorhanden | `js/core/cards.js`; Vergabe `abilities-helpers.js:5` `assignTotenkarten`, Anzeige `abilities-helpers.js:98` `showTodesscreen` |
| Kartenschlucker-Stapelmechanik | vorhanden | `abilities-helpers.js:167-188`, Sieg `js/ui/core.js:228` |
| Timer (mm:ss, Start/Pause/Reset, Endton) | vorhanden | `js/ui/audio.js:59-115`; Buttons `game.html` (`gameTimerStartBtn` etc.) |
| Audio: Nachtmusik (loop, Position gespeichert) | vorhanden | `night.js:137-142`, `night.js:168-173` |
| Audio: rollenbezogene SFX (Queue) | vorhanden, **teils kaputte Dateipfade** (Abschnitt 6) | `js/ui/audio.js:3-57` |
| Suche/Filter (Name oder Rolle, Sitz-Puls) | vorhanden | `js/core/abilities.js:60-69` |
| Undo (1 Schritt, Snapshot/Restore) | vorhanden (genau 1 Schritt, nicht 5) | `state.js:119-121` `snapshot`/`undoOnce` |
| Sitzkreis-Visualisierung (SVG, Fraktionsfarben) | vorhanden | `js/ui/ui.js:95` `draw()` |
| Auto-Fit-Layout (Sitze automatisch einpassen) | vorhanden | `ui.js:320` `autoFit()` |
| Spielprotokoll / Recap-Log (gefiltert, Copy) | vorhanden | `js/ui/gamelog.js` |
| SL-Assistent (Schritt-für-Schritt durch Nachtordnung) | vorhanden | `night.js:533-664` |
| Lynch-Flow inkl. Sonderfälle | vorhanden | `night.js:357` `doLynchFlow()` |
| Siegbedingungen (Team + diverse Solo-Siege) | vorhanden | `js/ui/core.js:205` `checkWinConditions`, `:272` `checkTeamWin` |
| Mehrsprachigkeit DE/EN (Laufzeit-Umschaltung) | vorhanden | `js/core/i18n.js` |
| Rollen-Tooltips / Info-Popups | vorhanden | `roles.js:336-450` |
| Legacy-Rollennamen-Migration beim Laden | vorhanden | `state.js:16-45` `migrateLegacyRoleIds` |

---

## 4. Datenmodell

**Rollen** — `js/core/roles.js`:
- `ALL_ROLES` (`roles.js:1`): 72 Rollennamen (deutsche IDs als Strings, kein Objekt mit Metadaten).
- Beschreibungen: `window.ROLE_DESCRIPTIONS` (`roles.js:63`) + `ROLE_DESCRIPTIONS_EN` (`roles.js:212`) + `ROLE_NAMES_EN` (`roles.js:137`).
- Fähigkeitstexte separat: `ROLE_ABILITIES` (`role-abilities.js:2`, nur DE).
- **Format-Risiko:** Rollendaten sind über mehrere parallele Objekte verteilt (Name-EN, Desc-DE, Desc-EN, Ability-DE, Tags), per Hand synchron zu halten. Keine einzelne `Role`-Struktur.

**Fraktionen** — `js/core/roles.js`:
- `WOLF_ROLES_SET` (`roles.js:391`, 19 Wolfsrollen), `SOLO_ROLES_SET` / `window.SOLO_WIN_ROLES` (`roles.js:399`, 14 Solo-Rollen).
- Auflösung: `getRoleFaction()` (`roles.js:405`) → `wolf` / `solo` / sonst `dorf`. `night.js:9` delegiert daran (kein Hardcode mehr).
- Zweite, **abweichende** Wolf-Definition als Heuristik: `isWolf()` in `js/ui/core.js:8` (Regex `/wolf/i` + Sonderfälle + `cursedWolfAura`). Zwei Wahrheiten nebeneinander (Set vs. Heuristik) → siehe Abschnitt 6.

**Totenkarten** — `js/core/cards.js`:
- `TOTENKARTEN` nach Kategorie. Gezählt: 80 Karten in 6 Kategorien — SEGEN 14, FLUCH 13, SCHICKSAL 14, SOLO 14, WENDE 12, LOKI 13 (`grep kategorie`).
- Jede Karte: `id`, `kategorie`, `name`, fraktionsabhängige Texte (`wolf`/`dorf` u.a.).
- Laufzeit-Zustand pro Sitz in `state.once.totenkarten[seatId] = {karteId, gespielt, shown}`.

**Akte** — `js/core/akte.js:6`: 4 kuratierte Sets (Dorf/Wolf/Solo-Aufteilung) + `custom` (alle Rollen). Selbstvalidierung beim Laden gegen `ALL_ROLES` (`akte.js:123-144`).

**Vollständigkeit:** Akt-Kommentar behauptet „72/72 Rollen abgedeckt" (`akte.js:3`). Eine Validierungsfunktion existiert und würde fehlende Rollen in der Konsole melden (`akte.js:131-137`). Inhaltlich-numerische Gegenprüfung pro Akt wurde in diesem Audit nicht durchgerechnet → [unsicher, aber durch eingebaute Validierung abgesichert].

**State-Schema** — `js/core/state.js:9-13` (`createState`): `seats[]` (`id,name,role,flags{...},meta{...}`), `once{...}` (sehr großer Flag-Beutel für Einmal-Effekte, Totenkarten, Solo-Zähler), `dark`, `nightCount`, `fenrirStage`, `layout`, `files`, `ui`, `pending`. Migration füllt fehlende `once`-Felder auf (`state.js:47-62`).

---

## 5. Zustand & Reife pro Feature

| Feature | Reife | Begründung (Beleg) |
|---|---|---|
| Sitzkreis / draw / Pick-System | fertig | vollständig, stabil aufgebaut, `ui.js:95`/`:276` |
| Nacht-Ordnung + dynamische Filter | fertig | umfangreiche Bedingungslogik `night.js:50-119` |
| Rollen-Fähigkeiten (Mehrheit) | fertig | Handler für ~50 aktive Rollen in `abilities-roles-chunk.js` |
| Totenkarten | fertig | Vergabe/Anzeige/Neuziehen vollständig `abilities-helpers.js` |
| Siegbedingungen | weitgehend fertig, redundant | `checkWinConditions` (`core.js:205`) **und** `checkTeamWin` (`core.js:272`) prüfen teils dasselbe doppelt mit leicht anderer Wolf-Definition |
| Timer | fertig | `audio.js:59-115` |
| Audio-SFX | halbfertig | Code ok, aber 3 referenzierte Sounddateien fehlen (Abschnitt 6) |
| i18n | halbfertig | 638 Keys, aber Prüf-Tool defekt → Drift nicht messbar (Abschnitt 6) |
| SL-Assistent | fertig | `night.js:533-664` |
| Undo | fertig (bewusst 1 Schritt) | `state.js:119-121`; Text wurde laut `FIX_REPORT.md:9` auf „letzter Schritt" korrigiert |
| „Totenrat-Führer"-Tagessieg/Reveal-UI | **toter Pfad** | Rolle wurde zu „Nekromant" migriert (`state.js:18`); UI in `ui.js:243-250` und Buttons `game.html` keyen auf den **alten** String `"Totenrat-Führer"`, der nie mehr vergeben wird → Buttons erscheinen nie. Nekromant-Nacht-Umlenkung (`night.js:322-336`) funktioniert dagegen. |
| Mobile/Portrait | offen/Platzhalter | Landscape-Annahme; lt. `ROADMAP.md:165-168` „auf <600px kein Spielkreis", Portrait fehlt |
| 10 Kickstarter-Rollen | nicht vorhanden | lt. `ROADMAP.md:170-173` noch nicht konzipiert |

---

## 6. Tech-Schulden & Risiken

1. **Fehlende Sound-Dateien (Live-relevant).** `js/ui/audio.js:3-13` referenziert `Alarm.mp3` (Nachtwächter-Alarm, `sfxBear`), `WahnsinnigKutscher.mp3`, `Loki.mp3` (Liebespaar-Tod, `sfxLovers`). Im Ordner `assets/sounds/` liegen diese **nicht**; stattdessen verwaiste `Amor.mp3` und `Bärenführer.mp3` (alte Namen). Folge: Alarmglocke und Liebespaar-Sound spielen im echten Spiel nicht. Beleg: `ls assets/sounds/` vs. `audio.js:3-13`, Aufruf `night.js:503` (`sfxBear`), `core.js:383` (`sfxLovers`).
2. **Defektes i18n-Prüfwerkzeug.** `node tools/compare-i18n.js` bricht ab (`TypeError: window.addEventListener is not a function`), weil der vm-Sandbox-`window` die in `i18n.js:1135` genutzte `addEventListener`-API nicht stellt. Das in `CLAUDE.md` empfohlene Drift-Tool liefert also keine Ergebnisse mehr.
3. **Zwei konkurrierende Wolf-Definitionen.** `WOLF_ROLES_SET` (`roles.js:391`, autoritativ) vs. Regex-Heuristik `isWolf()` (`core.js:8`) vs. eigene Inline-Liste `_allWolf` in `abilities.js:74` und nochmals in `ui.js:131`. Mehrfachpflege, Divergenzgefahr bei neuen Rollen.
4. **Toter „Totenrat-Führer"-Code** (s. Abschnitt 5): UI-Zweig und Buttons ohne erreichbaren Zustand. `markerList` (`ui.js:93`) und `ui.js:243-250` referenzieren die alte Rolle.
5. **„core ist nicht DOM-frei."** Projektziel (`CLAUDE.md`: „`js/core/` darf kein DOM enthalten"). Tatsächlich greifen `state.js:75/89`, `abilities.js`, `abilities-helpers.js`, `night.js` direkt auf `document`, `localStorage`, `Audio` zu. Die portable Schicht ist faktisch DOM-gebunden → erschwert die in `ROADMAP.md` geplante Portierung.
6. **Globale Kopplung über `window`.** Kein Modulsystem; gesamte Architektur hängt an Skript-Ladereihenfolge (`game.html:26-38`) und globalen Funktionen. Eine vertauschte Reihenfolge bricht alles still (viele `typeof x==="function"`-Guards als Symptom).
7. **`game.html` ist ein 2669-Zeilen-Monolith** mit ~30 Inline-`<script>`-Blöcken (`grep <script game.html`). Logik liegt teils dort, teils in `js/` — erschwert Auffinden/Review.
8. **`once`-Flag-Beutel.** Dutzende ad-hoc Felder in `state.once` (`state.js:10`, `:51-58`); Reset-Listen müssen manuell gepflegt werden (`FIX_REPORT.md:7` zählt 14 Felder, die zuvor beim Rundenreset vergessen wurden) → wiederkehrende Quelle für „klebrige" Zustände zwischen Runden.
9. **Breites `try/catch`-Schlucken.** Sehr viele leere `catch(e){}` (z.B. `core.js`, `night.js`, `ui.js`) verbergen Laufzeitfehler — gut für „nie hart abstürzen", schlecht für Diagnose während einer Live-Session.
10. **`abilities.js`/`abilities-roles-chunk.js` Refactor-Schuld** wie in `CLAUDE.md`/`ROADMAP.md:183` notiert; Handler-Datei 858 Zeilen, viele Einzeiler mit hoher Verschachtelung.
11. **Stale Doku-Aussagen.** `CLAUDE.md`/`ROADMAP.md` nennen „doppelte Ordner `/icons`+`/assets/icons`, `/Sounds`+`/assets/sounds`" — diese Root-Duplikate existieren **nicht mehr** (`ls`); der Punkt ist erledigt, aber noch als offen dokumentiert. Außerdem nennt `state.js:1` Key `uw_custom_v16`, `CLAUDE.md` ebenfalls — konsistent.
12. **Untracked Analyse-Altlast** `ANALYSE_BERICHT.md` (20 KB) im Root, nicht in Git (`git status`). Nicht angefasst.

---

## 7. Reibungspunkte für die Live-Session

1. **Audio-Lücken (s.o.).** Der Nachtwächter-Alarm — ein öffentliches, lautes Signal, das Mitspieler hören sollen — spielt mangels `Alarm.mp3` nicht. Für eine Tisch-Session der spürbarste Defekt.
2. **Einhand-Bedienung.** Kerngesten sind groß und mittig (Sitz antippen, zentraler Lynch-Button skaliert mit Kreis, `ui.js:120-126`). Aber: viele Aktionen laufen über **modale Overlays mit mehreren kleinen Buttons** (`mbtns`, z.B. Waldhexe `abilities-roles-chunk.js:208`, Hades `abilities.js:27`). Mehrstufige Dialoge sind im Halbdunkel mit Daumen fummelig.
3. **Lesbarkeit im Dunkeln.** Modal-Text skaliert dynamisch groß (`ui.js:294` `fitModalText`, bis 216px) — gut. Sitz-Beschriftungen skalieren mit Sitzradius (`ui.js:166-170`); bei vielen Spielern werden Name+Rolle klein. Tod-Overlays sind kontrastreich weiß-auf-dunkel (`ui.js:375-389`) — gut.
4. **Tempo beim Rollen-Nachschlagen.** Schnellzugriff vorhanden: Such-Box (Name/Rolle) `abilities.js:60`, ❓-Info-Buttons je Nachtordnungs-Zeile `night.js:103-112`, Hover-Tooltips `roles.js:359`. Solide. Einschränkung: Tooltips sind Hover (Maus) — auf Touch greift nur der ❓-Tap, nicht das Hover.
5. **SL-Assistent** führt sequenziell durch die Nacht (`night.js:602-625`) — reduziert „welche Rolle kommt jetzt?"-Last. Gutes Live-Feature.
6. **Mobile/Portrait** real nicht nutzbar (Landscape-Annahme, `ROADMAP.md:165`). Am Tisch auf dem Handy hochkant problematisch.
7. **Stille Fehler.** Wegen der vielen leeren `catch` kann eine Aktion „nichts tun" ohne Hinweis — der Spielleiter merkt mitten in der Runde nicht, dass ein Schritt ins Leere lief.

---

## 8. Empfehlungen (nur Liste, nichts umgesetzt) — nach Aufwand/Wirkung

**Hoher Hebel, kleiner Aufwand**
1. Fehlende Sounds beheben: entweder Dateien `Alarm.mp3`/`WahnsinnigKutscher.mp3`/`Loki.mp3` ergänzen **oder** `audio.js:3-13` auf die vorhandenen Namen (`Bärenführer.mp3`, `Amor.mp3`) mappen. (Abschnitt 6.1)
2. `tools/compare-i18n.js` reparieren (vm-`window` mit `addEventListener: ()=>{}` stubben), dann i18n-Drift DE↔EN einmal messen. (6.2)
3. Toten „Totenrat-Führer"-UI-Zweig entfernen oder auf „Nekromant" umstellen (`ui.js:243-250`, Buttons in `game.html`). (5/6.4)
4. `ROADMAP.md`/`CLAUDE.md` „doppelte Asset-Ordner" als erledigt markieren. (6.11)

**Mittlerer Aufwand, mittlere/hohe Wirkung**
5. Wolf-Definition vereinheitlichen: `isWolf()` und alle Inline-Wolf-Listen (`abilities.js:74`, `ui.js:131`) aus `WOLF_ROLES_SET` ableiten. (6.3)
6. Leere `catch`-Blöcke an spielentscheidenden Stellen durch sichtbares `center(...)`/Log ersetzen, damit Live-Fehler nicht stumm bleiben. (6.9/7.7)
7. Touch-Tooltips: Hover-Beschreibungen (`roles.js:359`) auch per Tap/Long-Press verfügbar machen. (7.4)
8. Sieg-Prüfung konsolidieren: `checkWinConditions` und `checkTeamWin` auf eine Quelle reduzieren. (5)

**Größerer Aufwand**
9. `js/core/` echt DOM-frei machen (DOM/Audio/localStorage hinter Adapter), Voraussetzung für die geplante App-/Online-Portierung. (6.5, `CLAUDE.md`-Ziel)
10. `game.html`-Inline-Skripte in `js/`-Module auslagern; `abilities-roles-chunk.js` aufteilen. (6.7/6.10)
11. Portrait/Mobile-Layout für Tischnutzung. (7.6, `ROADMAP.md:165`)
12. `state.once`-Flag-Beutel in benannte Teilzustände gliedern + zentrale Rundenreset-Funktion, um vergessene Felder strukturell auszuschließen. (6.8)

---

### Anhang — geprüfte Dateien
`package.json`, `tests/smoke.js` (lief: OK), `tools/compare-i18n.js` (lief: Fehler), `ROADMAP.md`, `FIX_REPORT.md`, `CLAUDE.md`,
`js/core/state.js`, `roles.js`, `role-abilities.js`, `akte.js`, `abilities.js`, `abilities-helpers.js`, `night.js`, (Auszüge `abilities-roles-chunk.js`, `cards.js`, `i18n.js`),
`js/ui/core.js`, `ui.js`, `audio.js`, `gamelog.js`,
Skript-Ladereihenfolge in `index.html`/`setup.html`/`game.html`, Datei-/Asset-Listing (`git ls-files`, `ls assets/sounds`).
