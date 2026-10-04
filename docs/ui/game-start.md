# Spielstart · „Partie starten“

> **Abgelöst (DA-89, 04.10.2026):** Dieser Wizard mit vier bestätigten Schritten wurde durch die Vorbereitung in drei Schritten ersetzt, siehe `preparation.md`. Der Text beschreibt den Stand davor.

Stand: 27.09.2026 · Godot 4.7.2 · Projekt `godot/`

Nach bestätigter Sitzordnung (`seating-setup.md`) startet der Spielleiter die Partie. Produktentscheidung vom 27.09.2026: „Sitzordnung bestätigen“ beendet nur das Setup. Erst der eigene Button „Partie starten“ sendet `StartGame`, damit die Sitzordnung vorher noch geprüft oder geändert werden kann.

## Ablauf

1. „Sitzordnung bestätigen“: Die Fußzeile zeigt an derselben Stelle „Partie starten“ (Hauptaktion, Gold). Die Karte „Sitzordnung fertig“ weist darauf hin.
2. Jede spätere Änderung, etwa ein Tausch oder ein früherer Schritt, hebt die Bestätigung auf. Dann steht dort wieder „Sitzordnung bestätigen“.
3. „Partie starten“: `NewGameScreen` ruft `GameStart.start(session, setup)` auf.
   - **Angenommen:** Der Setup-Entwurf ist verbraucht und wird verworfen. Die Statusmeldung „Partie gestartet“ erscheint, und das Cockpit öffnet sich. Es erkennt die aktive Partie (`has_game`), zeigt die Phase „Vorbereitung“ und sagt ausdrücklich, dass geführter Ablauf, Sitzkreis und Aktionen für Nacht und Tag in späteren Arbeitspaketen folgen.
   - **Abgelehnt:** Setup und Sitzung bleiben unverändert. Die Fußzeile meldet den Grund, und der Button bleibt für einen neuen Versuch aktiv.

Den weiteren Ablauf (Nacht, Morgen, Tag, Sieg) führt das Cockpit, siehe `cockpit.md`.

## Schichten

| Teil | Aufgabe |
|---|---|
| `PlayerSetup.start_data()` (`app/setup/`, ohne Regelkern) | Reine Startdaten nur bei vollständig bestätigtem Entwurf, sonst Fehlercode. Ändert nichts. |
| `GameStart` (`app/session/game_start.gd`) | Baut genau einen `StartGame`-Befehl und sendet ihn über `GameSession.submit`. Keine eigene Regelprüfung. |
| `GameSession` / `RulesEngine` | Annahme oder Ablehnung, Zustand und Ereignisse wie bei jedem Befehl. |

## Abbildung auf `StartGame`

| Feld | Quelle |
|---|---|
| `players` [{id, name}] | Personen in Listenreihenfolge, Personen-ID und Name unverändert |
| `seat_order` | `SeatingDraft.order`, Platz 1 = Index 0 |
| `assignment` | immer `"manual"` |
| `roles` {"<id>": Rolle} | feste Zuordnung aus der Verteilung, auch wenn sie im Setup zufällig entstand. Beim Start wird nicht erneut gemischt. |
| `appearances` {"<id>": Scheinrolle} | nur für Personen mit Trugbilderwolf-Kopie, die ausdrücklich gewählte Scheinrolle; fehlt ganz, wenn es keine Kopie gibt |
| `seed` | neuer Wert aus `PlayerSetup.seed_source` (Standard `AppPlatform.initial_seed()`, in Tests fest) |
| `round_id` | `GameStart.round_id_for(seed)`: die ersten 32 Hex-Zeichen von SHA-256(`"grimmhain-round:<seed>"`), gruppiert 8-4-4-4-12 |

Gleiche Startdaten und gleicher Seed ergeben denselben Befehl. Die `round_id` hat UUID-Form, ist aber keine zufällige UUID v4. Verschiedene Seeds ergeben praktisch immer verschiedene IDs.

## Fehler

| Code | Herkunft | Meldung in der Fußzeile |
|---|---|---|
| `players_not_confirmed`, `roles_not_confirmed`, `distribution_not_confirmed`, `seating_not_confirmed` | `start_data()` | „Start abgelehnt: Das Setup ist nicht vollständig bestätigt. Nichts wurde geändert.“ |
| `game_already_started` | Regelkern | „Start abgelehnt: Es läuft bereits eine Partie. Nichts wurde geändert.“ |
| jeder andere Code | Regelkern | „Start abgelehnt (Code …). Nichts wurde geändert.“ |

**Doppeltippen:** Nach dem ersten angenommenen Start ist der Entwurf verbraucht. Ein zweites Tippen sendet nichts, und der Regelkern sieht es nicht. Auch ein erneut aufgebautes Setup kann keine zweite Partie starten, solange eine läuft: Der Regelkern lehnt es mit `game_already_started` ab.

**Geheimhaltung:** Statusmeldungen, Fußzeile und Cockpit nennen keine Rolle und keine Scheinrolle.

## Tests und Screenshots

| Testdatei | Inhalt |
|---|---|
| `tests/ui/test_game_start_model.gd` | Start mit 6 und 24 Personen; Personen-ID, Name, Rolle, Scheinrolle und Sitzplatz im GameState nach mehreren Tauschen; manuelle Zuordnung ohne erneutes Mischen; Seed und `round_id` reproduzierbar; unvollständiger und nachträglich geänderter Entwurf; wiederholter Start; Ablehnung durch den Regelkern ohne Änderung; identisches Replay; reine Startdaten |
| `tests/ui/test_game_start_step.gd` | Button nur mit bestätigter Sitzordnung, ersetzt „Sitzordnung bestätigen“; Layout 24 Personen bei 1024×768 DE/EN; Start öffnet das Cockpit als aktive Partie; Doppeltippen; Ablehnung mit Meldung DE/EN; keine Rollen in Meldungen DE/EN |

```bash
godot/tests/run_all.sh --filter=test_game_start
```

Prüf-Screenshots: `docs/evidence/game-start/`.

## Grenzen

- Nur Maus bzw. simulierte Eingaben geprüft, keine Touch- oder Tablet-Prüfung.
- Der Start wird noch nicht gespeichert (kein SaveService). Nach einem Neustart der App ist die Partie weg.
- Wer im Hauptmenü erneut „Neue Partie“ wählt, während eine Partie läuft, kann ein neues Setup aufbauen. Der Start wird dann abgelehnt. Eine Partie zu beenden oder zu verwerfen ist noch nicht vorgesehen.
