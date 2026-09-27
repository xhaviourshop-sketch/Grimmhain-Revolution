# Rollen-Setup · Rollen auswählen und verteilen

Stand: 27.09.2026 · Godot 4.7.2 · Projekt `godot/`

„Neue Partie“ ist ein Wizard mit drei Schritten: **Spieler → Rollen → Verteilung**. Nach dem bestätigten Namensschritt (`player-setup.md`) stellt der Spielleiter einen Rollenpool für genau diese Personenzahl zusammen, verteilt ihn zufällig und reproduzierbar oder manuell und bestätigt die Verteilung. Das Ergebnis bleibt ein Entwurf im Speicher. Es entsteht weder `StartGame` noch ein `GameState`, und der Regelkern bleibt unverändert.

## Schichten

| Schicht | Dateien | Aufgabe |
|---|---|---|
| Katalogadapter | `app/setup/setup_role_catalog.gd` (`SetupRoleCatalog`) | liest Rollen-IDs, Fraktion, `counts_as_wolf`, Nachtpriorität, `max_copies`, Pflicht-Scheinrolle und zulässige Scheinrollen nur aus `RoleCatalog`/`Faction` |
| Darstellungsdaten | `app/setup/role_presentation.gd` (`RolePresentation`) | Übersetzungsschlüssel für Name, Kurzbeschreibung und Fraktion; Reihenfolge in der Oberfläche; keine Regelwirkung |
| Modell | `role_pool_draft.gd`, `distribution_draft.gd`, `setup_draft.gd` | Rollenanzahlen, Pool, Verteilung, Seed, Wizard-Schritt, Bestätigungen, Invalidierungsgründe |
| Logik | `role_setup.gd` (`RoleSetup`), `role_suggestion.gd`, `role_distribution.gd` | Operationen und zentrale Invalidierung, Vorschlag, deterministische Verteilung und Scheinrollen |
| Anwendungsschicht | `player_setup.gd` (`PlayerSetup`, `AppContext.setup`) | einzige Schnittstelle der UI; jede Operation atomar mit `SetupResult` |
| Sicht | `setup_distribution_view.gd` | Sicht des Verteilungsschritts (reine Daten) |
| UI | `app/screens/new_game/`: `new_game_screen`, `wizard_progress`, `player_step`, `role_step`, `role_row`, `distribution_step`, `assignment_row` | Darstellung, Eingabe, Rückfragen; keine Regellogik |

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
- `pool()`: kanonische Liste, `total()`, `summary()`, `issues(persons)`

**`DistributionDraft`**
- `mode`: `random` (Standard) oder `manual`
- `assignment: Dictionary[int, StringName]`: Personen-ID → Rollen-ID
- `appearances: Dictionary[int, StringName]`: Personen-ID → vorbereitete Scheinrolle, nur für Rollen mit Pflicht-Scheinrolle
- `confirmed`
- `base_seed` (`-1` = noch keiner), `shuffle_count`
- `pool`: der Pool, für den die Zuordnung gilt
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

## Rollenpool und Validierung

Ein Pool ist gültig, wenn alle folgenden Bedingungen gelten:
- Summe = Personenzahl (`too_few_roles`, `too_many_roles`)
- keine negative Anzahl (`negative_count`) und nur bekannte IDs (`unknown_role`)
- höchstens `copy_limit` Kopien je Rolle (`above_maximum`): Katalog-`max_copies`, bei `UNLIMITED` die Personenzahl
- mindestens eine Rolle der Fraktion Dorf (`missing_village`)
- mindestens eine Rolle mit `counts_as_wolf` (`missing_wolf`)
- mindestens eine Einzelsiegrolle (`missing_solo`)

Die Einzelsiegrolle erkennt der Adapter über `RoleCatalog.faction_of(id) == Faction.SOLO`. Ein fest verdrahteter Rollenname ist nicht nötig, weil der Katalog `manipulator` bereits maschinenlesbar als `solo` führt.

**Kanonischer Pool:**
- jede Kopie einmal
- nach Rollen-ID sortiert, z. B. `["dorfbewohner", "dorfbewohner", "manipulator", "schutzengel", "werwolf", …]`
- unabhängig von Eingabereihenfolge und Sprache

