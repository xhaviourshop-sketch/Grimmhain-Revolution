# 02 · Audit der umgesetzten Godot-Rollen (11 Vertical-Slice-Rollen, Nachtrag `siegreicher-wolf`)

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · nur Analyse, kein Code geändert
**Statuswerte:** ausschließlich aus [`00-method-and-sources.md`](00-method-and-sources.md) §3.

Pfade sind relativ zu `docs/role-migration/`. Der Auftrag nennt 11 Rollen als umgesetzt. Diese Liste wurde nicht übernommen, sondern gegen RoleCatalog, Produktionscode, Tests, README und Regelregister geprüft.

**Nachtrag Rollenaudit 2026-09-27:** `siegreicher-wolf` ist im Regelkern umgesetzt und getestet; aktueller Prüfstatus aller Rollen in [`11-role-audit-status.md`](11-role-audit-status.md).

## 1. Ergebnis in einem Satz

Alle 11 Rollen sind im Regelkern **implementiert und durch grüne headless Tests belegt** (Lauf am 26.09.2026: `godot/tests/run_all.sh` → „351 Tests, 0 fehlgeschlagen“, Exit-Code 0). Keine davon ist **spielfertig** im Sinne des Masterplans: Es fehlen für alle Rollen UI-Ablauf, lokalisierte Anzeigenamen und Regeltexte im Godot-Inhalt, Undo/Redo, Checkpoints auf Datenträger, öffentliche Projektionen und die echte Runde auf dem iPad. Das betrifft den Gesamtausbau, nicht die Regelumsetzung der einzelnen Rolle.

| Kennzahl | Wert |
|---|---:|
| im RoleCatalog vorhandene Rollen | 16 (Nachtrag Rollenaudit) |
| davon Migrationsstatus `implemented-and-tested` | 16 |
| davon `implemented-partial` | 0 |
| Rollen mit eigener Unit-Testdatei | 14 (`dorfbewohner` und `werwolf` ohne eigene Datei, aber in Szenarien und fast allen Rollentests benutzt) |
| Testrollen im Katalog | 0 (die frühere `test-sensentraeger` ist entfernt, [`../../godot/README.md`](../../godot/README.md) „Umsetzungsentscheidungen“ Nr. 13) |

## 1a. Geltungsbereich des Status (Konsolidierung 2026-09-27)

`implemented-and-tested` gilt **nur für den Regelkern**. Geprüft gegen `origin/main` `5eb5f2a`; seit dem Basiscommit hat sich `godot/core/` nicht geändert, neu sind nur UI-Setup (Spielernamen), Asset- und Audiodokumente.

| Ebene | Stand für alle 11 Rollen | Beleg |
|---|---|---|
| Regelkern implementiert | ja | `godot/core/rules/role_catalog.gd` und die in §3 genannten Regeldateien |
| Verhalten durch automatisierte Tests belegt | ja, headless | `godot/tests/run_all.sh` am Basiscommit `4673b0b`: 351 Tests, 0 fehlgeschlagen; Rollentests unter `godot/tests/unit/` |
| über die aktuelle Oberfläche bedienbar | **nein** | `main` enthält nur die Erfassung der Spielernamen (`docs/ui/player-setup.md`: „Rollen, Sitzordnung und `StartGame` folgen in späteren Arbeitspaketen“). Ein Rollen-Setup mit Verteilung existiert nur auf dem nicht gemergten Branch `claude/sleepy-babbage-u2o0i2` und erzeugt dort ausdrücklich kein `StartGame`. Nachtrag 27.09.2026: im lokalen Integrationsbranch `integration/cloud-to-local-20260927` zusammengeführt (Stand `53a3c7d`), weiterhin ohne `StartGame` und ohne Tablet-Abnahme |
| im vollständigen Spielablauf geprüft | **nein** | nur headless Befehlsfolgen (Szenarien `godot/tests/scenarios/`, Unit-Tests); keine vollständige Runde über die Oberfläche |
| auf einem echten Tablet geprüft | **nein** | kein Gerätenachweis im Repository; Masterplan Phase 2 Gate offen |

