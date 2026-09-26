# Grimmhain · Godot-Projekt

Phase 1 des Masterplans (`../GRIMMHAIN-REVOLUTION-MASTERPLAN.md`): headless, deterministischer Regelkern für Dorf gegen Werwölfe. Umfang nach `../docs/specs/vertical-slice/implementation-boundary.md` Abschnitt A. Keine UI, keine Szenen, keine Assets, keine Rollen außer `dorfbewohner` und `werwolf`.

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
| `tests/unit/test_seeded_rng.gd` | Seed, Ziehposition, Wiederaufnahme mitten in der Folge | A-18 |
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
| `game_state.gd` | vollständiger fachlicher Zustand, `schema_version`, `rules_version`, fachlicher Hash |
| `player.gd` | Person mit stabiler ID; Rolle, Fraktion, `counts_as_wolf`, `appears_as` getrennt; kein Sitzfeld |
| `kill_event.gd` | Todesdatensatz: Ursache (`NIGHT_KILL`, `LYNCH`), Quelle, Ziel, Zeitpunkt, Abfangstatus |
| `nomination.gd` | Nominierende, Nominierte, Tag; kein Stimmfeld |
| `pending_prompt.gd` | offene Eingabe als Teil des Spielstands (Rudelwahl) |
| `win_candidate.gd` | Siegkandidat mit Status offen/bestätigt/abgelehnt |
| `phase.gd`, `faction.gd`, `visibility.gd` | Konstanten für Phasen, Tages-Unterzustände, Fraktionen, Sichtbarkeit |
| **core/commands/** `command.gd` | Befehlstypen, Fabrikfunktionen, JSON-Rundreise |
| **core/events/** `game_event.gd` | Ereignistypen mit Index, Befehlsindex, Sichtbarkeit, Daten |
| **core/rules/** | |
| `rules_engine.gd` | `apply` (validieren → auf Kopie ausführen → Ereignisse), `replay` |
| `phase_machine.gd` | zulässige Befehle je Phase, Phasenwechsel mit Ereignis |
| `kill_pipeline.gd` | Tötungs-Pipeline ohne Abfangregeln |
| `win_rules.gd` | einzige Siegprüfung, erzeugt nur Kandidaten |
| `role_catalog.gd` | Stammdaten `dorfbewohner`, `werwolf` inkl. Obergrenzen |
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
| `StartNight` | – | SETUP oder beendeter Tag → NIGHT, Rudel-Prompt öffnen |
| `AnswerPrompt` | `prompt_id`, `targets` (leer = kein Opfer) | Rudelwahl speichern, noch kein Tod |
| `EndNight` | – | NIGHT → DAWN_RESOLUTION → Tod `NIGHT_KILL` → DAY |
| `Nominate` | `nominator_id`, `nominee_id` | Nominierung nach DR-03 speichern |
| `DecideExecution` | `target_id` (−1 = keine Hinrichtung) | Hinrichtung `LYNCH` einer heute nominierten Person oder „keine“ |
| `EndDay` | – | Tag beenden (erst nach `DecideExecution`) |
| `ConfirmWin` | `candidate_id` | Sieg bestätigen → GAME_OVER |
| `RejectWin` | `candidate_id`, `reason` (Pflicht) | Kandidat ablehnen, Partie läuft weiter |

Entsprechung zu den Namen im Masterplan (Phase 1): `SubmitAction` → `AnswerPrompt`, `ResolveMorning` → Teil von `EndNight`, `ExecutePlayer` → `DecideExecution`, `DeclareWinner` → `ConfirmWin`/`RejectWin`. Die Namen folgen `docs/godot-migration/03-godot-architecture.md` §5.6 und `implementation-boundary.md` A-12.

Ereignisse: `GameStarted` (gm), `RoleAssigned` (actor), `PhaseChanged` (public), `PromptOpened`/`PromptAnswered` (gm), `NightStepSkipped` (gm), `NoNightKill` (gm), `SeatDied` (gm), `KillIgnored` (gm), `NominationRecorded` (public), `ExecutionConfirmed`/`NoExecution` (public), `DayEnded` (public), `WinDetected` (gm), `WinConfirmed` (public), `WinRejected` (gm).

## Spielstand

```json
{ "format": "grimmhain-save", "schema_version": 1, "rules_version": "grimmhain-core-0.1",
  "round_id": "…", "commands": [ … ], "state": { … },
  "state_hash": "sha256:…", "integrity": "sha256:…" }
```

`state_hash` ist der fachliche Hash (kanonisches JSON des Zustands). `integrity` deckt alle übrigen Felder ab. Beim Laden wird die Befehlsliste erneut abgespielt; ihr Ergebnis muss denselben fachlichen Hash haben. Zeitstempel und `app_version` aus `03` §6.1 fügt später der SaveService außerhalb des Kerns hinzu, weil der Kern keine Uhr kennt.

## Umsetzungsentscheidungen innerhalb der Spezifikation

Diese Punkte legt die Spezifikation nicht fest; sie sind so gewählt, dass keine Regel erfunden wird, und lassen sich später ändern.

1. **Siegprüfung am Ende des Befehls.** Die Pipeline (A-16) prüft nach allen Toden eines Befehls. Bei `EndNight` liegt der automatische Wechsel zu DAY davor, weil `BeginDay` erst mit B-11 kommt.
2. **Offener Siegkandidat blockiert alle anderen Befehle** (`win_candidate_open`), bis `ConfirmWin` oder `RejectWin` erfolgt. So bleibt die Phase bis zur Entscheidung unverändert (AS-C01).
3. **Kandidat erneut nur nach einem weiteren Tod** (AS-C04, „nach einer weiteren Zustandsänderung“ ist als Tod ausgelegt).
4. **Tages-Unterzustand `ENDED`** zwischen `EndDay` und `StartNight`; `vertical-slice-flow.md` §8 führt beide Befehle getrennt.
5. **Pflicht einer Einzelsiegrolle beim Setup** (DECISION-LOG) wird nicht geprüft, weil der Core-Slice keine solche Rolle besitzt. Geprüft werden 6–24 Personen, Rollenanzahl, Obergrenzen (`werwolf` 5, `dorfbewohner` 10) und je mindestens eine Wolfs- und Dorfrolle.
6. **Selbstnominierung** ist nicht verboten, weil DR-03 sie nicht regelt.
7. **`SeatDied` ist nur für den Spielleiter sichtbar**, solange DR-04 (öffentliche Information bei Tod) offen ist.
8. **Seed** muss zwischen 0 und 2^53−1 liegen, damit er in JSON verlustfrei bleibt.

## Bekannte Lücken gegenüber der Spezifikation

- **AS-C09** verlangt `ReorderSeats`, der Befehl gehört laut `implementation-boundary.md` aber zu B-11. Getestet ist nur der Kernanteil (Zustand an Personen-ID, nicht triviale Sitzfolge).
- **AS-C08** verlangt Rückfall auf den vorherigen Checkpoint und Nicht-Überschreiben der Datei. Der Kern erkennt die Beschädigung; Dateihandling und Rotation gehören zu B-13.
- **Niemand lebt:** `implementation-boundary.md` A-17 nennt den Fall unerreichbar. Nach abgelehnten Kandidaten (`RejectWin`) ist er erreichbar. Bis DR-02 entschieden ist, entsteht dort kein automatischer Kandidat.

## Nicht enthalten

UI, Szenen, Autoloads, Assets, Audio, weitere Rollen, Effekte, Schutz, Reaktionswarteschlange, `CancelPrompt`, `BeginStep`/`SkipStep`, `ReorderSeats`, `GmCorrection`, Undo/Redo, Checkpoints auf Datenträger, öffentliche Projektionen. Siehe `implementation-boundary.md` B bis D.
