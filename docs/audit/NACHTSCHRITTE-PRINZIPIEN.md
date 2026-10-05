# Nachtschritte: Prinzipien für die neue Schablone (Vorschlag)

Stand 2026-10-04, Branch `feature/testrunde-1`. Nur Vorschlag und Bestandsaufnahme, nichts umgebaut. Datenbasis: `NACHTSCHRITTE-72.csv` (72 Rollen).

## Messung

Je Rolle wurde die echte Aktionskarte der App gerendert (Nacht 1 bis 3, Tod, und für bedingte Rollen eine Partie mit vielen Toten bzw. Hinrichtungen). "Tipps im besten Fall" zählt den kürzesten Weg, bei dem die Fähigkeit benutzt wird: Beginnen 1, je Person 1, Bestätigen 1, Ja/Nein 1, "Karte zeigen" 1 plus "Gezeigt" 1, jeder Hinweis 2. Nicht gemessen (Bedingung nicht erreicht): Dorfschmied (ab Nacht 6), Schutzgeist (nur als Tote), Kartenschlucker (Totenreichkarten), Nacht 4 des Schicksalswolfs, Tagesfähigkeiten.

## Befunde

- Heute hat fast jeder Schritt dieselbe Kette: Ansage mit "Schritt beginnen", dann Auswahl mit "Tu jetzt", "Handelnd: n" und "Zulässige Anzahl", dazu "Auswahl bestätigen", "Abbrechen" und bei Wahlfreiheit "Niemand / verzichten".
- 12 von 72 Rollen widersprechen dem Kartentext (Verzicht oder Ablauf), siehe Spalte `widerspruch_app_vs_rollentext`.
- Die meisten Tipps: Blutpriester 9, Loki 8, Waldhexe 8, dann mit je 7 Kopfgeldjäger, Kutscher, Lehrling, Spürhund, Traumdeuter.
- Der Block "Zuerst aufrufen (nur Ansage)" für Rollen ohne Schritt steht zusätzlich auf Karten anderer Rollen und verlängert den Text.
- "Karte zeigen" steht bei 18 Rollen auf 20 Bildschirmen. Nötig ist es nur bei geheimer Information; bei den Gebundenen ist es überflüssig (Spalte `karte_zeigen_noetig`). 23 Rollen haben in der Nacht gar keinen eigenen Schritt.

## Prinzipien der neuen Schablone

1. **Mini-Nachtkarte (DA-101, ersetzt die Regelzeilen-Regel unten):** Der Spielleiter kennt das Spiel und spricht frei. Die Karte ist ein kleines Fenster (höchstens ein Viertel der Bildschirmbreite) am unteren Rand der freien Ringmitte, sie verdeckt keinen Sitz. Inhalt: Rollensymbol, Name der Person(en), 1 bis 3 Wörter Aktion (`ui.night.<besitzer>.<stufe>.short`), z. B. "Anna · Kriegerin des Lichts · greift an", "Die Werwölfe · wählen ihr Opfer". Darunter nur die nötigen Knöpfe, Teilantworten (z. B. das Opfer für die Waldhexe) und höchstens 3 rote Warnungen (Liste `docs/audit/NACHT-WARNUNGEN.md`). Kein Vorlesesatz, keine Regelzeilen, keine Hilfesätze; der Regeltext steht nur hinter dem "i" (Rollentext und Lexikon). Der Vorlesesatz ist über die Einstellung "Ansagen anzeigen" (Standard aus) klein unter der Aktion zuschaltbar. Ergebnisse stehen groß als Symbol oder Zahl im Fenster "Karte zeigen".
   Frühere Fassung (ersetzt): **Oben die Fähigkeit in 1 Satz, darunter bis zu 3 kurze Regelzeilen** mit dem, was der Spielleiter wissen muss (Sonderfälle, Wechselwirkungen). Ersetzt "höchstens 1 Satz Hilfe" (Rückmeldung iPad-Test 05.10.2026: die Karte war zu 90 % leer). Die Zeilen sind aus den Regeltexten im Repo abgeleitet, nichts erfunden; Quelle der Texte `ui.night.rules.<rolle>` in den Übersetzungsdateien, Übersicht in der Spalte `nachtkarte_regeln` von `NACHTSCHRITTE-72.csv`. Keine Bedienwörter wie "Tippe", "Tu jetzt", "Handelnd: 15", "Zulässige Anzahl gewählter Personen". Beispiel Loki: "Loki verbindet zwei Personen als Liebende oder Rivalen." / "· Loki darf sich selbst wählen." / "· Liebende: Stirbt einer, stirbt der andere aus Liebeskummer mit." / "· Rivalen: Keiner kann gewinnen, solange der andere lebt."
2. **Feste Anzahl wird direkt übernommen**, sobald sie erreicht ist ("genau 2", "genau 3"). Kein extra "Auswahl bestätigen"; stattdessen 3 Sekunden rückgängig machbar. Kein "Auswahl leeren" (Antippen wählt ab).
3. **Verzichten nur, wenn der Rollentext es erlaubt.** Dann genau ein Knopf mit klarem Wort ("Nicht heute"), nie zusätzlich "Niemand / verzichten" im Text und "Abbrechen" daneben. Wo der Text zwingt (Loki, Spürhund, Werwolf, Albtraumwolf), entfällt der Knopf; das ist eine Produktentscheidung (siehe unten).
4. **Entscheidungen vor der Spielerwahl** (Loki: Liebende oder Rivalen zuerst, dann die zwei Personen).
5. **"Karte zeigen" nur bei geheimer Information, und dann genau einmal.** Die Karte schließt selbst, kein zweites "Gezeigt". Hinweise an mehrere Personen kommen auf einen Bildschirm mit den Namen.
6. **Gruppen-Aufrufe (Die Gebundenen, Wölfe, Ewige) sind 1 Bildschirm** mit den Namen und "Weiter". Kein "Karte zeigen".
7. **"Schritt beginnen" entfällt**, wenn die Ansage und die Aktion auf demselben Bildschirm stehen können (Ansage als erste Zeile).
8. **Tarnansagen** (Rollen ohne Schritt) bleiben eine einzeilige Ansage, kein eigener Textblock.

## Offene Entscheidungen (nicht neu eröffnet, nur benannt)

- Loki: DECISION-LOG B-05 sagt "freiwillig"; Kartentext und Markus' Rückmeldung sagen genau 2. Entscheidung nötig.
- Werwolf-Rudel darf heute ausdrücklich niemanden wählen (Lexikon); Kartentext: "tötet jede Nacht ein Opfer".
- Lehrling: Spielleiter wählt heute erst drei Personen, der Lehrling wählt dann eine Rolle; Kartentext: "wählt einen Mentor".
- Rollen mit Verzicht-Knopf trotz Kartentext ohne Verzicht: Albtraumwolf, Besessener Wolf, Dämonischer Wolf, Feuerteufel, Henker, König Lykaon, Sensenträger, Spürhund, Voodoo-Priester (Lexikon: freiwillig).
