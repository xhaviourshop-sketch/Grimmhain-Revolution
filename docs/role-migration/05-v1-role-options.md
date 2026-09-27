# 05 · Optionen für den Rollenumfang von Version 1.0

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · **Status:** Vorschlag, Product-Owner-Entscheidung offen

Alle Optionen enthalten die 11 umgesetzten Rollen. Die Optionen bauen aufeinander auf (A ⊂ B ⊂ C), damit eine spätere Erweiterung keine Arbeit verwirft. Entscheidungs-IDs verweisen auf [`08`](08-decision-request.md), Chargen auf [`06`](06-implementation-batches.md).

## 1. Auswahlkriterien

In dieser Reihenfolge gewichtet, wie im Auftrag gefordert:

1. **Klare Regeln:** Legacy-Befund `legacy-verified` oder ein Widerspruch, den eine Querschnittsentscheidung auflöst. Rollen mit `not-found` oder fehlender Siegbedingung sind ausgeschlossen.
2. **Spielleiterfreundlichkeit und geringe Fehlbedienung:** wenige Eingaben, keine Tischfragen mit Freitext, keine Nachtrücknahme.
3. **Testbarkeit:** deterministisch oder über `SeededRng`, kein Totenkarten-Bezug, keine Stimmen.
4. **Wenige neue Grundsysteme je Schritt:** jedes neue System soll mindestens eine weitere Rolle tragen.
5. **Mechanikvielfalt und Fraktionsbalance:** Dorf, Wölfe und Einzelsieg wachsen gemeinsam; jede Option bringt neue Mechanikfamilien.
6. **Kombination mit den 11 Rollen:** neue Rollen sollen vorhandene Systeme (Reaktionswarteschlange, `ExecutionRules`, `WinRules`, `InformationRules`, `RoleTransition`) wiederverwenden.

Nicht ausschlaggebend war die Nachtpriorität und nicht, wie interessant eine Rolle ist.

**Bewusst in keiner Option:** alle Rollen mit `not-found` (`die-ewigen`, `prophet-des-untergangs`, `korrupter-richter`, `grabraeuber`), mit Stimmbezug (`blutwolf`, `hades`, `nekromant`), mit Totenkarten-Kern (`kartenschlucker`), mit Wiederbelebung und Rollenneuvergabe (`kutscher`, `dr-victor-frankenstein`), mit kritischem Risiko (`zeitwaechter`, `seelentauscher`) sowie alle Einzelsiegrollen ohne Siegtext (`feuerteufel`, `voodoo-priester`, `pestbringerin`).

## 2. Option A · 20 Rollen

**Rollen Option A (20):** `dorfbewohner`, `werwolf`, `schutzengel`, `waldhexe`, `das-orakel`, `trugbilderwolf`, `sensentraeger`, `wolfskind`, `lehrling`, `manipulator`, `spiegelwolf`, `siegreicher-wolf`, `besessener-wolf`, `dorfwache`, `waldlaeufer`, `doktor`, `ritter`, `wahnsinniger-kutscher`, `selbstmoerder`, `doppelspion`

| Merkmal | Inhalt |
|---|---|
| Zusätzlich (9) | `siegreicher-wolf`, `besessener-wolf`, `dorfwache`, `waldlaeufer`, `doktor`, `ritter`, `wahnsinniger-kutscher`, `selbstmoerder`, `doppelspion` |
| Fraktionen | Dorf 12 · Wölfe 5 · Einzelsieg 3 |
| Neue Mechaniken | passive Immunität gegen den Wolfsangriff; Zahl- und Paarinformation; automatische Todesfolge mit Sitzbezug (Ritter); Todesreaktion mit Wahl auf Wolfsseite (Besessener Wolf); Nebentode bei Hinrichtung (Wahnsinniger Kutscher); Gewicht in der Wolfsparität; Einzelsieg durch Hinrichtung; Einzelsieg statt Dorfsieg |
| Fehlende Mechaniken | verknüpfte Personen, Rollenblockierung, bedingte oder zufallsgestützte Information, dauerhafte Marker, Wiederbelebung, verzögerte Tode, Tagfähigkeiten, Totenkarten |
| Neue Kernsysteme | Siegregel-Erweiterung, allgemeines Informationsmodell, Abfangregel-Liste in der `KillPipeline`, Sitznachbarschaft, weitere Todesfolgen und Reaktionsart, Liste von Hinrichtungsregeln (6, siehe [`06`](06-implementation-batches.md) §2) |
| Technische Risiken | Reihenfolge von Hinrichtungsregeln (Spiegelwolf vor oder nach Kutscher), Sitzrichtung (RM-DR-003), Doppelspion gegen Dorfkandidat (RM-DR-155) |
| Relativer Umfang | Referenz 1,0 (Anteile der Chargen K1 bis K5) |
| Abhängigkeiten | RM-DR-001, -002, -003, -004, -007, -009, -016; Rollen: RM-DR-116, -119, -124, -136, -138, -145, -147, -155 |
| Eignung für neue Spielleiter | hoch: fast alles passiv oder automatisch, wenige Eingaben |
| Wiederspielwert | niedrig bis mittel: 5 Wölfe mit kaum eigenem Nachtspiel, nur 3 Einzelsiegrollen |
| Testaufwand | niedrig bis mittel: 9 Rollen, davon 7 ohne eigenen Nachtschritt |
| Akt-I-Abdeckung | 9 von 17 Akt-I-Rollen |
| Bewertung | solide Minimalversion; erfüllt das 1.0-Ziel knapp und lässt klassische Rollen wie Loki weg |

