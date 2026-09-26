# Grimmhain · Godot-Projekt

Phase 1 des Masterplans (`../GRIMMHAIN-REVOLUTION-MASTERPLAN.md`): headless, deterministischer Regelkern für Dorf gegen Werwölfe. Umfang nach `../docs/specs/vertical-slice/implementation-boundary.md` Abschnitt A, ergänzt um die Grundlagen B-06, B-11 (ohne `ReorderSeats`, `ConfirmRoleShown`, `BeginDay`) und DR-14: Regelschritte, Prompt-Abbruch, Spielleiterkorrektur, persistente Reaktionswarteschlange, vorläufige und verbindliche Siegprüfung. Keine UI, keine Szenen, keine Assets. Rollen: `dorfbewohner`, `werwolf` und die Vertical-Slice-Rollen `sensentraeger`, `schutzengel` und `waldhexe` (siehe „Rollen“).

## Engine-Version (gepinnt)

| Feld | Wert |
|---|---|
| Version | **Godot 4.7.2-stable**, offizieller Linux-x86_64-Build `4.7.2.stable.official.ed1daf0bf` |
| Prüfsumme | SHA-512 der ZIP-Datei in `tools/install_godot.sh` (aus der offiziellen `SHA512-SUMS.txt`) |
| Pin | `tools/godot-version.txt` |
| Sprache | GDScript, statisch typisiert; `untyped_declaration` ist in `project.godot` als **Fehler** eingestellt |
| Renderer | Compatibility (`gl_compatibility`), für den Kern ohne Bedeutung |
| Testframework | eigener Minimalrunner (`tests/run_tests.gd`), keine Fremdabhängigkeit |

Ein Versionswechsel erfolgt nur an einem Stop/Go-Punkt: `tools/godot-version.txt` und die Prüfsumme in `tools/install_godot.sh` gemeinsam ändern.

## Tests ausführen

Aus dem Repository-Wurzelordner:

```bash
godot/tests/run_all.sh                     # alle Tests
godot/tests/run_all.sh --filter=replay     # nur Testdateien, deren Name "replay" enthält
godot/tests/run_all.sh --filter=reactions  # z. B. nur die Reaktionswarteschlange
GODOT_BIN=/pfad/zu/godot godot/tests/run_all.sh   # eigene Godot-Binärdatei verwenden
```

`run_all.sh` lädt bei Bedarf die gepinnte Version nach `~/.local/godot` (`tools/install_godot.sh`, prüft SHA-512), importiert das Projekt headless und startet den Runner. Exit-Code 0 = grün. Jeder `SCRIPT ERROR`, Parse-Fehler oder nicht ladbare Testdatei macht den Lauf rot, auch wenn der Runner ihn nicht abfangen kann.

Direkt mit Godot (z. B. unter Windows):

```bash
godot --headless --path godot --import
godot --headless --path godot -s res://tests/run_tests.gd
```

CI: `.github/workflows/godot-core-tests.yml` führt `godot/tests/run_all.sh` bei Änderungen unter `godot/` aus.

### Testabdeckung