Frühere Formulierungen „vollständig umgesetzt“ bzw. „vollständig implementiert“ (auch im Abschlussbericht der Analyse) meinen ausschließlich die ersten beiden Zeilen.

## 2. Prüfmethode

1. `RoleCatalog.ROLES` in [`../../godot/core/rules/role_catalog.gd`](../../godot/core/rules/role_catalog.gd) gelesen: genau 11 Schlüssel.
2. Für jede ID die Verwendung im Kern gesucht (`rg` nach Konstante und String-ID in `godot/core/`).
3. Testdateien unter [`../../godot/tests/unit/`](../../godot/tests/unit/) und Szenarien unter [`../../godot/tests/scenarios/`](../../godot/tests/scenarios/) gezählt (`^func test_`).
4. Abgleich mit Regelregister [`../specs/vertical-slice/rules-register.md`](../specs/vertical-slice/rules-register.md), Entscheidungen in [`../masterplan/DECISION-LOG.md`](../masterplan/DECISION-LOG.md) und README-Rollentabelle.
5. Vollständiger Testlauf ohne Filter, einschließlich UI-Tests.

Grenze: Die Tests wurden nicht inhaltlich einzeln nachgerechnet. Die Aussage „getestet“ stützt sich auf den grünen Lauf und die Beschreibung der Testabdeckung in der README, stichprobenartig gegen Testnamen geprüft.

## 3. Übersicht

