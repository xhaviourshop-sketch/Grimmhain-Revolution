# Cockpit · geführte Partie

Stand: 29.09.2026 · Godot 4.7.2 · Projekt `godot/` · Branch `feature/night-ui-expansion`

Das Cockpit führt die Spielleitung durch eine laufende Partie: Nacht, Morgenbericht, Tag, Hinrichtung und Siegbestätigung. Grundlage ist der Regelkern; das Cockpit hat keine eigene Nachtreihenfolge, keine eigene Rollenregel und keine eigene Zustandsverwaltung. Visuell und auf einem Tablet ist es noch nicht geprüft (nur headless Modell-, Layout- und Integrationstests).

Erreichbar: Hauptmenü → „Neue Partie“ → Setup bis „Partie starten“, oder Hauptmenü → „Cockpit“ bei laufender Partie.

## Aufbau

| Bereich | Inhalt |
|---|---|
| Kopfleiste (schmal) | Zurück (fragt bei laufender Partie nach, die Partie bleibt erhalten), Phase, Runde und Nachtfortschritt („Nacht 2 · Schritt 3 von 7 erledigt“), Lebende, Speicherstand mit „Erneut speichern“ nach einem Fehler; Nacht blau, Tag und Morgen warm |
| Hinweiszeile | übersprungene Schritte, niemand lebt (ohne Rollen); außerhalb der Nacht bei jeder verdeckten Karte ein neutraler Hinweis je Phase (PE-01) |
| Spielbrett | Der Sitzkreis füllt die Mitte der Ansicht: etwa 85 bis 92 Prozent der nutzbaren Fläche (geprüft in `test_cockpit_screen`), keine dauerhafte Seitenspalte. Plätze im Uhrzeigersinn: Platznummer, Name, „†“ für Tote, „(N)“ für heute Nominierte, Textzeichen „›“ für wählbare Ziele, „✓“ für die Auswahl und „•“ für handelnde Personen (nie nur Farbe). Nie eine Rolle. Bei 13 bis 24 Personen kompakte Plätze (48 px hoch, 96 bis 120 px breit). Tischfläche nachts blau, am Tag braun |
| Ansagekarte | liegt in der freien Tischmitte des Sitzkreises und verdeckt keinen Platz: Kontext, „Sag jetzt“ (Vorlesetext), „Tu jetzt“ (Anweisung), Auswahl. Der Text scrollt (`Scroll`); alle Aktionsbuttons stehen in einem festen Bereich darunter (`Actions`) und bleiben ohne Scrollen sichtbar |
| Werkzeugleiste (schmal, unten) | Protokoll, Rollen (privater Bereich), Rollen zeigen (neutrale Liste, dann Karte je Person), Spielleitung (Korrekturen, Rückgängig, Partie beenden), Verbergen (Sichtschutz), Lexikon, Regelbuch; ohne Partie deaktiviert. Jedes Werkzeug öffnet als Ebene über dem Brett |

## Nachtbrett (P3, 01.10.2026)

Das Cockpit ist ein Nachtbrett im Stil von `Spielfeld.png` und Mockup V3 (`docs/assets/p2-mockup/`). **Dieser Abschnitt ersetzt die Beschreibung von Kopfleiste, Spielbrett und Werkzeugleiste im Abschnitt „Aufbau“.** Die Regeln der Ansagekarte, Ebenen und der Geheimhaltung gelten unverändert. Die Bilder liegen unter `godot/assets/night/` (Registerstatus `intern-freigegeben`, Veröffentlichung gesperrt, siehe `DECISIONS.md`).

| Bereich | Inhalt |
|---|---|
| Hintergrund | Dorfplatz bei Nacht (G1) als eigene Ebene mit Farb- und Randdämpfung (`night_backdrop.gdshader`, `night_vignette.gdshader`) |
| Porträtplätze | Ellipse im Uhrzeigersinn (`PortraitRingLayout`), Platz 1 knapp links oben. Porträt 66 px (bis 12 Personen 76 bzw. 88 px), Nummern-Abzeichen, Namensschild, Ring für Zustand (handelnd, gewählt, wählbar, tot). Gesicht je Personen-ID automatisch und stabil (`PortraitAssignment`, bis 24 Personen nie doppelt); die Auswahl durch die Spielleitung folgt in P4 |
| Zustandsabzeichen | Schutz, Gift, Markiert, Stumm, Sonder, ab 24 px unten rechts am Porträt (nur Spielleitung, `GameSession.board_marks`, `NightBoardView`). Tote tragen den Tod als Ring und „†“ |
| Nachtleiste | oben, Rollensymbole in Aufrufreihenfolge (`GameSession.night_order`). Auf 4:3 eingeklappt als Chip, ab 16:10 voll; Pfeile blättern |
| Laschen | links Protokoll, rechts Optionen (Tippfläche 52 px breit). Darunter am rechten Rand „Verbergen“ (Auge) und „Sichtschutz“ (Schloss) |
| Optionen | Werkzeuge Privat, Rollen zeigen, Spielleitung, Lexikon, Regelbuch, Timer-Einstellungen, „Nacht-Timer anzeigen“, Einstellungen |
| Aktionskarte | Variante A in der Tischmitte: Rollenbild (nur Nacht), Titel, Anweisung, Zielplatz mit Pfeilen, Nebenaktionen, „i“ für Details. Die Hauptaktion steht als roter Knopf unten rechts („Nächster Schritt“ bzw. die Aktion selbst, z. B. „Auswahl bestätigen“) |
| Unten | links Phase und Timer, rechts Rückgängig und Hauptaktion; im Linkshändermodus vertauscht. Ecke oben links: Zurück, Nachtfortschritt, Lebende, Speicherstand |

**Verbergen** blendet alle geheimen Zustände aus: Abzeichen, Statusringe, Hervorhebung der handelnden Person, Nachtleiste und Rollenbild der Karte. Es bleiben Namen, Porträts und tot oder lebendig. Der Zustand ist nur Bedienzustand, wird nicht gespeichert und schaltet die Regeln nicht. **Sichtschutz** (früher „Verbergen“) blendet weiter das ganze Cockpit aus.

**Anzeige-Timer:** Dauer je Phasengruppe (Tag und Diskussion, Nacht) in den Optionen einstellbar, keine Standarddauer. Tippen auf die Anzeige startet und pausiert. Bei Ablauf steht die Anzeige auf 0:00 (kein Ton, keine Regelwirkung). Gespeichert werden Dauer, Restzeit und Pause im Block `ui` der Speicherhülle (`DisplayTimer`, `SaveService`), nie im Regelkern. Der Timer zählt nur, solange das Cockpit offen ist.

## Bedienhand (Rechts-/Linkshänder, NQ-04)

Die Einstellung „Bedienhand“ in den Optionen (Buttons „Rechtshändig“ / „Linkshändig“, Zeile „Aktiv: …“) legt fest, an welchem Ende des festen Aktionsbereichs der Ansagekarte die Hauptaktion steht: rechts bei rechtshändig (Standard), links bei linkshändig. Der Wechsel wirkt sofort (auch bei geöffnetem Cockpit), wird in `user://settings.json` gespeichert (`left_handed`) und gilt nach dem Neustart. Umgesetzt durch Umordnen der vorhandenen Buttons in `ActionCard.set_left_handed`: Auswahl, offene Karte und Signalverbindungen bleiben unberührt.

