# Speichern und Fortsetzen

Stand: 29.09.2026 (Paket 4) · Godot 4.7.2 · Projekt `godot/`

Die laufende Partie wird nach jedem angenommenen Befehl automatisch gespeichert und lässt sich nach einem Neustart über Hauptmenü → „Fortsetzen“ an derselben Stelle weiterführen, auch mitten in einem mehrstufigen Prompt (etwa der Waldhexen-Kette) oder bei offener Reaktion. Der Regelkern bleibt ohne Dateizugriff: Er liefert nur den versionierten Text (`StateCodec`, Schema 14, Regelversion 0.12); Dateien, Sicherung und Wiederaufnahme liegen in `app/session/save_service.gd`.

## Dateien

Je Partie eine Datei `user://saves/game-<round_id>.json`:

| Feld | Inhalt |
|---|---|
| `format`, `version` | `grimmhain-app-save`, 1 |
| `app_version`, `saved_at` | App-Version, Speicherzeit (Unix-Sekunden) |
| `summary` | nur öffentliche Angaben für die Liste: Namen in Sitzreihenfolge, Personenzahl, Lebende, Phase, Nacht, Tag, Befehlszahl. Keine Rollen. |
| `core` | unveränderter `StateCodec`-Text (Zustand, Befehle, Integrität). Geladen wird immer über `StateCodec.decode` mit Integritäts- und Replay-Prüfung. |

## Sicheres Schreiben

0. Liegt noch eine vollständige `.tmp` aus einem abgebrochenen Speichern vor, wird sie zuerst eingesetzt (Datei → `.bak`, `.tmp` → Datei). Sonst könnte ein erneuter Fehler beim Überschreiben der `.tmp` den neuesten vollständigen Stand zerstören (Befund B-04, Paket 4).
1. Neuen Stand in `<datei>.tmp` schreiben und byteweise zurücklesen.
2. Vorhandene Datei in `<datei>.bak` umbenennen (eine Sicherung, die ältere wird ersetzt).
3. `.tmp` in `<datei>` umbenennen.

Ein fehlendes Verzeichnis wird angelegt. Steht eine Datei im Pfad, meldet der Dienst `no_directory`, ohne etwas zu verändern.

Schlägt ein Schritt fehl, meldet `SaveService.status_changed` den Fehler; die letzte intakte Datei bleibt unverändert. Das Cockpit zeigt dann „Fehler: nicht gespeichert“, eine Statusmeldung und den Button „Erneut speichern“, nie „Gespeichert“. Die Partie bleibt unverändert bedienbar und wird nicht zurückgesetzt.

## Bedienung bei Speicherfehlern

| Situation | Verhalten |
|---|---|
| Speichern fehlgeschlagen | Phasenleiste „Fehler: nicht gespeichert“ (rot), Statusmeldung „Der letzte gespeicherte Stand bleibt erhalten“, Button „Erneut speichern“ |
| „Erneut speichern“ | genau ein Versuch je Tippen, keine automatische Wiederholung; bei Erfolg „Gespeichert“, der Button verschwindet. Nötig vor allem nach dem letzten Befehl einer Partie (Spielende), weil sonst kein weiterer Befehl ein Speichern auslöst |
| nächster angenommener Befehl | speichert wie immer automatisch; gelingt es, ist der Fehlerzustand beendet |
| Beenden (Desktop-Button, Zurück in der Wurzel) | die Rückfrage warnt „Der letzte Stand der laufenden Partie ist nicht gespeichert“ statt „ist gespeichert“ |
| System-Zurück in der Wurzel (Mobilgerät) | gespeichert: beendet sofort wie bisher; ungespeichert: dieselbe Warnung, Abbrechen erhält die Sitzung, „Beenden“ beendet genau einmal. Offene Dialoge und Unteransichten behandeln Zurück zuerst |
| Fenster schließen (Desktop, X oder Alt+F4) | gespeichert: schließt sofort wie bisher; ungespeichert: dieselbe Warnung (`auto_accept_quit` aus, Behandlung in `AppShell._notification`) |
| Beenden durch das Betriebssystem | nicht abfangbar (Speicherdruck, Aufgabenwechsel, Absturz); geschützt ist nur, was vorher gespeichert wurde |
| Wechsel zu einer anderen Partie | Rückfrage „Aktuelle Partie nicht gespeichert“ (bestehend) |
| neue Partie | nicht möglich, solange eine Partie läuft (Regelkern `game_already_started`); die laufende Partie wird nie still ersetzt |

