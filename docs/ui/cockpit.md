# Cockpit · geführte Partie

Stand: 29.09.2026 · Godot 4.7.2 · Projekt `godot/` · Branch `feature/night-ui-expansion`

Das Cockpit führt die Spielleitung durch eine laufende Partie: Nacht, Morgenbericht, Tag, Hinrichtung und Siegbestätigung. Grundlage ist der Regelkern; das Cockpit hat keine eigene Nachtreihenfolge, keine eigene Rollenregel und keine eigene Zustandsverwaltung. Visuell und auf einem Tablet ist es noch nicht geprüft (nur headless Modell-, Layout- und Integrationstests).

Erreichbar: Hauptmenü → „Neue Partie“ → Setup bis „Partie starten“, oder Hauptmenü → „Cockpit“ bei laufender Partie.

## Aufbau

| Bereich | Inhalt |
|---|---|
| Kopfzeile | Zurück (fragt bei laufender Partie nach, die Partie bleibt erhalten), Titel |
| Phasenleiste | Phase, Runde und Nachtfortschritt („Nacht 2 · Schritt 3 von 7 erledigt“), Lebende; Nacht blau, Tag und Morgen warm |
| Hinweiszeile | offene Reaktionen, übersprungene Schritte, niemand lebt (ohne Rollen) |
| Sitzkreis | Plätze der Partie im Uhrzeigersinn: Platznummer, Name, „†“ für Tote, „(N)“ für heute Nominierte. Nie eine Rolle. Bei 13 bis 24 Personen kompakte Plätze (48 px hoch, 96 bis 120 px breit) |
| Ansagekarte | nächste Handlung aus dem Regelkern: Kontext, „Sag jetzt“ (Vorlesetext), „Tu jetzt“ (Anweisung), Auswahl, Aktionen |
| Werkzeuge | Protokoll, Rollen (privater Bereich), Verbergen (Sichtschutz); ohne Partie deaktiviert |

## Geheimhaltung

- Sitzkreis, Phasenleiste und Hinweise enthalten keine Rollen und keine Nachtinformationen.
- Karten mit geheimem Inhalt (Nachtschritte, Prompts, Reaktionen, Siegkandidaten) sind in der Nacht sichtbar, weil alle die Augen geschlossen haben. In Morgen und Tag erscheinen sie verdeckt („Nur für die Spielleitung“) und erst nach „Anzeigen“; mit der nächsten Handlung sind sie wieder verdeckt. Verdeckt entstehen keine Knoten mit geheimem Inhalt, und der Sitzkreis markiert dann weder handelnde noch wählbare Personen.
- Jede Hinrichtung läuft über eine verdeckte Prüfkarte mit der Vorschau des Regelkerns. Sie erscheint immer, damit ihr Auftauchen nichts über Spiegelwolf, Cerberus oder den Weisen verrät.
- Rollen, Protokoll, Morgendetails und geheime Tagesaktionen (Amalia, Nekromant) stehen in Ebenen, die erst beim Öffnen gebaut und beim Schließen, beim Sichtschutz, bei Zurück und beim Verlassen der Ansicht entfernt werden. Tippen neben die Schublade schließt sie.
- „Karte zeigen“ (Informationsrollen) und „Ansagekarte zeigen“ (Morgen) ersetzen das Cockpit vollständig und zeigen nur eine Positivliste: beim Orakel das gezeigte Ergebnis ohne Wahrheit, beim Morgen nur Namen der Toten (Rolle nur mit Setup-Option), Wiederbelebte und ausdrücklich öffentliche Hinweise.
- Sichtschutz blendet das ganze Cockpit aus und entfernt offene Ebenen. Rückkehr per Button „Cockpit wieder anzeigen“ (Abweichung von `02` §8 „Rückkehr nur über Halten“: kein Halten ohne Gerätetest).

## Ablauf

1. **Nacht beginnen.** Der Regelkern plant die Nacht und öffnet den ersten Schritt selbst.
2. **Schritt ankündigen.** Die Karte nennt Rolle bzw. Gruppe, handelnde Personen (im Sitzkreis hervorgehoben), Nummer „Schritt 3 von 7“ und den Vorlesetext. „Schritt beginnen“ sendet `BeginStep`; überspringbare Schritte (Rudel) haben „Überspringen …“ mit Pflichtbegründung.
3. **Prompt beantworten.** Eine Karte für alle Antwortarten des Regelkerns: Personenwahl im Sitzkreis (nur zulässige Plätze antippbar, Auswahl gold, „Auswahl bestätigen“ erst bei passender Anzahl, „Niemand / verzichten“ nur bei Mindestzahl 0), Ja/Nein, Bestätigen („Gezeigt“, „Zur Kenntnis genommen“), Optionen (Lehrling, Frankenstein), Zeitpunkt (Todesprediger). Abbrechbare Schritte haben „Schritt abbrechen …“ mit Begründung. Beim Orakel kann das gezeigte Ergebnis mit Begründung geändert werden.
4. **Nacht abschließen**, sobald alle Schritte erledigt sind (Hinweis auf entfallene oder übersprungene Schritte).
5. **Morgenauflösung.** Offene Reaktionen (Sensenträger, Besessener Wolf, Ritter, Schmiedewaffe, Dämonischer Wolf) erscheinen als verdeckte Schritte.
6. **Morgenbericht** vor den Tagesaktionen: Vorlesetext aus dem öffentlichen Teil, „Ansagekarte zeigen“, „Private Details …“ (Ursachen, Rettungen, entfallene Schritte, Reaktionen), „Weiter zum Tag“.
7. **Tag.** Nominierung in zwei Schritten (wer nominiert, wen), öffentliche Liste der Nominierungen, heutige Tode als Vorlesetext. Keine Stimmenerfassung: Die Spielleitung zählt am Tisch. Hinrichtung nur für heute Nominierte, danach verdeckte Prüfkarte (Spiegelung, Cerberus-Abwehrfrage, Fluchdauer des Weisen) und Rückfrage. „Keine Hinrichtung heute …“ mit Rückfrage. Danach „Tag beenden“ und die nächste Nacht.
8. **Sieg.** Erkannte Kandidaten erscheinen verdeckt. Bestätigen genau eines Kandidaten mit Rückfrage beendet die Partie; „Alle ablehnen …“ verlangt eine Begründung.

