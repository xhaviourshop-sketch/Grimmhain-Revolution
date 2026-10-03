# Rollen-Setup · Rollen auswählen und verteilen

Stand: 27.09.2026 (Korrekturrunde DR-08) · Godot 4.7.2 · Projekt `godot/`

„Neue Partie“ ist ein Wizard mit vier Schritten: **Spieler → Rollen → Verteilung → Sitzordnung** (Sitzordnung: `seating-setup.md`). Nach dem bestätigten Namensschritt (`player-setup.md`) stellt der Spielleiter einen Rollenpool für genau diese Personenzahl zusammen, verteilt ihn zufällig und reproduzierbar oder manuell und bestätigt die Verteilung. Das Ergebnis bleibt ein Entwurf im Speicher. Erst „Partie starten“ nach der Sitzordnung erzeugt `StartGame` (`game-start.md`); die Schritte hier ändern den Regelkern nicht.

## Schichten

| Schicht | Dateien | Aufgabe |
|---|---|---|
| Katalogadapter | `app/setup/setup_role_catalog.gd` (`SetupRoleCatalog`) | liest Rollen-IDs, Fraktion, `counts_as_wolf`, Nachtpriorität, `max_copies`, Pflicht-Scheinrolle und zulässige Scheinrollen nur aus `RoleCatalog`/`Faction` |
| Darstellungsdaten | `app/setup/role_presentation.gd` (`RolePresentation`) | Übersetzungsschlüssel für Name, Kurzbeschreibung und Fraktion; Reihenfolge in der Oberfläche; keine Regelwirkung |
| Modell | `role_pool_draft.gd`, `role_copy.gd`, `distribution_draft.gd`, `setup_draft.gd` | Rollenanzahlen, Trugbilderwolf-Kopien mit gewählter Scheinrolle, Pool, Verteilung, Seed, Wizard-Schritt, Bestätigungen, Invalidierungsgründe |
| Logik | `role_setup.gd` (`RoleSetup`), `role_suggestion.gd`, `role_distribution.gd` | Operationen und zentrale Invalidierung, Vorschlag, deterministische Verteilung von Verteilungseinheiten |
| Anwendungsschicht | `player_setup.gd` (`PlayerSetup`, `AppContext.setup`) | einzige Schnittstelle der UI; jede Operation atomar mit `SetupResult` |
| Sicht | `setup_distribution_view.gd` | Sicht des Verteilungsschritts (reine Daten) |
| UI | `app/screens/new_game/`: `new_game_screen`, `wizard_progress`, `player_step`, `role_step`, `role_row`, `decoy_section`, `decoy_copy_row`, `distribution_step`, `assignment_row` | Darstellung, Eingabe, Rückfragen; keine Regellogik |

`app/setup/` kennt weder `GameState`, `RulesEngine`, `Command`, `StartGame` noch `GameSession` und enthält keine globale Zufallsquelle und keine Uhr (statisch geprüft).

## Datenmodell

**`SetupDraft`** (bisherige Felder siehe `player-setup.md`)
- `current_step`: `players`, `roles` oder `distribution`
- `players_invalidated`: Personenliste nach einer Bestätigung geändert
- `roles`: `RolePoolDraft`
- `distribution`: `DistributionDraft`

**`RolePoolDraft`**
- `counts: Dictionary[StringName, int]`, jede Katalogrolle, Start 0
- `confirmed`
- `invalidated`: `""`, `roles_changed` oder `person_count_changed`
- `copies: Array[RoleCopy]`, `next_copy_id`: Kopien von Rollen mit Pflicht-Scheinrolle (Trugbilderwolf); ihre Zahl in `counts` entspricht immer der Zahl der Kopien
- `pool()`: kanonische Liste der Rollen-IDs, `entries()`/`keys()`: Verteilungseinheiten, `total()`, `summary()`, `issues(persons)`

**`RoleCopy`**
- `copy_id` (stabil ab 1, nie wiederverwendet, nie als Produkttext gezeigt), `role_id`, `appears_as` (leer = noch nicht festgelegt)
- Verteilungsschlüssel `key()`, z. B. `trugbilderwolf#2`; `role_of(key)` liefert die Rolle
- Sichtbare Bezeichnung „Trugbilderwolf 1, 2, …“ = Position unter den Kopien der Rolle. Seit PE-07 gibt es beim Start höchstens eine Kopie („Trugbilderwolf 1“); das Modell führt weiter eine Liste, mehrere Kopien sind im Setup aber nicht mehr erreichbar (`above_maximum`).

