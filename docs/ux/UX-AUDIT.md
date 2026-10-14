# UX-Audit Spielleiter (14.10.2026, Branch classic-akt, Vorschau Build 202610142040-c5d3754)

Rolle: Spielleiter zum ersten Mal an einem Abend mit 8 bis 10 Personen. Nur gelesen und getestet, kein Spielcode geändert.

## Was geprüft wurde und was nicht (ehrlich)
- **Im Browser gespielt** (Chrome/Playwright, PC 1920x1080, Maus): Start, Neue Partie (Classic, 8 Personen, Namen, Empfehlung), Spielstart, Nacht 1 Schritt 1 (Amor, zwei Ziele) und Schritt 2 (Engel, ein Ziel). Screenshots dazu in `docs/ux/img/`.
- **Aus dem Code gezählt, nicht im Browser gespielt:** Anklage und Hinrichtung (`godot/app/screens/cockpit/cockpit_screen.gd` ab Zeile 1080 und 1150 bis 1240, Texte in `godot/content/i18n/ui.de.po`).
- **Nicht geprüft** (Zeitgrenze 40 Minuten, das Canvas-Spiel ist nur per Koordinaten bedienbar): Tablet 1180x820 mit Touch, alle 19 Classic-Rollen, Grundspiel-Runde, Nacht 2 und 3, Hexe (Ja/Nein), Morgenmeldung, Jäger, Ritter, Spielende, Speichern, Fortsetzen, Rückgängig nach Fehlklick, Rollennachschlagen, Tastenkürzel. In der Tabelle sind diese Zeilen mit "nicht geprüft" markiert.

## Top 10: größter Gewinn bei kleinem Risiko
1. **F-01 Anklage von 5 auf 4 Tipps:** den Knopf "Anklage bestätigen" streichen. Nach dem Tipp auf die angeklagte Person erscheint direkt die zentrale Rückfrage "X klagt Y an?".
2. **F-02 Hinrichtung von 4 auf 3 Tipps:** den Knopf "Hinrichten" streichen, nach dem Tipp auf die Person direkt die Rückfrage.
3. **F-03 Rollen-Empfehlung vorausgewählt:** im Schritt Rollen ist die Empfehlung schon übernommen (spart einen Tipp, "Empfehlung übernehmen" wird zu "Anpassen").
4. **F-04 Namen ohne Prüffenster:** Enter oder "Hinzufügen" fügt Namen direkt ein. Das Prüffenster (mit eigener Scrollliste) nur bei Unklarheit.
5. **F-05 Aktionsknöpfe an die Karte:** "Karte zeigen" und "Rückgängig" liegen unten rechts, die Karte in der Mitte. Sie gehören direkt unter die Karte.
6. **F-09 "Karte zeigen" mit einem Tipp schließen:** der Hinweis "Anna und Cora" braucht heute "Schließen"; ein Tipp irgendwo schließt (Rollen zeigen funktioniert so schon).
7. **F-08 Spielmodus beim Start klar machen:** "Classic" steht wie eine Überschrift, Akt I ist vorgewählt. Beide Wege als gleich aussehende Karten zeigen.
8. **F-11 "Spiel starten" und "Spiel beginnen" zusammenlegen:** nach dem Rollenbildschirm folgt noch eine Seite mit "Spiel beginnen". Nach Rückfrage bei Markus.
9. **F-13 Zeitanzeige "-:--" erklären oder ausblenden**, solange kein Timer läuft.
10. **F-14 Hauptmenü ohne Partie:** "Spielleiter-Cockpit" und "Partie fortsetzen" ausgrauen oder erklären.

Größere Punkte mit Kernnähe oder Layoutrisiko (F-06, F-07, F-12, F-15) stehen bewusst nicht in der Liste.

## Pflicht-Tabelle
Quelle: B = im Browser gezählt, C = aus Code gezählt.

