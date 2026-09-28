# 02 · Audit der umgesetzten Godot-Rollen (11 Vertical-Slice-Rollen, Nachtrag `siegreicher-wolf`)

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · nur Analyse, kein Code geändert
**Statuswerte:** ausschließlich aus [`00-method-and-sources.md`](00-method-and-sources.md) §3.

Pfade sind relativ zu `docs/role-migration/`. Der Auftrag nennt 11 Rollen als umgesetzt. Diese Liste wurde nicht übernommen, sondern gegen RoleCatalog, Produktionscode, Tests, README und Regelregister geprüft.

**Nachtrag Rollenaudit 2026-09-27:** `siegreicher-wolf` ist im Regelkern umgesetzt und getestet; aktueller Prüfstatus aller Rollen in [`11-role-audit-status.md`](11-role-audit-status.md).

## 1. Ergebnis in einem Satz

Alle 11 Rollen sind im Regelkern **implementiert und durch grüne headless Tests belegt** (Lauf am 26.09.2026: `godot/tests/run_all.sh` → „351 Tests, 0 fehlgeschlagen“, Exit-Code 0). Keine davon ist **spielfertig** im Sinne des Masterplans: Es fehlen für alle Rollen UI-Ablauf, lokalisierte Anzeigenamen und Regeltexte im Godot-Inhalt, Undo/Redo, Checkpoints auf Datenträger, öffentliche Projektionen und die echte Runde auf dem iPad. Das betrifft den Gesamtausbau, nicht die Regelumsetzung der einzelnen Rolle.

