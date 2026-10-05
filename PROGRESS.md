# Grimmhain React — Stabilisierungs-Fortschritt

Arbeitsregeln: additiv, bevorzugt React/Adapter. Vanilla-Engine (`js/core`, `js/ui`)
nur lesen, Engine-Fix nur als begründete Ausnahme. Commit/Push/Deploy NUR an
Phasen-Gates. Verifikation mit echten Klicks (DE+EN).

## 2026-10-05: Abschluss Nachtschritte neu, gemergt nach main
Stand: Aufgeraeumt (Schluessel `ui.night.reaction.*` ueber die gemeinsame Vorlage `ui.night.<besitzer>.<stufe>`, i18n-Pruefung gruen; 14 ungenutzte `ui.cockpit.*`-Schluessel in DE/EN entfernt, zwei bleiben, weil das Regelbuch sie zitiert: `ui.cockpit.card.decoys.caption`, `ui.cockpit.card.notice.heading`). `FOCUS_RING` von Gold auf Mondsilber `#e8edf6` (DAY_ACCENT unberuehrt). Spalte `tipps_neu` in `docs/audit/NACHTSCHRITTE-72.csv`: Messung ueber die echte Oberflaeche (Nacht 1 bis 3, Tipps = Knopf- und Sitzdruecke je Rolle, bedingte Rollen mit vielen Toten); 67 vergleichbare Rollen 182 vorher, 106 nachher; nicht gemessen: besessener-wolf, daemonischer-wolf, henker, kopfgeldjaeger, sensentraeger.
Verifikation: Vollsuite inkl. Fuzz auf dem finalen Stand: 1409 Tests, 0 Fehlschlaege (Exit 0); der erste Lauf war rot (Regelbuch zitierte zwei entfernte Schluessel), Schluessel wiederhergestellt, Lauf wiederholt. Screenshots 1024x768 in `Downloads/Grimmhain-Nacht-neu/`.
Merge: ohne Squash nach main (51b779f), main gepusht. Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion), `index.pck` 39783520 Byte wie lokal.
Offen: Die Rueckgaengig-Leiste erscheint direkt nach einer Auto-Uebernahme als schmaler Streifen mit senkrecht umbrochenem Text und verdeckt kurz die Karte (3 s, Ursache im Layout der Leiste); Titel der Blutpriester-Karte wird vom Info-Knopf angeschnitten. Safari/iPad nicht geprueft.

## MORGEN-ZUSAMMENFASSUNG Nachtschicht (2026-10-05, Branch chore/nachtschicht, gemergt)
- Erledigt: CLAUDE.md auf 51 Zeilen (Erklaerungen nach docs/development/), `tools/test-quiet`, `tools/test-changed` (+ `tools/test-map.json`), vier Projekt-Skills, Marken-Check-Hook (`tools/check-brand.js`), Standard-Screenshotwerkzeug `godot/tools/capture_standard_set.gd`.
- Darstellung: Rueckgaengig-Leiste ist wieder eine volle Zeile (Ursache: Umbruch bei 1 px Breite), Kartentitel laeuft nie unter den Info-Knopf (DE/EN, 37 von 72 Rollen in Nacht 1 geprueft, die uebrigen teilen den Code).
- Audit Paket B (57 Funde MITTEL/NIEDRIG): 5 vorher erledigt, 19 behoben, 22 fuer Markus, 11 offen. Einzelstand: docs/audit/AUDIT-2026-10-02.md.
- Vollsuite inkl. Fuzz auf dem finalen Stand: 1414 Tests, 0 Fehlschlaege (Runde 1 gruen). Merge ohne Squash (fe1d635), Deploy grimmhain-ipad-test ja (index.pck 39783744 Byte wie lokal). Nicht geprueft: Safari/iPad.
- Fuer Markus (Ja/Nein, Beispiel):
  1. Seuchenwolf-Durchdringung nur verbrauchen, wenn das Rudelopfer lebt (A-01)? Bsp: Rudel und Hexengift treffen Person 6, geschuetzte Person 7 ueberlebt Nacht 3.
  2. Schild des Schutzgeists bei durchdringendem Rudelangriff entfernen (A-02)? Bsp: Fenrir ueberlebt Nacht 3.
  3. Verliert der Parasit mit der Rolle auch die Bindung an den Wirt (B-06)? Bsp: Wirt stirbt, frueherer Parasit stirbt mit.
  4. Markierungen am Sitzkreis tagsueber verbergen (S-05)? Bsp: Giftabzeichen sichtbar, waehrend alle nominieren.
  5. Nachtleiste bei der anonymen Rotkaeppchen-Frage ausblenden (S-04)? Bsp: Leiste zeigt Rotkaeppchen als aktiv.
  6. Verdeckte Karten alle mit demselben Text (S-07, S-06, S-09)? Bsp: "Eine Siegbedingung ist erfuellt" verraet eine offene Siegentscheidung.
  7. Beenden-Knopf im Web ausblenden (UI-02) und Export-Weg auf dem iPad klaeren (UI-03)? Bsp: Knopf friert die Seite ein.
  8. Ungenutzte Bilder (25 Dateien, 1,8 MB) aus dem Export nehmen (F-A03) und Favicon setzen (UI-04)? Bsp: Godot-Symbol im Browsertab.
  9. Rechtfertigt eine Regelaenderung RULES_VERSION-Erhoehung statt "beschaedigt" (CM-05)? Bsp: alter Stand erscheint als defekt.

## UEBERGABE Nachtschritte neu (erledigt, siehe Abschluss oben, 2026-10-05)
- Phase 1 (Regelkern, Commit 6d8cda7): fertig. Unit, Szenarien und Fuzz waren gruen. Der .po-Mehrzeilenfehler aus diesem Commit ist im WIP-Commit repariert.
- Phase 2 (Schablone): Code steht (action_card, cockpit_screen, cockpit_text, cockpit_view, prompt_view), 172 neue ui.night.* Texte DE/EN fuer alle Schritte.
- UI-Tests (Stand 2026-10-05, Vollsuite --dir=ui): 431 Tests, 0 rot, alle Dateien ladbar. Vorher 16 rot (resume_scenarios 6, role_operation_kinds 4,
  target_selection 6), davor 39 rot. Alle UI-Testdateien sind auf die Nacht-Schablone migriert. Neu: tests/ui/test_night_template.gd (Auto-Uebernahme,
  Rueckgaengig-Leiste, Loki Art zuerst, Rudel ohne "Kein Opfer").
- Migrationsentscheidungen: Hinweiskarten werden durch Schliessen der gezeigten Karte bestaetigt (kein AckNoticeButton); Pflichtwahl ohne Verzicht
  (Besessener Wolf, Rudel); Pfeile/Zielplatz nur bei nicht festen Anzahlen; Zuflucht-Karte zeigt wieder den Namen der gefragten Person (AskedName) und einen Hilfesatz zu Apfel/Kette (RefugeHint, DE/EN); Rolle und Fragende bleiben verborgen.
  Entfallene Pruefungen: ui.prompt.*-Anweisungen in den Lexikonzeilen (Keys abgeschafft); Auswahlmarkierung/Abwaehlen vor Bestaetigung bei fester Anzahl.
  Code-Fix: action_card.gd zeigt keine Ansagezeile mit leerer Rolle bei anonymer Frage (Zuflucht). Lexikon-Aufruf des Lehrlings an Kartentext angeglichen.
- Fehlt: verwaiste i18n-Keys/Code entfernen (tools/check-godot-i18n.js meldet 2 Altbefunde zu ui.night.reaction.%s, cockpit_text.gd:62); FOCUS_RING Gold zu Mondsilber;
  Spalte tipps_neu in docs/audit/NACHTSCHRITTE-72.csv samt Neumessung; 7 Screenshots 1024x768 nach Downloads/Grimmhain-Nacht-neu; Vollsuite inkl. Fuzz; dann Merge, Export, Deploy.
- Entfallene Pruefungen (zusaetzlich): Abbrechen auf Rollenkarten (nur Karteneingaben), Lehrling-Optionswahl (jetzt direkte Meisterwahl), Auswahlmarkierung bei fester Anzahl.
- Testmuster: Auto-Commit bei fester Anzahl, also kein ConfirmTargetsButton (Mehrfachwahl-Tests mit Spuerhund, 3 Personen); Schritte mit Vorschau zaehlen als Prompt
  (effective_of / next() im Treiber), Schritt vorher per begin_open_step() beginnen, wenn der Zustand den Prompt braucht; Cancel/Skip/Clear nur noch bei Karteneingaben (owner card).
- Rudelschritt in Vorbereitungen per Kernbefehl skip_next_step ueberspringen (nur Core, nicht in der UI); Loki: erst YesButton/NoButton (Art), dann 2 Personen.
- CockpitScreen.double_tap_msec = 0 in Tests (spawn_shell setzt es), nur der Doppeltipp-Test schaltet 400 ein.
- Hinweise/Auskunft: ShowNoticeButton/ShowCardButton, dann CloseLayerButton erledigt sie; layer close ohne Knopf (close_layer) verwirft nur.
- Alte Spielstaende in der Lehrling-Stufe sind nicht mehr ladbar.

---

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

## 2026-09-29 - Paket 1 der Code-Abschluss-Roadmap (Abschlussmatrix)
Status: Der Arbeitsstand liegt nicht in diesem Checkout (main `8197ee6`), sondern im Worktree `grimmhain-night-ui`, Branch `feature/night-ui-expansion`, Commit `1e92f91` (gepusht, PR #3 offen). Dort: `docs/masterplan/CODE-COMPLETION-MATRIX.md`, konkretisierte `CODE-COMPLETION-ROADMAP.md`, PROGRESS-Eintrag mit allen Details. Hier bleiben Roadmap und Masterplan-Update unveraendert lokal (nicht committet).
Verifiziert (im Worktree, Godot 4.7.2 headless): Vollsuite 917 Tests, Lauf 1 mit 1 Fehlschlag (`test_prompt_coverage`, intermittierend, Ursache offen), Lauf 2 gruen; Asset-, Rollen-, Inhaltspruefer und `git diff --check` Exit 0. Keine Tablet-Abnahme.
Naechster Schritt: Paket 2 (Rollen-zeigen-Modus, Spezialkorrekturen, Vorpruefung B-01) nach Antwort auf die Schema-Frage.

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

---

## 2026-09-29 — Inhaltsentscheidungen DI-01 bis DI-08 in PR #3
Status: integriert im Branch `feature/night-ui-expansion`, noch nicht gemergt. Schema 13, Regelversion 0.12. Umsetzung und Abweichungen von den Entwurfsannahmen: `docs/content-drafts/INTEGRATION-STATUS.md`, Entscheidungen im Decision Log ("Inhaltsentscheidungen").
Umfang: Wiederbelebungsrunde statt Aufdeckungsoption (`revival_round`, alte Angabe wird abgelehnt), Tarnaufrufe (`CallPolicy`), öffentliche Todeseffekt-Ansagen (`DeathEffect`), private Hinweiskarten für Loki, Rattenfänger und Pestbringerin (`notices`, `AckNotice`), anonyme Rotkäppchen-Karte, keine Scheinrolle auf Karten. Spielstände anderer Schemaversion (zum Beispiel 12) werden nicht beiseitegelegt oder verändert, sondern als "andere Version" angezeigt (Fortsetzen gesperrt, Verwerfen möglich).
Verifiziert (Windows, Godot 4.7.2, headless): 917 Tests, 0 fehlgeschlagen, Exit 0; Register 313/313, Rollenprüfer und `check-coverage.py` ohne Befund, `git diff --check` Exit 0. Keine grafische, Touch- oder Tablet-Prüfung.
Nicht umgesetzt: Smartphone- und Audio-Ausgabe, Ton bei fünf Toten (DI-09), Totenreichkarten (nicht definiert).
Nächster Schritt: manueller PC-Test `docs/ui/pc-test-pr3.md` (A4, Teile I bis L).

---

## 2026-09-29 — Paket 1 der Code-Abschluss-Roadmap: Abschlussmatrix
Status: Dokumentation auf `feature/night-ui-expansion` (Ausgangs-HEAD `23c7044`), kein Code geändert, keine Regel geändert. PR #3 offen, nicht erweitert.
Ergebnis: `docs/masterplan/CODE-COMPLETION-MATRIX.md` (Funktionen, 72 Rollen-IDs, Befunde, offene Entscheidungen), `docs/masterplan/CODE-COMPLETION-ROADMAP.md` (aus dem Hauptrepo übernommen und mit Belegen konkretisiert), Planungsupdate im Masterplan (aus dem Hauptrepo übernommen, Stand-Absatz auf den Branch angepasst).
Befunde: `ConfirmRoleShown` existiert nicht im Code (nur Spezifikation); Einstellungen werden nicht gespeichert; gespeicherte Gruppen, Szenarien, Expertenmodus, Übungsmodus, Timer, Nachspielbericht, Audio, Clients, Export fehlen; Schutz-, Rettungs-, Wolfskind- und Lehrling-Korrekturen ohne Oberfläche; `test_prompt_coverage` einmal intermittierend rot (Ursache offen).
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0; Vollsuite 917 Tests, Lauf 1 mit 1 Fehlschlag (`test_prompt_coverage`), Lauf 2 mit 0 Fehlschlägen; `--filter=prompt_coverage` 7 von 7 grün; `node tools/check-asset-register.js`, `node tools/role-migration/check-role-docs.js`, `python docs/content-drafts/check-coverage.py`, `node --test tests/check-role-docs.test.js tests/check-asset-register.test.js` (20 Tests) jeweils Exit 0; `git diff --check` Exit 0. Keine grafische, Touch- oder Tablet-Prüfung.
Nächster Schritt: Paket 2 (Rollen-zeigen-Modus, Spezialkorrekturen, Vorprüfung B-01) nach Beantwortung der Schema-Frage.

---

## 2026-09-29 — Paket 2: stabile Prüfungen, Rollenanzeige, Spezialkorrekturen
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `1e92f91`), PR #3 offen, kein Merge. Schema 14 (vorher 13), Regelversion 0.12 unverändert. Ältere Spielstände (Schema 13 und früher) werden nicht migriert, bleiben unverändert erhalten und erscheinen als „andere Version“ (Fortsetzen gesperrt, Verwerfen möglich).
Umfang: (1) B-01: `Array.shuffle()` im Abdeckungstest nutzte den globalen Zufall, jetzt seedbar; feste Erreichbarkeitsszenarien für zwölf bedingte Nachtrollen; Regressionstest. (2) Kernbefehl `ConfirmRoleShown`, Zustand `roles_shown`, Rollenanzeige mit neutraler Liste und Karte (Trugbilderwolf: wahre Rolle, nie die Scheinrolle). (3) Spezialkorrekturen für Schutz, Rettung, Wolfskind und Lehrling über „Status ändern“, nur nach Kernvorprüfung.
Nicht umgesetzt: Geräte- und Touchabnahme, Layout-Umbau, Paket 3 (Buttonweg pro Rolle). Offen: siehe Matrix (`docs/masterplan/CODE-COMPLETION-MATRIX.md`).
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0; Vollsuite 956 Tests, 0 fehlgeschlagen, keine Laufzeitfehler, Exit 0 (vorher 917); `node tools/check-asset-register.js`, `node tools/role-migration/check-role-docs.js`, `python docs/content-drafts/check-coverage.py`, `node --test tests/check-role-docs.test.js tests/check-asset-register.test.js` jeweils Exit 0; `git diff --check` Exit 0. B-01: mit dem alten `shuffle()` rot (Gegenprobe), mit der Korrektur grün. Keine grafische, Touch- oder Tablet-Prüfung.
Nächster Schritt: Paket 3 (Rollen- und Interaktionsprüfung bis zur Bedienung), nur nach ausdrücklichem Auftrag.

---

## 2026-09-29 — Paket 3: Rollenbedienung, Wechselwirkungen, Kombinationsanalyse
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `9883291`), PR #3 offen, kein Merge. Schema 14, Regelversion 0.12 unverändert.
Umfang: Treiber `godot/tests/ui/role_ui_case.gd` (nur Sitzplätze, Kartenbuttons, Dialog); `test_role_buttons` (45 aktive Rollen), `test_role_passive_ui` (13, passive und Morgenbericht-Rollen), `test_role_operation_kinds` (Abbruch ohne Verbrauch, Doppeltippen je Antwortart, Undo, Rollenwechsel, Positivlisten von zwölf Zeigekarten); acht neue feste Wechselwirkungen in `test_role_interactions`; Fuzz unabhängig vom globalen Zufall; Analyse `docs/role-migration/12-role-combination-analysis.md` (A 0, B 0 offen, C 4, D 9).
Fehler behoben: Stimmhinweise (Blutwolf, Korrupter Richter, RM-DR-008) wurden nie angezeigt; jetzt im privaten Spielleiterbereich.
Nicht umgesetzt: Zufallsknopf R-06 (nicht beauftragt), Setup-Hinweise zu Kombinationen (Produktentscheidung offen), Geräte- und Touchabnahme.
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1028 Tests, 0 fehlgeschlagen, Exit 0 (vorher 956); Asset-Register, Rollendokumentprüfer, Inhaltsabdeckung und `node --test` (2 Prüfertests) jeweils Exit 0; `git diff --check` Exit 0. Gegenprobe: absichtlich verletzte Überspringen-Regel der Karte macht alle 5 Bedienarten-Tests rot. Keine grafische, Touch- oder Tablet-Prüfung.
Nächster Schritt: Paket 4 (Wiederaufnahme, Geheimhaltung, Betriebsfehler), nur nach Auftrag.