| # | ID | DE / EN (Regelregister) | Fraktion (Katalog) | `counts_as_wolf` | Nachtpriorität (Katalog ×10) | Produktionscode (Hauptdateien) | Tests (`func test_`) | Spezifikation | Migrationsstatus | Automation | Legacy-Status (Befund aus `04`, hier nachgeprüft) |
|---|---|---|---|---|---:|---|---|---|---|---|---|
| 1 | `dorfbewohner` | Dorfbewohner / Villager | village | nein | – | `role_catalog.gd`, `win_rules.gd` (`evaluate`) | keine eigene Datei; `test_player_count_range.gd` (5), Szenarien `as-c01` bis `as-c04`, Fixture in fast allen Rollentests | Register §1 | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 2 | `werwolf` | Werwolf / Werewolf | wolves | ja | Rudel 20 (`PACK_PRIORITY`) | `step_queue.gd` (Rudelschritt `pack`), `kill_pipeline.gd`, `win_rules.gd`, `information_rules.gd` | keine eigene Datei; `test_steps.gd` (7), `test_replay.gd` (4), `test_save_load.gd` (4), Szenarien `as-c01` bis `as-c03`, `as-c10` | Register §2, G-PH-6 | `implemented-and-tested` | `automatic` | `legacy-verified` (Rolle selbst korrekt; der Rudel-Bug F2 trifft andere Wolfsrollen, siehe §4.2) |
| 3 | `schutzengel` | Schutzengel / Guardian Angel | village | nein | 13 | `step_queue.gd`, `protections.gd`, `kill_pipeline.gd` (`_prevented_by_protection`), `gm_corrections.gd` | `test_schutzengel.gd` (29) | Register §3, DR-05 | `implemented-and-tested` | `automatic` | `legacy-broken` (Schutz wird beim Antippen verbraucht) |
| 4 | `waldhexe` | Waldhexe / Witch of the Woods | village | nein | 34 | `witch_step.gd`, `kill_pipeline.gd`, `step_queue.gd`, `gm_corrections.gd` | `test_waldhexe.gd` (43) | Register §6, DR-06 | `implemented-and-tested` | `automatic` | `legacy-verified` (Text mehrdeutig; Tränke technisch global statt je Person) |
| 5 | `das-orakel` | Das Orakel / The Oracle | village | nein | 46 | `oracle_step.gd`, `information_rules.gd`, `info_record.gd` | `test_orakel.gd` (28) | Register §4, DR-07 | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 6 | `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | wolves | ja | – (Teil des Rudels) | `role_catalog.gd` (`requires_appearance`), `rules_engine.gd` (Setup), `information_rules.gd`, `gm_corrections.gd` (`set_role_field`) | `test_trugbilderwolf.gd` (23), `test_gm_role_field.gd` (3) | Register §5, DR-08 | `implemented-and-tested` | `automatic` | `legacy-verified` (Code entspricht dem Text „zufällige Nicht-Wolf-Rolle“; DR-08 ändert die Regel bewusst) |
| 7 | `sensentraeger` | Sensenträger / Reaper | village | nein | – | `role_catalog.gd` (`death_reaction`), `kill_pipeline.gd` (`_queue_reaction`), `step_queue.gd` (Reaktionsschritt) | `test_sensentraeger.gd` (21), `test_reactions.gd` (9) | Register §7, DR-09 | `implemented-and-tested` | `automatic` | `legacy-contradictory` (Zeitpunkt nach Tageslynch) |
| 8 | `wolfskind` | Wolfskind / Wolf Child | village, verwandelt wolves | nein, verwandelt ja | 9 | `wolf_child_rules.gd`, `wolf_child_bond.gd`, `role_transition.gd`, `gm_corrections.gd` | `test_wolfskind.gd` (24) | Register §8, DR-10 | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 9 | `lehrling` | Lehrling / Apprentice | village, nach Erbe die der Rolle | nein, nach Erbe die der Rolle | 11 | `apprentice_rules.gd`, `apprentice_bond.gd`, `role_transition.gd`, `kill_pipeline.gd`, `gm_corrections.gd` | `test_lehrling.gd` (23) | Register §9, DR-11 und Korrekturrunden | `implemented-and-tested` | `automatic` | `legacy-broken` (Bug F5, toter Lehrling erbt) |
| 10 | `manipulator` | Manipulator / Manipulator | solo | nein | – | `rules_engine.gd` (Tod bei `Nominate`), `win_rules.gd` (`manipulator_wins`), `win_candidate.gd` | `test_manipulator.gd` (18) | Register §10, DR-12 | `implemented-and-tested` | `automatic` | `legacy-broken` (Richter-Nominierung tötet nicht) |
| 11 | `spiegelwolf` | Spiegelwolf / Mirror Wolf | wolves | ja | – (Teil des Rudels) | `execution_rules.gd` (`preview`, `execute`), `gm_corrections.gd` (`set_mirror`) | `test_spiegelwolf.gd` (20) | Register §11, DR-13 | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 12 | `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf (Rollentext) | wolves | ja | – (Teil des Rudels) | `role_catalog.gd` (`parity_weight`), `win_rules.gd` (`evaluate`) | `test_siegreicher_wolf.gd` (10), `test_role_interaction_fuzz.gd` | Rollentext, [`10`](10-next-decisions.md) „Zur Kenntnis“, G-SIEG-2 | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 13 | `doppelspion` | Doppelspion / Double Agent (Rollentext) | solo | nein | – | `role_catalog.gd`, `win_rules.gd` (`double_agent_wins`, Kandidatenmenge), `win_candidate.gd` (`double_agent_no_wolves`) | `test_doppelspion.gd` (11), `test_role_interaction_fuzz.gd` | RM-DR-155.1–.5, DECISION-LOG „Rollenaudit“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 14 | `selbstmoerder` | Selbstmörder / Death Seeker (Rollentext) | solo | nein | – | `kill_pipeline.gd`, `win_rules.gd` (`record_death_seeker`, Kandidat `death_seeker_lynched`), `game_state.gd` (`death_seeker_wins`) | `test_selbstmoerder.gd` (13), `test_role_interaction_fuzz.gd` | RM-DR-138.1/.3/.4/.5, F-11, DECISION-LOG „Rollenaudit“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 15 | `dorfchronistin` | Dorfchronistin / Village Chronicler (Rollentext) | village | nein | 3 (nur Nacht 1) | `night_one_info.gd`, `step_queue.gd`, `role_catalog.gd` (`first_night_only`) | `test_dorfchronistin.gd` (8), `test_role_interaction_fuzz.gd` | RM-DR-014 = B, F-09, DECISION-LOG „Rollenaudit“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 16 | `die-gebundenen` | Die Gebundenen / The Bound (Rollentext) | village | nein | 5 (gemeinsamer Schritt, nur Nacht 1) | `night_one_info.gd`, `step_queue.gd` (`BOUND`) | `test_die_gebundenen.gd` (8), `test_role_interaction_fuzz.gd` | RM-DR-014 = B, F-08, DECISION-LOG „Rollenaudit“ | `implemented-and-tested` | `automatic` | `legacy-verified` |

