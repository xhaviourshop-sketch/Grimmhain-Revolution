# Lessons Learned

Neue Einträge oben einfügen. Nur bewiesene, wiederverwendbare Erkenntnisse aufnehmen.

## 2026-09-27: Verwaiste `.git/index.lock`
- Symptom: `git add` scheitert mit "index.lock: File exists", obwohl kein git-Prozess läuft.
- Ursache: vermutlich abgebrochener Git-Aufruf aus VS Code oder Codex, die parallel im Repo laufen.
- Lösung: Prozessliste prüfen (kein `git`), dann 0-Byte-Lock nach Rückfrage löschen; Commit/Push liefen danach normal.
- Vermeidung: Vor Git-Schreibaktionen prüfen, ob andere Agenten/Editoren gerade Git ausführen.