---

## 2026-09-29 — Paket 4: Speichern, Wiederaufnahme, Geheimhaltung unter Fehlerbedingungen
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `437df88`), PR #3 offen, kein Merge. Schema 14, Regelversion 0.12 unverändert, kein Formatwechsel.
Umfang: Neustart über Hauptmenü → „Fortsetzen“ an neun Unterbrechungsstellen (`test_resume_scenarios`), Neustart über die Datei nach jedem Befehl von sechs Mischpartien (`test_resume_every_command`), echter zweiter Godot-Prozess (`test_process_restart`), Speicherfehler (zwei Fehler nacheinander, nicht anlegbares Verzeichnis, wiederholtes Laden), Positivlisten für Speicherübersicht, Statusmeldungen und öffentliche Cockpit-Sicht (`test_output_positive_lists`), Inventar aller Ausgabewege in `docs/ui/cockpit.md`.
Fehler behoben: B-04 (zweiter Speicherfehler nach abgebrochenem Speichern löschte den neuesten vollständigen Stand); B-05 (Beenden-Rückfrage versprach „ist gespeichert“ trotz Fehler, kein erneutes Speichern ohne neuen Befehl, Rückfallmeldung ohne Hinweis auf älteren Stand). Neu: „Erneut speichern“ (ein Versuch je Tippen). Ableitungen DA-34 bis DA-39.
Nicht umgesetzt: Zufallsknopf R-06 (funktionale Restaufgabe), Setup-Regel R-07 (Entscheidung offen), Checkpoint-Rotation D-04, Redo nach Neustart D-05, I-03 (alle Produktentscheidungen), Geräte- und Touchabnahme.
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1048 Tests, 0 fehlgeschlagen, Exit 0 (vorher 1028); Asset-Register, Rollendokumentprüfer, Inhaltsabdeckung Exit 0; `node --test` 3 Prüfertests Exit 0; `git diff --check` Exit 0.
Nächster Schritt: Produktentscheidungen D-04, D-05, I-03 und R-07; danach R-06 oder Paket 5, nur nach Auftrag.

---

## 2026-09-29 — Restpaket vor Paket 5: sichere Beendigung und Zufallsknopf R-06
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `a44bb0e`), PR #3 offen, kein Merge. Schema 14, Regelversion 0.12 unverändert, kein Formatwechsel.
Fehler behoben: B-06, die Warnung bei ungespeichertem Stand ließ sich umgehen (mobiles System-Zurück in der Wurzel beendete sofort, Desktop-Fensterschließen beendete ohne Rückfrage).
Umgesetzt: R-06 Zufallsknopf für Traumdeuter, Kopfgeldjäger, König und die Aufdeckung des Blutpriesters. Vorschlag aus einer Kopie des gespeicherten Generators, Übernahme erst mit Bestätigung über den Regelkern (`AnswerPrompt` mit `random: true`). Ableitungen DA-40 bis DA-45.
Paket 4: automatisierte Prüfungen abgeschlossen, Produktentscheidungen offen (D-04, D-05, I-03); keine vollständige Abnahme.
Nicht umgesetzt: Spielleitertexte der vier Rollen (OI-09, Paket 5), Setup-Hinweise R-07 (Entscheidung offen), Geräte- und Touchabnahme.
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1059 Tests, 0 fehlgeschlagen, Exit 0 (vorher 1048); Prüfer siehe Abschlussbericht.
Nächster Schritt: Antworten zu D-04, D-05, I-03, R-07 umsetzen (eigener Auftrag), danach Paket 5.

## 2026-09-29 — Produktentscheidungen PE-01 bis PE-04 umgesetzt
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `ca7b44e`), PR #3 offen, kein Merge. Schema 14, Regelversion 0.12 unverändert.
PE-01 (I-03): Die öffentliche Hinweiszeile nennt keine offenen Reaktionen mehr. Außerhalb der Nacht zeigt sie bei jeder verdeckten Karte einen neutralen Text je Phase (Morgen, Tag). Die Karte der Spielleitung bleibt vollständig. Als Rückschlussweg bleiben die Phase „Morgen“ und die verdeckte Karte (DA-46).
PE-04 (R-07): Zwei nicht blockierende Hinweise im Rollenschritt: Kutscher unter 13 Personen und mindestens zwei aus Parasit, Voodoo-Priester, Grabräuber, Manipulator. PE-04 nennt „Wahnsinniger Kutscher“, umgesetzt ist nach der Mechanik der Kutscher (DA-47, zur Bestätigung durch den Product Owner).
PE-02/PE-03 (D-04, D-05): Masterplan, Spec B-12, `save-resume.md`, Matrix und Roadmap nachgezogen; keine Codeänderung.
Zufallsknopf: gesperrter Zustand zusätzlich über die Oberfläche geprüft. Im regulären Ablauf ist er nicht erreichbar, deshalb wird er per Testvorbereitung hergestellt (DA-50).
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1072 Tests, 0 fehlgeschlagen, Exit 0 (vorher 1059).
Nicht umgesetzt: Geräte- und Touchabnahme; Paket 5.
Nächster Schritt: Paket 5 (Inhalte und Medienanschlüsse) nach Freigabe.

## 2026-09-29 — Paket 5a: Einstellungen dauerhaft, i18n-Prüfer, Inhaltsstand bereinigt
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `4f2deea`), PR #3 offen, kein Merge. Schema 14, Regelversion 0.12 unverändert.
Fehler behoben: B-02 (Sprache und „Bewegung reduzieren“ gingen beim Neustart verloren). Rote Tests zuerst (`test_settings_persistence`, Klasse fehlte), Mutationsproben: Laden erst in `_ready` und „immer gespeichert“ werden jeweils von einem Test erkannt.
Umgesetzt: `SettingsStore` (`user://settings.json`, getrennt von Spielständen), Laden in `AppShell._enter_tree` vor der ersten Ansicht, Validierung je Wert, defekte Datei ohne Startabbruch, Schreibfehler erhält die letzte gültige Fassung und wird im Einstellungsscreen gemeldet (DA-52). Linkshänderwert wird mitgespeichert, bleibt ohne Wirkung (D-10 offen).
Umgesetzt: `tools/check-godot-i18n.js` mit 17 Regressionstests und CI-Workflow `godot-i18n.yml` (DA-53). Grenzen: 47 dynamische Schlüsselvorlagen nur als Vorlage, Platzhalterwerte aus Variablen nicht statisch.
Inhalte: OI-12, OI-13, OI-17 mit DI-04 bis DI-07 verknüpft; 16 deutsche und 13 englische Verweise „noch nicht im Decision Log“ in Rollenlexikon, GUIDE-TEXTS und README durch DI-Nummern ersetzt; Spielleitungszeilen der vier Zufallsrollen an den Bedienweg angepasst (OI-09, DA-43 gekennzeichnet); Integrationsliste für Paket 5b in `INTEGRATION-STATUS.md`. Echte offene Inhaltsfragen: Rolle in drei Todeseffekt-Ansagen (DI-03), Phase „Alle Verzauberten“ ohne neu Verzauberte (DI-06).
Berichtigt: Matrix I-03 von AUTO auf TEIL (Rückschluss aus Phase „Morgen“ und verdeckter Karte offen, DA-46 ist keine Freigabe).
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1081 Tests, 0 fehlgeschlagen, Exit 0 (vorher 1072); Prüfer siehe Abschlussbericht.
Nicht umgesetzt: Linkshändermodus (D-10), Audio, Lexikonansicht, I-03 Teil 2, Geräte- und Touchabnahme.
Nächster Schritt: Paket 5b (Lexikon- und Spielleitungstexte ins Programm) nach Klärung von Anzeigeort und Freigabe.

## 2026-09-29 — Paket 5b: Rollenlexikon und kontextbezogene Spielleiterhilfe
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `b75d69d`), PR #3 offen, kein Merge. Schema 14, Regelversion 0.12 unverändert (DA-54).
Nutzerantworten (Auswahl in Claude Code): PE-05 „Quellrolle nennen“ (Liebeskummer → Loki, Kette → Rotkäppchen, Verknüpfung → Schattenwanderer), umgesetzt testgetrieben (`test_death_effects`, `test_death_effect_lines` erst rot, dann grün). PE-06 „Immer nach Rattenfänger“, nicht umgesetzt: ein Hinweis erschiene vor dem Tarnaufruf und verriete die Tarnung; Folgeauftrag mit eigenem Nachtschritt (DA-55, Matrix N-12).
Umgesetzt: Rollenlexikon (`RoleLexicon`) mit Suche, Fraktionsfilter, leerem Zustand, scrollbarem Eintrag und Sprachknopf; eigene Ansicht aus dem Hauptmenü, Ebene im Setup (Knopf „Regeln“ je Rollenzeile) und im Cockpit (Werkzeug „Lexikon“, „Regel nachlesen“ auf der privaten Karte). Offene Auswahl bleibt bis zur nächsten Zustandsänderung; kein Befehl, kein Zufall, keine Ressource (DA-57).
Inhalte: 71 Einträge gegen aktuellen Stand geprüft, 26 Zellen redaktionell korrigiert, 15 Rollen mit Feld „Noch nicht geklärt oder umgesetzt“; 654 Lexikonschlüssel je Sprache (DA-56). Kurztexte angeglichen (Rudelangriff, Hinrichtung, neutrale englische Pronomen, DA-58). GUIDE-TEXTS §3.3/§3.4 an den integrierten Wortlaut angeglichen.
Prüfer: `check-godot-i18n.js` prüft jedes Lexikon-Pflichtfeld je Katalogrolle und meldet Einträge für unbekannte Rollen oder Felder (18 Regressionstests). Layoutprüfung wertet Scrollinhalt mit seinem sichtbaren Teil (DA-59); sie fand dabei umbrechende Filterknöpfe, die die Liste bei 1024×768 fast aus dem Bild schoben (behoben).
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0; Vollsuite 1096 Tests, 0 fehlgeschlagen, Exit 0 (vorher 1081); Mutationsprobe: Verwerfen der Auswahl beim Öffnen wird erkannt. Keine visuelle, Touch- oder Geräteabnahme.
Nicht umgesetzt: PE-06, allgemeines Regelbuch, Handlungszeilen (OI-18), redaktionelle Endabnahme, I-03 Teil 2, D-10, Audio.
Nächster Schritt: PE-06 als Kernauftrag (eigener Nachtschritt „Alle Verzauberten“, Regelversion 0.13), danach redaktionelle Endabnahme des Lexikons.

## 2026-09-29 — PE-06: Rattenfänger-Ablauf vollständig automatisiert
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `09aec95`), PR #3 offen, kein Merge. Schema 14 unverändert, Regelversion `grimmhain-core-0.13` (DA-63).
Umgesetzt: „Alle Verzauberten“ als eigener Nachtschritt `piper-all` direkt hinter dem Rattenfänger (DA-60). Ablauf: Rattenfänger → Hinweis an die neu Verzauberten → „Alle Verzauberten“ → nächster Schritt; ohne neue Verzauberung entfällt nur der Hinweis. Nach einem Tarnaufruf (Rattenfänger vergiftet, tot in einer Wiederbelebungsrunde, eingefrorene Nacht) steht die Ansage des Rattenfängers auf derselben Karte davor. Der Schritt entfällt ohne Aufruf des Rattenfängers oder ohne lebende Verzauberte (DA-61). Liste nur auf der Karte der Spielleitung, keine zeigbare Karte, kein Zufall, keine Verzauberung (DA-62). Hinweis `piper_all` und Lexikonhinweis „selbst aufrufen“ entfernt.
Nutzerantwort: PE-07 „Es gibt keine einzige Rolle doppelt in diesem Spiel bis auf die Gebundenen“; widerspricht dem Katalog (Mehrfachrollen erlaubt, E-11), Setup nicht geändert, offen im Decision Log.
Tests: `test_piper_all` (12, erst rot: 11 fehlgeschlagen), `test_piper_all_ui` (3, echte Buttons und Sitzplätze), `test_resume_scenarios` (+1, Neustart an fünf Stellen, Rückgängig/Wiederholen). Angepasst, weil PE-06 die Erwartung ersetzt: `test_notices`, `test_notice_cards`, `test_prompt_coverage`, `test_role_lexicon_content`, `test_role_lexicon_ui`; Fuzz-Generator kennt den neuen Prompt. Mutationsprobe: Tarnaufruf nicht auf dem Platz des Rattenfängers wird von vier Tests erkannt.
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1112 Tests, 0 fehlgeschlagen, Exit 0 (vorher 1096); `check-godot-i18n.js` Exit 0; Node-Prüfertests 38/38; `check-asset-register.js` Exit 0; `check-coverage.py` OK. Keine visuelle, Touch- oder Geräteabnahme.
Nicht umgesetzt: PE-07 (Setup-Grenzen), Grabräuber mit gestohlenem Rattenfänger nur abgeleitet, Geräte- und Touchabnahme, redaktionelle Endabnahme des Lexikons.
Nächster Schritt: PE-07 klären (gilt „keine Rolle doppelt“ für alle Sonderrollen?), danach Setup-Grenzen umsetzen.