| Testdatei | Prüft | Spezifikation |
|---|---|---|
| `tests/scenarios/as-c01-wolf-parity.json` | Wolfsparität erzeugt Kandidaten, Phase bleibt bis zur Entscheidung | AS-C01 |
| `tests/scenarios/as-c02-no-early-parity.json` | keine vorzeitige Parität | AS-C02 |
| `tests/scenarios/as-c03-last-wolf-dies.json` | Tod des letzten Wolfs, `ConfirmWin`, danach alles abgelehnt | AS-C03 |
| `tests/scenarios/as-c04-confirm-reject-win.json` | Ablehnung mit Grund, kein erneutes Angebot ohne neuen Tod | AS-C04 |
| `tests/scenarios/as-c10-death-record.json` | vollständiger Todesdatensatz, offener Prompt blockiert `EndNight` | AS-C10, A-15 |
| `tests/scenarios/as-c11-no-digital-vote.json` | Nominierung gespeichert, kein Stimmfeld in Zustand und Ereignissen | AS-C11 |
| `tests/scenarios/as-c12-no-execution.json` | „keine Hinrichtung“, danach `EndDay` | AS-C12 |
| `tests/scenarios/dr-03-nomination-rules.json` | pro Tag, nur Lebende, Hinrichtung nur nach Nominierung | DR-03 |
| `tests/unit/test_replay.gd` | gleicher Seed → bytegleiche Eventliste und Endzustand; anderer Seed gespeichert | AS-C05, AS-C06 |
| `tests/unit/test_save_load.gd` | Save/Load in Nacht 2 mit identischem fachlichem Hash, offener Prompt und RNG-Position überleben | AS-C07 |
| `tests/unit/test_corrupt_save.gd` | abgeschnitten, Byte geändert, falsches Format/Schema/Regelversion, Hash- und Replay-Widerspruch | AS-C08 |
| `tests/unit/test_player_identity.gd` | Personen-ID getrennt vom Sitz, getrennte Rollenfelder | AS-C09 (Kernanteil), G-ID-2 |
| `tests/unit/test_command_validation.gd` | Setup-Prüfungen, Phasenreihenfolge, abgelehnte Befehle ändern nichts | A-13, A-15 |
| `tests/unit/test_player_count_range.gd` | jede Personenzahl 6–24 nur mit Dorfbewohnern und Werwölfen (16, 20, 24 ausdrücklich, manuell und zufällig), keine Rollenobergrenze, 5 und 25 abgelehnt, mindestens ein Werwolf und ein Dorfbewohner | DECISION-LOG „6 bis 24 Personen“ |
| `tests/unit/test_seeded_rng.gd` | Seed, Ziehposition, Wiederaufnahme mitten in der Folge | A-18 |
| `tests/unit/test_steps.gd` | `BeginStep` nur für den erwarteten Schritt, `SkipStep` des Rudelschritts mit Grund, `CancelPrompt` ohne Teilwirkung, Pflichtschritt nicht still übersprungen, Save/Load, Replay | AS-A02 (Kernanteil), B-11 |
| `tests/unit/test_schutzengel.gd` | Produktionsrolle, Schritt vor dem Rudel, Pflichtauswahl ohne `SkipStep`, kein Selbstschutz, Schutz nur gegen Rudelangriff derselben Nacht, `KillPrevented` ohne Tod/Reaktion/Siegstatus, Schutzengel stirbt nach Bestätigung, zwei Schutzengel, `CancelPrompt`, Rudelschritt weiter überspringbar, Schutzkorrekturen mit Save/Load und Replay, Save/Load an vier Punkten, Replay, Leak-Test | AS-R01–AS-R04, AS-R32, AS-R42, AS-R43, DR-05 |
| `tests/unit/test_waldhexe.gd` | Produktionsrolle, Reihenfolge Schutzengel → Rudel → Waldhexe, mehrere Waldhexen nach ID, entfallende Schritte (tot, keine Entscheidung, beide Tränke verbraucht), Opfer ohne Rolle vor der Entscheidung, Rollenoffenlegung nach Rettung, Heil- und Gifttrank einzeln, gemeinsam und auf derselben Person, Gift auf sich selbst, Gift auf Sensenträger mit Reaktion am Morgen und fester Ereignisreihenfolge, Schutz verhindert Gift nicht, Schutz und Rettung auf demselben Opfer, Einmal-Nutzung, Wiederbelebung, `CancelPrompt` und Save/Load auf jeder Stufe, Save/Load nach Rettung, Gifttod und jeder Korrekturart, Replay, manipulierte Antworten, kein `SkipStep`, Trank- und Rettungskorrekturen (Rettung nur auf das aktuelle Rudelopfer), tatsächliche Rolle trotz `appears_as`, Rollenwechsel in der Nacht (Schritt entfällt, kein neuer Schritt), widersprüchliche Prompt-Stufen beim Laden, Leak-Test | AS-R05–AS-R08, AS-R39, AS-R32, AS-R37, AS-A01, AS-A02, DR-06 |
| `tests/unit/test_sensentraeger.gd` | Produktionsrolle: Rudel-, Hinrichtungs-, GM- und Nachttod, Verzicht, lebende Ziele zum Antwortzeitpunkt, einmal pro Person, Kette zweier Sensenträger, DR-14, Wiederbelebung, totes Rudelopfer, Save/Load, Replay, keine Geheimnisse in öffentlichen Ereignissen | AS-R15, AS-R16, AS-R17, AS-R37, AS-R40, AS-R41, AS-G01, AS-G02 |
| `tests/unit/test_reactions.gd` | Reaktion eingereiht, blockiert andere Befehle, nicht überspringbar/abbrechbar, Verzicht, Fluch-Tod, Kettenreaktion und stabile Reihenfolge, Nachttod reagiert am Morgen, Save/Load mit offener Reaktion, Replay | AS-A03, B-06, DR-09 |
| `tests/unit/test_win_status.gd` | vorläufiger Status nach jedem Tod, verbindliche Prüfung erst nach allen Reaktionen, `ConfirmWin` bei offener Reaktion abgelehnt, niemand lebt ohne automatischen Gewinner, Save/Load, Replay | AS-R35, AS-R36, DR-02, DR-14 |
| `tests/unit/test_gm_correction.gd` | Bestätigung und Begründung Pflicht, alter/neuer Wert, Tod mit und ohne Folgen, Wiederbelebung, Rollenkorrektur, kein Undo, Save/Load, Replay | AS-G01, AS-G02, G-GM-1 |
| `tests/unit/test_gm_execute.gd` | `execute` ohne Nominierung, Ursache `LYNCH`, Übersteuerung protokolliert, Validierung, Reaktion und DR-14, Save/Load, Replay | AS-G03, AS-N05, DR-03 |
| `tests/unit/test_gm_role_field.gd` | nur `appears_as` korrigierbar, alter/neuer Wert, unbekannte Felder und ungültige Werte abgelehnt, Save/Load, Replay | AS-G05, DR-08 |
| `tests/unit/test_gm_open_prompt.gd` | `kill`, `revive`, `set_role`, `set_role_field`, `execute` brechen offenen Prompt ab; keine toten Ziele; kein Kandidat neben offenem Prompt; `declare_winner` nur ohne Prompt; Save/Load, Replay | AS-G04, G-GM-3 |
| `tests/unit/test_win_finalize_guard.gd` | kein Siegkandidat bei offenem Prompt oder offener Reaktion | DR-14, G-GM-3 |
| `tests/unit/test_save_versions.gd` | Spielstände mit Schema 1 bis 4 werden mit klarer Meldung abgelehnt | Versionierung |
| `tests/unit/test_core_purity.gd` | `core/` ohne Nodes, Szenen, Dateisystem, Zeit, Audio, Netzwerk, globalen Zufall | Masterplan §4 Regel 1 |