**Verteilungseinheiten** (`RolePoolDraft.entries()`): je Einheit `{key, role_id, appears_as}` in kanonischer Reihenfolge. Normale Rollen haben ihre Rollen-ID als Schlüssel, gleiche Kopien sind austauschbar und brauchen keine Unterscheidung. Jede Trugbilderwolf-Kopie ist eine eigene Einheit aus Rolle und gewählter Scheinrolle. Das entspricht direkt dem Core-Format `role_entries [{role_id, appears_as}]`.

**`DistributionDraft`**
- `mode`: `random` (Standard) oder `manual`
- `assignment: Dictionary[int, StringName]`: Personen-ID → Verteilungseinheit (Rollen-ID oder Kopien-Schlüssel); die Scheinrolle steht nur an der Kopie
- `confirmed`
- `base_seed` (`-1` = noch keiner), `shuffle_count`
- `pool`: die Verteilungseinheiten, für die die Zuordnung gilt
- `invalidated`: `""`, `roles_changed` oder `person_count_changed`

Alle Werte sind reine, speicherbare Daten. Eine Dateispeicherung gibt es noch nicht.

## Rollen und Darstellung

| ID | DE | EN | Fraktion (Katalog) | `counts_as_wolf` |
|---|---|---|---|---|
| `dorfbewohner` | Dorfbewohner | Villager | Dorf | nein |
| `schutzengel` | Schutzengel | Guardian Angel | Dorf | nein |
| `das-orakel` | Das Orakel | The Oracle | Dorf | nein |
| `waldhexe` | Waldhexe | Witch of the Woods | Dorf | nein |
| `sensentraeger` | Sensenträger | Reaper | Dorf | nein |
| `wolfskind` | Wolfskind | Wolf Child | Dorf | nein |
| `lehrling` | Lehrling | Apprentice | Dorf | nein |
| `werwolf` | Werwolf | Werewolf | Werwölfe | ja |
| `spiegelwolf` | Spiegelwolf | Mirror Wolf | Werwölfe | ja |
| `trugbilderwolf` | Trugbilderwolf | Decoy Wolf | Werwölfe | ja |
| `manipulator` | Manipulator | Manipulator | Einzelsieg | nein |

Die Tabelle gibt die Oberflächenreihenfolge wieder: nach Fraktion gruppiert (`RolePresentation.FACTION_ORDER`), darin nach `ROLE_ORDER`. Schlüssel: `ui.role.<id>.name` und `ui.role.<id>.short` (Bindestrich wird zu Unterstrich, z. B. `ui.role.das_orakel.name`) sowie `ui.faction.village|wolves|solo`. `wolfskind` beginnt laut Katalog im Dorf und zählt deshalb im Setup nicht als Wolf.

**Regeln (Paket 5b):** Jede Rollenzeile hat neben der Kurzbeschreibung den Knopf „Regeln“ (`RoleInfoButton_<id>`). Er öffnet den allgemeinen Lexikoneintrag der Rolle als Ebene über dem Setup (`NewGameScreen.open_lexicon`). Rollenwahl, Scheinrollen, Verteilung und Setup-Schritt bleiben unverändert; „Schließen“ und Zurück führen in denselben Setup-Zustand zurück. Der Knopf steht bewusst in der umbrechenden Beschreibungszeile, damit die Zeile bei 1024×768 nicht breiter wird.

## Rollenpool und Validierung

Ein Pool ist gültig, wenn alle folgenden Bedingungen gelten:
- Summe = Personenzahl (`too_few_roles`, `too_many_roles`)
- keine negative Anzahl (`negative_count`) und nur bekannte IDs (`unknown_role`)
- höchstens `copy_limit` Kopien je Rolle (`above_maximum`): Katalog-`max_copies`; seit PE-07 ist das 1, nur Die Gebundenen (`UNLIMITED`) dürfen bis zur Personenzahl vorkommen. Die Grenze gilt für die Startbesetzung (`StartGame`, `role_limit_exceeded`), nicht für gleiche Rollen, die erst im Spiel entstehen. `RolePoolDraft.over_limit(persons)` nennt die Rollen über der Grenze (Sicht: `over_limit`); ein solcher Entwurf wird nie still gekürzt
- mindestens eine Rolle der Fraktion Dorf (`missing_village`)
- mindestens eine Rolle mit `counts_as_wolf` (`missing_wolf`)
- mindestens eine Einzelsiegrolle (`missing_solo`)
- jede Trugbilderwolf-Kopie hat eine ausdrücklich gewählte Scheinrolle (`missing_appearance`)