**Der Sitzkreis wird nie gespiegelt:** Sitzordnung, Personenreihenfolge und Nachbarn sind in beiden Modi identisch, jeder Platz liegt an derselben Stelle. Ebenfalls unverändert: Texte, Symbole und Porträts, Spielregeln und Befehle. Ebenen (Protokoll, Rollen, gezeigte Karte, Lexikon, Regelbuch) und Dialoge liegen über dem Cockpit und bleiben mittig. Prüfung: `test_handedness` (headless, Rechteckprüfungen; keine Tablet- und Touchabnahme).

## Detailansichten

Gezeigte Karte, Hinweiskarte, Ansagekarte, Rollenkarte und Kartenfläche sind `DetailPanel`s (`detail_panel.gd`): Überschrift und Text scrollen, wenn sie die Höhe der Ebene überschreiten; die Buttons stehen in einem festen Bereich darunter. Im Kartenfenster der Ansagekarte liegen Spielen, Aufbewahren, Tauschen, Zeigen, Überblick und Schließen im festen Aktionsbereich, auch bei dem längsten Kartentext in Deutsch und Englisch (`test_cards_ui_closing`, `test_board_layout`).

## Geheimhaltung

- Sitzkreis, Phasenleiste und Hinweise enthalten keine Rollen und keine Nachtinformationen.
- Karten mit geheimem Inhalt (Nachtschritte, Prompts, Reaktionen, Siegkandidaten) sind in der Nacht sichtbar, weil alle die Augen geschlossen haben. In Morgen und Tag erscheinen sie verdeckt („Nur für die Spielleitung“) und erst nach „Anzeigen“; mit der nächsten Handlung sind sie wieder verdeckt. Verdeckt entstehen keine Knoten mit geheimem Inhalt, und der Sitzkreis markiert dann weder handelnde noch wählbare Personen.
- Jede Hinrichtung läuft über eine verdeckte Prüfkarte mit der Vorschau des Regelkerns. Sie erscheint immer, damit ihr Auftauchen nichts über Spiegelwolf, Cerberus oder den Weisen verrät.
- Rollen, Protokoll, Morgendetails und geheime Tagesaktionen (Amalia, Nekromant) stehen in Ebenen, die erst beim Öffnen gebaut und beim Schließen, beim Sichtschutz, bei Zurück und beim Verlassen der Ansicht entfernt werden. Tippen neben die Schublade schließt sie.
- „Karte zeigen“ (Informationsrollen) und „Ansagekarte zeigen“ (Morgen) ersetzen das Cockpit vollständig und zeigen nur eine Positivliste: beim Orakel das gezeigte Ergebnis ohne Wahrheit, beim Morgen nur Namen der Toten (Rolle nur mit Setup-Option), Wiederbelebte und ausdrücklich öffentliche Hinweise.
- Sichtschutz blendet das ganze Cockpit aus und entfernt offene Ebenen. Rückkehr per Button „Weiter“ (Abweichung von `02` §8 „Rückkehr nur über Halten“: kein Halten ohne Gerätetest).
- Die zeigbaren Ebenen erhalten nur ihre öffentlichen Daten: „Karte zeigen“ nur Rolle des Schritts und Positivliste, die Ansagekarte nur den öffentlichen Teil des Morgenberichts. Das Protokoll trägt denselben Warnhinweis wie der Rollenbereich, weil es alle geheimen Ereignisse enthält.
- **Offene Reaktionen für Mitlesende (PE-01, umgesetzt 29.09.2026):** Die öffentliche Hinweiszeile nennt weder Anzahl noch Art, Besitzer oder Existenz einer offenen Reaktion. Außerhalb der Nacht zeigt sie bei jeder verdeckten Karte (Reaktion, Prompt, Siegentscheidung, Hinweiskarte) denselben neutralen Text, in der Morgenauflösung „Die Spielleitung bereitet den Morgen vor.“, am Tag „Die Spielleitung bereitet den nächsten Schritt vor.“ (`CockpitView.warnings`). Anzahl, Art und Besitzer stehen nur auf der Karte der Spielleitung. Grenze: Der Regelkern bleibt nur bei offener Reaktion in der Phase „Morgen“, und statt des Morgenberichts erscheint zuerst eine verdeckte Karte; daraus und aus Handlungen am Tisch oder der Bedienzeit bleibt ein Rückschluss möglich (Decision Log DA-46). *(Frühere Fassung: „Grenzen (Review 29.09.2026, nicht entschieden)“, Hinweiszeile mit Anzahl.)* Unabhängig davon erhalten zeigbare Karten keine privaten Statusinformationen.
- **Rolle in der Todesansage:** Mit der Setup-Option zeigt die Ansage die Rolle, die die Person beim jeweiligen Tod hatte. Der Regelkern hält sie im Ereignis `SeatDied` fest (`role_id`); eine spätere Rollenänderung, eine Wiederbelebung oder ein zweiter Tod schreibt eine frühere Ansage nicht um. Ereignisse werden nicht gespeichert, sondern beim Laden per Replay neu erzeugt; das Speicherformat (Schema 12) ändert sich dadurch nicht, und vorhandene Spielstände liefern beim Laden dieselbe historische Rolle. Ohne Setup-Option enthält der öffentliche Teil keine Rolle (`role_id` leer).

## Ablauf

1. **Nacht beginnen.** Der Regelkern plant die Nacht und öffnet den ersten Schritt selbst.
2. **Schritt ankündigen.** Die Karte nennt Rolle bzw. Gruppe, handelnde Personen (im Sitzkreis hervorgehoben), Nummer „Schritt 3 von 7“ und den Vorlesetext. „Schritt beginnen“ sendet `BeginStep`; überspringbare Schritte (Rudel) haben „Überspringen …“ mit Pflichtbegründung.
3. **Prompt beantworten.** Eine Karte für alle Antwortarten des Regelkerns: Personenwahl im Sitzkreis (nur zulässige Plätze antippbar, Auswahl gold, „Auswahl bestätigen“ erst bei passender Anzahl, „Niemand / verzichten“ nur bei Mindestzahl 0), Ja/Nein, Bestätigen („Gezeigt“, „Zur Kenntnis genommen“), Optionen (Lehrling, Frankenstein), Zeitpunkt (Todesprediger). Abbrechbare Schritte haben „Schritt abbrechen …“ mit Begründung. Beim Orakel kann das gezeigte Ergebnis mit Begründung geändert werden.
4. **Nacht abschließen**, sobald alle Schritte erledigt sind (Hinweis auf entfallene oder übersprungene Schritte).
5. **Morgenauflösung.** Offene Reaktionen (Sensenträger, Besessener Wolf, Ritter, Schmiedewaffe, Dämonischer Wolf) erscheinen als verdeckte Schritte.
6. **Morgenbericht** vor den Tagesaktionen: Vorlesetext aus dem öffentlichen Teil, „Ansagekarte zeigen“, „Private Details …“ (Ursachen, Rettungen, entfallene Schritte, Reaktionen), „Weiter“.
7. **Tag.** Nominierung in zwei Schritten (wer nominiert, wen), öffentliche Liste der Nominierungen, heutige Tode als Vorlesetext. Keine Stimmenerfassung: Die Spielleitung zählt am Tisch. Jede Person nominiert und wird nur einmal nominiert (DA-95); Gesperrtes ist ausgegraut. Nominierte tragen einen Blutrot-Ring, darunter die Vorlesezeile zur Verteidigung. Hinrichtung in zwei Tipps (DA-98): nominierte Person antippen, dann „Hinrichten“; die Karte zeigt sofort die Prüfung (Spiegelung, Cerberus-Abwehrfrage, Fluchdauer des Weisen), ohne Rückfrage. „Niemand“ statt Hinrichtung, ebenfalls ohne Rückfrage. Danach „Tag beenden“ und die nächste Nacht.
8. **Sieg.** Erkannte Kandidaten erscheinen verdeckt. Bestätigen genau eines Kandidaten mit Rückfrage beendet die Partie; „Alle ablehnen …“ verlangt eine Begründung.