## Laden und Rückfall

| Fund | Verhalten |
|---|---|
| vollständige `.tmp` | stammt aus einem unterbrochenen Speichern und ist neuer als die Datei: wird eingesetzt (Hinweis „Das letzte Speichern war unterbrochen“) |
| unvollständige `.tmp` | wird als `.tmp.corrupt-<zeit>` beiseitegelegt; die Datei wird geladen |
| beschädigte Datei | wird nie überschrieben, sondern als `.corrupt-<zeit>` beiseitegelegt; die Sicherung wird geladen. Hinweis: „Geladen wurde die Sicherung, ein älterer Stand: Die zuletzt ausgeführten Schritte fehlen …“ |
| Datei und Sicherung beschädigt | Fehlermeldung „beschädigt und hat keine gültige Sicherung. Nichts wurde gelöscht“, Sitzung bleibt leer, keine angebliche Wiederherstellung |
| beschädigte Datei ohne Sicherung (erster Stand) | Fehlermeldung, Datei beiseitegelegt, Sitzung bleibt leer |
| beschädigte Sicherung, intakte Datei | Datei wird geladen, Sicherung bleibt unverändert |
| Spielstand anderer Schema- oder Regelversion (zum Beispiel Schema 12) | gilt nicht als beschädigt: nie beiseitegelegt, nie verändert, nie neu gedeutet. „Fortsetzen“ zeigt den Hinweis „andere Version“ und ist gesperrt; „Verwerfen“ bleibt möglich (Datei wird umbenannt, nicht gelöscht) |

Wiederholtes Laden (auch nach dem Einsetzen einer `.tmp`) liefert immer denselben Stand und wendet keinen Befehl doppelt an (`test_repeated_resume_never_applies_commands_twice`).

Beim Wechsel zu einer anderen Partie fragt „Fortsetzen“ nach, wenn der letzte Stand der laufenden Partie nicht gespeichert werden konnte. „Verwerfen …“ fragt nach und benennt die Dateien nur um (`.discarded-<zeit>`); nichts wird gelöscht.

## Unterbrechung: was erhalten bleibt (Paket 4)

Erhalten bleibt jeder angenommene Befehl, denn gespeichert wird nach jedem Befehl. Flüchtige Bedienauswahl wird beim Neustart bewusst verworfen; die Spielleitung setzt an der angezeigten nächsten Handlung fort.

| Unterbrechungsstelle | erhalten (Regelzustand) | verworfen (Bedienzustand) | Nachweis |
|---|---|---|---|
| offene Einzel- oder Mehrfachauswahl | Prompt offen | angetippte, nicht bestätigte Sitzplätze; neues Ziel ergibt den Befehl, kein veraltetes | `test_resume_scenarios` |
| mehrstufige Rollenaktion | beantwortete Stufen (Waldhexe: Heiltrank) | – | `test_resume_scenarios`, `test_process_restart` |
| offene Todesreaktion | eingereihte Reaktion, begonnener Reaktionsprompt, genau einmal | aufgedeckte Karte | `test_resume_scenarios` |
| unbestätigter privater Hinweis | Hinweis steht an | geöffnete Hinweiskarte (nach dem Neustart geschlossen) | `test_resume_scenarios` |
| bestätigter privater Hinweis | bleibt erledigt, wird nicht erneut verlangt | – | `test_resume_scenarios` |
| teilweise Rollenanzeige | bestätigte Personen; Fortsetzung bei der ersten unbestätigten | geöffnete, nicht bestätigte Rollenkarte | `test_resume_scenarios`, `test_role_show` |
| Morgenbericht | öffentlicher und privater Teil identisch | „Weiter zum Tag“ (Bericht wird erneut angeboten) | `test_resume_scenarios` |
| Nominierung/Hinrichtung | Nominierungen des Tages | aufgedeckte Hinrichtungsprüfkarte | `test_resume_scenarios` |
| Siegkandidat | Entscheidung offen, genau eine Bestätigung | – | `test_resume_scenarios` |
| bestätigtes Spielende | Spielende, Rückgängig öffnet die Entscheidung wieder | – | `test_resume_scenarios`, `test_save_service` |