Die Einzelsiegrolle erkennt der Adapter über `RoleCatalog.faction_of(id) == Faction.SOLO`. Ein fest verdrahteter Rollenname ist nicht nötig, weil der Katalog `manipulator` bereits maschinenlesbar als `solo` führt.

**Kanonischer Pool:**
- jede Kopie einmal
- nach Rollen-ID sortiert, z. B. `["das-orakel", "dorfbewohner", "manipulator", "schutzengel", "waldhexe", "werwolf"]` (6 Personen)
- unabhängig von Eingabereihenfolge und Sprache

## Besetzungshinweise (PE-04)

Nicht blockierende Hinweise im Rollenschritt (Decision Log PE-04, technische Ableitungen DA-47 bis DA-49). Sie sind kein Validierungsfehler, verändern weder `valid` noch `can_confirm`, öffnen keinen Dialog, sperren weder Bestätigen noch Start und ändern die Besetzung nie. `RolePoolDraft.hints(persons)` liefert sie als `roles.hints` in der Sicht; `RoleStep` zeigt je Hinweis eine eigene Zeile am Anfang der scrollbaren Rollenliste (`CoachHintLabel`, `SoloWinsHintLabel`). Die Seitenspalte hat bei 1024×768 keinen Platz dafür.

| Hinweis | Auslösebedingung | Text DE / EN |
|---|---|---|
| `coach_small_round` | mindestens ein `kutscher` und weniger als 13 Personen (Analyse R-07 C-1). `wahnsinniger-kutscher` und `dr-victor-frankenstein` lösen ihn nicht aus | „Hinweis: Der Kutscher kann erst wiederbeleben, wenn mindestens zehn Personen tot sind. Mit weniger als 13 Personen endet die Partie meist vorher. Die Runde wird trotzdem eine Wiederbelebungsrunde (Rollen bleiben beim Tod verdeckt). Starten bleibt möglich.“ / “Note: The Coachman can only revive once at least ten people are dead. With fewer than 13 people, the game usually ends before that. It still becomes a revival round (roles stay hidden on death). You can still start.” |
| `simultaneous_solo_wins` | zusammen mindestens zwei Kopien aus `parasit`, `voodoo-priester`, `grabraeuber`, `manipulator`: Einzelsieg bei höchstens drei Lebenden, Manipulator bei genau drei (Analyse C-3). Andere Einzelsiegrollen lösen ihn nicht aus | „Hinweis: Mehrere Rollen dieser Besetzung gewinnen allein, wenn höchstens drei Personen leben (Parasit, Voodoo-Priester, Grabräuber; Manipulator bei genau drei). Dann können mehrere Siege zugleich erfüllt sein, die Spielleitung bestätigt genau einen. Starten bleibt möglich.“ / “Note: Several roles in this setup win alone when at most three people are alive (Parasite, Voodoo Priest, Grave Robber; Manipulator at exactly three). Several wins can then be met at once, and the game master confirms exactly one. You can still start.” |

Beide Hinweise können gleichzeitig erscheinen. Jede Änderung der Rollenanzahl oder der Personenzahl aktualisiert sie sofort. Sie erscheinen nur im privaten Rollenschritt, nicht in Verteilung, Sitzordnung, Cockpit oder im StartGame-Befehl. Weitere Balancehinweise oder Rollenverbote gibt es nicht. Nachweis: `tests/ui/test_setup_hints.gd`, Layout in `test_role_step::test_role_step_layout`.

## Vorschlag

`RoleSuggestion.for_count(n)` ist eine Setup-Hilfe, keine Spielregel. Die Oberfläche nennt ihn „Vorschlag“ und nicht „ausgewogen“. Seit PE-07 (30.09.2026, Regelversion 0.14) ist er eine feste Liste je Personenzahl von 6 bis 24: keine Füllung mit gleichen Rollen, jede Rolle einmal, kein Zufall, keine Uhr.
1. **Wolfsrollen:** 1, 2, 3, 4, 5 ab 6, 9, 13, 18, 22 Personen, in der Reihenfolge Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf, Besessener Wolf.
2. **Einzelsieg:** genau ein Manipulator (nur im Vorschlag; für manuelle Besetzungen gilt keine neue Pflicht, wohl aber die bestehende Setup-Prüfung „mindestens eine Einzelsiegrolle“).
3. **Dorfrollen:** die ersten `n − Wolfsrollen − 1` der festen Reihenfolge Schutzengel, Orakel, Dorfbewohner, Waldhexe, Dorfwache, Sensenträger, Ritter, Lehrling, Nachtwächter, Wolfskind, Waldläufer, Doktor, Detektiv, Fährtenleser, Der Weise, Dorfchronistin, Wahnsinniger Kutscher, Traumdeuter (18 Einträge, reicht bis 24 Personen).