## Vorschlag

`RoleSuggestion.for_count(n)` ist eine Setup-Hilfe, keine Spielregel. Die Oberfläche nennt ihn „Vorschlag“ und nicht „ausgewogen“. Der Vorschlag ist deterministisch und kommt ohne Zufall aus:
1. **Wölfe:** 6–8 → 1, 9–12 → 2, 13–17 → 3, 18–21 → 4, 22–24 → 5, in der Reihenfolge Werwolf, Spiegelwolf, Werwolf, Trugbilderwolf, Werwolf
2. **Einzelsieg:** genau ein Manipulator
3. **Sonderrollen des Dorfs:** (n − Wölfe − 1) / 2, höchstens 6, in der Reihenfolge Schutzengel, Das Orakel, Waldhexe, Sensenträger, Lehrling, Wolfskind
4. **Rest:** Dorfbewohner

| n | Zusammensetzung |
|---|---|
| 6 | 1 Werwolf, 1 Manipulator, Schutzengel, Orakel, 2 Dorfbewohner |
| 7 | 1 Werwolf, 1 Manipulator, Schutzengel, Orakel, 3 Dorfbewohner |
| 8 | 1 Werwolf, 1 Manipulator, Schutzengel, Orakel, Waldhexe, 3 Dorfbewohner |
| 9 | Werwolf, Spiegelwolf, Manipulator, Schutzengel, Orakel, Waldhexe, 3 Dorfbewohner |
| 10 | wie 9, 4 Dorfbewohner |
| 11 | wie 9 + Sensenträger, 4 Dorfbewohner |
| 12 | wie 11, 5 Dorfbewohner |
| 13 | 2 Werwölfe, Spiegelwolf, Manipulator, Schutzengel, Orakel, Waldhexe, Sensenträger, 5 Dorfbewohner |
| 14 | wie 13 + Lehrling, 5 Dorfbewohner |
| 15 | wie 14, 6 Dorfbewohner |
| 16 | wie 14 + Wolfskind, 6 Dorfbewohner |
| 17 | wie 16, 7 Dorfbewohner |
| 18 | 2 Werwölfe, Spiegelwolf, Trugbilderwolf, Manipulator, alle 6 Sonderrollen, 7 Dorfbewohner |
| 19–21 | wie 18, 8 bis 10 Dorfbewohner |
| 22 | 3 Werwölfe, Spiegelwolf, Trugbilderwolf, Manipulator, alle 6 Sonderrollen, 10 Dorfbewohner |
| 23–24 | wie 22, 11 bzw. 12 Dorfbewohner |

`apply_suggestion()` übernimmt ihn direkt, wenn die Auswahl leer ist oder bereits dem Vorschlag entspricht. Weicht eine bestehende Auswahl ab, liefert es `confirmation_required`; die UI fragt dann „Vorschlag übernehmen?“, und Abbrechen ändert nichts. Danach ist alles frei änderbar.

## Abhängigkeiten und Invalidierung

Alle Regeln stehen zentral in `RoleSetup` und laufen als Anwendungsschicht-Operationen, nicht als UI-Rückrufe.

| Ereignis | Rollenpool | Verteilung |
|---|---|---|
| Person hinzufügen, importieren oder entfernen | bestätigter Pool mit unpassender Summe verliert die Bestätigung (`person_count_changed`) | vollständig verworfen (`person_count_changed`); Seed und Mischzähler bleiben |
| Name ändern | bleibt | bleibt an der Personen-ID; der neue Name erscheint |
| Rollenanzahl ändern, zurücksetzen, Vorschlag | Bestätigung aufgehoben (`roles_changed`) | vollständig verworfen (`roles_changed`) |
| Pool erneut bestätigen | bestätigt | bleibt nur bei identischem kanonischen Pool |
| Neu mischen | unverändert | nur zufällige Zuordnung und Scheinrollen neu |
| Moduswechsel | unverändert | bei bestehender Zuordnung nur nach Rückfrage (`confirmation_required`); dann verworfen |

