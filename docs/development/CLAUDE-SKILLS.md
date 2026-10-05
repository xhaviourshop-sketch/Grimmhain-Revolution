# Skill-Auswahl für Grimmhain (aus CLAUDE.md ausgelagert)

Beschreibung verfügbar halten, vollständigen Skill nur bei Bedarf laden. Kein vollständiger Stack pro Nachricht.

| Aufgabe | Skill |
|---|---|
| GDScript-Regeln, Rollen, Speichern, Replay, Core-Tests | `grimmhain-core` |
| Godot-Tablet-UI, Layout, visuelle Qualität, Animation | `grimmhain-tablet-ui` |
| Grafik, Audio, Assetproduktion, Herkunftsnachweise | `grimmhain-assets` |
| Abschluss, Wiederaufnahme, Cloud-Berichte übernehmen | `grimmhain-handoff` |
| Deploy nach grimmhain-ipad-test | `grimmhain-deploy` |
| Standard-Screenshotsatz 1024x768 | `grimmhain-screens` |
| Bild prüfen, zuschneiden, WebP, Register, Marken-Check | `grimmhain-asset` |
| Vollsuite, Merge ohne Squash, Push, Deploy | `grimmhain-merge` |
| Unerklärter Fehler oder roter Test | `systematic-debugging` |

Fachskills nur bei konkretem Bedarf: `godot-gdscript` (nichttriviale Implementierung, Typen/Lifecycle/Signale), `godot-ui-control` (Container-Layout, Theme, Fokus), `godot-animation`, `godot-audio`, `performance-optimization` (nur reproduzierbare Leistungsprobleme), `art-bible` (erste Grafikserie, Stiländerung), `verify-and-stop` (Abschluss-/Abnahmeprüfung). Aus GodotPrompter (MIT, siehe `AGENTEN.md`): `godot-ui`, `responsive-ui` (iPad-Größen), `export-pipeline` (Web-Export), `godot-optimization`, `godot-code-review` (Planer bei Prüfstufe full).

- Normalfall: ein Grimmhain-Skill plus der nötige Fachskill. Bereits geladene Anleitungen nicht erneut lesen.
- Fachskills sind allgemeine Anleitungen: bestehende Architektur, Tests und Briefings haben Vorrang. Keine Node-Beispiele in den Regelkern, keine zusätzliche Testarchitektur, keine zweite Art Bible.
- Kosmetischer Audio-Zufall darf weder den Regelgenerator verbrauchen noch den Core verändern.
- `verify-and-stop` nutzt nur gültige Nachweise für denselben Zustand; erforderliche Tests nach Änderungen bleiben Pflicht.
- `writing-plans`/`executing-plans` nur für komplexe Planung bzw. beauftragte Planausführung; `docs-write-concisely` für größere redaktionelle Aufgaben; `frontend-design`/Playwright sind für Web-Aufgaben, kein Ersatz für Godot-UI-Prüfungen.
