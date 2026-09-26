# Spieler-Setup · Namensschritt „Neue Partie“

Stand: 26.09.2026 · Godot 4.7.2 · Projekt `godot/`

Erster echter Setup-Schritt: Der Spielleiter legt 6 bis 24 Personen an, bearbeitet und entfernt sie und bestätigt die Liste als Setup-Entwurf. Rollen, Sitzordnung und `StartGame` folgen in späteren Arbeitspaketen.

## Schichten

| Schicht | Dateien | Aufgabe |
|---|---|---|
| Modell | `app/setup/person_name_rules.gd`, `setup_person.gd`, `setup_draft.gd`, `setup_result.gd` | Grenzen, Namensregeln, Personen, Entwurf, strukturierte Ergebnisse |
| Anwendungsschicht | `app/setup/player_setup.gd` (`AppContext.setup`) | einzige Wahrheit über Personen, IDs und Bestätigung; alle Operationen atomar |
| UI | `app/screens/new_game/new_game_screen.*`, `person_row.*` | Darstellung, Eingabe, Rückfragen; ruft nur `PlayerSetup` auf |

`app/setup/` kennt weder `GameState` noch `RulesEngine`, `Command`, `StartGame` oder `GameSession`; ein Test prüft das statisch.

Der Entwurf lebt in `AppContext`. Er bleibt also erhalten, wenn der Spielleiter zu den Einstellungen oder ins Hauptmenü wechselt, die Sprache ändert oder die Ansicht neu aufgebaut wird. Nichts wird auf Datenträger geschrieben.

## Datenmodell

**`SetupPerson`**
- `person_id` (int, ab 1, stabil)
- `name` (normalisiert)
- `created_order` (Erstellungsreihenfolge, derzeit gleich der ID-Vergabe)

**`SetupDraft`**
- `persons` (Array in Listenreihenfolge)
- `next_person_id` (nächste ID, Start 1)
- `confirmed` (Namensschritt bestätigt)
- `has_unconfirmed_changes` (Änderungen seit Bestätigung oder Neubeginn)
- `validation()` wird aus der Liste berechnet, nicht gespeichert: `count`, `valid`, `missing`, `at_maximum`

**`PlayerSetup.view()`** liefert immer eine neue Kopie. Sie enthält:
- `persons` mit `person_id`, `number` (sichtbare Listennummer), `name`, `duplicate`
- `count`, `min_persons`, `max_persons`, `max_name_length`
- `can_add`, `can_confirm`, `confirmed`, `has_unconfirmed_changes`, `is_empty`
- `duplicate_count`, `next_person_id`, `validation`

## Stabile IDs

- Eine ID wird beim Anlegen genau einmal vergeben, aufsteigend ab 1, und nie geändert.
- Bearbeiten behält die ID.
- Entfernen gibt die ID nicht frei; neue Personen erhalten immer `next_person_id`.
- Auch wenn die Liste zwischendurch leer war, zählt der Zähler weiter.
- Nur Verwerfen bzw. „Neu beginnen“ setzt Liste, Zähler und Status vollständig zurück; der nächste Entwurf beginnt wieder bei 1.
- Ein abgelehnter Import verändert den Zähler nicht.
- Die UI zeigt die ID nie an, sondern nur die fortlaufende Listennummer. Diese wird nach jedem Entfernen neu durchgezählt.
- Die ID ist die spätere Personen-ID für `StartGame`. Die Grenzen 6 und 24 stimmen per Test mit `RulesEngine.MIN_PLAYERS/MAX_PLAYERS` überein.

## Namensregeln

Alle Grenzen stehen nur in `PersonNameRules`: `MIN_PERSONS = 6`, `MAX_PERSONS = 24`, `MAX_NAME_LENGTH = 32`. Ein Test verbietet die Zahlen 24 und 32 in anderen App-Skripten.