Querschnittstests, die alle Rollen betreffen: `test_core_purity.gd` (2), `test_corrupt_save.gd` (10), `test_save_versions.gd` (1), `test_gm_correction.gd` (7), `test_gm_open_prompt.gd` (8), `test_gm_execute.gd` (4), `test_win_status.gd` (5), `test_win_finalize_guard.gd` (3), `test_command_validation.gd` (6), `test_player_identity.gd` (4), `test_seeded_rng.gd` (3), `test_scenarios.gd` (1 Runner für 8 Szenarien).

## 4. Rollen im Einzelnen

### 4.1 `dorfbewohner`
- **Belegt umgesetzt:** Katalogeintrag ohne Nachtschritt; zählt in `WinRules.evaluate` als Nicht-Wolf. Keine Obergrenze (`max_copies` nicht gesetzt, DECISION-LOG „Rollenanzahl der Grundrollen“).
- **Tests:** `test_player_count_range.gd` prüft 6 bis 24 Personen nur mit Dorfbewohnern und Werwölfen; Szenarien `as-c01` bis `as-c04`.
- **Grenzen:** keine rollenspezifischen offenen Punkte. `migrateLegacyRoleIds` in `js/core/state.js` bildet den entfernten Altnamen `Blinzelmädchen` auf `Dorfbewohner` ab (siehe `01` §3); der Godot-Kern kennt keine Altnamen, das ist für den neuen Kern ohne Spielstand-Import (Q10 Empfehlung A) ohne Bedeutung.

### 4.2 `werwolf`
- **Belegt umgesetzt:** Rudelschritt `pack` mit `PACK_PRIORITY` 20; alle lebenden Personen mit `counts_as_wolf` bilden das Rudel, der Schritt existiert, solange irgendein Wolf lebt (Register §2, G-PH-6). Tod `NIGHT_KILL` in der Morgenauflösung über `KillPipeline.request_kill`. Einziger überspringbarer Schritt (`StepQueue.SKIPPABLE_BY_KIND`).
- **Tests:** Rudelwahl, Skip mit Grund, Parität, Replay und Save/Load in `test_steps.gd`, `test_replay.gd`, `test_save_load.gd` und den Szenarien.
- **Legacy-Bug F2 behoben:** Legacy erzeugt die Werwolf-Zeile nur, wenn eine Rolle aus `WOLF_KILL_ROLES` lebt (`rebuildOrder`, `js/core/night.js:50-55`). Diese Liste enthält unter anderem `Giftwolf`, `Rudelvater`, `Schwarze Witwe`, `Siegreicher Wolf` nicht; lebt nur eine solche Wolfsrolle, fehlt der Tötungsschritt. Godot bildet das Rudel aus `counts_as_wolf`.
- **Grenzen:** Rudelziel ist jede lebende Person, auch ein Wolf (Register §2). Spätere Wolfsrollen mit eigenem Schritt (Giftwolf, Schwarze Witwe usw.) brauchen eine Erweiterung des Nachtplans; das Rudel selbst ist dafür vorbereitet.

