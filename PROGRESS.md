# Grimmhain React — Stabilisierungs-Fortschritt

Arbeitsregeln: additiv, bevorzugt React/Adapter. Vanilla-Engine (`js/core`, `js/ui`)
nur lesen, Engine-Fix nur als begründete Ausnahme. Commit/Push/Deploy NUR an
Phasen-Gates. Verifikation mit echten Klicks (DE+EN).

---

## Phase 0 — Diagnose (State-Karte)
Status: ERLEDIGT
Verifiziert: n/a (nur Kartierung)
Commit: -  Deploy: -

### Wo der Spielzustand lebt
Globales `window.state` (Vanilla `js/core/state.js`), persistiert in localStorage
`uw_custom_v16`. Gelesen vom React-Layer über den Adapter (`app/src/adapter/legacy/legacyAdapter.ts`).

| Zustand | Ort |
|---|---|
| Phase Nacht/Tag | `state.dark` (true=Nacht) + `state.nightCount` |
| Sieg | `state.once.TeamWinner` ("village" / "wolves" / "solo_*"); Adapter liest es als `snapshot.winner` |
| Tot-Status | `seat.flags.dead` |
| Per-Nacht-Flags (Sitz) | `seat.flags` (targeted, nominated, burned, protected) + `seat.meta` (blockedTonight, killedTonight) |
| Per-Nacht-Flags (global) | `state.once.*Tonight` (PestUsedTonight, …), `state.once.NightUsedRoles`, `state.once.BlockedRolesTonight` |
| Einmal-pro-SPIEL benutzt | `state.once.Used["role_<Name>"]` via `isOnceUsed`/`markOnceUsed` (night.js:3–5) — Loki, König Lykaon, Wolfskind, Blutpriester usw. |
| Nachtreihenfolge „erledigt" | DOM-Klasse `.slot.night-used` (← `state.once.NightUsedRoles`). `parseNightOrder` (legacyAdapter.ts:154) leitet `done` daraus ab |
| Browse-Cursor (Ansicht) | React `viewedIndex` in `GameScreen.tsx` (lokal, entkoppelt vom Engine-Cursor) |
| Fraktions-Baseline | localStorage `grimmhain_faction_baseline`, in `GameScreen.tsx` einmal beim Rundenstart fixiert |

### Übergänge
| Übergang | Funktion |
|---|---|
| Nacht starten | Adapter `setPhase("night")` → `state.dark=true` + `w.onNightStart()` (night.js:130) |
| Nacht-Reset (Flags) | `onNightStart()` setzt Sitz-Per-Nacht-Flags + einige `once.*Tonight` zurück |
| Tag starten | Adapter `setPhase("day")` → `w.onDayStart()` (night.js:173) |
| Nächste Rolle (Cursor) | `parseNightOrder().find(e=>!e.done)`; Ansicht via React `viewedIndex` |
| Rolle ausführen | `goToNightStep(role)` → `w.onOrderClick(role)` |
| Lynch | `startLynch()` → `w.doLynchFlow()` |
| Neue Runde | `startGame`/`newGame` (createState, swap), `clearRoles`→`clearRolesNewRound`, `hardReset` |

### Nacht-Reset-Bug — Wurzel lokalisiert
`onNightStart()` (Engine) setzt Per-Nacht-Sitzflags zurück, ruft aber **nicht**
`resetNightStars()` auf. Damit bleiben `state.once.NightUsedRoles` + die
`.slot.night-used`-Klassen aus Nacht N erhalten. Da `parseNightOrder().done`
genau aus `.night-used` kommt, gelten in Nacht N+1 alle in Nacht N benutzten
Rollen weiter als „erledigt" → werden vom „Nächster Schritt"/Cursor übersprungen.
**Lösbar im Adapter** (kein Engine-Eingriff): nach `onNightStart()` zusätzlich
`resetNightStars()` + `rebuildOrder()`. Zusätzlich React-seitig: `viewedIndex`
bei Nachtbeginn auf 0.

---