1. **Normalisierung:**
   - Entfernt wird nur Leerraum am Rand: Leerzeichen, Tabulator, Zeilenumbrüche, geschützte und typografische Leerzeichen (U+00A0, U+2000 bis U+200B, U+202F, U+3000 u. a.).
   - Innere Leerzeichen, Groß-/Kleinschreibung, Akzente, Bindestriche, Apostrophe und beliebige Schriften bleiben unverändert.
2. **Leer:** Ist der Name nach der Normalisierung leer, gilt `empty_name`; es wird nichts angelegt.
3. **Steuerzeichen:** Steuerzeichen im Namen (U+0000 bis U+001F, U+007F, U+0080 bis U+009F), z. B. ein Tabulator innen, ergeben `invalid_characters`.
4. **Länge:** Mehr als 32 Unicode-Zeichen nach der Normalisierung ergeben `name_too_long`. Der Name wird nie abgeschnitten.

**Dubletten:**
- Der Vergleich läuft über den normalisierten Namen in Kleinschreibung. `Anna`, `anna` und ` ANNA ` gelten als gleich; innere Doppelleerzeichen werden nicht angeglichen.
- Dubletten sind erlaubt und blockieren die Bestätigung nicht. Jede Person behält ihre eigene ID, nichts wird umbenannt.
- Sichtbar werden sie als Textplakette „Doppelter Name“ an jeder betroffenen Zeile, als Zusammenfassung „Hinweis: …“ über der Liste und als Meldung beim Hinzufügen, Importieren oder Umbenennen. Die Unterscheidung läuft über die Listennummer, nicht nur über Farbe.

## Eingabe

**Einzeleingabe:**
- Textfeld, „Hinzufügen“ und Enter lösen dieselbe Operation aus.
- Bei Erfolg wird das Feld geleert und der Fokus kehrt dorthin zurück.
- Bei Ablehnung bleibt der Text stehen und eine Meldung erscheint.
- „Hinzufügen“ ist gesperrt, solange das Feld leer ist. Ein zweites Tippen direkt nach dem Hinzufügen trifft deshalb einen gesperrten Button und legt nichts doppelt an.

**Mehrfachimport** („Mehrere Namen einfügen“):
- Eingabe über ein mehrzeiliges Textfeld, getrennt durch Zeilenumbruch (auch `\r\n`), Komma oder Semikolon.
- Leere Einträge werden ignoriert, die Reihenfolge bleibt erhalten, die IDs folgen der Eingabereihenfolge.
- Der Import ist atomar, es kommen alle Namen oder keiner:
  - `invalid_entries`: mindestens ein Eintrag ist zu lang oder enthält Steuerzeichen. Die Meldung nennt bis zu drei Einträge mit Position, gekürztem Namen und Grund, dazu die Zahl weiterer; überschreitet der Import zugleich 24, wird das ebenfalls erwähnt.
  - `too_many_persons`: bisherige plus neue Personen ergäben mehr als 24. Die Meldung nennt Höchstzahl, aktuelle und hinzukommende Anzahl.
  - `import_empty`: keine Namen gefunden.
- Nach Erfolg schließt der Import und leert das Feld; der Übernehmen-Button reagiert dann nicht mehr auf ein zweites Tippen.
- Namen mit Komma oder Semikolon lassen sich nur einzeln anlegen.
- Es gibt keine Zwischenablage-API, normales Einfügen genügt.

**Bearbeiten:**
- „Bearbeiten“ öffnet in der linken Spalte ein Feld mit dem vollen Namen.
- „Speichern“ oder Enter wendet atomar an; bei Ablehnung bleibt der Modus mit Meldung offen.
- „Abbrechen“ oder Escape ändert nichts.
- Ein unveränderter Name hebt eine Bestätigung nicht auf; ein zu einer Dublette geänderter Name erzeugt einen Hinweis.

**Entfernen:** Nur nach Rückfrage, die Namen und Nummer nennt. Abbrechen ändert nichts.

## Anzahl und Bestätigung