### Szenarioformat (`tests/scenarios/*.json`)

```json
{
  "id": "AS-C01", "title": "…", "spec": "docs/…",
  "steps": [
    { "cmd": { "type": "StartGame", "payload": { … } } },
    { "cmd": { "type": "EndDay", "payload": {} }, "reject": "win_candidate_open",
      "expect": { "phase": "DAY" } }
  ]
}
```

`reject` erwartet eine Ablehnung mit genau diesem Fehlergrund und prüft, dass Zustand und Ereignisse unverändert bleiben. `expect` prüft nach dem Schritt: `phase`, `night_number`, `day_number`, `alive`, `win_candidate`, `winner`, `nominations` (Teilmengenvergleich), `events` (Ereignisse dieses Schritts, Teilmenge), `no_event_types`, `forbidden_key_substrings` (über Zustand und alle bisherigen Ereignisse).

## Dateiverantwortung

| Datei | Verantwortung |
|---|---|
| `project.godot` | Projekteinstellungen, Typisierungswarnungen als Fehler |
| `tools/godot-version.txt`, `tools/install_godot.sh` | gepinnte Engine-Version, Download mit Prüfsumme |
| **core/util/** | |
| `canonical_json.gd` | kanonisches JSON (sortiert, Ganzzahlen normalisiert), SHA-256 |
| `dict_read.gd` | typsichere Lesezugriffe auf JSON-/Nutzdaten |
| `seeded_rng.gd` | einzige Zufallsquelle; Seed, Zustand, Ziehposition serialisierbar |
| **core/model/** | |
| `game_state.gd` | vollständiger fachlicher Zustand inkl. Nachtplan, Reaktionen und vorläufigem Siegstatus, `schema_version`, `rules_version`, fachlicher Hash |
| `player.gd` | Person mit stabiler ID; Rolle, Fraktion, `counts_as_wolf`, `appears_as` getrennt; begrenzte Einsätze `ability_uses`; kein Sitzfeld |
| `kill_event.gd` | Todesdatensatz: Ursache (`NIGHT_KILL`, `LYNCH`, `HUNTER_SHOT`, `GM_CORRECTION`, `WITCH_POISON`), Quelle, Ziel, Zeitpunkt, Abfangstatus |
| `reaction.gd` | offene Todesreaktion (Besitzer, auslösender Tod), Teil des Spielstands |
| `protection.gd` | bestätigter Schutz: Schutzengel, geschützte Person, Nacht |
| `witch_action.gd` | bestätigte Waldhexen-Entscheidung einer Nacht: Waldhexe, Nacht, gesehenes Opfer, Heiltrank verbraucht, gerettete Person, Gifttrank verbraucht, Giftziel |
| `nomination.gd` | Nominierende, Nominierte, Tag; kein Stimmfeld |
| `pending_prompt.gd` | offene Eingabe als Teil des Spielstands (Rudelwahl, Schutzengel, Reaktion, Waldhexenkette) mit Schritt-ID, Abbrechbarkeit, Stufe `stage` und Teilantworten `partial` |
| `win_candidate.gd` | Siegkandidat mit Status offen/bestätigt/abgelehnt |
| `phase.gd`, `faction.gd`, `visibility.gd` | Konstanten für Phasen, Tages-Unterzustände, Fraktionen, Sichtbarkeit |
| **core/commands/** `command.gd` | Befehlstypen, Fabrikfunktionen, JSON-Rundreise |
| **core/events/** `game_event.gd` | Ereignistypen mit Index, Befehlsindex, Sichtbarkeit, Daten |
| **core/rules/** | |
| `rules_engine.gd` | `apply` (validieren → auf Kopie ausführen → Ereignisse), `replay` |
| `phase_machine.gd` | zulässige Befehle je Phase, Phasenwechsel mit Ereignis |
| `kill_pipeline.gd` | Tötungs-Pipeline mit Abfangstufe Schutzengel und Waldhexenrettung (nur Rudelangriff, ein `KillPrevented` mit allen Quellen); reiht Todesreaktionen ein und berechnet den vorläufigen Siegstatus |
| `protections.gd` | Schutz der laufenden Nacht lesen, setzen, entfernen, Schutzengel eines Ziels |
| `step_queue.gd` | Nachtplan (persönliche Rollenschritte vor und nach dem Rudel), Schrittstatus, erwarteter nächster Schritt, Beginn, Überspringen, entfallende Schritte, Prompt-Abbruch |
| `witch_step.gd` | Waldhexe: Trankstatus, heilbares Rudelopfer, mehrstufige Prompt-Kette mit Prüfung je Stufe, atomare Bestätigung, Retter eines Ziels |
| `gm_corrections.gd` | Spielleiterkorrektur: Prüfung, Ausführung, Protokoll mit altem und neuem Wert |
| `win_rules.gd` | einzige Siegprüfung: vorläufig nach jedem Tod, verbindlich nach allen Reaktionen; erzeugt nur Kandidaten |
| `role_catalog.gd` | Stammdaten `dorfbewohner`, `werwolf`, `sensentraeger`, `schutzengel`, `waldhexe`; Lage des Nachtschritts `night_step` (`before_pack`, `after_pack`), optionale Obergrenze `max_copies`, Todesreaktion `death_reaction` |
| `rule_context.gd` | Zustandskopie und Ereignissammlung während eines Befehls |
| `command_result.gd`, `replay_result.gd` | Ergebnisobjekte |
| **core/serialization/** | |
| `state_codec.gd` | versionierter Spielstand als String, Integritäts-, Hash- und Replayprüfung |
| `load_result.gd` | Ergebnis des Ladens |
| **tests/** | `run_all.sh`, `run_tests.gd`, `test_case.gd`, `fixtures.gd`, `unit/`, `scenarios/` |

Abhängigkeitsregel: `core/` benutzt nur sich selbst und Godot-Grundtypen (`RefCounted`, `JSON`, `RandomNumberGenerator`). `tests/unit/test_core_purity.gd` erzwingt das.

## Befehle

| Befehl | Nutzdaten | Wirkung |
|---|---|---|
| `StartGame` | `round_id`, `seed`, `players [{id, name}]`, `seat_order`, `assignment` = `manual` (`roles {"id": role}`) oder `random` (`role_pool`) | Personen und Rollen anlegen, Phase bleibt SETUP (Rollenanzeige) |
| `StartNight` | – | SETUP oder beendeter Tag → NIGHT, Nachtplan berechnen, ersten Schritt (Rudel) selbst beginnen |
| `AnswerPrompt` | `prompt_id`, `targets` (leer = kein Opfer bzw. Verzicht); beim mehrstufigen Prompt zusätzlich `stage` und je Stufe `choice` (bool) oder `targets` (`Command.answer_choice`, `Command.answer_stage_targets`) | Rudel: Wahl speichern, Schritt erledigt, noch kein Tod. Schutzengel: Schutz speichern. Reaktion: Fluch-Tod `HUNTER_SHOT` oder Verzicht, Reaktion erledigt. Waldhexe: Teilantwort speichern bzw. bei `confirm` alle Wirkungen anwenden. Fehler der Kette: `stage_mismatch`, `invalid_answer`, `invalid_target`, `invalid_target_count` |
| `EndNight` | – | nur wenn kein Prompt und kein Nachtschritt offen ist: NIGHT → DAWN_RESOLUTION → Tod `NIGHT_KILL` → DAY, sobald keine Reaktion offen ist |
| `Nominate` | `nominator_id`, `nominee_id` | Nominierung nach DR-03 speichern |
| `DecideExecution` | `target_id` (−1 = keine Hinrichtung) | Hinrichtung `LYNCH` einer heute nominierten Person oder „keine“ |
| `EndDay` | – | Tag beenden (erst nach `DecideExecution`) |
| `ConfirmWin` | `candidate_id` | Sieg bestätigen → GAME_OVER |
| `RejectWin` | `candidate_id`, `reason` (Pflicht) | Kandidat ablehnen, Partie läuft weiter |
| `BeginStep` | `step_id` | beginnt genau den erwarteten nächsten Schritt (`RulesEngine.next_step_id`) und öffnet dessen Prompt. Fehler: `step_already_active`, `no_pending_step`, `step_out_of_order` |
| `SkipStep` | `step_id`, `reason` (Pflicht) | überspringt den erwarteten Schritt (begonnen oder nicht), wenn seine Art überspringbar ist (`StepQueue.SKIPPABLE_BY_KIND`): nur der Rudelschritt (= kein Angriff). Schutzengel-, Waldhexen- und Reaktionsschritte: `step_not_skippable` |
| `CancelPrompt` | `prompt_id`, `reason` (Pflicht) | schließt einen abbrechbaren Prompt; der Schritt gilt als nicht begonnen. Reaktions-Prompt: `prompt_not_cancellable` |
| `GmCorrection` | `kind`, `target_id`, `reason` (Pflicht), `confirmed: true` (Pflicht) und je Art `trigger_effects` (kill), `role_id` (set_role), `field` + `value` (set_role_field), `guardian_id` + `target_id` (set_protection), `guardian_id` (remove_protection), `witch_id` + `potion` (`heal`/`poison`) + `available` (set_witch_potion), `witch_id` + `target_id` (set_rescue), `witch_id` (remove_rescue), `winner_kind` (declare_winner) | `kill` (Ursache `GM_CORRECTION`, Folgen ausdrücklich gewählt); `execute` (nur am Tag vor Tagesende, ohne Nominierung, Ursache `LYNCH`, Quelle `gm`, `ExecutionConfirmed.gm_override = true`, Reaktionen und DR-14 normal); `revive`; `set_role`; `set_role_field` (nur Felder aus `CORRECTABLE_ROLE_FIELDS`, derzeit `appears_as` = Scheinrolle; Fehler `field_not_correctable`, `invalid_value`); `set_protection`/`remove_protection` (nur nachts, erst nach erledigtem Schritt des Schutzengels; Fehler `not_a_guardian`, `no_guard_step`, `step_not_completed`, `invalid_target` bei Selbstschutz; GM-Protokoll `{protected_id}` alt/neu); `set_witch_potion` (jederzeit, nur für eine Waldhexe, Fehler `not_a_witch`, `invalid_correction`, `no_change`; Protokoll `{potion, available}` alt/neu); `set_rescue`/`remove_rescue` (nur nachts nach bestätigtem Waldhexenschritt; `set_rescue` nur auf das aktuelle lebende Rudelopfer; Fehler `wrong_phase`, `step_not_completed`, `no_witch_step`, `no_pack_target`, `not_current_pack_target`, `player_dead`, `no_change`; Protokoll `{saved_id}` alt/neu; Trankstatus bleibt unverändert); `declare_winner` (village, wolves, solo, none → GAME_OVER, nur ohne offenen Prompt und ohne offene Reaktion). Jede Art außer `declare_winner` bricht einen offenen Prompt mit Grund `state_changed_by_gm_correction` ab |

Schritt-IDs: `night:<Nacht>:<Index>:<Schritt>` (z. B. `night:1:0:schutzengel:3`, `night:1:1:pack`, `night:1:2:waldhexe:5`) und `reaction:<Reaktions-ID>`. Persönliche Nachtschritte heißen `<rolle>:<Personen-ID>` und liegen je Lage nach Personen-ID sortiert vor (Schutzengel) bzw. nach (Waldhexe) dem Rudelschritt.

Entsprechung zu den Namen im Masterplan (Phase 1): `SubmitAction` → `AnswerPrompt`, `ResolveMorning` → Teil von `EndNight`, `ExecutePlayer` → `DecideExecution`, `DeclareWinner` → `ConfirmWin`/`RejectWin`. Die Namen folgen `docs/godot-migration/03-godot-architecture.md` §5.6 und `implementation-boundary.md` A-12.

Ereignisse: `GameStarted` (gm), `RoleAssigned` (actor), `PhaseChanged` (public), `PromptOpened`/`PromptAnswered` (gm), `NightStepSkipped` (gm), `NoNightKill` (gm), `SeatDied` (gm), `KillIgnored` (gm), `NominationRecorded` (public), `ExecutionConfirmed`/`NoExecution` (public), `DayEnded` (public), `WinDetected` (gm), `WinConfirmed` (public), `WinRejected` (gm), `StepBegun`/`StepSkipped` (gm, mit `step_id` und Grund), `PromptCancelled` (gm, `prompt_id`, `step_id`, `reason`), `ReactionQueued` (gm), `ReactionResolved` (gm, `outcome` = `cursed` oder `declined`, `target_id` = −1 bei Verzicht), `GmCorrected` (gm, `kind`, `target_id`, `old`, `new`, `reason`, `trigger_effects`), `WinStatusProvisional` (gm, nach jedem Tod), `WinStatusFinal` (gm, `results`, `requires_gm_decision`), `ProtectionSet` (gm), `KillPrevented` (gm, `target_id`, `cause`, `source_kind`, `night`, `protection` = erste Quelle, `sources`, `guardian_id`, `guardian_ids`, `rescuer_ids`), `PromptStageAnswered` (gm, Teilantwort mit `stage`, `answer`, `next_stage`), `WitchActed` (gm, bestätigte Entscheidung mit `saved_role`), `StepDropped` (gm, `step_id`, `reason` = `actor_dead`, `actor_role_changed` oder `no_decision`).

## Rollen

| ID | DE / EN | Fraktion | `counts_as_wolf` | `appears_as` | Nachtschritt | Todesreaktion |
|---|---|---|---|---|---|---|
| `dorfbewohner` | Dorfbewohner / Villager | village | nein | `dorfbewohner` | – | – |
| `werwolf` | Werwolf / Werewolf | wolves | ja | `werwolf` | Rudel (`pack`) | – |
| `sensentraeger` | Sensenträger / Reaper | village | nein | `sensentraeger` | – | Fluch (`curse`), freiwillig |
| `schutzengel` | Schutzengel / Guardian Angel | village | nein | `schutzengel` | eigener Schritt vor dem Rudel | – |
| `waldhexe` | Waldhexe / Forest Witch | village | nein | `waldhexe` | eigener Schritt nach dem Rudel (mehrstufig) | – |

**Schutzengel** (`rules-register.md` §3, DR-05): Jeder lebende Schutzengel erhält in jeder Nacht einen eigenen Pflichtschritt vor dem Rudel (mehrere nach Personen-ID). Er wählt genau eine andere lebende Person (`min_count = max_count = 1`, Selbstwahl nicht in `allowed_ids`, manipuliert `invalid_target`). Beim Bestätigen wird `Protection{guardian_id, target_id, night}` gespeichert (`ProtectionSet`, nur Spielleiter), der Schrittstatus wird `done`. `CancelPrompt` vor der Bestätigung bietet den Schritt erneut an; `SkipStep` ist nie zulässig (`step_not_skippable`, auch mit Grund). In der Morgenauflösung prüft die Abfangstufe der `KillPipeline` nur `NIGHT_KILL` durch das Rudel gegen den Schutz dieser Nacht: Das Ziel überlebt, genau ein `KillPrevented{target_id, cause, source_kind, protection, guardian_id, guardian_ids, night}` (nur Spielleiter), kein `SeatDied`, keine Reaktion, kein vorläufiger Siegstatus. Alle anderen Ursachen wirken trotz Schutz. Der Schutz bleibt bestehen, wenn der Schutzengel nach seiner Bestätigung stirbt, und wird beim Tagesbeginn verworfen. Stirbt die geschützte Person vorher, gilt der Randfall „totes Rudelopfer“ (`KillIgnored`).

**Waldhexe** (`rules-register.md` §6, DR-06): Jede lebende Waldhexe mit mindestens einem unverbrauchten Trank erhält einen Schritt nach dem Rudel (mehrere nach Personen-ID). Heil- und Gifttrank gelten je einmal pro Person und Partie (`Player.ability_uses["waldhexe:heal"]`, `["waldhexe:poison"]`); eine Wiederbelebung setzt sie nicht zurück. Der Schritt ist ein Prompt (`kind` = `witch_chain`, abbrechbar) mit dem heilbaren Rudelopfer `partial.victim_id` (lebende bestätigte Rudelwahl, sonst −1; nur die ID, auch bei Schutz) und den Stufen `heal` (nur mit Opfer und Heiltrank) → `reveal` (nach Ja, tatsächliche Rolle `partial.victim_role`, nicht `appears_as`) → `poison` (nur mit Gifttrank) → `poison_target` (jede lebende Person, auch sie selbst und das Opfer) → `confirm` (Zusammenfassung der Teilantworten und finale Bestätigung). Die Stufe folgt allein aus den gespeicherten Teilantworten (`WitchStep.next_stage`). Das Laden prüft das und zusätzlich den Bezug zum übrigen Zustand (`WitchStep.matches_state`: erwarteter Nachtschritt dieser Nacht, lebende Person mit Rolle `waldhexe`, aktuelles Rudelopfer, lebendes Giftziel, Auswahlliste); Widersprüche lehnt `StateCodec.decode` mit `state_invalid` ab. Bis `confirm` ändern Antworten nur den Prompt; `CancelPrompt` verwirft alles (fachlicher Hash wie vor `BeginStep`). `confirm` speichert Trankverbrauch und `WitchAction`, meldet `WitchActed`, tötet dann ein Giftziel sofort über die `KillPipeline` (`WITCH_POISON`, Quelle die Waldhexe, kein Schutz, Reaktionen am Morgen) und markiert den Schritt als erledigt. Die Rettung wirkt in der Morgenauflösung nur gegen den Rudelangriff dieser Nacht; mit einem Schutzengel auf demselben Opfer entsteht genau ein `KillPrevented` mit beiden Quellen. `WitchAction` wird bei Tagesbeginn verworfen. Tote Waldhexe vor ihrem Schritt, oder kein lebendes Opfer bei verbrauchtem Gift: Der Schritt entfällt (`StepDropped`). `SkipStep` ist nie zulässig.

**Sensenträger** (`rules-register.md` §7, DR-09): Stirbt er mit Folgen (Rudel, Hinrichtung, `GmCorrection kill` mit `trigger_effects`, `GmCorrection execute`), reiht die `KillPipeline` genau eine Reaktion ein, höchstens eine pro Person und Partie (`Player.ability_uses["sensentraeger:death_reaction"]`); ein erneuter Tod nach Wiederbelebung löst keine zweite aus. Die Reaktion ist nach einem Tod am Tag sofort fällig, nach einem Tod in der Nacht (auch durch Gift) in der Morgenauflösung. Wählbar ist jede Person, die zum Zeitpunkt der Antwort lebt, außer dem Besitzer der Reaktion selbst, auch nach seiner Wiederbelebung (`StepQueue.begin` entfernt `reaction.owner_id` aus `allowed_ids`; der Rudel-Prompt ist davon nicht betroffen); das Ziel stirbt mit `HUNTER_SHOT`, Quelle der Sensenträger. Verzicht = `AnswerPrompt` ohne Ziel. Die Reaktion ist weder überspringbar noch abbrechbar; eine Wiederbelebung entfernt eine eingereihte Reaktion nicht. Schutz gegen den Fluch gibt es nicht (Abfangregeln betreffen nur den Wolfsangriff, B-04).

## Reaktionswarteschlange und Siegprüfung (DR-14)

1. Jeder Tod läuft durch `KillPipeline`. Mit `trigger_effects` (Standard; bei `GmCorrection kill` ausdrücklich gewählt) reiht die Rolle ihre Todesreaktion in `GameState.reactions` ein (`ReactionQueued`). Reihenfolge = Einreihung (aufsteigende Reaktions-ID).
2. Nach jedem Tod: vorläufiger Siegstatus (`WinStatusProvisional`, `provisional_win`), `win_check_pending = true`. Er beendet nichts.
3. Fällig sind Reaktionen in `DAWN_RESOLUTION` und `DAY`; Reaktionen aus der Nacht warten bis zur Morgenauflösung (DR-09). Solange eine fällig ist, sind nur `BeginStep`, `AnswerPrompt`, `SkipStep`/`CancelPrompt` (beide mit klarem Fehler) und `GmCorrection` zulässig; alles andere, auch `ConfirmWin`, liefert `reaction_open`.
4. `BeginStep("reaction:<id>")` öffnet den Prompt der ersten Reaktion; `AnswerPrompt` mit Ziel tötet (`HUNTER_SHOT`, Quelle = Besitzer), leer = Verzicht. Folgetode reihen weitere Reaktionen hinten ein.
5. Ist die Warteschlange leer, wechselt die Morgenauflösung zu `DAY`. Am Ende des Befehls folgt die verbindliche Prüfung (`WinStatusFinal`), aber nur, wenn weder eine Reaktion noch ein Prompt offen ist. Genau eine erfüllte Bedingung → Kandidat (`WinDetected`) zur Bestätigung. Mehrere gleichzeitig (im Core-Slice nur, wenn niemand lebt) → kein Kandidat, `requires_gm_decision = true`; der Spielleiter erklärt das Ergebnis per `GmCorrection declare_winner` (DR-02).

## Spielstand

```json
{ "format": "grimmhain-save", "schema_version": 5, "rules_version": "grimmhain-core-0.5",
  "round_id": "…", "commands": [ … ], "state": { … },
  "state_hash": "sha256:…", "integrity": "sha256:…" }
```

`state_hash` ist der fachliche Hash: kanonisches JSON des Zustands ohne die reinen Zählfelder `command_count` und `next_ids` (so hinterlässt ein abgebrochener Schritt denselben Hash wie vor seinem Beginn, AS-A02). `integrity` deckt alle übrigen Felder ab. Beim Laden wird die Befehlsliste erneut abgespielt; ihr Ergebnis muss dem gespeicherten Zustand vollständig (inklusive Zählfeldern) gleichen.

Schema 2 ergänzte `night_plan`, `next_night_step`, `reactions`, `provisional_win`, `win_check_pending`, `next_ids.reaction`, `pending_prompt.step_id`; Schema 3 ergänzte `players[].ability_uses`; Schema 4 ergänzte `night_step_status` und `protections`; Schema 5 ergänzt `witch_actions`, `pending_prompt.stage` und die Ursache `WITCH_POISON`. Spielstände mit Schema 1 bis 4 werden nicht migriert, sondern mit `unsupported_schema_version` und einer Meldung wie „Spielstand-Schema 4 wird nicht unterstützt, erwartet wird Schema 5.“ abgelehnt (`LoadResult.detail`); eine abweichende Regelversion ebenso mit `unsupported_rules_version`. Zeitstempel und `app_version` aus `03` §6.1 fügt später der SaveService außerhalb des Kerns hinzu, weil der Kern keine Uhr kennt.

## Umsetzungsentscheidungen innerhalb der Spezifikation

Diese Punkte legt die Spezifikation nicht fest; sie sind so gewählt, dass keine Regel erfunden wird, und lassen sich später ändern.

1. **Siegprüfung am Ende des Befehls.** Die Pipeline (A-16) prüft nach allen Toden eines Befehls. Bei `EndNight` liegt der automatische Wechsel zu DAY davor, weil `BeginDay` erst mit B-11 kommt.
2. **Offener Siegkandidat blockiert alle anderen Befehle** (`win_candidate_open`), bis `ConfirmWin` oder `RejectWin` erfolgt. So bleibt die Phase bis zur Entscheidung unverändert (AS-C01).
3. **Kandidat erneut nur nach einem weiteren Tod** (AS-C04, „nach einer weiteren Zustandsänderung“ ist als Tod ausgelegt).
4. **Tages-Unterzustand `ENDED`** zwischen `EndDay` und `StartNight`; `vertical-slice-flow.md` §8 führt beide Befehle getrennt.
5. **Pflicht einer Einzelsiegrolle beim Setup** (DECISION-LOG) wird nicht geprüft, weil der Core-Slice keine solche Rolle besitzt. Geprüft werden 6–24 Personen, Rollenanzahl und je mindestens eine Wolfs- und Dorfrolle.
6. **Keine Obergrenze für `dorfbewohner` und `werwolf`** (Entscheidung vom 26.09.2026, `DECISION-LOG.md`). Nur so ist jede Personenzahl von 6 bis 24 mit den beiden Grundrollen spielbar. Der Katalog kennt weiterhin ein optionales `max_copies` für spätere Rollen; die konkrete Rollenkomposition legt das Setup in Phase 2 fest.
7. **Selbstnominierung** ist nicht verboten, weil DR-03 sie nicht regelt.
8. **`SeatDied` ist nur für den Spielleiter sichtbar.** Nach DR-04 ist öffentlich nur der Name (Rolle je nach Setup-Option `reveal_role_on_death`, nie die Ursache); die öffentliche Todesmeldung entsteht mit den Projektionen (B-18).
9. **Seed** muss zwischen 0 und 2^53−1 liegen, damit er in JSON verlustfrei bleibt.
10. **`StartNight` beginnt den ersten Nachtschritt selbst**, damit bestehende Befehlsfolgen gültig bleiben. Jeder weitere Schritt, jede Reaktion und jeder erneute Beginn nach `CancelPrompt` verlangt `BeginStep`.
11. **Abbrechbar** sind Rudel-, Schutzengel- und Waldhexen-Prompts vor der Bestätigung; Reaktions-Prompts sind weder abbrechbar noch überspringbar (Verzicht ist eine Antwort). **Überspringbar** ist ausschließlich der Rudelschritt; die Regel steht zentral je Schrittart in `StepQueue.SKIPPABLE_BY_KIND`, unbekannte Schrittarten sind nie überspringbar.
12. **`GmCorrection` ist während fälliger Reaktionen erlaubt** (Spielleiterautorität, G-GM-1), aber nicht bei offenem Siegkandidaten: erst `ConfirmWin` oder `RejectWin`. `revive` und `set_role` stoßen ebenfalls eine verbindliche Siegprüfung an. `set_role` und `set_role_field` bieten keine Testrollen an.
14. **Korrektur und offener Prompt** (DECISION-LOG, Korrekturrunde): Jede Korrektur am Zustand einer Person bricht einen offenen Prompt ab (`PromptCancelled`, Grund `state_changed_by_gm_correction`), auch einen Reaktions-Prompt; die Reaktion bleibt offen, der Schritt ist wieder der erwartete Schritt und wird mit `BeginStep` neu begonnen. So enthält kein Prompt veraltete Ziele. Eine bereits bestätigte Rudelwahl (`pack_target_id`) wird dagegen nicht zurückgesetzt; trifft sie eine inzwischen tote Person, protokolliert die Morgenauflösung `KillIgnored`.
15. **`execute` am Tag** setzt den Tag auf „Hinrichtung erfolgt“, auch nach einer bereits bestätigten Hinrichtung (Korrekturfall); nach `EndDay` ist sie nicht mehr möglich.
13. **Keine Testrollen mehr:** Die frühere Testrolle `test-sensentraeger` und `StartGame.test_mode` sind entfernt; alle Reaktionstests nutzen den echten `sensentraeger`.
16. **Bereits totes Rudelopfer** (DECISION-LOG, Randfälle): keine erneute Rudelwahl, `KillIgnored` in der Morgenauflösung.
17. **Nachtplan-Snapshot und entfallende Nachtschritte:** Der Nachtplan entsteht bei `StartNight` und wächst während der Nacht nie (neue Rollen und wieder verfügbare Tränke gelten ab der nächsten Nacht). Nach jedem Befehl und vor dem ersten Schritt der Nacht lässt `StepQueue.drop_unactionable` persönliche Schritte entfallen (`StepDropped`, Status `skipped`), wenn die Person tot ist (`actor_dead`), nicht mehr die im Schritt geplante Rolle hat (`actor_role_changed`, für alle Rollen) oder als Waldhexe keine Entscheidung treffen kann (`no_decision`). Ein offener Prompt wird dabei nie berührt; eine Korrektur bei offenem Prompt bricht ihn ab und der Schritt entfällt danach. So wird nie die Fähigkeit einer verlorenen Rolle ausgeführt.
18. **Zusammenfassung und Bestätigung sind eine Stufe** (`confirm`): Der Prompt enthält in dieser Stufe alle Teilantworten als Zusammenfassung; die Antwort „ja“ bestätigt. Ein „nein“ gibt es nicht, geändert wird per `CancelPrompt` und Neubeginn.
19. **Offengelegte Rolle** nach der Rettung ist die tatsächliche `role_id` des Opfers zum Zeitpunkt der Antwort, nie `appears_as` (DECISION-LOG, Korrekturrunde Waldhexe).
20. **Rettungskorrektur und Trankstatus sind getrennt:** `set_rescue`/`remove_rescue` ändern nur `WitchAction.saved_id`; den Heiltrank korrigiert `set_witch_potion`. `set_rescue` nimmt ausschließlich das aktuelle lebende Rudelopfer an; ein Ändern auf eine andere Person gibt es nicht.

## Abgrenzung zu späteren Stufen

- **AS-C09** ist in der Spezifikation auf den Kernanteil begrenzt (Zustand an Personen-ID, nicht triviale Sitzfolge); der Sitztausch per `ReorderSeats` ist AS-S03 (B-11).
- **AS-C08:** Der Kern erkennt die Beschädigung (Stufe C); Rückfall auf den vorherigen Checkpoint, Nicht-Überschreiben und Rotation gehören zu B-13 (Stufe V).
- **Niemand lebt:** Nach abgelehnten Kandidaten (`RejectWin`) erreichbar. Nach DR-02 entsteht kein automatischer Kandidat; der Spielleiter erklärt das Ergebnis mit `GmCorrection declare_winner`.
- **Gleichzeitige Kandidaten mit Auswahl per `ConfirmWin`** (z. B. Manipulator und Wolfsparität, AS-R34) entstehen erst mit der ersten Einzelsiegrolle (B-09); bis dahin entscheidet der Spielleiter per `declare_winner`.

## Nicht enthalten

UI, Szenen, Autoloads, Assets, Audio, weitere Rollen, allgemeines Effektmodell, `ReorderSeats`, `ConfirmRoleShown`, `BeginDay`, Undo/Redo, Checkpoints auf Datenträger, öffentliche Projektionen. Siehe `implementation-boundary.md` B bis D.
