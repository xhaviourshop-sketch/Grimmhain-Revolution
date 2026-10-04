# Vorbereitung · „Neue Partie“ in drei Schritten

Stand: 04.10.2026 · Godot 4.7.2 · Projekt `godot/` · Entscheidung: DA-89 (`docs/masterplan/DECISION-LOG.md`), Konzept: `docs/konzept/vorbereitung-neu.md`

Ersetzt den früheren Vierschritt-Wizard (`player-setup.md`, `role-setup.md`, `seating-setup.md`, `game-start.md` beschreiben den Stand davor). Der Regelkern und der `StartGame`-Befehl sind unverändert.

## Ablauf

Drei Medaillons oben (Runde, Namen, Rollen), unten „Zurück“ und „Weiter“, im letzten Schritt „Spiel starten“. Keine Bestätigungsknöpfe; Zurück verliert nichts (Namen, Rollenauswahl, Modus bleiben).

| Schritt | Inhalt |
|---|---|
| 1 Runde | Spielerzahl 6 bis 24 (Plus/Minus, Startwert 8), Zähler Dorf/Wölfe/Einzelgänger des Vorschlags (Teamsymbole), vier Akt-Karten, Schalter „App verteilt zufällig“ / „Echte Karten – ich weise zu“ |
| 2 Namen | Namen eintippen, per Tastatur-Diktat sprechen, mehrere auf einmal (Komma, „und“, Zeilenumbruch; Prüfliste), Liste einfügen, gespeicherte Gruppen. Nummerierte Namensschilder = Sitzordnung im Uhrzeigersinn; Schild antippen, dann früher/später schieben, ändern, entfernen; „Mischen“; Zähler „9 von 14“ mit Knopf „Spielerzahl anpassen“. Weiter erst, wenn alle Namen da sind (keine Platzhalter) |
| 3 Rollen | Vorschlag des Aktes nach Team gruppiert. Rolle antippen: Tauschen, Entfernen, Info (Lexikon). „Rolle hinzufügen“ je Team, „Neuer Vorschlag“. Besonderes: Trugbilderwolf gibt sich bei Prüfungen als eine andere Rolle aus (Zeile mit „ändern“, vorbelegt nach DA-88), Totenreichkarten-Schalter (Kartenschlucker). Hinweise und Blocker an der Fußzeile |

Modus „Echte Karten“: im Schritt 3 zwei Seiten „Rollen“ und „Zuordnung X von Y“. Zuordnung: Sitzring wie im Nachtbrett, Platz antippen, in der Rollenleiste die Rolle wählen („Zuordnung löschen“ möglich). Die Plätze zeigen nur ein Häkchen, nie die Rolle. Start erst, wenn alle zugeordnet sind.

## Akte

`ActCatalog` hält die vier Akte 1:1 aus `js/core/akte.js` (Test `test_prep_model`: alle Rollen im Katalog, Team = Katalog-Fraktion, Vereinigung = alle 72 Rollen). Der Dorfbewohner steht in keinem Akt (DA-90). Jeder Akt trägt 24 Personen (`ActCatalog.capacity` fragt den Vorschlag): Fehlende Plätze füllen weitere Einzelgänger- und Wolfsrollen, weitere Werwölfe bis zur Wolfsquote und, nur in Akt I, weitere Gebundene (Akt I bei 24: 3 Werwölfe, 7 Gebundene). Darüber ist die Karte gesperrt und nennt die Grenze.

`RoleSuggestion.for_act(akt, personen, totenreichkarten)`: Wolfsrollen nach der Staffel 1/2/3/4/5 ab 6/9/13/18/22 Personen (Reihenfolge der Akt-Karte), eine Einzelgängerrolle, Rest Dorf in der Reihenfolge aus PE-07; kleine Akte werden mit weiteren Einzelgänger- und Wolfsrollen des Aktes aufgefüllt. Deterministisch, ohne Zufall.

## Blocker und Warnungen

`PlayerSetup.blockers()` (Start technisch unmöglich) und `view()["warnings"]` (nur Anzeige):

| Blocker | Grund |
|---|---|
| `too_few_persons`, `too_many_persons`, `names_incomplete` | Personenzahl außerhalb 6 bis 24 oder Namen fehlen |
| `too_few_roles`, `too_many_roles`, `above_maximum` | Summe oder Höchstzahl der Startbesetzung (Kern lehnt ab) |
| `missing_wolf`, `missing_village` | Kern lehnt `missing_wolf_role` und `missing_village_role` ab |
| `missing_appearance` | Trugbilderwolf ohne Scheinrolle |
| `role_needs_death_cards` | Kartenschlucker ohne Totenreichkarten |
| `unknown_role`, `negative_count` | ungültige Eingabe |

Warnungen: `missing_solo` (keine Einzelgängerrolle, vorher Blocker) und die Hinweise PE-04 (`coach_small_round`, `simultaneous_solo_wins`).

## Anwendungsschicht

`PlayerSetup` (Operationen atomar, keine Bestätigungen): `set_player_count`, `fit_player_count_to_names`, `set_act`, `set_distribution_mode`, Namen (`add_person`, `import_names`, `replace_persons`, `rename_person`, `remove_person`, `move_person`, `shuffle_persons`), Rollen (`set_role_count`, `add_role`, `remove_role`, `replace_role`, `set_decoy_appearance`, `set_death_cards`, `apply_suggestion`), Zuordnung (`assign_role`, `unassign_role`, `swap_roles`, `distribute_randomly`), Start (`prepare_start`, `start_data`, `blockers`). Namensreihenfolge = `seat_order` = Reihenfolge von `players` im `StartGame`. Zufall nur über den gespeicherten Generator: `shuffle_persons` und die zufällige Verteilung leiten ihre Seeds aus der Seed-Quelle des Setups ab.

## Oberfläche

Code unter `godot/app/screens/new_game/`: Host `new_game_screen`, Schritte `round_step`, `names_step`, `roles_step` (Basis `prep_step`), Bauteile `step_medallions`, `act_card`, `team_counter`, `name_plate`, `role_chip`, `role_pool_view`, `choice_button`; Stil `app/theme/hain_style.gd` (überzieht wiederverwendete Bauteile wie `NameReviewCard` und `GroupCard`), Hintergrund `app/widgets/hain_backdrop.gd`. Hain-Teile aus `assets/ui/hain/`, Teamsymbole aus `assets/night/team/` (`tools/build_team_symbols.py`). Rückfragen zeigt ein eigener Dialog im Hain-Stil (`PrepDialog`). Mondsilber statt Gold, Blutrot nur für Aktives, Touchflächen mindestens 56 px.

## Prüfung

- `tests/unit/test_prep_model.gd`: Akt-Sätze gegen den Katalog, Vorschlag je Akt und Personenzahl als gültiger Start, Blocker und Warnungen, Namensreihenfolge = Sitz, Zuordnung im Kartenmodus, zufällige Verteilung mit gespeichertem Seed, StartGame-Struktur, Rollenaktionen, Zurück verliert nichts.
- `tests/ui/test_prep_screen.gd`: beide Modi bis zum Cockpit über echte Buttons, Weiter erst bei vollständigen Namen, Zurück verliert nichts.
- Aufnahmen: `godot/tools/capture_ui_screenshots.gd -- --only=prep --out=<Ordner>` (jeder Schritt in beiden Modi, 1024×768 und 2360×1640 mit Inhaltsskalierung wie auf dem Gerät). Headless-grün ist keine Tablet-Abnahme; Safari/iPad und Touch-Gefühl sind nicht geprüft.