Rollen-IDs: Orakel = `das-orakel`, Wahnsinniger Kutscher = `wahnsinniger-kutscher` (nicht `kutscher`), Sensenträger = `sensentraeger`, Nachtwächter = `nachtwaechter`, Waldläufer = `waldlaeufer`, Fährtenleser = `faehrtenleser`, Besessener Wolf = `besessener-wolf`, Der Weise = `der-weise`; die übrigen entsprechen ihrem Namen (`test_role_suggestion::test_answer_names_match_catalog_ids`). Beispiel 6 Personen: Werwolf, Manipulator, Schutzengel, Orakel, Dorfbewohner, Waldhexe.

| Personen | Wolfsrollen | Wolfsrollen (in dieser Reihenfolge) | Dorfrollen (die ersten n) |
|---|---|---|---|
| 6 | 1 | Werwolf | 4 |
| 7 | 1 | Werwolf | 5 |
| 8 | 1 | Werwolf | 6 |
| 9 | 2 | Werwolf, Spiegelwolf | 6 |
| 10 | 2 | Werwolf, Spiegelwolf | 7 |
| 11 | 2 | Werwolf, Spiegelwolf | 8 |
| 12 | 2 | Werwolf, Spiegelwolf | 9 |
| 13 | 3 | Werwolf, Spiegelwolf, Trugbilderwolf | 9 |
| 14 | 3 | Werwolf, Spiegelwolf, Trugbilderwolf | 10 |
| 15 | 3 | Werwolf, Spiegelwolf, Trugbilderwolf | 11 |
| 16 | 3 | Werwolf, Spiegelwolf, Trugbilderwolf | 12 |
| 17 | 3 | Werwolf, Spiegelwolf, Trugbilderwolf | 13 |
| 18 | 4 | Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf | 13 |
| 19 | 4 | Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf | 14 |
| 20 | 4 | Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf | 15 |
| 21 | 4 | Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf | 16 |
| 22 | 5 | Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf, Besessener Wolf | 16 |
| 23 | 5 | Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf, Besessener Wolf | 17 |
| 24 | 5 | Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf, Besessener Wolf | 18 |

Ab 13 Personen enthält der Vorschlag den Trugbilderwolf. Seine Scheinrolle belegt das Setup mit einer zufälligen Dorfrolle des Pools vor (DA-88); der Spielleiter kann sie im Dialog ändern. Steht keine Dorfrolle im Pool, bleibt sie offen und der Pool ungültig (`missing_appearance`). Der Vorschlag führt keine Nachtfähigkeit aus. Für jede Personenzahl von 6 bis 24 nimmt der Regelkern den Vorschlag nach Rollenbestätigung, Verteilung und Sitzordnung als Start an (`test_role_suggestion::test_every_proposal_is_a_valid_start_for_the_core`).

`apply_suggestion()` übernimmt ihn direkt, wenn die Auswahl leer ist oder bereits dem Vorschlag entspricht. Weicht eine bestehende Auswahl ab, liefert es `confirmation_required`; die UI fragt dann „Vorschlag übernehmen?“, und Abbrechen ändert nichts. Danach ist alles frei änderbar.

## Abhängigkeiten und Invalidierung

Alle Regeln stehen zentral in `RoleSetup` und laufen als Anwendungsschicht-Operationen, nicht als UI-Rückrufe.

| Ereignis | Rollenpool | Verteilung |
|---|---|---|
| Person hinzufügen, importieren oder entfernen | bestätigter Pool mit unpassender Summe verliert die Bestätigung (`person_count_changed`) | vollständig verworfen (`person_count_changed`); Seed und Mischzähler bleiben |
| Name ändern | bleibt | bleibt an der Personen-ID; der neue Name erscheint |
| Rollenanzahl ändern, zurücksetzen, Vorschlag, Kopie entfernen, Scheinrolle ändern | Bestätigung aufgehoben (`roles_changed`) | vollständig verworfen (`roles_changed`) |
| Pool erneut bestätigen | bestätigt | bleibt nur bei identischen Verteilungseinheiten |
| Neu mischen | unverändert, auch alle Scheinrollen | nur die Personenzuordnung der Einheiten neu |
| Moduswechsel | unverändert | bei bestehender Zuordnung nur nach Rückfrage (`confirmation_required`); dann verworfen |

Jede Personenänderung hebt wie bisher auch die Bestätigung des Namensschritts auf. Ist der aktuelle Schritt danach nicht mehr erreichbar, fällt der Wizard auf den letzten erreichbaren zurück.