## 2026-09-30 — PE-07: Einzigartige Startrollen (UNTERBROCHEN, nicht committet)
*Überholt am 30.09.2026 durch den nächsten Eintrag „PE-07 abgeschlossen“; dieser Zwischenstand bleibt als Verlauf stehen.*
Status: auf Nutzerwunsch nach dem ersten Teilschritt angehalten. Branch `feature/night-ui-expansion`, HEAD `6ff63f4` (= Kopf PR #3, CI grün). Alle Änderungen liegen **uncommittet** im Worktree `grimmhain-night-ui`; die Vollsuite ist damit absichtlich rot. Nicht pushen, bevor die Fixtures umgestellt sind.
Nutzerantworten (Auswahl in Claude Code, noch nicht im DECISION-LOG eingetragen):
- PE-07 Option B: Jede Rolle höchstens einmal bei Spielbeginn, auch Dorfbewohner und Werwolf. Später entstehende gleiche Rollen (Verwandlung, Erbe, Tausch, Diebstahl, Korrektur) sind nicht entschieden und werden nicht geändert.
- Gebundene: beliebig viele (1 bis Personenzahl), wie bisher in Godot.
- Automatischer Vorschlag: feste Rollenliste, gleiche Wolfsstufen (1/2/3/4/5 ab 6/9/13/18/22 Personen), genau ein Manipulator. Wölfe in Reihenfolge Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf, Besessener Wolf. Dorf in Reihenfolge Schutzengel, Orakel, Dorfbewohner, Waldhexe, Dorfwache, Sensenträger, Ritter, Lehrling, Nachtwächter, Wolfskind, Waldläufer, Doktor, Detektiv, Fährtenleser, Der Weise, Dorfchronistin, Wahnsinniger Kutscher, Traumdeuter (so viele wie nötig). 6 Personen: Werwolf, Manipulator, Schutzengel, Orakel, Dorfbewohner, Waldhexe.
Erledigt (uncommittet):
- `godot/core/rules/role_catalog.gd`: `max_copies` Standard 1, `die-gebundenen` UNLIMITED. StartGame (`RulesEngine._validate_start_game`, Fehler `role_limit_exceeded`) und Setup (`SetupRoleCatalog.copy_limit`, `RolePoolDraft.issues/view`, `RoleSetup.set_role_count`) lesen dieselbe Grenze bereits, keine zweite Regel nötig.
- `godot/tests/unit/test_unique_start_roles.gd` (8 Tests): vorher rot (5 von 8 fehlgeschlagen), jetzt grün (Exit 0). Deckt zwei Dorfbewohner, zwei Werwölfe, zwei Orakel/Rattenfänger/Trugbilderwölfe (manuell und zufällig), unveränderten Zustand und Zufall, Gebundene 1/4/23, 6 und 24 Personen, jede Personenzahl 6 bis 24.
- `godot/tests/fixtures.gd`: `UNIQUE_ORDER` und `unique_roles(count)`.
- `godot/tests/saves/pe07-core-0.13-duplicate-roles.json`: echter Spielstand, vor der Änderung mit `SaveService` der Regelversion 0.13 erzeugt (7 Personen, 2 Werwölfe, 3 Dorfbewohner). Grundlage für den Save-Kompatibilitätstest.
Befund Vollsuite nach der Kernänderung: 1120 Tests, 927 fehlgeschlagen, 930 Skriptfehler (Folgefehler: Start wird abgelehnt, danach Zugriff auf `null`). Ursache: `Fixtures.start_manual/start_random/start_reaper_game` und viele eigene Startlisten nutzen mehrere Werwölfe/Dorfbewohner. Größte Dateien: `test_role_buttons` 45, `test_waldhexe` 43, `test_schutzengel` 29, `test_orakel` 28, `test_save_service` 26.
Offen (Reihenfolge):
1. Regelversion auf `grimmhain-core-0.14` anheben (alte Startbefehle mit Dubletten würden beim Replay abgelehnt); Test mit der gespeicherten 0.13-Datei: `SaveService` meldet `incompatible`, Datei unverändert, nicht beiseitegelegt. Kein Schemawechsel.
2. Fixtures umstellen, Testzweck erhalten: zusätzliche Wölfe durch Blutwolf (nur Stimmhinweis) o. Ä., zusätzliche Dorfpersonen durch möglichst wirkungsarme eindeutige Rollen; Gebundene erzeugen einen Nacht-1-Schritt und verschieben Befehlsfolgen. Nicht erreichbare Zustände als künstlich kennzeichnen. Fuzz-/Abdeckungsgeneratoren (`test_role_interaction_fuzz`, `test_prompt_coverage`) und Szenario-JSONs (`tests/scenarios/*.json`) anpassen. Keine Testumgehung im Produktionscode.
3. `RoleSuggestion` auf die feste Liste oben umstellen; Setup-Anzeige: bei Höchstzahl 1 eigener Text „Nur einmal pro Partie“ (DE/EN), Fehler `above_maximum` mit Namen der betroffenen Rollen, Start gesperrt, nichts still kürzen.
4. Durchgang über echte Controls vom Setup bis Nacht und Tag.
5. Doku: PE-07 im DECISION-LOG mit Antwort ergänzen, Rollenkatalog-/Setup-Doku, Masterplan, Matrix (Grabräuber mit gestohlenem Rattenfänger sichtbar offen lassen), Roadmap, Regelregister, Lexikon.
6. Vollsuite, i18n-/Asset-Prüfer, `git diff --check`, Commit, Push, PR #3 aktualisieren.
Hilfsskript der Sitzung (nicht im Repo): Godot-EXE `C:\Users\Marku\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`, Aufruf `--headless --path godot -s res://tests/run_tests.gd -- --filter=<name>`.

## 2026-09-30 — PE-07 abgeschlossen: einzigartige Startrollen, Vorschlag, Setup, Bedienweg
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `6ff63f4`), PR #3 offen, kein Merge, kein Force-Push. Schema 14 unverändert, Regelversion `grimmhain-core-0.14` (DA-66).
Nutzerantworten: PE-07 Option B, Gebundene 1 bis Personenzahl, fester Vorschlag (Decision Log „PE-07-Umsetzung (30.09.2026): Antworten des Product Owners“).
Umgesetzt:
- Kern: `RoleCatalog.max_copies` Standard 1, Die Gebundenen unbegrenzt; `StartGame` lehnt Dubletten ab (`role_limit_exceeded`), Ablehnung ändert weder Zustand noch Zufall. Später entstehende gleiche Rollen (Verwandlung, Erbe, Tausch, Diebstahl, Korrektur) unverändert.
- Alte Spielstände: Regelversion 0.13 wird als „andere Version“ mit Schema- und Regelversion angezeigt, „Fortsetzen“ gesperrt, Datei bytegleich, nicht beiseitegelegt, keine Migration (`godot/tests/saves/pe07-core-0.13-duplicate-roles.json`, `.gitattributes` `-text`).
- Vorschlag: `RoleSuggestion` als feste Liste für 6 bis 24 Personen (Wolfsrollen 1/2/3/4/5 ab 6/9/13/18/22, ein Manipulator, Dorfrollen in fester Reihenfolge); Trugbilderwolf ab 13 Personen mit ausdrücklicher Scheinrolle über den bestehenden Dialog.
- Setup-Oberfläche: „Nur einmal zu Spielbeginn“ (DE/EN), nach dem Entfernen wieder wählbar; Entwurf über der Höchstzahl wird nicht gekürzt, Fehlerzeile „Rolle zu oft gewählt“ und Namen der Rollen im Listenkopf (`OverLimitLabel`), Start gesperrt.
- Tests: 927 rote Tests der Vollsuite über gemeinsame Ursachen behoben (`Fixtures`: wirkungsarme verschiedene Füllrollen, `with_copies` für gleiche Rollen nach dem Start, `legalize`, `legal_counts`); Fuzz- und Abdeckungsgeneratoren mit gültigen eindeutigen Besetzungen und unveränderten Seeds; Szenario-JSONs umgestellt; Setup-Tests auf einzigartige Rollen (Die Gebundenen tragen den Kopien-Nachweis). Neu: `test_role_suggestion`, `test_full_round_ui` (Weg von „Neue Partie“ bis zum ersten Tag für 6, 13 und 24 Personen, Speichern/Fortsetzen, Rückgängig), Entwurf über der Höchstzahl in `test_role_step`, Spielstand 0.13 in `test_save_service`, Grabräuber mit gestohlenem Rattenfänger in `test_piper_all` (Ablauf war schon richtig, kein Codewechsel).
Nachweis-Vergleich (Teil 4.5): Erhalten mit anderen Füllrollen: die Mehrzahl der Tests, Erwartungen unverändert. Auf legalen Weg umgestellt (gültiger Start, dann Korrektur „Rolle setzen“): alle Tests mit gleichen Rollen, unter anderem Feuerteufel (E-11), Chronistinnen, Lehrlinge, Waldhexen, Schutzengel, Sensenträger, Trugbilderwölfe mit eigener Scheinrolle, Voodoo-Priester, Nekromanten, Hades. Ersetzt, weil beim Start nicht mehr erreichbar: mehrere Trugbilderwolf-Kopien im Setup (jetzt eine Kopie; Kopiennachweis über Die Gebundenen), zwei zufällig verteilte Trugbilderwölfe, 23 Wolfsrollen bei 24 Personen (jetzt höchste mögliche Zahl 18), `max_copies == UNLIMITED` des Siegreichen Wolfs (jetzt 1). Blockiert: nichts.
Gefundene echte Fehler gegenüber Fixture-Anpassungen: keine Regelfehler im Kern. Befund Oberfläche (nicht behoben, vor PE-07 vorhanden): Rollenschritt bei 1024×768 läuft um 24 px aus dem Fenster, sobald die Fehlerzeile der Seitenspalte zwei Zeilen braucht (nachgewiesen mit `6ff63f4`).
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1134 Tests, 0 fehlgeschlagen, Exit 0 (nach der Kernänderung waren von 1122 Tests 927 rot); `check-godot-i18n.js` Exit 0, Prüfertests 18/18; `check-asset-register.js` Exit 0, Prüfertests 17/17; `check-role-docs.js` Exit 0, Prüfertests 3/3; `check-coverage.py` OK; `git diff --check` sauber. Mutationsproben: Katalogstandard zurück auf unbegrenzt wird von fünf Tests im Kern und zwei im Setup erkannt, vertauschte Dorfreihenfolge vom Namenstest.
Nicht umgesetzt und nicht getestet: Geräte- und Touchabnahme, visuelle Abnahme.
Offene Produktfragen (unbeantwortet, nichts davon umgesetzt): `docs/masterplan/NIGHT-QUESTIONS-2026-09-30.md` (NQ-01 bis NQ-05).
Nächster Schritt: Roadmap Paket 6 (Technikabschluss und Übergabe an die Gestaltung).

## 2026-09-30 — Nachtauftrag Pakete B, C, D (Abschluss)
Status: Pakete B, C und D umgesetzt und headless nachgewiesen auf `feature/night-ui-expansion` (Ausgangs-HEAD `f54d105`), PR #3 offen, kein Merge, kein Force-Push. Schema 14 und Regelversion `grimmhain-core-0.14` unverändert (reine Zusatzansichten).
- Setup-Überlauf im Rollenschritt (`ac784ef`): Seitenspalte in `RoleSideScroll`; Regressionstest `test_side_column_two_line_issue_stays_reachable`.
- Paket B Spielergruppen (`0c7b233`): `app/groups/`, `app/storage/safe_json_file.gd`, Knöpfe „Gruppe laden/speichern“ im Spielerschritt. Tests `test_group_store` (13), `test_player_groups` (17).
- Paket C Regelbuch und Handlungszeilen: `app/rulebook/`, Hauptmenü und Cockpit-Werkzeug „Regelbuch“, Lexikonfeld „Ablauf am Tisch“ für 71 Rollen (Rotkäppchen offen, NQ-06). Tests `test_rulebook` (11), `test_role_act_lines` (4).
- Paket D Abschlussbericht: `session/game_report.gd`, `app/history/` (Store, Text, Export), Ansicht „Partiehistorie“, Karte „Abschlussbericht öffnen“, zwei Fassungen, UTF-8-Export, Löschen nach Bestätigung, Rücknahme setzt `reopened`. Tests `test_game_report` (8), `test_history_store` (13), `test_game_history`. Doku `docs/ui/game-history.md`, DA-80 bis DA-82, NQ-07.
Prüfstand: Vollsuite 1216 Tests, 0 fehlgeschlagen (Exit 0), `check-godot-i18n.js` Exit 0, `tests/check-godot-i18n.test.js` Exit 0, Asset-Register und Rollendoku Exit 0. Keine Geräteabnahme, keine visuelle Abnahme; redaktionelle Endabnahme der Regelbuchtexte offen.
Offene Fragen: `docs/masterplan/NIGHT-QUESTIONS-2026-09-30.md` (NQ-01 bis NQ-07).

## 2026-09-30 — Nachtentscheidungen NQ-01 bis NQ-07 umgesetzt
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `6b88e2c`), PR #3 offen, kein Merge. Schema 14, Regelversion `grimmhain-core-0.14` unverändert. Antworten und Herkunft: Decision Log „Nachtentscheidungen NQ-01 bis NQ-07“ (DA-83 bis DA-87); bestätigte Antworten und technische Ableitungen dort getrennt.
Umgesetzt: Rechts-/Linkshänder-Auswahl in den Optionen, Cockpit-Seitenspalte wechselt die Seite (D-10, `test_handedness`); Rotkäppchen-Ablauf in Lexikon, Regelbuch und Spielleiterkarte; öffentlicher Abschlussbericht mit allen Rollen zum Spielende, Siegbedingung und gewinnenden Personen, bei zurückgenommener Siegbestätigung wieder gesperrt; Hinweis bei fünf Toten als technischer Hinweis mit stummem Fallback (`PresentationCue`, `GameSession.cue_requested`, `AudioCuePlayer`). NQ-02 und NQ-03 sind Streichungen bzw. bewusste Akzeptanz (S-06 entfällt, I-03 Teil 2 akzeptiert), NQ-05 gilt vorläufig für Testpartien.
Fehler behoben: (1) CI rot auf `6b88e2c`: drei Tests in `test_game_report` hingen von der Systemsprache ab (jetzt `_start` setzt Deutsch; Lauf mit `--locale en` grün). (2) Statusleiste bei sichtbarer Speicherwarnung sprengte 1024×768 (Button „Erneut speichern“ ohne Umbruch). (3) Referenzkreis in `AppContext` (Lambda mit `self`) war die Ursache der Warnung „resources still in use at exit“; `test_object_lifetime` war vor dem Fix rot, im Vollauf erscheint die Warnung nicht mehr. Nebenbei: Optionen liegen in einer Scrollfläche; ein zeitabhängiger Test (`test_five_dead_player`) wurde stabilisiert.
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0; Vollsuite 1248 Tests, 0 fehlgeschlagen, Exit 0 (Systemsprache Deutsch und `--locale en`, vorher 1216); `node tools/check-godot-i18n.js` OK, `node --test tests/check-godot-i18n.test.js` 18 OK, `node tools/check-asset-register.js` OK, `git diff --check` ohne Befund.
Nicht umgesetzt / offen: hörbarer Ton (keine Tondatei, keine Lautstärke- oder Stummschaltung); Randfall des Hinweises (erster Zeitpunkt nicht berechtigt, später nie) ist abgeleitet (DA-86); Karten, redaktionelle Endabnahme, Einzelprüfung aller Rollen (NQ-05), Geräte- und Tabletabnahme. Automatische Komprimierung: `autoCompactWindow` 750000 in `~/.claude/settings.json` vorhanden (nicht geändert).
Nächster Schritt: Einzelprüfung der Rollen (NQ-05) oder Kartenregeln (P8) nach Freigabe; Tondatei über `grimmhain-assets`.

## 2026-09-30 — Fünf-Tote-Hinweis, Entscheidung B, und Vorlage Totenkarten/Kartenschlucker
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `41299f5`), kein Merge. Schema 14 und Regelversion `grimmhain-core-0.14` unverändert, keine Audiodatei. Herkunft: Decision Log „Fünf-Tote-Hinweis, Entscheidung B“.
Geändert: Ein erfolgloser erster Versuch (fünf Tote ohne lebenden Selbstmörder) verbraucht den Hinweis nicht mehr; nach Wiederbelebung unter fünf löst das nächste Erreichen aus, wenn dann ein lebender Selbstmörder (auch geerbt) da ist. Nach einer Auslösung bleibt „genau einmal“. Code: `GameSession._observe_five_dead` und `_rescan_five_dead` (Laden und Rückgängig aus der Befehlsfolge). Tests: `test_five_dead_cue` (6 neu bzw. umgestellt).
Vorlage: `docs/role-migration/13-totenkarten-kartenschlucker-vorlage.md` (verbindliche Regeln, fehlende Informationen, betroffene Rollen, Reihenfolge, fünf Fragen). Nichts an Karten implementiert.
Ungeklärt, unverändert: Selbstmörder durch Rollenübernahme, während durchgehend fünf oder mehr Personen tot sind (kein Absinken unter fünf): löst nichts aus (`test_open_case_role_gain_while_five_are_already_dead_is_unchanged`, Decision Log). Frage an den Product Owner steht dort.
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0; Vollsuite 1254 Tests, 0 fehlgeschlagen, Exit 0 in Deutsch und mit `--locale en`; `node tools/role-migration/check-role-docs.js`, `node tools/check-godot-i18n.js`, `node tools/check-asset-register.js` OK. Bekannt, schon vor der Änderung vorhanden: „2 ObjectDB instances were leaked at exit“ bei gefiltertem Lauf von `five_dead`.
Nächster Schritt: Antworten auf Fragen 1 bis 5 der Vorlage, dann Auftrag „Totenkarten-Grundlage und Kartenschlucker“ (Schemafreigabe nötig).

## 2026-09-30 — Entscheidungen 1A bis 6B, Fünf-Tote-Hinweis abgeschlossen, Totenkarten-Arbeitsliste
Status: umgesetzt auf `feature/night-ui-expansion` (Ausgangs-HEAD `3c3d05d`), PR #3, kein Merge. Schema 14 und Regelversion unverändert, keine Audiodatei.
Dokumentiert: Decision Log „Totenkarten und Kartenschlucker, Entscheidungen vom 30.09.2026“ (1A, 2C, 3A eingeschränkt, 4B, 5A, 6B mit Herkunft und offenen Punkten); Vorlage 13 trägt einen Nachtrag, keine parallele Regelquelle.
Code: Nur 6B. Rolle Selbstmörder bei schon fünf Toten (Spielleiterkorrektur oder Erbe) löst den Hinweis einmalig aus (`PresentationCue.death_seeker_gained`, `GameSession._observe_five_dead`); in der Nacht erst mit der Morgenauflösung. Tests `test_five_dead_cue` (24): Regressionstests waren ohne die Änderung rot (4), Randfall „Wiederbelebung bei weiter fünf Toten“ als unentschieden festgehalten. Der Ton-Sonderfall ist damit technisch abgeschlossen; kein hörbarer Ton, keine Tablet- oder Hörprüfung.
Vorbereitet: `docs/role-migration/14-totenkarten-arbeitsliste.md` mit allen 80 Karten (Regeltext unverändert, Wirkung, reale Handlung, Eingabe, Unklarheiten, Status „noch nicht überarbeitet“), 8 Bearbeitungsgruppen, 10 übergreifende Punkte, 5 Fragen (KS-01 bis KS-05) und 8 weitere (KS-06 bis KS-13). Kartenmechanik, Kartenverteilung, Kartentausch und Kartenschlucker sind weiterhin nicht implementiert.
Verifiziert (Windows, Godot 4.7.2, headless): Vollsuite 1259 Tests, 0 fehlgeschlagen, Exit 0 (Deutsch und `--locale en`); `check-role-docs.js`, `check-godot-i18n.js`, `check-asset-register.js` OK; `git diff --check` ohne Befund.
Nächster Schritt: Antworten auf KS-01 bis KS-05, dann Gruppe 1 der Arbeitsliste durcharbeiten.