## 3. Option B · 25 Rollen (empfohlen)

**Rollen Option B (25):** `dorfbewohner`, `werwolf`, `schutzengel`, `waldhexe`, `das-orakel`, `trugbilderwolf`, `sensentraeger`, `wolfskind`, `lehrling`, `manipulator`, `spiegelwolf`, `siegreicher-wolf`, `besessener-wolf`, `dorfwache`, `waldlaeufer`, `doktor`, `ritter`, `wahnsinniger-kutscher`, `selbstmoerder`, `doppelspion`, `loki`, `kopfgeldjaeger`, `cerberus`, `schattenhund`, `rattenfaenger`

| Merkmal | Inhalt |
|---|---|
| Zusätzlich (14) | Option A plus `loki`, `kopfgeldjaeger`, `cerberus`, `schattenhund`, `rattenfaenger` |
| Fraktionen | Dorf 14 · Wölfe 7 · Einzelsieg 4 |
| Neue Mechaniken (zu A) | verknüpfte Personen mit Kettentod (Loki), bedingte und zufallsgestützte Information (Kopfgeldjäger), Hinrichtungsabwehr mit Zähler (Cerberus), Rollenblockierung (Schattenhund), dauerhafte Marker und zustandsbasierter Einzelsieg (Rattenfänger) |
| Fehlende Mechaniken | Wiederbelebung, verzögerte Tode, Zielumleitung durch Rollen außer Spiegelwolf, Tagfähigkeiten, Totenkarten, Durchdringung |
| Neue Kernsysteme | die 6 aus A plus Bindungsmodell, bedingte Schrittverfügbarkeit, Rollenblockierung, dauerhafte Statusmarker, Zähler je Person (11) |
| Technische Risiken | Kettentod und Wiederbelebung (RM-DR-011), Blockade und Nachtplan-Snapshot, Rattenfänger-Sieg nach Toden (Legacy-Bug), Cerberus gegen Hexengift (RM-DR-135) |
| Relativer Umfang | etwa 1,6 bis 1,9 × Option A (5 weitere Rollen, 5 weitere Systeme, die aber je nur eine Rolle der Option tragen, später aber 8 weitere) |
| Abhängigkeiten | wie A plus RM-DR-010, -011, -014, -015; Rollen: RM-DR-101, -103, -123, -135, -139 |
| Eignung für neue Spielleiter | hoch bis mittel: Loki und Rattenfänger sind bekannt; Schattenhund braucht eine klare Anzeige der blockierten Schritte |
| Wiederspielwert | mittel bis hoch: 7 Wölfe mit Nachtspiel (Schattenhund) und Tagspiel (Cerberus), 4 unterschiedliche Einzelsiege |
| Testaufwand | mittel: Kettentod, Blockade und Marker brauchen Kombinationstests ([`07`](07-test-strategy.md) §4) |
| Akt-I-Abdeckung | 11 von 17 |
| Bewertung | bester Ausgleich aus Vielfalt, Spielleiterfreundlichkeit und Anzahl neuer Systeme |

## 4. Option C · 30 Rollen

**Rollen Option C (30):** `dorfbewohner`, `werwolf`, `schutzengel`, `waldhexe`, `das-orakel`, `trugbilderwolf`, `sensentraeger`, `wolfskind`, `lehrling`, `manipulator`, `spiegelwolf`, `siegreicher-wolf`, `besessener-wolf`, `dorfwache`, `waldlaeufer`, `doktor`, `ritter`, `wahnsinniger-kutscher`, `selbstmoerder`, `doppelspion`, `loki`, `kopfgeldjaeger`, `cerberus`, `schattenhund`, `rattenfaenger`, `nachtwaechter`, `die-gebundenen`, `der-weise`, `koenig-lykaon`, `parasit`