## Seed und zufällige Verteilung

**Seed-Erzeugung:**
- Der erste Seed entsteht beim ersten bewussten „Zufällig verteilen“. Die manuelle Verteilung braucht keinen Seed; ihre Zusammenfassung zeigt dann „Seed keiner“.
- Quelle ist `PlayerSetup.seed_source`, standardmäßig `AppPlatform.initial_seed()`: Systemzeit in µs XOR Laufzeitzähler, gebracht auf 1 … `CanonicalJson.MAX_SAFE_INT`.
- Das ist die einzige Stelle mit Uhr, und sie liegt außerhalb von `app/setup/`.
- Der Seed wird als `base_seed` gespeichert und in den technischen Details angezeigt („Seed 20260926 · Mischung 0“).
- Tests setzen eine feste Quelle.

**Verteilung** (`RoleDistribution.random_assignment`):
1. Personen-IDs aufsteigend sortieren.
2. Die kanonischen Verteilungseinheiten mit `SeededRng(effektiver Seed).shuffled()` mischen (Fisher-Yates des Regelkerns). Eine Trugbilderwolf-Kopie wandert dabei samt ihrer Scheinrolle.
3. Paarweise zuordnen.

Die Verteilung nutzt weder globalen Zufall noch eine Uhr. Das Ergebnis hängt nur an Personen-IDs, Pool und Seed, nicht an Listenposition, Name, Sprache oder Neuaufbau.

**Neu mischen:**
- Nur als bewusste Aktion, erhöht `shuffle_count`.
- Effektiver Seed = `base_seed` bei Zählerstand 0, sonst `(base_seed + Zähler × 2654435761) mod MAX_SAFE_INT`.
- Reproduzierbar; dieselbe Permutation ist möglich, und kein Test setzt Verschiedenheit voraus.
- Hebt die Bestätigung der Verteilung auf.
- Ändert nie eine Scheinrolle: Sie hängt an der Kopie, nicht an der Person.

## Manuelle Verteilung

- Jede Person zeigt Nummer, Name und „nicht zugewiesen“ bzw. „zugewiesen“, dazu „Rolle zuweisen“ bzw. „Rolle ändern“ (48 px hoch).
- Die Auswahl ist ein modaler Dialog (`ConfirmDialog` mit `DialogOption`-Liste, Fokussperre, Escape bricht ab). Er bietet:
  - nur Rollen mit freien Kopien („Werwolf · 1 frei“)
  - jede freie Trugbilderwolf-Kopie einzeln („Trugbilderwolf 2 · Scheinrolle: Das Orakel“)
  - „Zuweisung entfernen“
  - „Rolle tauschen mit Nr. …“
- `assign_role(person_id, unit)` nimmt eine Rollen-ID oder den Schlüssel einer konkreten Kopie und lehnt ab: `no_copy_available` (Überbelegung), `copy_required` (Trugbilderwolf ohne konkrete Kopie), `unknown_copy`, `role_not_in_pool`, `unknown_role`, `unknown_person`, `wrong_mode`.
- Weitere Operationen: `unassign_role` (gibt genau die gehaltene Kopie frei), `swap_roles` (auch mit einer nicht zugewiesenen Person; eine Scheinrolle folgt ihrer Kopie).
- Der Restbestand ist öffentlich als Zahl sichtbar („Noch 7 Rollen offen“). Mit Rollennamen erscheint er nur im geöffneten Spielleiterbereich.
- `confirm_distribution` gelingt nur bei vollständiger, exakter Zuordnung (`distribution_incomplete`).

## Trugbilderwolf-Scheinrolle (DR-08)

Der Spielleiter kann die Scheinrolle jeder Trugbilderwolf-Kopie ausdrücklich festlegen (DR-08). Fehlt die Wahl, belegt das Setup sie mit einer zufälligen Dorfrolle des Pools vor (DA-88, SeededRng mit der Seed-Quelle des Setups, Ergebnis in der Kopie gespeichert, `RoleCopy.auto_chosen`). Eine eigene Wahl wird nie überschrieben; vorbelegte Kopien fallen beim Verringern ohne Rückfrage weg.