| Kennzahl | Wert |
|---|---:|
| im RoleCatalog vorhandene Rollen | 63 (Nachtrag Rollenaudit) |
| davon Migrationsstatus `implemented-and-tested` | 63 |
| davon `implemented-partial` | 0 |
| Rollen mit eigener Unit-Testdatei | 61 (`dorfbewohner` und `werwolf` ohne eigene Datei, aber in Szenarien und fast allen Rollentests benutzt) |
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
| 17 | `waldlaeufer` | Waldläufer / Ranger (Rollentext) | village | nein | 54 | `info_steps.gd` | `test_waldlaeufer_doktor.gd`, fuzz | RM-DR-147.1/.2, DECISION-LOG „Rollenaudit · Waldläufer, Doktor, Sitznachbarn …“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 18 | `doktor` | Doktor / Doctor (Rollentext) | village | nein | 50 | `info_steps.gd` (`same_team`) | `test_waldlaeufer_doktor.gd`, fuzz | RM-DR-145.1/.2, DECISION-LOG „Rollenaudit · Waldläufer, Doktor, Sitznachbarn …“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 19 | `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman (Rollentext) | village | nein | – | `kill_pipeline.gd` (`_coachman_crash`), `seats.gd` | `test_seat_roles.gd`, fuzz | RM-DR-003, RM-DR-116.1, DECISION-LOG „Rollenaudit · Waldläufer, Doktor, Sitznachbarn …“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 20 | `nachtwaechter` | Nachtwächter / Night Warden (Rollentext) | village | nein | – | `rules_engine.gd` (`_ring_alarm_bells`), `seats.gd` | `test_seat_roles.gd`, fuzz | RM-DR-003, RM-DR-102.1, DECISION-LOG „Rollenaudit · Waldläufer, Doktor, Sitznachbarn …“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 21 | `dorfwache` | Dorfwache / Village Guard (Rollentext) | village | nein | – | `kill_pipeline.gd` (`_prevented_by_protection`) | `test_seat_roles.gd`, fuzz | Rollentext; RM-DR-119 folgt mit Giftwolf/Seuchenwolf/Rudelvater | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 22 | `besessener-wolf` | Besessener Wolf / Possessed Wolf (Rollentext) | wolves | ja | – (Teil des Rudels) | `kill_pipeline.gd` (`_queue_reaction`), `reaction.gd` (`possessed`) | `test_ritter_besessener_faehrtenleser.gd`, fuzz | RM-DR-124.1, DECISION-LOG „Rollenaudit · Wiederbelebung, Besessener Wolf, Ritter, Fährtenleser“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 23 | `ritter` | Ritter / Knight (Rollentext) | village | nein | – | `kill_pipeline.gd` (`_knight_strike`), `seats.gd` (`closest_wolves`) | `test_ritter_besessener_faehrtenleser.gd`, fuzz | RM-DR-136.1, DECISION-LOG „Rollenaudit · Wiederbelebung, Besessener Wolf, Ritter, Fährtenleser“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 24 | `faehrtenleser` | Fährtenleser / Tracker (Rollentext) | village | nein | 52 | `info_steps.gd` (Stufe `use`), `seats.gd` (`wolf_direction`) | `test_ritter_besessener_faehrtenleser.gd`, fuzz | RM-DR-146.1/.2, DECISION-LOG „Rollenaudit · Wiederbelebung, Besessener Wolf, Ritter, Fährtenleser“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 25 | `blutwolf` | Blutwolf / Blood Wolf (Rollentext) | wolves | ja | – (Teil des Rudels) | `role_catalog.gd`, `vote_hints.gd` | `test_richter_waechter_blutwolf.gd`, fuzz | RM-DR-133.1, RM-DR-008, DECISION-LOG „Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor …“ und „Querschnittsfragen“ | `implemented-and-tested` | `assisted` | `legacy-verified` |
| 26 | `korrupter-richter` | Korrupter Richter / Corrupt Judge (Rollentext) | village | nein | 15 | `rules_engine.gd` (`_judge_nominations`, `_record_nomination`), `vote_hints.gd` | `test_richter_waechter_blutwolf.gd`, fuzz | RM-DR-117, RM-DR-012, DECISION-LOG „Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor …“ und „Querschnittsfragen“ | `implemented-and-tested` | `automatic` | `not-found` |
| 27 | `waechter-am-tor` | Wächter am Tor / Gatewarden (Rollentext) | village | nein | – | `gatewarden.gd`, `wolf_child_rules.gd`, `apprentice_rules.gd` | `test_richter_waechter_blutwolf.gd`, fuzz | RM-DR-149, DECISION-LOG „Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor …“ und „Querschnittsfragen“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 28 | `spuerhund` | Spürhund / Scent Hound (Rollentext, vom PO präzisiert) | village | nein | 68 | `info_steps.gd` (`hound_hit`) | `test_spuerhund_parasit.gd`, fuzz | RM-DR-105.1, DECISION-LOG „Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor, Spürhund, Parasit“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 29 | `parasit` | Parasit / Parasite (Rollentext) | solo | nein | 62 | `kill_pipeline.gd` (`_parasite_immune`, `_end_parasite_bonds`), `win_rules.gd` (`parasite_wins`) | `test_spuerhund_parasit.gd`, fuzz | RM-DR-157.1, RM-DR-011.2, DECISION-LOG „Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor, Spürhund, Parasit“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 30 | `schattenhund` | Schattenhund / Shadow Hound (Rollentext) | wolves | ja | 1 | `rules_engine.gd` (`_answer_shadow`), `step_queue.gd` (Blockade) | `test_wolf_specials.gd`, fuzz | RM-DR-123, RM-DR-010, DECISION-LOG „Rollenaudit · Schattenhund, Albtraumwolf, Giftwolf, Rudelvater, Seuchenwolf“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 31 | `albtraumwolf` | Albtraumwolf / Nightmare Wolf (Rollentext) | wolves | ja | 2 | `step_queue.gd` (Blockade), `rules_engine.gd` | `test_wolf_specials.gd`, fuzz | RM-DR-134, RM-DR-010, DECISION-LOG „Rollenaudit · Schattenhund, Albtraumwolf, Giftwolf, Rudelvater, Seuchenwolf“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 32 | `giftwolf` | Giftwolf / Poison Wolf (Rollentext) | wolves | ja | 27 | `rules_engine.gd` (`wolf_poisons`), `kill_pipeline.gd` | `test_wolf_specials.gd`, fuzz | RM-DR-111, DECISION-LOG „Rollenaudit · Schattenhund, Albtraumwolf, Giftwolf, Rudelvater, Seuchenwolf“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 33 | `rudelvater` | Rudelvater / Packfather (Rollentext) | wolves | ja | – (Teil des Rudels) | `kill_pipeline.gd` (`_packfather_survives`), `step_queue.gd` (`pack2`) | `test_wolf_specials.gd`, fuzz | RM-DR-112, DECISION-LOG „Rollenaudit · Schattenhund, Albtraumwolf, Giftwolf, Rudelvater, Seuchenwolf“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 34 | `seuchenwolf` | Seuchenwolf / Blight Wolf (Rollentext) | wolves | ja | – (Teil des Rudels) | `kill_pipeline.gd`, `rules_engine.gd` (`plague_pierce_pending`) | `test_wolf_specials.gd`, fuzz | RM-DR-108, DECISION-LOG „Rollenaudit · Schattenhund, Albtraumwolf, Giftwolf, Rudelvater, Seuchenwolf“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 35 | `fenrir` | Fenrir (Rollentext) | wolves | ja | – (Teil des Rudels) | `rules_engine.gd` (Wachstum), `kill_pipeline.gd` (`_fenrir_survives`) | `test_fenrir_cerberus_henker.gd`, fuzz | RM-DR-125, DECISION-LOG „Rollenaudit · Fenrir, Cerberus, Henker“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 36 | `cerberus` | Cerberus (Rollentext) | wolves | ja | – (Teil des Rudels) | `execution_rules.gd` (`needs_cerberus_decision`), `rules_engine.gd` | `test_fenrir_cerberus_henker.gd`, fuzz | RM-DR-135, DECISION-LOG „Rollenaudit · Fenrir, Cerberus, Henker“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 37 | `henker` | Henker / Executioner (Rollentext) | village | nein | 78 | `execution_rules.gd` (`_hangman_extras`), `rules_engine.gd` | `test_fenrir_cerberus_henker.gd`, fuzz | RM-DR-130, RM-DR-138.2, DECISION-LOG „Rollenaudit · Fenrir, Cerberus, Henker“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 38 | `traumdeuter` | Traumdeuter / Dreamer (Rollentext) | village | nein | 70 | `info_steps.gd` (Auswahl von drei, `no_wolf_selected`) | `test_info_roles.gd`, fuzz | RM-DR-129, I-01, I-02, I-05, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `assisted` | `legacy-contradictory` |
| 39 | `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter (Rollentext) | village | nein | 32 | `kill_pipeline.gd` (`bounty_credits`), `info_steps.gd`, `step_queue.gd` (Verfall) | `test_info_roles.gd`, fuzz | RM-DR-139, I-02, I-04, I-06, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `assisted` | `legacy-verified` |
| 40 | `koenig` | König / King (Rollentext) | village | nein | 44 | `info_steps.gd` (`king_condition`, `king_candidates`) | `test_info_roles.gd`, fuzz | RM-DR-140, I-03, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `assisted` | `legacy-contradictory` |
| 41 | `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light (Rollentext) | village | nein | 60 | `info_steps.gd`, `rules_engine.gd` (`death_marks`) | `test_info_roles.gd`, fuzz | RM-DR-152, I-07, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 42 | `blutpriester` | Blutpriester / Blood Priest (Rollentext) | village | nein | 82 | `info_steps.gd` (Stufe `reveal`), `rules_engine.gd` (`death_marks`) | `test_info_roles.gd`, fuzz | RM-DR-128, I-08, I-13, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `assisted` | `legacy-verified` |
| 43 | `amalia` | Amalia (Rollentext) | village | nein | – (Tagesaktion) | `rules_engine.gd` (`AmaliaSacrifice`), `phase_machine.gd` | `test_info_roles.gd`, fuzz | RM-DR-151, I-09, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `assisted` | `legacy-contradictory` |
| 44 | `detektiv` | Detektiv / Detective (Rollentext) | village | nein | – (Todesfolge) | `kill_pipeline.gd` (`_detective_hint`), `rules_engine.gd` (`detective_hints`) | `test_info_roles.gd`, fuzz | RM-DR-153, I-10, I-14, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 45 | `die-ewigen` | Die Ewigen / The Eternal Ones (Rollentext) | village | nein | 48 (gemeinsam) | `info_steps.gd` (`eternal_finds`), `win_rules.gd` (`eternal_co_winners`) | `test_info_roles.gd`, fuzz | RM-DR-104, I-11, I-12, I-15, DECISION-LOG „Rollenaudit · Informationsrollen“ | `implemented-and-tested` | `automatic` | `not-found` |
| 46 | `der-weise` | Der Weise / The Elder (Rollentext) | village | nein | – | `guard_roles.gd` (Fluch, `silenced`), `kill_pipeline.gd` (`pack_protection`), `execution_rules.gd` | `test_protection_roles.gd`, fuzz | RM-DR-114, S-01, S-02, S-05, S-09, S-10, S-11, DECISION-LOG „Rollenaudit · Schutzrollen“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 47 | `maertyrerin` | Märtyrerin / Martyr (Rollentext) | village | nein | 90 | `guard_roles.gd` (`martyr_victim`), `rules_engine.gd` (Morgenauflösung) | `test_protection_roles.gd`, fuzz | RM-DR-118, S-03, S-14, DECISION-LOG „Rollenaudit · Schutzrollen“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 48 | `schutzgeist` | Schutzgeist / Guardian Spirit (Rollentext) | village | nein | 56 (tot) | `step_queue.gd` (Ausnahme G-PH-2), `kill_pipeline.gd`, `rules_engine.gd` (`shields`, Meldung) | `test_protection_roles.gd`, fuzz | RM-DR-148, S-04, S-10, S-11, S-12, DECISION-LOG „Rollenaudit · Schutzrollen“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 49 | `dorfschmied` | Dorfschmied / Village Blacksmith (Rollentext) | village | nein | 17 | `kill_pipeline.gd` (`weapons`, Reaktion `smith`), `rules_engine.gd` | `test_protection_roles.gd`, fuzz | RM-DR-154, S-06, S-10, S-11, S-12, DECISION-LOG „Rollenaudit · Schutzrollen“ | `implemented-and-tested` | `assisted` | `legacy-verified` |
| 50 | `verdammniswaechter` | Verdammniswächter / Doom Warden (Rollentext) | village | nein | 23 | `guard_roles.gd` (`doom_offer`, Seed), `rules_engine.gd` | `test_protection_roles.gd`, fuzz | RM-DR-115, S-07, S-08, S-13, S-15, DECISION-LOG „Rollenaudit · Schutzrollen“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 51 | `loki` | Loki (Rollentext) | village | nein | 4 (nur Nacht 1) | `bond_steps.gd` (Stufen targets/mode), `bond_rules.gd` (Liebeskummer) | `test_bond_roles.gd`, fuzz | RM-DR-101, B-01, B-02, B-05, B-08, DECISION-LOG „Rollenaudit · Bindungsrollen“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 52 | `schwarze-witwe` | Schwarze Witwe / Black Widow (Rollentext) | wolves | ja | 28 | `rules_engine.gd` (Todesmarkierung), `bond_rules.gd` (`living_partners`) | `test_bond_roles.gd`, fuzz | RM-DR-113.1, B-03, B-06, DECISION-LOG „Rollenaudit · Bindungsrollen“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 53 | `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood (Rollentext) | village | nein | 74 | `bond_steps.gd` (Stufen targets/grant), `bond_rules.gd` (Kette), `step_queue.gd` (Apfel) | `test_bond_roles.gd`, fuzz | RM-DR-137, R-01 bis R-04, B-08, DECISION-LOG „Rollenaudit · Bindungsrollen“ | `implemented-and-tested` | `assisted` | `legacy-contradictory` |
| 54 | `schattenwanderer` | Schattenwanderer / Shadowwalker (Rollentext) | wolves | ja | 26 | `bond_rules.gd` (`shadow_partner`), `kill_pipeline.gd` | `test_bond_roles.gd`, fuzz | RM-DR-110, B-04, B-07, DECISION-LOG „Rollenaudit · Bindungsrollen“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 55 | `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf (Rollentext) | wolves | ja | – (Todesreaktion) | `rules_engine.gd` (Reaktion `demon`), `information_rules.gd` (`Player.cursed`) | `test_transform_roles.gd`, fuzz | RM-DR-122, V-01, V-02, V-07, DECISION-LOG „Rollenaudit · Verwandlungsrollen“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 56 | `koenig-lykaon` | König Lykaon / King Lycaon (Rollentext) | wolves | ja | 24 | `bond_steps.gd` (Stufen ally/targets, `_convert`) | `test_transform_roles.gd`, fuzz | RM-DR-107, V-03, V-08, V-09, DECISION-LOG „Rollenaudit · Verwandlungsrollen“ | `implemented-and-tested` | `automatic` | `legacy-verified` |
| 57 | `seelentauscher` | Seelentauscher / Soul Swapper (Rollentext) | village | nein | 80 | `bond_steps.gd` (`_swap`), `role_transition.gd`, `gatewarden.gd` | `test_transform_roles.gd`, fuzz | RM-DR-127, V-04 bis V-06, DECISION-LOG „Rollenaudit · Verwandlungsrollen“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 58 | `kutscher` | Kutscher / Coachman (Rollentext) | village | nein | 38 | `bond_steps.gd` (Stufen targets/wolf, `_revive_coach`), `role_transition.gd` (`revive`) | `test_revival_roles.gd`, fuzz | RM-DR-126, RM-DR-013, W-01 bis W-03, DECISION-LOG „Rollenaudit · Wiederbelebungsrollen“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 59 | `dr-victor-frankenstein` | Dr. Victor Frankenstein (Rollentext) | village | nein | 36 | `bond_steps.gd` (Stufen targets/role, `frankenstein_options`) | `test_revival_roles.gd`, fuzz | RM-DR-141.1/.2, RM-DR-013, W-01, W-04, DECISION-LOG „Rollenaudit · Wiederbelebungsrollen“ | `implemented-and-tested` | `assisted` | `legacy-broken` |
| 60 | `rattenfaenger` | Rattenfänger / Pied Piper (Rollentext) | solo | nein | 42 | `solo_rules.gd` (`charms`, `piper_wins`), `rules_engine.gd` | `test_solo_roles_a.gd`, fuzz | RM-DR-103, E-01, DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 1“ | `implemented-and-tested` | `automatic` | `legacy-broken` |
| 61 | `pestbringerin` | Pestbringerin / Plague Bringer (Rollentext) | solo | nein | 72 | `solo_rules.gd` (`infected`, `spread`, Seed) | `test_solo_roles_a.gd`, fuzz | RM-DR-120, E-02, DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 1“ | `implemented-and-tested` | `automatic` | `legacy-contradictory` |
| 62 | `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom (Rollentext) | solo | nein | 86 | `solo_rules.gd` (`prophet_marks`, `prophet_unlocked`), `win_rules.gd` | `test_solo_roles_a.gd`, fuzz | RM-DR-121, E-03, DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 1“ | `implemented-and-tested` | `automatic` | `not-found` |
| 63 | `todesprediger` | Todesprediger / Death Prophet (Rollentext) | solo | nein | 66 (nur Nacht 1) | `bond_steps.gd` (Stufe prediction), `solo_rules.gd` (`preacher_wins`) | `test_solo_roles_a.gd`, fuzz | RM-DR-158, E-04, DECISION-LOG „Rollenaudit · Einzelsiegrollen, Teil 1“ | `implemented-and-tested` | `automatic` | `legacy-broken` |

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