## Phase 1 — State-Maschine wasserdicht
Status: ERLEDIGT
Geänderte Dateien:
- `app/src/adapter/legacy/legacyAdapter.ts` (setPhase("night") → resetNightStars()+rebuildOrder(); Sieg-Guard; Typ ergänzt)
- `app/src/screens/GameScreen.tsx` (Effekt: viewedIndex bei Nachtbeginn → 0; clearBaseline bei Hard-Reset/Rollen-leeren)
Was getan:
- 1.1 Nacht-Reset: Adapter ruft bei Nachteintritt `resetNightStars()`+`rebuildOrder()`. Verbrauchte Per-Nacht-Rollen sind in der Folgenacht frei.
- 1.2 Index/Cursor: Engine-Cursor + React-`viewedIndex` starten bei Rolle 1.
- 1.3 Tote Rollen: Engine baut die Order schon ohne tote Sitze (`rolesInGame()`/`rebuildOrder` filtern `!flags.dead`) — bestätigt im Verlauf (Jana tot → raus).
- 1.4 Temp/Dauerhaft: `onNightStart` räumt nur Nachtspuren, lässt Tode/Konvertierungen/Baseline stehen.
- 1.5 Sieg-Logik: Adapter-`setPhase` bricht ab, wenn `state.once.TeamWinner` gesetzt → nach Sieg keine neue Nacht/Tag. F5 nach Sieg startet keine Nacht.
- 1.6 Neue Runde: „Neue Runde" (Banner) + „Neues Spiel" löschen `uw_custom_v16` + `grimmhain_faction_baseline` und gehen ins frische Setup; Hard-Reset/Rollen-leeren räumen die Baseline mit.
- 1.7 Keine stillen Falsch-Auslöser: H5-Guards (Pick/Dialog) + Sieg-Guard + togglePhase canceln offene Aktion. Sichtbarer „gesperrt"-Hinweis folgt in Phase 2.2.
Verifiziert (DE/EN, echte Koordinaten-Klicks): JA.
- Nacht-Reset: EN (Nacht1→2) + DE (Nacht2→3): Rolle ausgeführt → `NightUsedRoles=[]` nach Nachtstart, Slot frei, Ansicht=Rolle 1.
- Sieg: Jana (einziger Wolf) gelynchT → `TeamWinner=village`, Banner; „→ Nacht/Tag" danach ohne Wirkung (frischer Adapter). F5: keine neue Nacht.
- Neue Runde: localStorage danach leer (uw_custom_v16=null, baseline=null), sauberes Setup.
- `tsc --noEmit` + `npm run build` grün.
Commit: <s.u.>  Deploy: grimmhain-spiel.vercel.app

BLOCKER: keine.

---

## Phase 2 — Spielleiter-Führung
Status: ERLEDIGT (Kern); Feinschliff 2.1/2.9 optional in Phase 4/5
Geänderte Dateien:
- `app/src/screens/GameScreen.tsx` (togglePhase blockiert + Toast; handleUndo mit Klartext-Diff via getSnapshot; clearBaseline)
- `app/src/adapter/legacy/legacyAdapter.ts` (Sieg-Guard schon aus Phase 1; undo() liefert Klartext-Summary)
- `app/src/adapter/GameAdapter.ts` (undo(): string|null)
- `app/src/styles/tokens.css` (`.phase-hint-toast`)
Neu + verifiziert (DE, echte Klicks):
- 2.2 Phasenwechsel bei offener Aktion BLOCKIERT + Toast „Erst die offene Fähigkeit abschließen oder mit ✕ abbrechen." (statt stillem Abbruch).
- 2.7 Rückgängig-KLARTEXT: Toast „Rückgängig: Tod von Anna zurückgenommen." (Diff Snapshot vorher/nachher via getSnapshot; erkennt Tode/Sieg/Phasenwechsel). Verifiziert: Anna gelyncht → Undo → Toast + Anna lebt.
Vorbestehend, im Test bestätigt:
- 2.3 Ziel-Highlight `.dom-token.pick-allowed` + Dimmen. 2.4 Multi-Fortschritt „noch N". 2.5 Info-Ergebnis (`action-center-result`). 2.6 Dialoge (DialogPanel/day-dialog). 2.8 Tag-Zusammenfassung („Niemand starb diese Nacht").
Feinschliff (erledigt + verifiziert DE):
- 2.1 „Nächster Schritt" springt jetzt zur nächsten NOCH-NICHT-erledigten Rolle (überspringt done-Slots) statt blind +1. Verifiziert: Wolfskind → Next überspringt erledigtes Schutzengel → Werwolf.
- 2.9 Lynch-Klartext: Toast „Gelyncht: <Name> (· Sieg!)" beim Lynch (Snapshot-Diff in onSeatTap). Verifiziert: Bert gelyncht → Toast „Gelyncht: Bert".
- Bonus (1.7/Klarheit): Spieler-Editor öffnet bei offener Zielwahl (Pick) nicht mehr versehentlich (onSeatTap-Guard `!allowedSeatIds`). Verifiziert: Lynch-Tap öffnet keinen Editor.
EN: Toast-Strings haben EN-Zweig (Code-Parität); vollständiger EN-Klick-Pass am Phase-3-Akzeptanz-Gate (das DE+EN ohnehin fordert).
Commit: <s.u.>  Deploy: grimmhain-spiel.vercel.app
BLOCKER: keine (2.7 doch im Adapter/React lösbar, kein Engine-Eingriff).

