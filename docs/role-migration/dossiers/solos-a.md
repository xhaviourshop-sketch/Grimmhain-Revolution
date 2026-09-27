<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G3 Solo-Rollen A · Legacy-Rollenprüfung

Stand: 2026-09-26. Nur-Lese-Prüfung des Repositories `/home/user/Grimmhain-Revolution`. Keine Datei im Repo verändert.

Pfadkürzel wie im Auftrag: `roles`, `chunk`, `ab`, `help`, `night`, `core`, `ui`, `state`, `gh`. Zeilen als `pfad:start-ende`.

Hinweis zu Zitaten: Zwei Originaltexte (Prophet DE/EN) enthalten einen Geviertstrich. Er wird hier als `[U+2014]` wiedergegeben, damit dieses Dokument keine Em-Dashes enthält; sonst ist der Text wörtlich.

## Vorab: Die Siegprüfer (für alle sieben Rollen relevant)

Im Legacy-Code gibt es nicht zwei, sondern fünf Stellen, die `state.once.TeamWinner` für diese Rollengruppe setzen:

| Prüfer | Ort | Auslöser | Guard | Setzt | Betroffene Rollen |
|---|---|---|---|---|---|
| `checkWinConditions` | `core:218-239` | Ende jedes erfolgreichen `applyKill` (`core:212-214`) | `TeamWinner` (`core:222`) | über `triggerWin` (`core:85-100`, selbst ohne Guard) | Doppelspion (`core:227-230`), Dorf/Wölfe |
| `checkTeamWin` | `core:287-337` | jedes `save()` (`state:118`), also auch Chip-Umschalten `gh:429` | `TeamWinner`, `PestWon` (`core:291-292`) | direkt `TeamWinner` + `showWinBanner` | Doppelspion (`core:314-320`), Dorf/Wölfe, Kartenschlucker |
| `checkPestWin` | `core:264-273` | Pest-Handler (`chunk:696`) und Morgenbeginn vor den Nachttoden (`night:333`) | `PestWon`, `TeamWinner` | `solo_Pestbringerin` | Pestbringerin |
| `checkFluteWin` | `core:275-285` | nur Rattenfänger-Handler (`chunk:659,670`) | `TeamWinner` | `solo_Rattenfänger` | Rattenfänger |
| Selbstmörder-Zweig | `night:474-482` in `doLynchFlow` | Lynch | **kein Guard** | `solo_Selbstmörder` | Selbstmörder |

Unterschiede `checkWinConditions` vs. `checkTeamWin` [belegt]:
1. Rollenlose Sitze: `checkWinConditions` zählt lebende Sitze ohne Rolle als Nicht-Wölfe (`core:223-224`), `checkTeamWin` filtert sie aus (`core:297,309-310`). Wolfsparität kann daher je nach Prüfer zu unterschiedlichen Zeitpunkten eintreten.
2. Alle tot: `checkWinConditions` erklärt bei 0 Lebenden Dorf (oder Doppelspion ist dann nicht lebend, also Dorf) zum Sieger (`core:226-231`); `checkTeamWin` bricht ab (`core:299`). DECISION-LOG DR-02 verlangt: kein automatischer Gewinner.
3. `checkTeamWin` prüft erst, wenn mindestens eine Wolfs- und eine Nicht-Wolf-Rolle vergeben sind (`core:302-306`); `checkWinConditions` nicht.
4. Manipulator/Parasit nur in `checkWinConditions`, Kartenschlucker nur in `checkTeamWin`.
5. Weg über den „tot"-Chip (`gh:429`): kein `applyKill`, also nur `checkTeamWin`; `checkFluteWin` und `checkPestWin` laufen dabei nie.
6. Beide Prüfer werten Solo-Rollen als Nicht-Wölfe. Sterben alle Wölfe, gewinnt sofort das Dorf (bzw. der Doppelspion), auch wenn Rattenfänger, Pestbringerin, ein freigeschalteter Prophet, Feuerteufel oder Voodoo-Priester leben. Für Prophet, Feuerteufel, Voodoo-Priester gibt es keinen eigenen Siegcode (`rg` nach `triggerWin(`/`TeamWinner=` ergibt nur die obigen Stellen plus Hades, Kartenschlucker, Todesprediger, Nekromant `gh:552`).
7. Legacy blockiert nach einem Sieg nichts; die React-Hülle blockiert nur Phasenwechsel (`app/src/adapter/legacy/legacyAdapter.ts:477`). Der Selbstmörder-Zweig kann einen bereits gesetzten Sieger überschreiben.

---

### rattenfaenger
- DE-Name / EN-Name: Rattenfänger / Pied Piper (`roles:142`)
- Aliase/Altnamen: `Flötenspieler` → `Rattenfänger` in `migrateLegacyRoleIds` (`state:18`), inklusive Umschreibung eines gespeicherten `TeamWinner` (`state:39-43`, also `solo_Flötenspieler` → `solo_Rattenfänger`). Interner Funktionsname `checkFluteWin`/Variable `flute` (`core:275-280`). Flag `flags.charmed` (Chip `gh:285`, i18n `charmed` `js/core/i18n.js:62,386`). Bilder `assets/cards/de/Rattenfänger.webp`, `assets/cards/en/Pied_Piper.webp` (`gh:815`, `app/src/roleCard.ts:24`). React-Markerschlüssel `enchanted` (`app/src/components/MarkerLegend.tsx:21,42`).
- Legacy-ID: `"Rattenfänger"`
- Fraktion: `solo` (`roles:399-403`, `roles:405-409`). Zählt in beiden Siegprüfern als Nicht-Wolf (`core:224`, `core:310`).
- Akte: Akt I (`js/core/akte.js:22`)
- Nachtpriorität: tier 4.2, nicht `once` (`roles:33`). Keine Sonderbedingung in `rebuildOrder`; Zeile erscheint, solange ein lebender Rattenfänger existiert (`night:57-58,90-94`), auch wenn niemand mehr verzauberbar ist. Blockierbar durch Schattenhund, Zeitwächter-Einfrieren, Der-Weise-Debuff, Albtraum (`ab:94-99`, da nicht in `WOLF_ROLES_SET`).
- Quelltextstellen:
  - `chunk:645-676` `abilities["Rattenfänger"]` - Dialog „1 Ziel / 2 Ziele", dann `startMulti` mit 1 oder 2, setzt `flags.charmed=true`, ruft `checkFluteWin()`.
  - `core:275-285` `checkFluteWin` - erster lebender Rattenfänger; Sieg, wenn alle anderen Lebenden `charmed` sind.
  - `ui:340` `startMulti` - schließt erst ab, wenn genau `max` gültige Sitze gewählt wurden; kein Abbrechen, kein „fertig".
  - `chunk:308` Voodoo-Handler setzt beim Puppenträger `flags.charmed=false`.
  - `night:521` `resetMarksOnly` löscht `charmed`; Wiederbelebung Kutscher `chunk:849`, Hard-Reset `gh:516`.
  - `ab:103-124` Rotkäppchen-Apfel: `wrapMulti` wiederholt die Fähigkeit einmal.
- Text DE (wörtlich): "Du spielst jede Nacht dein Lied und verzauberst 1 oder 2 Spieler. Sobald alle lebenden Spieler in deinem Bann sind, gewinnst du die Runde." (`roles:68`)
- Text EN (wörtlich): "Charms players each night. Wins when all living players are charmed." (`roles:217`)
- DE/EN-Vergleich: NEIN. EN nennt keine Anzahl (DE: 1 oder 2), EN „Wins when" ohne „Sobald"-Betonung (gleichwertig), beide sagen „alle lebenden Spieler" (wörtlich inklusive des Rattenfängers selbst; Code schließt ihn aus).
- Weitere Texte: `js/core/role-abilities.js:74` identisch zu DE. i18n `charmHowMany`, `charmTargets1/2` (`i18n.js:312,321-322,636,645-646`). React-Legende „Vom Rattenfänger verzaubert." (`MarkerLegend.tsx:21`). Kein Totenkarten-Bezug (`rg` in `js/core/cards.js`: 0 Treffer).
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht beim Klick auf die Zeile, Reihenfolge 4.2.
  2. Ziele: SL wählt zuerst 1 oder 2, dann genau so viele lebende, noch nicht verzauberte Sitze (`chunk:657,668`). Selbstwahl erlaubt (Filter schließt den Rattenfänger nicht aus). Tote nicht wählbar.
  3. Mehrfachnutzung: kein Pro-Nacht-Guard; erneuter Klick auf die Zeile erlaubt weitere Verzauberungen. Mit Rotkäppchen-Apfel zweimal.
  4. Wirkung: dauerhaftes `flags.charmed` (wird bei Nachtbeginn nicht gelöscht, `night:145`). Nur SL-sichtbar (Marker ✨ `ui:109`).
  5. Sieg: nur direkt nach einer Verzauberung geprüft. Stirbt der letzte Unverzauberte (Nacht oder Lynch), wird der Sieg nicht erkannt. In der nächsten Nacht bleibt nur der Rattenfänger selbst wählbar (falls er sich nicht schon verzaubert hat); hat er sich schon verzaubert, gibt es keinen gültigen Sitz und `startMulti` kann nie abschließen, der Sieg wird nie erkannt. Bis dahin können `checkWinConditions`/`checkTeamWin` Dorf oder Wölfe gewinnen lassen.
  6. Tod des Rattenfängers: `checkFluteWin` findet keinen lebenden Rattenfänger, kein Sieg. Verzauberungen bleiben bestehen.
  7. Mehrere Kopien: `seats.find` nimmt den ersten lebenden; der zweite Rattenfänger muss selbst verzaubert sein, damit der erste gewinnt. Sieg wird immer als `solo_Rattenfänger` gespeichert.
  8. Zufall: keiner.
  9. Interaktion: Voodoo-Puppe hebt Verzauberung auf (`chunk:308`). Wiederbelebung (Kutscher) setzt Flags zurück. Rollenwechsel (Lehrling, Seelentauscher) übernimmt die global auf Sitzen liegenden Verzauberungen.