| Aufgabe | Aktuell | Minimum | Quelle | Vorschlag |
|---|---|---|---|---|
| Anklage (Ankläger, Angeklagter) | 5 Tipps: "Anklagen", Ankläger, Angeklagter, "Anklage bestätigen", "Bestätigen" im Fenster | 4 (3 Wahltipps plus 1 Bestätigung) | C | Knopf "Anklage bestätigen" streichen. Das Fenster sagt "Anna klagt Ben an?" mit "Ja" und "Zurück". Ergebnis: 4 Tipps, die Bestätigung bleibt einmalig am Ende. |
| Abstimmung | 0 (die Abstimmung findet am Tisch statt, die App erfasst nur Anklagen und das Ergebnis) | 0 | C (Text `ui.cockpit.card.day.do`) | keine Änderung |
| Hinrichtung | 4 Tipps: "Hinrichtung", Person, "Hinrichten", "Bestätigen" im Fenster. Mit Hinrichtungskandidat reichen 3 (Person, "Hinrichten", Fenster) | 3 (2 mit Kandidat) | C | Knopf "Hinrichten" streichen, direkt das Fenster |
| Nachtaktion mit einem Ziel (Engel) | 1 Tipp, kein Fenster, "Rückgängig" bleibt | 1 | B | schon gut, Vorbild für alle |
| Nachtaktion mit zwei Zielen (Amor) | 4 Tipps bis zur Ausführung: "Liebe" 1, zwei Personen 2, "Bestätigen" 1. Danach "Karte zeigen" 1 und "Schließen" 1, zusammen 6 | 3 (2 Personen plus 1 Bestätigung, ohne Liebe/Hass 2 bis 3) | B | Fenster "Stimmt das?" nach dem zweiten Ziel ersetzen durch Rückgängig (F-07); Hinweis mit einem Tipp schließen (F-09) |
| Entscheidung Ja/Nein (Hexe) | nicht geprüft | 1 | nicht geprüft | |
| Namen eingeben | Tippen, Enter, Fenster "8 Namen gefunden" (Scrollliste), "Alle hinzufügen", dann "Weiter": 3 Tipps nach dem Tippen | 2 (Enter, "Weiter") | B | F-04 |
| Sitzordnung ändern | nicht geprüft (vorhanden: "Mischen", "Früher", "Später", "Ändern", "Entfernen", Hinweis "Name antippen, dann verschieben") | nicht bestimmt | B (nur Ansicht) | |
| Spiel starten (ab Hauptmenü bis zur ersten Nachtkarte) | 9 Tipps plus Namen tippen: Neue Partie, Classic, Weiter, Enter, "Alle hinzufügen", Weiter, "Empfehlung übernehmen", "Spiel starten", "Spiel beginnen" | ca. 6 | B | F-03, F-04, F-08, F-11 |
| Partie fortsetzen | nicht geprüft (Eintrag "Partie fortsetzen" liegt direkt im Hauptmenü) | 1 | nicht geprüft | |
| Rückgängig nach Fehlklick | 1 Tipp, aber unten rechts weit von der Karte | 1 | B | F-05 |
| Rolle einer Person nachschlagen | nicht geprüft ("Rollen zeigen" auf dem Startbild, "Rollenlexikon" im Menü, Buchsymbol am linken Rand) | nicht bestimmt | nicht geprüft | |

## Befunde
Schweregrad: Spielfluss (stört den Spielfluss), Komfort, Kleinigkeit. Aufwand S/M/L. Kern: berührt der Vorschlag den Regelkern. Sonntag: klein und ohne Kernrisiko.