## Phase 3 — Teststrecke (Akzeptanz-Gate)
Status: KERN VERIFIZIERT; Breite ausstehend
Code-Änderung: KEINE (reine Verifikation, kein streckenbrechender Bug gefunden).
Vollständige Strecke EINMAL end-to-end (DE, 12 Spieler, echte Koordinaten-Klicks):
1. Nacht 1: Sonderrolle **Das Orakel** ausgeführt → Ziel Emil → Info-Ergebnis „Werwolf" GROSS angezeigt ✅ (2.5).
2. → Tag: Morgen-Zusammenfassung „Niemand starb diese Nacht." ✅ (2.8).
3. Lynch Anna (Dorf) → Toast „Gelyncht: Anna", kein Sieg ✅ (2.9).
4. → Nacht 2: `NightUsedRoles=[]`, kein „done"-Slot, Cursor=Loki ✅ (1.1/1.2). Die gelynchte Anna (=Das Orakel) ist NICHT mehr in der Reihenfolge ✅ (1.3 live).
5. Nacht 2: Schutzengel ausgeführt+bestätigt → **Rückgängig** → Toast „Letzte Aktion rückgängig gemacht.", Schutzengel wieder frei ✅ (2.7).
6. → Tag: Lynch Emil (einziger Wolf) → **Dorf-Sieg**, Toast „Gelyncht: Emil · Sieg!" + Sieg-Banner ✅ (1.5/2.9). „→ Nacht" danach ohne Wirkung ✅ (1.5).
7. „Neues Spiel" → Setup, localStorage geleert; Runde 2 ausgeteilt → bootet sauber (Nacht 1, kein Sieger, niemand tot, NightUsedRoles=[]) ✅ (1.6) → konsekutiver Neustart ohne Reststand.
EN-Vollstrecke (12 Spieler, echte Klicks) — VERIFIZIERT:
- The Oracle → Ziel Lena → Info „Werewolf" ✅; Tag „No one died this night." ✅; Lynch-Toast „Lynched: Lena · win!" ✅; Sieg-Banner „The village wins" + „New round/Close" ✅; ActionCenter-Texte/Phasen-Button englisch ✅.
- i18n-Morgen-Titel: GEFIXT (additiv im React-Layer, `localizeDialogTitle` in GameScreen) — EN zeigt jetzt „☀️ Night N — Dawn" statt „Nacht N — Morgengrauen". Verifiziert (EN). Kein Engine-Eingriff.
- Waldhexe-Entscheidung (Sonderrolle, in Akt I): VERIFIZIERT (DE) — 3 klare Choice-Buttons „Nicht retten / Schicksal bewahren / Tödliches Schicksal", Flow schließt sauber ab (Rolle danach night-used).
Breite NICHT abgeschlossen + Grund (ehrlich):
- 18/24/40 Spieler: Der kuratierte Akt-Rollen-Setup verlangt N DISTINCT Rollen ohne Stepper/„mit Dorfbewohnern füllen" in diesem Flow → >~17 Spieler über die UI nicht praktikabel automatisierbar. Funktionales Risiko gering: State-Maschine iteriert `state.seats` (sitzplatz-agnostisch), 12p verifiziert. Groß-Spielerzahl = primär VISUELL → Phase 4 (Ring-Auto-Fit). Empfehlung: in Phase 4 mit 24p visuell + funktional gemeinsam prüfen.
- 3× bis Sieg hintereinander: 1× Sieg DE + 1× Sieg EN + 1 sauberer Neustart belegt (kein Reststand). Volle 3×-Kette pro forma ausstehend.
- Exotische Sonderrollen (Doktor/Nekromant/Hades/Frankenstein/Dämonischer Wolf): NICHT in Akt I → brauchen CUSTOM-Set; eigener Spotcheck-Lauf. Setup-Automation für >~17 distinct Rollen/Custom-Sets ist über die UI zäh → bewusst als eigener Lauf zurückgestellt (kein funktionales Risiko bekannt; die Flows sind unveränderte Legacy). Abgedeckt: Orakel-Info DE+EN, Schutzengel, Spürhund (3 Ziele), Werwolf, Lynch→Sieg, Waldhexe (3-Wege-Entscheidung).
Verifiziert (echte Klicks): DE Kernstrecke + EN Vollstrecke. Breite (Spielerzahl/exotische Rollen): dokumentiert offen.
Commit: <PROGRESS-Doku>  Deploy: - (kein Code-Change)
BLOCKER: keiner funktional. Hinweis: Groß-Spielerzahl-Setup über die Akt-UI ist umständlich (Phase-4-Thema).