## 2026-09-30 — Kartenschlucker-Grundregeln (zweite Antwortrunde), nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `63ea0f1`), PR #3, kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenschlucker und Kartenmechanik weiterhin nicht implementiert.
Entschieden (Decision Log „Kartenschlucker, Grundregeln“): Tausch nur bei lebendem Träger der Rolle (+1 Stapel); Nachtaktion jede Nacht genau eine (nichts, zwei Finger = Tötung für 2 Stapel, fünf Finger = Schild für 5, zehn Finger = Sieg für 10); Schild bleibt bis zum verhinderten Tod, höchstens einer, keine Erneuerung; Zehn Stapel allein siegen nicht; Ansage in festen Nächten 3, 6, 9; Stapel gehören zur Person (neuer Träger bei null, beim alten ruhend). Ersetzt: „Bei 10 Stapeln gewinnt er sofort“, kostenlose Tötung, kostenloser Schild ab 5, Legacy-Automatismen, Vorschläge der Arbeitsliste vom Vortag.
Konsistenz: Hinweise in Vorlage 13, Dossier solos-b, 08-decision-request, 11-role-audit-status, Matrix R-03, Roadmap Paket 8; Arbeitsliste neu erzeugt (80 Karten, Regeltext unverändert geprüft), ÜB-1 korrigiert (Vergabe beim Tod widerspricht unterschiedlichen Kartentexten nicht), Gruppe 1 mit Blockern, zweite Fragerunde KS-06 bis KS-10, weitere Punkte KS-11 bis KS-21.
Geprüft: `check-role-docs.js` OK, `check-asset-register.js` OK, `git diff --check` ohne Befund. Godot-Vollsuite bewusst nicht ausgeführt (nur Dokumente geändert).
Nächster Schritt: Antworten auf KS-06 bis KS-10, danach Gruppe 1 der Karten durcharbeiten.

## 2026-09-30 — Totenreichkarten, dritte Antwortrunde und erste Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `12abe0e`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log „Totenreichkarten: Kartenfenster, Schild, Stapelansage, Wiederbelebungskarten“): Schild verhindert Tod durch Rollenfähigkeit oder Hinrichtung (auch bei „ignoriert Schutz“, Spielleiterkorrektur bleibt), gehört zur Person und bleibt über Rollenwechsel, Tod und Wiederbelebung; Ansage nennt die Gesamtzahl aller gesammelten Stapel ohne Abzug; zwei Kartenfenster (Tagesbeginn vor der Diskussion, Tagesende nach Hinrichtung und Todeseffekten), Originalkarte darf aufbewahrt werden, Tausch nur in den Fenstern; Wiederbelebungskarten nur in Wiederbelebungsrunden, keine Prüfung „Rolle lebt“.
Vorbereitet: Arbeitsliste Abschnitt 10 mit `segen_08`, `wende_04`, `wende_07` (Originaltexte, Beispiel, Vorschlag) und fünf Fragen; neue offene Punkte KS-22 bis KS-28.
Nächster Schritt: Antworten auf die fünf Fragen, dann die übrigen vier Karten der Gruppe 1 (`loki_10`, `wende_12`, `schicksal_08`, `loki_06`).

## 2026-09-30: Rückkehrkarten (vierte Antwortrunde) und zweite Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `f73c762`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log „Rückkehrkarten: Zweites Leben, Wiedergeburt, Befreiung (vierte Antwortrunde, 30.09.2026)“): `segen_08` nur bei mindestens zwei ANDEREN toten Personen derselben Fraktion vergeben, bis zu drei Namen zur Auswahl (bei mehr als drei zieht der gespeicherte Generator, Auswahl gespeichert), Kartenbesitzer tippt, Fraktionsinfo nur für den Besitzer; `wende_04` die SL wählt die wiederzubelebende Person und darf dabei auch die Kartenspielerin wählen; `wende_07` Kartenspielerin wählt, Tod erst nach dem einmaligen Einsatz, sonst am Leben, keine Frist; Rückkehrrolle = Rolle vom Todeszeitpunkt, doppelte Rolle zulässig.
Offen: Vorauswahl-Zeitpunkt und Ersatz ungültiger Ziele (`segen_08`), Einzelsiegrollen, Einsatzbegriff (`wende_07`), Rückkehr-Ablauf und Wächter am Tor (KS-38 bis KS-40). Die drei Karten sind nicht vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 11 und 12 mit `loki_10`, `wende_12`, `schicksal_08`, `loki_06` (Originaltexte aus `cards.js`, fünf Fragen KS-29 bis KS-33) und Folgerunde KS-34 bis KS-40.
Nächster Schritt: Antworten auf KS-29 bis KS-33, dann die restlichen Gruppe-1-Details und Gruppe 2.

## 2026-09-30: Phoenix, Geheimrat, Neuer Anfang, Rollenroulette (fünfte Antwortrunde) und dritte Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `1020fcf`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Würfel, Zufallsziehung, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log „Rückkehr- und Rollenkarten: Phoenix, Geheimrat, Neuer Anfang, Rollenroulette (fünfte Antwortrunde, 30.09.2026)“): `loki_10` zwei sichtbare App-Würfel (Anzahl 1 bis 6, Lebensdauer 1, 1, 2, 2, 3, 3 Tage, Tag des Ausspielens zählt als erster Tag, Tod am Ende des Tages, die spielende Person ausgeschlossen, weniger Tote: alle anderen, kein Neuwurf); `wende_12` Dorf: jede Frage erlaubt, wahrheitsgemäße Antwort; `schicksal_08`: Kartenspielerin wählt zwei Lebende, Spielleitung bestimmt die Rollen der bisherigen Fraktion; `loki_06`: zwei zufällige Lebende derselben Fraktion (Dorf oder Werwölfe, keine Einzelsiegrollen) tauschen still; neue Rolle beginnt frisch, persönliche Zustände und bestätigte Sonderregeln (Kartenschlucker-Stapel, Schilde) bleiben, nur für diese zwei Karten. Formulierung zu `wende_04` präzisiert (SL darf auch die Kartenspielerin wählen, keine Regeländerung).
Offen: Phoenix: Tagesende gegen Fristablauf (KS-41 gestellt), ohne andere Tote, Wiederbelebung in der Frist, Rückkehrrolle, Sichtbarkeit (KS-46 bis KS-48); Geheimrat: Wolfsvariante nicht entschieden (KS-42 gestellt, Rest KS-35), Öffentlichkeit offen; `schicksal_08`, `loki_06`: KS-36, KS-37. Die vier Karten sind nicht vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 13 und 14 mit `segen_01`, `segen_07`, `segen_11` (Originaltexte aus `cards.js`, Fragen KS-43 bis KS-45), zwei Klärungen (KS-41, KS-42) und Folgerunde KS-46 bis KS-51.
Nächster Schritt: Antworten auf KS-41 bis KS-45, dann Restfragen der Gruppe 1 und die nächsten drei Karten der Gruppe 2 (`wende_02`, `wende_05`, `wende_11`).

## 2026-09-30: Phoenix-Tagesende, Geheimrat (Wolf), Heilende Hand, Blutpakt, Spiegelschutz (sechste Antwortrunde) und vierte Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `9a10d13`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Würfel, Zufallsziehung, Schild, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log „Phoenix-Tagesende, Geheimrat (Wolf), Heilende Hand, Blutpakt, Spiegelschutz (sechste Antwortrunde, 30.09.2026)“): `loki_10` Tagesende: Hinrichtung, Todeseffekte, Fristablauf der Rückkehrer, dann zweites Kartenfenster (die durch Fristablauf Verstorbenen nutzen ihre neue Karte dort); `wende_12` Wolf: Hinweise nur stumm, kein leises Sprechen; `segen_01` Dorf: Angriff verhindert plus persönlicher Schild nach den bestätigten Schildregeln, keine Nacht-Unsterblichkeit; `segen_07` Dorf: Spielleitung entscheidet nach Ermessen über null, ein oder zwei aufgedeckte Wölfe; `segen_11` Dorf: die App zieht zufällig einen lebenden Wolf über den gespeicherten Generator.
Offen: Phoenix im zweiten Fenster mit Lebensdauer 1 (KS-55 gestellt), KS-46 bis KS-48; Geheimrat Wolf: Aufrufreihenfolge, Bezugsnacht, Öffentlichkeit (KS-35); `segen_01`, `segen_07`, `segen_11`: Wolfsvarianten, Reihenfolge der Schutzwirkungen, Öffentlichkeit, Wolfsauswahl (KS-27, KS-49 bis KS-51). Keine dieser Karten ist vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 15 und 16 mit `wende_02`, `wende_05`, `wende_11` (Originaltexte aus `cards.js`, Fragen KS-52 bis KS-54), Phoenix-Sonderfall (KS-55), Bezugszeitpunkt „nächste“ (KS-56) und Folgerunde KS-57 bis KS-59.
Nächster Schritt: Antworten auf KS-52 bis KS-56, dann Restfragen der Gruppe 1 und die nächsten Karten der Gruppe 2 (`fluch_05`, `fluch_08`, `fluch_12`, `loki_12`).

## 2026-09-30: Verzweiflungsschrei, Notanker, Schicksalswende (Wolf), Phoenix-Ausnahme, Bezug "nächste" (siebte Antwortrunde) und fünfte Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `754b311`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Schutz, aufgeschobener Tod, Verwandlung, Würfel, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log "Verzweiflungsschrei, Notanker, Schicksalswende (Wolf), Phoenix-Ausnahme, Bezugszeitpunkt (siebte Antwortrunde, 30.09.2026)"): `wende_02` geheime Zielwahl der Kartenspielerin in der nächsten Nacht, Schutz sofort (Dorf: gegen Wolfsangriffe diese und die nächsten zwei Nächte, Wolf: gegen Hinrichtung in den nächsten zwei Tagesphasen), geschützte Person überlebt die Hinrichtung ohne Ersatz und Neuabstimmung, Tagesablauf bleibt; `wende_05` handelt bis zum tatsächlichen Tod normal, zählt für Siegbedingungen als tot, sonst nicht allgemein tot; `wende_11` Wolf genau eine Gelegenheit in der nächsten Nacht (Dorfvariante nicht entschieden); `loki_10` Ausnahme (zweites Fenster, Lebensdauer ein Tag: Rückkehrer leben bis zum Ende des nächsten Tages); "nächste" = nächstes entsprechendes Ereignis nach dem Ausspielen, abweichende Kartenregeln gehen vor.
Offen: `wende_02` Selbstwahl, fehlende Ziele, Position in der Nachtreihenfolge, Restschutz (KS-68); `wende_05` Vollstreckungszeitpunkt, Entscheider (KS-64 gestellt), Siegprüfung gegen Todesreaktionen (KS-63 gestellt), Rest (KS-69); `wende_11` Wolf-Details und gesamte Dorfvariante (KS-70); `loki_10` KS-46 bis KS-48. Keine dieser Karten ist vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 17 und 18 mit `fluch_05`, `fluch_08`, `fluch_12` (Originaltexte aus `cards.js`, Fragen KS-60 bis KS-62), zwei Klärungen zu `wende_05` (KS-63, KS-64) und Folgerunde KS-65 bis KS-70.
Nächster Schritt: Antworten auf KS-60 bis KS-64, dann Restfragen der Gruppe 1 und `loki_12` (Gruppe 2).

## 2026-09-30: Gebrochener Schild, Kettenfluch, Doppeltes Leid, Notanker (achte Antwortrunde) und sechste Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `8b9d2e1`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Schutzpause, Mittod, zusätzlicher Tod, aufgeschobener Tod, Verwandlung, Erbe, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log "Gebrochener Schild, Kettenfluch, Doppeltes Leid, Notanker (achte Antwortrunde, 30.09.2026)"): `fluch_05` Schutzwirkungen pausieren und wirken danach wieder, Laufzeit wird nicht verlängert, unverbrauchter Schild bleibt erhalten, keine Ausnahme für gekaufte Schilde (KS-60, 1A); `fluch_08` nächste lebende Person der geforderten Fraktion in der angegebenen Richtung, Wolf nach rechts, Dorf nach links (KS-61, 2B); `fluch_12` der zusätzliche Tod kann durch eine passende Schutzwirkung verhindert werden, persönlicher Schild fängt ihn ab, kein Ersatz (KS-62, 3A); `wende_05` Wolfskind-Verwandlung und Lehrling-ähnliche Erbfolgen schon beim Aufschub vor der Siegprüfung, keine Vorverlegung anderer Todesreaktionen (KS-63, 4B), automatischer Aufschub des nächsten passenden Todes nach dem Ausspielen (KS-64, 5C).
Konflikt (nicht gelöst): Lehrling-Erbe setzt einen Meister voraus, der danach nicht mehr handelt; beim Aufschub handelt er weiter (zwei lebende Träger derselben Rolle, gestellt als KS-74); Reihenfolge und doppelte Auslösung beim tatsächlichen Tod notiert als KS-79.
Offen: `fluch_05` KS-65 Rest; `fluch_08` KS-66 Rest; `fluch_12` KS-67 Rest; `wende_05` KS-69, KS-79; `wende_02` KS-68; `wende_11` KS-70; `loki_10` KS-46 bis KS-48. Keine dieser Karten ist vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 19 und 20 mit `loki_12`, `segen_03`, `segen_04` (Originaltexte aus `cards.js`, Fragen KS-71 bis KS-73), zwei Klärungen (KS-74 Lehrling-Erbe beim Notanker, KS-75 Dauerzählung bei `fluch_05`) und Folgerunde KS-76 bis KS-79.
Nächster Schritt: Antworten auf KS-71 bis KS-75, dann Restfragen der Gruppe 1 und die Schutz- und Schildregeln (KS-27) vor den Detailpunkten der Gruppe 2.

## 2026-09-30: Kosmisches Gleichgewicht, Wachsame Augen, Stille Nacht, Notanker, Gebrochener Schild (neunte Antwortrunde) und siebte Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `25beba4`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, zusätzlicher Tod, Neuabstimmung, Wolfssperre, Schutzpause, Erbe, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log "Kosmisches Gleichgewicht, Wachsame Augen, Stille Nacht, Notanker, Gebrochener Schild (neunte Antwortrunde, 30.09.2026)"): `loki_12` jeder sonstige passende Tod löst einen Tod der anderen Fraktion aus, ein von der Karte verursachter Tod nicht erneut, Spielleitung bestimmt die Opfer nach Kartentext (KS-71, 1A); `segen_03` Dorf: Dorf entscheidet nach der Enthüllung, bei Ablehnung Neuabstimmung ohne automatisches Ersatzopfer (KS-72, 2B); `segen_04` Dorf: keine Wolfstötungen in der Nacht, andere Wolfsfähigkeiten bleiben (KS-73, 3B); `wende_05` Lehrling erbt sofort vollständig, Meister handelt bis zum tatsächlichen Tod weiter, kein zweites Erbe (KS-74, 4A); `fluch_05` Tag des Ausspielens zählt als erster Tag der Schutzpause, Ende am Ende des gezählten Tages (KS-75, 5C).
Offen: `loki_12` KS-76 (Folgetode gestellt als KS-84); `segen_03` KS-77 (erneute Enthüllung gestellt als KS-83); `segen_04` KS-78; `wende_05` KS-69, KS-79; `fluch_05` KS-65 und Ablaufzeitpunkt KS-88; `fluch_08` KS-66; `fluch_12` KS-67; `wende_02` KS-68; `wende_11` KS-70; `loki_10` KS-46 bis KS-48. Keine dieser Karten ist vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 21 und 22 mit `segen_09`, `segen_13`, `fluch_02` (Originaltexte aus `cards.js`, Fragen KS-80 bis KS-82), zwei Klärungen (KS-83, KS-84) und Folgerunde KS-85 bis KS-88.
Nächster Schritt: Antworten auf KS-80 bis KS-84, dann die Schutz- und Schildregeln (KS-27, KS-21) vor den Detailpunkten der Gruppen 2 und 3.

## 2026-09-30: Gerechter Zorn, Schattenvorteil, Falsche Fährte, Wachsame Augen, Kosmisches Gleichgewicht (zehnte Antwortrunde) und achte Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `514b9b6`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, verhinderte Hinrichtung, Scheitern von Nachtfähigkeiten, Falschauskunft, Neuabstimmung, zusätzlicher Tod, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log "Gerechter Zorn, Schattenvorteil, Falsche Fährte, Wachsame Augen, Kosmisches Gleichgewicht (zehnte Antwortrunde, 30.09.2026)"): `segen_09` Dorf: Hinrichtung wird verhindert, kein Todesereignis, Tagesablauf bleibt (KS-80, 1A); `segen_13` Wolf: die erste schädliche oder aufdeckende Nachtfähigkeit, die einen Wolf trifft, scheitert (KS-81, 2B); `fluch_02` Dorf: eine reguläre Rollenauskunft wird verfälscht, ohne mündlichen Ersatz (KS-82, 3A); `segen_03`: Enthüllung und Ablehnung nur beim ersten Wahlgang (KS-83, 4A); `loki_12`: der Kartentod und seine indirekten Folgen lösen die Karte nicht erneut aus (KS-84, 5A).
Offen: `segen_09` KS-85; `segen_13` KS-86; `fluch_02` KS-87; `segen_03` KS-77; `loki_12` KS-76; ältere Punkte unverändert (KS-65 bis KS-70, KS-78, KS-79, KS-88). Keine dieser Karten ist vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 23 und 24 mit `fluch_04`, `fluch_07`, `fluch_10` (Originaltexte aus `cards.js`, Fragen KS-89 bis KS-91), zwei gemeinsamen Klärungen zu Schutz und Schild (KS-92 verhinderte Hinrichtung, KS-93 Karten-Tode) und Folgerunde KS-94 bis KS-97.
Nächster Schritt: Antworten auf KS-89 bis KS-93, dann der Rest der Schildregeln (KS-97) vor den Detailpunkten der Gruppen 2 und 3.