### 4.17 `waldlaeufer`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Informationsschritt jede Nacht (Priorität 54): Anzahl der Personen, die bei seinem Schritt leben und als Wolf zählen, jede einmal; ein Rudelopfer dieser Nacht lebt noch (RM-DR-147). „Gezeigt“ erzeugt `RangerRecorded` und `RangerRevealed` (nur er). Vergiftet schläft er (`marked_for_death`).
- **Tests:** `test_waldlaeufer_doktor.gd`: Plan, Zählung mit Siegreichem Wolf und verwandeltem Wolfskind, jede Nacht, Gift, Ladeprüfung, nicht überspringbar, Leak.
- **Grenzen:** „Verfluchte“ des Dämonischen Wolfs folgen mit dieser Rolle.

### 4.18 `doktor`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Pflichtschritt jede Nacht (Priorität 50): genau zwei verschiedene andere Lebende (Stufe `targets`), Ergebnis gleiche aktuelle Fraktion; zwei Einzelsiegpersonen gelten als gleiches Team (RM-DR-145.1 = B), Trugbilderwolf mit wahrer Fraktion. „Gezeigt“ erzeugt `DoctorRecorded` und `DoctorRevealed` (nur er). Abbrechbar, entfällt mit weniger als zwei anderen Lebenden.
- **Tests:** `test_waldlaeufer_doktor.gd`: Teamregeln (Dorf, Wolf, Solo, Trugbild, Wolfskind vor/nach Verwandlung), ungültige Ziele, Abbruch, Ladeprüfung, Leak.
- **Grenzen:** Wechselwirkung mit Dämonischem Wolf, Seelentauscher und Rotkäppchen folgt mit diesen Rollen.