| Nr | Bildschirm | Problem | Vorschlag | Schwere | Aufwand | Kern | Sonntag |
|---|---|---|---|---|---|---|---|
| F-01 | Cockpit Tag, Anklage | Nach drei Tipps folgen zwei Bestätigungen (Knopf, dann Fenster). | Knopf streichen, nur das Fenster. | Spielfluss | S | nein | ja |
| F-02 | Cockpit Tag, Hinrichtung | Ebenso "Hinrichten" und dann Fenster. | Nur das Fenster. | Spielfluss | S | nein | ja |
| F-03 | Neue Partie, Schritt 3 | Der Bildschirm steht auf "0 / 8 Rollen gewählt", die Empfehlung muss extra übernommen werden. | Empfehlung vorbelegen, "Anpassen" statt "Empfehlung übernehmen". | Komfort | S | nein | ja |
| F-04 | Neue Partie, Schritt 2 | Enter öffnet "8 Namen gefunden" mit scrollbarer Liste (Dauerregel "nie scrollen" verletzt) und kostet zwei Tipps mehr (`img/namen-pruefen.png`). | Direkt übernehmen, Prüffenster nur bei "und", doppelten oder zu vielen Namen. | Spielfluss | M | nein | ja |
| F-05 | Cockpit Nacht | "Karte zeigen" und "Rückgängig" liegen unten rechts, die Karte mittig, der Mausweg ist weit (`img/amor-aktionsknoepfe-ecke.png`). | Knöpfe unter die Karte. | Komfort | M | nein | nein (Layout, braucht Sichtprüfung) |
| F-06 | Cockpit Nacht | Die Mittelkarte ändert nach "Bestätigen" Höhe und Lage. Kurz steht "Rückgängig" in der Karte, dann in der Ecke. Mein Tipp auf die Karte tat nichts, es wirkt wie ein Hänger. | Feste Kartenhöhe, Knöpfe nur an einem Ort. | Komfort | M | nein | nein |
| F-07 | Cockpit Nacht | Ein Ziel wirkt sofort, zwei Ziele (Amor) brauchen das Fenster "Stimmt das?". Uneinheitlich. | Beide gleich: sofort, mit Rückgängig. Vorher klären, ob das mit der zentralen zweiten Bestätigung vereinbar ist. | Komfort | M | nein | nein |
| F-08 | Neue Partie, Schritt 1 | "Classic" sieht wie eine Überschrift aus, Akt I ist vorgewählt. Man startet leicht im falschen Modus. Die Akt-Untertitel sind englisch ("Howl of the Hollow") in der deutschen Oberfläche. | Gleichartige Karten, deutsche Untertitel prüfen. | Komfort | S | nein | ja |
| F-09 | Hinweis "Anna und Cora" | Erst "Karte zeigen", dann "Schließen": zwei Tipps. | Ein Tipp irgendwo schließt. | Kleinigkeit | S | nein | ja |
| F-10 | Start | Das Menü erscheint im Browser nach grob 8 Sekunden (nicht genau gestoppt, Wartezeit bei der Erstladung). | Ladefortschritt prüfen. | Kleinigkeit | M | nein | nein |
| F-11 | Cockpit Start | Nach "Spiel starten" folgt eine Seite mit "Spiel beginnen" und "Rollen zeigen"; erst dort beginnt die Nacht. | Prüfen, ob "Spiel starten" direkt beginnen darf. "Rollen zeigen" bleibt erreichbar. | Komfort | S | nein | ja, nach Rückfrage |
| F-12 | Nacht 1, Amor | Amor fragte "Liebe oder Hass". `docs/classic/RUECKFRAGEN.md` sagt, der Classic-Bogen kenne nur Liebende. Ob die Empfehlung den Grundspiel-Amor einsetzte, habe ich nicht geklärt. | Prüfen, welche Rolle in der Empfehlung steckt. | Spielfluss (falls Classic) | S | ja, falls Classic-Regel falsch | nein |
| F-13 | Cockpit unten | Zeitanzeige "-:--" ohne Erklärung. | Beschriften oder ausblenden, solange kein Timer läuft. | Kleinigkeit | S | nein | ja |
| F-14 | Hauptmenü | "Spielleiter-Cockpit" und "Partie fortsetzen" stehen nebeneinander ohne Partie, der Unterschied ist unklar (nicht geöffnet). | Ohne Partie ausgrauen oder erklären. | Kleinigkeit | S | nein | ja |
| F-15 | PC allgemein | Keine Tastenkürzel gefunden, außer Enter im Namensfeld. Escape als Zurück nur laut Code (`app_shell.gd`). | Zuerst nur Leertaste für den Hauptknopf der Karte. | Komfort | M | nein | nein |
| F-16 | Cockpit Nacht | Nach dem Engel-Tipp zeigte die Leiste noch "Schritt 1 von 5". Ob der nächste Schritt von selbst beginnt, ist aus meinem Test nicht eindeutig. | Beim nächsten Durchlauf prüfen. | offen | | | |

