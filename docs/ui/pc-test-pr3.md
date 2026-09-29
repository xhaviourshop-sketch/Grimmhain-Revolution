# Manueller PC-Test · PR #3 (geführte Partie im Cockpit)

Stand: 29.09.2026 (mit den Entscheidungen DI-01 bis DI-08, Teile I bis L) · Branch `feature/night-ui-expansion` · Godot 4.7.2

**Das ist ein Windows-Fenstertest mit Maus und Tastatur. Er ist keine Tablet-, Touch- oder Endgeräte-Abnahme.** Godot-Kenntnisse sind nicht nötig. Dauer etwa 30 Minuten. Abweichungen trägst du in die Fehlerliste ein: [pc-test-pr3-fehlerliste.md](pc-test-pr3-fehlerliste.md).

Die Partie unten ist vorab headless mit denselben Befehlen durchgespielt worden. Die erwarteten Ergebnisse stammen aus diesem Lauf, nicht aus einer Annahme. Wie es aussieht, prüfst erst du.

## Starten

1. Im Explorer den Ordner `C:\Users\Marku\Desktop\Grimmhain\grimmhain-night-ui` öffnen.
2. `PC-Test-starten.cmd` doppelklicken. Er startet die vorhandene Godot-Version 4.7.2 aus `Downloads\Godot_v4.7.2-stable_win64.exe\` direkt mit dem Spiel, ohne Editor und ohne Installation.
3. Erwartet: Ein Fenster „Grimmhain“ (1280 × 800) mit dem Startbildschirm und dem Button „Eintreten“. Der erste Start kann einige Sekunden dauern.

Erscheint stattdessen ein schwarzes Textfenster mit „Fehler: …“, steht dort, welche Datei fehlt. Das Fenster mit einer Taste schließen und die Meldung in die Fehlerliste übernehmen.

Ist die Oberfläche englisch: Hauptmenü → „Settings“ → „Deutsch“ → zurück.

## Feste Partie

| Nr. | Name | Rolle |
|---|---|---|
| 1 | Anna | Werwolf |
| 2 | Ben | Werwolf |
| 3 | Clara | Schutzengel |
| 4 | David | Waldhexe |
| 5 | Emma | Das Orakel |
| 6 | Felix | Doppelspion |
| 7 | Greta | Dorfbewohner |
| 8 | Hannes | Dorfbewohner |

Warum der Doppelspion: Das Setup verlangt mindestens eine Einzelsiegrolle. Er hat keinen eigenen Nachtschritt und stört den Ablauf nicht. Am Ende sorgt er für den Einzelsieg (siehe H3).

Ablauf in Kürze: Nacht 1 schützt Clara Greta, die Wölfe töten Hannes, Emma prüft Anna. Tag 1 wird Anna hingerichtet. Nacht 2 schützt Clara Emma, die Wölfe greifen Emma an (gerettet), Emma prüft Ben. Tag 2 wird Ben hingerichtet.

Format: **Tun** ist die Bedienhandlung, **Erwartet** das Ergebnis. Die Schrittnummer (etwa „C4“) trägst du in der Fehlerliste ein.

## A · Setup und Spielstart

- **A1** Tun: „Eintreten“, dann „Neue Partie“. Erwartet: „Neue Partie · Spieler“, leere Spielerliste.
- **A2** Tun: „Mehrere Namen einfügen“, genau diese Zeile eingeben: `Anna, Ben, Clara, David, Emma, Felix, Greta, Hannes`, dann „Namen übernehmen“. Erwartet: „8 / 24 Spieler“, Liste 1. Anna bis 8. Hannes in dieser Reihenfolge.
- **A3** Tun: „Spieler bestätigen“, dann „Weiter zu den Rollen“. Erwartet: „Rollen auswählen“, Schrittanzeige „Schritt 2“.
- **A4** Tun: „+“ bei Werwolf zweimal, bei Schutzengel, Waldhexe, Das Orakel und Doppelspion je einmal, bei Dorfbewohner zweimal. Erwartet: seitlich der Hinweis „Ohne Wiederbelebung: Rollen werden beim Tod aufgedeckt, Tote müssen nachts die Augen nicht schließen.“ und kein Schalter „Rolle beim Tod öffentlich aufdecken“ mehr (ersetzt am 29.09.2026). Außerdem: „8 von 8 Rollen gewählt“, „Passt genau“, „Dorf 5 · Werwölfe 2 · Einzelsieg 1“.
- **A5** Tun: „Rollen bestätigen“. Unter „Verteilungsmodus“ auf „Manuell“. Bei jeder Person „Rolle zuweisen“ und die Rolle aus der Tabelle wählen (etwa „Werwolf · 2 frei“). Erwartet: „Alle Rollen vergeben“ und „Alle zugewiesen. Bereit zum Bestätigen.“ Kontrolle über „Geheime Zuordnung zeigen“: genau die Tabelle, danach „Zuordnung verbergen“.
- **A6** Tun: „Verteilung bestätigen“, dann „Weiter zur Sitzordnung“. Nichts tauschen. Erwartet: Plätze „1 · Anna“ bis „8 · Hannes“ im Uhrzeigersinn, nirgends eine Rolle.
- **A7** Tun: „Sitzordnung bestätigen“, dann „Partie starten“. Erwartet: Meldung „Partie gestartet“, Cockpit mit acht Plätzen, Ansagekarte „Nacht 1 beginnen“.

## B · Sitzkreis und geheime Informationen

- **B1** Tun: Cockpit ansehen. Erwartet: Sitzkreis, Phasenleiste und Karte nennen keine Rolle.
- **B2** Tun: „Rollen“. Erwartet: „Rollen · nur Spielleitung“ mit Warnhinweis und allen acht Rollen wie in der Tabelle. Tun: „Schließen“. Erwartet: Die Liste ist ganz weg.
- **B3** Tun: „Verbergen“. Erwartet: „Sichtschutz“, das Cockpit ist nicht zu sehen. Tun: „Cockpit wieder anzeigen“. Erwartet: unverändert zurück.

## C · Nacht 1 und zeigbare Orakelkarte

- **C1** Tun: „Nacht beginnen“. Erwartet: Nachtfarben, Karte „Schutzengel“ mit Vorlesetext, handelnd „Clara“, Zeile „Zulässige Anzahl gewählter Personen: 1.“. Claras Platz ist nicht wählbar.
- **C2** Tun: Greta (Platz 7) anklicken. Erwartet: Platz golden, „Gewählt: 7 · Greta“. Tun: „Auswahl bestätigen“ zweimal schnell hintereinander. Erwartet: Es geht genau einen Schritt weiter, zur Karte der Werwölfe.
- **C3** Tun: „Schritt beginnen“, Hannes (8) anklicken, „Auswahl bestätigen“. Erwartet: nächste Karte „Waldhexe“.
- **C4** Tun: „Schritt beginnen“, „Nicht heilen“, „Nicht vergiften“, „Bestätigen“. Erwartet: drei Fragen nacheinander, danach die Karte „Das Orakel“.
- **C5** Tun: „Schritt beginnen“, Anna (1) anklicken, „Auswahl bestätigen“. Erwartet: Ergebnis Anna · Werwolf, Buttons „Karte zeigen“ und „Gezeigt“.
- **C6** Tun: „Karte zeigen“. Erwartet: ganzer Bildschirm nur mit „Das Orakel“, Anna und Werwolf, keine anderen Namen, Rollen oder Knöpfe des Cockpits. Tun: „Zurück zur Spielleitung“, dann „Gezeigt“.
- **C7** Tun: „Nacht abschließen“. Erwartet: Morgenbericht (Teil D).

## D · Morgenbericht

- **D1** Erwartet: Karte „Morgenbericht“, Vorlesetext mit Hannes und seiner Rolle „Dorfbewohner“ (Runde ohne Wiederbelebung, siehe A4). Greta und der Schutzengel werden nicht erwähnt.
- **D2** Tun: „Ansagekarte zeigen“. Erwartet: „Morgen nach Nacht 1“, nur Hannes (Dorfbewohner), keine Ursache. Tun: zurück.
- **D3** Tun: „Private Details …“. Erwartet: „Morgenbericht · nur Spielleitung“ mit der Ursache von Hannes' Tod. Tun: schließen.
- **D4** Tun: „Weiter zum Tag“. Erwartet: Tagesfarben, Karte für Tag 1, Hannes im Sitzkreis mit „†“.

## E · Nominierung

- **E1** Tun: „Nominierung erfassen“, Emma (5) anklicken, dann Anna (1), „Nominierung bestätigen“. Erwartet: Die Tageskarte listet die Nominierung Emma → Anna.

## F · Rückgängig bei offener Prüfkarte

- **F1** Tun: „Hinrichtung …“, Anna anklicken, „Weiter zur Prüfung“. Erwartet: verdeckte Karte „Hinrichtung prüfen: 1 · Anna“ mit „Anzeigen“. Tun: „Anzeigen“. Erwartet: „Keine Besonderheit: … stirbt durch die Hinrichtung.“ Noch **nicht** bestätigen.
- **F2** Tun: „Spielleitung“, „Rückgängig: Nominierung: …“, im Dialog „Rückgängig“. Erwartet: Der Dialog sagt, dass Gezeigtes bekannt bleibt. Danach ist die Prüfkarte weg, die Nominierung ist nicht mehr gelistet, und „Hinrichtung …“ ist gesperrt.
- **F3** Tun: „Spielleitung“, „Wiederholen: Nominierung: …“, „Wiederholen“. Erwartet: Die Nominierung Emma → Anna ist wieder da.

## E (Fortsetzung) · Hinrichtung

- **E2** Tun: „Hinrichtung …“, Anna, „Weiter zur Prüfung“, „Anzeigen“, „Hinrichtung bestätigen“, im Dialog „Hinrichten“. Erwartet: Anna mit „†“, Vorlesetext „Heute gestorben: Anna (Werwolf).“, Karte „Tag beenden“.
- **E3** Tun: „Tag beenden“. Erwartet: Karte „Nacht 2 beginnen“.

## G · App schließen und offene Aktion fortsetzen

- **G1** Tun: „Nacht beginnen“. Schutzengel: Emma (5) anklicken, „Auswahl bestätigen“. Werwölfe: „Schritt beginnen“, Emma (5), „Auswahl bestätigen“. Waldhexe: nur „Schritt beginnen“. Erwartet: Die Waldhexe fragt nach dem Heiltrank. In der Phasenleiste steht „Gespeichert“.
- **G2** Tun: Das Fenster oben rechts mit „X“ schließen. Erwartet: Das Fenster schließt ohne Rückfrage.
- **G3** Tun: `PC-Test-starten.cmd` erneut doppelklicken, „Eintreten“, „Partie fortsetzen“. Erwartet: ein Eintrag „Anna, Ben, … (8 Personen)“, Nacht 2. Tun: „Fortsetzen“. Erwartet: „Partie fortgesetzt“, Cockpit, dieselbe offene Frage der Waldhexe nach dem Heiltrank.
- **G4** Tun: „Nicht heilen“, „Nicht vergiften“, „Bestätigen“. Orakel: „Schritt beginnen“, Ben (2), „Auswahl bestätigen“, „Gezeigt“. Dann „Nacht abschließen“. Erwartet: Morgenbericht ohne Tote (Emma wurde geschützt). Tun: „Weiter zum Tag“.

## H · Protokoll und Spielende

- **H1** Tun: „Protokoll“. Erwartet: „Protokoll · nur Spielleitung“ mit lesbaren Einträgen (Nächte, Antworten, Nominierung, Hinrichtung von Anna), keine technischen Codes. Tun: schließen.
- **H2** Tun: „Nominierung erfassen“, Clara (3), dann Ben (2), bestätigen. „Hinrichtung …“, Ben, „Weiter zur Prüfung“, „Anzeigen“, „Hinrichtung bestätigen“, „Hinrichten“.
- **H3** Erwartet: verdeckte Karte „Nur für die Spielleitung“, „Eine Siegbedingung ist erfüllt …“. Tun: „Anzeigen“. Erwartet: „Mögliches Spielende“: Einzelsieg, „Der Doppelspion lebt und kein Wolf lebt mehr.“, Felix. Kein Dorfsieg, das ist die beschlossene Regel (RM-DR-155.3). Tun: „Sieg bestätigen: Einzelsieg“, im Dialog „Sieg bestätigen“. Erwartet: „Die Partie ist beendet“.

## I · Wiederbelebungsrunde, Tarnaufruf und Todeseffekt (neu, zweite Partie mit 6 Personen)

Diese Teile prüfen die Entscheidungen vom 29.09.2026 (DI-01 bis DI-08, `docs/content-drafts/DECISIONS-TO-INTEGRATE.md`). Die erwarteten Kartenfolgen stammen aus einem Headless-Lauf mit denselben Befehlen. Vorher die erste Partie beenden: Cockpit „Esc“, „Zum Hauptmenü“, dann „Neue Partie“ (eine offene Partie bleibt unter „Partie fortsetzen“ erhalten).

- **I1** Tun: „Neue Partie“, „Mehrere Namen einfügen“: `A, B, C, D, E, F`, „Namen übernehmen“, „Spieler bestätigen“, „Weiter zu den Rollen“. Bei Werwolf zweimal „+“, bei Ritter, Dorfbewohner, Doppelspion und Kutscher je einmal. Erwartet: „6 von 6 Rollen gewählt“ und seitlich der Hinweis „Wiederbelebungsrunde: Rollen bleiben beim Tod verdeckt, Tote halten nachts die Augen geschlossen.“ Es gibt keinen Schalter „Rolle beim Tod öffentlich aufdecken“ mehr.
- **I2** Tun: Kutscher auf 0 und Dorfbewohner auf 2 stellen. Erwartet: Der Hinweis wechselt zu „Ohne Wiederbelebung: Rollen werden beim Tod aufgedeckt, Tote müssen nachts die Augen nicht schließen.“ Tun: Kutscher wieder auf 1 und Dorfbewohner auf 1.
- **I3** Tun: „Rollen bestätigen“, „Manuell“, zuweisen: A Werwolf, B Ritter, C Dorfbewohner, D Doppelspion, E Kutscher, F Werwolf. „Verteilung bestätigen“, „Weiter zur Sitzordnung“, „Sitzordnung bestätigen“, „Partie starten“. Erwartet: Karte „Nacht 1 beginnen“ mit der Vorlesezeile „Die Nacht bricht herein. Alle schließen die Augen, auch die Toten.“
- **I4** Tun: „Nacht beginnen“. Erwartet: Karte der Werwölfe, keine Zeile „Zuerst aufrufen“. Tun: B (2) anklicken, „Auswahl bestätigen“. Erwartet: Karte „Nacht abschließen“ mit der Zeile „Zuerst aufrufen (nur Ansage)“ und der Vorlesezeile des Kutschers („Kutscher, erwache. …“). Der Kutscher hat heute keinen Schritt, wird aber angesagt, damit der Tisch nichts erfährt. Es ändert sich nichts am Zustand.
- **I5** Tun: „Nacht abschließen“. Erwartet: Morgenbericht mit „In dieser Nacht sind gestorben: A, B.“ (ohne Rollen, Wiederbelebungsrunde) und der Zeile „B war Ritter und reißt A mit in den Tod.“ (der Todeseffekt nennt die Rolle bewusst). Kein Wort über Rudel, Schutz oder Ursache. Tun: „Ansagekarte zeigen“. Erwartet: dieselben Zeilen, keine Ursache.
- **I6** Kontrolle in einer Partie ohne Wiederbelebung (etwa der ersten Partie): Ein Tod nennt Name und Rolle (siehe D1 und E2), Todeseffekte nennen ebenfalls die Rolle.

## J · Hinweiskarte Loki (neu, Partie mit 7 Personen)

- **J1** Tun: Neue Partie mit den Namen `A, B, C, D, E, F, G` und den Rollen A Werwolf, B Loki, C bis F Dorfbewohner, G Doppelspion (Rollen zuweisen, bestätigen, Sitzordnung, starten). Tun: „Nacht beginnen“. Erwartet: Karte „Loki“. Tun: C (3) und E (5) anklicken, „Auswahl bestätigen“, dann „Liebende“. Erwartet: Karte „Privater Hinweis“ mit „Für: 3 · C“.
- **J2** Tun: „Karte zeigen“. Erwartet: ganzer Bildschirm „Hinweis für dich“ mit „Du und 5 · E seid Liebende. Stirbt eine Person von euch, stirbt die andere sofort mit.“ Kein anderer Name, keine Rolle. Tun: „Schließen“, dann „Gezeigt“.
- **J3** Erwartet: zweite Karte „Für: 5 · E“, der Text nennt 3 · C als Partner. Noch nicht bestätigen. Tun: „Spielleitung“, „Rückgängig …“, im Dialog „Rückgängig“. Erwartet: Die erste Karte „Für: 3 · C“ steht wieder an. Tun: „Spielleitung“, „Wiederholen …“. Erwartet: Die zweite Karte ist wieder da.
- **J4** Tun: Das Fenster mit „X“ schließen, `PC-Test-starten.cmd` erneut starten, „Partie fortsetzen“, „Fortsetzen“. Erwartet: dieselbe zweite Hinweiskarte („Für: 5 · E“). Tun: zeigen, schließen, „Gezeigt“. Erwartet: Karte „Werwölfe“ mit „Schritt beginnen“. Tun: „Schritt beginnen“, F (6) anklicken, „Auswahl bestätigen“, „Nacht abschließen“.
- **J5** Tun: „Weiter zum Tag“. Nominierung erfassen: D (4) nominiert C (3). Hinrichtung C. Erwartet: Vorlesezeile „Heute gestorben: C (Dorfbewohner), E (Dorfbewohner).“ und darunter „Aus Liebeskummer stirbt E.“ (Liebeskummer nennt keine Rolle).

## K · Rotkäppchen-Frage, anonym (neu, Partie mit 7 Personen)

- **K1** Tun: Neue Partie mit den Rollen A Werwolf, B Rotkäppchen, C bis F Dorfbewohner, G Doppelspion. Nacht 1: Werwölfe: F (6) anklicken, „Auswahl bestätigen“. Erwartet: Karte „Rotkäppchen“. Tun: „Schritt beginnen“, D (4) anklicken, „Auswahl bestätigen“.
- **K2** Erwartet: Karte „Zuflucht“ mit „Gefragt: 4 · D“ und dem Text „Jemand bittet dich um Zuflucht. Gewährst du sie, erhältst du einen Apfel … und ihr seid verkettet …“. Die Karte nennt weder „Rotkäppchen“ noch B. Buttons „Zuflucht gewährt“ und „Keine Zuflucht“. Tun: „Zuflucht gewährt“. Erwartet: Karte „Nacht abschließen“.

## L · Rattenfänger und Pestbringerin (neu)

- **L1** Rattenfänger: Neue Partie mit den Rollen A Werwolf, B Rattenfänger, C bis F Dorfbewohner, G Doppelspion. Nacht 1: Werwölfe: F (6) wählen und bestätigen, Rattenfänger „Schritt beginnen“, C (3) und D (4) anklicken, „Auswahl bestätigen“. Erwartet: Karte „Privater Hinweis“ für die neu Verzauberten („Ihr seid verzaubert …“, ohne Namen). Tun: zeigen, „Gezeigt“. Erwartet: zweite Karte „Alle Verzauberten: 3 · C, 4 · D. Ihr erkennt einander.“ Tun: zeigen, „Gezeigt“.
- **L2** Pestbringerin: Neue Partie mit den Rollen A Werwolf, B Pestbringerin, C bis G Dorfbewohner, H Doppelspion (8 Personen, Namen A bis H). Nacht 1: Werwölfe: G (7) wählen und bestätigen, Pestbringerin „Schritt beginnen“, E (5) anklicken, „Auswahl bestätigen“. Erwartet: Karte „Privater Hinweis“ für 5 · E („Du bist infiziert …“). Tun: zeigen, „Gezeigt“, „Nacht abschließen“. Erwartet am Morgen: Karte „Privater Hinweis“ für die neu Angesteckte, im Tagesmodus zuerst verdeckt („Anzeigen“ drücken), Text nennt keinen Namen.

## Godot vollständig beenden

1. Im Cockpit „Esc“ drücken (oder „Zurück“), dann „Zum Hauptmenü“. Im Hauptmenü „Beenden“, im Dialog „Beenden“. Alternativ das Fenster mit „X“ schließen.
2. Kontrolle: Task-Manager öffnen (Strg + Umschalt + Esc), Reiter „Prozesse“. Dort darf kein „Godot_v4.7.2-stable_win64“ mehr stehen. Falls doch: auswählen, „Task beenden“.

Der Starter selbst hält kein Fenster offen.

## Aufräumen (optional)

Die Testpartie bleibt unter „Partie fortsetzen“. „Verwerfen …“ entfernt sie aus der Liste. Die Dateien werden dabei nur umbenannt, nicht gelöscht. Speicherort: `%APPDATA%\Godot\app_userdata\Grimmhain\saves`.

## Nicht Teil dieses Tests

Tablet, Touch, Schriftbild auf Geräten, Lesbarkeit im Dunkeln. Außerdem Spezialkorrekturen und „Rollen zeigen“, die noch keine Oberfläche haben. Die Grenzen stehen in `docs/ui/cockpit.md`.