### 4.3 `schutzengel`
- **Belegt umgesetzt:** persönlicher Pflichtschritt vor dem Rudel, genau eine andere lebende Person, `Protection` gespeichert, Wirkung erst in der Morgenauflösung und nur gegen `NIGHT_KILL` des Rudels (`KillPipeline._prevented_by_protection`). `SkipStep` nie zulässig.
- **Tests:** 29 Testfunktionen, u.a. zwei Schutzengel, Tod nach Bestätigung, Korrekturen, Leak-Test.
- **Legacy-Bug behoben:** Legacy verbraucht den Schutz beim Antippen des Wolfsziels (`Werwolf`-Handler, `js/core/abilities-roles-chunk.js:162`, `protectedCount` wird schon bei der Zielwahl reduziert). Zusätzlich schließt der Legacy-Filter jede Person mit Rolle `Schutzengel` aus (`abilities-roles-chunk.js:157-161`, `(x.role||"")!=="Schutzengel"`), nicht nur sich selbst; Godot erlaubt einen anderen Schutzengel als Ziel.
- **Abweichung zum Legacy-Text (gewollt, DR-05):** Text „vor dem nächsten Werwolfangriff“; Godot: nur in dieser Nacht.
- **Grenzen:** Das Schutzsystem kennt genau zwei Quellen (Schutzengel, Waldhexe). Für `dorfwache`, `der-weise`, `dorfschmied`, `schutzgeist`, `seuchenwolf` (Durchbruch) und `rudelvater` (Zusatzopfer ohne Schutz) muss die Abfangstufe verallgemeinert werden (siehe [`06`](06-implementation-batches.md) §2).

### 4.4 `waldhexe`
- **Belegt umgesetzt:** mehrstufige, persistente Prompt-Kette `witch_chain`, Tränke je Person (`ability_uses`), Rettung nur gegen das aktuelle Rudelopfer, Gift sofort `WITCH_POISON`, Reaktionen am Morgen.
- **Tests:** 43 Testfunktionen, umfangreichste Rollendatei.
- **Legacy-Abweichungen (gewollt):** Legacy speichert die Tränke global (`state.once.WaldhexeL`/`WaldhexeD`), nicht je Person. DR-06 legt beide Tränke in einer Nacht fest.
- **Dokumentinkonsistenz (nicht geändert, siehe [`09`](09-executive-summary.md) §8):** EN-Name im Regelregister und in der Legacy „Witch of the Woods“, in [`../../godot/README.md`](../../godot/README.md) Rollentabelle, im Kommentar von `role_catalog.gd` und in `test_waldhexe.gd` „Forest Witch“. Der Anzeigename liegt noch in keiner Godot-Übersetzungsdatei.

### 4.5 `das-orakel`
- **Belegt umgesetzt:** Schritt nach allen Waldhexen, keine Selbst- oder Totwahl, `InformationRules.determine_role` (Erscheinung → `werwolf` bei `counts_as_wolf` → Rolle), `InfoRecord` mit Wahrheit/ermittelt/gezeigt, Übersteuerung `OverrideShownRole`, getrennte GM- und Actor-Ereignisse.
- **Tests:** 28 Testfunktionen einschließlich ACTOR- und PUBLIC-Leak-Tests.
- **Grenzen:** `InfoRecord` ist auf das Orakel zugeschnitten (Feld `oracle_id`, Ergebnis ist immer eine Rolle). Weitere Informationsrollen mit anderem Ergebnistyp (Anzahl, Richtung, ja/nein, Namensliste) brauchen ein allgemeineres Informationsmodell (siehe [`06`](06-implementation-batches.md) §2).

### 4.6 `trugbilderwolf`
- **Belegt umgesetzt:** Wolfsfraktion ohne eigenen Schritt, Pflicht-Scheinrolle `appears_as` beim Setup (`requires_appearance`), zufällige Rollenverteilung über `role_entries` (die Scheinrolle je Kopie wählt ausdrücklich der Spielleiter, DR-08; sie wird nicht ausgelost), Korrektur per `set_role_field`.
- **Tests:** 23 Testfunktionen plus `test_gm_role_field.gd`.
- **Legacy-Abweichung (gewollt, DR-08):** Legacy zieht die Scheinrolle im Orakel-Handler per `Math.random` (siehe `docs/godot-migration/04-rules-migration-matrix.md` A-33). Der Legacy-Text „Täuscht das Orakel mit zufälliger Nicht-Wolf-Rolle“ widerspricht damit dem neuen Verhalten; der Text muss für Godot neu formuliert werden.
- **Abhängigkeit:** `koenig-lykaon` erzeugt in Legacy Trugbilderwölfe während der Partie; dafür fehlt in Godot eine Regel, welche Scheinrolle ein nachträglich entstandener Trugbilderwolf erhält (siehe [`04`](04-rule-conflicts.md) RM-C-004 und RM-DR-107).

