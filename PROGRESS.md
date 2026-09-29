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

---

## 2026-09-27 — Cloud-zu-lokal-Integration (Branch `integration/cloud-to-local-20260927`)
Status: INTEGRIERT und per Fast-Forward nach main gebracht (`1bc8016`, gepusht); CI Godot (438 Tests) und Asset register grün
Quellen: Assets `55ad4d5`, UI `53a3c7d`, Rollenplanung `fc38043`; Korrekturen: CRLF im Rollenprüfer, 27 Screenshots im Register, Dokumentkonsistenz.
Verifiziert (Windows, Godot 4.7.2): 438 Godot-Tests grün, Register 299/299, 20 Node-Tests grün, Rollenprüfer und Schriftmuster ohne Befund; grafischer Start und skriptgesteuerter Setup-Ablauf ohne Fehler. Keine Tablet-Abnahme.
Details und offene Punkte: `docs/development/CLOUD-TO-LOCAL-HANDOFF.md` §0.
Masterplan-Status (Kopf, Phasen 0/1/2/4) und Gate A in PHASE-CHECKLISTS.md am 27.09. nach Belegen aktualisiert. OFL-Whitespace als Ausnahme in .gitattributes/FONTS.md dokumentiert.
Nächster Schritt: Sitzordnung im Setup (Phase 2), danach StartGame-Anbindung.

---

## 2026-09-27 — Setup-Schritt Sitzordnung (Branch `feature/setup-seating`)
Status: ERLEDIGT, PR #1 am 27.09.2026 mit Merge-Commit `f09cd08` nach main gemergt (CI auf main grün)
Inhalt: vierter Wizard-Schritt nach bestätigter Verteilung; `SeatingDraft` in `SetupDraft` (Personen-IDs im Uhrzeigersinn), `PlayerSetup.swap_seats`/`confirm_seating`; Sitzkreis mit Drag-and-drop und Tauschen per Antippen; „Sitzordnung fertig“ ohne StartGame/GameState. Details: `docs/ui/seating-setup.md`.
Verifiziert (Windows, Godot 4.7.2): 456 Godot-Tests grün (438 + 10 Modell + 8 UI), Register 308/308, 20 Node-Tests grün, Rollenprüfer ohne Befund, `git diff --check` Exit 0. Grafisch: 9 Aufnahmen `docs/evidence/seating-setup/` (lokal, AMD-Renderer), angesehen. Drag-and-drop mit simulierten Mausereignissen, keine Handbedienung, keine Touch- oder Tablet-Prüfung.
Nächster Schritt: StartGame aus dem bestätigten Setup-Entwurf bauen (`seat_order`, `roles`, `appearances`), ohne neue Regeln.

---

## 2026-09-27 — Spielstart aus dem Setup (Branch `feature/start-game`)
Status: ERLEDIGT, über PR #2 (Merge-Commit auf main, 28.09.2026) nach main übernommen
Inhalt: „Sitzordnung bestätigen“ beendet nur das Setup; danach steht in der Fußzeile „Partie starten“. Erst dieser Button sendet genau einen `StartGame` (manuelle Zuordnung aus der festen Verteilung, kein erneutes Mischen, Scheinrollen unverändert, Seed aus `PlayerSetup.seed_source`, `round_id` per SHA-256 aus dem Seed) über `GameStart` → `GameSession`. Nach Annahme ist der Entwurf verbraucht, das Cockpit öffnet sich als aktive Partie. Ablehnung lässt Setup und Sitzung unverändert und meldet den Grund. Details: `docs/ui/game-start.md`.
Verifiziert (Windows, Godot 4.7.2): 470 Godot-Tests grün (456 + 8 Modell + 6 UI), keine SCRIPT-ERROR- oder ERROR-Zeilen, Register 313/313, `git diff --check` Exit 0. Grafisch: 5 Aufnahmen `docs/evidence/game-start/` und neu `seating-setup/08` (lokal, AMD-Renderer), angesehen; dabei Layoutfehler (Tischmitte bei 24 Personen/1024×768) und widersprüchliche Cockpit-Hinweise gefunden und behoben. Keine Touch- oder Tablet-Prüfung.
Nicht enthalten: Speichern der Partie, Nacht-/Tagablauf in der Oberfläche, Beenden/Verwerfen einer laufenden Partie.
Nächster Schritt: Cockpit-Sitzkreis mit der gestarteten Partie (öffentliche Sicht aus `GameSession`, ohne Rollen) oder `StartNight` über das Cockpit, je nach Priorität.