## 2026-10-01: Verrat, Alptraum, Schlechtes Omen, verhinderte Hinrichtung, Schild gegen Kartentode (elfte Antwortrunde) und neunte Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `4509134`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Schildänderung, Rudelzwang, Bewertung durch die Spielleitung, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log "Verrat, Alptraum, Schlechtes Omen, verhinderte Hinrichtung, Schild gegen Kartentode (elfte Antwortrunde, 01.10.2026)"): `fluch_04` Wolf: das Rudel muss eine eigene Wolfsperson als Ziel wählen, Dorfpersonen sind nur vor diesem Rudelangriff verschont (KS-89, 1A); `fluch_07` Wolf: gemeinsame Rudelangriffe entfallen, eigene Tötungsfähigkeiten einzelner Wölfe bleiben, bewusst anders als `segen_04` Dorf (KS-90, 2B); `fluch_10` Wolf: Ermessen der Spielleitung zu „starke Rolle erwischt“ (KS-91, 3A); allgemein: durch persönlichen Schild verhinderte Hinrichtung verbraucht den Schild, kein Ersatzopfer, keine neue Abstimmung wegen des Schilds, Tagesablauf bleibt (KS-92, 4A); persönliche Schilde verhindern auch Kartentode (KS-93, 5A).
Offen: `fluch_04` KS-94; `fluch_07` KS-95; `fluch_10` KS-96; Dorfvarianten der drei Karten nicht entschieden; Schild nur noch KS-97 (Reihenfolge, Rudelangriff, Todesketten, „ein Schild“ je Person); ältere Punkte unverändert. Keine dieser Karten ist vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 25 und 26 mit `wende_03`, `wende_06`, `schicksal_06` (Originaltexte aus `cards.js`, Fragen KS-98 bis KS-100), zwei Klärungen (KS-101 Verrat Dorf „getroffen“ bei verhinderter Hinrichtung, KS-102 Schlechtes Omen Dorf bei überlebendem Wolf) und Folgepunkten KS-103 bis KS-105.
Nächster Schritt: Antworten auf KS-98 bis KS-102, dann der Rest der Schildregeln (KS-97), danach `loki_03` als letzte Karte der Gruppe 3.

## 2026-10-01: Wendepunkt, Trotz, Zeitsprung, Verrat, Schlechtes Omen (zwölfte Antwortrunde) und zehnte Kartenrunde, nur Dokumentation
Status: dokumentiert auf `feature/night-ui-expansion` (Ausgangs-HEAD `be090a9`), kein Merge. Kein GDScript, kein Test, kein Schema, keine Oberfläche geändert; Kartenmechanik, Zielwahl des Rudels, Schutzänderung, Nachtzählung, Wiederholung von Wahlgängen, Todesbedingung, Kartenverteilung, Kartentausch und Kartenschlucker weiterhin nicht implementiert.
Entschieden (Decision Log "Wendepunkt, Trotz, Zeitsprung, Verrat, Schlechtes Omen (zwölfte Antwortrunde, 01.10.2026)"): `wende_03` Wolf: gemeinsamer Schritt, zwei verschiedene Personen, Schutz je Opfer einzeln (KS-98, 1A); `wende_06` Wolf: direkte Tötungen von Wölfen durch Rollenfähigkeiten einschließlich Gift werden in der Nacht verhindert, Todesketten und Kartentode bleiben möglich (KS-99, 2A); `schicksal_06`: die übersprungene Nacht zählt als Nacht, Fristen laufen weiter, Aktionen und Ansagen entfallen, nicht auf `loki_03` übertragen (KS-100, 3A); `fluch_04` Dorf: Auswahl einer Dorfperson zur Hinrichtung genügt, auch bei Schildverhinderung (KS-101, 4A); `fluch_10` Dorf: nur ein tatsächlicher Hinrichtungstod des Wolfs zählt, bei Schildverhinderung tritt der Zusatztod ein (KS-102, 5A).
Offen: `wende_03` KS-103; `wende_06` KS-104; `schicksal_06` KS-105 samt Wechselwirkung mit "kein Tod" (gestellt als KS-109, KS-110); `fluch_04` KS-94; `fluch_10` KS-96; Schild KS-97; Dorfvarianten von `wende_03` und `wende_06` nicht entschieden. Keine dieser Karten ist vollständig spezifiziert.
Vorbereitet: Arbeitsliste Abschnitte 27 und 28 mit `loki_03`, `segen_06`, `segen_12` (Originaltexte aus `cards.js`, Fragen KS-106 bis KS-108; Übernahme der Zeitsprung-Regel bei Zeitwarp ausdrücklich zur Entscheidung), zwei Klärungen zu Zeitsprung (KS-109 Giftpranke des Giftwolfs, KS-110 Wahl des Todespredigers) und Folgepunkten KS-111 bis KS-113.
Nächster Schritt: Antworten auf KS-106 bis KS-110, dann der Rest der Schildregeln (KS-97), danach Gruppe 4 ab `segen_14`.

