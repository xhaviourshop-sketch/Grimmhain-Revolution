# Lessons Learned

Neue Einträge oben einfügen. Nur bewiesene, wiederverwendbare Erkenntnisse aufnehmen.

## 2026-10-05: Parallele Godot-Läufe unter Windows
- Zwei Godot-Fenster (Screenshot-Werkzeuge) gleichzeitig: 290 s statt 35 s nacheinander. Fenster nie parallel starten; neben fensterlosen Tests laufen sie normal (41 s).
- Parallele headless Testprozesse teilen sich `user://`. Lösung in `tools/test-full`: eigenes `APPDATA` je Prozess (Godot nimmt `user://` unter Windows aus `APPDATA`).
- 6 Prozesse sind auf 12 Kernen schneller als 9 (174 s gegen 194 s); der Fuzz-Test allein bestimmt die Untergrenze.
- Neue Agenten in `.claude/agents/` sind nicht sofort aufrufbar; Claude Code lädt sie verzögert. Bis dahin als allgemeiner Agent mit der Agentendatei als Anweisung.

## 2026-10-05: iPad/Web: Feld per Code geleert, nächster Tastendruck hängt alten Text an
- Symptom: Nach "Timo" + Enter und `LineEdit.text = ""` ergab das nächste Tippen "TimoJ".
- Ursache: Der Web-Export schreibt Tastatureingaben über ein verstecktes `<input>` (bzw. `<textarea>`) vor dem Canvas und behält dessen Wert; `LineEdit.text` ändert es nicht. Quelle: `platform/web/js/libs/library_godot_display.js`.
- Lösung: `AppPlatform.sync_keyboard_text(text)` setzt den Wert dieser Felder mit; Fokus danach `grab_focus()` plus `edit()`.
- Vermeidung: Jedes Feld, das per Code geleert oder gesetzt wird, während die Bildschirmtastatur offen sein kann, gleicht ab. Nicht headless prüfbar.

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

## 2026-09-29: Intermittierend roter Test durch globalen Zufall (`Array.shuffle()`)
- Symptom: `test_prompt_coverage` meldete einmal „Rolle koenig erschien nie als Prompt“, danach grün.
- Ursache: `Array.shuffle()` nutzt den globalen Generator, den Godot bei jedem Start zufällig setzt. Eine `rg`-Suche nach `randi`/`randf` fand ihn nicht. Zusätzlich hängt der König-Schritt am Überleben (mehr Tote als Lebende).
- Lösung: Mischen über den seedbaren Test-Generator; Fokusrolle wird nicht übersprungen oder als Ziel gewählt; bedingte Nachtrollen mit festen Szenarien; Regressionstest (gleiche Partie unter mehreren globalen Seeds muss gleich sein).
- Vermeidung: In Tests und Kern auch nach `.shuffle()`, `pick_random()` und `randomize()` suchen. Einen roten Lauf nicht durch grüne Wiederholung erklären, sondern die Gegenprobe mit dem alten Verhalten führen.

## Web-Export: Headless-Tests sehen Parse-Fehler des Exports nicht (2026-10-05)
Symptom: Startbildschirm der Web-App lud nicht, Konsole: "Function free() not found in base self" in `epic_button.gd`. Ursache: nacktes `free()` im eigenen Skript; Editor und Headless-Tests kompilieren es, der Web-Export nicht. Lösung: `queue_free()`. Vermeidung: Nach jedem Deploy die Live-URL im Browser öffnen und die Konsole auf Skriptfehler prüfen (Skill grimmhain-deploy), nicht nur Dateigrößen vergleichen.