### 4.7 `sensentraeger`
- **Belegt umgesetzt:** freiwillige Todesreaktion `curse` (einzige Reaktionsart `Reaction.KIND_CURSE`), einmal pro Person, Tod `HUNTER_SHOT`, am Tag sofort, nachts in der Morgenauflösung, kein Selbstziel.
- **Tests:** 21 Rollentests und 9 Tests der Reaktionswarteschlange.
- **Legacy-Abweichung (gewollt, DR-09):** Legacy arbeitet die Warteschlange nach einem Tageslynch erst nach der nächsten Nacht ab (`docs/godot-migration/04-rules-migration-matrix.md` A-6).
- **Grenzen:** Die Reaktionswarteschlange kennt nur `curse`. `ritter` (automatische Vergeltung), `besessener-wolf` (Mitnahme), `daemonischer-wolf` (Fluch als Markierung) und `feuerteufel` (Nachbarn brennen) brauchen weitere Reaktionsarten.

### 4.8 `wolfskind`
- **Belegt umgesetzt:** Vorbildwahl (Priorität 9), Verwandlung als unmittelbare Todesfolge vor der vorläufigen Siegprüfung, Rudel ab folgender Nacht, Korrekturen `set_wolf_model`, `transform_wolf_child` usw.
- **Tests:** 24 Testfunktionen.
- **Grenzen:** `waechter-am-tor` würde die Verwandlung in Legacy blockieren (`gatewardenBlocksNewWolves`, `js/ui/core.js:387-389`); in Godot existiert dafür noch kein Einhängepunkt.

### 4.9 `lehrling`
- **Belegt umgesetzt:** verdeckte Auswahl aus drei Rollen (DR-11), Bindung `ApprenticeBond`, Erbe über `RoleTransition.change_role` mit frischen Einsätzen, Verfall beim eigenen Tod, vier Korrekturarten.
- **Tests:** 23 Testfunktionen einschließlich Erbe jeder Slice-Rolle.
- **Legacy-Bug F5 behoben:** `postDeathHooks` sucht den Lehrling ohne Totprüfung (`js/ui/core.js:389`, `state.seats.find(s=>s.role==="Lehrling")`), ein toter Lehrling erbt.
- **Legacy-Abweichung (gewollt):** Legacy wählt den Mentor direkt als Person und nur in Nacht 1 (`ORDER_BASE` Tier 1.1 `once`); DR-11 ändert das Verfahren grundlegend.
- **Grenzen:** Jede neue Rolle, die geerbt werden kann, braucht einen Test „Lehrling erbt X“. Das ist ein wiederkehrender Aufwand pro Charge (siehe [`07`](07-test-strategy.md) §3).

### 4.10 `manipulator`
- **Belegt umgesetzt:** Tod `MANIPULATOR_NOMINATED` direkt nach gespeicherter Nominierung, `ever_nominated` als Personenstatus, Siegkandidat bei exakt drei Lebenden, mehrere Manipulatoren getrennt.
- **Tests:** 18 Testfunktionen.
- **Legacy-Bug:** Die Nominierung durch den Korrupten Richter setzt in Legacy keine Manipulator-Folge (`docs/godot-migration/04-rules-migration-matrix.md` A-26, A-67). Im Godot-Kern gibt es den Richter noch nicht; sobald `korrupter-richter` kommt, muss dessen Markierung als echte Nominierung laufen oder die Wechselwirkung ausdrücklich entschieden werden (siehe [`08`](08-decision-request.md) RM-DR-012).

### 4.11 `spiegelwolf`
- **Belegt umgesetzt:** zentrale Hinrichtungsauflösung `ExecutionRules.preview`/`execute`, Spiegelung auf die nominierende Person einmal pro Person, Selbstnominierung, `set_mirror`.
- **Tests:** 20 Testfunktionen.
- **Grenzen:** `ExecutionRules` kennt nur die Spiegelung. Weitere Hinrichtungsreaktionen (`wahnsinniger-kutscher`, `fenrir`, `cerberus`, `voodoo-priester`, `selbstmoerder`, `henker`, `rudelvater`, `der-weise`, `feuerteufel`) brauchen eine geordnete Liste von Hinrichtungsregeln mit fester Reihenfolge (Legacy-Reihenfolge `doLynchFlow`, `js/core/night.js:421-504`).

