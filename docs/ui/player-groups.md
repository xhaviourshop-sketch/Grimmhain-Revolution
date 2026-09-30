# Gespeicherte Spielergruppen

Stand: 30.09.2026 (Nachtauftrag Paket B) · Godot 4.7.2 · Projekt `godot/` · Branch `feature/night-ui-expansion`

Die Spielleitung kann die aktuelle Namensliste als benannte Gruppe speichern und für die nächste Partie wieder laden, statt alle Namen neu einzugeben. Die Funktion gehört zur Setup-Oberfläche und zur Anwendungsschicht. Sie berührt weder den Regelkern noch Spielstände noch die laufende Partie.

## Bedienung

Erreichbar im Spielerschritt von „Neue Partie“, über der Spielerliste:

| Aktion | Ablauf |
|---|---|
| „Gruppe speichern“ | gesperrt bei leerer Liste. Dialog mit Pflichtfeld „Gruppenname“, „Speichern“ legt die Namen in Listenreihenfolge ab. Die aktuelle Liste bleibt unverändert. Gibt es den Namen schon (ohne Beachtung der Groß-/Kleinschreibung), fragt ein zweiter Dialog, ob die Gruppe mit der aktuellen Liste ersetzt werden soll; Abbrechen ändert nichts. |
| „Gruppe laden“ | öffnet die Karte „Gespeicherte Gruppen“ in der linken Spalte (Modus neben Eingabe, Import und Bearbeiten). Auswahlliste mit „Name · n Namen“, darunter die Namen der gewählten Gruppe und die Aktionen. „Zurück zur Eingabe“, Escape und Zurück schließen die Karte. |
| „Laden“ | ersetzt den Entwurf durch neue Personen mit diesen Namen in dieser Reihenfolge. Bei gefüllter Liste erst eine Rückfrage („Liste ersetzen?“), Abbrechen ändert nichts. Rollenwahl, Verteilung und Sitzordnung des Entwurfs werden verworfen (frischer Entwurf, Personen-IDs ab 1). |
| „Umbenennen“ | Dialog mit Pflichtfeld; ein Name, den eine andere Gruppe trägt, wird abgelehnt. |
| „Aktualisieren“ | nur bei gefüllter Liste. Rückfrage; danach hat die Gruppe die Namen der aktuellen Liste. Der Name der Gruppe bleibt. |
| „Löschen“ | Rückfrage mit roter Bestätigung. Die aktuelle Liste bleibt. |

Spätere Änderungen im Setup verändern eine geladene oder gespeicherte Gruppe nie. Nur die ausdrücklich bestätigten Aktionen oben schreiben in die Gruppen.

## Daten

Datei `user://groups.json`, getrennt von Einstellungen (`settings.json`) und Spielständen (`saves/`):

```
{"format": "grimmhain-player-groups", "version": 1, "next_id": 3,
 "groups": [{"id": "grp-1", "name": "Freitagsrunde", "players": ["Anna", "Bärbel", ...]}]}
```

- Gespeichert werden nur stabile Gruppen-ID, Gruppenname und geordnete Spielernamen. Keine Rollen, Bindungen, Markierungen, Ressourcen, Partie-IDs oder alten Personen-IDs (`test_player_groups::test_group_file_holds_only_names_after_a_full_setup`).
- Die ID ist ein Zähler (`grp-<n>`), ohne Zufall; gelöschte IDs werden nicht wiederverwendet. `version` betrifft nur dieses Format.
- Namen folgen `PersonNameRules` (Normalisierung, höchstens 32 Zeichen, keine Steuerzeichen); eine Gruppe hat 1 bis 24 Namen (weniger als eine Partie ist erlaubt). Gruppennamen sind ohne Beachtung der Groß-/Kleinschreibung eindeutig.
- Ohne Pfad lebt `GroupStore` nur im Speicher (Tests, Werkzeuge). Die Shell setzt beim echten Start `user://groups.json` und lädt. Tests schreiben nie in echte Nutzerdateien.

## Fehler und Sicherheit

- Fehlende Datei: leere Liste, kein Fehler, nichts wird geschrieben.
- Schreiben wie bei den Einstellungen: `.tmp` schreiben und zurücklesen, alte Datei zu `.bak`, `.tmp` zu Datei (`SafeJsonFile`). Eine Änderung wird zuerst geschrieben und erst danach im Speicher übernommen; scheitert das Schreiben (`write`, `verify`, `backup`, `swap`), bleibt der letzte gültige Stand in Speicher und Datei, und die Karte meldet „Speichern nicht möglich. Die zuletzt gespeicherten Gruppen bleiben unverändert.“
- Unlesbare oder fremde Datei: leere Liste, sichtbarer Hinweis in der Karte („nicht gelesen“), die Datei wird als `groups.json.corrupt` beiseitegelegt und nie überschrieben. Eine Datei einer neueren Formatversion wird ebenso unverändert beiseitegelegt. Ist die Hauptdatei unlesbar und die Sicherung gültig, wird die Sicherung geladen und gemeldet.
- Einzelne ungültige Einträge (leerer Name, leere Liste, doppelte ID oder doppelter Name) werden übersprungen und gezählt; der Hinweis nennt die Zahl.

## Tests

| Test | Inhalt |
|---|---|
| `test_group_store` (Unit) | Speichern und Laden in neuer Instanz mit Umlauten und Reihenfolge, Dateiinhalt nur ID/Name/Namen, Umbenennen, Aktualisieren, Löschen, ID-Zähler über Neustart, gleicher Name nie still überschrieben, Namens- und Personenvalidierung mit Grenzfällen (32 Zeichen, 24 Namen), Schreibfehler an allen vier Stellen erhalten Speicher und Datei, defekte Datei, fremdes Format, neuere Version, übersprungene Einträge, Sicherung, `PlayerSetup.replace_persons` |
| `test_player_groups` (UI) | Bedienweg: speichern, neue App-Instanz, laden, bestätigen, Rollen, Verteilung, Sitzordnung, Partie starten mit genau diesen Namen; gefüllte Liste nur nach Bestätigung ersetzt, Abbrechen; keine alte Rollenwahl; Setup-Änderungen ändern die Gruppe nicht; Umbenennen, Aktualisieren, Löschen mit Abbruch; gleicher Name; Schreibfehler; defekte Datei; kein Spielereignis und kein Befehl; DE/EN; Layout bei 1024×768 und 1280×800 mit Karte und Dialogen |

Nicht geprüft: Darstellung und Bedienung auf einem Tablet (Bildschirmtastatur im Dialog), visuelle Abnahme.
