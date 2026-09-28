# UI-Grundlage · Godot-Tablet-App

Stand: 26.09.2026 · Godot 4.7.2-stable · Projekt `godot/`

Technisches Fundament der Tablet-App: App-Shell, Navigation, sechs Ansichten als Platzhalter, Theme, Lokalisierung DE/EN und eine schmale Anwendungsschicht zum Regelkern. Keine Spiellogik, keine Assets, kein Audio. Darauf aufgebaut ist der Setup-Wizard „Neue Partie“ (Spieler → Rollen → Verteilung → Sitzordnung, `player-setup.md`, `role-setup.md` und `seating-setup.md`) mit „Partie starten“ (`game-start.md`); der Spielablauf nach dem Start folgt in eigenen Arbeitspaketen.

## Schichten

```
app/ (Szenen, Widgets, Theme)          liest GameSession.view()      sendet GameSession.submit(Command)
        │                              reagiert auf events_applied / view_changed
app/session/game_session.gd            einzige Stelle mit GameState und RulesEngine.apply
        │
core/ (Regelkern, unverändert)         RulesEngine.apply(state, command) -> CommandResult
```

- Der Regelkern kennt keine UI (`test_core_does_not_reference_ui`, zusätzlich `test_core_purity`).
- Nur `app/session/` darf `GameState`, `RulesEngine` und andere Regelklassen verwenden (`test_ui_does_not_touch_game_state`).
- `GameSession.view()` liefert immer eine neue Kopie aus einfachen Werten; es gibt keine öffentliche Eigenschaft vom Typ `GameState`.
- Keine Autoloads: Die Shell erzeugt `AppContext` (Einstellungen und Sitzung) und reicht ihn an jede Ansicht. Das hält Tests unabhängig und lässt sich später in Autoloads nach `03-godot-architecture.md` §4.1 überführen.

## Szenen und Verantwortungen

```
app/main.tscn                AppShell (Control, Vollbild)
├─ Background                Panel, Variation AppBackground
├─ SafeArea                  MarginContainer, Ränder = max(Geräte-Safe-Area, SAFE_MARGIN)
│  ├─ ScreenHost             ScreenRouter, genau eine aktive Ansicht
│  │  └─ <Ansicht>           eine der sechs Ansichten (BaseScreen)
│  └─ ToastHost              toast_host.tscn, Statusmeldungen, fängt keine Eingaben
└─ ConfirmDialog             confirm_dialog.tscn, Overlay für Rückfragen
```