Jede Personenänderung hebt wie bisher auch die Bestätigung des Namensschritts auf. Ist der aktuelle Schritt danach nicht mehr erreichbar, fällt der Wizard auf den letzten erreichbaren zurück.

## Seed und zufällige Verteilung

**Seed-Erzeugung:**
- Der erste Seed entsteht beim ersten bewussten „Zufällig verteilen“ oder bei der ersten vollständigen manuellen Zuordnung.
- Quelle ist `PlayerSetup.seed_source`, standardmäßig `AppPlatform.initial_seed()`: Systemzeit in µs XOR Laufzeitzähler, gebracht auf 1 … `CanonicalJson.MAX_SAFE_INT`.
- Das ist die einzige Stelle mit Uhr, und sie liegt außerhalb von `app/setup/`.
- Der Seed wird als `base_seed` gespeichert und in den technischen Details angezeigt („Seed 20260926 · Mischung 0“).
- Tests setzen eine feste Quelle.

**Verteilung** (`RoleDistribution.random_assignment`):
1. Personen-IDs aufsteigend sortieren.
2. Den kanonischen Pool mit `SeededRng(effektiver Seed).shuffled()` mischen (Fisher-Yates des Regelkerns).
3. Paarweise zuordnen.

Die Verteilung nutzt weder globalen Zufall noch eine Uhr. Das Ergebnis hängt nur an Personen-IDs, Pool und Seed, nicht an Listenposition, Name, Sprache oder Neuaufbau.

**Neu mischen:**
- Nur als bewusste Aktion, erhöht `shuffle_count`.
- Effektiver Seed = `base_seed` bei Zählerstand 0, sonst `(base_seed + Zähler × 2654435761) mod MAX_SAFE_INT`.
- Reproduzierbar; dieselbe Permutation ist möglich, und kein Test setzt Verschiedenheit voraus.
- Hebt die Bestätigung der Verteilung auf.

## Manuelle Verteilung

- Jede Person zeigt Nummer, Name und „nicht zugewiesen“ bzw. „zugewiesen“, dazu „Rolle zuweisen“ bzw. „Rolle ändern“ (48 px hoch).
- Die Auswahl ist ein modaler Dialog (`ConfirmDialog` mit `DialogOption`-Liste, Fokussperre, Escape bricht ab). Er bietet:
  - nur Rollen mit freien Kopien („Werwolf · 1 frei“)
  - „Zuweisung entfernen“
  - „Rolle tauschen mit Nr. …“
- `assign_role` lehnt ab: `no_copy_available` (Überbelegung), `role_not_in_pool`, `unknown_role`, `unknown_person`, `wrong_mode`.
- Weitere Operationen: `unassign_role`, `swap_roles` (auch mit einer nicht zugewiesenen Person).
- Der Restbestand ist öffentlich als Zahl sichtbar („Noch 7 Rollen offen“). Mit Rollennamen erscheint er nur im geöffneten Spielleiterbereich.
- `confirm_distribution` gelingt nur bei vollständiger, exakter Zuordnung (`distribution_incomplete`).

## Trugbilderwolf-Scheinrolle

Für jede Person mit Pflicht-Scheinrolle (`RoleCatalog.requires_appearance`) bereitet der Entwurf eine Scheinrolle vor:
- **Herleitung:** `SeededRng(mix(effektiver Seed, 1000003 + Personen-ID))` wählt aus `SetupRoleCatalog.appearance_options()`, also den kanonisch sortierten Rollen, die bekannt sind und nicht als Wolf zählen. Das Ergebnis ist nie leer.
- **Stabilität:** Die Scheinrolle hängt an der Personen-ID und bleibt bei Umbenennen gleich. Neu mischen berechnet sie neu. Manuell entsteht sie, sobald die Zuordnung vollständig ist.
- **Sichtbarkeit:** nur im geöffneten Spielleiterbereich, als „Scheinrolle: Lehrling (vorläufig)“. Eine manuelle Wahl gibt es noch nicht.