### 4.19 `wahnsinniger-kutscher`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Stirbt er durch Hinrichtung (LYNCH, auch Spielleiter-Hinrichtung), sterben seine nächsten lebenden Nachbarn im Sitzkreis mit (`COACHMAN_CRASH`, Quelle Kutscher, im Uhrzeigersinn zuerst); Spiegelung, Rudel und Korrektur-Tötung lösen nicht aus. Nachbarfolgen (Reaktion, Verwandlung, Siegprüfung) laufen normal.
- **Tests:** `test_seat_roles.gd`: nächste Lebende, Sitzfolge statt ID, Spielleiter-Hinrichtung, andere Todesarten, Spiegelung, Sensenträger-Nachbar, nur ein anderer Lebender.
- **Grenzen:** Schilde späterer Rollen (Rudelvater, Nekromant, Hades …) folgen mit diesen.

### 4.20 `nachtwaechter`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Bei jedem Tagesbeginn nach vollständiger Morgenauflösung: sitzt neben einem lebenden Nachtwächter (nächste Lebende) jemand mit Fraktion ungleich Dorf, entsteht genau ein öffentliches `AlarmBells` ohne Namen und Seite; Einzelheiten `AlarmBellsDetail` nur für den Spielleiter.
- **Tests:** `test_seat_roles.gd`: Wolf, Einzelsieg, nur Dorf, tote Plätze, toter Nachtwächter, zwei Nachtwächter und jeder Morgen, Save/Load.
- **Grenzen:** Dämonischer-Wolf-Fluch folgt mit dieser Rolle.

### 4.21 `dorfwache`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Der Rudelangriff tötet sie nicht: `KillPrevented` mit Quelle `dorfwache` (nur Spielleiter), zusammen mit Schutzengel und Waldhexenrettung genau ein Abfangen. Gift, Hinrichtung und Korrekturen töten sie. Die Waldhexe sieht sie als Opfer und darf (verbrauchend) heilen. Lehrling-Erbe wirkt sofort.
- **Tests:** `test_seat_roles.gd`: Rudel, Lynch, Gift, Heilung, Lehrling-Erbe.
- **Grenzen:** RM-DR-119.1/.2 (Giftwolf, Seuchenwolf, Rudelvater) betreffen Rollen, die noch fehlen; im heutigen Kern gibt es keinen anderen Wolfsangriff.

### 4.22 `besessener-wolf`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Wolfsfraktion, Rudel. Stirbt er mit Folgen, während unmittelbar vorher mindestens 5 Personen leben (er eingeschlossen), wird die Reaktion `possessed` eingereiht: eine andere lebende Person (auch ein Wolf) mitreißen (`POSSESSED_DRAG`) oder verzichten; Tag sofort, Nacht am Morgen; einmal je Leben.
- **Tests:** Lynch mit Wahl, Schwelle 5/4, Nachttod, Verzicht, Wiederbelebung.
- **Grenzen:** Schilde späterer Rollen folgen mit diesen.

### 4.23 `ritter`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Stirbt er durch den Rudelangriff, stirbt sofort der nächste Wolf (Abstand in Sitzen einschließlich toter Plätze, `KNIGHT_STRIKE`); bei Gleichstand Reaktion `knight` mit Pflichtwahl des Spielleiters unter den gleich nahen Wölfen; einmal je Leben.
- **Tests:** tote Plätze zählen, Gleichstand, Gift und Lynch lösen nicht aus, Wiederbelebung.
- **Grenzen:** RM-DR-136.2/.3 (Verfluchte, Fenrir) folgen mit diesen Rollen.

### 4.24 `faehrtenleser`
- **Belegt umgesetzt (Rollenaudit 2026-09-27):** Jede Nacht „jetzt nutzen?“ (Priorität 52) bis zur Nutzung, danach kein Schritt; Wiederbelebung setzt zurück. Richtung des nächsten Wolfs: `left` = Uhrzeigersinn aus Sicht der Person, `right`, `equal` bei Gleichstand; Abstand einschließlich toter Plätze. `TrackerRevealed` nur an ihn.
- **Tests:** links/rechts/gleich weit, tote Plätze, Verzicht und erneute Frage, keine Frage nach Nutzung, Wiederbelebung, Ladeprüfung.
- **Grenzen:** Gegenprüfung am Tablet, ob die Sitzansicht im Uhrzeigersinn läuft (RM-DR-146.1).