| Personen | Verhalten |
|---|---|
| 0 | Hinweis „Mindestens 6 … es fehlen noch 6“, Bestätigen gesperrt, „Neu beginnen“ gesperrt |
| 5 | Bestätigen gesperrt; `confirm()` liefert `too_few_persons` |
| 6 | Bestätigen frei (auch mit Dubletten) |
| 24 | Bestätigen frei; Feld, „Hinzufügen“ und Import gesperrt, Hinweis „Höchstzahl erreicht“, Fokus auf „Spieler bestätigen“ |
| 25. Person | `too_many_persons`, Zustand unverändert |

- **Bestätigen:** Setzt `confirmed` und leert `has_unconfirmed_changes`. Es erscheinen der Status „Bestätigt: N Spieler.“, eine Statusmeldung und die Karte „Namensschritt vollständig“.
- **Keine Partie:** Bestätigen erzeugt keinen `GameState`, keinen Befehl und keine Rollen. `GameSession` bleibt unberührt, per Test mit Befehlszähler 0 und ohne Ereignisse.
- **Erneute Änderung:** Jede spätere Änderung (hinzufügen, importieren, umbenennen, entfernen) hebt die Bestätigung auf.

## Verlassen und erneutes Öffnen

- Zurück-Button, Escape und System-Zurück laufen über `NewGameScreen.handle_back()`:
  1. offener Import- oder Bearbeitungsmodus → schließen
  2. unbestätigte Änderungen an einer nicht leeren Liste → Rückfrage mit „Weiter bearbeiten“ (Fokus, Escape), „Entwurf behalten“ (zum Hauptmenü) und „Entwurf verwerfen“ (rot, setzt zurück, zum Hauptmenü)
  3. sonst normales Zurück
- Ein bestätigter oder leerer Entwurf verlässt die Seite ohne Rückfrage.
- Programmgesteuerte Navigation fragt nicht nach, der Entwurf bleibt dabei erhalten.
- Beim erneuten Öffnen erscheinen dieselben Namen, IDs und derselbe Status.
- „Neu beginnen“ (Fußzeile) setzt nach einer roten Rückfrage alles zurück.

## Dialoge

Alle Rückfragen laufen über `ConfirmDialog` mit `DialogRequest`, siehe `docs/ui/README.md`.

## Tests und Screenshots

```bash
godot/tests/run_all.sh --filter=test_setup     # Modell, Ansicht, Layout
godot/tests/run_all.sh --filter=test_dialog    # Fokussperre
xvfb-run -a -s "-screen 0 1920x1080x24" <godot-4.7.2> --path godot --rendering-driver opengl3 \
  --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- --only=player-setup
```

| Testdatei | Inhalt |
|---|---|
| `tests/ui/test_setup_model.gd` | IDs, Normalisierung, Länge, Steuerzeichen, Anzahl, Dubletten, Import, Umbenennen, Entfernen, Status, keine Regelkern-Bezüge, Sicht als Kopie |
| `tests/ui/test_setup_screen.gd` | Einzeleingabe, Doppeltippen, Importmeldungen, Zähler und Sperren, IDs über Sprachwechsel und Neuaufbau, keine Partie, Bearbeiten, Entfernen, Verlassen, Neu beginnen |
| `tests/ui/test_setup_layout.gd` | 0/6/12/18/24 Personen bei 1024×768 und 1280×800, EN, 1920×1080, lange Namen, Dubletten, offene Modi und Dialog, Scrollen, Schlüssel, keine festen Texte |
| `tests/ui/test_dialog_focus.gd` | Fokussperre, Hintergrund gesperrt, Escape, Fokus-Rückgabe, kein zweiter Dialog |

Prüf-Screenshots: `docs/evidence/player-setup/`.

## Bewusst noch nicht enthalten

- Rollen, Rollenanzahl und Rollenverteilung
- Sitzordnung und Sitzkreis, Drag-and-drop, manuelle Umordnung der Liste
- `StartGame` und eine echte Partie
- Speichern auf Datenträger, Autosave, gespeicherte Gruppen, Dateiimport und -export