- React-Version: kein eigenes Verhalten. Adapter spiegelt `charmed` als Marker (`legacyAdapter.ts:366,393`), ruft Legacy-`startMulti` über einen Beobachtungs-Wrapper (`legacyAdapter.ts:249-282`). Siegerbanner zeigt den rohen DE-Rollennamen auch im EN-Modus (`app/src/screens/GameScreen.tsx:28-29`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-5 „verifiziert", Zeilen `chunk:645-676`, `core:275-285`: Zeilen bestätigt. Status **widerlegt in Teilen**: „Sieg, wenn alle anderen Lebenden verzaubert" gilt nur zum Zeitpunkt einer Verzauberung, nicht nach Toden.
  - 04 D-4 „verifiziert": ebenso eingeschränkt.
  - ROLE-FLOW-REPORT.md:27 (UX-Fluss sauber) bestätigt, sagt nichts zur Siegprüfung.
  - 06-execution-roadmap.md:74 plant die Rolle für Akt I.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Siegzeitpunkt | „Sobald alle lebenden Spieler in deinem Bann sind" | „Wins when all living players are charmed" | nur nach Verzaubern (`chunk:659,670`) | wie Legacy | 04: verifiziert | Prüfung nach jeder Zustandsänderung (Tod, Verzauberung, Wiederbelebung) | nur beim eigenen Zug | A macht Nachttode durch Wölfe zum Vorteil des Rattenfängers | Siegregel in WinRules nach jedem Tod | A | Nein (Bug) |
| Zählt er selbst | „alle lebenden Spieler" | „all living players" | alle außer ihm (`core:280`) | wie Legacy | 04: „alle anderen" | alle außer Rattenfänger | inkl. Rattenfänger (Selbstverzauberung nötig) | B verschwendet eine Verzauberung | Filter | A (Code) + Text präzisieren | Ja |
| Anzahl pro Nacht | 1 oder 2 | keine Zahl | 1 oder 2, beliebig oft pro Nacht per erneutem Klick | wie Legacy | – | genau eine Aktion mit 1-2 Zielen | beliebig | Mehrfachklick bricht Balance | Einmal-pro-Nacht-Schritt | A | Nein |
| Verzauberung durch Puppe aufgehoben | – | – | `chunk:308` setzt `charmed=false` | wie Legacy | nirgends dokumentiert | beabsichtigte Interaktion | Altlast | Voodoo kann Rattenfänger bremsen | eigene Regel nötig | streichen, falls nicht gewollt | Ja |

- Bugs:
  1. Echter Bug · Sieg nach Tod nicht erkannt · `core:275-285` wird nur aus `chunk:659,670` aufgerufen. Tatsächlich: Letzter Unverzauberter stirbt, kein Sieg; ggf. nie erkennbar (leere Zielmenge, `ui:340`). Erwartet laut Text („Sobald"): Sieg sofort. Risiko hoch (häufiger Fall, Wölfe töten gezielt Unverzauberte). Regressionstest: 5 Lebende, 3 verzaubert, 1 unverzaubert + Rattenfänger; Wölfe töten den Unverzauberten → Siegkandidat Rattenfänger am Morgen.
  2. Echter Bug (Bedienung) · `startMulti` ohne Abbruch bei weniger gültigen Zielen als gewählt (`ui:340`), z. B. „2 Ziele" bei nur 1 Unverzaubertem. Tatsächlich: Pick hängt, SL muss anderen Schritt starten. Erwartet: Abbruch oder Begrenzung. Test: 1 gültiges Ziel, Option „2" → Prompt nicht startbar oder abbrechbar.
  3. Technische Altlast · Mehrfachnutzung pro Nacht ohne Guard (`chunk:645-676`). Test: zweite Aktion in derselben Nacht wird abgelehnt.
- Legacy-Status: **legacy-broken**. Die Siegbedingung („Sobald ...") ist die Kernfunktion und wird bei Toden belegbar nicht ausgewertet (Bug 1).
- Automationsvorschlag: automatic. Regeln sind klar, Ziele deterministisch, Sieg als WinCandidate.
- Mechanikfamilie: primär Einzelsieg; sekundär mehrstufige Nachtfähigkeit (Anzahl wählen, dann Ziele).
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (mehrstufig, abbrechbar), WinRules/WinCandidate, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit (gm).
- Benötigte NEUE Systeme: dauerhafte Statusmarker (Verzauberung), zusätzliche Siegbedingungen (Rattenfänger-Kandidat).
- Abhängigkeiten: Voodoo-Priester (hebt Verzauberung auf), Lehrling/Seelentauscher (Rollenwechsel), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (Doppelaktion), Die Ewigen (Solo-Erkennung), Wölfe/Dorf (konkurrierender Sieg).
- Komplexität / Fehlerrisiko: M / mittel. Einfacher Marker, aber Siegzeitpunkt und Konkurrenz mit Parität.
- Offene Entscheidungen: (1) Zählt der Rattenfänger selbst zu „allen lebenden Spielern"? (2) Sieg auch, wenn die Bedingung durch einen Tod eintritt? (3) Genau eine Aktion pro Nacht, 1 oder 2 Ziele, Selbstwahl erlaubt? (4) Gewinnt der Rattenfänger vor dem Dorf, wenn in derselben Auflösung der letzte Wolf und der letzte Unverzauberte sterben (DR-02: SL wählt aus Kandidaten)? (5) Soll die Voodoo-Puppe Verzauberung aufheben?
- Relevante Testgruppen:
  - Normalfall: 4 Lebende, Rattenfänger verzaubert 2, dann 1 → WinCandidate `rattenfaenger`.
  - ungültiges Ziel: bereits verzauberter oder toter Sitz → abgelehnt.
  - tote Person: Rattenfänger tot → kein Schritt, keine Kandidatur trotz vollständiger Verzauberung.
  - Selbstwahl: nach PO-Entscheidung erlaubt/verboten, Test beider Varianten.
  - mehrere Kopien: zwei Rattenfänger, jeder personenbezogener Kandidat; keine Vermischung.
  - Wiederbelebung: verzauberte Person stirbt und wird wiederbelebt → Marker nach PO-Regel (Legacy: gelöscht).
  - Rollenwechsel: Lehrling erbt Rattenfänger → vorhandene Marker gelten weiter?
  - Save/Load: Marker und offener Zwei-Ziel-Prompt überstehen Laden.
  - Replay: gleiche Befehle → gleicher Kandidat.
  - SL-Korrektur: Verzauberung per Korrektur setzen → Siegprüfung angestoßen (Legacy: nicht).
  - Sichtbarkeit: Marker nur gm.
  - Schutz: nicht relevant, weil Verzaubern kein Angriff ist.
  - Todesreaktionen: letzter Unverzauberter ist Sensenträger, Reaktion zuerst, dann Kandidat (DR-14).
  - Siegprüfung: letzter Unverzauberter stirbt nachts → Kandidat; gleichzeitig letzter Wolf tot → zwei Kandidaten.
  - beschädigter Spielstand: `charmed` auf totem Sitz / auf Nicht-Existenz-ID → Laden lehnt ab oder bereinigt.
- Belegsicherheit: hoch. Nicht zur Laufzeit getestet; alle Aussagen aus Code-Lektüre.

### pestbringerin
- DE-Name / EN-Name: Pestbringerin / Plague Bringer (`roles:159`)
- Aliase/Altnamen: i18n-Meldungen nennen sie „Plague Bearer" (`i18n.js:534-535`), abweichend vom Rollennamen. Keine Migrationsalias. Flag `flags.poisoned` (gleicher Flagname wie das allgemeine „vergiftet"-Chip `gh:283`). Bilder `Pestbringerin.webp` / `Plague_Bringer.webp` (`gh:824`, `roleCard.ts:47`). Zustand `once.PestTotal`, `once.PestUsedTonight`, `once.PestWon`. Handler-Meldung spricht von „Tränken" (`i18n.js:205`).
- Legacy-ID: `"Pestbringerin"`
- Fraktion: `solo`; zählt als Nicht-Wolf in beiden Prüfern. `PestWon` sperrt `checkTeamWin` (`core:292`).
- Akte: Akt II (`akte.js:42`)
- Nachtpriorität: tier 7.2, nicht `once` (`roles:49`). Keine Sonderbedingung; Zeile bleibt auch nach Verbrauch beider Einsätze (Handler meldet „Keine Tränke mehr"). Blockaden wie oben (`ab:94-99`).
- Quelltextstellen:
  - `chunk:678-701` Handler - max. 2 Einsätze insgesamt (`PestTotal`), max. 1 pro Nacht (`PestUsedTonight`), Ziel lebend und nicht vergiftet, setzt `poisoned`, ruft `checkPestWin`.
  - `night:157` `onNightStart` setzt `PestUsedTonight=false`.
  - `night:332-333` `resolveDayKills`: `spreadPoison()` und `checkPestWin()` vor den Nachttoden.
  - `core:452-455` `spreadPoison` - jeder lebende Vergiftete infiziert einen zufälligen direkten Sitznachbarn (nur lebende, unvergiftete), `Math.random`.
  - `core:264-273` `checkPestWin` - Sieg, wenn alle Lebenden vergiftet sind; prüft nicht, ob die Pestbringerin lebt.
  - `ab:103-110` Apfel-Reset `PestUsedTonight`.
  - `state:65` Default `PestTotal:0, PestUsedTonight:false`; `gh:522-523,558` Resets.
- Text DE (wörtlich): "Verbreitet jede Nacht eine tödliche Seuche, die sich ausbreitet." (`roles:85`)
- Text EN (wörtlich): "Each night spreads a lethal plague that keeps spreading." (`roles:234`)
- DE/EN-Vergleich: JA, semantisch gleich (jede Nacht, tödlich, breitet sich aus). Beide nennen keine Siegbedingung und keine Begrenzung.
- Weitere Texte: `role-abilities.js:72` identisch DE. i18n „Keine Tränke mehr" / „No more potions" (`i18n.js:205,534`) führt eine Trank-Begrenzung ein, die kein Rollentext nennt. React-Legende: „Vergiftet - stirbt durch das Gift." (`MarkerLegend.tsx:18,39`), falsch für die Pest (Gift tötet nie).
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nacht, Schritt 7.2; Ausbreitung jeden Morgen zu Beginn der Auflösung (`night:332`), auch wenn die Pestbringerin tot oder nicht im Spiel ist. Kein Ausbreiten bei Zeitwächter-Einfrieren (`night:323-331` kehrt vorher zurück).
  2. Ziele: eine lebende, unvergiftete Person; Selbstwahl erlaubt; Tote nicht.
  3. Verbrauch: insgesamt 2 Einsätze pro Partie (global, nicht pro Person), 1 pro Nacht (Apfel erlaubt 2 in einer Nacht).
  4. Wirkung: dauerhaftes `poisoned`; **tötet nie** (kein `applyKill` mit Pest-Ursache, `rg` bestätigt).
  5. Ausbreitung: pro Morgen je Vergiftetem ein zufälliger direkter Nachbar nach Sitzindex (`(id-1±1) mod n`), tote Nachbarn werden nicht übersprungen, sondern verfallen. Neu Infizierte breiten sich erst am nächsten Morgen aus (Liste vorab gebildet).
  6. Sieg: alle Lebenden vergiftet (inklusive der Pestbringerin selbst) → `solo_Pestbringerin`. Geprüft nur beim Handler und am Morgen vor den Toden. Stirbt der letzte Unvergiftete (Nacht oder Lynch), wird das erst am nächsten Morgen nach erneuter Ausbreitung geprüft. Sieg auch, wenn die Pestbringerin tot ist.
  7. Sichtbarkeit: Marker ☣ nur SL; Siegerbanner öffentlich.
  8. Mehrere Kopien: gemeinsamer Zähler und Nacht-Guard, also zusammen 2 Einsätze.
  9. Zufall: `Math.random` in `core:454`.
  10. Interaktion: Schutz irrelevant. Wiederbelebung setzt `poisoned` zurück (`chunk:849`). Rollenwechsel übernimmt verbrauchte globale Einsätze.
- React-Version: kein eigenes Verhalten; spiegelt `poisoned` als Ring/Marker (`legacyAdapter.ts:367,380,391`, `app/src/components/DomBoard.tsx:43,64`). Eigene Legenden-Daten mit falscher Aussage „stirbt durch das Gift".
- Bisherige Doku und Prüfergebnis:
  - 04 A-29 „widersprüchlich", `chunk:678-701`, `core:452-455`, `core:264-273`: Zeilen und Kernaussage („2 Tränke, Gift tötet nie, breitet sich aus, Sieg wenn alle Lebenden vergiftet, auch sie selbst") **bestätigt**. Ergänzt: Sieg auch nach ihrem Tod; Prüfzeitpunkt vor den Nachttoden; Ausbreitung nur direkte Sitznachbarn, zufällig.
  - 04 D-4 zählt Pest zu „verifiziert bzw. wie A": missverständlich, A sagt widersprüchlich.
  - 07 Q1 Teil 1: Vorschlag „Code, Text anpassen". 07 Q1 Kontext „Die Pestbringerin tötet im Code nie": bestätigt.
  - 04 D-8 (Pest und Wolfsparität am selben Morgen): Legacy-Reihenfolge ist deterministisch, Pest-Prüfung vor den Nachttoden, dann `applyKill`-Prüfungen; DECISION-LOG (26.09.2026, Zeile 206, DR-02) ersetzt Prioritäten durch Kandidatenmenge.
  - ROLE-FLOW-REPORT.md:56 („max 2 Tränke, 1/Nacht") bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Tödlichkeit | „tödliche Seuche" | „lethal plague" | tötet nie | Legende: „stirbt durch das Gift" | 04/07: widersprüchlich | Code: Marker ohne Tod, Sieg bei Totalinfektion | Text: Seuche tötet (Zeitpunkt offen) | A ist ein Siegrennen, B eine Tötungsrolle | A einfach; B braucht verzögerte Tode | A (07-Vorschlag), Text anpassen | Ja |
| Häufigkeit | „jede Nacht" | „Each night" | 2 Einsätze insgesamt, 1/Nacht | wie Legacy | 04 bestätigt | Code | Text (jede Nacht neu) | B beschleunigt Sieg stark | Zähler | Code | Ja |
| Siegbedingung | keine | keine | alle Lebenden vergiftet, auch sie selbst, auch wenn sie tot ist | Banner | 04: Sieg wenn alle vergiftet | nur lebend | auch tot | B erlaubt „posthumen" Sieg | Kandidat nur bei lebender Pestbringerin | lebend verlangen | Ja |
| Ausbreitung | „breitet sich aus" | „keeps spreading" | 1 zufälliger direkter Nachbar je Vergiftetem je Morgen | wie Legacy | 04 nennt Ausbreitung | direkte Sitze | nächste lebende Nachbarn | Tote Nachbarn bremsen A | Sitznachbarschaft + SeededRng | PO | Ja |

- Bugs:
  1. Unklare Regel · Sieg ohne lebende Pestbringerin · `core:264-273`. Tatsächlich: `solo_Pestbringerin` auch nach ihrem Tod. Erwartet: kein Text dazu. Risiko mittel. Test: Pestbringerin tot, übrige Lebende alle vergiftet → Kandidat ja/nein nach PO.
  2. Echter Bug · verspätete Prüfung · `checkPestWin` nur `chunk:696`, `night:333`. Tatsächlich: Stirbt der letzte Unvergiftete (Nacht/Lynch), keine Prüfung bis zum nächsten Morgen, Parität kann vorher gewinnen. Erwartet: Prüfung nach jeder Zustandsänderung (DR-14). Risiko mittel. Test: letzter Unvergifteter wird gelyncht → Kandidat Pestbringerin sofort.
  3. Technische Altlast · Ausbreitung läuft auch ohne Pestbringerin im Spiel (`night:332`), betrifft manuell per Chip gesetzte Vergiftungen. Test: Chip „vergiftet" ohne Pestbringerin → keine Ausbreitung.
  4. Technische Altlast · Namenskonflikt „Plague Bearer" vs. „Plague Bringer" (`i18n.js:534` vs. `roles:159`). Content-Lint.
- Legacy-Status: **legacy-contradictory**. Code ist in sich schlüssig und lauffähig, widerspricht aber Rollentext (tötet nie, 2 Einsätze) und React-Legende.
- Automationsvorschlag: automatic, sofern PO die Code-Mechanik bestätigt (Ausbreitung per SeededRng, Sieg als WinCandidate).
- Mechanikfamilie: primär Einzelsieg; sekundär Zufallsmechanik, Sitzpositionsmechanik.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt, SeededRng, WinRules/WinCandidate, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: dauerhafte Statusmarker (Seuche), Sitznachbarschaft (Nachbarberechnung, lebend/direkt), zeitlich verzögerte Effekte (Ausbreitung bei Morgenauflösung), zusätzliche Siegbedingungen; bei Interpretation B zusätzlich verzögerte Tode.
- Abhängigkeiten: Zeitwächter (friert Ausbreitung ein), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (zweiter Einsatz pro Nacht), Die Ewigen, Wolfsparität (konkurrierender Sieg).
- Komplexität / Fehlerrisiko: M / mittel. Zufall und Sitznachbarschaft müssen deterministisch replaybar sein.
- Offene Entscheidungen: (1) Tötet die Seuche (Text) oder nicht (Code)? (2) Einsätze: 2 pro Partie oder jede Nacht? (3) Ausbreitung auf direkte Sitze oder nächste lebende Nachbarn, zufällig oder SL-Wahl? (4) Sieg nur, wenn die Pestbringerin lebt? Muss sie sich selbst infizieren? (5) Einsatzzähler pro Person oder global?
- Relevante Testgruppen:
  - Normalfall: Nacht 1 vergiften A, Morgen: genau ein Nachbar von A infiziert (Seed fix).
  - ungültiges Ziel: bereits vergiftet oder tot → abgelehnt; dritter Einsatz → abgelehnt.
  - tote Person: toter Nachbar wird nicht infiziert; tote Pestbringerin → Schritt entfällt, Ausbreitung nach PO.
  - Selbstwahl: Pestbringerin vergiftet sich → erlaubt (Legacy).
  - mehrere Kopien: zwei Pestbringerinnen, Zähler pro Person oder global nach PO.
  - Wiederbelebung: vergiftete Person wiederbelebt → Marker nach PO (Legacy: gelöscht).
  - Rollenwechsel: Lehrling erbt Pestbringerin → Einsätze frisch (DECISION-LOG Lehrling: „alle begrenzten Einsätze beginnen frisch").
  - Save/Load: Seed, Marker, Zähler überstehen Laden; Ausbreitung danach identisch.
  - Replay: gleiche Seeds → gleiche Infektionen.
  - SL-Korrektur: Marker setzen/entfernen → Siegprüfung.
  - Sichtbarkeit: Marker gm; Ausbreitung nicht öffentlich.
  - Schutz: nicht relevant, weil kein Angriff (sofern PO Code-Variante wählt).
  - Todesreaktionen: nicht relevant in Code-Variante (kein Tod durch Seuche); bei Variante B: Sensenträger stirbt an Seuche → Reaktion.
  - Siegprüfung: letzter Unvergifteter stirbt → Kandidat; gleichzeitig Wolfsparität → zwei Kandidaten.
  - beschädigter Spielstand: `PestTotal` > 2 oder negativ → abgelehnt.
- Belegsicherheit: hoch für Code; Zufallsverteilung nicht zur Laufzeit geprüft.

### prophet-des-untergangs
- DE-Name / EN-Name: Prophet des Untergangs / Prophet of Doom (`roles:160`)
- Aliase/Altnamen: in Prompts nur „Prophet" (`i18n.js:303-304,627-628`, `chunk:802,821`). Nicht zu verwechseln mit „Todesprediger"/„Death Prophet" (i18n-Schlüssel `deathProphet*` gehören zum Todesprediger). SFX `assets/sounds/Prophet 1.mp3`, `Prophet 2.mp3` (Schlüssel `sfxProphet1/2`, `state:101,105`, `gh:2056,2060`; `queueSfxKey` ist No-op). Bilder `Prophet_des_Untergangs.webp` / `Prophet_of_Doom.webp`. Zustand `once.ProphetTargets`, `ProphetUnlocked`, `ProphetDeadCount`, `ProphetKillUsedTonight`, Sitzmarker `meta.unholy` (Marker ☄ `ui:109`).
- Legacy-ID: `"Prophet des Untergangs"`
- Fraktion: `solo`; zählt als Nicht-Wolf in beiden Prüfern.
- Akte: Akt III (`akte.js:64`) und Akt IV (`akte.js:84`).
- Nachtpriorität: tier 8.6, nicht `once` (`roles:56`). Bedingung `night:74-82`: Sind 3 Ziele markiert, nicht freigeschaltet und nicht alle tot, entfällt die Zeile. Vor dem Markieren und nach Freischaltung sichtbar. Blockaden `ab:94-99`.
- Quelltextstellen:
  - `chunk:797-829` Handler - ohne Ziele: `startMulti` genau 3 Lebende (Selbstwahl erlaubt), setzt `meta.unholy`, `ProphetTargets`. Danach: zählt tote Markierte; <3 → Meldung; sonst `ProphetUnlocked=true`, einmal pro Nacht `applyKill(s,"PROPHET_KILL")` sofort mit `postDeathHooks`.
  - `night:74-82` Zeilenbedingung.
  - `night:159` `ProphetKillUsedTonight=false` bei Nachtbeginn.
  - `state:94-110` `save()` zählt tote Markierte, setzt `ProphetUnlocked` bei 3 (Seiteneffekt im Speichern, W12).
  - `gh:2043-2069` `prophetProgressCheck` - liest `window.state`, das nicht existiert (`let state` `gh:371`), also wirkungslos (F8).
  - `ab:109` Apfel-Reset `ProphetKillUsedTonight`.
  - `ui:414` Todesursachen-Label „🔮 Prophet des Untergangs".
- Text DE (wörtlich): "Markiert drei Spieler. Wenn alle tot sind, erhält er die Fähigkeit, jede Nacht zu töten [U+2014] und gewinnt alleine." (`roles:86`)
- Text EN (wörtlich): "Marks three players. When all are dead, gains the ability to kill each night [U+2014] and wins alone." (`roles:235`)
- DE/EN-Vergleich: JA, semantisch gleich (3 Markierungen, Freischaltung bei Tod aller drei, jede Nacht töten, Einzelsieg ohne Bedingung).
- Weitere Texte: `role-abilities.js:73` identisch DE. Keine Totenkarten-Bezüge.
- Legacy-Codeverhalten:
  1. Markieren: beim ersten Aufruf, meist Nacht 1, genau 3 verschiedene lebende Personen, Selbstwahl erlaubt (Filter nur `!dead`), einmalig pro Partie (globaler Zustand).
  2. Freischaltung: sobald alle drei tot sind, egal durch welche Ursache; `ProphetUnlocked` wird durch `save()` oder den Handler gesetzt.
  3. Tötung: jede Nacht 1 Person, lebend, Selbstwahl erlaubt, sofortiger Tod in der Nacht (`PROPHET_KILL`), Todesfolgen und Tod-Popup sofort (`core:401-405`, da nicht `_inNightResolution`). Ignoriert Schutzengel/Dorfwache (die nur im Wolfs-Handler wirken). `applyKill`-Schilde greifen (Nekromant, Kartenschlucker, Hades, Rudelvater einmal, Parasit). Keine Voodoo-Umlenkung, keine Ritter-Vergeltung (`core:431` enthält `PROPHET_KILL` nicht), kein Feuerteufel-Brand.
  4. Wiederbelebung eines Markierten nach Freischaltung: Handler zählt erneut und verweigert die Tötung („Noch 1 unheilig(e) am Leben"), obwohl `ProphetUnlocked` true bleibt und die Zeile sichtbar ist.
  5. Sieg: **nicht implementiert** (`rg` nach `solo_Prophet`/`triggerWin("Prophet`: 0 Treffer). Sterben alle Wölfe, gewinnt das Dorf, auch wenn der Prophet lebt.
  6. Mehrere Kopien: globaler `ProphetTargets`; ein zweiter Prophet markiert nicht selbst und teilt Freischaltung und Nacht-Guard.
  7. Rollenwechsel: `resetOnceForInheritedRole` (`core:339-359`) setzt Prophet-Zustand nicht zurück; Erbe übernimmt Markierungen/Freischaltung.
  8. Zufall: keiner.
  9. Sichtbarkeit: `unholy`-Marker nur SL; Tod öffentlich wie alle Tode.
- React-Version: kein eigenes Verhalten; Marker `unholy` gespiegelt (`legacyAdapter.ts:370`), Legende „Unheilig markiert." (`MarkerLegend.tsx:28`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-30 „fehlend", `chunk:797-829`, `night:74-82`, `state:94-108`: Zeilen bestätigt (Speicherteil reicht bis `state:110`). Kernaussage „Markiert 3; sterben alle → darf jede Nacht töten; Solo-Sieg fehlt" **bestätigt**.
  - 04 B-5 (Prophet freigeschaltet) bestätigt. 04 B-10 (Sofort-Tod) bestätigt.
  - 01 F8 (`prophetProgressCheck` liest `window.state`) bestätigt; Freischaltung funktioniert trotzdem über `state:94-110`.
  - 07 Q4: Sieg fehlt, bestätigt. 07-Vorschlag „Solo vor Wölfen vor Dorf" ist durch DECISION-LOG (Zeile 206, DR-02: Kandidatenmenge ohne Priorität) überholt.
  - NIGHT-REPORT-abilities.md:104 „🟡/❌" ohne Begründung; ROLE-FLOW-REPORT.md:29 nur UX.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Einzelsieg | „gewinnt alleine" | „wins alone" | fehlt; Dorf gewinnt bei 0 Wölfen | wie Legacy | 04/07: fehlend | Sieg als letzter Überlebender (bzw. letzte Nicht-Prophet-Person tot) | Sieg, sobald freigeschaltet und X weitere Tote | Ohne Regel ist die Rolle faktisch Dorf-Hilfe | neue Siegbedingung | PO definieren (07 Q4 B: SL-Siegbutton bis dahin) | Ja |
| Freischaltung dauerhaft | „Wenn alle tot sind, erhält er die Fähigkeit" | „When all are dead, gains the ability" | Handler prüft bei jedem Aufruf neu; Wiederbelebung sperrt wieder | wie Legacy | – | dauerhaft | solange alle tot | selten | Status speichern | dauerhaft | Ja |
| Selbstmarkierung | „drei Spieler" | „three players" | Selbst erlaubt | wie Legacy | – | nur andere | beliebig | Selbstmarkierung macht Freischaltung unmöglich | Filter | nur andere | Ja |

- Bugs:
  1. Unklare Regel (fehlende Mechanik) · kein Einzelsieg · gesamte Codebasis. Tatsächlich: Rolle gewinnt nie. Erwartet laut Text: Einzelsieg. Risiko hoch (Rolle in Akt III und IV). Test: nach PO-Regel.
  2. Echter Bug (klein) · Wiederbelebung sperrt freigeschaltete Tötung · `chunk:812-816` prüft `deadCnt` vor `ProphetUnlocked`. Erwartet laut Text: Fähigkeit „erhalten". Test: freigeschaltet, Markierter wird wiederbelebt → Tötung weiter möglich.
  3. Technische Altlast · `prophetProgressCheck` doppelt und wirkungslos (`gh:2043-2069`), Freischaltung im `save()` (`state:94-110`). Test: Freischaltung nur über Befehlsanwendung, Speichern ändert nichts.
- Legacy-Status: **not-found**. Der Text verspricht einen Einzelsieg, der im Code nicht existiert. Markieren und Töten sind implementiert und funktionieren; der Status bezieht sich auf die fehlende Siegmechanik.
- Automationsvorschlag: assisted. Markieren und Töten automatisch; Sieg mangels Regel als SL-bestätigter Kandidat bzw. „Sieg erklären".
- Mechanikfamilie: primär Tötung; sekundär Einzelsieg, Einmalfähigkeit (Markieren).
- Benötigte vorhandene Godot-Systeme: StepQueue (bedingter Schritt), PendingPrompt, KillPipeline (`PROPHET_KILL`, sofort), Reaktionswarteschlange, WinRules/WinCandidate, GmCorrections (`declare_winner`), StateCodec, Replay, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: dauerhafte Statusmarker (unheilig, Markierungsliste pro Prophet), zusätzliche Siegbedingungen.
- Abhängigkeiten: alle Tötungsrollen (Freischaltung), Kutscher/Frankenstein (Wiederbelebung), Lehrling/Seelentauscher (Erbe des globalen Zustands), Rotkäppchen (zwei Tötungen), Schilde (Nekromant, Hades, Kartenschlucker, Rudelvater), Die Ewigen.
- Komplexität / Fehlerrisiko: M / mittel. Mechanik klar, Sieg undefiniert.
- Offene Entscheidungen: (1) Wann genau gewinnt der Prophet alleine? (2) Darf er sich selbst oder Tote markieren? Markieren nur in Nacht 1? (3) Bleibt die Freischaltung nach Wiederbelebung eines Markierten? (4) Soll die Prophet-Tötung von Schutzengel/Dorfwache geblockt werden? (5) Gewinnt das Dorf, wenn alle Wölfe tot sind, der freigeschaltete Prophet aber lebt?
- Relevante Testgruppen:
  - Normalfall: markiert A,B,C; alle sterben; nächste Nacht Schritt verfügbar, tötet D sofort.
  - ungültiges Ziel: weniger als 3 Markierungen, doppelte Wahl, tote Ziele → abgelehnt.
  - tote Person: Prophet tot → Schritt entfällt.
  - Selbstwahl: Markierung sich selbst / Tötung sich selbst nach PO.
  - mehrere Kopien: zwei Propheten mit getrennten Markierungen (Legacy global).
  - Wiederbelebung: Markierter wird wiederbelebt → Freischaltung bleibt/erlischt nach PO.
  - Rollenwechsel: Lehrling erbt Prophet → Markierungen frisch (DECISION-LOG Lehrling).
  - Save/Load: Markierungen, Freischaltung, Nacht-Guard.
  - Replay: bytegleich.
  - SL-Korrektur: Tod eines Markierten per Korrektur → Freischaltung.
  - Sichtbarkeit: Markierung gm, Tötung öffentlich als Tod.
  - Schutz: Schutzengel schützt Ziel der Prophet-Tötung nach PO (Legacy: nein).
  - Todesreaktionen: Prophet tötet Sensenträger → Reaktion sofort.
  - Siegprüfung: letzter Wolf durch Prophet getötet → Kandidaten Dorf und ggf. Prophet.
  - beschädigter Spielstand: `ProphetTargets` mit 2 Einträgen oder unbekannten IDs → abgelehnt (Legacy würde hängen: `chunk:812-816`).
- Belegsicherheit: hoch; Sieg-Abwesenheit per `rg` über `js/`, `game.html`, `app/src` belegt.

### feuerteufel
- DE-Name / EN-Name: Feuerteufel / Pyromaniac (`roles:172`)
- Aliase/Altnamen: keine Migrationsalias. Flag `flags.burned` (Chip „🔥 gebrannt" `gh:284`, i18n `burned` `i18n.js:61,385`, React „Gebrannt - zum Verbrennen markiert." `MarkerLegend.tsx:22`). Todesursachen `BURN_SPREAD`, `BURN_LYNCH_SPREAD` (Label „🔥 Feuerteufel" `ui:405-406`). Bilder `Feuerteufel.webp` / `Pyromaniac.webp`.
- Legacy-ID: `"Feuerteufel"`
- Fraktion: `solo`; zählt als Nicht-Wolf; kein Siegcode.
- Akte: Akt IV (`akte.js:84`)
- Nachtpriorität: tier 7.6, nicht `once` (`roles:51`). Keine Sonderbedingung. Blockaden `ab:94-99`.
- Quelltextstellen:
  - `chunk:702` Handler - `pick` 1 lebende Person (Selbstwahl erlaubt), setzt `flags.burned=true`. Kein Nacht-Guard.
  - `night:145` `onNightStart` löscht `burned` bei allen; `night:509` `resetNightState`.
  - `night:340-348` in `resolveDayKills.runRest`: für jeden `burned`-Sitz, der in `nightTargets` steht, sterben beide direkten Sitznachbarn (`BURN_SPREAD`), unabhängig davon, ob das Ziel gestorben ist.
  - `night:444-446` in `doLynchFlow`: gelynchtes `burned`-Ziel → beide direkten Nachbarn sterben (`BURN_LYNCH_SPREAD`), außer Nachbarn mit Rolle Feuerteufel; läuft vor den Überlebenszweigen Fenrir/Cerberus/Der Weise/Spiegelwolf.
  - `core:431` Ritter-Vergeltung greift bei `BURN_SPREAD`, nicht bei `BURN_LYNCH_SPREAD`.
- Text DE (wörtlich): "Wählt ein Ziel; beim Tod des Ziels verbrennen auch die Nachbarn." (`roles:98`)
- Text EN (wörtlich): "Chooses a target; when the target dies, neighbors burn as well." (`roles:247`)
- DE/EN-Vergleich: JA, semantisch gleich. Beide ohne Häufigkeit, Dauer, Nachbardefinition, Siegbedingung.
- Weitere Texte: `role-abilities.js:65` identisch DE.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nacht, Schritt 7.6, jede Nacht; Markierung gilt nur für die Auflösung dieser Nacht und den folgenden Tag (Löschung bei nächstem Nachtbeginn).
  2. Ziele: 1 lebende Person, Selbstwahl erlaubt; kein Guard gegen mehrfaches Markieren in einer Nacht.
  3. Auslöser Nacht: nur wenn das markierte Ziel in `nightTargets` (Wolfsopfer inkl. Rachsüchtiger, Schicksalswolf-Extras, Rudelvater-Zusatzopfer) steht und nicht vom Albtraumwolf blockiert ist. Brennt auch, wenn das Ziel überlebt (Der Weise `night:359-364`, Schmied-Waffe `night:381-392`, Nekromant-Umlenkung `night:365-379`, Schilde in `applyKill`). Kein Brand bei Waldhexen-Gift, Prophet-, Hades-, Kartenschlucker-, Blutpriester-Tod, Liebeskummer usw. Kein Brand, wenn Waldhexe rettet, Märtyrerin opfert, Voodoo umlenkt oder Dorfwache filtert (Ziel verlässt `nightTargets`).
  4. Auslöser Lynch: jeder Lynch des markierten Ziels, auch wenn es anschließend überlebt (Fenrir Stufe 3 `night:448`, Cerberus 3 Köpfe `night:449`, Spiegelwolf erste Spiegelung `night:483-495`). Nicht bei Voodoo-Priester mit Puppe (`night:440-443` kehrt vorher zurück) und nicht beim Wahnsinnigen Kutscher (`night:425-438`).
  5. Nachbarn: direkte Sitze nach Index, tote Nachbarn verfallen (kein Weitersuchen). Nacht: kann den Feuerteufel selbst töten. Lynch: Feuerteufel-Nachbarn werden verschont (inkonsistent zur Nacht).
  6. Kette: Verbrannte lösen keinen weiteren Brand aus (nur Ziele aus `nightTargets`).
  7. Mehrere Kopien: `burned` ist sitzbezogen, beliebig viele Markierungen; Lynch schont alle Feuerteufel-Nachbarn.
  8. Todesfolgen: Verbrannte landen in `killedTonight` auch bei überlebendem `applyKill` (F14).
  9. Sieg: nicht vorhanden. Zufall: keiner. Sichtbarkeit: Marker gm; Tode öffentlich.
- React-Version: kein eigenes Verhalten; Marker gespiegelt (`legacyAdapter.ts:368,392`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-42 „fehlend", `chunk:702`, `night:340-348,444-446`: Zeilen bestätigt. „Nachbarn brennen auch, wenn Ziel überlebt (Bug)" **bestätigt** und ergänzt (Lynch-Überlebenszweige, Nekromant-Umlenkung, Schilde). „Solo-Sieg fehlt" bestätigt, aber der Rollentext verspricht **keinen** Sieg; nach 04-Definition („Text verspricht Mechanik") ist „fehlend" daher nicht begründet. Die Lücke liegt in der Fraktionszuordnung (`SOLO_WIN_ROLES` ohne Siegregel).
  - 04 C.2 `BURN_SPREAD night:345`, `BURN_LYNCH_SPREAD night:445` bestätigt.
  - 01 §2 Punkt 2 (Nachbarn per Sitz-ID) bestätigt.
  - 07 Q4 nennt Feuerteufel unter fehlenden Solo-Siegen; bestätigt, dass kein Siegcode existiert.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Auslöser | „beim Tod des Ziels" | „when the target dies" | beim Wolfsangriff bzw. Lynch, auch ohne Tod; nicht bei anderen Todesursachen | wie Legacy | 04: Bug | jeder tatsächliche Tod, jede Ursache | nur Wolfsangriff und Hinrichtung, aber nur bei Tod | A stärker | Todesreaktion in KillPipeline | A oder B, jeweils nur bei Tod | Ja |
| Dauer der Markierung | offen | offen | eine Nacht + folgender Tag | – | – | bis Ziel stirbt | nur diese Nacht | A viel stärker | Statusmarker mit Ablauf | PO | Ja |
| Nachbarn | „die Nachbarn" | „neighbors" | direkte Sitze, Tote verfallen | – | 07 Q1 für Wahnsinnigen Kutscher: „lebende Nachbarn" | direkte Sitze | nächste Lebende | B tötet immer 2 | Sitznachbarschaft | analog Wahnsinniger Kutscher | Ja |
| Feuerteufel als Nachbar | offen | offen | Nacht: stirbt; Lynch: verschont | – | – | immer verschont | nie verschont | – | Filter | einheitlich | Ja |
| Siegbedingung | keine | keine | keine, aber Fraktion solo | – | 04/07: fehlend | Einzelsieg definieren | Fraktion ändern (Dorf-Chaos-Rolle) | – | WinRules | PO | Ja |

- Bugs:
  1. Echter Bug · Brand ohne Tod des Ziels · `night:340-348` (Liste aus `nightTargets`, nicht aus Toten) und `night:444-446` (vor Fenrir/Cerberus/Spiegelwolf). Tatsächlich: Nachbarn sterben, Ziel lebt. Erwartet laut Text: nur „beim Tod des Ziels". Risiko hoch (bis zu 2 falsche Tode). Test: markierter Der Weise wird angegriffen (erster Angriff) → keine Nachbartode.
  2. Echter Bug · kein Brand bei anderen Todesursachen · nur zwei Auslösestellen. Tatsächlich: Ziel stirbt durch Waldhexe/Prophet/Hades → keine Nachbartode. Erwartet laut Text: Brand. Risiko mittel. Test: markiertes Ziel stirbt durch Gift → Nachbarn sterben (nach PO).
  3. Unklare Regel · Feuerteufel verbrennt sich nachts selbst, beim Lynch nicht (`night:345` vs. `night:445`). Test: Feuerteufel sitzt neben markiertem Opfer → einheitliches Ergebnis.
  4. Technische Altlast · `killedTonight.push(nb)` ohne Prüfung des `applyKill`-Ergebnisses (`night:345`, F14). Test: verbrannter Nachbar mit Hades-Barriere zählt nicht als getötet.
- Legacy-Status: **legacy-broken**. Die Kernfunktion „beim Tod des Ziels" wird durch belegte Fehler verfälscht (Brand ohne Tod, kein Brand bei Tod durch andere Ursachen).
- Automationsvorschlag: automatic nach Regelfestlegung; der Brand ist eine deterministische Todesreaktion.
- Mechanikfamilie: primär Todesreaktion; sekundär Sitzpositionsmechanik, Hinrichtungsreaktion.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt, KillPipeline (Kettenschritt), Reaktionswarteschlange, ExecutionRules, WinRules, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Sitznachbarschaft, dauerhafte Statusmarker (Brandmarke mit Ablauf), ggf. zusätzliche Siegbedingungen.
- Abhängigkeiten: Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Albtraumwolf (Blockade), Der Weise, Dorfschmied, Nekromant, Waldhexe, Märtyrerin, Voodoo-Priester, Dorfwache (Überleben/Entfernen aus Zielen), Fenrir, Cerberus, Spiegelwolf, Wahnsinniger Kutscher (Lynch-Zweige), Ritter (Vergeltung bei `BURN_SPREAD`), Seuchenwolf/Rudelvater-Durchschlag.
- Komplexität / Fehlerrisiko: M / hoch. Viele Wechselwirkungen in Nachtauflösung und Hinrichtung.
- Offene Entscheidungen: (1) Brand bei jedem Tod des Ziels oder nur Nacht/Hinrichtung? (2) Wie lange gilt die Markierung? (3) Direkte oder lebende Nachbarn? (4) Stirbt der Feuerteufel, wenn er Nachbar ist? (5) Welche Siegbedingung, oder gehört die Rolle nicht zur Einzelsiegfraktion? (6) Kettenbrand, wenn ein verbrannter Nachbar selbst markiert ist?
- Relevante Testgruppen:
  - Normalfall: markiertes Wolfsopfer stirbt → beide Nachbarn sterben (`BURN_SPREAD`).
  - ungültiges Ziel: totes Ziel → abgelehnt; zweite Markierung in derselben Nacht nach PO.
  - tote Person: toter Nachbar → kein zweites Opfer (bzw. nächster Lebender nach PO).
  - Selbstwahl: Feuerteufel markiert sich und wird angegriffen → Nachbarn sterben.
  - mehrere Kopien: zwei Feuerteufel markieren dasselbe Ziel → Brand genau einmal.
  - Wiederbelebung: verbrannter Nachbar wiederbelebt → Marker nicht übernommen.
  - Rollenwechsel: Feuerteufel wird per Seelentauscher getauscht → bestehende Markierung bleibt/erlischt nach PO.
  - Save/Load: Markierung zwischen Nacht und Morgen gespeichert.
  - Replay: gleiche Reihenfolge der Nachbartode.
  - SL-Korrektur: Tod des Ziels per Korrektur mit Folgen → Brand.
  - Sichtbarkeit: Markierung gm; Tode öffentlich; Ursache privat (DR-04).
  - Schutz: Schutzengel schützt Ziel → kein Brand; Schutzengel schützt Nachbarn → Brand tötet trotzdem (Schutz nur gegen Rudel).
  - Todesreaktionen: verbrannter Ritter → Vergeltung; verbrannter Sensenträger → Reaktion.
  - Siegprüfung: Brand tötet letzten Wolf → Dorfkandidat nach allen Reaktionen.
  - beschädigter Spielstand: Brandmarke auf totem Sitz → bereinigt/abgelehnt.
- Belegsicherheit: hoch für Code-Pfade; nicht zur Laufzeit geprüft.

### voodoo-priester
- DE-Name / EN-Name: Voodoo-Priester / Voodoo Priest (`roles:173`)
- Aliase/Altnamen: Bild-Ausnahme `Voodoo_Priester.webp` (`roles:415`, `gh:811`, `roleCard.ts:16`), EN-Bild `Voodoo_Priest.webp`. Objekt heißt „Puppe" (DE), EN uneinheitlich „doll" (`roles:248`, `i18n.js:467` „Voodoo Doll") und „puppet" (`i18n.js:389,788`, React). Flag `flags.puppet`, Zustand `once.VoodooCooldown`, Ursache `VOODOO_PUPPET`.
- Legacy-ID: `"Voodoo-Priester"`
- Fraktion: `solo`; zählt als Nicht-Wolf; kein Siegcode.
- Akte: Akt II (`akte.js:42`)
- Nachtpriorität: tier 8.4, nicht `once` (`roles:55`). Keine Sonderbedingung; Zeile jede Nacht, auch während Abklingzeit oder bei aktiver Puppe. Blockaden `ab:94-99` betreffen nur das Vergeben, nicht die Umlenkung.
- Quelltextstellen:
  - `chunk:304-309` Handler - Abbruch bei `VoodooCooldown>0` oder lebender Puppe; `pick` 1 lebende Person ohne Puppe (Selbstwahl erlaubt), setzt `puppet=true` und `charmed=false`.
  - `night:233` `onDayStart` verringert `VoodooCooldown` um 1 vor der Auflösung.
  - `night:252-256` Morgen: erster lebender Priester ohne Abklingzeit, der in `nightTargets` steht → lebende Puppe stirbt (`VOODOO_PUPPET`), Priester aus Zielliste entfernt, `VoodooCooldown=2`.
  - `night:339` Puppe unter `killedTonight` → `VoodooCooldown=2`.
  - `night:440-443` Lynch des Priesters ohne Abklingzeit mit lebender Puppe → Puppe stirbt, Priester lebt, `finalizeLynch`.
  - `night:460,499` Lynch der Puppe → `VoodooCooldown=2`.
  - `help:264-273` `witchDeadlyFatePick` - Hexen-Gift auf Priester → Puppe stirbt; `help:265` Hexen-Gift auf Puppe → Abklingzeit.
  - `state:66` Default `VoodooCooldown:0`; `night:523` `resetMarksOnly` löscht `puppet`.
- Text DE (wörtlich): "Gibt einem Spieler eine Voodoo-Puppe. Solange eine Puppe aktiv ist, stirbt bei seinem Tod stattdessen der Puppenträger." (`roles:99`)
- Text EN (wörtlich): "Gives a voodoo doll to a player. If he would die, the doll holder dies instead." (`roles:248`)
- DE/EN-Vergleich: JA mit Nuance. EN „If he would die" macht das Überleben des Priesters ausdrücklich; DE „Solange eine Puppe aktiv ist" fehlt in EN. Keine Unterschiede bei Zeitpunkt, Häufigkeit, Zahlen; beide schweigen zu Abklingzeit, Ursachen und Häufigkeit des Vergebens.
- Weitere Texte: `role-abilities.js:77` identisch DE. i18n `voodooCrafting` „bastelt noch {n} Tag(e)" (`i18n.js:199,528`) beschreibt eine Abklingzeit, die im Rollentext fehlt. React-Legende „Als Puppe kontrolliert." (`MarkerLegend.tsx:23,44`) beschreibt eine Kontrolle, die es nicht gibt.
- Legacy-Codeverhalten:
  1. Vergeben: nachts, jederzeit wenn keine lebende Puppe und keine Abklingzeit; 1 lebende Person, Selbstwahl möglich; hebt Verzauberung des Ziels auf.
  2. Umlenkung nur bei drei Ursachengruppen: Nachtziel der Wölfe (inkl. Rachsüchtiger, Schicksalswolf, Rudelvater-Zusatzopfer) `night:252-256`, Lynch `night:440-443`, Hexen-Gift `help:265`. Keine Umlenkung bei `PROPHET_KILL`, `HADES_KILL`, `KARTENSCHLUCKER_KILL`, `BURN_SPREAD`/`BURN_LYNCH_SPREAD`, `HANGMAN_EXECUTION`, `BLACK_WIDOW`, `GIFTWOLF_DELAY`, `LOVER_HEARTBREAK`, `HUNTER_SHOT`, `BLOODPRIEST_SACRIFICE`, `VERDAMMNISWAECHTER`, `BUSDRIVER_LYNCH`, `SPIEGELWOLF_RETALIATE` usw.
  3. Die Umlenkung geschieht vor Märtyrerin, Der Weise, Schmied, Nekromant; die Puppe stirbt auch dann, wenn der Priester anderweitig überlebt hätte. Schutz der Puppe wirkt nicht (direkter `applyKill`); `applyKill`-Schilde der Puppe greifen (dann überlebt die Puppe, Priester trotzdem gerettet, Abklingzeit trotzdem gesetzt).
  4. Abklingzeit: 2, Abzug jeden Morgen; blockiert Umlenkung und Neuvergabe zwei Nächte lang. Auch gesetzt, wenn die Puppe normal stirbt (Nacht, Lynch, Hexe) oder nur in `killedTonight` steht (F14).
  5. Mehrere Kopien: global nur eine lebende Puppe; Nachtumlenkung nur für den ersten gefundenen Priester (`night:252`); Lynch/Hexe für jeden Priester.
  6. Selbst als Puppe: Nachtangriff tötet ihn mit Ursache `VOODOO_PUPPET` statt `NIGHT_KILL`.
  7. Sieg: nicht vorhanden. Zufall: keiner. Sichtbarkeit: Puppe gm-Marker 🧸; Tod der Puppe öffentlich mit Ursache „starb als Voodoo-Puppe" im Log.
- React-Version: kein eigenes Verhalten; Marker gespiegelt (`legacyAdapter.ts:369,396`); eigene, sachlich falsche Legendentexte.
- Bisherige Doku und Prüfergebnis:
  - 04 A-43 „fehlend", `chunk:304-309`, `night:252-256,440-443`: Zeilen bestätigt. „Puppe stirbt statt Priester (Nacht, Lynch, Hexe); 2 Tage Abklingzeit" **bestätigt**. „Solo-Sieg fehlt" bestätigt, aber der Text verspricht keinen Sieg; „fehlend" nach 04-Definition daher nicht begründet.
  - 04 C.1 „unklar (welche Ursachen?)": **beantwortet** (siehe Punkt 2 oben).
  - GRIMMHAIN_ANALYSE_2026-06-12.md:156,169: „Direkt-Button ohne Voodoo-Redirect" ist **veraltet**; beide Hexen-Wege nutzen `witchDeadlyFatePick` (`chunk:219`, `help:269`).
  - 03-godot-architecture.md:225 ordnet Voodoo als Umlenkung ein; passt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ursachen der Umlenkung | „bei seinem Tod" | „If he would die" | nur Wolfsnachtziel, Lynch, Hexen-Gift | wie Legacy | 04: unklar | jede Todesursache | nur Angriffe (Wolf, Hinrichtung, Gift) | A macht ihn sehr robust | Umlenkungsregel mit Ursachenfilter in KillPipeline | PO | Ja |
| Abklingzeit | keine | keine | 2 Tage, auch nach normalem Puppentod | wie Legacy | 04 bestätigt | Code übernehmen, Text ergänzen | keine Abklingzeit | ohne Abklingzeit endloser Schutz | Zähler | Code | Ja |
| Verzauberung löschen | – | – | `charmed=false` beim Vergeben | – | – | Altlast | gewollt | Rattenfänger-Konter | – | streichen | Ja |
| Siegbedingung | keine | keine | keine, Fraktion solo | – | 04/07: fehlend | Einzelsieg definieren | Fraktion ändern | – | WinRules | PO | Ja |
| Bezeichnung | Puppe | doll | – | „puppet", „kontrolliert" | – | – | – | – | Content | einheitlich „doll", Legende korrigieren | Nein |

- Bugs:
  1. Echter Bug · Hexen-Gift wird nicht verbraucht, wenn es auf den Priester umgelenkt wird · `help:265`: Umlenkungszweig kehrt vor `state.once.WaldhexeD=true` zurück. Erwartet: Gift verbraucht. Risiko mittel (Waldhexe kann erneut vergiften). Test: Hexe vergiftet Priester mit Puppe → Puppe tot, Gifttrank verbraucht.
  2. Echter Bug · Mehrere Priester: Nachtumlenkung nur für den ersten gefundenen (`night:252`). Test: zwei Priester, zweiter angegriffen, Puppe lebt → Umlenkung.
  3. Technische Altlast · Abklingzeit auch, wenn die Puppe überlebt (`night:339` mit F14). Test: Puppe mit Schild angegriffen, überlebt → keine Abklingzeit.
  4. Unklare Regel · Umlenkung nur bei drei Ursachen (siehe Tabelle).
- Legacy-Status: **legacy-contradictory**. Die Umlenkung funktioniert für die Hauptursachen, widerspricht aber dem allgemeinen Text („bei seinem Tod") und enthält eine undokumentierte Abklingzeit; die belegten Bugs betreffen Nebenpfade.
- Automationsvorschlag: automatic. Umlenkung ist eine deterministische Abfangregel in der KillPipeline, sobald der Ursachenfilter feststeht.
- Mechanikfamilie: primär Zielumleitung; sekundär Verknüpfte Personen, Hinrichtungsreaktion.
- Benötigte vorhandene Godot-Systeme: KillPipeline (Abfangregel/Umlenkung), ExecutionRules (Hinrichtungsumlenkung, analog Spiegelwolf-Umlenkung), StepQueue, PendingPrompt, Protections (Abgrenzung), StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Liebes-/Bindungsmodell (Priester-Puppe-Bindung), dauerhafte Statusmarker (Puppe), zeitlich verzögerte Effekte (Abklingzeit), ggf. zusätzliche Siegbedingungen.
- Abhängigkeiten: Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Waldhexe (Gift), Märtyrerin, Der Weise, Dorfschmied, Nekromant (Reihenfolge der Abfangregeln), Rattenfänger (Verzauberung), Feuerteufel (Brand entfällt bei Umlenkung), Hades/Kartenschlucker/Nekromant/Rudelvater (Schilde der Puppe), Henker.
- Komplexität / Fehlerrisiko: L / hoch. Abfangreihenfolge, Ursachenfilter, Abklingzeit und Hinrichtungspfad.
- Offene Entscheidungen: (1) Welche Todesursachen lenkt die Puppe um? (2) Abklingzeit übernehmen, wie lang, auch nach normalem Tod der Puppe? (3) Darf der Priester sich selbst die Puppe geben? (4) Verliert der Puppenträger Verzauberung? (5) Weiß der Puppenträger von der Puppe? (6) Siegbedingung oder Fraktionswechsel? (7) Umlenkung vor oder nach Märtyrerin/Der Weise/Schmied?
- Relevante Testgruppen:
  - Normalfall: Wölfe greifen Priester an, Puppe lebt → Puppe stirbt (`VOODOO_PUPPET`), Priester lebt, Abklingzeit 2.
  - ungültiges Ziel: tote Person, bereits Puppe → abgelehnt; Vergabe während Abklingzeit → abgelehnt.
  - tote Person: Puppe tot → keine Umlenkung; Priester tot → Schritt entfällt, Puppe verliert Wirkung.
  - Selbstwahl: Priester ist eigene Puppe → Angriff tötet ihn (Legacy) bzw. nach PO verboten.
  - mehrere Kopien: zwei Priester, je eigene Puppe (Legacy: nur eine global).
  - Wiederbelebung: Puppe wiederbelebt → Marker gelöscht.
  - Rollenwechsel: Priester getauscht → Bindung erlischt/übergeht nach PO.
  - Save/Load: Abklingzeit zwischen Tag und Nacht.
  - Replay: Umlenkungsereignis in gleicher Reihenfolge.
  - SL-Korrektur: Hinrichtung des Priesters per Korrektur → Umlenkung (DECISION-LOG: Ursache bleibt LYNCH).
  - Sichtbarkeit: Puppe gm; Tod der Puppe öffentlich, Ursache privat (DR-04).
  - Schutz: Schutzengel schützt Priester → keine Umlenkung nötig, Puppe lebt; Schutz auf Puppe verhindert Umlenkungstod nicht (Legacy).
  - Todesreaktionen: Puppe ist Sensenträger → Reaktion nach Umlenkungstod.
  - Siegprüfung: Puppe ist letzter Wolf → Dorfkandidat.
  - beschädigter Spielstand: zwei lebende Puppen, negative Abklingzeit → abgelehnt.
- Belegsicherheit: hoch; Ursachenliste per `rg "VOODOO_PUPPET"` vollständig (`night:255,442`, `help:265`, `gh:2426`, `ui:407`).

### selbstmoerder
- DE-Name / EN-Name: Selbstmörder / Death Seeker (`roles:179`)
- Aliase/Altnamen: keine Migrationsalias. SFX `sfxSuicide` (`night:475`, No-op), Datei `assets/sounds/Selbstmörder.mp3`. Bilder `Selbstmörder.webp` / `Death_Seeker.webp`. Gespeicherter Sieger `solo_Selbstmörder`.
- Legacy-ID: `"Selbstmörder"`
- Fraktion: `solo`; zählt als Nicht-Wolf.
- Akte: Akt I (`akte.js:22`)
- Nachtpriorität: kein Eintrag in `ORDER_BASE`; zusätzlich im `passive`-Set (`night:96`), das für ihn wirkungslos ist.
- Quelltextstellen:
  - `night:421-423` `doLynchFlow` - `deadBefore` = Anzahl toter Sitze vor dem Lynch.
  - `night:474-482` Zweig: Rolle Selbstmörder und `deadBefore>=5` → `TeamWinner="solo_Selbstmörder"` (ohne Guard), `applyKill(target,"LYNCH")`, `finalizeLynch`, Banner.
  - `night:444-446` Brand-Zweig läuft vorher.
- Text DE (wörtlich): "Gewinnt, sobald 5+ Tote sind und er am Tage gelyncht wird." (`roles:105`)
- Text EN (wörtlich): "Wins if lynched when >=5 players are already dead." (`roles:254`)
- DE/EN-Vergleich: NEIN (feiner Unterschied). EN „already dead" legt fest, dass 5 Tote vor dem Lynch zählen; DE „sobald 5+ Tote sind" ist mehrdeutig (zählt sein eigener Tod mit?). EN lässt „am Tage" weg (Lynch ist ohnehin Tagesaktion). Code = EN-Lesart.
- Weitere Texte: `role-abilities.js:75` „Gewinnt sobald ..." (ohne Komma), sonst gleich.
- Legacy-Codeverhalten:
  1. Zeitpunkt: nur beim Lynch über `doLynchFlow` am Tag.
  2. Bedingung: mindestens 5 tote Sitze vor dem Lynch (alle Sitze, auch rollenlose).
  3. Wirkung: Sieg, Tod mit `LYNCH`, LynchCount und Henker-Markierungen laufen.
  4. Kein Sieg bei anderen Todesarten (Nacht, `HANGMAN_EXECUTION`, `BUSDRIVER_LYNCH`, Hexe usw.) und bei <5 Toten (normaler Lynch).
  5. Kein Guard: überschreibt einen bereits gesetzten Sieger. Ist er `burned`, töten die Brand-Nachbarn (`night:444-446`) vorher per `applyKill`; `checkWinConditions` kann dabei Dorf/Wölfe setzen, danach überschreibt der Selbstmörder-Zweig (zwei Banner).
  6. Puppe: Selbstmörder-Zweig setzt bei `flags.puppet` keine Voodoo-Abklingzeit (Standardzweig `night:499` schon).
  7. Mehrere Kopien: jeder gelynchte Selbstmörder gewinnt unter demselben Schlüssel.
  8. Zufall: keiner. Sichtbarkeit: Banner öffentlich.
- React-Version: kein eigenes Verhalten; Lynch über Legacy-`doLynchFlow` (`legacyAdapter.ts:683-685`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-49 „verifiziert", `night:474-482`: **bestätigt**. Ergänzt: fehlender Guard, Wechselwirkung mit Brand-Zweig.
  - 04 D-4 bestätigt. GRIMMHAIN_ANALYSE_2026-06-12.md:207 (Tippfehler „Gelyncht") ist behoben (`roles:105`).
  - 06-execution-roadmap.md:74 plant ihn für Akt I.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Zählbasis | „sobald 5+ Tote sind" | „>=5 players are already dead" | 5 Tote vor dem Lynch | wie Legacy | 04: „vorher ≥ 5 Tote" | vorher (Code/EN) | inklusive eigenem Tod | B einen Tod früher | Zählpunkt | A, DE-Text präzisieren | Ja |
| Hinrichtungsarten | „gelyncht" | „lynched" | nur Lynch-Ziel | wie Legacy | – | nur Hauptziel des Lynchs | auch Henker-Hinrichtung | – | ExecutionRules | A | Ja |

- Bugs:
  1. Echter Bug · fehlender Guard / Überschreiben · `night:476` setzt `TeamWinner` ohne Prüfung. Tatsächlich: bereits entschiedener Sieg wird überschrieben (z. B. nach Brand-Nachbartod des letzten Wolfs). Erwartet (DR-02/DR-14): Kandidatenmenge, SL wählt. Risiko mittel. Test: gebrannter Selbstmörder, Nachbar ist letzter Wolf, 5 Tote → Kandidaten Dorf und Selbstmörder.
  2. Technische Altlast · keine Voodoo-Abklingzeit, wenn der Selbstmörder Puppe ist (`night:474-482` vs. `night:499`). Test nach PO.
- Legacy-Status: **legacy-verified**. Code setzt den Text (EN-Lesart) nachvollziehbar um; die Bugs betreffen nur Randfälle der Sieger-Konkurrenz.
- Automationsvorschlag: automatic.
- Mechanikfamilie: primär Einzelsieg; sekundär Hinrichtungsreaktion.
- Benötigte vorhandene Godot-Systeme: ExecutionRules, KillPipeline (`LYNCH`), WinRules/WinCandidate, Nominations, GmCorrections (`execute`), StateCodec, Replay.
- Benötigte NEUE Systeme: zusätzliche Siegbedingungen (Selbstmörder-Kandidat bei Hinrichtung); sonst keine.
- Abhängigkeiten: Feuerteufel (Brand vor Siegprüfung), Henker (Nebenhinrichtung), Voodoo (Puppe), alle Tötungsrollen (Totenzahl), Die Ewigen.
- Komplexität / Fehlerrisiko: S / niedrig.
- Offene Entscheidungen: (1) Zählt „5+ Tote" vor oder nach seinem Tod? (2) Zählt nur „LYNCH" oder auch Henker/SL-Hinrichtung (DECISION-LOG: SL-Hinrichtung ist `LYNCH`)? (3) Zählen wiederbelebte Personen als Tote (Legacy: nur aktueller Status)?
- Relevante Testgruppen:
  - Normalfall: 5 Tote, Selbstmörder hingerichtet → Kandidat `selbstmoerder`.
  - ungültiges Ziel: 4 Tote → normaler Tod, kein Kandidat.
  - tote Person: nicht relevant, weil tote Personen nicht hingerichtet werden können.
  - Selbstwahl: nicht relevant, weil keine aktive Fähigkeit.
  - mehrere Kopien: zwei Selbstmörder, der gehängte ist Kandidat.
  - Wiederbelebung: 5 Tote, einer wiederbelebt → 4 → kein Sieg.
  - Rollenwechsel: Lehrling erbt Selbstmörder → Sieg bei Hinrichtung.
  - Save/Load: nicht relevant, weil kein Zustand außer Totenzahl; Test nur Siegstatus nach Laden.
  - Replay: Hinrichtung erzeugt gleichen Kandidaten.
  - SL-Korrektur: `execute` ohne Nominierung → Kandidat (Ursache `LYNCH`).
  - Sichtbarkeit: Sieg öffentlich erst nach SL-Bestätigung.
  - Schutz: nicht relevant, weil Schutz nur gegen Rudel.
  - Todesreaktionen: Selbstmörder ist Liebender → Liebeskummer-Tod vor Bestätigung.
  - Siegprüfung: gleichzeitig Parität/Dorf → mehrere Kandidaten.
  - beschädigter Spielstand: nicht relevant, weil kein rollenspezifischer Zustand.
- Belegsicherheit: hoch.

### doppelspion
- DE-Name / EN-Name: Doppelspion / Double Agent (`roles:205`)
- Aliase/Altnamen: keine Migrationsalias. EN-Kartenbild heißt `Doppelspion.webp` (kein englisches Bild, `gh:841`, `roleCard.ts:86`). EN-Rollentext nennt den Rachsüchtigen Wolf „Revenge Wolf", dessen EN-Name ist aber „Lone Wolf" (`roles:150`).
- Legacy-ID: `"Doppelspion"`
- Fraktion: `solo` (`roles:402`). `isWolf` gibt immer `false` zurück, auch bei `flags.werewolf` oder `cursedWolfAura` (`core:13`). Zählt in der Parität als Nicht-Wolf. Für Orakel zeigt er seine echte Rolle (`chunk:238-251`). Doktor/Spürhund/Chronistin/Ewige behandeln ihn als Solo.
- Akte: Akt III (`akte.js:63`)
- Nachtpriorität: kein Eintrag in `ORDER_BASE`; im wirkungslosen `passive`-Set (`night:96`). Wird im Werwolf-Schritt nicht als Akteur geführt (`ab:73-76` nur `WOLF_ROLES_SET` oder `flags.werewolf`).
- Quelltextstellen:
  - `core:13` `isWolf` - nie Wolf.
  - `core:227-230` `checkWinConditions` - keine lebenden Wölfe und lebender Doppelspion → `triggerWin("Doppelspion")`.
  - `core:314-320` `checkTeamWin` - gleiche Regel mit Filtern (rollenlose Sitze, vergebene Wolfsrolle).
  - `chunk:325,359` Rachsüchtiger Wolf schließt ihn aus der Zielliste aus (redundant, da Ziele `isWolf` erfüllen müssen).
  - `core:152` Detektiv-Hinweis nicht bei ihm (redundant).
- Text DE (wörtlich): "Wacht gemeinsam mit den Werwölfen auf. Gewinnt alleine, wenn alle Werwölfe tot sind. Der Angriff des Rachsüchtigen Wolfs verpufft an ihm." (`roles:131`)
- Text EN (wörtlich): "Wakes up together with the werewolves. Wins alone when all werewolves are dead. The Revenge Wolf's attack has no effect on him." (`roles:281`)
- DE/EN-Vergleich: JA, semantisch gleich. Nur Namensabweichung „Revenge Wolf" statt EN-Rollenname „Lone Wolf".
- Weitere Texte: `role-abilities.js:64` identisch DE.
- Legacy-Codeverhalten:
  1. Aufwachen mit den Wölfen: keine App-Unterstützung (kein Schritt, kein Hinweis im Werwolf-Schritt); reine Tischanweisung für den SL.
  2. Sieg: wenn kein Wolf lebt (`isWolf`: Wolfsrollen, `flags.werewolf`, `cursedWolfAura`) und er lebt → er statt Dorf. Ist er tot, gewinnt das Dorf. Geprüft nach jedem `applyKill` und jedem `save()`.
  3. Rachsüchtiger Wolf: kann ihn nicht wählen (Zielliste), Wirkung „verpufft" damit gleichwertig. Normales Rudel kann ihn töten.
  4. Parität: zählt gegen die Wölfe; Wölfe gewinnen bei Wolfsstärke ≥ Nicht-Wölfe inkl. Doppelspion.
  5. Dämonischer Fluch: `cursedWolfAura` auf ihm bleibt wirkungslos (`core:13` vor Auswertung).
  6. Mehrere Kopien: erster lebender wird Sieger, Schlüssel `solo_Doppelspion`.
  7. Zufall: keiner. Sichtbarkeit: Banner öffentlich.
- React-Version: kein eigenes Verhalten; Fraktion über `getRoleFaction` (`legacyAdapter.ts:288-290`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-68 „verifiziert", `core:13,227-229,314-319`: Zeilen bestätigt (`core:227-230`, `core:314-320`). Kernaussage **bestätigt**. Ergänzt: Aufwachen mit Wölfen ohne App-Unterstützung; Parität zählt ihn gegen die Wölfe.
  - 04 D-1 bestätigt. NIGHT-REPORT-abilities.md:108 „passiv (wacht mit Rudel)" bestätigt, dass es nur Tischregel ist.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Muss er leben? | „wenn alle Werwölfe tot sind" | „when all werewolves are dead" | nur lebend | wie Legacy | 04: „wenn er lebt" | nur lebend (Code) | auch tot | B macht ihn stärker | WinCandidate | A, Text präzisieren | Ja |
| Parität | – | – | zählt als Nicht-Wolf | – | 04 D-2: Solos zählen als Nicht-Wölfe | Nicht-Wolf | neutral (zählt für keine Seite) | A lässt Wölfe schwerer gewinnen | `counts_as_wolf=false` | A | Ja |
| Aufwachen | „Wacht gemeinsam mit den Werwölfen auf" | „Wakes up together with the werewolves" | kein App-Schritt | – | – | Hinweis im Rudelschritt | reine Tischregel | – | StepQueue-Hinweis | A | Nein |

- Bugs: keine echten Bugs belegt. Technische Altlast: redundante Doppelspion-Ausschlüsse (`chunk:325,359`, `core:152`); Namensabweichung „Revenge Wolf" (Content-Lint).
- Legacy-Status: **legacy-verified**. Sieg und Immunität gegen den Rachsüchtigen Wolf sind nachvollziehbar umgesetzt; das Aufwachen ist eine Tischregel ohne Codebedarf.
- Automationsvorschlag: automatic (Sieg und Wolfsstatus); Aufwachen als Hinweis im Rudelschritt.
- Mechanikfamilie: primär Einzelsieg; sekundär Wolfsangriff-Modifikation.
- Benötigte vorhandene Godot-Systeme: WinRules/WinCandidate, StepQueue (Hinweis im Rudelschritt), appears_as (falls er dem Orakel als Wolf erscheinen soll; Legacy: nein), Ereignis-Sichtbarkeit, StateCodec, Replay.
- Benötigte NEUE Systeme: zusätzliche Siegbedingungen (Doppelspion ersetzt Dorfsieg); Immunität gegen Rachsüchtigen Wolf als Zielfilter.
- Abhängigkeiten: Rachsüchtiger Wolf, Dämonischer Wolf (Fluch wirkungslos), Wolfskind/Lehrling (Wolfszählung), Orakel/Doktor/Spürhund (Erscheinung/Fraktion), Die Ewigen, Dorfchronistin.
- Komplexität / Fehlerrisiko: S / mittel. Einfach, aber Siegkonkurrenz mit Dorf und Paritätsfrage.
- Offene Entscheidungen: (1) Muss er für den Sieg leben? (2) Zählt er in der Parität als Nicht-Wolf? (3) Erscheint er dem Orakel als Wolf oder Doppelspion? (4) Darf das normale Rudel ihn angreifen? (5) Gewinnt das Dorf mit, wenn er gewinnt?
- Relevante Testgruppen:
  - Normalfall: letzter Wolf stirbt, Doppelspion lebt → Kandidat `doppelspion` statt Dorf.
  - ungültiges Ziel: Rachsüchtiger Wolf kann ihn nicht wählen.
  - tote Person: Doppelspion tot, letzter Wolf stirbt → Dorf.
  - Selbstwahl: nicht relevant, weil keine aktive Fähigkeit.
  - mehrere Kopien: zwei Doppelspione, personenbezogene Kandidaten.
  - Wiederbelebung: Doppelspion wiederbelebt nach Wolfstod → Siegprüfung erneut.
  - Rollenwechsel: Lehrling erbt Doppelspion; Wolfskind-Verwandlung verhindert Doppelspion-Sieg.
  - Save/Load: Siegkandidat überlebt Laden.
  - Replay: gleicher Kandidat.
  - SL-Korrektur: `set_role` zu Doppelspion → Siegprüfung.
  - Sichtbarkeit: Hinweis im Rudelschritt nur gm.
  - Schutz: nicht relevant, weil keine Schutzmechanik.
  - Todesreaktionen: letzter Wolf ist Sensenträger-Ziel → Reaktion, dann Kandidat.
  - Siegprüfung: Parität mit Doppelspion als Nicht-Wolf.
  - beschädigter Spielstand: Doppelspion mit `counts_as_wolf=true` → abgelehnt.
- Belegsicherheit: hoch.

---

## Gruppenübergreifende Beobachtungen

1. **Fünf Siegstellen statt zwei.** Für diese Gruppe setzen `checkWinConditions`, `checkTeamWin`, `checkPestWin`, `checkFluteWin` und der Selbstmörder-Zweig den Sieger. Nur die ersten beiden laufen nach jedem Tod bzw. Speichern; Pest und Rattenfänger werden nur beim eigenen Zug (Pest zusätzlich am Morgen vor den Toden) geprüft, der Selbstmörder überschreibt ohne Guard. 04 D-6 und 01 F7 sprechen nur von zwei Prüfern; die Solo-Prüfer sollten dort ergänzt werden.
2. **Solo-Rollen zählen im Legacy als Dorfseite.** Beide Hauptprüfer werten alle Solos als Nicht-Wölfe; sterben alle Wölfe, gewinnt das Dorf sofort, auch wenn Rattenfänger, Pestbringerin, ein freigeschalteter Prophet, Feuerteufel oder Voodoo-Priester leben. Nur der Doppelspion ersetzt den Dorfsieg.
3. **„fehlend" in 04 ist für Feuerteufel und Voodoo-Priester nicht textbegründet.** Ihre Rollentexte nennen keinen Sieg; die Lücke entsteht allein durch die Mitgliedschaft in `SOLO_WIN_ROLES`. Auch der Pest-Text nennt keinen Sieg (Code hat einen). Nur beim Propheten verspricht der Text einen Einzelsieg. Q4 sollte zwischen „Text verspricht Sieg" (Prophet) und „Fraktion solo ohne Siegtext" (Feuerteufel, Voodoo) unterscheiden.
4. **Rattenfänger ist in 04 zu Unrecht „verifiziert".** Der Sieg wird nach Toden nicht erkannt (`checkFluteWin` nur aus dem Handler).
5. **Priorität:** 07 Q4 schlägt „Solo vor Wölfen vor Dorf" vor; DECISION-LOG (26.09.2026, Zeile 206 und DR-02/DR-14) hat stattdessen eine Kandidatenmenge ohne Priorität mit SL-Bestätigung festgelegt. Der Vorschlag in 07 ist damit überholt. Godot-Konsequenz: jede Solo-Bedingung dieser Gruppe als WinCandidate nach jeder relevanten Zustandsänderung, nicht nur nach eigenen Aktionen.
6. **Gemeinsamer Bedarf „dauerhafte Statusmarker"**: `charmed`, `poisoned`, `burned`, `puppet`, `unholy` sind heute lose Sitz-Flags; Wiederbelebung (Kutscher `chunk:849`) löscht alle, der Voodoo-Handler löscht `charmed`. Ein gemeinsames Markermodell mit Eigentümer, Ablauf und Wiederbelebungsregel würde fünf Rollen abdecken.
7. **Gemeinsamer Bedarf „Sitznachbarschaft"**: Feuerteufel und Pestbringerin nutzen direkte Sitzindizes, tote Nachbarn verfallen. 07 Q1 schlägt beim Wahnsinnigen Kutscher „lebende Nachbarn" vor; eine einheitliche Nachbarregel ist sinnvoll.
8. **Globale statt personenbezogene Zustände**: `PestTotal`, `PestUsedTonight`, `ProphetTargets`, `ProphetUnlocked`, `ProphetKillUsedTonight`, `VoodooCooldown`, eine einzige Puppe. Mehrere Kopien und Rollenerbe (Lehrling) verhalten sich dadurch falsch; `resetOnceForInheritedRole` (`core:339-359`) setzt keinen dieser Zustände zurück.
9. **`killedTonight` mit Überlebenden (F14)** wirkt auch hier: Voodoo-Abklingzeit (`night:339`) und Brand-Nachbarn (`night:345`).
10. **Chip-Weg (`gh:429`)**: Setzen von `dead`, `charmed`, `poisoned`, `puppet` per Chip umgeht `applyKill` und alle Solo-Prüfer; nur `checkTeamWin` läuft.
11. **Zufall**: Einzige `Math.random`-Stelle dieser Gruppe ist `spreadPoison` (`core:454`). Totenkarten-Ziehung beim Tod (`js/core/cards.js:667` für Solos) ist rollenübergreifend.
12. **React-Hülle** hat für keine dieser Rollen eigenes Regelverhalten, aber eigene fehlerhafte Legendentexte (`MarkerLegend.tsx`: Gift „stirbt durch das Gift", Puppe „kontrolliert") und zeigt Solo-Sieger mit rohem DE-Rollennamen (`GameScreen.tsx:28-29`).
13. **Übersetzungs-Uneinheitlichkeiten**: „Plague Bearer" vs. „Plague Bringer", „doll" vs. „puppet", „Revenge Wolf" vs. „Lone Wolf", fehlendes EN-Kartenbild für den Doppelspion, EN-Rattenfängertext ohne Zielanzahl.
14. **Veraltete Aussage in GRIMMHAIN_ANALYSE_2026-06-12.md:156-170** (Hexen-Direktbutton ohne Voodoo) ist behoben; dafür neuer Bug: Hexen-Gift wird bei Voodoo-Umlenkung nicht verbraucht (`help:265`).