- **Anlegen:** Plus beim Trugbilderwolf (auch über den Vorschlag) erzeugt eine neue, noch nicht konfigurierte Kopie. Solange eine Kopie keine Scheinrolle hat, ist der Pool ungültig (`missing_appearance`) und „Rollen bestätigen“ gesperrt.
- **Wählen:** `set_decoy_appearance(copy_id, rolle)` akzeptiert jede bekannte Rolle, die nicht als Wolf zählt, auch wenn sie nicht im Pool vorkommt. Abgelehnt werden atomar `empty_appearance`, `unknown_role`, `invalid_appearance` (Wolf) und `unknown_copy`. (Mehrere Kopien mit gleicher oder verschiedener Scheinrolle waren bis PE-07 möglich und sind beim Start nicht mehr erreichbar.)
- **Entfernen:** Minus entfernt die letzte *unkonfigurierte* Kopie ohne Rückfrage. Ist keine unkonfigurierte übrig, fragt die Oberfläche „Kopie entfernen?“ und nennt „Trugbilderwolf N“ (`confirmation_required` mit `copy_id` und `number`). Jede Kopie hat zusätzlich „Entfernen“ (`remove_decoy_copy`). Übrige Kopien behalten Kopien-ID und Scheinrolle; die sichtbaren Nummern zählen neu.
- **Vorschlag und Zurücksetzen:** Der Vorschlag behält vorhandene Kopien samt Scheinrolle, soweit er Trugbilderwölfe vorsieht, und legt fehlende unkonfiguriert an. Zurücksetzen entfernt alle Kopien.
- **Invalidierung:** Eine geänderte Scheinrolle hebt Rollen- und Verteilungsbestätigung auf und verwirft die Verteilung. Dieselbe Scheinrolle erneut zu wählen ändert nichts. Umbenennen, Sprachwechsel und Navigation erhalten alles.
- **Verteilung:** Zufällig, Neu mischen, manuelles Zuweisen und Tauschen bewegen die ganze Kopie; die Person trägt immer die Scheinrolle ihrer Kopie.

**Oberfläche:**
- Direkt unter der Trugbilderwolf-Zeile steht der Bereich `DecoySection`. Öffentlich zeigt er nur „Scheinrollen festgelegt: 1 von 2“ (als Hinweis hervorgehoben, solange etwas fehlt) und „Scheinrollen festlegen“.
- Erst nach bewusstem Öffnen erscheint der als „Geheim · nur für die Spielleitung“ markierte Bereich. Er enthält je Kopie „Trugbilderwolf 1“, „Scheinrolle: Waldhexe“ oder „Scheinrolle fehlt“, „Wählen“ bzw. „Ändern“ und „Entfernen“.
- Die Wahl läuft über den modalen Dialog „Scheinrolle wählen“ mit allen Nicht-Wolf-Rollen (lokalisiert, die aktuelle als „· aktuell“). Es gelten Fokussperre und Escape.
- Schließen oder Verlassen des Schritts blendet den Bereich aus; liegt der Fokus darin, wandert er auf „Scheinrollen festlegen“.
- In der Verteilung zeigt der geöffnete Spielleiterbereich „Scheinrolle: …“.

**StartGame-Abbildung (gebaut, `game-start.md`):** Die im Setup bestätigte Zuordnung wird unverändert als manueller Aufbau übernommen: `roles {"<Personen-ID>": role_id}` und `appearances {"<Personen-ID>": appears_as}` aus Zuordnung und Kopie. Beim Start wird nicht erneut gemischt; ein zweiter Zufallsalgorithmus entsteht nicht.

## Geheimhaltung

- Die Standardansicht der Verteilung zeigt je Person nur „zugewiesen“ oder „nicht zugewiesen“.
- Rollen und Scheinrollen erscheinen nur im bewusst geöffneten Bereich „Geheim · nur für die Spielleitung“ (Verteilung: `AssignmentPanel` mit `SecretHeading`; Rollenschritt: `DecoySecretPanel`) und in den modalen Auswahldialogen.
- Beim Verlassen des Schritts schließen sich beide Bereiche wieder.
- Eine dauerhafte Warnung steht im Schritt: „Rollen sind geheim: nicht vor Mitspielenden zeigen.“
- Toasts („Rollen verteilt“, „Neu gemischt“, „Verteilung bestätigt“), Status, Fortschrittsanzeige, Dialogtitel, Tooltips und Screen-IDs nennen weder Rolle noch Scheinrolle. `test_distribution_step` und `test_decoy_step` prüfen das nach jeder Aktion gegen alle DE/EN-Rollennamen.

## Wizard-Navigation