## Phase 4 — ActionCenter + Spielerkreis (Tablet / 24 Spieler)
Status: KERN ERLEDIGT + verifiziert; Rest-Polish offen
Geänderte Dateien: `app/src/components/DomBoard.tsx` (Ring-Clearance: Kreis → reale BOX).
Was getan (#6, Kernpunkt):
- Ring-Clearance gegen das Zentral-Element nutzt jetzt die ECHTE Bounding-BOX (Laufzeit gemessen: `lynch-button`/`action-center`), nicht mehr den einbeschriebenen Kreis. AABB-Push: Tokens innerhalb der erweiterten Box (Halbmaße + ~24px + Token-Radius) werden radial an den Box-Rand geschoben. Das breite ActionCenter-Panel wird so links/rechts nicht mehr von Tokens überlappt.
Verifiziert (echte Klicks/Messung, 24 Spieler via „+ Sitzkreis", DE, Nacht mit offenem ActionCenter):
- 4:3 (1366×1024): 24 Tokens (84px), **0 Overlaps** mit der Panel-Box, kein Name/Token verdeckt, Nachtleiste schneidet keine Namen, „Fähigkeit ausführen" sitzt in der Pille.
- 16:10 (1280×800): Auto-Fit verkleinert Tokens auf 58px, **0 Overlaps, 0 abgeschnitten**.
- → #1 (Button in Pille), #2 (Panel verdeckt nichts), #6 (Box-Clearance), #7 (Ring nutzt Platz, kein Clipping) erfüllt.
Vorbestehend (im Test gesehen): #8 Status-Ringe/aktives-Ziel-Glow + Dimmen verbotener Ziele + Tot-Overlay; #9 Token-Größe-Regler (einziger manueller Regler); #10 Nachtleiste schneidet keine Namen.
Rest-Polish — ERLEDIGT + verifiziert (DE, echte Klicks):
- #3 Rollen-Beschreibung: lesbarer Boden 14px (vorher Schrumpf bis 6px); lange Texte werden auf 4 Zeilen geklammert + „▼ mehr"/„▲ weniger"-Umschalter (Details on demand, expandierte Beschreibung scrollbar im Rechteck, Ausführen-Button bleibt sichtbar). Verifiziert: Loki/Spürhund passen ohne Toggle; Waldhexe (172 Zeichen) → Toggle erscheint → expandiert/kollabiert.
- #5 „Fähigkeit ausführen" (gold, im Panel-Pill) vs „Nächster Schritt" (dunkelrot, eigene Art, unten rechts): klar getrennt nach Ort + Farbe + Label — visuell bestätigt, kein Umbau nötig.
- Tag-Medaillon nutzt dieselbe Box-Clearance (kleinere quadratische Box) — Code identisch, Nacht (breites Panel) ist der harte Fall und ist verifiziert.
→ Phase 4 vollständig (Kern + Polish).
Commit: <s.u.>  Deploy: grimmhain-spiel.vercel.app
BLOCKER: keine.

## Phase 5 — Robustheit (niedrigste Prio)
Status: GESTARTET (Diagnose + erste Quick-Wins); Rest offen
Geänderte Dateien: `app/src/components/PlayerEditor.tsx` (Tot-Sicherheitsfrage).
Diagnose (PlayerEditor.tsx, Protokoll, Setup):
- Editor-Rolle ist ein FREIES Text-Input (`<input>`, onBlur→setPlayerRole) → Tippfehler-Risiko. Echte Auswahl/Dropdown braucht die Rollenliste (~72) + Adapter-Plumbing.
Erledigt + verifiziert (DE, echte Klicks):
- „Tot setzen"-Sicherheitsfrage: Toggle „☠ tot" fragt jetzt per `window.confirm` nach (klarstellend: manuelle Markierung, keine Auto-Todesfolgen). Verifiziert: Frage erscheint, bei „OK" wird das Flag gesetzt, bei Abbruch nicht.
- Editor öffnet NICHT mehr versehentlich bei Zielwahl: bereits in Phase 2 gelöst (onSeatTap-Guard `!allowedSeatIds`).
- Fortsetzen nach Neuladen: funktioniert (über die Session vielfach beobachtet — Reload des Boards behält den Stand; resumeRound).
- Editor-Rollen-Auswahl statt Freitext: ERLEDIGT + verifiziert (ehem. BLOCKER, Entscheidung „a"). Neue Adapter-Methode `listRoles()` (über `getAktRollen("custom")` = alle 72 + `getRoleName`/`getRoleFaction`); Editor-Freitext → `<select>` gruppiert nach Dorf/Werwölfe/Solo mit lokalisierten Namen, Wert = Rollen-ID. Verifiziert: 72 Optionen, aktuelle Rolle vorausgewählt, Wechsel setzt `seat.role` auf die ID (nicht Anzeigename) + Wolf-Flag rechnet neu. Behebt nebenbei den alten Freitext-Bug (setzte den lokalisierten Anzeigenamen als Rolle).
Rest — ERLEDIGT + verifiziert (DE/EN, echte Klicks):
- Manuelle Editor-Änderungen → Protokoll: setPlayerFlag/Role/Name schreiben einen ✏️-Eintrag direkt in `gameLog.entries` (der Recap-Filter `shouldLogRecap` lässt ✏️ sonst fallen). Verifiziert: „✏️ Carl — protected on".
- Protokoll-Gruppierung: ProtocolDrawer gruppiert die Einträge an den Phasen-Markern (🌙 Nacht / ☀️ Tag) unter Sektions-Headern (sticky, scrollbar); manuelle Einträge optisch markiert (`.is-manual`). Verifiziert: Sektion „🌙 Night 2 begins" mit dem ✏️-Eintrag. Sieg ist über das 🏆-Log + Banner begründet.
- „+ Sitzkreis" Sicherheitsfrage: `window.confirm` vor der Spielerzahl-Änderung. Verifiziert: Abbruch hält die Sitzzahl (24→24), Bestätigung würde vergrößern.
→ Phase 5 abgeschlossen.
Komfort-Nachzug (erledigt + verifiziert): Rückgängig wird jetzt zusätzlich als ↩️-Eintrag ins Protokoll geschrieben und dort markiert (nicht nur Toast). Verifiziert: „↩️ Undone: death of Dora reverted." nach Lynch+Undo.
Commit: <s.u.>  Deploy: grimmhain-spiel.vercel.app
BLOCKER: keiner.

---

## 2026-09-27 — Claude-Arbeitsstack (Godot-Neuentwicklung)
Hinweis: Die Phasen oben betreffen die Legacy-React-App. Aktive Entwicklung ist `godot/` (siehe `CLAUDE.md`).
Status: ERLEDIGT
Commit: `6af60d4` (main, gepusht nach origin/main); Doku-Nachtrag `a9fbf07` (PROGRESS/LESSONS, gepusht)
Inhalt:
- `CLAUDE.md` als Arbeitsvertrag neu gefasst; `DECISIONS.md` und `LESSONS.md` angelegt.
- Projekt-Skills unter `.claude/skills/` (grimmhain-core/-tablet-ui/-assets/-handoff, godot-gdscript/-ui-control/-animation/-audio, art-bible, performance-optimization, verify-and-stop).
- `docs/development/`: `CLAUDE-STACK.md`, `CLOUD-TO-LOCAL-HANDOFF.md`, `SKILLS-SH-AUSWAHL.md`, Cloud-Berichte 2026-09-27, Skill-Quellen mit Lizenzen und Lock-Datei.
- `godot/project.godot`: Editor-Neuspeicherung (Schlüssel umsortiert, Kopfkommentar entfernt, `emulate_mouse_from_touch=true` und `locale/fallback="en"` entfernt; beides Godot-Standardwerte).
Verifiziert: `git diff --cached --check` Exit 0; Push Exit 0. Keine Godot-Tests ausgeführt (keine Code-Änderung).
Nächste Schritte:
- Einmal `bash godot/tests/run_all.sh` bzw. Windows-Checks laufen lassen, um die `project.godot`-Neuspeicherung zu bestätigen (Touch-Emulation, EN-Fallback).
- Die drei Cloud-Berichte (`docs/development/cloud-reports/2026-09-27/`) gegen tatsächliche Commitstände abgleichen (`grimmhain-handoff`).
BLOCKER: keiner.
