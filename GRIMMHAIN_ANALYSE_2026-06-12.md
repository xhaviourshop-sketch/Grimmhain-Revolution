# GRIMMHAIN ANALYSE — 2026-06-12 (verifizierter Ist-Stand)

**Methode:** Read-only-Audit am aktuellen Code (`main`, HEAD `ed0ad02`). Die alten Berichte
(`ANALYSE_BERICHT.md` 03.05., `AUDIT.md` 30.05.) wurden als Hypothesen behandelt; jede Behauptung
wurde gegen den Code geprüft. Bei Konflikt gewinnt der Code. Jeder Punkt hat einen Beleg `datei:zeile`.

**Verifikationsläufe:**
- `node tests/smoke.js` → **OK**
- `node tools/compare-i18n.js` → **missing_in_de 0, missing_in_en 0** (keine Key-Drift DE↔EN)

---

## A) OFFEN — echte, belegte Punkte

### A1. `WahnsinnigKutscher.mp3` fehlt — stiller SFX-Ausfall
- **Beleg:** `js/ui/audio.js:6` mappt `sfxWahnsinniger → "WahnsinnigKutscher.mp3"`; Aufruf in `js/core/night.js:371`; Datei fehlt in `assets/sounds/` (Listing geprüft).
- **Auswirkung:** Sound der Rolle "Wahnsinniger Kutscher" spielt im Live-Spiel nie, ohne Fehlermeldung.
- **Fix-Optionen:** Datei ergänzen ODER Eintrag aus `SOUNDS_FILENAMES` entfernen (dann greift kein Aufruf mehr).
- **Risiko:** trivial.

### A2. `checkWinConditions()`: fehlendes `return` nach Wolfssieg
- **Beleg:** `js/ui/core.js:220` — `if(wolfPower >= villagers.length) triggerWin("Werwölfe", null);` **ohne** `return`. Danach laufen die Manipulator-/Parasit-Checks (`core.js:221-224`) weiter.
- **Auswirkung:** Edge-Case: Wolfssieg UND z. B. Parasit-Sieg (3 Lebende) im selben Aufruf → zweiter `triggerWin` überschreibt `TeamWinner` und zeigt ein zweites Sieg-Banner.
- **Fix:** `return` nach dem Wolfssieg ergänzen (analog `core.js:218`).
- **Risiko:** klein, eine Zeile.

### A3. Divergierende Wolf-Definitionen (4 Stellen, eine echte Inkonsistenz)
- **Belege:**
  - Autoritativ: `WOLF_ROLES_SET` `js/core/roles.js:391-396` (19 Rollen).
  - Heuristik `isWolf()` `js/ui/core.js:8-15` — inkl. `Schattenhund` + `meta.cursedWolfAura`.
  - Lokale Kopie `isWolfSeat` in `checkTeamWin` `js/ui/core.js:279-284` — **ohne** `Schattenhund`-Sonderfall und **ohne** `cursedWolfAura`.
  - Inline-Listen `_allWolf` `js/core/abilities.js:74` und `wolfRoles` `js/core/abilities.js:88`.
- **Konkrete Inkonsistenz:** Ein Sitz mit `meta.cursedWolfAura` (ohne `flags.werewolf`) zählt in `checkWinConditions` als Wolf, in `checkTeamWin` aber nicht → die zwei Sieg-Prüfungen können sich widersprechen. `Schattenhund` ist nur über `flags.werewolf` abgedeckt (`game.html:455`, `game.html:1156`) — hängt davon ab, dass das Flag bei jeder Rollenzuweisung gesetzt wird.
- **Fix-Richtung:** `isWolfSeat` in `checkTeamWin` durch `isWolf()` ersetzen; Inline-Listen aus `WOLF_ROLES_SET` ableiten.
- **Risiko:** mittel — ändert Sieg-Logik; ohne echte Tests nur mit manuellem Durchspielen verifizierbar.

