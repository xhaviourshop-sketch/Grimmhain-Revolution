# Prüfer-Erstlauf (05.10.2026)

Probelauf des Agenten-Teams (`docs/development/AGENTEN.md`) auf die 24 Screenshots in `Downloads/Grimmhain-Feedback-6/` (8) und `Downloads/Grimmhain-Feedback-7/` (16). Nur aufgelistet, nichts behoben. Funde sind Vorschläge der Prüfer, keine Entscheidungen; Markus entscheidet, was umgesetzt wird.

Durchführung: Die drei Prüfer liefen gleichzeitig. Weil die neuen Agenten beim Start des Probelaufs noch nicht geladen waren (Claude Code lädt sie verzögert), liefen sie als allgemeine Agenten mit der Anweisung aus ihrer Agentendatei und dem dort festgelegten Modell (Sprache Haiku, Marke und Spielleiter Sonnet). Dauer: 49 s (Marke), 111 s (Spielleiter), 139 s (Sprache).

Summe: **45 Funde** (Marke 21, Spielleiter 18, Sprache 6). Davon hoch 6, mittel 24, niedrig 15.

## Einordnung durch die Hauptsitzung

- Mehrfach gefunden (stark): Knopf "Kein Angriff in dieser Nacht" bricht um und sprengt den Rahmen (Marke, Spielleiter); Ergebnis in `vorschau-kriegerin-3` abgeschnitten (Marke, Spielleiter); Haken und Feuer bei Akt IV (Marke, Spielleiter); Titel "Die Werwölfe" bricht um (Marke, Spielleiter).
- Lücke der Sprachprüfung: Der Haiku-Prüfer hat die Regel "Knöpfe 1 bis 2 Wörter" auf den Bildern nicht angewendet ("Kein Angriff in dieser Nacht", "Nominierung erfassen" fehlen bei ihm). Für Bilder ist er schwächer als bei Textdateien; künftig ihm den Diff der Übersetzungsdateien mitgeben.
- Geheimhaltung (Spielleiter, Herzen und Fadenkreuz am Ring): Das iPad ist die Sicht des Spielleiters, keine öffentliche Ansicht. Ob Mitspieler das Gerät sehen, ist eine Produktfrage, kein Regelverstoß.
- Standardknöpfe in Einstellungen, Rollenliste und Vorschau-Leiste (Marke Punkt 2): `GroveWindow` gilt laut DA-100 für Fenster, nicht für ganze Bildschirme. Bewertung offen.

## Prüfer Sprache (Haiku), 6 Funde

```
[mittel] godot/content/i18n/ui.de.po:108 | "Lautstärke und Klänge folgen in einem späteren Arbeitspaket." | Regel 1 | Vorschlag: "Kommt später"
[mittel] godot/content/i18n/ui.de.po:2235 | "Diskussion und Abstimmung finden am Tisch statt. Du zählst die Stimmen selbst und erfasst nur Nominierungen und das Ergebnis." | Regel 3 | Vorschlag: "Diskussion am Tisch. Du erfasst Nominierungen und Ergebnis."
[mittel] godot/content/i18n/ui.de.po:9211 | "Tippe eine Rolle an: Du siehst nacheinander die Bildschirme der Spielleitung. Nichts wird gespeichert." | Regel 1 | Vorschlag: "Tippe eine Rolle an. Du siehst die Bildschirme der Spielleitung."
[mittel] godot/content/i18n/ui.en.po:107 | "Volume and sounds follow in a later work package." | Regel 6 | Vorschlag: "Coming soon"
[mittel] godot/content/i18n/ui.en.po:2235 | "Discussion and voting happen at the table. You count the votes yourself and record only nominations and the result." | Regel 3 | Vorschlag: "Discuss at the table. Record nominations and results."
[mittel] godot/content/i18n/ui.en.po:9211 | "Tap a role to see the game master screens one after another. Nothing is saved." | Regel 3 | Vorschlag: "Tap a role. See the game master screens here."
```

## Prüfer Marke (Sonnet), 21 Funde

Gold, Teamfarben und gotische Schrift: keine sicheren Funde.