### 4.12 `siegreicher-wolf`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Wolfsfraktion ohne eigenen Schritt, Teil des Rudels (G-PH-6). `RoleCatalog.parity_weight` = 2; `WinRules.evaluate` zählt ihn, solange er lebt, in der Wolfsparität doppelt (`reason_args.wolves` ist der Paritätswert). Die Dorfbedingung zählt weiter lebende Wolfspersonen, der Manipulator weiter Personen.
- **Tests:** `test_siegreicher_wolf.gd` (10): Rudel allein, Orakel `werwolf`, Parität 2 gegen 2, tot zählt 0, Dorfsieg erst ohne lebenden Wolf, zwei Kopien, Wiederbelebung, Lehrling-Erbe mit sofortiger Doppelzählung, Rollenkorrektur, Manipulator zählt Personen, Save/Load, Replay, Leak; zusätzlich im Fuzztest.
- **Grenzen:** Regelquelle ist der widerspruchsfreie Rollentext (Legacy gleich) mit der Auslegung aus [`10`](10-next-decisions.md) „Zur Kenntnis“; keine eigene Decision-Log-Zeile.

### 4.13 `doppelspion`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Einzelsieg, zählt nicht als Wolf (Parität, RM-DR-155.2), kein eigener Schritt. Lebt kein Wolf, entsteht je lebendem Doppelspion ein Kandidat `double_agent_no_wolves`; der Dorfkandidat entfällt dann (RM-DR-155.3). Tot gewinnt er nicht (RM-DR-155.1). Aufwachen mit dem Rudel ist nur Ansage ohne Rollennennung (RM-DR-155.4/.5). Orakel: tatsächliche Rolle (DR-07). Ladeprüfung wie beim Manipulator.
- **Tests:** `test_doppelspion.gd` (11): Rolle, Hinrichtung des letzten Wolfs, tot → Dorf, zwei Kopien, einer tot, Parität, mit Manipulator gleichzeitig, Lehrling-Erbe, erneuter Vorschlag nach Ablehnung, beschädigter Kandidat, Leak; Fuzztest.
- **Grenzen:** „Der Angriff des Rachsüchtigen Wolfs verpufft an ihm“ folgt mit `rachsuechtiger-wolf`.

### 4.14 `selbstmoerder`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Einzelsieg, zählt nicht als Wolf, kein Schritt. Stirbt er mit Ursache `LYNCH` (auch `GmCorrection execute`), während unmittelbar vorher mindestens 5 Personen tot sind (nur aktuell Tote), wird der Sieg in `GameState.death_seeker_wins` festgehalten (Ereignis `DeathSeekerFulfilled`, nur Spielleiter). Ab dann schlägt jede Siegprüfung ihn vor, auch nach Ablehnung und nach Wiederbelebung (RM-DR-138.4, F-11). Spiegelung, Nacht-, Gift- und Korrektur-Tötung zählen nicht.
- **Tests:** `test_selbstmoerder.gd` (13): 5 und 4 Tote, Wiederbelebte zählen nicht, Spielleiter-Hinrichtung, andere Todesarten, Spiegelung, erneuter Vorschlag nach Ablehnung und Wiederbelebung, gleichzeitig mit Dorfsieg, zwei Kopien, Lehrling-Erbe, 6 Personen (niemand lebt), Ladeprüfung.
- **Grenzen:** RM-DR-138.2 (zählt eine Henker-Hinrichtung?) folgt mit `henker`. Sound bei 5 Toten ist eine Oberflächenanforderung (Decision Log), nicht Regelkern.

