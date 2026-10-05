# Fenster-Optik (Feedback iPad-Test, Teil 5)

Stand 2026-10-05, Branch `feat/feedback-5`. Ziel von Markus: kein Standard-Fenster mehr, alle Fenster im Grimmhain-Rahmen wie „Karte zeigen“ (dunkler Grund, Eisenrahmen mit Ecken-Ornament, Grimmhain-Knöpfe), ein gemeinsamer Baustein.

**Baustein:** `GroveWindow` (`godot/app/theme/grove_window.gd`). `frame(panel)` setzt den Eisenrahmen der Aktionskarte, `dress(root)` rahmt alle Fensterflächen (`DialogPanel`, `DrawerPanel`, `ShowPanel`, Lexikon, Regelbuch) unter einem Knoten und zieht die Knöpfe im Hain-Stil an. Genutzt von `DetailPanel` (gezeigte Karten), `ConfirmDialog` (alle Rückfragen), jeder Cockpit-Ebene (`CockpitScreen`, an der einen Stelle, an der Ebenen eingehängt werden) und der Lexikonebene der Vorbereitung. Zeilen mit linksbündigem Text (Lexikon, Regelbuch) und Umschalter bleiben bewusst schlichte Zeilen; der Titel der Rückfragen steht in `GothicTitleLabel` (Grenze Gotisch).

Screenshots: `C:/Users/Marku/Downloads/Grimmhain-Feedback-5/` (1024x768, Dateiname = Spalte „Bild“). Bewertung „vorher“ nach dem Code (Theme-Fläche `DialogPanel`/`DrawerPanel`/`ShowPanel`: einfache Fläche mit dünnem Rand, keine Ornamente), „nachher“ nach dem Bild.

## Alle Fenster

| Fenster | Wo (Code) | Bild | Vorher | Nachher |
|---|---|---|---|---|
| Rollen zeigen, Liste | `CockpitLayers.role_list`, Werkzeug „Rollen“ | `fenster-rollen-zeigen-liste` | billig: Standardfläche, Knöpfe im Theme | gut: Eisenrahmen, Hain-Knöpfe, „Fertig“ |
| Rollen zeigen, Vorderseite | `CockpitLayers.role_card` | `fenster-rollen-zeigen-vorderseite` | gut (DetailPanel) | unverändert gut |
| Rollen zeigen, Rolle | `CockpitLayers.role_card` | `fenster-rollen-zeigen-rolle` | gut | gut; Knöpfe „Fertig“ und „Schließen“ |
| Karte zeigen | `CockpitLayers.show_card` | `fenster-karte-zeigen` | gut, aber kleine Schrift | gut: Zahl 112 (vorher 48), Beschriftung 32, Titel 64, Knopf „Fertig“ |
| Hinweiskarte („Hinweis für euch“) | `CockpitLayers.notice_card` | `fenster-hinweiskarte` | gut | gut; Bildplatz Bund-Bild offen (siehe Assets) |
| Karte der Toten (Kartenfenster) | `CockpitLayers.card_face` | gleicher Baustein wie Karte zeigen, kein eigenes Bild | gut | gut, Knopf „Fertig“ |
| Rückfragen (Beenden, Verwerfen, Rückgängig, Wiederholen, Begründung, Auswahllisten, Gruppen speichern/laden/umbenennen, Historie, Entfernen einer Person, Vorbereitung verlassen) | `ConfirmDialog` (eine Szene, eine Instanz in `main.tscn`, eine in der Vorbereitung) | `fenster-rueckfrage-verwerfen` als Vertreter | billig: Theme-Fläche `DialogPanel` | gut: Eisenrahmen, gotischer Titel, Hain-Knöpfe, Gefahr rot |
| Schublade „Rollen · nur Spielleitung“ | `CockpitLayers.private_drawer` | `fenster-privat` | billig: schlichte Seitenfläche | gut |
| Schublade Spielleitung (Korrekturen) | `CockpitLayers.gm_drawer` | `fenster-spielleitung` | billig | gut |
| Schublade Protokoll | `CockpitLayers.log_drawer` | `fenster-protokoll` | billig | gut |
| Schublade Kartenüberblick | `CockpitLayers.cards_drawer` | kein Bild (braucht Totenreichkarten); gleicher Baustein wie die drei Schubladen | billig | gut (nicht einzeln angesehen) |
| Rollenlexikon (Ebene) | `RoleLexicon.layer` | `fenster-lexikon` | billig: einfache Fläche | gut: Rahmen, Hain-Knöpfe in der Kopfzeile |
| Regelbuch (Ebene) | `RuleBook.layer` | `fenster-regelbuch` | billig | gut |
| Sichtschutz | `CockpitLayers.cover_panel` | `fenster-sichtschutz` | billig | Knopf „Weiter“ im Hain-Stil; die Fläche bleibt bewusst ein schlichter dunkler Vollbildschutz, damit nichts durchscheint. Text steht schmal und mittig, könnte ein gemaltes Bild vertragen (siehe Assets) |
| Lexikon-Ebene der Vorbereitung | `NewGameScreen.open_lexicon` | gleicher Baustein wie Rollenlexikon | billig | gut |
| Hinweis „Gespeichert“ / Meldungen (Toast) | `ToastHost` | kein Fenster, kein Bild | Textzeile | unverändert (keine Fensterfläche) |
| Rückgängig-Leiste | `ActionCard` (`UndoBar`) | kein Fenster, Teil der Karte | in der Karte | unverändert |