| Merkmal | Inhalt |
|---|---|
| Zusätzlich (19) | Option B plus `nachtwaechter`, `die-gebundenen`, `der-weise`, `koenig-lykaon`, `parasit` |
| Fraktionen | Dorf 17 · Wölfe 8 · Einzelsieg 5 |
| Neue Mechaniken (zu B) | öffentliche Warninformation aus Sitzlage (Nachtwächter), Gruppeninformation mit mehreren Kopien (Gebundene), Einmalrettung plus mehrtägige Blockade nach Hinrichtung (Der Weise), Rollenwechsel durch einen Wolf während der Partie mit Scheinrolle (König Lykaon), Immunität über Bindung und Einzelsieg bei drei Lebenden (Parasit) |
| Fehlende Mechaniken | Wiederbelebung, verzögerte Tode, Totenkarten, Nachtrücknahme, Tagfähigkeiten |
| Neue Kernsysteme | die 11 aus B plus öffentliche Informationsereignisse, Obergrenzen-Ausnahme für Gruppenrollen, mehrnächtige Modifikatoren, Scheinrolle bei Rollenwechsel und Wächter-Einhängepunkt, Immunität über Bindung (etwa 15) |
| Technische Risiken | Der Weise (M/hoch, Legacy-Bug F10, sechs Widersprüche), Scheinrolle eines neu entstandenen Trugbilderwolfs (RM-C-004), Parasit-Immunität gegen Hinrichtung am Tisch erklären |
| Relativer Umfang | etwa 2,4 bis 2,8 × Option A |
| Abhängigkeiten | wie B plus RM-DR-102, -107, -114, -157 |
| Eignung für neue Spielleiter | mittel: Der Weise und König Lykaon verlangen Erklärung; mehr Setup-Entscheidungen |
| Wiederspielwert | hoch: fast vollständiger Akt I, 5 Einzelsiege, Rollenwechsel auf Wolfsseite |
| Testaufwand | hoch: Der Weise allein berührt Schutz, Hinrichtung und Blockade |
| Akt-I-Abdeckung | 15 von 17 (fehlend: `spuerhund`, `rachsuechtiger-wolf`) |
| Bewertung | sinnvoll als Ziel, wenn nach B Kapazität bleibt; keine zusätzliche Grundarchitektur nötig, aber viele Einzelregeln |

## 5. Vergleich

| Kriterium | A (20) | B (25) | C (30) |
|---|---|---|---|
| Dorf / Wölfe / Einzelsieg | 12 / 5 / 3 | 14 / 7 / 4 | 17 / 8 / 5 |
| Neue Kernsysteme (ca.) | 6 | 11 | 15 |
| Offene Entscheidungen bis 1.0 (Querschnitt + Rolle) | 7 + 8 | 11 + 13 | 11 + 17 |
| Relativer Umfang | 1,0 | 1,6 bis 1,9 | 2,4 bis 2,8 |
| Rollen mit Risiko „hoch“ | 0 | 0 | 1 (`der-weise`) |
| Eignung für neue Spielleiter | hoch | hoch bis mittel | mittel |
| Wiederspielwert | niedrig bis mittel | mittel bis hoch | hoch |
| Akt-I-Abdeckung | 9/17 | 11/17 | 15/17 |
| Rollen ohne eigenen Nachtschritt unter den neuen | 7 von 9 | 8 von 14 | 10 von 19 |

## 6. Empfehlung

**Option B (25 Rollen).**

- Sie erfüllt das Ziel „20 bis 30 geprüfte Rollen“ mit Reserve, ohne eine Rolle mit hohem oder kritischem Risiko.
- Alle drei Fraktionen wachsen spürbar; die Wolfsseite erhält erstmals eigene Nacht- und Tagesmechaniken (Schattenhund, Cerberus, Besessener Wolf).
- Jedes neue Kernsystem wird in B eingeführt und trägt nach 1.0 weitere Rollen: Bindungsmodell (`schattenwanderer`, `schwarze-witwe`, `parasit`, `rotkaeppchen`, `voodoo-priester`), Rollenblockierung (`albtraumwolf`, `der-weise`, `zeitwaechter`), Marker (`pestbringerin`, `feuerteufel`, `prophet-des-untergangs`), Sitznachbarschaft (`nachtwaechter`, `faehrtenleser`, `detektiv`), Informationsmodell (`die-gebundenen`, `dorfchronistin`, `koenig`, `traumdeuter`, `spuerhund`, `blutpriester`, `kriegerin-des-lichts` und weitere).
- Keine Rolle hängt an Totenkarten, Stimmen oder Wiederbelebung, deren Grundsatzfragen (`07` Q2, Q3) offen sind.
- Option C bleibt als direkte Erweiterung möglich, weil sie nur B ergänzt.

**Voraussetzung:** Die elf Querschnittsentscheidungen, die 1.0 blockieren (RM-DR-001 bis -004, -007, -009, -010, -011, -014, -015, -016), und die 13 Rollenentscheidungen der Option B.