| Datei | Verantwortung |
|---|---|
| `app/shell/app_shell.gd` | Theme setzen, Dienste erzeugen, sichere Fläche, zentrale Zurück-Logik, Beenden, Dialog und Statusmeldungen verbinden |
| `app/navigation/screen_ids.gd` | stabile Screen-IDs, Szenenpfade, Elternansicht für Zurück (einzige Quelle) |
| `app/navigation/screen_router.gd` | Ansicht wechseln, alte sofort entfernen, Übergang, Standardfokus |
| `app/screens/base_screen.gd` | Basis jeder Ansicht: Signale statt Router-Zugriff, Kopfzeile verdrahten, Standardfokus |
| `app/screens/start/` | Titel, Untertitel, „Eintreten“, Version |
| `app/screens/main_menu/` | Neue Partie, Fortsetzen, Cockpit, Einstellungen, Beenden (nur Desktop, abgesetzt) |
| `app/screens/new_game/` | Setup-Wizard: Host `new_game_screen` mit Schrittanzeige (`wizard_progress`) und genau einem Schritt: `player_step` (Namensschritt mit `person_row`, `player-setup.md`), `role_step` mit `role_row` (Rollenwahl) und `decoy_section` mit `decoy_copy_row` (geheime Trugbilderwolf-Scheinrollenwahl) und `distribution_step` mit `assignment_row` (Verteilung, geheimer Spielleiterbereich); Details in `role-setup.md` |
| `app/screens/continue/` | leerer Zustand „Kein Spielstand vorhanden“, Bereich `SaveSlotList` |
| `app/screens/settings/` | Sprache DE/EN, Bewegung reduzieren, Platzhalter Audio und Anzeige |
| `app/screens/cockpit/` | Geführte Partie: Phasenleiste, Sitzkreis, Ansagekarte für Nacht, Morgen, Tag und Sieg, Ebenen für Rollen, Protokoll und gezeigte Karten, Sichtschutz; Details in `cockpit.md` |
| `app/widgets/grimm_button.gd` | Button mit Übersetzungsschlüssel, Art primär/sekundär/Gefahr, Mindestgröße, Fokus, Umbruch |
| `app/widgets/grimm_label.gd` | Beschriftung mit Übersetzungsschlüssel und Platzhaltern (`{version}`) |
| `app/widgets/grimm_toggle.gd` | Umschalter mit Übersetzungsschlüssel |
| `app/widgets/header_bar/` | Kopfzeile: Zurück, Titel, Platz `%Actions` für spätere Aktionen |
| `app/widgets/confirm_dialog/` | Modal für Rückfragen (`DialogRequest`): Abbrechen links mit Fokus, optionale Alternative, Bestätigen rechts, 32 px Abstand, optional rot; optional scrollbare Auswahlliste (`DialogOption`); Fokussperre und Fokus-Rückgabe |
| `app/widgets/toast/` | Statusmeldung am unteren Rand, 2,5 s sichtbar |
| `app/theme/theme_tokens.gd` | alle Farben, Abstände, Radien, Rahmen, Schriftgrößen, Mindestgrößen, Zeiten |
| `app/theme/theme_factory.gd` | baut das Theme aus den Tokens (kein `.tres`) |
| `app/settings/app_settings.gd` | Sprache, Bewegung reduzieren, Linkshänder-Grundlage; nur im Speicher |
| `app/platform/app_platform.gd` | Desktop/Mobil, Beenden erlaubt, Version aus `project.godot` |
| `app/session/game_session.gd` | Anwendungsschicht zum Regelkern |
| `app/setup/*.gd` | Anwendungsschicht und Modell des Setups ohne Regelkern: `PlayerSetup`, `SetupDraft`, `SetupPerson`, `SetupResult`, `PersonNameRules`; Rollen: `SetupRoleCatalog` (lesender Katalogadapter), `RolePresentation`, `RolePoolDraft`, `RoleCopy`, `RoleSuggestion`, `DistributionDraft`, `RoleDistribution`, `RoleSetup`, `SetupDistributionView` |
| `app/app_context.gd` | Einstellungen, Sitzung und Setup-Entwurf für die Ansichten |
| `content/i18n/ui.de.po`, `ui.en.po` | UI-Texte |
| `tools/capture_ui_screenshots.gd` | Prüf-Screenshots (nicht Teil der App) |

Szenen enthalten keine Stilwerte (keine Farben, `theme_override_*`, Mindestgrößen oder Schriftgrößen). Das prüft `test_no_hardcoded_styles_outside_theme`; Farben stehen ausschließlich in `app/theme/`.

## Navigation und Screen-IDs

| ID | Szene | Zurück zu |
|---|---|---|
| `start` | `screens/start/start_screen.tscn` | – (Wurzel) |
| `main_menu` | `screens/main_menu/main_menu_screen.tscn` | `start` |
| `new_game` | `screens/new_game/new_game_screen.tscn` | `main_menu` |
| `continue` | `screens/continue/continue_screen.tscn` | `main_menu` |
| `settings` | `screens/settings/settings_screen.tscn` | `main_menu` |
| `cockpit` | `screens/cockpit/cockpit_screen.tscn` | `main_menu` |

- Ansichten melden Wünsche nur über Signale (`navigate_requested`, `back_requested`, `quit_requested`, `status_message_requested`); der Router verbindet sie beim Einhängen.
- `ScreenRouter.navigate(id)` entfernt die alte Ansicht sofort aus dem Baum und hängt die neue ein. Navigation zur aktiven Ansicht wird ignoriert. Deshalb erzeugt schnelles Mehrfachtippen nie doppelte Ansichten.
- Zurück hat genau einen Weg, `AppShell.go_back()`, für Zurück-Button, Escape (`ui_cancel`) und System-Zurück (`NOTIFICATION_WM_GO_BACK_REQUEST`). Escape wird in `AppShell._input` vor der GUI abgefangen, weil ein fokussiertes `LineEdit` `ui_cancel` sonst selbst verbraucht.
  1. offener Dialog → Abbruchaktion
  2. Ansicht erledigt es selbst (`handle_back`; „Neue Partie“: offenen Modus schließen oder bei unbestätigten Änderungen nachfragen)
  3. Elternansicht → dorthin
  4. Start → Desktop: Rückfrage „Grimmhain beenden?“, Mobilgerät: App verlassen
