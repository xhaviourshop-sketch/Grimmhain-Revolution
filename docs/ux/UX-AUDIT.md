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