---

## 2026-09-29 — Geführte Partie im Cockpit (Branch `feature/night-ui-expansion`)
Status: auf dem Branch fertig, nicht nach main gemergt. Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui`, Basis main `8197ee6` plus Merge von `audit/all-72-roles` (`312f5bb`, 71 Rollen im Kern).
Inhalt: Cockpit mit echter Partie (Sitzkreis ohne Rollen, Phasenleiste, Ansagekarte, private Ebenen, Sichtschutz); geführte Nacht für alle Prompt-Arten der 71 Rollen mit DE/EN-Vorlesetexten und Anweisungen; Morgenbericht öffentlich/privat mit Setup-Option `reveal_role_on_death` (DR-04, Schema 12); Tag mit Nominierung, verdeckter Hinrichtungsprüfung, Siegbestätigung, geheimen Tagesaktionen; Speichern mit Sicherung, Wiederaufnahme und „Fortsetzen“; Spielleitung mit Korrekturen, Undo/Redo, Beenden/Verwerfen; Bedienqualität (Tag/Nacht, Übergänge, Fokus). Testrunner wertet jeden Laufzeitfehler als Fehlschlag. Details: `docs/ui/cockpit.md`, `docs/ui/save-resume.md`.
Verifiziert (Windows, Godot 4.7.2, nur headless): 832 Tests grün, Exit 0, keine SCRIPT-ERROR-/ERROR-Zeilen; Assetregister Exit 0, darunter eine vollständige Partie nur über Buttons bis zum bestätigten Sieg und 142 Partien mit allen Rollen nur über Kartendaten. Keine grafische, Touch- oder Tablet-Prüfung.
Offen: Kartenschlucker und Totenkarten (RM-DR-013, RM-DR-141.4, RM-DR-143.x); Rollen zeigen (`ConfirmRoleShown`); Spezialkorrekturen ohne eigene Oberfläche; visuelle Abnahme am Tablet.
Nächster Schritt: gemeinsame Tablet-Abnahme des Cockpits (Anleitung in `docs/ui/cockpit.md`), danach Rollen-zeigen-Modus.

---

## 2026-09-29 — Review PR #3 (Fehler, Geheimhaltung, Speichern, Undo)
Status: Korrekturen auf `feature/night-ui-expansion`, nicht nach main gemergt.
Behoben: (1) Nach Rückgängig/Wiederholen blieb eine offene Tages- oder Korrekturbedienung stehen, etwa die Hinrichtungs-Prüfkarte mit Vorschau des alten Zustands; sie verfällt jetzt (`test_cockpit_day::test_undo_drops_open_execution_check`, vorher rot). (2) Die Rückfrage zu Rückgängig sagt jetzt, dass nur der Spielstand zurückgesetzt wird und Gezeigtes bekannt bleibt. (3) Das Protokoll trägt den Warnhinweis „Nur Spielleitung“. (4) „Karte zeigen“ und die Ansagekarte erhalten nur noch Positivliste bzw. öffentlichen Berichtsteil statt des ganzen Prompts/Berichts (Absicherung, vorher keine sichtbare Lücke).
Zusätzlich abgesichert (grün ab Beginn): beschädigte Datei ohne Sicherung, beschädigte Sicherung bei intakter Datei, Spielende mitten in der Nacht mit Neustart und Rückgängig, Rückgängig mit Neustart (Ereignisverlauf, kein Wiederholen). Testrunner-Gegenprobe: Laufzeitfehler nach bestandener Prüfung (synchron und nach `await`) ergibt FAIL und Exit 1; Probedateien entfernt.
Verifiziert (Windows, Godot 4.7.2, headless): 837 Tests, 0 fehlgeschlagen, Exit 0; Assetregister Exit 0; Rollendoku-Prüfer Exit 0; `git diff --check` Exit 0. Keine grafische, Touch- oder Tablet-Prüfung.
Grenzen (dokumentiert in `docs/ui/cockpit.md`): offene Reaktion ist am Morgen/Tag erkennbar (Phase, Hinweis, verdeckte Karte); aufgedeckte Rolle eines Toten ist seine aktuelle Rolle; Karte lässt Teilauswahlen zu, die der Kern ablehnt (Loki, Seelentauscher, Kutscher, Spürhund); „bedienbar“ = mit Kartendaten lösbar, nicht je Rolle mit erwartetem Ergebnis über Buttons geprüft; Spezialkorrekturen (Schutz, Rettung, Wolfskind, Lehrling) ohne Oberfläche.
Nächster Schritt: manueller PC-Fenstertest, danach Export-/Installationsweg für den iPad-Test klären.

---

## 2026-09-29 — Korrekturrunde PR #3 (Auswahl, Todesansage, Grenzen)
Status: auf `feature/night-ui-expansion`, nicht nach main gemergt.
Behoben: (1) Die Aktionskarte ließ Teilauswahlen bestätigen, die der Regelkern ablehnt (Loki, Seelentauscher, Kutscher: keiner oder alle; Spürhund: keiner oder drei; im Abdeckungslauf 178 Ablehnungen). Ursache: Die Karte kannte nur min/max. Jetzt liefert der Regelkern die zulässigen Anzahlen (`RulesEngine.target_counts`, von denselben Validatoren genutzt) und eine Prüfung ohne Anwenden (`RulesEngine.check`); die Karte nennt die Anzahl, sperrt „Auswahl bestätigen“ mit Erklärung und verwirft die Auswahl bei jeder Zustandsänderung. (2) Die Todesansage zeigte mit „Rolle aufdecken“ die aktuelle statt der Rolle beim Tod. Jetzt trägt `SeatDied` die Rolle beim Tod; kein Schemawechsel (Ereignisse entstehen beim Laden per Replay), Schema bleibt 12.
Nachweise: `test_target_selection` (vier Rollen über Sitzplätze und Buttons, Teilauswahl gesperrt und erklärt, vollständige Auswahl mit erwartetem Ergebnis, Auswahl verfällt bei Laden, Korrektur, Rückgängig/Wiederholen), `test_target_counts` (Kern: `check` = `apply`, manipulierte und veraltete Befehle abgelehnt), `test_prompt_coverage` jetzt mit genau einer Antwort je Prompt (0 Ablehnungen, 142 Partien), `test_morning_report` (Rollenänderung nach Tod, Wiederbelebung und zweiter Tod, Laden, Replay, ohne Aufdeckung keine Rolle). Neue Tests zuerst rot, Mutationsprobe für Sperre und Verwerfen rot.
Verifiziert (Windows, Godot 4.7.2, headless): 854 Tests, 0 fehlgeschlagen, Exit 0; weitere Prüfungen siehe PR-Beschreibung. Keine grafische, Touch- oder Tablet-Prüfung.
Grenzen: Abdeckungslauf bedient `GameSession` mit Kartendaten, Buttons nur in den genannten gezielten Tests; Spezialkorrekturen (Schutz, Rettung, Wolfskind, Lehrling) und „Rollen zeigen“ ohne Oberfläche; Wiederholbares nach Rückgängig entfällt beim Neustart; offene Reaktion bleibt am Morgen erkennbar (Produktfrage, unverändert).
Nächster Schritt: manueller PC-Fenstertest.

---

## 2026-09-29 — Vorbereitung manueller PC-Test PR #3
Status: vorbereitet, noch nicht durchgeführt. Anleitung `docs/ui/pc-test-pr3.md` (feste Partie mit acht Personen, Schritte A bis H), Fehlerliste `docs/ui/pc-test-pr3-fehlerliste.md`, Starter `PC-Test-starten.cmd` (Godot 4.7.2 aus Downloads, ohne Editor; `--check` prüft nur Pfade und Version).
Verifiziert: Partie der Anleitung headless über `GameSession` durchgespielt (temporärer Test, nicht versioniert); Starter mit `--check` Exit 0, fehlende Datei und falsche Version Exit 1; nicht grafisch gestartet. Kein Code geändert, daher keine erneute Volltestsuite.
Nächster Schritt: PC-Test durch den Nutzer, danach Befunde aus der Fehlerliste bearbeiten.