### A4. Zwei redundante Sieg-Prüfpfade
- **Beleg:** `checkWinConditions` (`js/ui/core.js:205`, aufgerufen aus `applyKill` `core.js:200`) und `checkTeamWin` (`core.js:272`, aufgerufen aus `save()` `js/core/state.js:106`). Beide prüfen Wolf-vs-Dorf-Mehrheit mit leicht anderen Regeln (siehe A3); `checkTeamWin` hat zusätzlich die "erst werten wenn konfiguriert"-Guards (`core.js:290-304`).
- **Fix-Richtung:** Auf eine Quelle konsolidieren (Mehrheits-/Team-Logik einmal, von beiden Triggern aufgerufen).
- **Risiko:** mittel — gleiches Risiko wie A3, sinnvoll zusammen anzugehen.

### A5. DE-Anzeigetexte sagen noch "Totenrat-Führer" statt "Nekromant"
- **Beleg:** `js/core/i18n.js:119,175,177,179,180` (DE-Werte). Die EN-Werte sagen bereits "Necromancer" (`i18n.js:439,495,497,499,500`). Dazu Fallback-Strings/Title in `game.html:96,546,560,562`.
- **Hinweis:** Funktional ist alles gefixt — Buttons keyen auf `Nekromant` (`game.html:541-543`, `js/ui/field-viewmodel.js:61`, `js/ui/ui.js:295-299`). Nur die **deutschen Texte** zeigen den alten Rollennamen.
- **Risiko:** trivial, reine Textänderung (5 i18n-Werte + 4 Fallbacks).

### A6. Stale Doku in `CLAUDE.md`
- **Beleg:** CLAUDE.md nennt `abilities.js ← Fähigkeiten-Auflösung (~1150 Zeilen)` — real 121 Zeilen (längst gesplittet in `abilities-helpers.js` 287 + `abilities-roles-chunk.js` 858). Abschnitt "Bekannte Schwachstellen" führt das noch als offen. Die `js/ui/`-Liste fehlt: `field-pixi.js` (581), `field-viewmodel.js` (78), `touch-tooltips.js` (50).
- **Risiko:** trivial, nur Doku.

### A7. Untracked Altlasten im Root
- **Beleg:** `git status`: `AGENTS.md` und `ANALYSE_BERICHT.md` untracked. `ANALYSE_BERICHT.md` ist zu ~80 % überholt (siehe Abschnitt B) und stiftet Verwirrung als vermeintliche To-do-Liste.
- **Empfehlung:** `ANALYSE_BERICHT.md` löschen oder als `docs/archive/` ablegen; `AGENTS.md` committen oder entfernen — Entscheidung Markus.

---

## B) ERLEDIGT / KEIN_BUG — Behauptungen der alten Berichte, am Code widerlegt

| Alte Behauptung | Status | Gegenbeleg |
|---|---|---|
| akte.js fehlt / Crash | KEIN_BUG | `js/core/akte.js` existiert (144 Z.), nur in setup.html gebraucht |
| night.js eigene Fraktionslisten | ERLEDIGT | `night.js:9-11` delegiert an `getRoleFaction()` |
| SOLO-Set in game.html unvollständig | ERLEDIGT | `game.html:886` nutzt `window.SOLO_WIN_ROLES` (alle 14) |
| `clearRolesNewRound()` resettet once-Keys nicht | ERLEDIGT | `game.html:532-535` resettet alle genannten Keys |
| `applyKill()` Totenkarten-Duplikate bei Kettentod | KEIN_BUG | Dead-Guard `core.js:99` + `flags.dead=true` (`:142`) vor Rekursion verhindert Doppelvergabe |
| Undo-Tooltip verspricht 5 Schritte | ERLEDIGT | `game.html:92`: "Letzten Schritt rückgängig machen" |
| localStorage ohne try/catch | ERLEDIGT | `state.js:98-102, 109-118` |
| "White Werewolf" in EN-Keys / doppelte Leerzeichen | ERLEDIGT | nicht mehr im Code (`i18n.js` geprüft) |
| `sfxBear`/`sfxLovers` zeigen auf fehlende Dateien | ERLEDIGT | `audio.js:4,12` mappen auf vorhandene `Bärenführer.mp3`/`Amor.mp3` |
| `compare-i18n.js` defekt (kein addEventListener) | ERLEDIGT | Stub `tools/compare-i18n.js:9`; Lauf erfolgreich, 0 Drift |
| Tooltips nur Hover, kein Touch | ERLEDIGT | `js/ui/touch-tooltips.js` eingebunden (`game.html:42`) |
| Totenrat-Buttons toter Pfad (alter Rollenname) | ERLEDIGT (funktional) | `field-viewmodel.js:61` + `ui.js:295-299` keyen auf `Nekromant`; nur DE-Texte stale → A5 |
| Kein Capacitor im Repo | ERLEDIGT | Capacitor 8 + `capacitor.config.ts` (webDir `dist`), Build via `tools/copy-dist.js` |
| root↔dist `game.html` weichen ab | KEIN_BUG | Beabsichtigter Offline-Font-Patch (`tools/copy-dist.js:35-37`); einziger Unterschied; dist↔android↔ios identisch |
| Leere catch-Blöcke verbergen alles | TEILS ERLEDIGT | Spielentscheidende Stellen melden über `grimmReportError` (Commit `aa9b578`); unkritische leere catches bleiben |