### 4.15 `dorfchronistin`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Dorf; persönlicher Schritt `dorfchronistin:<id>` mit Priorität 3, nur in Nacht 1 (RM-DR-014 = B). Der Prompt zeigt dem Spielleiter die Anzahl der Personen mit Einzelsiegrolle, lebend und tot (F-09); „Gezeigt“ erzeugt `ChronicleRecorded` (Spielleiter) und `ChronicleRevealed` (nur die Chronistin). Abbrechbar, nicht überspringbar; Ladeprüfung vergleicht die Zahl mit dem Zustand.
- **Tests:** `test_dorfchronistin.gd` (8): Rolle und Plan, Zählung inklusive Toter, nur Nacht 1, zwei Chronistinnen, tote Chronistin, Abbruch und Rollenkorrektur, ungültige Antworten und beschädigter Prompt, Leak.
- **Grenzen:** Blockaden in Nacht 1 (Schattenhund, Albtraumwolf) folgen mit diesen Rollen; ein Lehrling-Erbe nach Nacht 1 gibt keinen Schritt.

### 4.16 `die-gebundenen`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Dorf; ein gemeinsamer Schritt `die-gebundenen` mit Priorität 5, nur in Nacht 1, solange eine Gebundene lebt (RM-DR-014 = B). Der Prompt zeigt dem Spielleiter die lebenden Gebundenen; „Gezeigt“ erzeugt `BoundRecorded` (Spielleiter) und je lebender Gebundener `BoundRevealed` mit den anderen lebenden (F-08; allein: leere Liste). Abbrechbar, nicht überspringbar, entfällt ohne lebende Gebundene.
- **Tests:** `test_die_gebundenen.gd` (8): Rolle und Plan, tote Gebundene ausgeschlossen, allein, nur Nacht 1, alle tot, Abbruch und beschädigter Prompt, 24 Personen mit sechs Gebundenen, Leak.
- **Grenzen:** Blockaden in Nacht 1 folgen mit Schattenhund und Albtraumwolf.

## 5. Bekannte Grenzen, die alle 11 Rollen betreffen

| Grenze | Beleg | Folge für die Migration |
|---|---|---|
| Keine Anzeigenamen und Regeltexte im Godot-Inhalt | `godot/content/i18n/ui.de.po` enthält 55 UI-Einträge, keine Rollennamen | B-16 offen; gehört nicht in diese Sitzung (UI-Dateien gesperrt) |
| Kein Undo/Redo, keine Checkpoints auf Datenträger | README „Nicht enthalten“, `implementation-boundary.md` B-12, B-13 | Undo-Tests pro Rolle erst nach B-12 möglich |
| Keine öffentlichen Projektionen | README „Nicht enthalten“, B-18 | Sichtbarkeit wird nur über Ereignis-Sichtbarkeit (gm/actor/public) geprüft |
| Keine UI für den Spielablauf | README „Nicht enthalten“ | Keine Rolle ist am Tablet bedienbar |
| Kein allgemeines Effektmodell | README „Nicht enthalten“ | Jede neue Mechanikfamilie braucht bisher eigene Datenfelder und Schemaerweiterung |
| `ABILITY_USE_KEYS` ist eine feste Liste | `role_catalog.gd:43` | Jede Rolle mit begrenztem Einsatz erweitert Liste, Ladeprüfung und Schema |
| Schema-Version 10 ohne Migration | README „Spielstand“ | Jede Charge mit neuem Zustand erhöht das Schema; alte Stände werden abgelehnt (bis 1.0 akzeptabel) |
| README-Dateiverantwortung veraltet | `godot/README.md` Zeile zu `role_catalog.gd` nennt nur 6 Rollen | Dokumentpflege, hier nicht geändert |

## 6. Folgerung für die Statusmatrix

Für [`../masterplan/RULE-MIGRATION-MATRIX.md`](../masterplan/RULE-MIGRATION-MATRIX.md) ist nachweisbar:

- 11 Rollen: Core-Verhalten vorhanden und getestet. Das entspricht dort dem Status „implemented“.
- `verified` verlangt laut Matrix zusätzlich „Tests und echte Runde bestanden“ sowie Undo-Tests. Eine echte Runde und Undo existieren nicht. Deshalb erhält keine Rolle dort „verified“.
