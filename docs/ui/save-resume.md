# Speichern und Fortsetzen

Stand: 29.09.2026 · Godot 4.7.2 · Projekt `godot/`

Die laufende Partie wird nach jedem angenommenen Befehl automatisch gespeichert und lässt sich nach einem Neustart über Hauptmenü → „Fortsetzen“ an derselben Stelle weiterführen, auch mitten in einem mehrstufigen Prompt (etwa der Waldhexen-Kette) oder bei offener Reaktion. Der Regelkern bleibt ohne Dateizugriff: Er liefert nur den versionierten Text (`StateCodec`, Schema 12); Dateien, Sicherung und Wiederaufnahme liegen in `app/session/save_service.gd`.

## Dateien

Je Partie eine Datei `user://saves/game-<round_id>.json`:

| Feld | Inhalt |
|---|---|
| `format`, `version` | `grimmhain-app-save`, 1 |
| `app_version`, `saved_at` | App-Version, Speicherzeit (Unix-Sekunden) |
| `summary` | nur öffentliche Angaben für die Liste: Namen in Sitzreihenfolge, Personenzahl, Lebende, Phase, Nacht, Tag, Befehlszahl. Keine Rollen. |
| `core` | unveränderter `StateCodec`-Text (Zustand, Befehle, Integrität). Geladen wird immer über `StateCodec.decode` mit Integritäts- und Replay-Prüfung. |

## Sicheres Schreiben

1. Neuen Stand in `<datei>.tmp` schreiben und byteweise zurücklesen.
2. Vorhandene Datei in `<datei>.bak` umbenennen (eine Sicherung, die ältere wird ersetzt).
3. `.tmp` in `<datei>` umbenennen.

Schlägt ein Schritt fehl, meldet `SaveService.status_changed` den Fehler; die letzte intakte Datei bleibt unverändert. Das Cockpit zeigt dann „Fehler: nicht gespeichert“ und eine Statusmeldung, nie „Gespeichert“.

## Laden und Rückfall

| Fund | Verhalten |
|---|---|
| vollständige `.tmp` | stammt aus einem unterbrochenen Speichern und ist neuer als die Datei: wird eingesetzt (Hinweis „Das letzte Speichern war unterbrochen“) |
| unvollständige `.tmp` | wird als `.tmp.corrupt-<zeit>` beiseitegelegt; die Datei wird geladen |
| beschädigte Datei | wird nie überschrieben, sondern als `.corrupt-<zeit>` beiseitegelegt; die Sicherung wird geladen (Hinweis) |
| Datei und Sicherung beschädigt | Fehlermeldung, Sitzung bleibt leer, nichts wird gelöscht |
| beschädigte Datei ohne Sicherung (erster Stand) | Fehlermeldung, Datei beiseitegelegt, Sitzung bleibt leer |
| beschädigte Sicherung, intakte Datei | Datei wird geladen, Sicherung bleibt unverändert |

Beim Wechsel zu einer anderen Partie fragt „Fortsetzen“ nach, wenn der letzte Stand der laufenden Partie nicht gespeichert werden konnte. „Verwerfen …“ fragt nach und benennt die Dateien nur um (`.discarded-<zeit>`); nichts wird gelöscht.

## Grenzen

- Eine Sicherung (`.bak`), keine längere Checkpoint-Rotation.
- Die Liste zeigt die acht neuesten Partien; ältere bleiben auf dem Datenträger.
- Wiederholbare Schritte (nach Rückgängig) werden nicht gespeichert und entfallen beim Neustart.
- Testspielstände liegen in eigenen Verzeichnissen `user://test-saves-*` und werden nach jedem Test entfernt; `user://saves` wird von Tests nicht berührt.
- Ältere Schemaversionen werden nicht migriert, sondern mit Meldung abgelehnt (`StateCodec`).
- Nicht auf einem Tablet geprüft (Speicherort, Rechte, App-Beendigung durch das System). Headless geprüft sind unterbrochenes Schreiben an jedem Schritt, beschädigte Dateien, Wiederaufnahme offener Prompts und identisches Replay (`tests/ui/test_save_service.gd`).