---

## C) Architektur-Themen (nur gelistet, nicht Teil eines Fix-Laufs)

1. **`js/core/` nicht DOM-frei:** `night.js` (`rebuildOrder` rendert DOM, `night.js:22-120`), `abilities.js` (Overlay-DOM, `abilities.js:30-57`), `state.js` (`save()` ruft `rebuildOrder`/`prophetProgressCheck`/`checkTeamWin`, `state.js:94,104,106`). Blockiert die geplante Portierung; bewusst großes Refactoring.
2. **`game.html`-Monolith** (~2700 Z., viele Inline-Skripte).
3. **`state.once`-Flag-Beutel** mit manuell gepflegten Reset-Listen (`game.html:532-535`) — strukturelle Fehlerquelle bei jeder neuen Rolle.
4. **Portrait-/Mobile-Layout** weiterhin Landscape-only.

## D) Ausgeklammert (separater Lauf, bereits entschieden)

**Totenkarten-EN:** 80 Karten-Texte in `js/core/cards.js` nur DE; Overlay-Labels in `abilities-helpers.js:126,154` ("ist gestorben", "Karte ausspielen") hardcodiert DE. Größte echte i18n-Lücke, bewusst als eigener Übersetzungslauf geplant.

---

## Empfohlene Fix-Reihenfolge (zur Triage)

| Prio | Punkt | Aufwand | Risiko |
|---|---|---|---|
| 1 | A1 fehlender Sound | 1 Zeile / 1 Datei | keins |
| 2 | A2 fehlendes `return` | 1 Zeile | minimal |
| 3 | A5 DE-Texte Nekromant | ~9 Strings | keins |
| 4 | A6 + A7 Doku/Altlasten | Doku | keins |
| 5 | A3 + A4 Wolf-Definition + Sieg-Konsolidierung | mittel | **mittel — manuell testen** |

*Audit: Claude (Fable 5), 2026-06-12. Read-only — außer diesem Report wurde nichts verändert.*

---
---

# TEIL 2 — Tiefenanalyse (Logikfehler · Bugs · Textfehler)

**Methode:** Vollständige Durchsicht von `js/core/*` (state, roles, night, abilities, abilities-helpers, abilities-roles-chunk, cards, akte, i18n-Stichproben), `js/ui/*` (core, ui, audio, gamelog, field-viewmodel, field-pixi-Stichproben) und allen Inline-Skripten in `game.html`, `setup.html`, `index.html`. Jeder Fund mit Beleg. Keine Code-Änderung.

---

## L) LOGIKFEHLER & BUGS

### L1. 🔴 Wolf-Klassifikation: Wolfskind falsch-positiv, Fenrir/Cerberus/Rudelvater falsch-negativ (KRITISCH)

Das System hat **6+ verschiedene Wolf-Definitionen**, und zwei Rollengruppen fallen durch die Lücken:

**a) Wolfskind zählt ab Nacht 1 als Wolf (soll erst nach Tod des Vorbild-Feindes):**
- Regex `/wolf/i` matcht "Wolfskind" → `flags.werewolf=true` bei Zuweisung: `setup.html:1069-1074`, `game.html:455` (savePop), `game.html:1156` (setupModal)
- `isWolf()` (`js/ui/core.js:14`) zählt es damit überall als Wolf: **Siegprüfung** (Wolf-Mehrheit erreicht früher), Spielfeld zeigt **roten Wolfs-Rahmen + 🐺-Marker ab Start** (`field-viewmodel.js:11`, `markerList`), **Orakel zeigt "Werwolf"** (`abilities-roles-chunk.js:250`), bekommt **keine Totenkarte** (`abilities-helpers.js:12`), **Ritter-Vergeltung kann es töten** (`findNearestWolf` Regex, `js/ui/core.js:408`)
- Beschreibung sagt explizit: "Sollte dieser sterben, erwacht dein animalisches Blut und du zählst **fortan** als Wolf" (`roles.js:70`). Transformation ist korrekt implementiert (`core.js:385`), aber das Start-Flag macht sie bedeutungslos.

**b) Fenrir, Cerberus, Rudelvater bekommen das Flag NIE (über die Haupt-Pfade):**
- Kein `/wolf/i`-Match, fehlen in den Setz-Listen: `setup.html:1069` (alle 3), `game.html:1156` (alle 3), `game.html:455` (Cerberus, Rudelvater)
- `isWolf()` erkennt sie nur über `flags.werewolf` → sie zählen als **DORF** in `checkWinConditions`/`checkTeamWin`, bekommen Totenkarten, Bärenführer-Ping ignoriert sie
- **Anzeige widerspricht Logik:** Das Spielfeld nutzt `WOLF_ROLES_SET` (`field-viewmodel.js:11`) und zeigt sie korrekt als Wolf — Siegprüfung zählt sie als Dorf.

**c) Die einzige korrekte Setz-Stelle wird überschrieben:** `selectRole` (`game.html:655`) nutzt `WOLF_ROLES_SET` ✓ — aber der "Übernehmen"-Button ruft danach `savePop` (`game.html:455`), das das Flag mit der Regex-Liste neu berechnet und den korrekten Wert **rückgängig macht**.

**Fix-Richtung:** Eine einzige Funktion: `WOLF_ROLES_SET.has(role) || flags.werewolf || meta.cursedWolfAura` (ohne Regex). Alle 6 Stellen darauf umstellen. **Risiko mittel — betrifft Siegprüfung, manuell testen.**

### L2. 🔴 `applyRitterRetaliationFromNight` doppelt definiert — die gute Version ist tot
- `night.js:418-438`: verfeinerte Version (lastKillCause-Whitelist inkl. BLACK_WIDOW/HADES, `ritterRetaliated`-Guard, Gamelog)
- `game.html:489-493`: ältere, crude Version (nur `meta.killedTonight`, kein Guard, kein Log, Cause `"RITTER_RETALIATE"`)
- Inline-Skripte laden **nach** night.js → **die game.html-Version gewinnt**, die night.js-Version ist toter Code
- Folgen: Ritter-Vergeltung feuert NICHT bei Schwarze-Witwe-/Hades-/Giftwolf-Toden (kein `killedTonight`); Tod-Overlay zeigt rohen String "💀 RITTER_RETALIATE", weil `DEATH_CAUSE_LABELS` nur `RITTER_RETALIATION` kennt (`ui.js:409`)
- **Fix:** game.html:489-493 löschen (night.js-Version übernimmt), Cause-String vereinheitlichen.

### L3. 🔴 Debug-Code: Zufallsnamen bei jedem Seitenladen
- `game.html:1586` (Dynamic-Circle-`init()`): ruft bei **jedem Laden** `assignRandomSeatNames()` auf → leere Sitze heißen plötzlich "Lena", "Ben", ... Zusätzlich shadowt das lokale `save()` (Z. 1560) das globale — verwirrender Nebeneffekt.
- **Fix:** Zeile 1586 entfernen (Test-Helfer, gehört nicht in init).

### L4. 🟠 Undo-Stack Off-by-one: erster Klick wirkungslos
- `game.html:2317-2336`: Snapshot wird beim `save()`-Wrap gepusht — also **nach** der Mutation. Stack-Top == Ist-Zustand → erster Undo-Klick stellt den aktuellen Zustand wieder her (nichts passiert), erst der zweite macht rückgängig.
- Korrekt wäre Push **vor** der Aktion (so macht es das alte `snapshot()` in `state.js:122`, das hier umgangen wird).
- Nebenfund: Tooltip sagt "Letzten Schritt" (`game.html:92`), Stack kann jetzt 5 — Text untertreibt.