## Fehler
Keine Abstürze und keine Sackgassen beobachtet. Nicht auszuschließen, weil nur ein kleiner Teil gespielt wurde.

## Nächster Schritt
Ein vollständiger Durchlauf auf dem Tablet mit Touch, alle Classic-Rollen und drei Nächte. Erst danach sind die Zahlen für Hexe, Jäger, Ritter, Speichern, Fortsetzen und Rückgängig belastbar.

---

# Durchlauf 2 (14.10.2026, Stand nach den UX-Umsetzungen, Commit 6bcec1f und folgende)

## Methode und Grenzen
Kein Browser: ein Godot-Skript mit echtem Renderer (1180x820, ohne Touch) startet ein Classic-Spiel mit 22 Personen (alle 19 Classic-Rollen, drei Brüder und zwei Schwestern als Gruppen), bedient die Karten über die echten Knöpfe, zählt Tipps (Rückfragefenster mitgezählt) und speichert je Kartentyp einen Screenshot. Wo die Bedienung scheiterte, ging das Skript per Kernbefehl weiter; die Zahlen unten gelten nur für Schritte mit Bedienung. Skript und alle Bilder liegen im Scratchpad, nicht im Repo; vier Bilder in `docs/ux/img/`.

## Ehrlich: weiterhin ungeprüft
Jäger-Schuss, Ritter-Fenster (die Wölfe fraßen den Ritter im zweiten Versuch nicht, mein Antwortschlüssel griff nicht), Spielende und Siegbestätigung, Speichern, Fortsetzen, Rückgängig nach Fehlklick (nur das Vorhandensein des Knopfs gesehen), Rolle nachschlagen, Sitzordnung nachträglich ändern, Rollenübersicht, Protokoll, Weißer Wolf mit Ziel (nur das Fenster gesehen), Abstimmung (gibt es in der App nicht). **Touch auf dem Tablet: gar nicht geprüft.** Tagesbedienung nur ein Versuch, der Bot verhedderte sich dort.

## Neue Tipp-Zahlen (gemessen, Rückfragefenster eingerechnet)
| Aufgabe | Aktuell | Minimum | Hinweis |
|---|---|---|---|
| Amor (Liebe/Hass, 2 Ziele, Bestätigen, Hinweis zeigen, schließen) | 6 | 4 | Hinweisanzeige macht die letzten 2 aus (F-07, F-09) |
| Hexe: Gifttrank nutzen | 4 (Ja 1, Bestätigen 1, Ziel 1, Bestätigen 1) | 3 | Ja/Nein braucht schon ein Fenster |
| Hexe: nichts tun ("Nicht vergiften") | 2 (Knopf, Bestätigen) | 1 | Ablehnen sollte ohne Fenster gehen (F-17) |
| Ein Ziel (Schutzengel, Orakel, Urwolf-Opfer) | 2 (Person, Bestätigen) | 1 bis 2 | im Browser-Lauf zuvor beim Engel nur 1 Tipp; Unterschied nicht geklärt (F-23) |
| Flötenspieler (1 Person) | 3 (Eine Person, Ziel, Bestätigen) | 2 | |
| Seherin (Ziel, Ergebnis zeigen) | 4 (Ziel 2, Karte zeigen 1, Schließen 1) | 3 | |
| Anklage am Tag | 4 plus 1 für "Weiter" am Tagesbeginn | 4 | nach F-01 erreicht |
| Hinrichtung | 2 bis 3 gemessen | 3 | Bot unzuverlässig, nicht belastbar |