- **Schrittanzeige** unter der Kopfzeile (`WizardProgress`, Fließlayout): „Schritt 2 von 3: Rollen“, dazu je Schritt ein Textchip wie „1. Spieler · erledigt“. Zustände sind `erledigt`, `offen` und `neu prüfen`; der aktuelle Schritt ist farbig hervorgehoben und steht zusätzlich als Text da.
- **Spieler → Rollen:** nur mit bestätigter, gültiger Liste über „Weiter zu den Rollen“ in der Bestätigungskarte.
- **Rollen → Verteilung:** nur über „Rollen bestätigen“ mit gültigem Pool.
- **Schrittwechsel:** `PlayerSetup.go_to_step()` prüft die Vorbedingungen (`players_not_confirmed`, `roles_not_confirmed`). Schritte haben keine eigenen Screen-IDs, ein Doppelklick überspringt nichts, und kein Wechsel erzeugt einen Befehl.
- **Zurück, Escape, System-Zurück:** Sitzordnung → Verteilung → Rollen → Spieler. Im Spielerschritt gilt die bestehende Rückfrage „Weiter bearbeiten / Entwurf behalten / Entwurf verwerfen“. Sie erscheint jetzt auch bei unbestätigter Rollenwahl oder unbestätigter Zuordnung.
- **Erneutes Öffnen:** Der Wizard öffnet im zuletzt aktiven Schritt.

## Bestätigungen

**„Rollen bestätigen“:**
- nur mit gültigem Pool und bestätigter Personenliste
- setzt `roles.confirmed` und wechselt zur Verteilung

**„Verteilung bestätigen“:**
- nur bei vollständiger Zuordnung
- setzt `distribution.confirmed`
- zeigt die Karte „Bereit für Sitzordnung“: Personen, Rollen nach Fraktion, Modus und Seed, dazu „Weiter zur Sitzordnung“

Beide Bestätigungen erzeugen kein `StartGame`, keinen `GameState` und keinen Befehl; `GameSession` bleibt unberührt, was Tests belegen. Jede spätere passende Änderung hebt die Bestätigung auf.

## Öffentliche API (`PlayerSetup`)

| Methode | Fehlercodes |
|---|---|
| `go_to_step(step)` | `unknown_step`, `players_not_confirmed`, `roles_not_confirmed` |
| `set_role_count(role, count)`, `change_role_count(role, delta)` | `unknown_role`, `negative_count`, `above_maximum`, `confirmation_required` (konfigurierte Kopie; Details `copy_id`, `number`) |
| `set_decoy_appearance(copy_id, role)` | `unknown_copy`, `empty_appearance`, `unknown_role`, `invalid_appearance` |
| `remove_decoy_copy(copy_id)` | `unknown_copy` |
| `reset_roles()` | – |
| `apply_suggestion(force = false)` | `confirmation_required`, `too_few_persons`, `too_many_persons` |
| `confirm_roles()` | `players_not_confirmed`, `roles_invalid` (Details: `issues`) |
| `set_distribution_mode(mode, force = false)` | `unknown_mode`, `confirmation_required` |
| `distribute_randomly()` | `players_not_confirmed`, `roles_not_confirmed`, `wrong_mode`, `no_seed_source`, `invalid_seed` |
| `reshuffle()` | wie oben, `nothing_to_reshuffle` |
| `assign_role(person_id, unit)`, `unassign_role(person_id)`, `swap_roles(a, b)` | `wrong_mode`, `unknown_person`, `unknown_role`, `copy_required`, `unknown_copy`, `role_not_in_pool`, `no_copy_available` |
| `confirm_distribution()` | `distribution_incomplete` und die Vorbedingungen |

- **Eigenschaft:** `seed_source: Callable`.
- **Signal:** `changed(view)`, auch nach einem Schrittwechsel.
- **Sicht `view()`:** ergänzt um `step`, `steps` (`id`, `number`, `state`, `current`, `reachable`), `roles` (`counts`, `total`, `persons`, `free`, `valid`, `issues`, `confirmed`, `can_confirm`, `invalidated`, `pool`, `factions`, `wolf_count`, `limits`, `can_increase`, `can_decrease`, `is_empty`, `is_suggestion`, `decoys` [`copy_id`, `number`, `key`, `role_id`, `appears_as`, `configured`], `entries`, `appearance_options`) und `distribution` (`mode`, `assignment` [`person_id`, `number`, `name`, `role`, `copy_key`, `copy_number`, `appearance`], `assigned_count`, `person_count`, `role_count`, `remaining`, `remaining_keys`, `remaining_copies`, `remaining_total`, `complete`, `has_assignment`, `confirmed`, `can_confirm`, `invalidated`, `has_seed`, `seed`, `effective_seed`, `shuffle_count`, `factions`, `ready_for_seating`).