## 2026-10-01: Totenreichkarten und Kartenschlucker umgesetzt (alle 80 Karten, 119 Varianten)
Status: umgesetzt auf `feature/night-ui-expansion` (PR #3), kein Merge. Regelkern, Spielaufbau, Cockpit (Kartenfenster, Karteneingaben, Würfel, Handzeichen, Tagesregeln), Speicherformat (Schema 15, Regelversion 0.15, alte Spielstände unverändert als nicht kompatibel gemeldet), Regelbuch Kapitel 13, Abschlussbericht mit stillen Mitsiegern.
Entschieden: Product-Owner-Antworten KS-106 bis KS-110 (Decision Log „Totenreichkarten und Kartenschlucker: Umsetzung“); alle übrigen Auslegungen sind dort als technische bzw. redaktionelle Entscheidung innerhalb dieses Auftrags gekennzeichnet.
Nachweis: `docs/role-migration/15-totenkarten-umsetzungsmatrix.md` (80 Karten mit Kern, UI, DE/EN, Tests); Tests je Mechanikfamilie, je Kartenvariante (Spielbarkeit, ungültige Eingaben, öffentliche Angaben), Fuzz mit Karten, Oberflächenpartien mit 6, 12 und 24 Personen.
Offen: keine Prüfung auf Tablet, Touch, visuell oder Audio; keine Zusicherung der Fehlerfreiheit aller Kombinationen.
Übergabe: `docs/development/HANDOVER-TOTENKARTEN.md`.

## 2026-10-01: Spielbrettzentriertes Cockpit
Status: umgesetzt auf `feature/night-ui-expansion` (PR #3, Ausgangs-HEAD `e945d0a`), kein Merge. Regelkern, Kartenwirkungen und Speicherformat unverändert.
Umgesetzt: Das Brett belegt etwa 85 bis 92 Prozent der nutzbaren Fläche (keine Seitenspalte). Die Ansagekarte liegt in der freien Tischmitte des Sitzkreises: Text scrollt, alle Aktionsbuttons stehen in einem festen Bereich darunter. Schmale Kopfleiste (Phase, Speicherstand, „Erneut speichern“) und schmale Werkzeugleiste. Wählbare Ziele, Auswahl und handelnde Personen tragen zusätzlich Textzeichen (›, ✓, •). Detailebenen (gezeigte Karte, Hinweis, Ansage, Rollenkarte, Kartenfläche) als `DetailPanel` mit scrollendem Text und festen Buttons. Bedienhand spiegelt den Sitzkreis nicht mehr, sie setzt nur das Ende der Hauptaktion. Tischfläche nachts blau, am Tag braun (Platzhalter, keine neuen Assets).
Geschlossen: `check-role-docs.js` (7 Fehler) und `check-coverage.py` (Kartenschlucker fehlte) durch Rollenunterlagen 01, 02 (§4.72), 03, 06 sowie DE/EN-Rollenbuch- und Leitfadenzeilen; die veraltete Sonderregel „kartenschlucker darf keinen Eintrag haben“ im Prüfer entfernt. Die gelockerte Kartenbutton-Anforderung („durch Scrollen erreichbar“) ist durch den Layoutnachweis „Text scrollt, Pflichtaktionen ohne Scrollen sichtbar“ ersetzt.
Verifiziert (Windows, Godot 4.7.2, headless): Import Exit 0 ohne Skriptfehler; Vollsuite 1457 Tests, 0 fehlgeschlagen, Exit 0 (vorher 1452, 5 neue Tests in `test_board_layout`); Mutationsprobe: ohne Höhenbegrenzung im `DetailPanel` ist der Scrolltest rot. Prüfer jeweils Exit 0: `check-asset-register.js`, `check-godot-i18n.js`, `check-role-docs.js`, `check-coverage.py`, `node --test` (38 Tests).
Offen: keine Sicht-, Tablet- oder Touchabnahme. Das neue Aussehen ist nicht gesehen. Anleitung: `docs/ui/pc-test-pr3.md` Teil N.

---

## Godot: Prüfung der visuellen Roadmap (01.10.2026)
Status: PRÜFUNG ABGESCHLOSSEN, keine Umsetzung, keine Codeänderung
Verifiziert: nur Lesen (Git, Szenen, Register, Roadmap). Kein Test, keine Bildgenerierung.
Befund: `9ca16c2` (feature/night-ui-expansion, PR #3 offen) baut auf `8197ee6` (main) auf, kein Nachziehen nötig.
Roadmap `docs/masterplan/entwurf-visuell/GRIMMHAIN-VISUELLE-ROADMAP.md` mit Änderungen machbar:
P3 größer als beschrieben (runde Porträtplätze, 24 Namensschilder auf 4:3 knapp), Angriffsanimation nur bei
öffentlichem Tod und standardmäßig ohne Krallen (Ursache geheim), Totenreichkarten-Schalter existiert (`role_step.gd`).
Nächster Schritt: Freigabe von Auftrag 1 (P0+P1) und Entscheidung, wer die Bilder erzeugt (Higgsfield-MCP mit Credits
oder Markus selbst). Keine Medien aus dem Altbestand sind freigegeben.


## 2026-10-01: Visuelle Roadmap, Auftrag 1 (P0 + P1), Zwischenstand
Status: Branch `feature/visual-night-board` (lokal, ab `9ca16c2`, kein Push, PR #3 unberührt). Nichts committet, kein Code in `godot/` geändert.
Umgesetzt: Roadmap und Referenzen nach `docs/masterplan/entwurf-visuell/` kopiert; Art Direction `docs/assets/ART-DIRECTION-NIGHT-BOARD.md`; Bildbriefings für ChatGPT (G1 Nachtdorf, G2 Porträtblätter A und B, G3 Kartenrahmen) in `C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/BRIEFINGS-FUER-CHATGPT.md`.
P0 gesehen (Screenshots in `.../p0-istzustand/`): Cockpit mit 24 Personen bei 1024x768: ein Ring aus 7 + 7 + 5 + 5 rechteckigen Textbuttons, die Ansagekarte füllt etwa 65 % der Brettfläche; Zielwahl zeigt alle wählbaren Plätze mit goldenem Rahmen. Totenreichkarten-Schalter existiert im Rollenschritt (kein Fehler).
Platzvariante (Mockup mit alten Platzhalterbildern, außerhalb von `godot/`): Einring, Porträt 60 px, Nummer als Badge, Name auf Schild 84 px (V1b) empfohlen; versetzter Ring und zwei Ringe schlechter (Details in der Art Direction).
Verifiziert: Screenshots mit Godot 4.7.2 (OpenGL, sichtbares Fenster) erzeugt und angesehen. Keine Testsuite (Dokumentation und Wegwerf-Mockup, kein Spielcode).
Offen: Markus erzeugt die Bilder in ChatGPT; danach Mockup mit echten Bildern neu rendern und Abnahme 1. Kein Tablet-, Touch- oder Audiotest. Alte Medien (Hintergrund, Porträts) sind nur Platzhalter ohne Freigabe.

## 2026-10-01: Mockup V1c mit Seitenleisten (Ergänzung zu Auftrag 1)
Markus hat V1b als Platzaufteilung abgenommen. Mockup ergänzt um linke Leiste (Protokoll, Rollen, Spielleitung, Verbergen), rechte Leiste (Optionen, Ton, Hilfe mit Lexikon/Regelbuch), unten links Phasenanzeige mit Timer-Platz und „Legende“; die untere Werkzeugleiste entfällt. Nur Platzhalter ohne Funktion.
Messung: Leistenbreite 52 px (48 px Bedienfläche); der Ring bleibt bei 1024x768 unverändert (a=458, b=284,5 wie V1b), 0 Überschneidungen der drei Bereiche mit den 24 Plätzen (ebenso bei 1280x800). Die Leisten sind nicht vollhoch, sondern enden über den äußersten Plätzen.
Neue Entscheidung: Anzeige-Timer für Tagphase und Diskussion in `DECISIONS.md`, Roadmap P3 ergänzt (beide Kopien). Konflikt mit „Die App hat keinen Timer“ im Decision Log benannt, dort nicht geändert.
Screenshots: `mockup-platzhalter/P1-V1c-seitenleisten-*.png`. Kein Code in `godot/`, nichts committet.

## 2026-10-01: Mockup mit echten Bildern (Auftrag 1, Schritt 6)
Eingebaut ins Mockup V1c (außerhalb von `godot/`, nichts committet): G1 als Hintergrund mit Abdunklung und Vignette per Shader (nicht neu generiert), 10 runde Porträts aus G2A (6) und G2B (oben 3, unten Mitte; die zwei Fast-Duplikate ausgelassen), G3 mit freigestelltem Magenta als 9-Slice-Kartenrahmen (Ecken 46 px bei 25 % Verkleinerung), Porträtring in Godot gezeichnet. Nachbarn haben nie dasselbe Gesicht (Schritt 3 durch 10 Gesichter).
Screenshots: `C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/mockup-echt/` (1024x768, 1280x800), angesehen. Herkunft aller vier Bilder: ChatGPT-Bildgenerierung 01.10.2026, Prompts aus `BRIEFINGS-FUER-CHATGPT.md`; Kandidaten, keine Freigabe, nicht im Register.
Decision Log: Satz „Die App hat keinen Timer“ verweist jetzt auf die Timer-Entscheidung in `DECISIONS.md`.
Offen: Abnahme 1 durch Markus; Tablet-/Touchprüfung fehlt weiter.

## 2026-10-01: Mockup V2 nach Spielfeld.png (Abnahme 1 erteilt)
Markus bestätigt die Richtung; verbindliche Layout-Vorlage ist sein Design `Spielfeld.png` und `Full UI.png`. Mockup V2 (außerhalb von `godot/`, nichts committet) baut es mit den echten Teilen nach: G1-Hintergrund mit Abdunklung und gedämpften Randreflexen, Nachtreihenfolge-Leiste, Platzrahmen mit Statusringen, Laschen Protokoll/Optionen, Nacht und Timer, Rückgängig und Nächster Schritt, Aktionskarte A (Rollenbild) und B (G3-Rahmen), Porträts G2 gegen Village_*.
Screenshots: `C:/Users/Marku/Downloads/Grimmhain-P1-Nachtentwurf/mockup-v2/` (angesehen). Ergebnis und Empfehlungen im Bericht.
Neu: Entscheidung Platzporträt-Auswahl in `DECISIONS.md`; Herkunftsvermerk (Nutzerangabe, keine Freigabe) in 44 Registerzeilen `ui-*` und in `docs/assets/ORIGIN-NOTES-NIGHT-BOARD.md` (nicht versionierte Teile, ChatGPT-Kandidaten). `node tools/check-asset-register.js`: Register vollständig und konsistent.
Offen: Nacht-Timer (Design zeigt ihn, `DECISIONS.md` regelt nur Tag und Diskussion), öffentliche Statusringe und Rollenleiste gegen Geheimhaltung klären, Texte in den Laschenbildern. Kein Tablet-/Touchtest.

## 2026-10-01: P0 und P1 abgeschlossen (Abnahme 1)
Entscheidungen von Markus in `DECISIONS.md` (Karte A, G2-Porträts mit leichter Abdunklung, Leiste auf 4:3 einklappbar, Timer auch nachts abschaltbar, Tablet sieht nur die Spielleitung und „Verbergen“ blendet Geheimes aus, Spielfeld.png und Full UI.png verbindlich). Timer-Entscheidung ergänzt, Satz im Decision Log aktualisiert.
Roadmap: P0 und P1 als erledigt markiert (Verweis auf mockup-v2); offen bleibt der Punkt, die Roadmap nach `docs/masterplan/VISUAL-EXPERIENCE-ROADMAP.md` zu übernehmen und im Masterplan zu verlinken.
Abgelegt in `docs/assets/p1-mockup/` (Skripte, zugeschnittene Bilder, README, keine Laufzeitassets). 23 neue Medien im Register (Status `ungeklärt`, Herkunft als Nutzerangabe). `node tools/check-asset-register.js`: Register vollständig und konsistent (336 Zeilen). Mockup-Skript aus dem Repo-Ordner einmal gestartet (Screenshot erzeugt).
Commit lokal auf `feature/visual-night-board`, nur Dokumentation und `docs/assets/`, kein Push, `CLAUDE.md` (Nutzeränderung) nicht enthalten.

## 2026-10-01: P2 vorbereitet (nur Planung)
Grafikliste `docs/assets/P2-GRAFIKLISTE.md`: Claude Code kann aus dem Bestand ableiten (nicht ausgeführt): textfreie Lasche Protokoll (vorhanden) und Optionen, bereinigte Nachtreihenfolge-Slots, Rollenbilder ohne Kartenecken als Übergangslösung, Rollenkartenrahmen ohne schwarzen Block. ChatGPT nötig: Porträtblätter C und D (je 8 Gesichter, ergibt 26 statt der nötigen 24), Statusabzeichen, Rollensymbol-Probeblatt (12). Briefings: `Downloads/Grimmhain-P1-Nachtentwurf/P2-BRIEFINGS-FUER-CHATGPT.md`. Nichts generiert, nichts repariert, nichts bestellt.
Nächster Schritt: Markus erzeugt die vier Bilder P2-1 bis P2-4, danach P2-Ausführung (Reparaturen und Einbau ins Mockup) und P3.

## 2026-10-01: Testregeln in CLAUDE.md
Abschnitt „Testregeln (verbindlich, Markus 01.10.2026)“ ersetzt die vorläufige Testumfang-Vorgabe (Commit `f9c68a5` auf main). Keine Code- oder Testläufe. P3-Stand liegt auf `feature/visual-night-board` (siehe dortige PROGRESS.md).

## 2026-10-01: P2 ausgeführt
Ergebnis: Mockup V3 (1024x768 und 1280x800, Leiste voll und eingeklappt), angesehen: `Downloads/Grimmhain-P1-Nachtentwurf/mockup-v3/`, dort auch das Kontaktblatt `P2-kontaktblatt-gesichter-24.png`.
24 eindeutige Gesichter (26 Kandidaten aus A, B ohne zwei Duplikate, C, D; D5 und D6 als zu ähnlich aussortiert, fünf grenzwertige Paare in der Grafikliste). Statusabzeichen freigestellt und als 24-px-Abzeichen an vier Plätzen im Mockup (Schutz, Gift plus Stumm, Markiert, Stumm). Rollensymbole freigestellt (11 von 12, Wolfskind-Symbol verworfen), 7 davon in der Nachtreihenfolge-Leiste, Wolfskind mit Kreisbild als Übergang.
Repariert: Laschen textfrei (Zahnrad selbst gezeichnet), Slots ohne Säume und Speckles mit dunklem Sockel, Kartenrahmen mit transparenter Platte, Kreismaske für alle 72 Nachtbilder.
Nicht gelöst: aktiver Slot behält einen leichten rosa Hauch am Rand, Stumm-Abzeichen bei 24 px grenzwertig, „Rückgängig“ überlappt bei 1024x768 knapp Platz 11 (Layout aus V2), nichts auf dem Tablet geprüft.
Entscheidung: Stil der Rollensymbole für alle 72 Rollen in `DECISIONS.md`. Art Direction Abschnitt 7 (Abzeichen 24 px, größer `marker-*.webp`). Herkunft in `ORIGIN-NOTES-NIGHT-BOARD.md` Abschnitt 5, 119 neue Registerzeilen (`node tools/check-asset-register.js`: vollständig und konsistent).
Schätzung Rollensymbole: 61 fehlende Symbole, mindestens 6 Blätter, realistisch 7 bis 8 (Grafikliste).
Abgelegt in `docs/assets/p2-mockup/`, nichts in `godot/`, lokaler Commit auf `feature/visual-night-board`, kein Push.

## 2026-10-01: P3 Nachtbrett, Zwischenstand 2 (Commit `cfcf1d1`, Vollsuite nicht abgeschlossen)
Branch `feature/visual-night-board`, lokal, kein Push, PR #3 unberührt.
Stand: Nachtbrett im Code fertig (Hintergrund, 24 eindeutige Porträts, Abzeichen, Nachtleiste, Laschen, Zielplatz mit Pfeilen, „i“, Dock, Speicherzeile unten, Verbergen, Anzeige-Timer im Block `ui` der Speicherhülle, Asset-Status `intern-freigegeben` mit Release-Sperre). Commits: `cfcf1d1` (P3-Stand), `1446580` (Testregeln in `CLAUDE.md`).
Verifikation: gezielt grün (jeweils 0 Fehler): display_timer, night_board_view, portrait_assignment, portrait_ring_layout, night_board, timer_save, board_layout, cockpit_screen, cards_ui, cards_ui_closing, handedness, cockpit_polish, ui_i18n, setup_model, full_round_ui; `node tools/check-asset-register.js` Exit 0 (657 Dateien), Asset-Tests 19/19. Der Vollauf wurde bei ca. 106 Tests ohne Fehler abgebrochen: kein Gesamtergebnis. Nach der letzten Kartenänderung (Zielplatz neben den Aktionen) liefen keine Tests, nur Screenshots (`Downloads/Grimmhain-P1-Nachtentwurf/p3-spielbar/wip/`, noch nicht nach `p3-spielbar/` übernommen).
Offen (blockiert Abnahme 2): Tests nach der Kartenänderung (`cards_ui*`, `handedness`, `cockpit_screen`) einmal bestätigen; Screenshots ansehen und übernehmen. Später: Namen am Rand bei 24 Personen und 4:3 teils stark gekürzt, Anweisungstext scrollt auf kleiner Karte, Nacht-Timer-Schalter im Einstellungsbildschirm, Spielerauswahl der Porträts (P4).
Lehre: Testläufe nicht mit Dateiänderungen in `godot/` überlappen; Python-Edits von CRLF-Dateien nur im Textmodus, Pfade für Python als Windows-Pfad (nicht `/tmp`).
Neue Testregeln: siehe `CLAUDE.md` (Abschnitt „Testregeln“).


## 2026-10-02: P4 Atmosphäre Nachtbrett (Paket 1)
Branch `feature/visual-night-board`, lokal, kein Push. Nur Hintergrund, Licht und Nebel; Rahmen, Knöpfe und Karten unverändert.
Neu: Nachtszene als Brett-Hintergrund (cover, zentriert), Fensterschein per ID-Karte und einem Shader (`night_backdrop.gdshader`, 47 Inseln, je Insel eigene Schwankung 85 bis 100 %, seltenes weiches Absacken), Nebelebene (`night_fog.gdshader`, 18 % am Rand, 40 % davon über dem Ring). Reduzierte Bewegung hält Schein und Nebel an. Keine Töne, keine Spiellogik.
Wiederholbar: `python tools/build_night_windows.py` (erzeugt Grundbild, ID-Karte und Kontrollbild), danach `godot --path godot --import`. Herkunft: `docs/assets/ORIGIN-NOTES-NIGHT-BOARD.md` Abschnitt 6; die alte `village-night.webp` ist ungenutzt, aber nicht entfernt.
Abnahme-Material: `Downloads/Grimmhain-P1-Nachtentwurf/p4-atmosphaere/` (Screenshots 24 Spieler in 3 Größen, Kontrollbild, Video 1024x768).

## 2026-10-02: P4 Atmosphäre nachgebessert (Paket 1b)
Nachtszene v2 (Platz größer), Platzmitte auf Ringmitte gelegt (cover mit 5 % Überdeckung, kein Rand). Fensterschein neu: 47 Inseln, Schwankung 55 bis 100 % (Periode 2 bis 6 s), seltenes weiches Absacken auf 30 %, Lichthof pro Fenster, alles in `night_backdrop.gdshader`; Nebel am Rand 25 %. Lehre: Beim Schreiben von Shadern mit Umlauten per Python `encoding="utf-8"` setzen, sonst Parse-Fehler und stilles Fehlen des Effekts (Log auf `ERROR` prüfen). Gemessen im Video: Fensterhelligkeit schwankt im Median um 32 % (max/min je Fenster), Vergleichsbild `p4-atmosphaere/flackern-vergleich.png`.

## 2026-10-02: P5 Rahmen und Bedienflächen (Paket 2)
Skalierung: Die App skalierte schon richtig (Stretch `canvas_items`, `expand`); das Aufnahmewerkzeug schaltete die Skalierung ab und zeigte 2360x1640 deshalb in 1x. Werkzeug jetzt wie das Gerät (`--logical` für den alten Modus), Basisgröße 1024x768 (eigener Commit `6815e2f`).
Neu: sieben Teile aus `ui-paket-v1.png` (`godot/assets/ui/hain/`, `tools/build_grove_ui.py`, Herkunft Abschnitt 7 der ORIGIN-NOTES), `GroveStyleBox` (Neun-Felder-Rahmen mit 2 Texturpixeln je logische Einheit), `GroveSkin`. Eingebaut: Platzrahmen mit Nummer im Sockel und Namensschild (24 Plätze, Porträtfenster 56,4 bei Rahmenbreite 86), roter Schein für die handelnde Person, tote Plätze entsättigt, Aktionskarte im Kartenrahmen mit Medaillon, Hauptaktion rot und Nebenaktionen dunkel. Laschen, Nachtleiste und Timer-Kartusche unverändert.
Verifikation: gezielt grün (0 Fehler): portrait_ring_layout, night_board, board_layout, cockpit_screen, cockpit_polish, cards_ui (inkl. cards_ui_closing), handedness. Keine Vollsuite (reine Oberfläche). Abnahme-Bilder: `Downloads/Grimmhain-P1-Nachtentwurf/p5-ui/`.
Grenzen: Bei 24 Personen auf 1024x768 sind Namen an den Seiten auf etwa 7 bis 10 Zeichen gekürzt. Die Dock-Knöpfe sind knapp bemessen, weil die Speicherfehler-Zeile daneben sonst umbricht. Kein Tablet-/Touchtest.

## 2026-10-02: P5b Korrekturen (Zielwahl, Kartentext, gesperrter Knopf, Namen)
Zielwahl: wählbar = dezenter kühler Silberschimmer, gewählt = heller Mondsilber-Schein plus Häkchen, nicht wählbar leicht abgedunkelt, handelnd blutrot; kein Gold mehr, der Nummernsockel wird in jedem Zustand zuletzt über den Ring gezeichnet. Das „›“ steht nicht mehr auf dem Schild (nur im Button-Text für Bedienungshilfe und Tests).
Kartentext: Karte füllt die freie Tischmitte (kann nicht höher, ohne Plätze zu verdecken; Tischmitte jetzt aus Ringradius und tatsächlichen Schildbreiten berechnet, dadurch größer). Dann schrumpft die Schrift schrittweise (bis 15), danach das Rollenbild und die Zeilenabstände, erst dann scrollt der Text mit sichtbarem Pfeil (`ScrollHint`). Gesperrter Hauptknopf: dunkle Fläche mit hellgrauer Schrift. Fokus über Tönung statt Fokusrahmen (Godot zeichnet den Fokusrahmen sonst über den gesperrten Knopf).
Namen: Schrift 13 bis 10, dann kürzen; Schilder dürfen zur freieren Seite wachsen (`plate_spans`), Token breiter (d + 40).
Verifikation: gezielt grün (0 Fehler): portrait_ring_layout, night_board, board_layout, cockpit_screen, cockpit_polish, cards_ui (inkl. cards_ui_closing), handedness. Keine Vollsuite. Abnahme-Bilder: `Downloads/Grimmhain-P1-Nachtentwurf/p5b-ui/`.
Grenzen: Bei 1280x800 mit Zielwahl scrollt der Kartentext noch (letzte Zeile „Gewählt: …“ angeschnitten, Pfeil sichtbar). Sehr lange Namen werden an dichten Stellen weiter gekürzt (7 bis 9 Zeichen). Lehre: Kein `await` auf `process_frame` in Knoten, die Tests oder Ansichten freigeben (Laufzeitfehler „class instance is gone“); schrittweise Logik in `_process`.

## 2026-10-02: P6 Bedienteile im Hain-Stil (Paket 3)
Neu: sechs Teile aus `ui-paket-v2.png` (side_tab, night_bar mit geschützter Mittelspange, role_medallion, cartouche, icon_button_round, back_plate) plus Mondsilber-Pfeile (umgefärbt), `tools/build_grove_ui.py --source2`, Herkunft Abschnitt 8 der ORIGIN-NOTES, Register ergänzt. Eingebaut: Laschen mit Buch/Zahnrad, Nachtleiste (Medaillons links und rechts der Spange, aktiv = blutroter Ring + Raute, erledigt = gedämpft + Haken), Kartusche unten links, runde Knöpfe (Auge, Schloss, i), Zurück als Platte mit Pfeil (Text bleibt für Bedienungshilfe). Kein Gold mehr auf dem Brett; neue Tokens MOON_SILVER*, BLOOD_RED*. "Abbrechen ..." einzeilig (Kurzlabel, voller Text als Tooltip und accessibility_name).
Nebenbei: ui_theme war seit P5b rot (Farbwerte in scroll_hint und game_seat_token), jetzt Tokens, Verhalten gleich.
Verifikation: gezielt grün (0 Fehler): night_board, board_layout, cockpit_screen, handedness, cockpit_polish, cards_ui, timer_save, ui_architecture, ui_theme, portrait_ring_layout, night_board_view. Keine Vollsuite. Abnahme: `Downloads/Grimmhain-P1-Nachtentwurf/p6-ui/`.
Grenzen: Die Kartusche musste schmal bleiben (Speicherzeile daneben); auf 4:3 zeigt die ausgeklappte Leiste 6 Rollen, dann blättern die Pfeile. Kein Tablet-/Touchtest. Alte Leistenbilder unter assets/night/ui ungenutzt.

## 2026-10-02: P6b Feinschliff Nachtbrett (Paket 3b)
Leiste: immer Silbersymbol, sonst das Kreisbild entsättigt und abgedunkelt (`NightArt.role_symbol`); das gemalte Bild bleibt auf der Aktionskarte. Bestand: `Downloads/Grimmhain-P1-Nachtentwurf/rollen-bilder-bestand.csv` (72 Rollen, 65 ohne Silbersymbol, 72 mit gemaltem Bild). Rollennamen auf dem Namensschild-Teil. Ausgeklappte Leiste kompakter (Höhe 70, Medaillon 44), verdeckt auf 4:3 keine Plätze mehr; Umschalter-Pfeil an der Mittelspange. "Gespeichert" klein über der Kartusche; Fehlerzeile unverändert breit (Höhe nach Breitenwechsel per call_deferred nachgezogen). Statuszeile oben links dezent hinterlegt.
Verifikation: gezielt grün (0 Fehler): night_board, cockpit_screen, board_layout, handedness, timer_save, ui_theme, cockpit_polish, cards_ui, ui_architecture, portrait_ring_layout, night_board_view. Keine Vollsuite. Abnahme: `Downloads/Grimmhain-P1-Nachtentwurf/p6b-ui/`.
Grenzen: Namen unter der Leiste werden bei langen Rollennamen gekürzt ("Schutzen…"). Die Fallback-Kreisbilder sind sehr dunkel, bis echte Silbersymbole vorliegen.

## 2026-10-02: P6c Silbersymbole für alle 72 Rollen (Paket 3c)
`tools/build_role_emblems.py` schneidet die acht Bögen (`Downloads/Grimmhain-P1-Nachtentwurf/symbole/`) nach zusammenhängenden Alpha-Bereichen statt nach Dritteln zu (Schwerpunkt bestimmt die Zelle, berührende Nachbarmotive werden nach dem nächsten Kern getrennt, kleine abgeschnittene Spitzen entfernt) und schreibt 72 Dateien `godot/assets/night/emblems/<rollen_id>.png` (256 px). Die sieben alten Bronzesymbole liegen in `emblems/_alt/`. Register und ORIGIN-NOTES (Abschnitt 9) ergänzt. Die Nachtleiste nutzt für alle Rollen das neue Symbol; der abgedunkelte Porträt-Fallback bleibt nur für Rollen ohne Datei. Kontrollbild: `symbole/kontrolle-72.png`.
Verifikation: gezielt grün: night_board, cockpit_screen, board_layout, night_board_view, ui_theme. Keine Vollsuite. Abnahme: `Downloads/Grimmhain-P1-Nachtentwurf/p6c-ui/`.
Auffälligkeit: Beim Rattenfänger bleibt links ein kleines Splitterstück aus dem Bogen. Die Symbole füllen den Ring eher klein (Rand im Bild).

## 2026-10-02: Abschluss Nachtbrett (Paket 4)
Symbole: Rand auf etwa 4 % je Seite verkleinert, lose Bruchstücke (Rattenfänger, Prophet des Untergangs, Kutscher, Parasit, Schutzengel) und abgeschnittene Spitzen der Nachbarmotive entfernt; alle 72 im Kontrollbild geprüft.
Vollsuite (einmal, inkl. Fuzz): 1503 Tests, 16 rot. Alle 16 waren Altlasten des Branches (P3 "wip", P4/P5 ohne Vollsuite), keine Spielregel: 10 Tests drückten Werkzeuge im Optionenmenü ohne die Lasche zu öffnen (`tap_button` öffnet sie jetzt), 5 prüften das überstehende Hintergrundbild (Backdrop beschneidet jetzt, `clipped_rect` kennt `clip_contents`), 1 kannte `show_night_timer` nicht, 1 fand die Zahl 24 im Quelltext (jetzt als 12 * 2). Danach nur die betroffenen Dateien erneut: alle grün.
Stand: Nachtbrett P3 bis P6c fertig (Leiste, Laschen, Kartusche, Knöpfe, 72 Silbersymbole). Offen: Tablet-/Touchtest, Rollen-Hintergrundbilder der Karte, Töne.

## 2026-10-02: Paket 5 iPad-Test per Web-Version (vorbereitet, Export wartet auf Vorlagen)
Masterplan-Konfliktmarkierung aufgelöst (neuerer Stand gültig, älterer als "Früherer Stand"). Export-Preset "Web" in `godot/export_presets.cfg` (Threads aus, gl_compatibility laut project.godot, Querformat laut project.godot, Ziel `Downloads/Grimmhain-iPad-Web/index.html`; keine Build-Dateien im Repo). Startdatei `Downloads/Grimmhain-iPad-Web/START-IPAD-TEST.bat` (Python-Server Port 8080, zeigt die WLAN-Adresse).
Blocker: Die Godot-4.7.2-Exportvorlagen für Web sind nicht installiert (`export_templates` leer, Export bricht mit "web_nothreads_release.zip nicht gefunden" ab). Markus muss sie im Editor installieren (Editor > Exportvorlagen verwalten > Herunterladen und installieren). Browser-Prüfung und Screenshot stehen noch aus.

---

## 2026-10-02 — Projekt-Audit (nur Analyse)
Status: ERLEDIGT. Bericht: `docs/audit/AUDIT-2026-10-02.md`, Commit `e91e81c` (main, kein Push). Am Code nichts geändert.
Ergebnis: 67 Funde (5 KRITISCH, 5 HOCH, 15 MITTEL, 42 NIEDRIG); 53 nachgestellt, 14 Verdacht.
Verifikation: Import Exit 0; Vollsuite einmal 1503 Tests, 1 Fehlschlag (`test_game_history::test_screen_and_public_export_have_the_same_scope`, CRLF im Windows-Arbeitsordner); Fuzz mit 3-facher Rundenzahl 1 Fehlschlag (Generatorlücke, kein Regelkern); alle 328 .gd laden ohne Parsefehler.
Nicht geprüft: Tablet/Browser/iPad, Totenreichkarten einzeln, Rollendateien nur Stichproben (Details im Bericht, Abschnitt C).
Nächste Schritte (nur nach Freigabe von Markus): KRITISCH B-01 bis B-03, S-01, S-02 beheben; danach HOCH; Entscheidungen zu B-06, B-07, B-08, S-05, S-06 einholen; Exportvorlagen 4.7.2 installieren (UI-01); Registerzeile für `plate-frame.png` (F-A01).

## 2026-10-03 — Reparatur Paket A (Audit-Funde KRITISCH/HOCH)
Status: umgesetzt, je Fund ein Commit auf main (kein Push): B-01 00ca5a8, B-02 9343c2b, B-03/B-05/CM-01 efd441d, B-04 78bc135, S-01 33732c1, S-02 7d84ea8, S-03 8e7c671, F-A01 7b904a1, X-01 224d755. Details und Tests je Fund: `docs/audit/AUDIT-2026-10-02.md` ("BEHOBEN in").
Verifikation: je Fund gezielter Test vorher rot, nachher grün; Vollsuite einmal am Ende inkl. Fuzz: 1515 Tests, 0 Fehlschläge. UI-01 (Exportvorlagen) und Paket B (MITTEL/NIEDRIG) offen.
Offen für Markus: Zuordnung von `plate-frame.png` zur P3-Freigabe bestätigen.

## 2026-10-03: Paket 5 Web-Export und Selbstmörder-Symbol
Status: umgesetzt. Neues Symbol `selbstmoerder` (Commit 1d3ed9e, altes in `emblems/_alt/`, Register ergänzt, `check-asset-register.js` Exit 0). Web-Export mit Preset "Web" Exit 0 nach `Downloads/Grimmhain-iPad-Web/` (keine Build-Dateien im Repo). UI-01 im Audit-Bericht als behoben markiert (Commit des Berichts: siehe git log).
Verifikation: Desktop-Browser über `http://localhost:8080` (Chromium): 24 Spieler, Rollen, Verteilung, Sitzordnung, Nachtbrett bis Zielwahl (Wolfskind), keine Konsolenfehler, Speichern: Neuladen, "Partie fortsetzen" stellt Nacht 1 Schritt 2 wieder her. Screenshot: `Downloads/Grimmhain-iPad-Web/check-browser.png`. Server beendet. Keine Spiellogik geändert, keine Tests (nur Medien/Export).
Auffälligkeiten nur im Web beobachtet (nicht umgebaut): (1) Namenseingabe verliert bei schnellem Enter jeden zweiten Namen, solange das Feld nicht neu angeklickt wird; (2) Seite verschob sich einmal um etwa 40 px nach oben (Verteilungsschritt); (3) "Partie fortsetzen": Fortsetzen-Knopf sehr hoch, zweiter (roter) Knopf nur als schmaler Streifen. Nicht geprüft: Safari/iPad, Touch, Ton.

## 2026-10-03: iPad-Test per https
Test-Adresse: https://grimmhain-ipad-test.vercel.app/ (eigenes Vercel-Projekt `grimmhain-ipad-test`, Produktion, ohne Login ansehbar; COOP/COEP-Header und `application/wasm` per vercel.json). Im Desktop-Browser (Chromium) gestartet, Titelbild "Eintreten" sichtbar, keine Konsolenfehler. Nicht geprüft: Safari/iPad.

## 2026-10-03: iPad-Feedback (Teil A umgesetzt, Teil B Konzept)
Teil A, Commits auf main (kein Push): 16811cc Touch-Scrollen global (`TouchScrollPolicy`: Flächen im ScrollContainer auf PASS, Totzone 16 px), 9cce7a7 PWA-Export (Symbol aus Werwolf-Silbersymbol, `godot/assets/app/`, im Assetregister, Querformat, standalone), 45f9db6 Scheinrolle des Trugbilderwolfs vorbelegt (zufällige Dorfrolle des Pools, änderbar, DA-88) und Blocker-Texte der Rollenwahl in einfacher Sprache, 3c613e1 Namensfeld bleibt nach Enter im Bearbeitungsmodus (Ursache des "jeder zweite Name geht verloren") plus Prüfliste für mehrere Namen (Komma, Zeilenumbruch, "und"/"and") und `experimental_virtual_keyboard` im Web-Export. A4 und A5 liegen zusammen in einem Commit (gleiche Datei).
Blocker der Rollenwahl (alle jetzt mit Erklärsatz): zu wenige/zu viele Rollen, keine Dorfrolle, keine Wolfsrolle, keine Rolle mit Einzelsieg, Rolle zu oft gewählt, ungültige Anzahl, unbekannte Rolle, Scheinrolle fehlt (nur noch ohne Dorfrolle im Pool), Kartenschlucker ohne Totenreichkarten. Spieler-/Verteilungs-/Sitzschritt waren schon einfach formuliert.
Tests (gezielt, rot dann grün wo möglich): Touch-Scrollen nur im Chromium-Touchkontext prüfbar (ohne Fix Liste bewegt sich nicht, mit Fix ja); `touch_scroll`, `setup_screen` (Bearbeitungsmodus vorher rot, Prüfliste), `person_name_split`, `decoy`, `role_model`, `role_suggestion`, `full_round`, `role_step`, `setup_layout`, `i18n`, `ui_theme`, `game_start`, `role_buttons`, `role_show`, `distribution`, `seating`, `player_`, `setup`, `player_groups` je 0 Fehlschläge; `check-asset-register.js`, `check-role-docs`, `check-godot-i18n` grün. Vollsuite und Fuzz nicht gelaufen (Regelkern unverändert).
Geänderte alte Tests (Produktentscheidung DA-88, nicht abgeschwächt): `test_decoy_model`, `test_decoy_step`, `test_role_model`, `test_role_suggestion`, `test_full_round_ui` erwarteten "keine Vorbelegung".
Web-Export neu nach `Downloads/Grimmhain-iPad-Web/` und auf `grimmhain-ipad-test` (Produktion, gleiche Adresse) deployt. Dateigrößen auf Vercel stimmen mit dem Export überein. Vom Download-Test hier aus nicht abgeschlossen: die Internetverbindung dieses Rechners lieferte zeitweise nur etwa 80 KB/s (auch von Cloudflare), der Vollstart der Live-Adresse wurde nicht abgewartet; derselbe Build lief lokal im Touchkontext (Scrollen, Namenseingabe). Die erste Ladung dauert mit PWA länger, weil der Service Worker die 72 MB zusätzlich zwischenspeichert.
Nicht geprüft: Safari/iPad (Tastatur mit Diktat, "Zum Home-Bildschirm" ohne Leisten, echtes Touch-Gefühl), Ton. Markus: Zuordnung der drei App-Symbole zur P6c-Freigabe des Werwolf-Silbersymbols bestätigen.
Teil B: Konzept in `docs/konzept/vorbereitung-neu.md` (Kopie und 27 Bilder in `Downloads/Grimmhain-Vorbereitung/`), kein Code. Offene Entscheidungen dort in Abschnitt 6.

## 2026-10-03: Cloud-Sitzungen mit Godot
Stand: `main` (c82ad0c) und `feature/visual-night-board` nach origin gepusht (Fast-Forward von 8197ee6, keine Force-Pushes; `audit/all-72-roles` war schon aktuell). Commit 799e356: SessionStart-Hook in `.claude/settings.json` (nur bei `CLAUDE_CODE_REMOTE`) startet `tools/cloud/setup-godot.sh` (Godot 4.7.2 headless, fest hinterlegte SHA512 aus `SHA512-SUMS.txt` des Releases, Ziel `~/.local/godot`, Befehl `godot`, einmal `--import`). CLAUDE.md um Abschnitt "Cloud-Sitzungen" ergänzt.
Verifikation: `bash -n` auf das Skript Exit 0, `git diff --check` ohne Befund. Das Skript lief noch nie real (lokal Windows, Linux-Build).
Nächster Schritt: erste Cloud-Sitzung starten und prüfen, dass `godot --version` 4.7.2 meldet und ein gezielter Test läuft; bei Fehler Skript anpassen.

## 2026-10-04: Teil B Vorbereitung in drei Schritten (Branch feature/vorbereitung-neu, noch nicht gemergt)
Stand: Neue Vorbereitung gebaut (Runde, Namen, Rollen; beide Modi; Hain-Stil), Entscheidung DA-89 im DECISION-LOG, Beschreibung `docs/ui/preparation.md`. Modell ohne Bestätigungen (`PlayerSetup.blockers()`/`warnings`), vier Akte als `ActCatalog`, Vorschlag je Akt, Teamsymbole `godot/assets/night/team/` (im Assetregister). Abweichung von der Vorgabe: fehlende Dorfrolle bleibt Blocker, weil der Regelkern `missing_village_role` ablehnt (Ja/Nein-Frage offen).
Verifikation: Vollsuite einmal am Ende (1400 Tests, enthält Fuzz): 3 Fehlschläge in alten UI-Tests (`test_dialog_focus` 2, `test_role_lexicon_ui` 1, bedienten die entfernten Knöpfe); angepasst und einzeln grün, dazu `test_ui_shell` (Shell verwirft `request_quit`, solange der Dialog der Vorbereitung offen ist). Neu: `test_prep_model` (10), `test_prep_screen` (3). Angepasst und grün: `test_player_groups`, `test_full_round_ui`, `test_cards_ui_closing`, `test_group_store`, `test_ui_*`. `check-asset-register.js`, `check-godot-i18n.js` grün. 16 Screenshots (1024x768 und 2360x1640 mit Gerätenskalierung) in `Downloads/Grimmhain-Vorbereitung/neu/prep/`. Gelöscht (Vierschritt-Wizard): `test_setup_screen/layout/hints/model`, `test_role_step/model/suggestion`, `test_distribution_step/model`, `test_seating_step/model`, `test_game_start_step/model`, `test_decoy_step/model`.
Deploy: Web-Export neu und auf `grimmhain-ipad-test` (Produktion, gleiche Adresse https://grimmhain-ipad-test.vercel.app/) deployt; `index.pck` auf Vercel gleich groß wie lokal (33327872 Byte). Nicht geprüft: Safari/iPad, Touch-Gefühl.
Nächster Schritt: Markus prüft auf dem iPad; Ja/Nein-Frage zur fehlenden Dorfrolle (Kernregel ändern?) beantworten; Branch `feature/vorbereitung-neu` nach Prüfung mergen.

## 2026-10-04: Vorbereitung nach iPad-Test (DA-90), Branch feature/vorbereitung-neu
Stand: Dorfbewohner aus allen Akten und Vorschlägen entfernt, Werwolf mehrfach (`max_copies` UNLIMITED), Vorschlag füllt mit besonderen Rollen, weiteren Werwölfen bis zur Wolfsquote, zuletzt (nur Akt I) mit Gebundenen; jeder Akt trägt 24 Personen. Schritt 1: Schalter links unter den Teamzählern (Zähler einzeilig), Akt-Karte zeigt Fokusrahmen nur bei Tastatur (`grab_focus(true)` im Router), Einzahl „1 Name“ (DE/EN). Entscheidung DA-90, Beschreibung `docs/ui/preparation.md`.
Verifikation: gezielt grün: `unique_start` (8, neu: 3 Werwölfe Start, Siegprüfung, Speichern/Laden), `prep_model` (10, neu: jeder Akt trägt 24), `prep_screen`, `dialog_focus`, `ui_architecture`, `ui_i18n`, `ui_shell`, `siegreicher_wolf`. Vollsuite einmal am Ende (inkl. Fuzz): 1400 Tests, 1 Fehlschlag (`test_cards_ui_closing`: Karte `wende_01` war mit der neuen Besetzung bei Seed 20260930 nicht spielbar, kein Produktfehler); Seed auf 20261001 geändert, Datei danach 4/4 grün, keine zweite Vollsuite. Screenshots Schritt 1 und 3 (1024x768): `Downloads/Grimmhain-Vorbereitung/neu/prep2/`.
Offen: Gebundene als Füller in Akt I (Ja/Nein), Rollenzähler „1 Rollen“ hat noch keine Einzahl.

## 2026-10-04: Abnahme der Vorbereitung, Merge nach main
Stand: Markus hat die Vorbereitung am iPad abgenommen. Akt I bleibt wie gebaut (Gebundene als letzter Füller, in DA-90 ergänzt). Blocker `act_too_small` samt Schlüsseln und Sperre der Akt-Karten entfernt (jeder Akt trägt 24, unerreichbar). Einzahl bei „1 Rolle fehlt/zu viel“ (DE/EN). Commit 72c0a76, danach Merge ohne Squash nach main.
Verifikation: gezielt `prep_model` 10, `prep_screen` 3, `ui_i18n` 6 grün; `check-godot-i18n.js` konsistent; Vollsuite einmal inkl. Fuzz: 1400 Tests, 0 Fehlschläge (Exit 0). Safari/iPad nur durch Markus geprüft.
Deploy: Web-Export neu, `grimmhain-ipad-test` (Produktion).
Offen: nichts aus diesem Auftrag.


## 2026-10-04: Feinschliff Vorbereitung (DA-91), Branch feature/vorbereitung-feinschliff (nicht gemergt)
Stand: Eigener Ladebildschirm (boot_splash, `web/shell.html`, `tools/build_splash.py`, Register ergänzt), Hauptmenü mit Hain-Knöpfen, „Empfohlene Aufstellung“ in Schritt 1, weiches pulsierendes Glühen (`SelectionGlow`) statt rotem Rechteck, Schritt 3 startet leer und ist ein Kachelraster (`RoleTile`, `RolePoolView`), „Empfehlung übernehmen“, Rollenleiste im Kartenmodus 40 Prozent hoch in Teamfarben. Popup „Welche Rolle kommt dazu?“, Rollenmenü und 13 Übersetzungsschlüssel entfernt. Regelkern unverändert.
Verifikation: gezielt grün: `prep_model` 11 (neu: Schritt 3 startet leer), `prep_screen` 4 (neu: Kacheln leer, Toggle, ×N, Zähler, Empfehlung), `unique_start`, `role_lexicon_ui`, `player_groups`, `full_round_ui`, `cards_ui_closing`, `dialog_focus`, `ui_layout`, `ui_theme`, `ui_i18n`, `ui_shell`, `ui_architecture`, `cockpit_gm`, `role_operation_kinds`, `settings_persistence`, `game_history`, `touch_scroll`, `rulebook`, `save_service`; `check-godot-i18n.js` und `check-asset-register.js` grün. Keine Vollsuite (Kern unverändert). Bestehende UI-Tests an den neuen Ablauf angepasst (leerer Schritt 3: erst „Empfehlung übernehmen“), nicht abgeschwächt. Screenshots 1024x768 in `Downloads/Grimmhain-Vorbereitung/neu/prep3/` (Ladebildschirm im Browser mit gedrosseltem Download, Hauptmenü, Schritt 1, Schritt 3 leer und gefüllt, Kartenmodus mit Leiste).
Nicht geprüft: Safari/iPad (Langdruck, Glühen, Touch), Leistung des Glüh-Schein-Bildes im Browser (einmal berechnet, Viertelauflösung).
Deploy: Web-Export neu, `grimmhain-ipad-test` (Produktion), `index.pck` 35964444 Byte wie lokal, eigene Ladeseite live.
Offen: Schriftzug des Ladebilds ist Georgia Bold als Platzhalter für ein Markenlogo.

## 2026-10-04: Lebendiger Startbildschirm und Fehlerkorrekturen (DA-92), Branch feature/vorbereitung-feinschliff (nicht gemergt)
Stand: Fehler 1 (Kartenmodus, kompakter Ring in zwei Reihen ohne Überlappung, Mitteltext aus, gewählter Platz glüht), Fehler 2 (Teamfarben-Glühen der Rollenkacheln), Hilfszeile bei 0 Rollen. Startbilder geprüft (Logo und Nebel haben echte Alpha, „GRIMMHAIN“ richtig, Nebel hatte harte Kanten und Farbsäume: bereinigt und nahtlos gemacht) und eingebaut: `StartBackdrop` (Zoom, Mondglühen, 2 Nebelbänder, Wolfsaugen, Wetterleuchten), Startbildschirm mit Logo und glühendem „Eintreten“ (Nebel zieht zu), Hauptmenü mit Logo und abgedunkeltem Hintergrund, Ladebild mit Logo statt Georgia-Schriftzug. Regelkern unverändert.
Verifikation: gezielt grün: `portrait` (9, neu: kompakter Ring 6 bis 24 Personen ohne Berührung), `prep_model` 11, `prep_screen` 4, `ui_shell`, `ui_i18n`, `ui_layout`, `ui_theme`, `board_layout`, `role_lexicon_ui`, `full_round_ui`, `player_groups`, `settings_persistence`, `cockpit_screen`, `cards_ui_closing`; `check-godot-i18n.js`, `check-asset-register.js` grün. Keine Vollsuite (Kern unverändert). Im Browser (Chromium, Service Worker blockiert) geprüft: Ladebildschirm mit Balken, Startbildschirm läuft ohne Konsolenfehler (ca. 6 Bilder/s bei Software-Rendering, kein Maß für das iPad), Wolfsaugen blenden auf. Screenshots 1024x768 und 2360x1640 sowie `start-bewegung.gif` (10 s) in `Downloads/Grimmhain-Vorbereitung/neu/prep4/`.
Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion), `index.pck` 38037904 Byte wie lokal.
Nicht geprüft: Safari/iPad (Flüssigkeit der Ebenen, Glühen, Touch). Offen: Eintreten-Übergang im Browser nicht aufgenommen (nur Code und Tests).


## 2026-10-04: Abnahme Feinschliff, Nebel-Übergang und Logo-Lesbarkeit (DA-93), gemergt nach main
Stand: Markus hat den Feinschliff am iPad abgenommen. Nach „Eintreten“ zieht der Nebel zu und das Hauptmenü taucht aus dem Nebel auf (`StartBackdrop.fog_open`, 0,8 s, einmalig über `fog_open_pending`; bei reduzierter Bewegung hart). Hauptmenü-Logo liegt auf dem Mond: weiche dunkle Vignette hinter dem Logo (`LogoShade` in `main_menu_screen.gd`). Regelkern unverändert.
Verifikation: Screenshots Hauptmenü 1024x768 und 2360x1640 geprüft (Logo lesbar) in `Downloads/grimmhain-menue-logo/`. Vollsuite vor Merge: erster Lauf 1403 Tests, 4 Fehlschläge (`ui_layout`: `LogoShade` ragte über den Bildrand, echter Fehler der Änderung); Schatten ins beschneidende Backdrop verlegt, `ui_layout` 6/6 grün, zweite Vollsuite inkl. Fuzz: 1403 Tests, 0 Fehlschläge (Exit 0). Test nicht abgeschwächt.
Merge: ohne Squash nach main (66b8a9a), main gepusht.
Deploy: Web-Export neu, `grimmhain-ipad-test` (Produktion), `index.pck` 38039584 Byte.
Nicht geprüft: Nebel-Auftauchen im echten Ablauf (nur Code, kein Video), Safari/iPad.
Offen: nichts aus diesem Auftrag.

## 2026-10-04: Team-Kachelrahmen für Rollenkacheln (DA-94), gemergt nach main
Stand: Neues ChatGPT-Bild mit drei leeren Rahmen geprüft (echte Transparenz außen, lange Kanten ohne Ornament; Inneres war nur zu 96 bis 99 Prozent deckend, im Zuschnitt auf voll gesetzt, Halo entfernt). Original nach `Downloads/Grimmhain-P1-Nachtentwurf/ui/team-kacheln.png`. `tools/build_grove_ui.py` (`build_team_tiles`, auch einzeln mit `--team-tiles-only`) erzeugt `godot/assets/ui/team_tile_village|wolves|solo.webp` (verlustfrei, 150 px hoch, Ende | Mittelstück | Ende) und `godot/app/theme/team_tile_art_data.gd` (Ränder, Fassung). Drei Registerzeilen (intern-freigegeben). `RoleChip` mit `team_tint` (Kachel in Schritt 3, Rollenleiste im Kartenmodus) zeichnet den Rahmen statt des eingefärbten `name_plate_short`; Symbol in der runden Fassung; nicht gewählt entsättigt und auf 45 Prozent Helligkeit, Text grau; gewählt volle Farbe, Glühen in Teamfarbe (`SelectionGlow`/`GroveStyleBox` mit `px_per_unit`). ×N, − und + (56 px) und Langdruck unverändert. Regelkern unverändert.
Verifikation: gezielt grün: `prep_screen` 4, `ui_layout` 6, `ui_architecture` 4, `ui_theme` 8, `ui_shell` 12, `touch_scroll`, `cards_ui_closing` 4; `check-asset-register.js` grün. Dabei zwei eigene Fehler behoben (leere Rolle beim Anlegen der Kachel, Farbliteral außerhalb der Tokens), Tests nicht angepasst. Keine Vollsuite (Kern unverändert), keine neuen Tests (nur Aussehen). Screenshots 1024x768 und 2360x1640 in `Downloads/Grimmhain-Vorbereitung/neu/prep5/prep/` (Schritt 3 Akt I und Akt IV gefüllt mit gewählten und nicht gewählten Rollen, Kartenmodus mit offener Leiste).
Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion), `index.pck` 38186752 Byte wie lokal.
Nicht geprüft: Safari/iPad. Offen: Symbolgröße in der Fassung (ca. 22 logische Einheiten) am Gerät beurteilen.

## 2026-10-04: Abnahme Team-Kacheln, größeres Symbol, Merge nach main
Stand: Markus hat die Team-Kacheln abgenommen. Rollensymbol in der runden Fassung von ca. 22 auf ca. 30 Einheiten vergrößert (`TILE_SYMBOL_FILL` 2,3); bei 2,45 (ca. 32) ragte die Sense über den Ring, 30 ist die größte Größe ohne Überstand. Gilt für Schritt 3 und die Leiste im Kartenmodus.
Verifikation: gezielt `prep_screen` 4, `ui_layout` 6, `ui_theme` 8 grün; Vollsuite vor Merge inkl. Fuzz: 1403 Tests, 0 Fehlschläge (Exit 0). Screenshots 1024x768 in `Downloads/Grimmhain-Vorbereitung/neu/prep6/prep/`.
Merge: ohne Squash nach main, main gepusht. Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion).
Nicht geprüft: Safari/iPad. Offen: nichts aus diesem Auftrag.

## 2026-10-04: Testrunde 1, Teil A und B, Branch feature/testrunde-1 (nicht gemergt)
Stand Teil A: (1) Kartenmodus: Antippen eines Platzes öffnet das Rollenwahl-Fenster über die ganze Zuordnungsseite (Sitzring verdeckt, oben groß „Platz N: Name“, Marken 1,6-fach). (2) Sitzring: Ringform auf Superellipse 2,15 (`RING_SHAPE`), Schildbreite berücksichtigt jetzt die Nummern-Abzeichen der Nachbarn; neuer Test `test_number_badges_never_overlap_names_or_portraits` (6 bis 24 Personen, 4 Feldgrößen) war vor dem Fix rot (36 Treffer). Der kompakte Ring (`compact`) wird von der App nicht mehr benutzt, Code und Test bleiben. (3) Spielbeginn: Textkasten „Sag jetzt“ entfällt, stattdessen großer Knopf „Spiel beginnen“ (button_primary, rotes Glühen), „Rollen zeigen“ als Nebenknopf; nur in Nacht 1 ohne Wiederbelebungsrunde (dort bleibt die Karte wegen der Ansage „auch die Toten“). (4) Akt-Karten: gewählter Akt lodert (`FireGlow`, Shader plus höchstens 28 Funken, Stärke nach Aktstufe I Glut bis IV sehr wild, bei reduzierter Bewegung still).
Verifikation Teil A: gezielt grün `portrait_ring_layout` 6, `prep_screen` 4, `ui_layout` 6, `ui_theme` 8, `ui_i18n` 6, `ui_architecture` 4, `night_board` 19, `handedness` 10, `call_presentation` 6, `cards_ui` 20, `cockpit_*`, `full_round_ui`, `resume_scenarios`, `dialog_focus` u. a.; `check-godot-i18n.js` grün. Tests angepasst, nicht abgeschwächt: `night_board`, `handedness` (Hauptaktion im Dock erst ab dem ersten Nachtschritt), `call_presentation` (Ansage „Die Nacht bricht herein“ jetzt ab Nacht 2 geprüft, Spielbeginn ohne Text neu geprüft). Keine Vollsuite (Kern unverändert). Screenshots 1024x768 in `Downloads/Grimmhain-Test1/` (Ordner `prep`, `nacht`, `vorher`). Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion), `index.pck` 38194156 Byte wie lokal.
Stand Teil B (nur Bestandsaufnahme, nichts umgebaut): `docs/audit/NACHTSCHRITTE-72.csv` (72 Rollen, Werkzeug außerhalb des Repos spielt je Rolle die echten Karten durch) und `docs/audit/NACHTSCHRITTE-PRINZIPIEN.md`. 12 Rollen mit Widerspruch App gegen Kartentext; meiste Tipps: Blutpriester 9, Loki 8, Waldhexe 8, je 7 Kopfgeldjäger, Kutscher, Lehrling, Spürhund, Traumdeuter. Nicht gemessen: Dorfschmied (ab Nacht 6), Schutzgeist (nur als Tote), Kartenschlucker, Nacht 4 Schicksalswolf, Tagesfähigkeiten.
Nicht geprüft: Safari/iPad (Flammen und Funken flüssig?), Seitenverhältnisse außer 1024x768 für die neuen Bilder. Offen: Loki-Entscheidung B-05 (freiwillig) gegen Markus' Rückmeldung (immer genau 2); Umbau der Nachtschritte erst nach Freigabe der Prinzipien.

Nachtrag Testrunde 1: epischer Knopf (Markus' Bild `start-knopf.png`). Neuer Knopf-Typ `EpicButton` (`godot/app/widgets/epic_button.gd`, nur „Eintreten“ und „Spiel beginnen“): Enden `epic_button_left/right.webp` ungestreckt, Lava-Mitte `epic_button_mid.webp` nahtlos gekachelt (`tools/build_epic_button.py`), Mindesthöhe 72, große helle Schrift mit dunklem Umriss, Lava pulsiert in 3 s (Shader), gedrückt 0,1 s heller und leicht eingesunken, bei reduzierter Bewegung ohne Pulsieren und ohne Übergang; kein Rechteck-Glühen mehr um diese Knöpfe. Verifikation: neuer Test `epic_button` 1, gezielt `call_presentation` 6, `handedness` 10, `night_board` 19, `ui_layout` 6, `ui_shell` 12, `cards_ui` 20 grün; Register konsistent; Screenshots 1024x768 in `Downloads/Grimmhain-Test1/epic/`. Nicht geprüft: Safari/iPad (Shader auf dem Gerät), Druckeffekt per echtem Tippen.
## 2026-10-04: Marke einbauen (feature/marke)
Stand: Wortmarke ersetzt `start-logo` in Startbildschirm, Hauptmenü (mit Vignette) und Ladebild; Siegel klein über der Wortmarke im Ladebild. App-Symbol aus dem Siegel auf nachtschwarzem rundem Grund (`godot/assets/app/app-symbol-{32,60,120,144,180,512}.png`, `config/icon`, PWA-Symbole im Exportpreset). Das große Siegel war bei 60 und 32 px verwaschen: bis 120 px gilt eine Klein-Fassung (Kopf größer, kreisrund maskiert, nur Ring, Kontrast höher), ab 144 px das unveränderte Siegel. `start-logo.webp` und die alten `app-icon-*` bleiben im Repo, im Register als ersetzt markiert. Quelle: `tools/build_brand_assets.py`, `docs/brand/MARKE.md` (das Projekt-Dokument "marken-blatt-grimmhain" war nicht lesbar, Kurzfassung stützt sich auf Design-Tafel und ThemeTokens).
Verifikation: `ui_layout` 6 grün, Start-/Menü-Tests (`start`-Filter) 9 grün, `node tools/check-asset-register.js` konsistent, Screenshots 1024x768 geprüft, Kontaktbogen `Downloads/Grimmhain-P1-Nachtentwurf/marke/kontrolle-marke.png`. Keine Vollsuite (nur Oberfläche und Assets).
Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion), `index.pck` 38823900 Byte wie lokal. Nicht geprüft: Safari/iPad, Favicon im Browser-Tab.

## 2026-10-04: Marken-Abgleich und Merge nach main (testrunde-1, dann marke)
Stand: `docs/brand/MARKE.md` mit dem verbindlichen Marken-Blatt abgeglichen (kein Gold, kein Slogan, Klein-Fassung unter 144 px, Sprache mit dem Loki-Beispiel des Blatts). `feature/testrunde-1` (Teil A, Nachtschritte-Bestandsaufnahme, epischer Knopf `EpicButton`) und `feature/marke` ohne Squash nach main gemergt; Konflikte nur in `PROGRESS.md` und Asset-Register (beide Seiten behalten). Epischer Knopf auf „Eintreten“ und „Spiel beginnen“, neue Wortmarke überall.
Verifikation: Vollsuite inkl. Fuzz auf dem Merge-Stand 1405 Tests, 1 rot: `ui_theme::test_no_hardcoded_styles_outside_theme` (drei Farbwerte und `Color.WHITE` direkt in `epic_button.gd`). Behoben mit Tokens `EPIC_TEXT_OUTLINE`, `EPIC_TEXT_SHADOW`, `TINT_EPIC_DISABLED`; danach gezielt `ui_theme` 8, `epic_button` 1, `ui_layout` 6 grün. Die Vollsuite wurde danach nicht wiederholt (nur Tokens und eine Datei geändert).
Offen: Das Marken-Blatt sagt „Kein Gold. Nirgends.“, die App nutzt noch Gold-Tokens (`GOLD*`, in 3 Dateien unter `godot/app`); Entscheidung und Umbau stehen aus. Nicht geprüft: Safari/iPad.
Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion), `index.pck` 39772752 Byte wie lokal. Nächster Schritt: Markus prüft Start und Spielbeginn auf dem iPad (Lava-Puls, Druckeffekt) und entscheidet über die Gold-Tokens.