### L5. 🟠 `doLynchFlow`: Sonderpfade vergessen LynchCount / Henker-Markierte (`night.js:357-448`)
| Pfad | LynchCount++ | Henker-`hmark`-Exekution | Gamelog |
|---|---|---|---|
| Normal (`:443-446`) | ✓ | ✓ | ✓ |
| Der Weise (`:399-400`) | ✓ | ✓ | ✓ |
| Spiegelwolf (`:428`) | ✓ | ✗ | ✗ |
| **Wahnsinniger Kutscher (`:361-374`)** | ✗ | ✗ | ✗ |
| **Voodoo-Redirect (`:375-378`)** | ✗ | ✗ | ✗ |
| **Dämonischer Wolf (`:444`)** | ✓ | ✗ (return davor) | ✗ |
- Folge: Henker-Aktivierung (braucht LynchCount≥3) verzögert sich; vom Henker markierte Spieler überleben, wenn der Lynch einen dieser Pfade trifft.

### L6. 🟠 `checkWinConditions`: fehlendes `return` nach Wolfssieg (= A2 aus Teil 1, bestätigt) — `js/ui/core.js:220`.

### L7. 🟠 "Die Ewigen" sind unerreichbar
- In `ORDER_BASE` (tier 4.8, `roles.js:36`) UND im passive-Filter (`night.js:89`) → Zeile wird in der Nachtreihenfolge nie gerendert → der vorhandene Fähigkeits-Handler (`abilities-roles-chunk.js:253`) ist toter Code. Die Rolle kann ihre Nachtprüfung nie ausführen.

### L8. 🟠 Kutscher-Wiederbelebung kann Unikat-Rollen duplizieren
- `abilities-roles-chunk.js:843`: `nonWolfPool` filtert bereits vergebene Rollen **nicht** (Frankenstein macht es richtig, `:64`) → wiederbelebter Spieler kann z. B. einen zweiten "Hades" bekommen. Dazu 6. Inline-Wolfsliste (`:842`) und erneut `/wolf/i` (`:851`, trifft Wolfskind).

### L9. 🟠 Waldhexe: zwei Todestrank-Pfade mit unterschiedlichem Verhalten
- Direkt-Button `btnD` (`abilities-roles-chunk.js:219`): nur Cerberus-Sonderfall, **kein** Voodoo-Puppen-Redirect, kein Gamelog
- Über "Nicht retten" → `hexeAskDeath` (`abilities-helpers.js:262`): Voodoo-Redirect + Cerberus + Puppet-Cooldown + Gamelog
- Gleiche Aktion, je nach Klickweg anderes Ergebnis. Konsolidieren.

### L10. 🟠 setup.html: gespeichertes Layout geht bei jedem Setup verloren
- `setup.html:1058-1059`: `Object.assign({}, appState.layout, fresh.layout)` — **Reihenfolge falsch**, die createState-Defaults überschreiben die gespeicherten Werte (scale/ratio/offx/offy reset). `game.html:1101` macht es richtig (`Object.assign({}, fresh.layout, keptLayout)`).

### L11. 🟡 Totenkarten-System: Setup-Zuweisung ist wirkungslos
- `setup.html:1083`: `assignTotenkarten.call({state: fresh})` — die Funktion nutzt das **globale** `state` (in setup.html nicht definiert) → ReferenceError, still geschluckt. No-op.
- Grundsätzlicher: `applyKill` (`core.js:184-194`) zieht beim Tod **immer eine neue Karte** und überschreibt jede Vorab-Zuweisung. Damit ist `assignTotenkarten` (inkl. "Wölfe ausgenommen", `helpers:12`) funktionslos — Wölfe bekommen beim Tod trotzdem Karten. Entweder Vorab-Zuweisung respektieren oder sie streichen.

