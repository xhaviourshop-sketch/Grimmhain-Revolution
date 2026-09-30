# Allgemeines Regelbuch und Handlungszeilen

Stand: 30.09.2026 (Nachtauftrag Paket C) · Godot 4.7.2 · Projekt `godot/` · Branch `feature/night-ui-expansion`

Die App erklärt den gesamten Spielablauf, zusätzlich zum Rollenlexikon (Paket 5b). Es gibt zwei Teile: das allgemeine Regelbuch und, je Rolle, die Handlungszeilen „Ablauf am Tisch“ im Lexikon (OI-18).

## Regelbuch

Lesende Ansicht mit Inhaltsverzeichnis und zwölf Kapiteln (`RuleBook`, Katalog `RulebookCatalog`):

1. Vorbereitung
2. Personen, Rollenwahl, Verteilung und Sitzordnung
3. Rollen sicher zeigen
4. Nacht führen und Tarnaufrufe
5. Private Informationen zeigen
6. Morgen und Wiederbelebungsrunde
7. Tag, Nominierung und physische Abstimmung
8. Hinrichtung und Todesreaktionen
9. Sieg bestätigen
10. Spielleiterkorrekturen und Undo
11. Speichern, Fortsetzen und Fehlerbehandlung
12. Rollenlexikon und Hilfe nutzen

Erreichbar: Hauptmenü → „Regelbuch“ (eigene Ansicht `rulebook`) und im Cockpit über das Werkzeug „Regelbuch“ (Ebene, auch ohne Partie). Bedienung: Verzeichnis, Kapitel als scrollbarer Text, „Vorheriges Kapitel“ und „Nächstes Kapitel“, „Inhaltsverzeichnis“, Sprachknopf (das geöffnete Kapitel bleibt), „Schließen“ (Ebene). Zurück schließt zuerst das Kapitel, dann die Ansicht.

### Inhalt und Quellen

- Ausschließlich bestätigte Regeln und tatsächlich umgesetzte Abläufe: Vertical-Slice-Ablauf, Decision Log (DR, DI, PE, PE-07), Cockpit-, Setup- und Speicherdokumente, Beschriftungen der Oberfläche.
- Jede in Anführungszeichen genannte Beschriftung, Meldung oder Vorlesezeile muss im Programm vorkommen (`test_rulebook::test_quoted_labels_exist_in_the_app`, DE und EN, rund 500 Prüfungen).
- Keine digitale Stimmzählung. Ausdrücklich genannt, dass es in dieser Version keinen Ton, keine Sprecherstimme, keine Smartphone-Ansicht der Mitspielenden und keine Kartenfunktionen gibt.
- Bewusst nicht ausformuliert, weil nur technisch abgeleitet oder offen: Aufruf blockierter und noch nicht aktiver Rollen (DI-02, zu bestätigen), Länge des Fluchs des Weisen in der Ansage (DA-23), Ton bei fünf Toten (NQ-01), Sitzplatztausch nach dem Start (NQ-03), Totenreichkarten.
- Sprache ohne Codebegriffe; das prüft ein Test gegen eine Liste verbotener Begriffe. Ohne Geviertstrich.

### Sicherheit

Das Regelbuch kennt keine Partie, keine Personen und keinen Spielstand (`RulebookCatalog` und Übersetzungen). Öffnen, Blättern, Sprachwechsel und Schließen senden keinen Befehl, ziehen keinen Zufall und verbrauchen nichts (Fingerabdruck aus Befehlen, Ereignissen und vollem Zustand bleibt gleich). Eine offene Zielauswahl bleibt erhalten, solange sich der Spielstand nicht ändert; danach gilt die bestehende Verwerfung. Auf einer gezeigten Karte (Karte zeigen, Ansagekarte, Rollenanzeige) ersetzt die Karte das Cockpit, das Werkzeug ist dort nicht erreichbar. Sichtschutz und Zurück schließen die Ebene. Das Regelbuch in einer laufenden Partie ist wortgleich mit dem ohne Partie.

## Handlungszeilen (OI-18)

Lexikonfeld `act`, Überschrift „Ablauf am Tisch“ (EN „Procedure at the table“), für alle 71 Rollen (`ui.role.<rolle>.lex.act`). Vier Zeilen:

| Zeile | Antwort auf |
|---|---|
| Aufruf | Wen ruft die Spielleitung wann auf, und was liest sie vor (der Vorlesetext der Karte, wörtlich) |
| Auswählen oder ablesen | Was muss sie auswählen oder ablesen (die Anweisungen der Karte) |
| Vorlesen oder zeigen | Was darf sie vorlesen oder zeigen |
| Beenden | Wie beendet sie den Schritt (Beschriftung des Knopfes) |

Die Zeilen sind aus den Kartentexten (`ui.call.*`, `ui.prompt.*`, `ui.cockpit.action.*`) und dem Feld „Nachtschritt“ des Lexikons zusammengesetzt und dürfen ihnen nicht widersprechen (`test_role_act_lines::test_lines_agree_with_the_card_texts`). Rollen ohne Nachtschritt beschreiben ihre Tages- oder Reaktionsbedienung (Amalia, Nekromant, Weiser, Cerberus, Spiegelwolf, Reaktionen) oder sagen, dass es nichts zu bedienen gibt. Nur entschiedene Abläufe. Rotkäppchen (NQ-06, DA-84): Rotkäppchen wählt die Person, die Spielleitung lässt Rotkäppchen die Augen wieder schließen, tippt die gewählte Person unauffällig an (ohne Namen zu nennen) und zeigt ihr die anonyme Frage auf dem Tablet (nicht laut vorlesen); die Antwort wird mit „Zuflucht gewährt“ oder „Keine Zuflucht“ erfasst, danach schließt die Person die Augen wieder. Diese Anleitung steht im Lexikon, im Regelbuch (Kapitel 5) und auf der Spielleiterkarte der Zielwahl, nicht auf der Karte der gefragten Person.

## Tests

| Test | Inhalt |
|---|---|
| `test_rulebook` | zwölf Kapitel mit vereinbarten Titeln, alle Blöcke in DE und EN vorhanden und verschieden, keine Codebegriffe, keine Platzhalter; Beschriftungen kommen im Programm vor; Hauptmenü, Verzeichnis, jedes Kapitel in DE und EN; Vor, Zurück, Escape; Sprachwechsel; jedes Kapitel bei 1024×768 in beiden Sprachen (Kopf und Fuß sichtbar, letzter Absatz nach Scrollen erreichbar); Cockpit-Werkzeug ohne Befehl, Zufall und Ressourcenverbrauch, Auswahl bleibt, wird nach Zustandsänderung verworfen; kein Partiedaten-Unterschied; Sichtschutz, Zurück; keine gezeigte Karte; ohne Partie |
| `test_role_act_lines` | vier beschriftete Zeilen je Rolle in DE und EN, Übereinstimmung mit den Kartentexten, vollständiger Ablauf von Rotkäppchen in fester Reihenfolge (keine offenen Punkte), Anzeige im Lexikoneintrag |

Nicht geprüft: Lesbarkeit, Darstellung und Bedienung auf einem Tablet. Redaktionelle Endabnahme aller Texte steht aus (maßgeblich ist `ui.*.po`; `docs/content-drafts/GUIDE-TEXTS.md` bleibt Entwurf).
