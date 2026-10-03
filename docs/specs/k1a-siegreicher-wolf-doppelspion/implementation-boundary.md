# K1a · Umsetzungsgrenze · Siegreicher Wolf und Doppelspion

**Stand:** 2026-10-03 · **Status:** Spezifikation, nicht umgesetzt; Freigabe durch den Product Owner ausstehend
**Regeln:** `rules-register.md` · **Szenarien:** `acceptance-scenarios.md` · **Planung:** `../../role-migration/06-implementation-batches.md` §3

Pfade relativ zu `docs/specs/k1a-siegreicher-wolf-doppelspion/`. Diese Datei legt fest, was die Umsetzung von K1a baut und was nicht.

## A · Voraussetzungen

| Nr. | Voraussetzung | Stand |
|---|---|---|
| A-1 | Produktentscheidungen RM-DR-155.1, .3, .4 und Bestätigung des Siegreichen Wolfs im Decision Log | erfüllt (3. Oktober 2026) |
| A-2 | Freigabe dieses Regelregisters (DE/EN) durch den Product Owner | offen |
| A-3 | Abstimmung mit Grimmhain-1 über die Katalogerweiterung (`../../role-migration/06-implementation-batches.md` §3.7) | offen |
| A-4 | RM-DR-155.6 (Mitzeigen am Tisch) | offen; blockiert nur den Ansagetext, nicht den Regelkern |

## B · Umfang

| Nr. | Umfang |
|---|---|
| B-1 | `RoleCatalog`: Rollen `siegreicher-wolf` (Werwölfe, zählt als Wolf, Erscheinung `siegreicher-wolf`, ohne Nachtpriorität) und `doppelspion` (Einzelsieg, zählt nicht als Wolf, Erscheinung `doppelspion`, ohne Nachtpriorität); keine eigene Obergrenze (RM-DR-016) |
| B-2 | `WinRules.evaluate`: Gewicht nach K1-SIEG-1/2; Doppelspion-Kandidaten nach K1-SIEG-3; kein Dorfkandidat nach K1-SIEG-4. Stabile Reihenfolge: Dorf, Werwölfe, Manipulatoren nach Personen-ID, Doppelspione nach Personen-ID |
| B-3 | `WinCandidate`: neuer Grund für den Doppelspion-Kandidaten in `REASONS` (Name in der Umsetzung festlegen, Muster `manipulator_three_alive`) |
| B-4 | `WinRules.state_is_consistent`: offene und bestätigte Doppelspion-Kandidaten müssen zum Zustand passen (Person lebt, hat die Rolle, kein Wolf lebt); ein offener Dorfkandidat ist ungültig, solange ein Doppelspion lebt |
| B-5 | Rudelschritt: dem Spielleiter sichtbare Angabe der lebenden Doppelspione als mitaufwachende Personen; keine Teilnahme an der gespeicherten Wahl; keine Spieler-Projektion |
| B-6 | Regelversion erhöhen. Schemaversion nur, falls ein gespeichertes Feld hinzukommt (die Angabe aus B-5 wird voraussichtlich nicht gespeichert, sondern aus dem Zustand berechnet). Die Nummern ergeben sich aus dem dann aktuellen Stand |
| B-7 | `godot/README.md`: Rollenliste, Kandidatengründe, Szenarien |
| B-8 | Headless-Tests für alle Szenarien aus `acceptance-scenarios.md`, zuerst rot, dann grün; alle bestehenden Tests unverändert grün |

## C · Nicht im Umfang

| Nr. | Ausschluss | Grund |
|---|---|---|
| C-1 | Wirkung des Rachsüchtigen Wolfs auf den Doppelspion | Rolle `rachsuechtiger-wolf` erst in Charge K11 |
| C-2 | Wirkung des Dämonischen Wolfs (Fluch) | Rolle nicht im Katalog |
| C-3 | Gewicht des Siegreichen Wolfs in Zählungen anderer Rollen (z. B. Waldläufer) | K1-SIEG-2: dort zählt er als eine Person; Umsetzung mit der jeweiligen Rolle |
| C-4 | Oberflächentexte, Übersetzungsschlüssel, Rollenreihenfolge, UI-Tests | Bereich Grimmhain-1 (§3.7 in `06`) |
| C-5 | Ansagetext für das Mitzeigen | RM-DR-155.6 offen |
| C-6 | Setup-Vorschlag mit Doppelspion | Oberflächenfrage für Grimmhain-1 |
| C-7 | Digitale Stimmen | `../vertical-slice/implementation-boundary.md` D |

## D · Voraussichtlich betroffene Dateien (Regelkern)

`godot/core/rules/role_catalog.gd`, `godot/core/rules/win_rules.gd`, `godot/core/model/win_candidate.gd`, `godot/core/rules/step_queue.gd` (Angabe im Rudelschritt), die Regelversion in der Serialisierung, neue Tests unter `godot/tests/unit/`. Die Liste ist eine Planungshilfe; maßgeblich ist der Umfang in B.

## E · Abnahme

Alle Szenarien AS-K1A-01 bis AS-K1A-37 grün, alle bestehenden headless Tests grün, Speichern/Laden und bytegleiches Replay für jedes Szenario mit Kandidat, Abstimmung mit Grimmhain-1 erfolgt, `godot/README.md` aktualisiert. Headless-Tests belegen nur den Regelkern, keine Bedienung.