Nicht gefunden: Godot-eigene Fenster (`AcceptDialog`, `ConfirmationDialog`, `PopupPanel`, `Window`, `FileDialog`, `PopupMenu`). Es gibt kein Standard-Fenster im Projekt. Nicht einzeln fotografiert: Gruppen- und Historien-Rückfragen und der Kartenüberblick, weil sie denselben Baustein wie das Vertreterbild nutzen. Safari/iPad nicht geprüft.

## Knöpfe mit Programmierer-Text (geändert)

| Schlüssel | Fenster | Vorher (DE / EN) | Nachher (DE / EN) |
|---|---|---|---|
| `ui.cockpit.show.close` | Karte zeigen, Karte der Toten | Zurück zur Spielleitung / Back to game master | Fertig / Done |
| `ui.cockpit.roles.confirm` | Rollen zeigen, Rolle | Gesehen, Karte schließen / Seen, close card | Fertig / Done |
| `ui.cockpit.roles.close` | Rollen zeigen, bestätigte Rolle | Karte schließen / Close card | Schließen / Close |
| `ui.cockpit.roles.close_unconfirmed` | Rollen zeigen, Rolle | Ohne Bestätigung schließen / Close without confirming | Schließen / Close |
| `ui.groups.close` | Gruppenkarte der Vorbereitung | Zurück zur Eingabe / Back to entry | Schließen / Close |
| `ui.cockpit.action.continue_day` | Morgenkarte | Weiter zum Tag / Continue to the day | Weiter / Continue |
| `ui.cockpit.cover.resume` | Sichtschutz | Cockpit wieder anzeigen / Show cockpit again | Weiter / Continue |

Angepasst, weil sie die Knöpfe zitieren: Regelbuch (`ui.rulebook.c03.b05`, `c05.b05`, `c06.b07`, `c07.b01`) und der Regelbuch-Text zur gezeigten Karte (`ui.rulebook.c05`, nannte „Zurück zur Spielleitung“). Bewusst unverändert, weil sie eine Entscheidung benennen und kein Programmierertext sind: „Abbrechen und verwerfen“, „Beenden und verwerfen“, „Weiter vorbereiten“ (Rückfrage beim Verlassen der Vorbereitung), „Bestätigen“ der Quittung. Nicht angefasst: ungenutzte Schlüssel (`ui.setup.to_roles`, `ui.setup.distribution.to_seating`, `ui.setup.dialog.leave.continue`), nur erwähnt.

## Fehlende gemalte Bilder (Markus erstellt, mit fertiger Beschreibung für ChatGPT)

Regeln für jedes Bild (`docs/brand/MARKE.md`): ChatGPT-Projekt „Grimmhain Assets“, Design-Tafel als Vorlage anhängen, kein Text im Bild, kein Gold, nachtblau mit Mondlicht, warme Fensterlichter als einziger warmer Ton. Danach über den Skill/Ablauf „grimmhain-asset“ prüfen, in WebP umwandeln und im `ASSET-REGISTER.md` eintragen.

| Datei | Wofür | Plätze im Code | Beschreibung für ChatGPT |
|---|---|---|---|
| `godot/assets/ui/ladebild.png` | Ladebild-Hintergrund (Web-Ladeseite, Querformat 4:3, 2048x1536) | `web/shell.html` und `tools/export-web.js` (ohne Datei bleibt das jetzige Startbild) | „Gemaltes Querformat 4:3, detailreich im Stil der Startbildschirm-Illustration: ein dunkler Märchenwald bei Nacht, Vollmond hinter ziehenden Wolken, über einem Dorf mit warm erleuchteten Fenstern, Bodennebel. Unten in der Mitte freier, ruhiger Platz für Siegel und Ladebalken. Kein Text, kein Gold, nachtblau und Mondsilber, nur die Fenster leuchten warm.“ |
| `godot/assets/ui/bund-liebende.png` | Hinweiskarte „Ihr seid Liebende“ | `CockpitLayers._bond_picture` (ohne Datei kein Bild) | „Quadratisch, transparenter Hintergrund, kleines gemaltes Emblem: zwei ineinander verschlungene Dornenranken bilden ein Herz, in der Mitte ein dünner Mondsilber-Ring, schwarzes geschmiedetes Eisen, Mondsilber-Glanz. Kein Text, kein Gold, Ornament nur an den Enden.“ |
| `godot/assets/ui/bund-rivalen.png` | Hinweiskarte „Ihr seid Rivalen“ | wie oben | „Quadratisch, transparenter Hintergrund, kleines gemaltes Emblem: zwei gekreuzte, gezackte Dolche aus Mondsilber, dazwischen ein Riss aus Dornenranken, schwarzes geschmiedetes Eisen. Kein Text, kein Gold.“ |
| `godot/assets/ui/sichtschutz.png` (neuer Platz, noch nicht im Code) | Sichtschutz-Fenster | noch nicht angeschlossen (erst nach Freigabe bauen) | „Quadratisch 1:1, transparenter Hintergrund: ein geschlossenes schwarzes Eisentor mit Wurzeln und Dornen im Mondlicht, davor leichter Nebel. Kein Text, kein Gold, nachtblau und Mondsilber.“ |

Musik: `godot/assets/audio/musik-start.ogg` (Startbildschirm, Schleife, blendet leise ein, nach dem Tippen auf „Eintreten“ aus) und `musik-laden.ogg` (Platz benannt in `ScreenMusic.LOADING`, noch an keinen Bildschirm angeschlossen, weil die App keinen eigenen Ladebildschirm hat; die Web-Ladeseite läuft vor dem Start der Engine und kann keine Godot-Musik spielen). Ohne Dateien bleibt alles still wie bisher.
