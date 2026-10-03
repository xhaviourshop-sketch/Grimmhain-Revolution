# K1b · Umsetzungsgrenze · Selbstmörder

**Stand:** 2026-10-03 · **Status:** bereit zur Umsetzung, wartet auf Grimmhain-1; keine offene Produktfrage
**Regeln:** `rules-register.md` · **Szenarien:** `acceptance-scenarios.md` · **Planung:** `../../role-migration/06-implementation-batches.md` §3

Pfade relativ zu `docs/specs/k1b-selbstmoerder/`. Diese Datei legt fest, was die Umsetzung von K1b baut und was nicht.

## A · Voraussetzungen

| Nr. | Voraussetzung | Stand |
|---|---|---|
| A-1 | Produktentscheidungen RM-DR-138.1, .3, .4, .6, .7 im Decision Log | erfüllt (3. Oktober 2026, mit Ergänzung) |
| A-2 | Abstimmung mit Grimmhain-1 über die Katalogerweiterung (`../../role-migration/06-implementation-batches.md` §3.7) | **offen, einzige verbleibende Voraussetzung** |

K1b hängt nicht von K1a ab; beide Einheiten können in beliebiger Reihenfolge umgesetzt werden. Die Abstimmung mit Grimmhain-1 sollte trotzdem für alle drei Rollen gemeinsam erfolgen, damit deren Tests nur einmal angepasst werden.

## B · Umfang

| Nr. | Umfang |
|---|---|
| B-1 | `RoleCatalog`: Rolle `selbstmoerder` (Einzelsieg, zählt nicht als Wolf, Erscheinung `selbstmoerder`, ohne Nachtpriorität); keine eigene Obergrenze (RM-DR-016) |
| B-2 | `WinRules.evaluate`: Selbstmörder-Kandidat je Person nach K1B-SIEG-3 (Anspruch gespeichert, tot, aktuelle Rolle `selbstmoerder`). Stabile Reihenfolge nach Personen-ID hinter den bestehenden Kandidaten |
| B-3 | `WinCandidate`: neuer Grund in `REASONS` (Name in der Umsetzung festlegen) |
| B-4 | `WinRules.state_is_consistent`: offene und bestätigte Selbstmörder-Kandidaten müssen zum Zustand passen (AS-K1B-41) |
| B-5 | Gespeicherter Hinrichtungsanspruch je Person (RM-DR-138.6): gesetzt in der Tötungs-Pipeline im Moment eines `LYNCH`-Todes mit aktueller Rolle `selbstmoerder` und mindestens fünf anderen Toten, vor allen Folgen dieses Todes; gelöscht bei `revive` (RM-DR-138.7); nur bei toten Personen zulässig (Ladeprüfung). Erhöht die Schemaversion |
| B-6 | Regelversion erhöhen; Nummern ergeben sich aus dem dann aktuellen Stand |
| B-7 | `godot/README.md`: Rolle, Kandidatengrund, Szenarien |
| B-8 | Headless-Tests für alle Szenarien aus `acceptance-scenarios.md`, zuerst rot, dann grün; alle bestehenden Tests unverändert grün |

## C · Nicht im Umfang

| Nr. | Ausschluss | Grund |
|---|---|---|
| C-1 | Henker-Hinrichtung | RM-DR-138.2, Charge K4 |
| C-2 | Brand des Feuerteufels, Voodoo-Puppe, Liebeskummer | Rollen in späteren Chargen |
| C-3 | Oberflächentexte, Übersetzungsschlüssel, Rollenreihenfolge, UI-Tests | Bereich Grimmhain-1 (§3.7 in `06`) |
| C-4 | Änderungen an `ExecutionRules` | nicht nötig: die Hinrichtung läuft unverändert, der Sieg entsteht nur in der Siegprüfung |
| C-5 | Digitale Stimmen | `../vertical-slice/implementation-boundary.md` D |

## D · Voraussichtlich betroffene Dateien (Regelkern)

`godot/core/rules/role_catalog.gd`, `godot/core/rules/win_rules.gd`, `godot/core/model/win_candidate.gd`, für B-5 `godot/core/model/player.gd`, `godot/core/rules/kill_pipeline.gd`, `godot/core/rules/gm_corrections.gd` (`revive`) und die Serialisierung, neue Tests unter `godot/tests/unit/`. Die Liste ist eine Planungshilfe; maßgeblich ist der Umfang in B.

## E · Abnahme

Alle Szenarien AS-K1B-01 bis AS-K1B-43 grün, alle bestehenden headless Tests grün, Speichern/Laden und bytegleiches Replay, Abstimmung mit Grimmhain-1 erfolgt, `godot/README.md` aktualisiert. Headless-Tests belegen nur den Regelkern, keine Bedienung.
