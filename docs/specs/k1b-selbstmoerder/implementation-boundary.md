# K1b · Umsetzungsgrenze · Selbstmörder

**Stand:** 2026-10-03 · **Status:** Spezifikation, nicht umgesetzt; Umsetzung blockiert durch RM-DR-138.6 und RM-DR-138.7
**Regeln:** `rules-register.md` · **Szenarien:** `acceptance-scenarios.md` · **Planung:** `../../role-migration/06-implementation-batches.md` §3

Pfade relativ zu `docs/specs/k1b-selbstmoerder/`. Diese Datei legt fest, was die Umsetzung von K1b baut und was nicht.

## A · Voraussetzungen

| Nr. | Voraussetzung | Stand |
|---|---|---|
| A-1 | Produktentscheidungen RM-DR-138.1, .3, .4 im Decision Log | erfüllt (3. Oktober 2026) |
| A-2 | RM-DR-138.6 (späterer Sieg nach früher Hinrichtung) | **offen**, blockiert die Siegbedingung |
| A-3 | RM-DR-138.7 (Anspruch nach eigener Wiederbelebung) | **offen**, blockiert nur diesen Sonderfall und die Ladeprüfung (b) |
| A-4 | Freigabe dieses Regelregisters (DE/EN) durch den Product Owner | offen |
| A-5 | Abstimmung mit Grimmhain-1 über die Katalogerweiterung (`../../role-migration/06-implementation-batches.md` §3.7) | offen |

K1b hängt nicht von K1a ab; beide Einheiten können in beliebiger Reihenfolge umgesetzt werden. Die Abstimmung mit Grimmhain-1 sollte trotzdem für alle drei Rollen gemeinsam erfolgen, damit deren Tests nur einmal angepasst werden.

## B · Umfang

| Nr. | Umfang |
|---|---|
| B-1 | `RoleCatalog`: Rolle `selbstmoerder` (Einzelsieg, zählt nicht als Wolf, Erscheinung `selbstmoerder`, ohne Nachtpriorität); keine eigene Obergrenze (RM-DR-016) |
| B-2 | `WinRules.evaluate`: Selbstmörder-Kandidat je Person nach K1B-SIEG-1 bis K1B-SIEG-4, aus dem Zustand bei der verbindlichen Prüfung (Rolle, `Player.death` mit Ursache `LYNCH`, Zahl der anderen Toten). Stabile Reihenfolge nach Personen-ID hinter den bestehenden Kandidaten |
| B-3 | `WinCandidate`: neuer Grund in `REASONS` (Name in der Umsetzung festlegen) |
| B-4 | `WinRules.state_is_consistent`: offene und bestätigte Selbstmörder-Kandidaten müssen zum Zustand passen (AS-K1B-41) |
| B-5 | Nur falls RM-DR-138.6 = B oder RM-DR-138.7 = B: ein gespeicherter Wert je Person (B: „Bedingung bei der ersten Prüfung nach der Hinrichtung erfüllt“ bzw. „wurde hingerichtet“), mit Ladeprüfung und Erhöhung der Schemaversion. Bei A und A ist kein neues Feld nötig, weil RM-DR-138.3 die Totenzahl bei der Prüfung zählt und `Player.death` die Ursache bereits speichert |
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

`godot/core/rules/role_catalog.gd`, `godot/core/rules/win_rules.gd`, `godot/core/model/win_candidate.gd`, bei B-5 zusätzlich `godot/core/model/player.gd` und die Serialisierung, neue Tests unter `godot/tests/unit/`. Die Liste ist eine Planungshilfe; maßgeblich ist der Umfang in B.

## E · Abnahme

Alle Szenarien AS-K1B-01 bis AS-K1B-42 grün (AS-K1B-30 und -31 nach der Antwort festgeschrieben), alle bestehenden headless Tests grün, Speichern/Laden und bytegleiches Replay, Abstimmung mit Grimmhain-1 erfolgt, `godot/README.md` aktualisiert. Headless-Tests belegen nur den Regelkern, keine Bedienung.