### 4.25 `blutwolf`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Wolfsfraktion, Rudel. Kein Stimmsystem: `VoteHints.hints` liefert dem Spielleiter „+1 je direkt benachbartem toten Platz“, solange er lebt (live berechnet).
- **Tests:** Hinweis 0/1/2, nur direkte Nachbarn, Wiederbelebung, toter Blutwolf.
- **Grenzen:** Anzeige des Hinweises in der Oberfläche folgt mit dem Spielablauf-UI.

### 4.26 `korrupter-richter`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Nachtschritt (Priorität 15): freiwillig eine lebende Person markieren (auch sich selbst). Bei Tagesbeginn wird die Markierte, wenn Richter und Ziel leben und frei sind, als Nominierung des Richters gespeichert (Tageslimit, Manipulator-Tod, Spiegelung wie sonst); öffentlich nur `JudgeNominationRecorded` ohne Richter, `JudgeNominated` für den Spielleiter; `VoteHints` +1. Markierung wird bei Nachtbeginn gelöscht (`judge_marks`).
- **Tests:** verdeckte Nominierung, Hinweis, Limits, Verzicht, Selbstmarkierung, Löschen, Manipulator, Spiegelwolf, tote Beteiligte, Save/Load.
- **Grenzen:** –

### 4.27 `waechter-am-tor`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Solange ein Wächter lebt, wird eine Wolfskind-Verwandlung durch Tod des Vorbilds und ein Lehrling-Erbe einer Wolfsrolle durch Tod des Meisters blockiert: die Person wird Dorfbewohner (frische Einsätze), `NewWolfBlocked` für den Spielleiter, `NewWolfBlockedNotice` privat. Spielleiterkorrekturen bleiben unberührt.
- **Tests:** Wolfskind, toter Wächter, Lehrling-Erbe mit Save/Load, Korrekturen.
- **Grenzen:** König Lykaon, Seelentauscher und der Fluch des Dämonischen Wolfs folgen mit diesen Rollen.

### 4.28 `spuerhund`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht (Priorität 68) freiwillig drei verschiedene andere Lebende oder Verzicht; ✓, wenn eine davon (wahre aktuelle Fraktion) Wolf oder Einzelsieg ist, sonst ✗ und `spuerhund:lost`. Danach wird er weiter aufgerufen (nur „Gezeigt“, ohne Information). Wiederbelebung setzt zurück. Ergebnis nur an ihn.
- **Tests:** ✓ bei Wolf, Einzelsieg, Trugbilderwolf; ✗ und Verlust, Aufruf ohne Fähigkeit, Wiederbelebung, Verzicht, ungültige Ziele, Ladeprüfung.
- **Grenzen:** Fluch des Dämonischen Wolfs folgt mit dieser Rolle.

### 4.29 `parasit`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Nachtschritt (Priorität 62): freiwillig einen anderen lebenden Wirt wählen, sonst bleibt der bisherige (`parasite_hosts`). Mit lebendem Wirt verhindert er jeden Tod außer Spielleiterkorrekturen (`KillPrevented`, Quelle `parasit`); stirbt der Wirt mit Folgen, stirbt er mit (`PARASITE_HOST`); Bindung endet mit dem Tod. Sieg `parasite_final_three` bei höchstens drei Lebenden, wenn er lebt; gleichzeitig mit anderen Siegen.
- **Tests:** Rudel, Lynch, Korrektur, Wirtstod, ohne Wirt, Wechsel, Behalten, Sieg bei drei Lebenden, Save/Load.
- **Grenzen:** Setup-Einschränkungen für Einzelsiegrollen sind vertagt (Decision Log).

### 4.30 `schattenhund`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Rudel; Schritt ganz am Anfang der Nacht (Priorität 1) „jetzt blockieren?“ bis zur Nutzung (je Leben). Ja: alle aktiven Dorf-Nachtschritte dieser Nacht entfallen (`blocked`), auch der Gebundenen-Schritt; Todesreaktionen und passive Fähigkeiten wirken weiter.
- **Tests:** Blockade, Rudel unberührt, einmalig, nur eine Nacht, Verzicht.
- **Grenzen:** –

### 4.31 `albtraumwolf`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Rudel; jede Nacht (Priorität 2) freiwillig eine andere lebende Person; deren aktiver Dorf-Nachtschritt dieser Nacht entfällt (`blocked`); Gebundene erhalten dann keine Information.
- **Tests:** blockiertes Orakel, anderes Orakel handelt.
- **Grenzen:** –

### 4.32 `giftwolf`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Rudel; eigener Schritt nach dem Rudel (Priorität 27), freiwillig eine andere lebende Person, zwei Ladungen je Leben. Das Ziel erhält sofort `WolfPoisonNotice` und stirbt in der Morgenauflösung nach Nacht N+2 (`WOLF_POISON`), unaufhaltbar durch Schutz; ein früherer Tod beendet das Gift.
- **Tests:** privater Hinweis, Tod nach Nacht 3 trotz Schutz, eine pro Nacht, zwei Ladungen, Ladbarkeit.
- **Grenzen:** Parasit-Schild und Rudelvater-Überleben wirken nach ihren eigenen Regeln.

### 4.33 `rudelvater`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Überlebt einmal je Leben einen Tod, der weder Rudelangriff noch Lynch noch Korrektur ist (`KillPrevented`, Quelle `rudelvater`). Nach seinem Lynch folgt in der nächsten Nacht direkt nach dem Rudel ein zweiter Rudelschritt (`pack2`), dessen Opfer am Morgen stirbt und Schutzengel, Waldhexenrettung und Dorfwache durchdringt.
- **Tests:** Überleben von Gift, Korrektur tötet, zweiter Rudelschritt, Durchdringung, nur eine Nacht; Gegenprobe ohne Durchdringung wird rot.
- **Grenzen:** –

### 4.34 `seuchenwolf`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Nach seinem Tod (mit Folgen) durchdringt der nächste tatsächliche Rudelangriff Schutz und verbraucht die Wirkung; Nächte ohne Rudelopfer verbrauchen nichts; keine Stapelung.
- **Tests:** Nacht ohne Opfer, Durchdringung, danach wieder Schutz.
- **Grenzen:** –

### 4.35 `fenrir`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Stufe `growth` +1 je Morgen, den er lebend erreicht; ab Stufe 3 überlebt er einmal je Leben jeden Tod außer Korrektur (auch Lynch, Ritter). Wiederbelebung und Rollenwechsel setzen Stufe und Schutz zurück.
- **Tests:** Wachstum, Überleben, zweite Hinrichtung, Stufe 1 stirbt, Wiederbelebung.
- **Grenzen:** –