## Neue Befunde (F-15 und F-16 stehen oben und bleiben; neue ab F-17)
| Nr | Bildschirm | Problem | Vorschlag | Schwere | Aufwand | Kern | Sonntag |
|---|---|---|---|---|---|---|---|
| F-17 | Nacht, Ja/Nein-Entscheidungen (Hexe, Urwolf "Nicht jetzt", Weißer Wolf "Nicht heute") | Auch das Ablehnen verlangt "Stimmt das?" (2 Tipps für "nichts tun"). Das passiert in jeder Nacht mehrfach. | Ablehnen ohne Fenster, Rückgängig genügt; nur Handlungen mit Wirkung bestätigen. | Spielfluss | S | nein, wenn die zentrale zweite Bestätigung für Ablehnen ausgenommen werden darf (vorher klären) | nein |
| F-18 | Nacht, Antwortreihe (Hexe, Urwolf, Flötenspieler) | Schriftgrößen der Knöpfe sind uneinheitlich: die rote Hauptantwort steht klein ("Gifttrank nutzen", "Verwandeln"), die dunkle Nebenantwort groß ("Nicht vergiften", "Nicht jetzt"). Beim Flötenspieler bricht "Eine Person" umbrochen und größer als "Zwei Personen" (`img/hexe-gift.png`, `img/urwolf.png`, `img/floetenspieler.png`). | Eine Schriftgröße für alle Knöpfe der Reihe; "Eine Person" und "Zwei Personen" kürzer oder gleich groß. | Komfort | S | nein | ja |
| F-19 | Nacht, jedes Fenster | "Rückgängig" steht schon im ersten Schritt oben im Fenster, über den Antwortknöpfen, obwohl noch nichts zurückzunehmen ist. Direkt neben "Gifttrank nutzen" besteht Fehltippgefahr. | Im Fenster nur zeigen, wenn es etwas zurückzunehmen gibt; Platz unter oder neben den Antworten, nicht darüber. | Komfort | M | nein | nein (Layout) |
| F-20 | Tag, Morgenmeldung | Bei mehreren Toten läuft der Text über das Fenster, mit Scrollleiste und Pfeil (`img/morgenmeldung.png`). Das verletzt "nie scrollen", und der Spielleiter liest laut vor. | Schrift verkleinern (Anpassung wie bei anderen Fenstern) oder die Zeilen auf zwei Seiten teilen. | Spielfluss | M | nein | nein |
| F-21 | Tag, Morgenmeldung | "Weiter" steht unten rechts in der Ecke, "Übernommen." und "Rückgängig" im Fenster. Anders als die Nachtfenster mit der Antwortreihe in der Mitte (F-05). | Gleiche Reihe im Fenster. | Komfort | M | nein | nein |
| F-22 | Nacht 1 mit Gruppenrollen (drei Brüder) | Eine Gruppe aufwecken ist "Weiter" in der Fenstermitte, dasselbe Wort wie "nächster Schritt" und als einziger Knopf neben "Rückgängig"; ohne Hinweis, dass die Gruppe jetzt wach ist, nur "wachen auf" im Text. Unklar, ob das Dorf jetzt schlafen gehen soll. | Satz "Gruppe wecken, dann Weiter" oder Knopf "Wecken". | Kleinigkeit | S | nein | ja |
| F-23 | Nacht, Ein-Ziel-Schritte | Im Browser-Lauf 1 (Engel) kein Fenster, im Skriptlauf zwei Tipps (Person, Bestätigen). Ob die Fensterlogik je nach Rolle oder Umgebung unterschiedlich ist, habe ich nicht geklärt. | Prüfen und vereinheitlichen (siehe F-07). | offen | S | nein | nein |
| F-24 | Nacht 2, Weißer Wolf | Das Fenster bietet nur "Nicht heute"; die Opfer (rot leuchtende Sitze) sind nur an Farbe erkennbar, keine Zeile erklärt "Tippe ein Opfer an". | Eine Zeile "Tippe eine Person an" ergänzen. | Kleinigkeit | S | nein | ja |
| F-25 | Rollennamen im Fenster | Fenstertitel bei Classic-Rollen zeigt intern andere Rollen (Teilweise "Die Hexe" für Classic-Hexe, "Der Flötenspieler" richtig); die Leiste oben nennt nur die Rolle. Das passt, aber die Seherin heißt in den Bedienwegen intern "Orakel" (Kartentext nicht geprüft). | Texte der Classic-Karten in einer Stichprobe gegen Rollennamen prüfen. | Kleinigkeit | S | nein | ja |

