# Abschlussbericht und Partiehistorie

Stand: 30.09.2026 (Paket D, Matrix C-09). Headless nachgewiesen, keine Geräte- und keine visuelle Abnahme.

## Bedienweg
- Nach bestätigtem Spielende zeigt die Cockpit-Karte „Abschlussbericht öffnen“. Der Knopf öffnet die Historie mit diesem Bericht.
- Hauptmenü „Partiehistorie“ listet alle abgeschlossenen Partien; ein Eintrag öffnet den Bericht, auch ohne aktive Partie.
- Fassungen: „Öffentlicher Bericht“ (Standard) und „Spielleiterbericht“ (nie vorausgewählt, öffnet erst nach Rückfrage).
- „Als Text speichern“ nennt die Fassung im Knopf und im Hinweis. Eine vorhandene Datei wird nur nach Bestätigung ersetzt.
- „Bericht löschen“ fragt nach. Es gibt keine automatische Löschfrist.

## Inhalt
Partie-ID, Teilnehmerzahl, Namen, Nächte und Tage, chronologische Ereignisse in Klartext (DE/EN), Siegseite. Nach bestätigtem Spielende nennt auch die öffentliche Fassung die Rollen zum Spielende, die Siegbedingung und gewinnende Personen (NQ-07). Der Spielleiterbericht ergänzt ursprüngliche Rollen bei Rollenwechseln, Ursachen, Effekte, Korrekturen und die übrigen privaten Zeilen. Keine Spielzeit (wird nicht erfasst), keine rohen Datenstrukturen, keine Statistik, kein PDF, kein Upload, kein Teilen.

## Datenhaltung
- `user://history.json`, Format `grimmhain-game-history`, Version 1, sicheres Schreiben mit `.tmp`, `.bak`, `.corrupt` (`SafeJsonFile`). Sprachneutral gespeichert, beim Anzeigen in die aktuelle Sprache gesetzt.
- Ein Eintrag je Partie-ID (idempotent). Status `completed` oder `reopened`.
- Nimmt „Rückgängig“ die Siegbestätigung zurück, zeigt die Liste „Partie läuft wieder“ und der Export ist gesperrt. Ein erneuter Abschluss aktualisiert den Eintrag. Die aktive Partie bleibt maßgeblich.
- Ein Speicherfehler der Historie beschädigt die Partie nicht; die Historienansicht versucht es beim Öffnen erneut.
- Export: `user://exports/grimmhain-bericht-<id>-<oeffentlich|spielleitung>.txt`, UTF-8, Ersetzen über geprüfte `.tmp`.
- Kein Regelkern-Zugriff: Historie, Text und Export liegen außerhalb von `core/`; Schema 14 unverändert.

## Geheimhaltung
Die öffentliche Fassung enthält, was am Tisch bekannt ist (Rolle eines Toten in der Chronik nur in Runden ohne Wiederbelebung), und nach dem **bestätigten** Spielende zusätzlich (NQ-07, Antwort C, DA-85):

- alle Teilnehmenden mit ihrer Rolle zum Spielende („3 · Name: Rolle“, † bei Toten); bei einem Rollenwechsel die Rolle zum Spielende, nie die ursprüngliche und kein Wechselverlauf,
- die Siegbedingung und gewinnende Personen (nur bei personenbezogenen Siegen und Mitsiegern; bei Wolfs- und Dorfsieg steht die Siegseite).

Nicht öffentlich bleiben geheime Ziele, Schutzmarkierungen, private Entscheidungen, Todesursachen, Korrekturen, verdeckte Nominierende und interne Zustände. Sie stehen nur in der Spielleiterfassung.

Sicherheitsgrenze: Ein offener Siegkandidat ist kein bestätigtes Spielende, es entsteht kein Bericht und keine Rollenliste. Nimmt „Rückgängig“ die Siegbestätigung zurück, meldet die Historie „Partie läuft wieder“; die Ansicht zeigt Rollen, Sieger und Siegbedingung dann nicht mehr (Hinweistext der Fassung sagt das) und der Export ist gesperrt. Ein neuer Abschluss ersetzt den Eintrag mit dem neuen Stand, es werden keine Rollen aus einem älteren Abschluss übernommen. Bildschirm und Textexport verwenden dieselbe Zeilenliste und haben denselben Umfang. Ein gespeicherter Bericht ohne Rollen wird nicht ergänzt (keine Rollenliste). Das gespeicherte Format (Version 1) ändert sich nicht; die Rollen standen schon im Bericht. Bereits exportierte Dateien lassen sich nicht zurückrufen; der Hinweis vor dem Export sagt das.

## Nachweise
`test_game_report` (8), `test_history_store` (13), `test_game_history` (Bedienweg, Layout 1024×768, Export, Löschen, Rücknahme, Fehlerpfade). Offen: Geräteabnahme, redaktionelle Endabnahme der Berichtstexte.