### 4.36 `cerberus`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Köpfe +1 je Morgen (max. 3). Hinrichtung mit 3 Köpfen verlangt `cerberus_defend` (auch bei Spielleiter-Hinrichtung); Ja: überlebt, Köpfe 0, Hinrichtung gilt als erfolgt und zählt.
- **Tests:** Köpfe, Pflichtentscheidung, Abwehr, Annahme, Obergrenze.
- **Grenzen:** Eingabe „abwehren?“ in der Oberfläche folgt mit dem Spielablauf-UI.

### 4.37 `henker`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** `executions_count` zählt jede bestätigte Hinrichtung der Partie. Ab 3 markiert er nachts (Priorität 78) freiwillig eine andere Person; bei der Hinrichtung des Folgetags stirbt sie zusätzlich (`HANGMAN_EXTRA`), wenn er dann lebt; sonst verfällt die Markierung bei Nachtbeginn.
- **Tests:** Aktivierung, Zusatztod, kein Selbstmörder-Sieg, Verfall, toter Henker.
- **Grenzen:** –

### 4.38 `traumdeuter`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht (Priorität 70) wählt der Spielleiter genau drei andere Lebende; die Bestätigung ist erst mit mindestens einer Person möglich, die als Wolf zählt (`no_wolf_selected`); zwei oder drei Wölfe sind zulässig. Der Traumdeuter erhält nur die drei Namen („mindestens ein Wolf“), der Spielleiter-Datensatz nennt die Wölfe. Ohne drei andere Lebende mit einem Wolf entfällt der Schritt.
- **Tests:** Auswahlregeln, Anzeige ohne Anzahl, Trugbilderwolf zählt als Wolf, Entfall, Save/Load offener Stufen.
- **Grenzen:** Die Erinnerung „mindestens ein Wolf“ ist eine Oberflächenaufgabe.

### 4.39 `kopfgeldjaeger`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jeder Lynch-Tod (`LYNCH`) einer Person, die als Wolf zählt, gibt jedem lebenden Kopfgeldjäger eine Liste (`bounty_credits`). Je Nacht mit Guthaben ein Schritt (Priorität 32) wie beim Traumdeuter. Blockiert bleibt das Guthaben; ohne drei andere Lebende mit Wolf verfällt eine Liste mit privatem Hinweis (`BountyExpired`). Ein Rollenwechsel löscht das Guthaben.
- **Tests:** Zähler, Nicht-Wolf-Lynch, Korrektur-Tod, toter Kopfgeldjäger, Blockade, Verfall.
- **Grenzen:** Mehrere Listen aus einem Tag (nur per Korrektur möglich) werden in aufeinanderfolgenden Nächten gezeigt.

### 4.40 `koenig`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Einmal je Leben (`koenig:learn`), in der ersten Nacht mit strikt mehr Toten als Lebenden (Plan und Schrittbeginn); der Spielleiter wählt eine andere lebende Person der aktuellen Fraktion Dorf; der König erfährt sie mit wahrer Rolle.
- **Tests:** Gleichstand, Auswahl nur Dorf, wahre Rolle, einmal, Wiederbelebung setzt zurück.
- **Grenzen:** –

### 4.41 `kriegerin-des-lichts`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Einmal je Leben (`kriegerin-des-lichts:attack`), Priorität 60, freiwillig; Ziel eine andere Lebende; das Ergebnis (wahre Wolfszählung) nur an sie. Kein Wolf: Todesmarkierung, sie stirbt in der Morgenauflösung (`WARRIOR_WRONG`) und wacht nicht mehr auf. Ein Wolf überlebt.
- **Tests:** Treffer, Irrtum mit Tod am Morgen, Verzicht verbraucht nichts, einmal je Leben, Save/Load.
- **Grenzen:** –

### 4.42 `blutpriester`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Einmal je Leben (`blutpriester:sacrifice`), Priorität 82, freiwillig: Opfer eine andere Lebende, dann nennt der Spielleiter 0–3 lebende Wölfe (Stufe `reveal`), nur an ihn. Das Opfer erhält eine Todesmarkierung und stirbt am Morgen (`BLOOD_SACRIFICE`); Schutzengel wirkt nicht, Rudelvater und andere Schilde schon.
- **Tests:** Opferregeln, Aufdeckung nur Wölfe, Schutzengel wirkungslos, Rudelvater überlebt, Opfer wacht nicht mehr auf.
- **Grenzen:** –

### 4.43 `amalia`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Befehl `AmaliaSacrifice` am Tag (vor Tagesende, ohne offenen Prompt) bei mindestens drei lebenden Wolfspersonen: öffentliches Ereignis `AmaliaAnswered` mit der Ja/Nein-Antwort des Spielleiters, danach sofort Tod `AMALIA_SACRIFICE` mit allen Folgen.
- **Tests:** Antwort Pflicht, nur Amalia, nur lebend, nur am Tag, Schwelle.
- **Grenzen:** Die Frage selbst wird mündlich gestellt und nicht gespeichert.

### 4.44 `detektiv`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Todesfolge: Stirbt mit Folgen eine Person, die als Wolf zählt, während ein Detektiv lebt, und lebt nach Verwandlung und Erbe ein anderer Wolf, wird die Richtung vom Platz des Toten zum nächsten lebenden Wolf öffentlich (`DetectiveHint`: links/rechts/gleich weit). Nachts vorgemerkt (`detective_hints`), in der Morgenauflösung verkündet. Ein Hinweis je Tod.
- **Tests:** Richtung, Gleichstand, Bedingungen, Korrektur ohne Folgen, Nachttod, verwandeltes Wolfskind.
- **Grenzen:** Öffentliche Ansage und Richtungsdarstellung am Tablet folgen mit der Oberfläche.

### 4.45 `die-ewigen`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Gemeinsamer Schritt `die-ewigen` in jeder Nacht mit lebenden Ewigen (Priorität 48): eine lebende Person außerhalb der Ewigen prüfen, nur Ja (Einzelsieg) oder Nein an jede wache Ewige. Ja-Personen stehen in `eternal_finds`; gewinnt eine davon einen Einzelsieg, stehen alle Ewigen (lebend oder tot) als Mitsieger in `beneficiary_ids`. Schattenhund und Albtraumwolf blockieren.
- **Tests:** Prüfung, Nein ohne Speicherung, Mitsieg nur mit geprüfter Person, Blockade.
- **Grenzen:** –

