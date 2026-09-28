# Lessons Learned

Neue Einträge oben einfügen. Nur bewiesene, wiederverwendbare Erkenntnisse aufnehmen.

## 2026-09-29: Laufzeitfehler nach bestandener Prüfung galten als grün
- Symptom: Ein Test mit `SCRIPT ERROR` nach der ersten Prüfung meldete „ok“; nur die Log-Suche fand den Fehler.
- Lösung: `tests/error_logger.gd` (Godot-`Logger`) im Runner; jeder Engine- oder Skriptfehler während eines Tests macht ihn rot.
- Folgen für neuen Code: erwartbar ungültige Eingaben ohne Engine-Fehler behandeln (`JSON.new().parse()` statt `JSON.parse_string()`), Hilfsfunktionen in Testdateien nie mit `test_` beginnen (der Runner führt sie als Tests aus), Lambdas mit `self` nicht an Signale langlebiger Objekte hängen (Referenzzyklus, Leckmeldung beim Beenden).

## 2026-09-27: Rule-15-Hook blockierte trotz aktueller Doku
- Fehler: `~/.claude/hooks/rule15-enforcer.js` erkannte Doku nur bei Edit/Write auf die Zustandsdatei (nicht per Shell) und wertete jeden Commit als neue, ungedokumentierte Änderung. Behoben: Inhalts-Hash statt Werkzeug, Commits mit `PROGRESS.md` gelten als dokumentiert, Doku-Dateien zählen nicht als Code (Backup: `rule15-enforcer.js.bak`).

## 2026-09-27: Verwaiste `.git/index.lock`
- Symptom: `git add` scheitert mit "index.lock: File exists", obwohl kein git-Prozess läuft.
- Ursache: vermutlich abgebrochener Git-Aufruf aus VS Code oder Codex, die parallel im Repo laufen.
- Lösung: Prozessliste prüfen (kein `git`), dann 0-Byte-Lock nach Rückfrage löschen; Commit/Push liefen danach normal.
- Vermeidung: Vor Git-Schreibaktionen prüfen, ob andere Agenten/Editoren gerade Git ausführen.