**Offener Widerspruch zu DR-08:** Laut Entscheidungslog legt der Spielleiter die Scheinrolle fest, „nie zufällig“. Dieser Auftrag verlangt dagegen eine aus dem Seed abgeleitete Vorbelegung. Deshalb ist sie ausdrücklich als *vorläufig* markiert. Der Regelkern bleibt unberührt, weil `StartGame` die Scheinrolle weiterhin explizit über `appearances` bekommt. Vor der StartGame-Integration muss entschieden werden, ob der Spielleiter die Vorbelegung bestätigen oder ändern muss.

## Geheimhaltung

- Die Standardansicht der Verteilung zeigt je Person nur „zugewiesen“ oder „nicht zugewiesen“.
- Rollen und Scheinrollen erscheinen nur im bewusst geöffneten Bereich „Geheim · nur für die Spielleitung“ (`AssignmentPanel` mit `SecretHeading`, eigener Rahmen) und in der modalen Rollenauswahl.
- Beim Verlassen des Schritts schließt sich der Bereich wieder.
- Eine dauerhafte Warnung steht im Schritt: „Rollen sind geheim: nicht vor Mitspielenden zeigen.“
- Toasts („Rollen verteilt“, „Neu gemischt“, „Verteilung bestätigt“), Status, Dialogtitel, Tooltips und Screen-IDs nennen keine Rolle. `test_distribution_step` prüft das nach jeder Aktion gegen alle DE/EN-Rollennamen.

## Wizard-Navigation

- **Schrittanzeige** unter der Kopfzeile (`WizardProgress`, Fließlayout): „Schritt 2 von 3: Rollen“, dazu je Schritt ein Textchip wie „1. Spieler · erledigt“. Zustände sind `erledigt`, `offen` und `neu prüfen`; der aktuelle Schritt ist farbig hervorgehoben und steht zusätzlich als Text da.
- **Spieler → Rollen:** nur mit bestätigter, gültiger Liste über „Weiter zu den Rollen“ in der Bestätigungskarte.
- **Rollen → Verteilung:** nur über „Rollen bestätigen“ mit gültigem Pool.
- **Schrittwechsel:** `PlayerSetup.go_to_step()` prüft die Vorbedingungen (`players_not_confirmed`, `roles_not_confirmed`). Schritte haben keine eigenen Screen-IDs, ein Doppelklick überspringt nichts, und kein Wechsel erzeugt einen Befehl.
- **Zurück, Escape, System-Zurück:** Verteilung → Rollen → Spieler. Im Spielerschritt gilt die bestehende Rückfrage „Weiter bearbeiten / Entwurf behalten / Entwurf verwerfen“. Sie erscheint jetzt auch bei unbestätigter Rollenwahl oder unbestätigter Zuordnung.
- **Erneutes Öffnen:** Der Wizard öffnet im zuletzt aktiven Schritt.

## Bestätigungen

**„Rollen bestätigen“:**
- nur mit gültigem Pool und bestätigter Personenliste
- setzt `roles.confirmed` und wechselt zur Verteilung

**„Verteilung bestätigen“:**
- nur bei vollständiger Zuordnung
- setzt `distribution.confirmed`
- zeigt die Karte „Bereit für Sitzordnung“: Personen, Rollen nach Fraktion, Modus und Seed

Beide Bestätigungen erzeugen kein `StartGame`, keinen `GameState` und keinen Befehl; `GameSession` bleibt unberührt, was Tests belegen. Jede spätere passende Änderung hebt die Bestätigung auf.

## Öffentliche API (`PlayerSetup`)

| Methode | Fehlercodes |
|---|---|
| `go_to_step(step)` | `unknown_step`, `players_not_confirmed`, `roles_not_confirmed` |
| `set_role_count(role, count)`, `change_role_count(role, delta)` | `unknown_role`, `negative_count`, `above_maximum` |
| `reset_roles()` | – |
| `apply_suggestion(force = false)` | `confirmation_required`, `too_few_persons`, `too_many_persons` |
| `confirm_roles()` | `players_not_confirmed`, `roles_invalid` (Details: `issues`) |
| `set_distribution_mode(mode, force = false)` | `unknown_mode`, `confirmation_required` |
| `distribute_randomly()` | `players_not_confirmed`, `roles_not_confirmed`, `wrong_mode`, `no_seed_source`, `invalid_seed` |
| `reshuffle()` | wie oben, `nothing_to_reshuffle` |
| `assign_role(person_id, role)`, `unassign_role(person_id)`, `swap_roles(a, b)` | `wrong_mode`, `unknown_person`, `unknown_role`, `role_not_in_pool`, `no_copy_available` |
| `confirm_distribution()` | `distribution_incomplete` und die Vorbedingungen |