### 4.46 `der-weise`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Rettung (`der-weise:survive`, einmal je Leben) nur, wenn der Rudelangriff ihn sonst töten würde; Durchdringung tötet. Sein Lynch-Tod verlangt `sage_curse` 0–3 bei `DecideExecution` und Spielleiter-Hinrichtung; danach ruhen in so vielen folgenden Nächten und Tagen alle Fähigkeiten aller Dorfpersonen (`GuardRoles.silenced`): Nacht- und Tagesschritte (`cursed`), passive Wirkungen, Todesreaktionen, Wolfskind-Verwandlung und Lehrling-Erbe; ausgelöste Wirkungen entfallen endgültig. Ein ruhender Weiser löst keinen Fluch aus.
- **Tests:** Rettung nur wenn nötig, Durchdringung, Fluch mit Orakel/Dorfwache/Nachtwächter/Sensenträger/Amalia, Verwandlung und Erbe entfallen, 0 = kein Fluch, ruhender Weiser.
- **Grenzen:** Bindungen von Wolfskind und Lehrling bleiben an das tote Vorbild bzw. den toten Meister geknüpft; eine spätere Wiederbelebung und ein erneuter Tod lösen sie aus.

### 4.47 `maertyrerin`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Schritt am Ende der Nacht (Priorität 90), nur wenn das erste Rudelopfer ohne sie tatsächlich stürbe (`martyr_victim`: kein Schutz, keine Markierung, kein persönlicher Schild); nicht blockierbar, aber vom Fluch betroffen. Opfert sie sich, stirbt sie am Morgen (`MARTYR_SACRIFICE`) statt des Opfers, auch gegen Durchdringung.
- **Tests:** Verzicht, Opfer, geschütztes Opfer ohne Frage, Blockade wirkungslos, Save/Load.
- **Grenzen:** Die Frage liegt technisch als letzter Nachtschritt vor der Morgenauflösung.

### 4.48 `schutzgeist`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Tote Schutzgeister handeln in der ersten Nacht nach ihrem Tod (Priorität 56, Ausnahme zu G-PH-2): Pflichtwahl einer lebenden Person. Das Schild wirkt ab der folgenden Nacht bis zum nächsten Rudelangriff und bricht bei Durchdringung. Ein gewählter Wolf wird am Morgen öffentlich ohne Namen gemeldet (`GhostWolfAlert`).
- **Tests:** Schritt nur in der ersten Nacht, Wirkung ab Folgenacht, Verbrauch, öffentliche Meldung ohne Namen.
- **Grenzen:** –

### 4.49 `dorfschmied`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Ab Nacht 6 der Partie (Priorität 17) „jetzt geben?“ bis zur Vergabe (einmal je Leben) an eine andere lebende Person. Die Waffe wehrt den nächsten Rudelangriff auf den Träger ab, auch einen durchdringenden, und reiht eine Pflichtreaktion ein, in der der Spielleiter den sterbenden Wolf wählt (`SMITH_WEAPON`). Gaben bleiben nach dem Tod des Gebers und wirken im Fluch.
- **Tests:** Nacht 6, Vergabe, Durchdringung, Tod des Schmieds, Reihenfolge Waffe → Schild → Weiser.
- **Grenzen:** Ein Zufallsknopf für die Wolfswahl (RM-DR-015.2) folgt mit der Oberfläche.

### 4.50 `verdammniswaechter`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht nach dem Rudel (Priorität 23), wenn ein erstes Rudelopfer lebt, das nicht er selbst ist: die App zieht einmal je Nacht über den Seed ein Angebot aus lebenden Nicht-Wölfen außer Opfer und ihm (`doom_offers`); er wählt Opfer oder Angebot. Die gewählte Person wird zum Rudelopfer; alle Regeln des Rudelangriffs gelten.
- **Tests:** Angebot, gleiche Ziehung nach Abbruch, Umlenkung, Schutz bleibt, Wächter als Opfer.
- **Grenzen:** Der Rollentext „umgeht alle Schutzfähigkeiten“ gilt nach S-07 nicht.

### 4.51 `loki`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Nur in Nacht 1 (Priorität 4, nach den Blockern), freiwillig: zwei verschiedene Lebende (er selbst erlaubt), dann Liebende oder Rivalen (`loki_pairs`). Stirbt ein Liebender mit Todesfolgen, stirbt der andere sofort (`LOVER_HEARTBREAK`), außer er ist in dieser Nacht ohnehin todesmarkiert; jeder Tod beendet das Paar. Rivalen sind nur Marker.
- **Tests:** Nacht 1, Selbstwahl, Liebeskummer, beendetes Paar nach Wiederbelebung, Rivalen, Fluch.
- **Grenzen:** –

### 4.52 `schwarze-witwe`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Wolf im Rudel mit eigenem Schritt (Priorität 28): Pflichtwahl einer anderen Lebenden; gehört sie zu einem lebenden, nicht beendeten Loki-Paar, erhalten Ziel und Partner eine Todesmarkierung und sterben am Morgen (`BLACK_WIDOW`).
- **Tests:** Paar, Rivalen, kein Paar, markierte Person wacht nicht auf, Partner stirbt durch die Witwe.
- **Grenzen:** RM-DR-113.2 (Zeitwächter) folgt mit dem Zeitwächter; die Setup-Pflicht „Loki im Spiel“ folgt mit der Setup-Prüfung.

### 4.53 `rotkaeppchen`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht (Priorität 74) Pflichtfrage an eine andere Lebende; gewährt sie Zuflucht, ersetzt die neue Todeskette die alte (`red_chains`) und sie erhält einen Apfel für die folgende Nacht (`apples`). Der Apfel plant den ersten Jede-Nacht-Schritt der Person (`RoleCatalog.APPLE_ROLES`) direkt ein zweites Mal ein (`apple_steps`); beim Schutzengel entsteht ein zusätzlicher Schutz (`Protection.extra`). Kettentod `RED_CHAIN`.
- **Tests:** Kette, Ablehnung, Kettentod, Apfel beim Orakel, Schutzengel doppelt, Richter wirkungslos, Verfall.
- **Grenzen:** Der Apfel verlängert den gespeicherten Nachtplan um einen Schritt; das ist die einzige Planänderung während der Nacht.

### 4.54 `schattenwanderer`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Wolf im Rudel mit eigenem Schritt (Priorität 26), jede Nacht bis zur Nutzung (`schattenwanderer:link`): eine andere Lebende oder „noch nicht“. Stirbt eine Seite tatsächlich (nach allen Schutzwirkungen und Schilden, nicht bei Korrektur), stirbt stattdessen die andere mit derselben Ursache und Quelle; die Verknüpfung ist verbraucht.
- **Tests:** Schutz verhindert Umlenkung, Rudelangriff umgelenkt, Lynch umgelenkt und gezählt, Korrektur nicht.
- **Grenzen:** Ein umgelenkter Lynch des Weisen löst keinen Fluch aus.