- `application/config/quit_on_go_back=false`: Android-Zurück beendet die App nicht automatisch, sondern läuft über dieselbe Logik.
- Cockpit mit laufender Partie: Zurück schließt zuerst eine offene Ebene oder den Sichtschutz und fragt sonst vor dem Verlassen nach; die Partie bleibt erhalten (`cockpit.md`).
- Rückfragen: Ansichten senden `BaseScreen.dialog_requested(DialogRequest)`, der Router reicht sie an die Shell, die Shell öffnet `ConfirmDialog.open_request()`. Jede Aktion hat einen eigenen Rückruf; Beenden nutzt denselben Weg.

## Dialog als Modal

- Die Abdunklung (`Dim`, Vollbild über der sicheren Fläche) fängt Maus und Touch ab.
- Tab, Shift+Tab und Pfeiltasten wechseln in `ConfirmDialog._input` nur zwischen den sichtbaren Dialogaktionen (Abbrechen, optional Alternative, Bestätigen) und werden als behandelt markiert.
- Setzt Code den Fokus in den Hintergrund, holt `gui_focus_changed` ihn in den Dialog zurück.
- Escape und System-Zurück lösen über die Shell die Abbruchaktion aus.
- Nach dem Schließen erhält das vorher fokussierte Control den Fokus zurück, sofern es noch sichtbar ist. Erst danach läuft der Rückruf, der den Fokus neu setzen darf (z. B. nach dem Entfernen auf die nächste Zeile).
- Solange ein Dialog offen ist, liefert `open_request()` für weitere Anfragen `false`; es entsteht nie ein zweiter Dialog.
- Drei Aktionen nutzen die breitere Karte (`DIALOG_WIDE_WIDTH`).
- Auswahlliste: `DialogRequest.options` (`DialogOption` mit Knotenname, Schlüssel, Platzhaltern, Rückruf; `DialogOption.header()` für Zwischenüberschriften) erscheint scrollbar über den Aktionen, höchstens Fensterhöhe − `DIALOG_LIST_RESERVED_HEIGHT`. Die erste Option erhält den Fokus, alle Optionen gehören zur Fokussperre, eine gewählte Option schließt den Dialog und ruft ihren Rückruf. Ohne `confirm_key` entfällt die Bestätigungsaktion. `title_values` füllt Platzhalter im Titel. Genutzt von der manuellen Rollenauswahl.

## Theme-Tokens