Mehrfachtippen: Jede Aktion sperrt die Karte bis zur neuen Sicht; Tippen auf einen bereits ersetzten Button wird ignoriert. Abgelehnte Befehle zeigen eine Fehlermeldung („Fehler: … Nichts wurde geändert.“) in Karte und Statusmeldung.

## Schichten

| Datei | Aufgabe |
|---|---|
| `app/session/game_session.gd` | hält Zustand, Befehle und Ereignisprotokoll; Sichten und Befehlsbausteine (`start_night`, `begin_next_step`, `answer_targets`, `answer_choice`, `nominate`, `decide_execution`, `gm_correction` …) setzen nur Prompt-ID, Stufe oder Schritt-ID ein |
| `app/session/cockpit_view.gd` | öffentliche Cockpit-Sicht, nächste Handlung, Hinrichtungsvorschau, geheime Tagesaktionen, privater Rollenbereich |
| `app/session/prompt_view.gd` | offener Prompt als Kartendaten: Antwortart je Besitzer und Stufe, zulässige Personen, zulässige Anzahlen `counts` (aus `RulesEngine.target_counts`), Teilantworten, Positivliste `show` |
| `app/session/morning_report.gd` | Morgenbericht (öffentlich/privat) und heutige öffentliche Tode |
| `app/screens/cockpit/action_card.gd` | eine Karte für alle Handlungen, meldet Aktionen über `requested` |
| `app/screens/cockpit/cockpit_layers.gd` | Ebenen: Rollen, Protokoll, gezeigte Karte, Ansagekarte, Morgendetails, Sichtschutz |
| `app/screens/cockpit/detail_panel.gd` | Detailansicht: scrollender Text, feste Aktionsbuttons |
| `app/screens/cockpit/cockpit_text.gd` | Schlüssel je Rolle und Stufe mit generischem Rückfall |
| `app/widgets/seat_ring/` | Sitzkreis des Cockpits (Anordnung aus `SeatCircle.layout`) |

Texte: `ui.call.<rolle>` (Vorlesetext), `ui.prompt.<besitzer>.<stufe>` (Anweisung), `ui.cockpit.action.<aktion>.<besitzer>.<stufe>` (rollenspezifische Beschriftung, etwa Loki „Liebende“/„Rivalen“), `ui.prompt.reaction.<art>`, `ui.morning.*`, `ui.cause.*` (nur privat). Alle Nachtrollen haben eigene Vorlesetexte und Anweisungen; `test_prompt_coverage` prüft das.

## Spielleitung: Korrekturen, Rückgängig, Partie beenden

Werkzeug „Spielleitung“ öffnet eine private Ebene:

- **Verlauf:** „Rückgängig: …“ und „Wiederholen: …“ mit Klartext des Befehls (etwa „Antwort im Schritt Waldhexe (Heiltrank)“) und Rückfrage. Grundlage ist die gespeicherte Befehlsfolge: Rückgängig spielt alle Befehle bis auf den letzten erneut ab (deterministisches Replay), Wiederholen wendet den zurückgenommenen Befehl erneut über den Regelkern an. Genau ein Befehl je Schritt, wie in Vertical Slice §10 festgelegt; mehrstufige Aktionen gehen Stufe für Stufe zurück. `StartGame` ist nicht rücknehmbar, ein neuer Befehl verwirft Wiederholbares, nach Rückgängig/Wiederholen wird gespeichert, und Rückgängig funktioniert auch nach einem Neustart. Wiederholbares wird nicht gespeichert und entfällt beim Neustart. Eine offene Tages- oder Korrekturbedienung (etwa eine Prüfkarte mit Vorschau) verfällt beim Rückgängig. Rückgängig setzt nur den Spielstand zurück: Was bereits gezeigt oder angesagt wurde, bleibt den Spielern bekannt; die Rückfrage sagt das ausdrücklich.
- **Korrekturen:** Person töten (mit oder ohne Todesfolgen, Pflichtwahl), Person wiederbeleben, Rolle ändern, Status ändern (Nominierungsstatus jeder Person; Tränke der Waldhexe, Spiegelung des Spiegelwolfs, Scheinrolle des Trugbilderwolfs je nach Rolle, angezeigt als „Feld: aktuell → neu“), Hinrichten ohne Nominierung (nur während der Tagesaktionen, mit derselben Prüfkarte wie die normale Hinrichtung) und Sieger erklären. Ablauf: Art wählen → Person im Sitzkreis → Pflichtangaben → Warnung mit Pflichtbegründung → Befehl `GmCorrection`. Danach zeigt die Ebene „Letzte Korrektur: das hat sich geändert“ mit den Ereignissen dieses Befehls; das Protokoll enthält Begründung, alten und neuen Wert.
- **Partie:** „Zum Hauptmenü“ (Partie bleibt gespeichert) und „Partie beenden und verwerfen …“ (rote Rückfrage; Dateien werden nur umbenannt).

**Stimmhinweise (Paket 3).** Der private Bereich nennt unter „Stimmhinweise“ die Boni, die die Spielleitung bei der physischen Zählung einrechnet (Blutwolf +1 je totem Nachbarplatz, Korrupter Richter +1 auf seine verdeckte Nominierung, RM-DR-008). Sie erscheinen nie auf einer öffentlichen Karte.

**Spezialkorrekturen (Paket 2).** „Status ändern“ bietet nach der Personenwahl zusätzlich nur die Korrekturen an, die der Regelkern für diese Person im aktuellen Zustand annimmt (Vorprüfung mit `RulesEngine.check`, keine Regel in der Oberfläche): Schutz setzen und entfernen (Schutzengel, nach seinem Schritt in der Nacht), Rettung setzen und entfernen (Waldhexe, nur das Rudelopfer), Vorbild setzen und entfernen sowie Verwandlung und deren Rücknahme (Wolfskind), Meister setzen und entfernen, Erbe auslösen und zurücknehmen (Lehrling; die Rücknahme steht auch nach dem Erbe bei der Person, obwohl sie nicht mehr Lehrling ist). Der Trankstatus der Waldhexe blieb wie bisher ein Umschalter. Jeder Eintrag zeigt „Art · bisheriger Wert“; Korrekturen mit Ziel („…“) öffnen zuerst eine Liste der annehmbaren Ziele. Die Rückfrage nennt Person, bisherigen Wert und Ziel und verlangt eine Begründung. Abbrechen ändert nichts; hat sich der Spielstand zwischen Auswahl und Bestätigung geändert, wird die Auswahl verworfen (Meldung „Der Spielstand hat sich geändert“). Kernablehnungen erscheinen mit eigener DE/EN-Meldung.

**Rollen zeigen (Paket 2).** Die Spielleitung behält das Tablet. Ablauf: Liste (nur Namen, Stand „gesehen“, die nächste offene Person hervorgehoben) → neutrale Vorderseite „Karte für Sitz · Name“ → „Rolle anzeigen“ (bewusste Aktion) → Rolle und Kurztext dieser Person → „Fertig“ (sendet `ConfirmRoleShown`) oder „Schließen“ (sendet nichts) → zurück zur Liste. Bereits bestätigte Personen können nachlesen; „Schließen“ sendet dann nichts. Die Karte mit Rolle wird erst beim Zeigen gebaut und bei Zustandswechsel, Rückgängig, Laden, Sichtschutz und Verlassen der Ansicht verworfen (danach steht die frisch gebaute neutrale Liste). Beim Schließen der Liste bleibt keine geheime Cockpitkarte aufgedeckt und kein privater Bereich öffnet sich. Beim Trugbilderwolf steht die wahre Rolle auf der Karte, nie die Scheinrolle. Keine Pflicht vor der ersten Nacht. Die Bedienung ist vorläufig schlicht (vollflächige Ebene) und für die spätere Gestaltung umbaubar; sie schafft keine dauerhafte Seitenleiste. Geräte- und Touch-Abnahme stehen aus.