### 4.55 `daemonischer-wolf`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Todesreaktion bei jedem Tod mit Todesfolgen (einmal je Leben): eine andere lebende Person verfluchen oder verzichten. `Player.cursed` lässt `InformationRules.determine_role` „werwolf“ ergeben (nur Rollenauskünfte wie das Orakel); Zählungen, Prüfungen und Siege bleiben wahr. Ein Rollenwechsel löscht den Fluch, eine Wiederbelebung nicht.
- **Tests:** Fluch, Orakel-Erscheinung, Waldläufer wahr, Wiederbelebung, Rollenwechsel, Verzicht, ohne Todesfolgen.
- **Grenzen:** –

### 4.56 `koenig-lykaon`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht bis zur Nutzung (Priorität 24), wenn ein anderer Wolf lebt: Stufe „ally“ (anderer lebender Wolf, höchstens dreimal verschieben, bei der vierten Gelegenheit Pflicht), dann eine lebende Dorfperson → Trugbilderwolf mit alter Rolle als Scheinrolle (frische Einsätze), private Mitteilung; Rudel ab der Folgenacht. Wächter am Tor macht sie zum Dorfbewohner. Nächte ohne Verbündeten zählen nicht.
- **Tests:** Verwandlung, Scheinrolle, Rudel ab Folgenacht, Ziele nur Dorf, Wächter, drei Verzichte, Nacht ohne Verbündeten.
- **Grenzen:** –

### 4.57 `seelentauscher`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht bis zur Nutzung (Priorität 80): 0 oder zwei verschiedene Personen, lebend oder tot, er selbst erlaubt. Beide erhalten die Rolle der anderen wie beim Lehrling-Erbe (frische Einsätze, Wolfskind ohne Vorbild, Lehrlingsbindung endet, Scheinrolle des Trugbilderwolfs wandert mit); lebende Betroffene erfahren ihre Rolle privat. Würde jemand (auch tot) neu Wolf, macht ein lebender Wächter am Tor ihn zum Dorfbewohner.
- **Tests:** Tausch mit frischen Rollen, private Mitteilung, Tote, Selbsttausch, Wächter bei Lebenden und Toten.
- **Grenzen:** Rollenschritte der Getauschten in derselben Nacht entfallen (Nachtplan-Schnappschuss).

### 4.58 `kutscher`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Ab einer Nacht mit mindestens 10 Toten (Priorität 38), freiwillig, einmal je Leben: drei Tote wählen, dann einen davon als Wolf. Alle drei leben sofort wieder mit frischen Einsätzen (`RoleTransition.revive`), zwei behalten ihre Rolle, der gewählte wird Werwolf (Wächter am Tor: Dorfbewohner). Private Mitteilung, Handeln ab der Folgenacht, öffentliches `PlayerRevived` am Morgen.
- **Tests:** Schwelle, nur Tote, genau drei, Wolfswahl, Rudel ab Folgenacht, Wächter, Verzicht.
- **Grenzen:** Totenkarten-Bedingungen folgen mit dem Assistenten (W-01).

### 4.59 `dr-victor-frankenstein`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht bis zur Nutzung (Priorität 36), freiwillig: ein Toter, dann eine Rolle aus `frankenstein_options` (Rollen, die gerade niemand hat, Dorfbewohner immer, keine Wolfsrolle, keine Pflicht-Scheinrolle). Die Person lebt sofort wieder mit dieser Rolle und frischen Einsätzen, erfährt sie privat, handelt ab der Folgenacht; am Morgen öffentlich sichtbar.
- **Tests:** Nur Tote, Rollenangebot, private Mitteilung, Folgenacht, einmal je Leben, Save/Load der Rollenwahl.
- **Grenzen:** Totenkarten-Bedingung RM-DR-141.4 folgt mit dem Assistenten (W-01).

### 4.60 `rattenfaenger`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht (Priorität 42) Pflichtwahl von 1 oder 2 anderen lebenden, von ihm noch unverzauberten Personen (`charms`, dauerhaft, auch nach Wiederbelebung). Siegkandidat bei jeder Siegprüfung, wenn er lebt und alle anderen Lebenden verzaubert sind.
- **Tests:** Auswahl, Verzauberung auch des Wolfs, Sieg nach Lynch der Letzten, toter Rattenfänger, Save/Load.
- **Grenzen:** –

### 4.61 `pestbringerin`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Jede Nacht (Priorität 72) Pflichtwahl einer anderen gesunden Lebenden (`infected`, gemeinsam). Zu Beginn jeder Morgenauflösung steckt jede lebende Infizierte einen per Seed gezogenen nächsten lebenden Nachbarn an (`PlagueSpread`). Sieg lebend bei Totalinfektion der anderen.
- **Tests:** Infektion, Ausbreitung auf Nachbarn, Seed-Reproduzierbarkeit, Sieg.
- **Grenzen:** Die Ausbreitung läuft auch ohne lebende Pestbringerin weiter (ohne Wirkung).

### 4.62 `prophet-des-untergangs`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Nacht 1: Pflichtmarkierung von drei anderen Lebenden (`prophet_marks`). Sind alle drei tot (jede Ursache), dauerhaft freigeschaltet (`prophet_unlocked`, auch nach Wiederbelebung eines Markierten); dann jede Nacht freiwillig eine andere Person töten (Todesmarkierung, `PROPHET_KILL` am Morgen, Rudelschutz wirkungslos). Lebt er freigeschaltet und kein Wolf, ersetzt sein Sieg den Dorfsieg.
- **Tests:** Markieren, Freischalten, dauerhaft, Tötung trotz Schutzengel, Sieg statt Dorf.
- **Grenzen:** –

### 4.63 `todesprediger`
- **Belegt umgesetzt (Rollenaudit 2026-09-28):** Nur Nacht 1 (Priorität 66): geheime Vorhersage `{kind: night|day, number}` einer künftigen Phase (Tag N nach Nacht N; laufende Nacht nicht). Stirbt er mit Todesfolgen genau in dieser Phase (Morgentode zählen zur Nacht), steht er in `preacher_wins` und wird fortan vorgeschlagen.
- **Tests:** Ungültige Vorhersagen, geheim, Treffer am Tag, falsche Phase.
- **Grenzen:** –

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
