# Grimmhain · Godot-Projekt

Phase 1 des Masterplans (`../GRIMMHAIN-REVOLUTION-MASTERPLAN.md`): headless, deterministischer Regelkern für Dorf gegen Werwölfe. Umfang nach `../docs/specs/vertical-slice/implementation-boundary.md` Abschnitt A, ergänzt um die Grundlagen B-06, B-11 (ohne `ReorderSeats`, `ConfirmRoleShown`, `BeginDay`) und DR-14: Regelschritte, Prompt-Abbruch, Spielleiterkorrektur, persistente Reaktionswarteschlange, vorläufige und verbindliche Siegprüfung. Keine UI, keine Szenen, keine Assets, keine Produktionsrollen außer `dorfbewohner` und `werwolf`; für Reaktionstests gibt es die reine Testrolle `test-sensentraeger`.

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
| `tests/unit/test_steps.gd` | `BeginStep` nur für den erwarteten Schritt, `SkipStep` mit Grund, `CancelPrompt` ohne Teilwirkung, Pflichtschritt nicht still übersprungen, Save/Load, Replay | AS-A02 (Kernanteil), B-11 |
| `tests/unit/test_reactions.gd` | Reaktion eingereiht, blockiert andere Befehle, nicht überspringbar/abbrechbar, Verzicht, Fluch-Tod, Kettenreaktion und stabile Reihenfolge, Nachttod reagiert am Morgen, Save/Load mit offener Reaktion, Replay | AS-A03, B-06, DR-09 |
| `tests/unit/test_win_status.gd` | vorläufiger Status nach jedem Tod, verbindliche Prüfung erst nach allen Reaktionen, `ConfirmWin` bei offener Reaktion abgelehnt, niemand lebt ohne automatischen Gewinner, Save/Load, Replay | AS-R35, AS-R36, DR-02, DR-14 |
| `tests/unit/test_gm_correction.gd` | Bestätigung und Begründung Pflicht, alter/neuer Wert, Tod mit und ohne Folgen, Wiederbelebung, Rollenkorrektur, kein Undo, Save/Load, Replay | AS-G01, AS-G02, G-GM-1 |
| `tests/unit/test_save_versions.gd` | Spielstand mit Schema 1 wird mit klarer Meldung abgelehnt | Versionierung |
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
| `player.gd` | Person mit stabiler ID; Rolle, Fraktion, `counts_as_wolf`, `appears_as` getrennt; kein Sitzfeld |
| `kill_event.gd` | Todesdatensatz: Ursache (`NIGHT_KILL`, `LYNCH`), Quelle, Ziel, Zeitpunkt, Abfangstatus |
| `reaction.gd` | offene Todesreaktion (Besitzer, auslösender Tod), Teil des Spielstands |
| `nomination.gd` | Nominierende, Nominierte, Tag; kein Stimmfeld |
| `pending_prompt.gd` | offene Eingabe als Teil des Spielstands (Rudelwahl, Reaktion) mit zugehöriger Schritt-ID und Abbrechbarkeit |
| `win_candidate.gd` | Siegkandidat mit Status offen/bestätigt/abgelehnt |
| `phase.gd`, `faction.gd`, `visibility.gd` | Konstanten für Phasen, Tages-Unterzustände, Fraktionen, Sichtbarkeit |
| **core/commands/** `command.gd` | Befehlstypen, Fabrikfunktionen, JSON-Rundreise |
| **core/events/** `game_event.gd` | Ereignistypen mit Index, Befehlsindex, Sichtbarkeit, Daten |
| **core/rules/** | |
| `rules_engine.gd` | `apply` (validieren → auf Kopie ausführen → Ereignisse), `replay` |
| `phase_machine.gd` | zulässige Befehle je Phase, Phasenwechsel mit Ereignis |
| `kill_pipeline.gd` | Tötungs-Pipeline ohne Abfangregeln; reiht Todesreaktionen ein und berechnet den vorläufigen Siegstatus |
| `step_queue.gd` | erwarteter nächster Schritt (Nachtplan, Reaktionen), Beginn, Überspringen, Prompt-Abbruch |
| `gm_corrections.gd` | Spielleiterkorrektur: Prüfung, Ausführung, Protokoll mit altem und neuem Wert |
| `win_rules.gd` | einzige Siegprüfung: vorläufig nach jedem Tod, verbindlich nach allen Reaktionen; erzeugt nur Kandidaten |
| `role_catalog.gd` | Stammdaten `dorfbewohner`, `werwolf` und Testrolle `test-sensentraeger` (nur mit `test_mode`); optionale Obergrenze `max_copies`, Todesreaktion `death_reaction` |
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
| `AnswerPrompt` | `prompt_id`, `targets` (leer = kein Opfer bzw. Verzicht) | Rudel: Wahl speichern, Schritt erledigt, noch kein Tod. Reaktion: Fluch-Tod `HUNTER_SHOT` oder Verzicht, Reaktion erledigt |
| `EndNight` | – | nur wenn kein Prompt und kein Nachtschritt offen ist: NIGHT → DAWN_RESOLUTION → Tod `NIGHT_KILL` → DAY, sobald keine Reaktion offen ist |
| `Nominate` | `nominator_id`, `nominee_id` | Nominierung nach DR-03 speichern |
| `DecideExecution` | `target_id` (−1 = keine Hinrichtung) | Hinrichtung `LYNCH` einer heute nominierten Person oder „keine“ |
| `EndDay` | – | Tag beenden (erst nach `DecideExecution`) |
| `ConfirmWin` | `candidate_id` | Sieg bestätigen → GAME_OVER |
| `RejectWin` | `candidate_id`, `reason` (Pflicht) | Kandidat ablehnen, Partie läuft weiter |
| `BeginStep` | `step_id` | beginnt genau den erwarteten nächsten Schritt (`RulesEngine.next_step_id`) und öffnet dessen Prompt. Fehler: `step_already_active`, `no_pending_step`, `step_out_of_order` |
| `SkipStep` | `step_id`, `reason` (Pflicht) | überspringt den erwarteten Nachtschritt (begonnen oder nicht), Rudel = kein Angriff. Reaktionen: `step_not_skippable` |
| `CancelPrompt` | `prompt_id`, `reason` (Pflicht) | schließt einen abbrechbaren Prompt; der Schritt gilt als nicht begonnen. Reaktions-Prompt: `prompt_not_cancellable` |
| `GmCorrection` | `kind`, `target_id`, `reason` (Pflicht), `confirmed: true` (Pflicht) und je Art `trigger_effects` (kill), `role_id` (set_role), `winner_kind` (declare_winner) | `kill` (Ursache `GM_CORRECTION`, Folgen ausdrücklich gewählt), `revive`, `set_role`, `declare_winner` (village, wolves, solo, none → GAME_OVER) |

Schritt-IDs: `night:<Nacht>:<Index>:<Schritt>` (z. B. `night:1:0:pack`) und `reaction:<Reaktions-ID>`.

Entsprechung zu den Namen im Masterplan (Phase 1): `SubmitAction` → `AnswerPrompt`, `ResolveMorning` → Teil von `EndNight`, `ExecutePlayer` → `DecideExecution`, `DeclareWinner` → `ConfirmWin`/`RejectWin`. Die Namen folgen `docs/godot-migration/03-godot-architecture.md` §5.6 und `implementation-boundary.md` A-12.

Ereignisse: `GameStarted` (gm), `RoleAssigned` (actor), `PhaseChanged` (public), `PromptOpened`/`PromptAnswered` (gm), `NightStepSkipped` (gm), `NoNightKill` (gm), `SeatDied` (gm), `KillIgnored` (gm), `NominationRecorded` (public), `ExecutionConfirmed`/`NoExecution` (public), `DayEnded` (public), `WinDetected` (gm), `WinConfirmed` (public), `WinRejected` (gm), `StepBegun`/`StepSkipped` (gm, mit `step_id` und Grund), `PromptCancelled` (gm, `prompt_id`, `step_id`, `reason`), `ReactionQueued`/`ReactionResolved` (gm), `GmCorrected` (gm, `kind`, `target_id`, `old`, `new`, `reason`, `trigger_effects`), `WinStatusProvisional` (gm, nach jedem Tod), `WinStatusFinal` (gm, `results`, `requires_gm_decision`).

## Reaktionswarteschlange und Siegprüfung (DR-14)

1. Jeder Tod läuft durch `KillPipeline`. Mit `trigger_effects` (Standard; bei `GmCorrection kill` ausdrücklich gewählt) reiht die Rolle ihre Todesreaktion in `GameState.reactions` ein (`ReactionQueued`). Reihenfolge = Einreihung (aufsteigende Reaktions-ID).
2. Nach jedem Tod: vorläufiger Siegstatus (`WinStatusProvisional`, `provisional_win`), `win_check_pending = true`. Er beendet nichts.
3. Fällig sind Reaktionen in `DAWN_RESOLUTION` und `DAY`; Reaktionen aus der Nacht warten bis zur Morgenauflösung (DR-09). Solange eine fällig ist, sind nur `BeginStep`, `AnswerPrompt`, `SkipStep`/`CancelPrompt` (beide mit klarem Fehler) und `GmCorrection` zulässig; alles andere, auch `ConfirmWin`, liefert `reaction_open`.
4. `BeginStep("reaction:<id>")` öffnet den Prompt der ersten Reaktion; `AnswerPrompt` mit Ziel tötet (`HUNTER_SHOT`, Quelle = Besitzer), leer = Verzicht. Folgetode reihen weitere Reaktionen hinten ein.
5. Ist die Warteschlange leer, wechselt die Morgenauflösung zu `DAY`. Am Ende des Befehls folgt die verbindliche Prüfung (`WinStatusFinal`). Genau eine erfüllte Bedingung → Kandidat (`WinDetected`) zur Bestätigung. Mehrere gleichzeitig (im Core-Slice nur, wenn niemand lebt) → kein Kandidat, `requires_gm_decision = true`; der Spielleiter erklärt das Ergebnis per `GmCorrection declare_winner` (DR-02).

## Spielstand

```json
{ "format": "grimmhain-save", "schema_version": 2, "rules_version": "grimmhain-core-0.2",
  "round_id": "…", "commands": [ … ], "state": { … },
  "state_hash": "sha256:…", "integrity": "sha256:…" }
```

`state_hash` ist der fachliche Hash: kanonisches JSON des Zustands ohne die reinen Zählfelder `command_count` und `next_ids` (so hinterlässt ein abgebrochener Schritt denselben Hash wie vor seinem Beginn, AS-A02). `integrity` deckt alle übrigen Felder ab. Beim Laden wird die Befehlsliste erneut abgespielt; ihr Ergebnis muss dem gespeicherten Zustand vollständig (inklusive Zählfeldern) gleichen.

Neue Zustandsfelder in Schema 2: `night_plan`, `next_night_step`, `reactions`, `provisional_win`, `win_check_pending`, `next_ids.reaction`, `pending_prompt.step_id`. Spielstände mit Schema 1 werden nicht migriert, sondern mit `unsupported_schema_version` und der Meldung „Spielstand-Schema 1 wird nicht unterstützt, erwartet wird Schema 2.“ abgelehnt (`LoadResult.detail`); eine abweichende Regelversion ebenso mit `unsupported_rules_version`. Zeitstempel und `app_version` aus `03` §6.1 fügt später der SaveService außerhalb des Kerns hinzu, weil der Kern keine Uhr kennt.

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
11. **Abbrechbar** ist der Rudel-Prompt; Reaktions-Prompts sind Pflichtentscheidungen und weder abbrechbar noch überspringbar (Verzicht ist eine Antwort).
12. **`GmCorrection` ist während fälliger Reaktionen erlaubt** (Spielleiterautorität, G-GM-1), aber nicht bei offenem Siegkandidaten: erst `ConfirmWin` oder `RejectWin`. `revive` und `set_role` stoßen ebenfalls eine verbindliche Siegprüfung an. `set_role` bietet keine Testrollen an; die Scheinrolle des Trugbilderwolfs ist nicht korrigierbar (DECISION-LOG).
13. **Testrolle `test-sensentraeger`** (Fraktion Dorf, Fluch-Reaktion) ist nur mit `StartGame.test_mode = true` zulässig und keine Produktionsversion des Sensenträgers.

## Abgrenzung zu späteren Stufen

- **AS-C09** ist in der Spezifikation auf den Kernanteil begrenzt (Zustand an Personen-ID, nicht triviale Sitzfolge); der Sitztausch per `ReorderSeats` ist AS-S03 (B-11).
- **AS-C08:** Der Kern erkennt die Beschädigung (Stufe C); Rückfall auf den vorherigen Checkpoint, Nicht-Überschreiben und Rotation gehören zu B-13 (Stufe V).
- **Niemand lebt:** Nach abgelehnten Kandidaten (`RejectWin`) erreichbar. Nach DR-02 entsteht kein automatischer Kandidat; der Spielleiter erklärt das Ergebnis mit `GmCorrection declare_winner`.
- **Gleichzeitige Kandidaten mit Auswahl per `ConfirmWin`** (z. B. Manipulator und Wolfsparität, AS-R34) entstehen erst mit der ersten Einzelsiegrolle (B-09); bis dahin entscheidet der Spielleiter per `declare_winner`.

## Nicht enthalten

UI, Szenen, Autoloads, Assets, Audio, weitere Rollen (auch kein Produktions-Sensenträger), Effekte, Schutz, `ReorderSeats`, `ConfirmRoleShown`, `BeginDay`, Undo/Redo, Checkpoints auf Datenträger, öffentliche Projektionen. Siehe `implementation-boundary.md` B bis D.