Eine Korrektur während eines offenen Prompts setzt den Schritt im Regelkern zurück; die Karte kündigt ihn neu an.

## Bedienqualität und Anschlussstellen

- Hintergrund des Cockpits je Tageszeit (`NightBackdrop` tiefblau, `DayBackdrop` warm) und Phasenleiste in Nacht- bzw. Tagfarben; Wechsel in 0,3 s, abbrechbar.
- Die Ansagekarte blendet bei einer neuen Handlung in 0,15 s ein; eine neue Handlung bricht das Einblenden ab. Auswahländerungen derselben Karte blenden nicht erneut ein.
- „Bewegung reduzieren“ schaltet beide Übergänge ab.
- Nach jeder Aktion erhält die erste Aktion der neuen Karte den Fokus (Tastatur, Controller), sofern kein Dialog und keine Ebene offen ist.
- Status nie nur über Farbe: Tote tragen „†“, Nominierte „(N)“, Fehler beginnen mit „Fehler:“, Hinweise mit „Hinweis:“.
- Anschlussstellen ohne Assets: `CockpitScreen.set_backdrop_art(texture)` legt ein Bild über die Hintergrundfarbe (Knoten `BackdropArt`, leer), `GameSeatToken.set_portrait(texture)` zeigt ein öffentliches Porträt am Platz (nie ein Rollenbild). Für spätere Effekte liefert `GameSession.events_applied` die Ereignisse; ein Effekt darf nur öffentliche Ereignisse sichtbar machen.

## Eigenständig getroffene Bedienentscheidungen

| Entscheidung | Begründung | Folge |
|---|---|---|
| Geheime Karten außerhalb der Nacht verdeckt, „Anzeigen“ deckt nur die aktuelle Handlung auf | Am Tag sieht der Tisch mit; nachts haben alle die Augen zu | ein zusätzlicher Tipp bei Reaktionen und Siegkandidaten am Tag |
| Jede Hinrichtung über eine verdeckte Prüfkarte | eine Prüfkarte nur bei Sonderrollen würde die Rolle verraten | ein zusätzlicher Tipp je Hinrichtung |
| Morgenbericht als eigener Schritt vor den Tagesaktionen („Weiter“) | Ansage vor Diskussion; kein `BeginDay` im Regelkern | Bedienzustand, nach Neustart erscheint der Bericht erneut |
| Nominierung in zwei Schritten im Sitzkreis | entspricht dem Ablauf am Tisch (wer, wen) | keine Liste, keine Stimmenerfassung |
| Keine Option „Rolle beim Tod aufdecken“ mehr; die Wiederbelebungsrunde folgt aus der Startbesetzung (DI-01) | Antwort des Product Owners vom 29.09.2026 ersetzt DR-04 | Anzeige im Rollenschritt, Schema 13 |
| Traumdeuter/Kopfgeldjäger: Hinweiszeile „Wölfe unter den Wählbaren“ | der Spielleiter muss mindestens einen Wolf wählen und sieht sonst keine Rollen | nur nachts in der Karte; Regelprüfung im Kern |
| Sichtschutz endet per Button statt Halten | Halten ist ohne Gerätetest nicht verlässlich prüfbar | bei der Tablet-Abnahme prüfen |
| Undo/Redo je Befehl über Replay, `StartGame` ausgenommen | Vertical Slice §10; ein Start rückgängig hieße Partie verwerfen, dafür gibt es „Beenden und verwerfen“ | mehrstufige Aktionen gehen Stufe für Stufe zurück |

## Wiederbelebungsrunde statt Aufdeckungsoption (DI-01, ersetzt DR-04)

**Änderung der bisherigen Produktvorgabe.** Die frei wählbare Setup-Option „Rolle beim Tod öffentlich aufdecken“ (`reveal_role_on_death`, Schema 12) ist entfallen. Der Regelkern leitet bei `StartGame` aus den Startrollen ab, ob die Partie eine Wiederbelebungsrunde ist (`GameState.revival_round`, Schema 13): Direkte Wiederbelebungsrollen (Kutscher, Dr. Victor Frankenstein) lösen den Modus aus; Erbe, Tausch, Diebstahl und die Korrektur `revive` nicht. Der Modus bleibt die ganze Partie gleich.

- Wiederbelebungsrunde: Beim Tod wird keine Rolle aufgedeckt; die Ansage der Nacht sagt „Alle schließen die Augen, auch die Toten.“ (`ui.call.night_falls_revival`).
- Runde ohne Wiederbelebung: Die Rolle wird beim Tod aufgedeckt (Rolle zum Todeszeitpunkt aus `SeatDied`).
- Das Setup zeigt den Modus im Rollenschritt nur an (`RevivalRoundLabel`, aus der Rollenwahl berechnet); `StartGame` trägt keine Aufdeckungsangabe, der Kern lehnt `reveal_role_on_death` ab (`reveal_option_removed`).
- Ältere Spielstände (Schema 12) werden mit klarer Meldung abgelehnt und nicht verändert.
- Totenreichkarten sind nicht definiert; es gibt weder Kartenregeln noch Dummy-Karten.

## Aufrufe und Tarnaufrufe (DI-02)

`CallPolicy` (Regelkern, reine Abfrage) bestimmt, welche Rollen in der Nacht aufgerufen werden: ohne Wiederbelebung nur Rollen, die noch eine lebende Person hält (Startrolle oder aktuelle Rolle); mit Wiederbelebung auch Rollen Toter. Rollen ohne Schritt heute (verbrauchte, blockierte, noch nicht aktive) erscheinen als **Tarnaufruf**: Die Karte des nächsten echten Schritts (bzw. „Nacht abschließen“) trägt oben die Zeile „Zuerst aufrufen (nur Ansage)“ mit den Vorlesezeilen dieser Rollen. Tarnaufrufe lösen keinen Befehl, keine Ziehung und keinen Verbrauch aus; sie werden bei jedem Rendern aus dem Kernzustand neu berechnet und bleiben deshalb nach Rückgängig, Wiederholen, Neustart und Navigation gleich. Abgeleitet und noch zu bestätigen: Blockierte und noch nicht aktive Rollen werden ebenfalls aufgerufen; Rollen, die in der Partie nicht vorkommen, nicht.

## Todeseffekte werden angesagt (DI-03, ändert DR-04)

**Änderung der bisherigen Produktvorgabe.** Sichtbare Folgen eines Todes werden öffentlich angesagt, mit Effekt und Rolle zum Ereigniszeitpunkt, auch in Wiederbelebungsrunden: Sensenträger, Ritter, Besessener Wolf, Wahnsinniger Kutscher, Fluch des Weisen, Liebeskummer, Rotkäppchen-Kette, Verknüpfung des Schattenwanderers. Der Kern erzeugt dafür das öffentliche Ereignis `DeathEffect` (Positivliste: Effekt, Quelle, Rolle, Ziel, ersetzte Person) direkt nach `SeatDied`, nur wenn der Tod eintritt; kein privates Ereignis wird übernommen. Liebeskummer, Kette und Verknüpfung nennen die Rolle, von der der Effekt stammt (Loki, Rotkäppchen, Schattenwanderer; PE-05), nie die der sterbenden Person; der Fluch des Weisen nennt seine Länge nicht. Der Morgenbericht (`public.effects`) und die Tageskarte zeigen die Ansagen; mehrere Nachbarn desselben Kutscherunfalls stehen in einer Ansage. Geheime Wahlen ohne sichtbare Folge (Fluch des Dämonischen Wolfs, Puppe, Markierungen) bleiben verdeckt.

