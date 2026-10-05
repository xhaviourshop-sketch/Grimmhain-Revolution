# Agenten-Team

Fünf feste Agenten in `.claude/agents/`. Ablauf (verbindlich) steht in `CLAUDE.md` unter "Team-Ablauf".

| Agent | Modell | Aufgabe | Darf ändern |
|---|---|---|---|
| `planer` | Opus | Auftrag in Teile mit festen Dateien zerlegen, Prüfstufe wählen, danach Zweige und Funde zusammenführen | nein |
| `godot-entwickler` | Sonnet | einen Teil umsetzen, eigener Worktree (`isolation: worktree`) und Zweig `team/<auftrag>-<teil>`, gezielte Tests, Screenshots | ja, nur zugewiesene Dateien |
| `pruefer-sprache` | Haiku | sichtbare Texte gegen `docs/brand/MARKE.md` und `docs/audit/NACHTSCHRITTE-PRINZIPIEN.md`, Funde mit Datei und Zeile | nein |
| `pruefer-marke` | Sonnet | Screenshots gegen MARKE.md: kein Gold, GroveWindow, Blutrot nur aktiv, gotisch nur Titel, nichts abgeschnitten oder verdeckt | nein |
| `pruefer-spielleiter` | Sonnet | Screenshots aus Sicht eines Spielleiters vor 20 Leuten: wer ist dran, was tippe ich, unnötige Klicks, fehlende Info | nein |

## Prüfstufen

- `minimal`: nur Text oder Doku. Prüfer: Sprache.
- `standard`: sichtbare UI-Änderung (Normalfall). Prüfer: alle drei.
- `full`: Regelkern, Speichern/Laden, Befehle. Alle drei Prüfer, Code-Durchsicht durch den Planer nach `godot-code-review`, Vollsuite mit Fuzz vor dem Merge.

## Warum so

- Unterhaltene Agenten können keine weiteren Agenten starten. Der Planer liefert deshalb einen Verteilplan; die Hauptsitzung startet Entwickler und Prüfer danach. Trade-off: ein Schritt mehr in der Hauptsitzung, dafür bleibt die Verteilung sichtbar.
- Worktrees verhindern, dass parallele Entwickler dieselben Dateien überschreiben. Ein neuer Worktree hat noch keinen `.godot`-Importcache: der erste Testlauf darin importiert neu (siehe `TEMPO.md`).
- Haiku für die Sprachprüfung, weil sie Regeln abgleicht und keine Gestaltung entscheidet. Sonnet für Bildprüfung und Umsetzung, Opus nur für Zerlegen und Zusammenführen.
- Prüfer ändern nie selbst. Funde gehen über den Planer an einen Entwickler; so bleibt jede Änderung in genau einem Zweig.

## Fachskills (GodotPrompter, unverändert kopiert)

`.claude/skills/godot-ui`, `responsive-ui`, `export-pipeline`, `godot-optimization`, `godot-code-review`. Nur bei Bedarf lesen; Grimmhain-Architektur und Tests haben Vorrang. Nicht übernommen: Spiel-Skills (Physik, 3D, Gegner, Inventar, Mehrspieler), Hooks, Befehle und die übrigen GodotPrompter-Agenten.

## Herkunft und Lizenzen

- **Claude-Code-Game-Studios** (Donchitos), MIT, Commit `b21fa0f`: keine Dateien kopiert. Übernommene Ideen: Modell-Staffelung Haiku/Sonnet/Opus, Prüfstufen minimal/standard/full, Rollentrennung QA, UX, Text, Art Director. Lizenztext: `docs/development/skill-sources/Donchitos--Claude-Code-Game-Studios/`.
- **GodotPrompter** (jame581), MIT, Commit `1e73eea`: fünf Skills unverändert kopiert (oben). Die Checkliste des Agenten `godot-code-reviewer` nutzt der Planer über den Skill `godot-code-review`. Lizenztext: `docs/development/skill-sources/jame581--GodotPrompter/`.