**Neue UI-Bausteine:**
- `DialogOption` und `DialogRequest.options`/`title_values` (Auswahlliste im modalen Dialog; ohne `confirm_key` keine Bestätigungsaktion)
- `GrimmButton.format_values`

## Tests und Screenshots

```bash
godot/tests/run_all.sh --filter=test_role           # Rollenmodell, Vorschlag, Rollenwahl-UI
godot/tests/run_all.sh --filter=test_distribution   # Verteilungsmodell, Verteilungs-UI, Geheimhaltung
godot/tests/run_all.sh --filter=test_decoy          # Trugbilderwolf-Scheinrolle (DR-08)
xvfb-run -a -s "-screen 0 1920x1080x24" <godot-4.7.2> --path godot --rendering-driver opengl3 \
  --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- --only=role-setup
```

| Testdatei | Inhalt |
|---|---|
| `tests/ui/test_role_model.gd` | Katalogadapter gegen `RoleCatalog`, Darstellungsschlüssel DE/EN, Plus/Minus mit Höchstzahl 1 (PE-07) und Ausnahme Die Gebundenen, Validierung, kanonischer Pool, Schrittsperren, Vorschlag 6 bis 24, Überschreiben nur mit Bestätigung, Personenänderungen, kein Zufall und keine Uhr in `app/setup/` |
| `tests/ui/test_role_suggestion.gd` | PE-07: fester Vorschlag für 6 bis 24 Personen (Wolfsstufen und Schwellen 8→9, 12→13, 17→18, 21→22, genau ein Manipulator, Reihenfolgen, keine Dublette), Namen der Antwort gegen Katalog-IDs, jeder Vorschlag ist über das Setup ein gültiger `StartGame` |
| `tests/ui/test_role_step.gd` | Schrittanzeige und Sperren, Doppelklick, Zurück und Navigation erhalten Daten, Verlassen-Rückfrage, Rollenzeilen mit Katalogdaten und Gruppen, Zähler und Fehler, „Nur einmal zu Spielbeginn“ (DE/EN), Entwurf über der Höchstzahl (Namen im Listenkopf, nicht gekürzt, Start gesperrt, Layout 1024×768), Überschreib-Dialog, kein GameState/StartGame, Layout 1024×768/1280×800 EN/1920×1080, Scrollen, Schlüssel |
| `tests/ui/test_distribution_model.gd` | Vollständigkeit, Reproduzierbarkeit, Personen-ID statt Reihenfolge, Neuaufbau/Sprache/Name, Neu mischen, Bestätigen, Invalidierung, manuelle Zuweisung, Moduswechsel, ausdrücklich gewählte Trugbilderwolf-Scheinrolle, mehrere Kopien einer Rolle nur bei Den Gebundenen |
| `tests/ui/test_decoy_model.gd` | DR-08/DA-88: Vorbelegung aus dem Pool, ohne Dorfrolle weiter gesperrt, Validierung, eine Kopie anlegen, konfigurieren und entfernen (zweite Kopie abgelehnt), Vorschlag und Zurücksetzen, Kopie als Einheit beim Verteilen, Neu mischen, manuell und Tauschen, Invalidierung, Name und Sprache, kein abgeleiteter Code |
| `tests/ui/test_decoy_step.gd` | Scheinrollen-Bereich: fehlende Wahl sichtbar, Öffnen und Schließen mit Fokusabgabe, modaler Dialog, Entfernen der konfigurierten Kopie mit Rückfrage, Anzeige in der Verteilung, Kopienwahl im Dialog, Geheimhaltung, kein GameState/StartGame, Layout 1024×768/1280×800 DE/EN |
| `tests/ui/test_setup_hints.gd` | PE-04: Kutscher-Schwelle 12/13, ohne Kutscher kein Hinweis, belegte Siegüberschneidung, Kontrollbesetzungen ohne Fehlalarm, beide Hinweise zugleich, Gültigkeit unverändert, sofortige Aktualisierung bei Rollen- und Personenänderung, DE/EN, StartGame mit denselben Rollen und Zuordnungen, keine Hinweise im Cockpit |
| `tests/ui/test_distribution_step.gd` | verborgene Rollen, geheimer Bereich, Seed, Neu mischen, Zusammenfassung ohne Partie, manuelle Auswahl im modalen Dialog mit Fokussperre, Moduswechsel-Rückfrage, Layout, Scrollen |

Prüf-Screenshots: `docs/evidence/role-setup/`.

## Bewusst noch nicht enthalten

- Rollenübergabe an Spieler, öffentliche Rollenanzeige
- Speichern des Entwurfs, gespeicherte Gruppen, Undo/Redo