| Gruppe | Token | Wert |
|---|---|---|
| Hintergrund | `BG_APP` · `BG_SURFACE` · `BG_SURFACE_RAISED` | `#0b0d14` · `#151924` · `#1f2433` |
| Overlay | `BG_OVERLAY` | `#050710` mit 78 % Deckung |
| Rahmen | `BORDER_SUBTLE` | `#2e3446` |
| Gold | `GOLD` · `GOLD_BRIGHT` · `GOLD_DEEP` | `#c9a84c` · `#e0c26e` · `#a8883a` |
| Gefahr | `DANGER` · `DANGER_BRIGHT` · `DANGER_DEEP` | `#9b3a3a` · `#ad4545` · `#7c2d2d` |
| Meldungen | `DANGER_TEXT` (Fehler) · `WARNING_TEXT` (Hinweis) | `#ec9f97` · `#e0c26e`, immer mit Textpräfix „Fehler:“/„Hinweis:“ |
| Text | `TEXT_PRIMARY` · `TEXT_MUTED` · `TEXT_ON_GOLD` · `TEXT_DISABLED` | `#ece7dc` · `#aaa393` · `#15110a` · `#6b675f` |
| Fokus | `FOCUS_RING` | `#f3de9f`, Rahmen 3 px mit 4 px Abstand |
| Deaktiviert | `DISABLED_FILL` · `DISABLED_BORDER` | `#181b23` · `#262a35` |
| Abstände | `SPACE_XS/S/M/L/XL` | 4 · 8 · 16 · 24 · 32 |
| Radien | `RADIUS_S/M/L` | 6 · 10 · 16 |
| Rahmen | `BORDER_THIN/THICK` · `FOCUS_WIDTH` | 1 · 2 · 3 |
| Schrift | `FONT_CAPTION/COMPACT/BODY/BUTTON/SUBTITLE/HEADING/TITLE` | 16 · 18 · 20 · 22 · 24 · 30 · 64 |
| Bedienflächen | `TOUCH_MIN` · `BUTTON_SECONDARY_HEIGHT` · `BUTTON_PRIMARY_HEIGHT` · `BUTTON_PRIMARY_MIN_WIDTH` | 48 · 56 · 64 · 240 |
| Layout | `SAFE_MARGIN` · `SCREEN_PADDING` · `MENU_COLUMN_WIDTH` · `CONTENT_MAX_WIDTH` · `SIDE_COLUMN_WIDTH` | 16 · 24 · 480 · 880 · 360 |
| Overlays | `TOAST_WIDTH` · `TOAST_BOTTOM_OFFSET` · `DIALOG_WIDTH` · `DIALOG_WIDE_WIDTH` · `SWITCH_WIDTH`×`SWITCH_HEIGHT` | 420 · 88 · 560 · 720 · 64×32 |
| Setup | `SETUP_SIDE_WIDTH` · `INPUT_HEIGHT` · `IMPORT_TEXT_MIN_HEIGHT` · `PERSON_NUMBER_WIDTH` · `SCROLLBAR_WIDTH` | 360 · 56 · 96 · 44 · 12 |
| Rollen-Setup | `ROLE_COUNT_WIDTH` · `ASSIGNMENT_STATE_WIDTH` · `ROLE_LIST_MIN_HEIGHT` · `DIALOG_LIST_RESERVED_HEIGHT` | 56 · 200 · 240 · 300 |
| Fenster | `WINDOW_MIN_WIDTH`×`WINDOW_MIN_HEIGHT` | 1024×640 (nur Desktop) |
| Bewegung | `TRANSITION_SECONDS` · `TRANSITION_OFFSET` · `TOAST_FADE_SECONDS` · `TOAST_VISIBLE_SECONDS` | 0,2 s · 12 px · 0,15 s · 2,5 s |

Kontraste (WCAG, geprüft in `test_text_contrast`): Text auf Flächen ≥ 4,5:1 (`TEXT_PRIMARY` auf `BG_SURFACE` 14,2:1, `TEXT_MUTED` auf `BG_SURFACE` 7,0:1, `GOLD` auf `BG_SURFACE` 7,7:1, `TEXT_ON_GOLD` auf `GOLD` 8,2:1, `TEXT_PRIMARY` auf `DANGER` 5,6:1), Fokusrahmen ≥ 3:1 (`FOCUS_RING` auf `BG_SURFACE` 13,2:1). Meldungsfarben auf `BG_SURFACE`: `DANGER_TEXT` 8,3:1, `WARNING_TEXT` 10,1:1.

Neue Theme-Variationen des Setups: `CompactButton` (Listenzeilen, 48 hoch, Schrift 18), Labels `SectionLabel`, `ErrorLabel`, `ErrorCaptionLabel`, `WarningLabel`, `BadgeLabel`, Panels `PersonRowPanel`, `WarningBadge`, `SummaryPanel`, `ListPanel` (Zuordnungsliste) und `SecretPanel` (geöffneter Spielleiterbereich, Hinweisrahmen); dazu Stile für `LineEdit`/`TextEdit` (Goldrahmen im Fokus, gesperrt gedämpft), `VScrollBar` und Tooltips.