### L12-L14. 🟡 Regelfragen (PRÜFEN — Code vs. Beschreibung, Entscheidung Markus)
- **L12 Rachsüchtiger Wolf** (`chunk:347`): löscht beim Zielen ALLE `targeted` → sein Wolfs-Kill **ersetzt** das normale Nachtopfer. Beschreibung sagt "wachst **zusätzlich** auf". Gewollt?
- **L13 Märtyrerin** (`night.js:250`): Opferung rettet **alle** Nachtopfer (`resolveDayKills([])`), nicht nur eines — relevant bei Rudelvater-Extra-Kill/Schicksalswolf. Gewollt?
- **L14 Verdammniswächter** (`chunk:730`): tötet sofort per `applyKill` — umgeht "Der Weise übersteht ersten Angriff" und die Schmied-Waffe (beide nur im Morgen-Resolve `processOne`, `night.js:316/338`). Gewollt?

### L15. 🟡 Gamelog-Filter verschluckt gewollte Einträge
- `gamelog.js:17-29` (Recap-Whitelist): kein Keyword-/Icon-Match für: Ritter-Log "wurde vom Ritter **erschlagen**" (⚔️), Detektiv-Hinweis (🔍, `core.js:77`), Nekromant-Sieg (🏆, `game.html:562`), Spiegelwolf EN "was reflected", Märtyrerin "geopfert" (Keyword ist "opferte"). Diese `gameLog.add()`-Aufrufe laufen ins Leere.

### L16. 🟡 Tote/konkurrierende Patch-Schichten in game.html (Aufräum-Kandidaten)
- `WhiteWolfCharges` (`:2298`): gesetzt, nie gelesen — toter Patch
- `wrapPickOnce`/`wrapStartMultiOnce` (`:1898-1935`): wrappt `window.pick`/`window.startMulti`, aber Abilities bekommen `startPick` direkt übergeben → wirkungslos (Sterne funktionieren über `onOrderClick` sowieso)
- **Drei** konkurrierende Kreis-Verschiebe-Tools: Slider (offx/offy), `centerDot` (`:1462`), `dragHandle`-Overlay (`:2171`, 64px-Kreis, z-index 9999 — verdeckt im SVG-Fallback-Modus die Spielfeldmitte/Lynch-Button); dazu Dynamic-Circle-Panel mit hartkodiertem cx=600/cy=350, das gegen `draw()` kämpft
- `tSound` (`:1768`): setzt Alarm ohne `save()`, nutzt `alert()`, dupliziert `alarmFile` (`:576`)
- `resetOnce` (`:568`): zweite, deutlich unvollständigere Reset-Liste neben `clearRolesNewRound` (`:522`) — das strukturelle once-Reset-Problem aus AUDIT.md 6.8

---

## T) TEXTFEHLER DEUTSCH

| # | Stelle | Fehler | Korrekt |
|---|---|---|---|
| T1 | `cards.js` solo_01 (`:480`) | "Schreibe ... einen Spieler und **gebe sie** dem Spielleiter"; "am **spielgeschehen**" | "schreibe ... und **gib ihn** dem Spielleiter"; "am **Spielgeschehen**" |
| T2 | solo_02 (`:486`) | "Du **tippt**"; "**Liegt** du richtig" | "Du tippst"; "Liegst du richtig" |
| T3 | solo_06 (`:510`) | "**Nominieren** und mit **Abstimmen**", "zählt deine Stimme **Doppelt**", "jemanden zu **Lynchen**", "einer **Neuen** Solo-Rolle" | Verben/Adjektive klein |
| T4 | wende_11 (`:375`) | "**Trugbildwolf**" | "Trugbilder­wolf" (offizieller Rollenname) |
| T5 | loki_06 (`:425`) | "zweier zufälliger lebender Spieler beide gehören **der selben** Fraktion an" | Satzzeichen + "derselben" |
| T6 | solo_11/solo_13 (`:540/:552`) | "erneut einmal **Nominieren**", "dürfen **Reden, Nominieren und Lynchen**" | Verben klein |
| T7 | `roles.js:105` Selbstmörder | "am Tage **Gelyncht** wird" | "gelyncht" |
| T8 | `roles.js:110` Kartenschlucker | "jedes Mal wenn ein Toter **ihre** Karten austauscht" | "jedes Mal, wenn ein Toter **seine** Karte austauscht" |
| T9 | `chunk:700` + `i18n.js:763,864` | "**Wieviele** Wölfe aufdecken?" | "Wie viele" (Achtung: String ist zugleich Runtime-Übersetzungs-Key — beide Seiten ändern) |
| T10 | `roles.js:117` Rudelvater (DE) | "Überlebt den ersten Tod durch eine Sonderfähigkeit" — missverständlich | Code + EN sagen: überlebt den ersten Tod, der NICHT Wolfsangriff/Lynch ist. DE präzisieren |
| T11 | systematisch, ~25 Kartentexte | Fehlende Kommas: "so schlecht **dass**", "Stirbt X **stirbt** Y", "Wer ... spricht **stirbt** sofort", "solange gelyncht **bis**" | Komma vor dass/bis; Komma nach Konditional-Vorfeld |