```
[hoch] vorschau-kriegerin-3 | Ergebnisfenster Mitte unten, unter "Wolf" | Punkt 5 | Wolfssiegel und Haken am unteren Rand des Scrollbereichs halb abgeschnitten
[hoch] einstellungen-rollen-vorschau | ganzer Bildschirm (Sprache, Audio, Bedienhand, Anzeige) | Punkt 2 | flache Standard-Karten und Systemknöpfe ohne GroveWindow-Rahmen
[hoch] rollenliste | Rollenknöpfe und Kopfleiste "Zurück" | Punkt 2 | flache Standardknöpfe ohne GroveWindow-Rahmen
[hoch] rollenliste-ende | Rollenknöpfe und Kopfleiste | Punkt 2 | wie oben
[mittel] feuer-akt4-geisterfeuer | Karte "Akt IV" rechts Mitte | Punkt 3 | Wahl mit grellem weißblauem Leuchten statt Blutrot oder Mondsilber, ragt in die Unterkante von "Akt II"
[mittel] ansagen-anzeigen-an | Karte Mitte, Knopf "Kein Angriff in dieser Nacht" | Punkt 5 | Text bricht auf zwei Zeilen und ragt aus dem Knopfrahmen
[mittel] kriegerin-mit-warnung | Karte Mitte, Knopf unten | Punkt 5 | wie oben
[mittel] kriegerin-ohne-warnung | Karte Mitte, Knopf unten | Punkt 5 | wie oben
[mittel] vorschau-kriegerin-1 | Karte Mitte, Knopf unten | Punkt 5 | wie oben
[mittel] vorschau-kriegerin-sonderfall | Karte Mitte, Knopf unten | Punkt 5 | wie oben, Knopf klebt an der Kartenkante unter der zweiten Warnzeile
[mittel] alle 14 Vorschau-Bilder | Vorschau-Leiste unten (Rolle, Zurück, Weiter, Sonderfall, Liste) | Punkt 2 | flache Standardknöpfe ohne GroveWindow-Rahmen
[mittel] vorschau-kriegerin-5, vorschau-loki-5 | Aktionsleiste rechts, "Hinrichtung ..." | Punkt 5 | Kürzung mit "..." bei wichtiger Aktion
[niedrig] alle Vorschau-Bilder | Leiste links, "VORSCHAU" | Punkt 3 | blassrote Schrift und rote Linie für ein ruhiges Element
[niedrig] vorschau-kriegerin-5, vorschau-loki-5 | Tageskarte, "Nominierung erfassen" | Punkt 5 | Text bricht um und füllt den Rahmen bis zum Rand
[niedrig] werwoelfe | Karte Mitte unten, "Die Werwölfe wählen ihr Opfer" | Punkt 5 | Titel bricht nach "Die" um, Karte wirkt gequetscht
[niedrig] rollenliste-ende | oberste Knopfreihe | Punkt 5 | Reihe angeschnitten, "Prophet des Untergangs" ohne Symbol
[niedrig] rollenliste | untere Knopfreihe | Punkt 5 | Reihe unten angeschnitten, "Wahnsinniger Kutscher" ohne Symbol
[niedrig] feuer-akt4-geisterfeuer | Karte "Akt IV", Haken | Punkt 6 | Haken überlagert "Bis zu 24 Personen"
[niedrig, unsicher] einstellungen-rollen-vorschau | Hilfstexte | Punkt 1 | warmes Beige-Grau, leicht Richtung Messing
[niedrig, unsicher] feuer-akt4-geisterfeuer | Zeilen Dorf / Wölfe / Einzelgänger | Punkt 7 | Teamsymbole silber statt Teamfarbe (evtl. gewollte Silber-Prägung)
[niedrig, unsicher] waldlaeufer-ergebnis | Knopf "Fertig" | Punkt 3 | volle Blutrot-Leiste über die ganze Fensterbreite
```

## Prüfer Spielleiter (Sonnet), 18 Funde