**Zustände.** Jede Button-Variation (`PrimaryButton`, `SecondaryButton`, `DangerButton`) hat eigene StyleBoxen für normal, hover, pressed, focus und disabled. Primär ist gold gefüllt, sekundär eine dunkle Fläche mit Rahmen, Gefahr gedämpftes Rot. Gedrückt hat einen dickeren Rahmen, deaktiviert einen dünneren Rahmen und schwächeren Text. Fokus ist ein separater heller Rahmen außerhalb des Buttons. Umschalter zeigen den Zustand über die Knopfposition (Theme-Symbol aus einfachen Formen), die Sprachwahl zusätzlich als Textzeile „Aktive Sprache: …“. Information hängt damit nie allein an Farbe.

**Schrift.** Das Projekt bettet bewusst keine Schrift ein: `assets/fonts/` (Cinzel, IM Fell English) hat keine Lizenzdateien im Repository, das Assetregister verlangt sie aber. Verwendet wird die Standardschrift der Engine. Die Schriftentscheidung ist offen (Vorschlag `05` §2.3: Cinzel für Titel, eine OFL-Lesetextschrift wie Source Sans 3 oder Alegreya Sans, jeweils mit Lizenzdatei). Geprüft durch `test_no_unlicensed_fonts_embedded`.

## Lokalisierung

- Dateien: `godot/content/i18n/ui.de.po` und `ui.en.po`, registriert unter `internationalization/locale/translations`, Rückfall `en`. Godot lädt `.po` direkt, ohne Importschritt.
- Schlüssel sind `msgid`s nach dem Muster `app.*` und `ui.<bereich>.<element>` (263 Schlüssel, davon 185 `ui.setup.*` sowie 22 `ui.role.*` und 3 `ui.faction.*`, identisch in beiden Dateien).
- Szenen setzen nur `text_key`. Kein sichtbarer Text steht in Szenen oder Skripten (`test_no_literal_texts_in_scenes_or_scripts`).
- `GrimmButton`, `GrimmLabel` und `GrimmToggle` übersetzen selbst (`tr(text_key)`) und aktualisieren sich bei `NOTIFICATION_TRANSLATION_CHANGED`. Die automatische Übersetzung der Engine ist für sie abgeschaltet, damit der sichtbare Text in `text` steht und prüfbar ist.
- Sprachwechsel: `AppSettings.set_language("de"|"en")` setzt die Locale; die Shell verteilt die Änderung sofort an alle Knoten. Andere Sprachen werden abgelehnt. Die Wahl wird noch nicht gespeichert.
- Nutzerdaten (Personennamen) stehen in einfachen `Label`s der Gruppe `user_content`; alle anderen Texte haben einen Schlüssel. Platzhalter von Eingabefeldern setzt die Ansicht per `tr()` und erneuert sie beim Sprachwechsel.
- Neuer Text: Schlüssel in beide `.po`-Dateien eintragen, im Szenenknoten `text_key` setzen. `test_po_files_have_same_keys` und `test_all_referenced_keys_exist_in_both_languages` finden Lücken.
- Lange Texte: Beschriftungen und Buttons in Spalten brechen um. `test_long_german_texts_do_not_overlap` verlängert alle deutschen Texte um etwa 50 % (Pseudo-Locale `de_XA`) und prüft 1024×768 erneut.

## Barrierearme Grundlage und Bewegung

- **Bewegung reduzieren** (`AppSettings.reduced_motion`) setzt die Übergangszeit des Routers und die Einblendung der Statusmeldung auf 0. Beim Einschalten wird ein laufender Übergang sofort beendet. Sonst blendet eine neue Ansicht in 200 ms mit 12 px Aufwärtsbewegung ein (Cubic, Ease-out). Eingaben sind während eines Übergangs nie gesperrt.
- **Fokus:** Jeder Button ist fokussierbar (`FOCUS_ALL`), jede Ansicht setzt einen Standardfokus (Startbutton, erste Menüaktion, Namensfeld in „Neue Partie“, sonst Zurück). Tab, Shift+Tab und Pfeiltasten bewegen den Fokus über die Container, Enter oder Leertaste lösen aus, Escape läuft über Zurück.
- **Touch und Maus:** Buttons reagieren auf das Signal `pressed`. Touch löst über `input_devices/pointing/emulate_mouse_from_touch=true` dieselben Mausereignisse aus. Keine Gesten, kein Langdruck.
- **Linkshänder:** `AppSettings.left_handed` existiert mit Signal, hat aber noch keine Wirkung. Die spätere Spiegelung gehört ins Cockpit mit echtem Sitzkreis.
- **Skalierung:** Basis 1280×800, Streckung `canvas_items` mit Aspekt `expand`. Alle Layouts nutzen Container und Anker, keine festen Positionen.