Mehrfachtippen: Jede Aktion sperrt die Karte bis zur neuen Sicht; Tippen auf einen bereits ersetzten Button wird ignoriert. Abgelehnte Befehle zeigen eine Fehlermeldung („Fehler: … Nichts wurde geändert.“) in Karte und Statusmeldung.

## Schichten

| Datei | Aufgabe |
|---|---|
| `app/session/game_session.gd` | hält Zustand, Befehle und Ereignisprotokoll; Sichten und Befehlsbausteine (`start_night`, `begin_next_step`, `answer_targets`, `answer_choice`, `nominate`, `decide_execution`, `gm_correction` …) setzen nur Prompt-ID, Stufe oder Schritt-ID ein |
| `app/session/cockpit_view.gd` | öffentliche Cockpit-Sicht, nächste Handlung, Hinrichtungsvorschau, geheime Tagesaktionen, privater Rollenbereich |
| `app/session/prompt_view.gd` | offener Prompt als Kartendaten: Antwortart je Besitzer und Stufe, zulässige Personen, Teilantworten, Positivliste `show` |
| `app/session/morning_report.gd` | Morgenbericht (öffentlich/privat) und heutige öffentliche Tode |
| `app/screens/cockpit/action_card.gd` | eine Karte für alle Handlungen, meldet Aktionen über `requested` |
| `app/screens/cockpit/cockpit_layers.gd` | Ebenen: Rollen, Protokoll, gezeigte Karte, Ansagekarte, Morgendetails, Sichtschutz |
| `app/screens/cockpit/cockpit_text.gd` | Schlüssel je Rolle und Stufe mit generischem Rückfall |
| `app/widgets/seat_ring/` | Sitzkreis des Cockpits (Anordnung aus `SeatCircle.layout`) |

Texte: `ui.call.<rolle>` (Vorlesetext), `ui.prompt.<besitzer>.<stufe>` (Anweisung), `ui.cockpit.action.<aktion>.<besitzer>.<stufe>` (rollenspezifische Beschriftung, etwa Loki „Liebende“/„Rivalen“), `ui.prompt.reaction.<art>`, `ui.morning.*`, `ui.cause.*` (nur privat). Alle Nachtrollen haben eigene Vorlesetexte und Anweisungen; `test_prompt_coverage` prüft das.

## Setup-Option „Rolle beim Tod öffentlich aufdecken“

DR-04 verlangt die Option im Setup. Sie fehlte bisher; sie steht jetzt im Rollenschritt (Standard: aus) und geht als optionales Feld `reveal_role_on_death` mit `StartGame` in den Spielstand (Schema 12). Sie ändert keine Regel, nur den öffentlichen Teil der Todesansagen.

## Abdeckung der Rollen über die Oberfläche

Grundlage: `tests/ui/test_prompt_coverage.gd` spielt 142 Partien mit allen 71 implementierten Rollen ausschließlich mit den Daten der Karte und löst jeden Prompt; seltene Reaktionen (Ritter bei Gleichstand, Schmiedewaffe) und die gestohlene Fähigkeit des Grabräubers sind gezielt geprüft. Tagesmechaniken prüft `tests/ui/test_cockpit_day.gd`. „Bedienbar“ heißt: headless über die Kartendaten und Buttons geprüft, nicht auf einem Tablet.

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

## Tests

| Test | Inhalt |
|---|---|
| `test_cockpit_model` | Sicht ohne Rollen, vollständige erste Nacht über die Bausteine, Abbruch (gleicher Hash), Pflichtbegründung, gestohlene Fähigkeit |
| `test_cockpit_screen` | Sitzkreis, Nacht über Buttons, verdeckte Reaktion, privater Bereich, Sichtschutz, gezeigte Karte, Begründungsdialog, Mehrfachtippen, Zurück, Layout 6/24 Personen bei 1024×768, 1280×800, 1920×1080 mit langen Namen, Morgenbericht mit und ohne Rollenaufdeckung |
| `test_prompt_coverage` | Bedienbarkeit aller Prompt-Arten, eigene Texte je Kombination, Ritter und Schmied |
| `test_morning_report` | Positivliste, private Ursachen und Rettungen, Rollenaufdeckung |
| `test_cockpit_day` | Nominierung, Hinrichtung mit Prüfkarte, Spiegelwolf, Weiser, Amalia, Nekromant, keine Hinrichtung, Sieg |
| `test_full_round_ui` | vollständige Partie nur über Buttons bis zum bestätigten Sieg |

Nicht geprüft: Darstellung auf echten Geräten, Schriftbild, Touch-Treffsicherheit, Lesbarkeit im Dunkeln, Übergänge. Diese Abnahme erfolgt gemeinsam am Tablet.