## Rollenlexikon und Kontexthilfe (Paket 5b)

- **Werkzeug „Lexikon“:** öffnet das allgemeine Rollenlexikon als Ebene über dem Cockpit, auch ohne Partie. Es zeigt alle 71 Rollen unabhängig von der Partie: keine Personen, keine verteilten Rollen, keine Ziele, Bindungen, Markierungen oder Ladungen.
- **„Regel nachlesen“ auf der Karte:** nur auf der privaten Spielleiterkarte eines Schritts, eines Prompts oder eines privaten Hinweises; öffnet den allgemeinen Eintrag der handelnden Rolle (Rudel → Werwolf, Frage an die von Rotkäppchen gefragte Person → Rotkäppchen, Hinweise → Loki, Rattenfänger, Pestbringerin). Eine verdeckte Karte hat keine Hilfe; eine gezeigte Karte (Karte zeigen, Hinweiskarte, Rollenanzeige, Ansagekarte) ersetzt das Cockpit und hat keine.
- **Bedienzustand:** Die Ebene ändert weder Karte noch Auswahl. Eine offene Zielauswahl bleibt erhalten, solange sich der Spielstand nicht ändert; jede Zustandsänderung verwirft sie wie bisher. Öffnen, Suchen, Filtern und Schließen senden keinen Befehl, ziehen keinen Zufall und verbrauchen nichts.
- **Schließen:** „Schließen“, Zurück/Escape und Sichtschutz entfernen die Ebene; Zurück führt nicht zur Verlassen-Rückfrage, solange die Ebene offen ist.
- **Inhalt:** Suche nach dem Rollennamen der gewählten Sprache, Filter Alle/Dorf/Werwölfe/Einzelsieg, leerer Suchzustand, Eintrag mit Fraktion, Kurztext und neun Abschnitten, bei 15 Rollen zusätzlich „Noch nicht geklärt oder umgesetzt“. Der Sprachknopf wechselt die App-Sprache, der geöffnete Eintrag bleibt.
- **Nicht geprüft:** Darstellung und Touch auf dem Gerät; die spätere Gestaltung (85 bis 90 % Spielfeldfläche) ist ein eigener Auftrag.

## Private Hinweise (DI-04 bis DI-08)

Der Kern führt offene Hinweise im Spielstand (`notices`, Befehl `AckNotice`); die Karte „Privater Hinweis“ erscheint vor dem nächsten Schritt. „Karte zeigen“ öffnet die Karte für die betroffene Person, „Gezeigt“ bestätigt sie. Der Kern blockiert nicht, die Oberfläche zeigt offene Hinweise zuerst; im Sichtschutz (Tag) bleibt der Inhalt bis „Anzeigen“ verdeckt.

- Loki: beide Personen des Paares, jede sieht nur ihren Partner und die Bindungsart.
- Rattenfänger: erst die neu Verzauberten (ohne Namen), dann alle lebenden Verzauberten mit Namen.
- Pestbringerin: jede neu infizierte Person, auch durch die Ausbreitung am Morgen.
- Rotkäppchen: Die Frage an die gefragte Person erklärt Apfel und Kette und nennt weder die Rolle noch die fragende Person (Handelnde ist die gefragte Person).
- Trugbilderwolf: Seine Scheinrolle steht auf keiner Karte; nur der private Spielleiterbereich nennt sie.

## Abdeckung der Rollen über die Oberfläche

Grundlage: `tests/ui/test_prompt_coverage.gd` spielt 142 Partien mit allen 71 implementierten Rollen ausschließlich mit den Daten der Karte und löst jeden Prompt; seltene Reaktionen (Ritter bei Gleichstand, Schmiedewaffe) und die gestohlene Fähigkeit des Grabräubers sind gezielt geprüft. Tagesmechaniken prüft `tests/ui/test_cockpit_day.gd`. „Bedienbar“ heißt: Jeder Prompt der Rolle ist headless mit genau einer Antwort nach den Kartendaten lösbar (zufällige zulässige Anzahl aus `counts`, Wolfshinweis der Karte, Freigabe über `check_targets` wie beim Button „Auswahl bestätigen“); eine Ablehnung durch den Regelkern macht den Test rot, Wiederholversuche gibt es nicht. Die Karte hat für jede Kombination eigene Bedienelemente und Texte. Dieser Lauf bedient `GameSession` mit den Kartendaten, nicht die Buttons selbst. Über echte Buttons und Sitzplätze mit erwartetem Ergebnis geprüft sind nur die ausdrücklich getesteten Abläufe: erste Nacht mit Schutzengel, Waldhexe, Orakel, Sensenträger; Tag, Spiegelwolf, Weiser, Amalia, Nekromant, Ritter, Schmied, Grabräuber; Loki, Seelentauscher, Kutscher, Spürhund (`test_target_selection`); vollständige Partie. Die Wirkung der Rollen selbst prüfen die Regelkern-Tests. Nicht auf einem Tablet geprüft.

Personenauswahl: Die Karte nennt die zulässige Anzahl aus dem Regelkern (`RulesEngine.target_counts`, etwa „0 oder 2“ bei Loki und Seelentauscher, „0 oder 3“ bei Kutscher und Spürhund, „2“ beim Doktor). „Auswahl bestätigen“ ist nur freigegeben, wenn der Regelkern die aktuelle Auswahl annehmen würde (`GameSession.check_targets` → `RulesEngine.check`, dieselbe Validierung wie beim Senden, ohne Zustandsänderung). Sonst bleibt der Button gesperrt und die Karte erklärt den Grund (Anzahl passt nicht, kein Wolf unter den Gewählten, Person nicht wählbar). Mehr als die Höchstzahl lässt der Sitzkreis nicht zu. Jede Zustandsänderung (angenommener Befehl, Laden, Rückgängig/Wiederholen) verwirft die Auswahl. Ein manipulierter oder veralteter Befehl wird weiterhin vom Regelkern abgelehnt (`test_target_counts`).

Zufallsknopf (RM-DR-015.2, nur Traumdeuter, Kopfgeldjäger, König und die Aufdeckung des Blutpriesters): „Zufällig auswählen“ setzt einen Vorschlag als Auswahl, markiert im Sitzkreis und mit dem Hinweis „Zufallsvorschlag“. Er stammt aus einer Kopie des gespeicherten Generators und ändert nichts; erneutes Drücken liefert bei unverändertem Zustand denselben Vorschlag, auch nach Laden. Erst „Auswahl bestätigen“ sendet ihn; der Regelkern zieht erneut, nimmt nur genau dieses Ergebnis an und übernimmt dabei die eine Ziehung. Antippen einer Person ändert den Vorschlag in eine eigene Wahl ohne Ziehung. Jede Zustandsänderung verwirft den Vorschlag. Gibt es kein zulässiges Ergebnis, ist der Knopf gesperrt und die Karte erklärt es. Die Opferwahl des Blutpriesters ist seine eigene Entscheidung und hat keinen Zufallsknopf. Vorher zeigte der Abdeckungslauf 178 abgelehnte Teilauswahlen (`invalid_target_count`); jetzt 0.