## Tests und Prüfbefehle

```bash
godot/tests/run_all.sh                      # Regelkern und UI, Exit 0 = grün
godot/tests/run_all.sh --filter=test_ui     # nur UI-Grundlage
godot/tests/run_all.sh --filter=test_setup  # nur Spieler-Setup (siehe player-setup.md)
godot/tests/run_all.sh --filter=test_role   # Rollenwahl (siehe role-setup.md)
godot/tests/run_all.sh --filter=test_distribution  # Verteilung und Geheimhaltung
```

UI-Tests liegen unter `godot/tests/ui/` und erben von `tests/ui_test_case.gd`. Sie starten `app/main.tscn` im Root-Viewport in genau 1024×768, 1280×800 oder 1920×1080 logischen Pixeln ohne Skalierung. Das ist der ungünstigste Fall: Auf einem echten 1024×768-Gerät skaliert Godot die Basis 1280×800 herunter.

Geprüft werden Control-Rechtecke, keine Pixel:
- alles liegt im Viewport und in der sicheren Fläche
- keine Bedienelemente überlappen, kein Text überdeckt einen fremden Button
- kein Control ist kleiner als seine Mindestgröße (also nichts abgeschnitten)
- Buttons sind mindestens 48×48, Primärbuttons mindestens 64 hoch
- zwischen Abbrechen und Bestätigen liegen mindestens 32 px

Prüf-Screenshots (brauchen einen echten Renderer, headless gibt es kein Bild):

```bash
xvfb-run -a -s "-screen 0 1920x1080x24" <godot-4.7.2> --path godot --rendering-driver opengl3 \
  --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd [-- --only=role-setup]
```

Ergebnis: `docs/evidence/ui-foundation/*.png`, `docs/evidence/player-setup/*.png` und `docs/evidence/role-setup/*.png`. Mit `--only=<Teilstring>` nur passende Aufnahmen. Die Bilder sind Prüfartefakte, keine Produktionsassets.

## Lokal starten (Godot 4.7.2)

1. Godot 4.7.2-stable installieren (Linux: `godot/tools/install_godot.sh` lädt und prüft die gepinnte Version).
2. Im Projektmanager „Importieren“ → `godot/project.godot` wählen, oder `godot --path godot -e` für den Editor.
3. Starten mit F5 im Editor oder `godot --path godot`. Die Hauptszene ist `res://app/main.tscn`.
4. Tablet-Format testen: im Editor unter Projekt → Projekteinstellungen → Anzeige → Fenster eine Testgröße setzen (z. B. 1024×768), oder das Fenster frei skalieren (Desktop-Minimum 1024×640).

## Bekannte Grenzen

- Keine gespeicherten Einstellungen; Sprache und Bewegung gelten nur bis zum Neustart.
- Keine Schrift eingebettet (Lizenzfrage offen); die Engine-Standardschrift ist neutral, aber noch nicht die Grimmhain-Typografie.
- Safe Area nur auf Mobilgeräten aus `DisplayServer.get_display_safe_area()`; auf echten Geräten mit Notch oder Gestenleiste ungetestet.
- Beim ersten Anzeigen hat der Standardbutton sichtbaren Fokus, auch auf Touchgeräten.
- Kein Portrait-Layout (`window/handheld/orientation = sensor_landscape`).
- Keine CI-Screenshots; die Bilder entstehen lokal oder in der Cloud mit Xvfb.
- Die Statusmeldung schwebt 88 px über dem unteren Rand und verdeckt dabei 2,5 s lang den unteren Listenbereich (fängt keine Eingaben ab).
- Die Pfeiltasten im Dialog wechseln die Aktion wie Tab; im Begründungsfeld bewegen links/rechts den Cursor.