## 2026-10-04: Vollsuite nachgeholt, Gold entfernt
Stand: Vollsuite inkl. Fuzz auf main f78748e nachgeholt: 1405 Tests, 0 Fehlschläge. Gold-Tokens (`GOLD`, `GOLD_BRIGHT`, `GOLD_DEEP`, `TEXT_ON_GOLD`, `WARNING_TEXT`) aus `ThemeTokens` entfernt. Ersatz: Mondsilber (Akzent, Titel, Rahmen, Cursor, Scrollleiste), Blutrot nur für Hauptaktion und „an/gewählt“ (neue Tokens `BLOOD_RED_BRIGHT`, `BLOOD_RED_DEEP`: Primärknopf, Schalter, gewählter Platz). Betroffen: `theme_factory.gd`, `theme_tokens.gd`, `dice_row.gd`, `asset_lab/font_specimen`. Neuer Test `test_no_gold_tokens` (kein Token mit „GOLD“ im Namen). Regel in CLAUDE.md: Vollsuite auf dem finalen Stand vor dem Push.
Verifikation: Vollsuite inkl. Fuzz auf dem Stand ohne Gold: 1406 Tests, 0 Fehlschläge (Exit 0), vor dem Push. Screenshots 1024x768 (Start, Menü, Cockpit, Einstellungen, Vorbereitung) in `Downloads/Grimmhain-Test1/gold-weg/`.
Offen: Weitere warme Töne mit Gold-Charakter bleiben, weil nicht beauftragt: `FOCUS_RING` (#f3de9f), `DAY_ACCENT` (Sonnengold), `DAY_SURFACE` und Tag-Töne; Entscheidung bei Markus. Nicht geprüft: Safari/iPad.
Deploy: Web-Export neu auf `grimmhain-ipad-test` (Produktion), `index.pck` 39772576 Byte wie lokal. main d363369.