## E) TEXTFEHLER ENGLISCH

| # | Stelle | Fehler |
|---|---|---|
| E1 | `roles.js:283` | Key **"Parasite"** statt "Parasit" → EN-Beschreibung des Parasit wird nie gefunden, EN-Spieler sehen Deutsch (skriptgeprüft) |
| E2 | `roles.js:220` | "Das Orakel" EN-Text ist Copy-Paste vom Traumdeuter ("Receives visions...") statt Kugel/Rollen-Einsicht (skriptgeprüft: identische Strings) |
| E3 | `roles.js` | EN inhaltlich unvollständig vs. DE: Spürhund (Falsche-Spur-Mechanik fehlt, `:222`), Schutzgeist (Wolf-Offenbarung fehlt, `:272`), König Lykaon (Trugbilderwolf-Folge fehlt, `:226`) |

## H) Hardcodierte DE-Strings, die bei Sprache=EN deutsch bleiben

Die Runtime-Übersetzung (`translateRuntimeText`, läuft in `center()`/`tUi`) fängt vieles ab — aber **direkte `mb.textContent`-Dialoge umgehen sie**:
- Frankenstein-Dialog komplett (`chunk:39-94`: "Möchtest du jemanden wiederbeleben?", "Rolle vergeben", ...)
- Loki "Liebe ❤ oder Hass 💔 ?" (`chunk:133-135`), Waldhexe "Nicht retten"/"Kein Opfer gesetzt." (`chunk:213-214`), Schattenhund-Dialog (`chunk:703-706`), Korrupter Richter (`chunk:718`), Rachsüchtiger Wolf "Jetzt töten?" (`chunk:334-342`), Blutpriester (`chunk:700`)
- `showNightDeathSummary`-Titel "☀️ Nacht X — Morgengrauen" (`ui.js:472`), Rollen-Picker-Texte ("Rolle wählen", "Nacht-Position:", `game.html:257,317,693`), Flag-Gruppen "Status"/"Sozial"/"Fraktion" ohne data-i18n (`game.html:268,288,298`)
- Totenkarten-Overlays: bekannt, separater Lauf (Teil 1, D)

---

## Empfohlene Reihenfolge (Triage Teil 2)

| Prio | Was | Risiko |
|---|---|---|
| 1 | **L3** Zufallsnamen-Zeile entfernen | keins |
| 2 | **L2** doppelte Ritter-Funktion + Cause-String | klein |
| 3 | **L4** Undo-Off-by-one | klein |
| 4 | **L10** setup.html assign-Reihenfolge | klein |
| 5 | **E1+E2** EN-Key/Copy-Paste + **T1-T9** Texte | keins |
| 6 | **L5** doLynchFlow-Pfade vereinheitlichen | mittel |
| 7 | **L1** Wolf-Klassifikation konsolidieren (+L6, mit Teil-1 A3/A4) | **mittel-hoch, manuell testen** |
| 8 | **L7/L8/L9/L15** Einzelfixes | klein-mittel |
| 9 | **L12-L14** erst Regel-Entscheidung von Markus | — |
| 10 | **L16** Patch-Schichten aufräumen | mittel (eigener Lauf) |

*Tiefenanalyse: Claude (Fable 5), 2026-06-12. Read-only.*