Nach jedem Neustart ist keine private Ebene geöffnet. Geprüft wird der Neustart über den echten Weg: neue Shell mit neuer Sitzung und neuen Diensten, Hauptmenü → „Fortsetzen“. Zusätzlich:

- `test_resume_every_command`: sechs Mischpartien des Fuzz-Generators (mit Rollenwechsel, Wiederbelebung, Kettentod, Ressourcenverbrauch, Spielleiterkorrekturen, Rollen- und Hinweisbestätigungen) werden nach jedem einzelnen Befehl über die Datei neu gestartet. Zustand, Ereignisverlauf, Cockpit-Sicht, Morgenbericht, Rollenanzeige und Spielleiterbereich sind identisch; der nächste Befehl wird genau einmal angenommen und ergibt denselben Stand wie ohne Unterbrechung.
- `test_process_restart`: echter Prozessneustart. Ein zweiter Godot-Prozess (`tests/ui/process_resume_child.gd`) lädt die Datei, setzt die offene Waldhexen-Stufe fort und speichert; der erste Prozess lädt diesen Stand zurück.

## Grenzen

- Eine Sicherung (`.bak`) je Partie, keine längere Checkpoint-Rotation. Entschieden durch Decision Log PE-02 (29.09.2026): eine Sicherung reicht, mehrere Stände frühestens als spätere Komfortfunktion.
- Die Liste zeigt die acht neuesten Partien; ältere bleiben auf dem Datenträger.
- Wiederholbare Schritte (nach Rückgängig) werden nicht gespeichert und entfallen beim Neustart. Entschieden durch Decision Log PE-03 (29.09.2026); die frühere Anforderung „über Neustart“ in Spezifikation B-12 ist entsprechend ersetzt.
- Ereignisse werden nicht gespeichert, sondern beim Laden per Replay der Befehle neu erzeugt. Deshalb ändert die Rolle beim Tod im Ereignis `SeatDied` das Speicherformat nicht. Schema 13 (29.09.2026) ersetzt `reveal_role_on_death` durch die abgeleitete `revival_round` und ergänzt `notices`; Spielstände älterer Schemata werden mit klarer Meldung abgelehnt (`unsupported_schema_version`), die Dateien bleiben unverändert erhalten.
- Testspielstände liegen in eigenen Verzeichnissen `user://test-saves-*` und werden nach jedem Test entfernt; `user://saves` wird von Tests nicht berührt.
- Ältere Schemaversionen werden nicht migriert, sondern mit Meldung abgelehnt (`StateCodec`, Fehler `incompatible` im `SaveService`). Die Datei bleibt dabei unverändert auf dem Datenträger (Test `test_save_service`).
- Nicht auf einem Tablet geprüft (Speicherort, Rechte, App-Beendigung durch das System). Headless geprüft sind unterbrochenes Schreiben an jedem Schritt, zwei aufeinanderfolgende Fehler, beschädigte Dateien, nicht anlegbares Verzeichnis, Wiederaufnahme offener Prompts und identisches Replay (`tests/ui/test_save_service.gd`).
- Schreibrechte: Ein Test über Dateirechte (ACL, `chmod`) beweist unter einem privilegierten Konto nichts und ist unter Windows nicht zuverlässig. Nachgewiesen wird deshalb mit einer im Pfad stehenden Datei (echter Fehler, kontounabhängig) und mit dem Testanschluss `simulate_failure` für die Schritte Schreiben, Prüfen, Sichern und Einsetzen.
- Ein Abbruch des Prozesses mitten im Schreiben einer Datei ist nicht zeitgenau auslösbar; die dabei möglichen Dateizustände (unvollständige `.tmp`, fehlende Datei mit `.tmp` und `.bak`) werden direkt hergestellt und geladen.