- **Eigenschaft:** `seed_source: Callable`.
- **Signal:** `changed(view)`, auch nach einem Schrittwechsel.
- **Sicht `view()`:** ergänzt um `step`, `steps` (`id`, `number`, `state`, `current`, `reachable`), `roles` (`counts`, `total`, `persons`, `free`, `valid`, `issues`, `confirmed`, `can_confirm`, `invalidated`, `pool`, `factions`, `wolf_count`, `limits`, `can_increase`, `can_decrease`, `is_empty`, `is_suggestion`) und `distribution` (`mode`, `assignment` [`person_id`, `number`, `name`, `role`, `appearance`], `assigned_count`, `person_count`, `role_count`, `remaining`, `remaining_total`, `complete`, `has_assignment`, `confirmed`, `can_confirm`, `invalidated`, `has_seed`, `seed`, `effective_seed`, `shuffle_count`, `factions`, `ready_for_seating`).

**Neue UI-Bausteine:**
- `DialogOption` und `DialogRequest.options`/`title_values` (Auswahlliste im modalen Dialog; ohne `confirm_key` keine Bestätigungsaktion)
- `GrimmButton.format_values`

## Tests und Screenshots

```bash
godot/tests/run_all.sh --filter=test_role           # Rollenmodell, Vorschlag, Rollenwahl-UI
godot/tests/run_all.sh --filter=test_distribution   # Verteilungsmodell, Verteilungs-UI, Geheimhaltung
xvfb-run -a -s "-screen 0 1920x1080x24" <godot-4.7.2> --path godot --rendering-driver opengl3 \
  --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- --only=role-setup
```

| Testdatei | Inhalt |
|---|---|
| `tests/ui/test_role_model.gd` | Katalogadapter gegen `RoleCatalog`, Darstellungsschlüssel DE/EN, Plus/Minus, Grenzen, Validierung, kanonischer Pool, Schrittsperren, Vorschlag 6 bis 24, Überschreiben nur mit Bestätigung, Personenänderungen, kein Zufall und keine Uhr in `app/setup/` |
| `tests/ui/test_role_step.gd` | Schrittanzeige und Sperren, Doppelklick, Zurück und Navigation erhalten Daten, Verlassen-Rückfrage, Rollenzeilen mit Katalogdaten und Gruppen, Zähler und Fehler, Überschreib-Dialog, kein GameState/StartGame, Layout 1024×768/1280×800 EN/1920×1080, Scrollen, Schlüssel |
| `tests/ui/test_distribution_model.gd` | Vollständigkeit, Reproduzierbarkeit, Personen-ID statt Reihenfolge, Neuaufbau/Sprache/Name, Neu mischen, Bestätigen, Invalidierung, manuelle Zuweisung, Moduswechsel, Trugbilderwolf-Scheinrollen (auch mehrere, manuell) |
| `tests/ui/test_distribution_step.gd` | verborgene Rollen, geheimer Bereich, Seed, Neu mischen, Zusammenfassung ohne Partie, manuelle Auswahl im modalen Dialog mit Fokussperre, Moduswechsel-Rückfrage, Layout, Scrollen |

Prüf-Screenshots: `docs/evidence/role-setup/`.

## Bewusst noch nicht enthalten

- Sitzordnung, Sitzkreis, Drag-and-drop
- Rollenübergabe an Spieler, öffentliche Rollenanzeige
- `StartGame`-Integration: Geplant ist ein manueller Aufbau mit `roles` und `appearances` aus dem Entwurf, damit die Setup-Zuordnung maßgeblich bleibt. Der zufällige Kernmodus mischt selbst und würde eine andere Zuordnung erzeugen.
- manuelle Wahl der Trugbilderwolf-Scheinrolle (siehe DR-08 oben)
- Speichern des Entwurfs, gespeicherte Gruppen, Undo/Redo