## Fehler (Durchlauf 2)
Keine Abstürze. Eine Sackgasse ist nicht belegt: Der Skript-Bot blieb bei optionalen Zielen (Rachsüchtiger Wolf, Weißer Wolf, Zählung 0 bis 1) hängen, weil er den Knopf "Nicht heute"/"Verzichten" nicht kannte. Das ist eine Grenze meines Bots, kein belegter Fehler im Spiel. Ob ein Mensch dort ohne Hilfe weiterkommt, sagt das Fenster mit "Nicht heute" ja; für den Rachsüchtigen Wolf (`img` fehlt) habe ich den Bildschirm nicht angesehen.

## Top 10 aktualisiert (größter Gewinn bei kleinem Risiko)
Bereits umgesetzt (Commits 21278d6, 4a3191f, 6bcec1f, cf50dee, F-04, F-09): F-01, F-02 (ohne Besonderheit), F-03, F-04, F-09, F-13, F-14; F-08 nur zum Teil.
1. **F-17 Ablehnen ohne Fenster** (spart 1 Tipp bei jedem "nichts tun"; vorher klären, ob die zentrale zweite Bestätigung dafür gilt).
2. **F-18 Knopfschrift vereinheitlichen** (reine Optik, kein Kern).
3. **F-11 Spielstart in einem Schritt** (Markus hat zugestimmt; braucht Testumbau).
4. **F-05/F-21 Antwortreihe überall im Fenster** (gleiche Stelle für "Weiter", "Karte zeigen", "Rückgängig").
5. **F-20 Morgenmeldung ohne Scrollen.**
6. **F-19 Rückgängig nur bei Bedarf und nicht über den Antworten.**
7. **F-07 Zwei-Ziele-Schritte wie Ein-Ziel-Schritte (sofort, mit Rückgängig).**
8. **F-24 Hinweiszeile beim Weißen Wolf.**
9. **F-22 Satz zum Wecken einer Gruppe.**
10. **F-08 Classic als gleichartige Auswahlkarte.**

## Nächster Schritt
Ein Durchlauf mit echtem Touch auf dem Tablet (Browser mit Touch-Emulation) für die Hauptabläufe, dazu Ritter, Jäger, Spielende, Speichern/Fortsetzen und Sitzordnung. Für den Bot lohnt ein kleiner Hilfsmodus mit festen Antworten; der Skript-Weg über `UiGame.step` reicht dafür nicht, weil der Antwortschlüssel für die Wölfe nicht griff.

## Umsetzungsstand 15.10.
Umgesetzt: F-17, F-18, F-11, F-05, F-21, F-19, F-20, F-07 (Amor), F-08, F-22, F-24. F-23 geklaert: kein rollen- oder umgebungsabhaengiger Zweig im Code; der Browser-Lauf mit einem Tipp stammte vermutlich von einem Build vor der zentralen Bestaetigung. Offen: englische Akt-Untertitel in der deutschen Oberflaeche (F-08), F-25.
