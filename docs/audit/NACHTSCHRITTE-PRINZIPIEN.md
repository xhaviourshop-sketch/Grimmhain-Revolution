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

1. **Oben die Fähigkeit in 1 Satz, darunter höchstens 1 Satz Hilfe.** Keine Status-Wörter wie "Tu jetzt", "Handelnd: 15", "Zulässige Anzahl gewählter Personen".
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