Spezialkorrekturen für Schutz und Rettung der laufenden Nacht, Wolfskind und Lehrling haben keine eigene Oberfläche (siehe oben). Die Oberfläche ist daher für diese Korrekturen nicht vollständig.

| Rolle | Name | Prompt-Formen (Stufe → Antwortart) | Weitere Mechanik | Oberfläche |
|---|---|---|---|---|
| `dorfbewohner` | Dorfbewohner | – | keine eigene Fähigkeit | bedienbar |
| `werwolf` | Werwolf | – | Rudelschritt (`pack`) | bedienbar |
| `schutzengel` | Schutzengel | pick → targets | – | bedienbar |
| `waldhexe` | Waldhexe | confirm → ack, heal → choice, poison → choice, poison_target → targets, reveal → ack | – | bedienbar |
| `das-orakel` | Das Orakel | shown → ack, target → targets | – | bedienbar |
| `trugbilderwolf` | Trugbilderwolf | – | Rudel; Scheinrolle im Setup | bedienbar |
| `wolfskind` | Wolfskind | pick → targets | – | bedienbar |
| `spiegelwolf` | Spiegelwolf | – | Rudel; Spiegelung bei Hinrichtung (Regelkern, Vorschau geheim) | bedienbar über Hinrichtung |
| `manipulator` | Manipulator | – | stirbt automatisch bei Nominierung (Regelkern) | bedienbar über Nominierung |
| `lehrling` | Lehrling | candidates → targets, confirm → ack, option → option | – | bedienbar |
| `sensentraeger` | Sensenträger | – | Todesreaktion `curse` (Reaktionskarte) | bedienbar |
| `siegreicher-wolf` | Siegreicher Wolf | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `doppelspion` | Doppelspion | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `selbstmoerder` | Selbstmörder | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `dorfchronistin` | Dorfchronistin | shown → ack | – | bedienbar |
| `die-gebundenen` | Die Gebundenen | shown → ack | – | bedienbar |
| `waldlaeufer` | Waldläufer | shown → ack | – | bedienbar |
| `doktor` | Doktor | shown → ack, targets → targets | – | bedienbar |
| `wahnsinniger-kutscher` | Wahnsinniger Kutscher | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `nachtwaechter` | Nachtwächter | – | öffentliche Glocken automatisch (Morgenbericht) | bedienbar |
| `dorfwache` | Dorfwache | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `ritter` | Ritter | – | Todesreaktion `knight` bei Gleichstand (gezielter Test) | bedienbar |
| `faehrtenleser` | Fährtenleser | shown → ack, use → choice | – | bedienbar |
| `besessener-wolf` | Besessener Wolf | – | Rudel; Todesreaktion `possessed` | bedienbar |
| `korrupter-richter` | Korrupter Richter | pick → targets | – | bedienbar |
| `waechter-am-tor` | Wächter am Tor | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `blutwolf` | Blutwolf | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `spuerhund` | Spürhund | shown → ack, targets → targets | – | bedienbar |
| `parasit` | Parasit | pick → targets | – | bedienbar |
| `schattenhund` | Schattenhund | use → choice | – | bedienbar |
| `albtraumwolf` | Albtraumwolf | pick → targets | – | bedienbar |
| `giftwolf` | Giftwolf | pick → targets | – | bedienbar |
| `rudelvater` | Rudelvater | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `seuchenwolf` | Seuchenwolf | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `fenrir` | Fenrir | – | passiv, wirkt automatisch im Regelkern | keine Bedienung nötig |
| `cerberus` | Cerberus | – | Rudel; Abwehrfrage bei Hinrichtung | bedienbar über Hinrichtung |
| `henker` | Henker | pick → targets | – | bedienbar |
| `traumdeuter` | Traumdeuter | shown → ack, targets → targets | – | bedienbar |
| `kopfgeldjaeger` | Kopfgeldjäger | shown → ack, targets → targets | – | bedienbar |
| `koenig` | König | shown → ack, targets → targets | – | bedienbar |
| `kriegerin-des-lichts` | Kriegerin des Lichts | shown → ack, targets → targets | – | bedienbar |
| `blutpriester` | Blutpriester | reveal → targets, shown → ack, targets → targets | – | bedienbar |
| `amalia` | Amalia | – | Selbstopfer am Tag (geheime Tagesaktion) | bedienbar über privaten Bereich |
| `detektiv` | Detektiv | – | öffentlicher Hinweis automatisch (Morgenbericht) | bedienbar |
| `die-ewigen` | Die Ewigen | shown → ack, targets → targets | – | bedienbar |
| `der-weise` | Der Weise | – | Fluchdauer bei Hinrichtung | bedienbar über Hinrichtung |
| `maertyrerin` | Märtyrerin | pick → targets | – | bedienbar |
| `schutzgeist` | Schutzgeist | pick → targets | – | bedienbar |
| `dorfschmied` | Dorfschmied | pick → targets | Waffe; Reaktion `smith` (gezielter Test) | bedienbar |
| `verdammniswaechter` | Verdammniswächter | pick → targets | – | bedienbar |
| `loki` | Loki | mode → choice, targets → targets | – | bedienbar |
| `rotkaeppchen` | Rotkäppchen | grant → choice, targets → targets | – | bedienbar |
| `schwarze-witwe` | Schwarze Witwe | pick → targets | – | bedienbar |
| `schattenwanderer` | Schattenwanderer | pick → targets | – | bedienbar |
| `seelentauscher` | Seelentauscher | targets → targets | – | bedienbar |
| `daemonischer-wolf` | Dämonischer Wolf | – | Rudel; Todesreaktion `demon` | bedienbar |
| `koenig-lykaon` | König Lykaon | ally → targets, targets → targets | – | bedienbar |
| `kutscher` | Kutscher | targets → targets, wolf → targets | – | bedienbar |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein | role → option, targets → targets | Nacht: Wiederbelebung; Totenkarten-Bedingung RM-DR-141.4 offen | bedienbar, Totenkarten-Abhängigkeit offen |
| `rattenfaenger` | Rattenfänger | pick → targets | – | bedienbar |
| `pestbringerin` | Pestbringerin | pick → targets | – | bedienbar |
| `prophet-des-untergangs` | Prophet des Untergangs | pick → targets | – | bedienbar |
| `todesprediger` | Todesprediger | prediction → prediction | – | bedienbar |
| `feuerteufel` | Feuerteufel | pick → targets | – | bedienbar |
| `voodoo-priester` | Voodoo-Priester | pick → targets | – | bedienbar |
| `nekromant` | Nekromant | redirect → targets, targets → targets | Nacht: Tote opfern, Umlenken; Tag: Wolf benennen (geheime Tagesaktion) | bedienbar |
| `hades` | Hades | barrier → choice, targets → targets | – | bedienbar |
| `grabraeuber` | Grabräuber | targets → targets | – | bedienbar |
| `schicksalswolf` | Schicksalswolf | pick → targets | – | bedienbar |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf | pick → targets | – | bedienbar |
| `zeitwaechter` | Zeitwächter | use → choice | – | bedienbar |
| `kartenschlucker` | Kartenschlucker | – | Totenkarten-Modell RM-DR-013, RM-DR-143.1/.2 offen | **blockiert**, nicht im Katalog, nicht wählbar |

Gruppen- und Reaktionsschritte: die-ewigen/shown/ack, die-ewigen/targets/targets, die-gebundenen/shown/ack, pack//targets, pack2//targets, reaction/curse/targets, reaction/demon/targets, reaction/possessed/targets

Offene Abhängigkeiten, die nicht als fertig gelten:

- **Kartenschlucker:** blockiert (Totenkarten-Modell RM-DR-013, RM-DR-143.1/.2). Nicht im Rollenkatalog, im Setup nicht wählbar.
- **Dr. Victor Frankenstein:** Wiederbelebung bedienbar; die Totenkarten-Bedingung RM-DR-141.4 ist nicht entschieden und wird nicht geprüft. Der private Rollenbereich weist darauf hin.
- **Richter-Nominierung:** Öffentlich erscheint nur die nominierte Person. Nominiert der Richter am selben Tag erneut, lehnt der Regelkern mit „hat heute schon nominiert“ ab; die Oberfläche kann das vorher nicht wissen, ohne das Geheimnis zu zeigen.
- **„Keine oder genau N“-Auswahlen** (Loki, Seelentauscher, Kutscher, Nekromant, Spürhund): Die Karte erlaubt Bestätigen zwischen Mindest- und Höchstzahl; eine Zwischenzahl lehnt der Regelkern mit klarer Meldung ab. Die Anweisung nennt die Regel.

## Manuell testen (gemeinsame Tablet-Abnahme)

Für den Windows-Fenstertest am PC mit fester Partie und Starter ohne Editor: `docs/ui/pc-test-pr3.md` (Fehlerliste: `docs/ui/pc-test-pr3-fehlerliste.md`).

Start: `godot/project.godot` im Godot-Editor 4.7.2 öffnen und F5, oder die exportierte App. Fenster auf 1280×800 bzw. 1024×768 stellen; zusätzlich auf dem Tablet im Querformat.

1. **Setup:** Hauptmenü → „Neue Partie“ → acht Namen → Rollen „Vorschlag“ (oder Werwolf ×2, Schutzengel, Waldhexe, Das Orakel, Sensenträger, Dorfbewohner ×2) → im Rollenschritt „Rolle beim Tod öffentlich aufdecken“ einmal an, einmal aus → verteilen → Sitzordnung bestätigen → „Partie starten“. Erwartet: Cockpit mit acht Plätzen, keine Rolle sichtbar, Karte „Nacht 1 beginnen“.
2. **Geheimhaltung:** „Rollen“ öffnet die Liste „nur Spielleitung“; Tippen neben die Schublade, „Schließen“ und Zurück schließen sie. „Verbergen“ blendet alles aus, „Weiter“ zurück.
3. **Nacht:** „Nacht beginnen“ → Schutzengel: Platz antippen (gold), „Auswahl bestätigen“ → „Schritt beginnen“ je Rolle → Waldhexe Ja/Nein → Orakel: Ziel, „Karte zeigen“ (nur Ergebnis, keine Wahrheit), „Gezeigt“ → „Nacht abschließen“. Doppelt tippen darf nichts doppelt auslösen.
4. **Morgen:** Morgenbericht vorlesen, „Ansagekarte zeigen“ (nur Namen, Rolle nur mit Option), „Private Details …“ (Ursachen), „Weiter“. Stirbt der Sensenträger, erscheint vorher eine verdeckte Reaktion („Anzeigen“).
5. **Tag:** „Nominierung erfassen“: erst die nominierende, dann die nominierte Person antippen, bestätigen. Nominierte Person im Sitzkreis antippen → „Hinrichten“ (die Karte zeigt die Prüfung sofort, keine Rückfrage). Stimmen werden nur am Tisch gezählt. „Tag beenden“, nächste Nacht.
6. **Sieg:** bis zur Wolfsparität spielen: verdeckte Siegkarte, „Anzeigen“, bestätigen → Spielende.
7. **Spielleitung:** „Spielleitung“ → „Rückgängig: …“ (Klartext prüfen), „Wiederholen“; „Person töten …“ mit Begründung; danach „Letzte Korrektur“ ansehen.
8. **Speichern:** App mitten in der Waldhexen-Kette beenden, neu starten → „Fortsetzen“ → derselbe Schritt ist offen; Anzeige „Gespeichert“ in der Phasenleiste. Nach einem Speicherfehler erscheint „Erneut speichern“ (siehe `save-resume.md`).
9. **Bewegung reduzieren** in den Einstellungen an/aus: Kartenwechsel und Tag/Nacht-Wechsel ohne bzw. mit kurzem Übergang.

Worauf bei der Abnahme achten: Lesbarkeit der Namen bei 24 Personen, Größe und Abstand der Buttons, Kontrast im abgedunkelten Raum, ob verdeckte Karten und Prüfkarten den Ablauf zu sehr bremsen.

## Geheimhaltung der Ausgabewege (Inventar Paket 4)

Jeder Weg hat eine Positivliste; ein weiteres Feld macht den jeweiligen Test rot. Geprüft werden Datenstrukturen und die an Controls übergebenen Texte, nicht nur einzelne Zeichenfolgen.

| Ausgabeweg | erlaubte Angaben | Nachweis |
|---|---|---|
| Öffentliche Ansagekarte (Morgen) | Tote mit Namen; Rolle nur ohne Wiederbelebungsrunde (DI-01); angesagte Todeseffekte; Wiederbelebte; öffentliche Hinweiszeilen (`deaths`, `effects`, `notices`, `reveal_roles`, `revived`) | `test_death_effect_lines`, `test_morning_report` |
| Tages-/Todeseffektkarte | Effekt, Quelle, Rolle zum Ereigniszeitpunkt, Ziel, ersetzte Person (DI-03, erlaubte Ausnahme); Liebeskummer, Kette, Verknüpfung ohne Rolle | `test_death_effects`, `test_death_effect_lines` |
| Morgenbericht, privater Teil | Ursachen, Rettungen (nur Spielleitung, nach ausdrücklichem Öffnen) | `test_morning_report` |
| Personenbezogene Informationskarte (Zeigekarte) | nur Personen und Rollen aus `show`, keine Wahrheit hinter einer Scheinrolle | `test_cockpit_model`, `test_cockpit_screen`, `test_role_operation_kinds` |
| Private Hinweiskarten | nur der eigene Partner und die Bindungsart (Loki), Verzauberte (Rattenfänger), Infektion (Pestbringerin), Apfel ohne fragende Person (Rotkäppchen); Trugbilderwolf erhält keine Karte (DI-08) | `test_notice_cards` |
| Rollenanzeige | Name, Platz, eigene Rolle, Kurztext (`confirmed`, `name`, `person_id`, `role_id`, `seat`); Trugbilderwolf sieht seine wahre Rolle, nie die Scheinrolle | `test_role_show` |
| Neutrale Vorderseiten | nur Name und Platz | `test_role_show`, `test_cockpit_screen` |
| Statusmeldungen (Toasts) | nur feste Textschlüssel ohne Platzhalter (`ToastHost.show_message(text_key)`) | `test_output_positive_lists` |
| Speicher-/Fortsetzen-Übersicht | Namen, Personenzahl, Lebende, Phase, Nacht, Tag, Befehlszahl; Listeneintrag und Dateihülle ohne Kern | `test_output_positive_lists`, `test_save_service` |
| Öffentliche Cockpit-Sicht und Sitzkreis | feste Felder, Sitzplätze nur mit ID, Platz, Name, lebend, Nominierungen; gleich nach Laden und Rückgängig | `test_output_positive_lists`, `test_cockpit_screen` |
| Öffentliche Hinweiszeile | feste Schlüssel; bei offener Reaktion nur der neutrale Phasentext ohne Werte, derselbe wie bei anderen verdeckten Karten (PE-01) | `test_public_reaction_hint`, `test_output_positive_lists` |
| Öffentliche Ereignisse | keine Rolle, Ursache oder Information außer der DI-03-Ausnahme | Fuzz-Invariante `test_role_interaction_fuzz` |
| Spielleiterbereich, Protokoll | alles (bewusst), nur nach ausdrücklichem Öffnen; Sichtschutz, Laden, Rückgängig und Zustandswechsel schließen offene Karten | `test_cockpit_screen`, `test_role_show`, `test_special_corrections`, `test_resume_scenarios` |
| Export | nicht implementiert (C-09) | – |