```
[hoch] vorschau-loki-3 (auch kriegerin-mit-warnung, vorschau-kriegerin-sonderfall) | Frage 5 | Herzen an Tom und Lena dauerhaft am Ring, Mitschauende sehen die Liebenden | Vorschlag: Herz nur, wenn öffentlich bekannt
[hoch] vorschau-kriegerin-3 | Frage 6 | Ergebnis abgeschnitten (Wolf-Symbol, Haken, Scrollbalken), wohl durch die Vorschau-Leiste | Vorschlag: Ergebnisfenster in der Vorschau um die Leistenhöhe kürzen
[mittel] vorschau-kriegerin-2 | Frage 4 | roter Ring auf Lukas, nächste Karte nennt Tom; Bedeutung des Rings unklar | Vorschlag: Ring und Ergebnis auf dieselbe Person, Ring beschriften
[mittel] kriegerin-ohne-warnung (auch kriegerin-mit-warnung, ansagen-anzeigen-an, waldlaeufer-karte) | Frage 3 | "Rückgängig" doppelt (Karte und unten rechts), vor einer Auswahl sinnlos | Vorschlag: Knopf in der Karte erst nach einer Auswahl
[mittel] vorschau-loki-2 | Frage 2 | "Rivalen" klein in der Karte, "Liebende" groß rot unten rechts | Vorschlag: zwei gleich große Knöpfe, Entscheidung vor der Personenwahl (Prinzip 4)
[mittel] vorschau-loki-3 | Frage 1 | Leiste oben "2 · Werwolf", Karte zeigt Loki "Karte zeigen" | Vorschlag: Leiste und Karte auf denselben Schritt
[mittel] vorschau-kriegerin-1 (alle Karten mit "Kein Angriff in dieser Nacht") | Frage 6 | Knopf bricht um, klein, schwer lesbar | Vorschlag: "Kein Angriff" oder höherer Knopf
[mittel] vorschau-kriegerin-4, vorschau-loki-4 | Frage 2 | "Weiter" in der Leiste und rotes "Weiter" im Bildschirm, dazu "Zurück" | Vorschlag: Leistenknöpfe anders benennen und farblich trennen
[mittel] rollenliste | Frage 2 | 72 Rollen ohne erkennbare Reihenfolge, ohne Sprung zu Dorf/Wölfe/Einzelsieg | Vorschlag: alphabetisch oder Sprungmarken
[mittel] feuer-akt4-geisterfeuer, kriegerin-mit-warnung | Frage 5 | Fadenkreuz am Wolfsopfer vor der Morgenansage sichtbar | Vorschlag: Zielmarke nur in der Karte
[mittel] waldlaeufer-karte | Frage 5 | roter Ring an Felix vor "Karte zeigen"; Bedeutung unklar | Vorschlag: klären, ggf. erst nach "Karte zeigen"
[mittel] vorschau-loki-4 | Frage 5 | "Für dich: Tom und Lena sind Liebende ..." neben "Fürs Dorf" | Vorschlag: "Für dich" kleiner oder hinter einem Tipp
[niedrig] werwoelfe | Frage 6 | "Die" / "Werwölfe" in zwei Zeilen | Vorschlag: Kopfzeile auf eine Zeile weiten
[niedrig] feuer-akt4-geisterfeuer | Frage 6 | Haken auf "Bis zu 24 Personen", Feuer läuft in Akt II | Vorschlag: Haken in die Ecke, Feuer begrenzen
[niedrig] waldlaeufer-ergebnis | Frage 6 | Wolf-Symbol links unten neben der "1" | Vorschlag: Symbol und Zahl in eine Reihe
[niedrig] rollenliste-ende | Frage 4 | "(Lücke)" unklar, Knöpfe ohne Symbol | Vorschlag: erklären oder ausblenden
[niedrig] vorschau-kriegerin-5, vorschau-loki-5 | Frage 3 | vier Zeilen Regeltext ("Du zählst die Stimmen selbst ..."), "Niemand" und "Hinrichtung ..." unklar | Vorschlag: eine Zeile oder hinter das "i"
[niedrig] einstellungen-rollen-vorschau | Frage 2 | Eintrag "Rollen-Vorschau" erst nach Scrollen sichtbar | Vorschlag: weiter oben
```

Tipps im besten Fall (Spielleiter): Kriegerin 3, Loki 4 bis 5, Werwölfe 1, Waldläufer 2.
