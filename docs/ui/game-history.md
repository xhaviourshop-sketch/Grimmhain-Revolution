# Abschlussbericht und Partiehistorie

Stand: 30.09.2026 (Paket D, Matrix C-09). Headless nachgewiesen, keine Geräte- und keine visuelle Abnahme.

## Bedienweg
- Nach bestätigtem Spielende zeigt die Cockpit-Karte „Abschlussbericht öffnen“. Der Knopf öffnet die Historie mit diesem Bericht.
- Hauptmenü „Partiehistorie“ listet alle abgeschlossenen Partien; ein Eintrag öffnet den Bericht, auch ohne aktive Partie.
- Fassungen: „Öffentlicher Bericht“ (Standard) und „Spielleiterbericht“ (nie vorausgewählt, öffnet erst nach Rückfrage).
- „Als Text speichern“ nennt die Fassung im Knopf und im Hinweis. Eine vorhandene Datei wird nur nach Bestätigung ersetzt.
- „Bericht löschen“ fragt nach. Es gibt keine automatische Löschfrist.

## Inhalt
Partie-ID, Teilnehmerzahl, Namen, Nächte und Tage, chronologische Ereignisse in Klartext (DE/EN), Siegseite. Der Spielleiterbericht ergänzt Gewinnernamen, Siegbedingung, Rollen aller Personen, Ursachen, Effekte und Korrekturen. Keine Spielzeit (wird nicht erfasst), keine rohen Datenstrukturen, keine Statistik, kein PDF, kein Upload, kein Teilen.

## Datenhaltung
- `user://history.json`, Format `grimmhain-game-history`, Version 1, sicheres Schreiben mit `.tmp`, `.bak`, `.corrupt` (`SafeJsonFile`). Sprachneutral gespeichert, beim Anzeigen in die aktuelle Sprache gesetzt.
- Ein Eintrag je Partie-ID (idempotent). Status `completed` oder `reopened`.
- Nimmt „Rückgängig“ die Siegbestätigung zurück, zeigt die Liste „Partie läuft wieder“ und der Export ist gesperrt. Ein erneuter Abschluss aktualisiert den Eintrag. Die aktive Partie bleibt maßgeblich.
- Ein Speicherfehler der Historie beschädigt die Partie nicht; die Historienansicht versucht es beim Öffnen erneut.
- Export: `user://exports/grimmhain-bericht-<id>-<oeffentlich|spielleitung>.txt`, UTF-8, Ersetzen über geprüfte `.tmp`.
- Kein Regelkern-Zugriff: Historie, Text und Export liegen außerhalb von `core/`; Schema 14 unverändert.

## Geheimhaltung
Die öffentliche Fassung enthält nur, was am Tisch bekannt ist. Rolle eines Toten nur in Runden ohne Wiederbelebung. Der erweiterte öffentliche Umfang nach dem Spielende ist offen (NQ-07).

## Nachweise
`test_game_report` (8), `test_history_store` (13), `test_game_history` (Bedienweg, Layout 1024×768, Export, Löschen, Rücknahme, Fehlerpfade). Offen: Geräteabnahme, redaktionelle Endabnahme der Berichtstexte.