Die aktive Nachtkarte der Spielleitung nennt die aufgerufene Rolle; das entspricht dem öffentlichen Aufruf. Tagsüber sind Reaktions- und Siegkarten verdeckt, bis die Spielleitung sie aufdeckt.

## Tests

| Test | Inhalt |
|---|---|
| `test_role_lexicon_ui` | Lexikon aus Hauptmenü, Setup und Cockpit: Suche, Filter, leerer Zustand, langer Eintrag bei 1024×768, Sprachwechsel, Kontexthilfe bei offener Auswahl ohne Befehl, Zufall oder Ressource, Verwerfen nach Zustandsänderung, keine Partiedaten, gezeigte und verdeckte Karte, Sichtschutz, Zurück |
| `test_role_lexicon_content` | alle Katalogrollen mit allen Lexikonfeldern in DE/EN, keine unbekannten Rollen oder Felder, keine Platzhalter oder Dokumentverweise, gerendert in beiden Sprachen |
| `test_cockpit_model` | Sicht ohne Rollen, vollständige erste Nacht über die Bausteine, Abbruch (gleicher Hash), Pflichtbegründung, gestohlene Fähigkeit |
| `test_cockpit_screen` | Sitzkreis, Nacht über Buttons, verdeckte Reaktion, privater Bereich, Sichtschutz, gezeigte Karte, Begründungsdialog, Mehrfachtippen, Zurück, Layout 6/24 Personen bei 1024×768, 1280×800, 1920×1080 mit langen Namen, Morgenbericht mit und ohne Rollenaufdeckung |
| `test_board_layout` | Zielwahl mit Textzeichen bei Lebenden und Toten, `DetailPanel` mit langem Text und festen Buttons, private Rollenkarte schließt zum Brett ohne Rollen, Speicherfehler mit erreichbarem „Erneut speichern“ |
| `test_public_reaction_hint` | PE-01: unterschiedliche offene Reaktionen (Art, Besitzer, Anzahl) ergeben dieselbe neutrale Hinweiszeile, Tagestext statt Morgentext, derselbe Text bei einer Siegentscheidung ohne Reaktion, nachts keine Zeile, private Karte vollständig und bedienbar, DI-03-Ansage, Laden und Rückgängig, Label DE/EN |
| `test_prompt_coverage` | Bedienbarkeit aller Prompt-Arten mit genau einer Antwort nach Kartendaten, eigene Texte je Kombination, Ritter und Schmied |
| `test_target_selection` | Loki, Seelentauscher, Kutscher, Spürhund über Sitzplätze und Buttons: Regelzeile, gesperrte Teilauswahl mit Erklärung, gesperrter Button sendet nichts, vollständige Auswahl mit erwartetem Ergebnis; Höchstzahl; Auswahl verfällt bei Laden, Korrektur, Rückgängig/Wiederholen |
| `test_target_counts` (Regelkern) | zulässige Anzahlen und `check` = `apply` ohne Änderung für Loki, Seelentauscher, Kutscher, Spürhund, Doktor; manipulierte und veraltete Befehle abgelehnt |
| `test_call_presentation` | Tarnaufrufe vor dem ersten Schritt und vor dem Ende der Nacht, tote Rolle nur in Wiederbelebungsrunden, „auch die Toten“, keine Zustandsänderung, gleiche Ansage nach Rückgängig und Laden |
| `test_notice_cards` | Loki, Rattenfänger, Pestbringerin, Rotkäppchen und Trugbilderwolf: Karten zeigen nur Erlaubtes, Bestätigen, Neustart, Navigation, Rückgängig, Sichtschutz |
| `test_death_effect_lines` | Ansagen der Todeseffekte mit Rolle (DE, EN), Wiederbelebungsrunde, nur Positivliste, ein Kutscherunfall eine Ansage, Laden und Replay |
| `test_morning_report` | Positivliste, private Ursachen und Rettungen, Rollenaufdeckung, Rolle beim Tod nach späterer Rollenänderung, Wiederbelebung und zweitem Tod, Laden und Replay, ohne Aufdeckung keine Rolle in zeigbaren Daten |
| `test_cockpit_day` | Nominierung, Hinrichtung mit Prüfkarte, Spiegelwolf, Weiser, Amalia, Nekromant, keine Hinrichtung, Sieg, keine veraltete Prüfkarte nach Rückgängig |
| `test_full_round_ui` | vollständige Partie nur über Buttons bis zum bestätigten Sieg |
| `test_resume_scenarios`, `test_resume_every_command`, `test_process_restart` | Paket 4: Fortsetzen nach Neustart über den Fortsetzen-Bildschirm an neun Unterbrechungsstellen, Neustart nach jedem Befehl, zweiter Godot-Prozess |
| `test_output_positive_lists` | Paket 4: Positivlisten der Speicherübersicht, Statusmeldungen und öffentlichen Cockpit-Sicht |
| `test_random_pick` | Zufallsknopf je Rolle über Buttons: Vorschlag zulässig und ohne Wirkung, identisch bei Wiederholung und nach Laden, Doppeltippen, manuelle Änderung, veränderte Bestätigung, Laden, Replay, Rückgängig, Abbrechen, keine öffentlichen Daten |
| `test_undo` | Rückgängig = Replay der verkürzten Folge, Wiederholen gleicher Hash, mehrstufige Prompts, bestätigter Sieg, Speichern, Ereignisverlauf und entfallenes Wiederholen nach Neustart |
| `test_cockpit_polish` | Tag/Nacht-Hintergrund, Einblenden und Abbruch, reduzierte Bewegung, Fokus nach Aktionen, Anschlussstellen, Kartenbreite bei 1024×768 DE/EN |
| `test_role_show`, `test_role_shown` | Rollenanzeige: Bestätigung, Fortsetzung nach Neustart, Abbruch, Nachlesen, Rollenwechsel, verworfene Karte bei Zustandswechsel und Undo, Sichtschutz, Trugbilderwolf, Buttonweg, Speichern und Replay |
| `test_role_buttons`, `test_role_passive_ui`, `test_role_operation_kinds` | Paket 3: jede Rolle über Sitzplätze, Kartenbuttons und Dialog (Treiber `role_ui_case.gd`), passive Rollen über ihren Auslöser, Bedienarten, Abbruch ohne Verbrauch, Doppeltippen, Undo, Rollenwechsel, Positivlisten der Zeigekarten, Stimmhinweise im privaten Bereich |
| `test_special_corrections` | Spezialkorrekturen über Buttons: Erfolg je Art, nur passende Angebote, Abbruch, Grund, ungültige Eingabe, Undo/Redo, Speichern und Laden, veraltete Auswahl, Geheimhaltung |
| `test_cockpit_gm` | Korrekturen mit Warnung, Begründung, Protokoll und Änderungsanzeige, Rückgängig/Wiederholen mit Klartext, Hinrichtung ohne Nominierung, Sieger erklären, Verwerfen |

Nicht geprüft: Darstellung auf echten Geräten, Schriftbild, Touch-Treffsicherheit, Lesbarkeit im Dunkeln, Übergänge. Diese Abnahme erfolgt gemeinsam am Tablet.
