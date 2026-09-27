# Asset-Lab

Isolierte Muster zur Beurteilung von Assets. Nicht Teil der App: keine Verbindung zum Regelkern, keine Änderung an `project.godot` oder `app/`, kein `class_name`, kein Autoload. Die Testsuite (`tests/run_tests.gd`) lädt nichts aus diesem Ordner.

## Schriftmuster (`font_specimen/`)

Vergleicht Cinzel und IM FELL English mit der Godot-Standardschrift auf dem vorhandenen Grimmhain-Theme (nur gelesen über `ThemeFactory.build()`). Drei Seiten: Titel und Beispielkarte, Erklärung DE/EN, Größenstufen und lange Namen mit Umlauten und ß. **Interne Vorschau, keine Stilentscheidung, keine Releasefreigabe.**

**Starten im Godot-Editor (4.7.2):**

1. Ordner `godot/` als Projekt öffnen.
2. Im Dateisystem-Dock `res://asset_lab/font_specimen/font_specimen.tscn` doppelklicken.
3. Oben rechts „Aktuelle Szene starten" (F6), nicht „Projekt starten" (F5, das startet die App).
4. Seiten über die drei Buttons oben rechts wechseln. Fenstergröße frei ziehen, um andere Formate zu sehen.

**Starten auf der Kommandozeile** (aus dem Repository-Wurzelordner):

```bash
<godot> --path godot res://asset_lab/font_specimen/font_specimen.tscn
```

**Schriften.** Die Szene lädt die Dateien zur Laufzeit aus `assets/fonts/` und kopiert sie nicht ins Godot-Projekt. Dort liegen Datei, Lizenztext und Registerzeile zusammen, und `tests/ui/test_ui_theme.gd` (`test_no_unlicensed_fonts_embedded`) verlangt, dass keine Schriftdatei unter `godot/` liegt. Vor der Nutzung vergleicht die Szene den SHA-256 jeder Datei mit dem Assetregister. Fehlt eine Datei oder weicht sie ab, erscheint dort die Standardschrift mit dem sichtbaren Hinweis „ERSATZ: Standardschrift". Das funktioniert nur beim Start aus dem Repository, nicht in einem exportierten Build.

**Prüfen und Screenshots:**

```bash
# nur Layoutprüfung, headless, Exit 0 = nichts abgeschnitten
<godot> --headless --path godot -s res://asset_lab/font_specimen/check_font_specimen.gd

# Prüfung und Screenshots (echter Renderer nötig)
xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot --rendering-driver opengl3 \
  --audio-driver Dummy -s res://asset_lab/font_specimen/check_font_specimen.gd -- --shots
```

Geprüft wird in 1024×768 und 1280×800 mit logischer Größe = Fenstergröße (ohne Skalierung, ungünstigster Fall): alle Beschriftungen im Fenster, kein einzeiliger Text und kein Button schmaler als sein Text, keine verdeckten Zeilen bei Umbruch, keine Seite braucht Scrollen. Neue oder neu erzeugte Screenshots unter `docs/evidence/asset-lab/font-specimen/` müssen im Assetregister erfasst oder aktualisiert werden (`docs/masterplan/ASSET-REGISTER.md`, Abschnitt „Neue Mediendateien registrieren").
