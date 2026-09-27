# 04 · Regelwidersprüche und Legacy-Bugs

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · konsolidiert 2026-09-27 (§2) · nur Analyse, keine Regel entschieden

## 1. Aufbau

- §2 Querschnittswidersprüche, die viele Rollen gleichzeitig betreffen. Sie werden einmal entschieden (RM-DR-001 bis RM-DR-016 in [`08`](08-decision-request.md)), sonst müsste dieselbe Frage bei jeder Rolle erneut beantwortet werden.
- §3 Rollenspezifische Widersprüche mit stabilen IDs `RM-C-###`.
- §4 Legacy-Bugs: rollenübergreifend und je Rolle.
- §5 Einstufungen, in denen diese Analyse von der älteren Matrix `docs/godot-migration/04-rules-migration-matrix.md` abweicht.
- §6 Veraltete oder widersprüchliche Aussagen in bestehenden Dokumenten.

Widersprüche bleiben offen stehen. Die Spalte „Empfehlung“ ist ein Vorschlag, keine Entscheidung. Belegt ist jeder Eintrag im verlinkten Dossier mit Pfad und Zeilenbereich.

## 2. Querschnittswidersprüche

| Thema | Beleg (Auszug) | Betroffene Rollen (Auszug) | Entscheidung |
|---|---|---|---|
| **Einsätze global pro Rollenname statt pro Person.** `markOnceUsed`/`isOnceUsed` speichern `once.Used["role_<Name>"]`; eigene globale Schlüssel wie `GiftwolfUses`, `WhiteWolfCooldown`, `MaertyUsed`, `KutscherUsed`, `HadesLichter`. Mehrere Kopien teilen einen Einsatz; `resetOnceForInheritedRole` (`js/ui/core.js:339-359`) löscht teils falsche Schlüssel. Godot hat bereits `Player.ability_uses` je Person. | `js/core/night.js:3-5`, `js/ui/core.js:339-359`, Dossiers (Abschnitte „Gruppenübergreifende Beobachtungen“) | fast alle Rollen mit begrenztem Einsatz | RM-DR-001 (entschieden durch G-ID-3) |
| **Drei Wolfsdefinitionen.** `isWolf` schließt `flags.werewolf` und `meta.cursedWolfAura` ein (`js/ui/core.js:8-19`); Doktor und König nutzen die rollenbasierte Fraktion; Spürhund nutzt `getRoleFaction(role)`; der Der-Weise-Debuff nutzt `WOLF_ROLES_SET`. Ein verwandeltes Wolfskind ist für den Nachtwächter Wolf, für den Spürhund nicht. Godot trennt `faction`, `counts_as_wolf`, `appears_as` und hat `InformationRules.determine_role`. | `js/ui/core.js:8-19`, [`dossiers/village-1.md`](dossiers/village-1.md) Gruppenbeobachtung 1, [`dossiers/village-3.md`](dossiers/village-3.md) Gruppenbeobachtung 2 | über 20 Informations- und Wirkungsrollen | RM-DR-002 |
| **Sitzrichtung widersprüchlich.** Fährtenleser: „links“ = höhere Sitznummer (`js/core/abilities-roles-chunk.js:478-483`); Ritter prüft bei Gleichstand zuerst die niedrigere Nummer (`js/ui/core.js:423-425`); Detektiv: links = `id-1`. Nachbarschaft teils „direkter Sitz“ (Wahnsinniger Kutscher `night.js:427-429`), teils „nächster Lebender“ (Nachtwächter `night.js:546-553`). Alle rechnen mit `id-1` als Sitzindex, Godot trennt Personen-ID und `seat_order`. | Dossiers `village-1`, `village-3`, `village-4` | 8 Rollen | RM-DR-003 |
| **„Wolfsangriff“ ist nicht definiert.** Alle Wolfskills außer Gift und Rudelvater laufen als `NIGHT_KILL`; Rachsüchtiger Wolf, Schicksalswolf-Zusatzopfer und umgelenkte Tode sind vom Rudelkill nicht unterscheidbar. Der Weise, Dorfwache, Rudelvater, Seuchenwolf, Ritter, Dorfschmied hängen am Begriff. | [`dossiers/wolves-a.md`](dossiers/wolves-a.md) Gruppenbeobachtung 4 | 13 Rollen | RM-DR-004 |
| **Zwei Durchdringungsregeln.** Rudelvater-Zusatzopfer (`PACKFATHER_KILL`) durchdringt die Schilde von Nekromant, Kartenschlucker und Hades (`js/ui/core.js:126-143`), der Seuchenwolf nicht; beide durchdringen Schmied, Voodoo, Märtyrerin nicht. Verdammniswächter „umgeht alle Schutzfähigkeiten“, im Code greifen die Schilde trotzdem. | [`dossiers/wolves-a.md`](dossiers/wolves-a.md) Gruppenbeobachtung 2, [`dossiers/village-1.md`](dossiers/village-1.md) `verdammniswaechter` | 10 Rollen | RM-DR-005 |
| **Schutz wird beim Zielen geprüft, nicht bei der Auflösung.** Nur Werwolf- und Rachsüchtiger-Handler prüfen Schutz (`abilities-roles-chunk.js:162`, `:348`). Zusatzopfer von Schicksalswolf und Rudelvater ignorieren den Schutzengel; der Schutzgeist (Tier 5.6) schützt nach dem Rudel (2.0) und wird bei Nachtbeginn gelöscht. Godot prüft Schutz in der Morgenauflösung (DR-05) und ändert damit das Verhalten dieser Rollen. | [`dossiers/wolves-a.md`](dossiers/wolves-a.md) Gruppenbeobachtung 3, [`dossiers/village-4.md`](dossiers/village-4.md) Gruppenbeobachtung 8 | Schicksalswolf, Rudelvater, Schutzgeist, Dorfwache | RM-DR-004, RM-DR-005 (DR-05 gilt bereits) |
| **Fünf Siegprüfstellen, Solos zählen als Dorfseite.** `checkWinConditions`, `checkTeamWin`, `checkPestWin`, `checkFluteWin` und der Selbstmörder-Zweig setzen Sieger; `triggerWin` hat keinen Guard. Sterben alle Wölfe, gewinnt das Dorf sofort, auch wenn Einzelsiegrollen leben (außer Doppelspion). Für Godot ist das entschieden: Kandidatenmenge ohne Priorität (DR-02, DR-14), Dorfkandidat sobald kein Wolf lebt, unabhängig von Einzelsiegrollen (G-SIEG-1), Einzelsiegrollen zählen als Nicht-Wölfe (G-SIEG-2). Offen ist nur eine mögliche Ausnahme beim Doppelspion (RM-DR-155.3). | [`dossiers/solos-a.md`](dossiers/solos-a.md) Gruppenbeobachtungen 1-2, [`dossiers/solos-b.md`](dossiers/solos-b.md) Gruppenbeobachtung 4 | 13 Einzelsiegrollen | RM-DR-007 (entschieden) |
| **Einzelsiegrollen ohne Siegcode, Siegtexte fehlen.** Kein Siegcode für Prophet des Untergangs, Feuerteufel, Voodoo-Priester, Grabräuber; Mitsieg der Ewigen fehlt; Rachsüchtiger Wolf „will alleine gewinnen“, gewinnt im Code mit dem Rudel. Feuerteufel, Voodoo-Priester und Pestbringerin versprechen im Text gar keinen Sieg. | [`dossiers/solos-a.md`](dossiers/solos-a.md) Gruppenbeobachtung 3 | 7 Rollen | RM-DR-006 |
| **Stimmbezug trotz Ausschluss digitaler Stimmen.** Korrupter Richter „+1 Stimme“, Blutwolf-Stimmgewicht, Hades „Stimme ×3“, Nekromant „Stimmen opfern“. `implementation-boundary.md` D schließt Stimmgewichte aus. | `js/ui/ui.js:18` (`voteWeight`, ungenutzt), [`../specs/vertical-slice/implementation-boundary.md`](../specs/vertical-slice/implementation-boundary.md) D | 4 Rollen | RM-DR-008 |
| **Todesreaktionen außerhalb einer Warteschlange.** Dämonischer Wolf, Besessener Wolf, Rudelvater, Nekromant, Märtyrerin öffnen eigene Picks; Abbruch (`startPick`/`startMulti` ohne `onCancel`, `js/ui/ui.js:315,325,340`) lässt die Morgenauflösung hängen. Zeitpunkt teils sofort, teils am Morgen. | [`dossiers/wolves-b.md`](dossiers/wolves-b.md) Gruppenbeobachtungen 3-4 | 11 Rollen | RM-DR-009 (für Reaktionen mit Entscheidung entschieden durch G-TOD-4) |
| **Blockaden wirken nur auf Nachtschritte und filtern über Rollennamen.** Schattenhund, Albtraumwolf, Zeitwächter, Der-Weise-Debuff wirken ausschließlich in `onOrderClick` (`js/core/abilities.js:92-99`), nie auf Morgenauflösung oder Todesreaktionen, und filtern „nicht in `WOLF_ROLES_SET`“, also auch Solos. | [`dossiers/wolves-b.md`](dossiers/wolves-b.md) Gruppenbeobachtung 7 | 4 Rollen | RM-DR-010 |
| **Wiederbelebung ohne Modell.** Frankenstein setzt `dead=false` (`abilities-roles-chunk.js:57`), Kutscher löscht alle Flags (`:849`); Bindungen, `lastKillCause`, Totenkarten und Einsätze werden uneinheitlich behandelt. Ein wiederbelebter Liebender stirbt erneut an Liebeskummer. Godot kennt Wiederbelebung nur als `GmCorrection revive`. | [`dossiers/village-3.md`](dossiers/village-3.md) `dr-victor-frankenstein`, [`dossiers/village-2.md`](dossiers/village-2.md) `kutscher` | 11 Rollen | RM-DR-011 |
| **„once“ bedeutet „einmal pro Partie“, Texte sagen „erste Nacht“.** `ORDER_BASE` `once:true` blendet nach Nutzung aus, nicht nach Nacht 1. Die Gebundenen sollen laut Text in Nacht 1 aufwachen; König Lykaon und Schicksalswolf verfallen nach Nacht 1; Wolfskind und Lehrling sind in Godot bereits als „erste verfügbare Nacht“ entschieden (DR-10, DR-11). | [`dossiers/village-1.md`](dossiers/village-1.md) Gruppenbeobachtung 5 | 14 Rollen | RM-DR-014 |
| **Zufall ohne Seed.** `Math.random` in Spürhund, Verdammniswächter, Kutscher, Blutpriester, Traumdeuter, Kopfgeldjäger, König, Detektiv, Dorfschmied, Pestbringerin; erneutes Öffnen würfelt teils neu; Informationsergebnisse werden nicht gespeichert. | Dossiers, jeweils „Legacy-Codeverhalten“ | 10 Rollen | RM-DR-015 |
| **Legacy-Obergrenze 1 für fast alle Rollen.** `setup.html:793-798`: Werwolf 5, Dorfbewohner 10, Die Gebundenen 6, alle anderen 1. Viele Handler nehmen `seats.find(role)` an. Godot hat `max_copies`, setzt es aber für keine Rolle. | [`dossiers/inventory.md`](dossiers/inventory.md) §6 | alle neuen Rollen | RM-DR-016 (keine globale Grenze beschlossen; Mehrfachkopien entstehen auch durch Erbe) |

## 3. Rollenspezifische Widersprüche

Je Rolle eine Tabelle. Spalten wie im Auftrag; „PO“ = Product-Owner-Entscheidung erforderlich. Die Spalten Legacy-Code, React und Doku fassen den Befund zusammen, die Fundstellen stehen im Dossier. Rollen ohne Eintrag haben keinen belegten Text-/Code-Widerspruch.

**Lesehilfe:** In übernommenen Zellen und Bugtexten bezeichnen `01` bis `07` ohne Pfad die älteren Dokumente unter `docs/godot-migration/` (nicht die Dokumente dieses Ordners); Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`.

### `loki`

Dossier: [village-1.md](dossiers/village-1.md#loki) · Entscheidung: RM-DR-101

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-082 | Rivalen-Wirkung | "verfluche zwei als ewige Rivalen" | "curse two players as eternal rivals" | kein Effekt außer Witwe-Ziel (`chunk:454`) | wie Legacy | 07 Q1 Vorschlag: nie gemeinsam gewinnen oder Option entfernen | Rivalen = reiner Marker für Schwarze Witwe | Rivalen bekommen eigene Regel (z.B. Siegsperre) | Hass-Option ist ohne Witwe eine Leerwahl | Ohne Regel nur Marker; mit Regel WinRules-Erweiterung | PO entscheidet; bis dahin Marker | Ja |
| RM-C-083 | Nacht-1 vs. einmal | "einmalig" | "Once per game" | jede Nacht bis Nutzung (`night:59`) | wie Legacy | 04: "einmal" | einmal pro Partie, beliebige Nacht | nur Nacht 1 | gering | Schritt-Bedingung | Code = Text, beibehalten | Nein |

### `nachtwaechter`

Dossier: [village-1.md](dossiers/village-1.md#nachtwaechter) · Entscheidung: RM-DR-102

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-084 | Öffentlicher Alarm | "Es ertönen öffentlich die Alarmglocken" | "ring publicly" | kein sichtbarer Effekt (No-op) | keiner | 04: fehlend | Öffentliches Ereignis jeden Morgen bei Treffer | nur SL-Hinweis, SL läutet | Rolle ist heute wirkungslos | PUBLIC-Ereignis + Anzeige | A, als öffentliches Ereignis | Nein |
| RM-C-085 | Nachbarbegriff | "ein Nachbar" | "a neighbor" | nächster lebender Nachbar | keiner | 04: "lebender Nachbar" | nächster lebender Sitz | direkter Sitz | leicht | Sitznachbarschafts-Funktion | nächster lebender (wie Code) | Ja |
| RM-C-086 | Solo zählt | "nicht ins Dorf gehört" | "doesn't belong to the village" | Wolf ODER Solo | keiner | 04: Wolf oder Solo | Solo zählt | nur Wolf | mittel | Fraktionsabfrage | Solo zählt (Code und Text decken sich) | Nein |

### `rattenfaenger`

Dossier: [solos-a.md](dossiers/solos-a.md#rattenfaenger) · Entscheidung: RM-DR-103

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-040 | Siegzeitpunkt | „Sobald alle lebenden Spieler in deinem Bann sind" | „Wins when all living players are charmed" | nur nach Verzaubern (`chunk:659,670`) | wie Legacy | 04: verifiziert | Prüfung nach jeder Zustandsänderung (Tod, Verzauberung, Wiederbelebung) | nur beim eigenen Zug | A macht Nachttode durch Wölfe zum Vorteil des Rattenfängers | Siegregel in WinRules nach jedem Tod | A | Nein |
| RM-C-041 | Zählt er selbst | „alle lebenden Spieler" | „all living players" | alle außer ihm (`core:280`) | wie Legacy | 04: „alle anderen" | alle außer Rattenfänger | inkl. Rattenfänger (Selbstverzauberung nötig) | B verschwendet eine Verzauberung | Filter | A (Code) + Text präzisieren | Ja |
| RM-C-042 | Anzahl pro Nacht | 1 oder 2 | keine Zahl | 1 oder 2, beliebig oft pro Nacht per erneutem Klick | wie Legacy | – | genau eine Aktion mit 1-2 Zielen | beliebig | Mehrfachklick bricht Balance | Einmal-pro-Nacht-Schritt | A | Nein |
| RM-C-043 | Verzauberung durch Puppe aufgehoben | – | – | `chunk:308` setzt `charmed=false` | wie Legacy | nirgends dokumentiert | beabsichtigte Interaktion | Altlast | Voodoo kann Rattenfänger bremsen | eigene Regel nötig | streichen, falls nicht gewollt | Ja |

### `die-ewigen`

Dossier: [village-1.md](dossiers/village-1.md#die-ewigen) · Entscheidung: RM-DR-104

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-087 | Mitsieg | "gewinnen gemeinsam mit ihm" | "win together with them" | nicht vorhanden | nicht vorhanden | 04 fehlend, 07 Q4 | Ewige gewinnen mit jedem gefundenen Solo, wenn dieser gewinnt | Ewige gewinnen mit dem Solo, den sie zuletzt/zuerst gefunden haben | hoch (Dorfrolle wechselt faktisch Siegseite) | WinCandidate muss Mitsieger tragen; widerspricht "genau ein Kandidat" | Regel festlegen, Mitsieg als Zusatz-Gewinner am Kandidaten | Ja |
| RM-C-088 | Info-Umfang | "prüfen ob ... Solo-Siegbedingung" | "check whether" | zeigt Ja + Rollennamen | wie Legacy | nicht erwähnt | nur Ja/Nein | Ja + Rolle | Rollenname ist Orakel-starke Info | InfoRecord-Inhalt | nur Ja/Nein | Ja |
| RM-C-089 | Siegseite der Ewigen | Dorf-Akte, Fraktion dorf | dito | `getRoleFaction` = dorf, zählt in Parität als Nicht-Wolf | wie Legacy | – | Ewige bleiben Dorf und gewinnen zusätzlich mit Solo | Ewige verlassen das Dorf, sobald Solo gefunden | mittel | Fraktionswechsel oder Zusatzsieg | PO | Ja |

### `spuerhund`

Dossier: [village-1.md](dossiers/village-1.md#spuerhund) · Entscheidung: RM-DR-105

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-090 | Wer wird falsche Spur | "ein Spieler" | "a random player" | Zufall über alle Lebenden | wie Legacy | 04: zufälliger Spieler (Seed) | Zufall (SeededRng) | SL wählt | Zufall kann Spürhund selbst oder echte Wölfe treffen (dann wirkungslos) | Rng-Aufruf vs. Prompt | Zufall über lebende Nicht-Wolf/Nicht-Solo außer Spürhund, per SeededRng | Ja |
| RM-C-091 | Was ist "Wolf" | "Wolf" | "wolf" | Rollenname-Fraktion | wie Legacy | 04 verifiziert | wie `isWolf` (inkl. verwandelte) | nur Rollenname | verwandeltes Wolfskind unsichtbar | FactionQuery statt Rollenname | `isWolf`-Äquivalent | Nein |

### `rachsuechtiger-wolf`

Dossier: [wolves-a.md](dossiers/wolves-a.md#rachsuechtiger-wolf) · Entscheidung: RM-DR-106

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-001 | Siegziel | "willst alleine gewinnen" | fehlt | gewinnt mit Rudel (isWolf, Parität) | kein eigenes | 04 widersprüchlich, 07 Q1 "Text" | Einzelsieg: gewinnt nur, wenn er als Letzter (oder mit Bedingung X) übrig ist | Rudelsieg wie Code | A macht ihn zum Verräter im Rudel, B zu einem normalen Wolf mit Zusatzkill | A: neue Siegbedingung, Fraktion "solo" trotz Wolfsrudel, Parität neu definieren | A (Text), EN ergänzen | Ja |
| RM-C-002 | Rhythmus | "jede dritte Nacht" | "every third night" | ab Nacht 1 frei, danach 2 Nächte Sperre | kein | 04 "3 Nächte Pause" | fester Takt (Nacht 3, 6, 9) | Abklingzeit nach Nutzung | A seltener und vorhersehbar | Nachtschritt-Bedingung nach Nachtnummer vs. Zähler pro Person | Abklingzeit (Code), Text präzisieren | Ja |
| RM-C-003 | Zeitpunkt der ersten Nutzung | nicht genannt | nicht genannt | Nacht 1 möglich | kein | nicht erwähnt | erst ab Nacht 3 | ab Nacht 1 | früher Rudelverlust in Nacht 1 möglich | Startwert Zähler | festlegen | Ja |

### `koenig-lykaon`

Dossier: [wolves-a.md](dossiers/wolves-a.md#koenig-lykaon) · Entscheidung: RM-DR-107

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-004 | Scheinrolle des erzeugten Trugbilderwolfs | nicht genannt | nicht genannt | keine gespeichert; Orakel zeigt Zufallsrolle | kein | DECISION-LOG: Scheinrolle nur im Aufbau festgelegt | Scheinrolle = alte Rolle der Person | SL wählt bei Verwandlung | A passt zur Tarnzeile und ist logisch stark | `appears_as` muss bei RoleTransition gesetzt werden | A, mit SL-Korrektur | Ja |
| RM-C-005 | "Dorfbewohner" | "Dorfbewohner" | "villager" | jede Nicht-Wolf-Rolle inkl. Solos | kein | 04 "Opfer" | nur Dorffraktion | jede Nicht-Wolf-Person | B kann Solo-Rollen neutralisieren | Zielfilter `faction==village` vs `!counts_as_wolf` | festlegen | Ja |

### `seuchenwolf`

Dossier: [wolves-a.md](dossiers/wolves-a.md#seuchenwolf) · Entscheidung: RM-DR-108

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-006 | Umfang "alle Schutzeffekte" | alle | all | nur Schutzengel/Schutzgeist, Dorfwache, Der Weise; Schilde, Hexe, Schmied, Märtyrerin nicht | kein | 04 verifiziert, "Schutz" | wirklich alles, was einen Rudelkill verhindert | nur Schutzrollen (Schutzengel, Dorfwache, Der Weise), keine Schilde/Rettungen | A deutlich stärker | Liste der durchdrungenen Abfangregeln in KillPipeline festlegen | Einheitliche Liste mit Rudelvater teilen | Ja |
| RM-C-007 | Verbrauch | "der nächste Wolfsangriff" | "the next wolf attack" | erst beim nächsten erfolgreichen NIGHT_KILL | kein | 04 "einmal" | nächster Angriff, auch wenn er scheitert | nächster erfolgreiche Kill | A kann durch Hexe verpuffen | Verbrauchszeitpunkt | A (Text) | Ja |
| RM-C-008 | Welche Angriffe | "Wolfsangriff" | "wolf attack" | nur Rudelwahl nutzt es, Rachsüchtiger nicht; aber dessen Kill verbraucht es | kein | nicht erwähnt | nur Rudelangriff | jeder Wolfskill | gering | Ursachen-Attribut | nur Rudelangriff | Ja |

### `schicksalswolf`

Dossier: [wolves-a.md](dossiers/wolves-a.md#schicksalswolf) · Entscheidung: RM-DR-109

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-009 | Zeitfenster | "in Nacht 4" | "in night 4" | ab Nacht 4 bis genutzt | kein | 04 "ab Nacht 4" | nur Nacht 4, danach verfallen | ab Nacht 4, einmal | B lässt Wölfe auf Bonus warten | Schrittbedingung | A (Text) | Ja |
| RM-C-010 | Schutz gegen Zusatzopfer | nicht genannt ("reißen") | "kill" | Schutzengel ignoriert, Dorfwache/Weise wirken | kein | nicht erwähnt | wie Rudelangriff (Schutz wirkt) | eigener Kill ohne Schutz | A schwächer | Ursache/Quelle, Protections-Filter | A | Ja |
| RM-C-011 | Zählung der ersten drei Toten | "unter den ersten drei Toten" | "among the first three dead" | alle Ursachen, keine Deduplizierung, auch vor Markierung | kein | nicht erwähnt | erste drei verschiedenen Toten der Partie | nur Tode nach Markierung | gering | Todesreihenfolge-Historie | A mit Deduplizierung | Ja |

### `giftwolf`

Dossier: [wolves-a.md](dossiers/wolves-a.md#giftwolf) · Entscheidung: RM-DR-111

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-012 | Zwei Ladungen in einer Nacht | "zweimal im Spiel" | "twice per game" | ja | kein | 04 unklar, 07 Vorschlag max 1 | beide sofort erlaubt | max 1 pro Nacht | A erlaubt Doppelschlag | Schrittbedingung | B (07) | Ja |
| RM-C-013 | "erfährt davon" | Ziel erfährt | informed | nur SL-Hinweis | kein | nicht erwähnt | öffentlich/Ansage an Ziel in der Nacht | SL flüstert am Morgen | Informationsvorteil fürs Ziel | InfoRecord actor=Ziel | A als Actor-Ereignis | Ja |
| RM-C-014 | Zeitpunkt "zwei Tage später" | zwei Tage später | two days later | Morgen nach der übernächsten Nacht, vor Nachtopfern | kein | 04 "übernächster Morgen" | Morgen von Tag N+1 | Ende von Tag N+1 | gering | Termin in `day_number` | Code | Ja |

### `rudelvater`

Dossier: [wolves-a.md](dossiers/wolves-a.md#rudelvater) · Entscheidung: RM-DR-112

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-015 | Was ist "Wolfsangriff" | Wolfsangriff | wolf attack | NIGHT_KILL, PACKFATHER_KILL, GIFTWOLF_DELAY; nicht Schwarze Witwe, Besessener Wolf, Spiegelwolf | kein | 04 Filter übernommen | jede Tötung durch eine Wolfsrolle | nur Rudel-/Wolfsnachtangriff | A macht ihn verwundbarer | Ursachen-Attribut `wolf_source` | A oder Liste | Ja |
| RM-C-016 | Was ist "Lynch" | Lynch | lynch | nur Ursache LYNCH; Kutscher-Seitentod, Brand-Seitentod, Henker werden gerettet | kein | nicht erwähnt | nur die Hinrichtung selbst | alles, was aus einer Hinrichtung folgt | gering | Ursachen-Attribut execution vs. execution_side | nur Hinrichtung (Code) | Ja |
| RM-C-017 | "alle Schutzfähigkeiten" | alle | all | Schilde ja, Schmied/Voodoo/Märtyrerin/Albtraum nein | kein | 04 "pierces" | wirklich alle Abfangregeln | nur Schutzrollen und Schilde | gering | gemeinsame Durchdringungsliste mit Seuchenwolf | eine Liste für beide | Ja |
| RM-C-018 | Wer wählt wann | Werwölfe, folgende Nacht | werewolves, following night | SL am Morgen nach der Nacht | kein | 04 "nächste Nacht" | eigener Rudelschritt in der Nacht | Pick bei Morgenauflösung | kein, aber Ablauf/Ansage | zweiter Rudel-Prompt in StepQueue | A | Ja |

### `schwarze-witwe`

Dossier: [wolves-b.md](dossiers/wolves-b.md#schwarze-witwe) · Entscheidung: RM-DR-113

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-019 | Loki "automatisch gewählt" | "Loki wird automatisch gewählt" | "Loki is chosen automatically" | Setup blockiert nur ohne Loki (`setup.html:1111`, `gh:1197`); Handler bricht ohne Loki ab (`chunk:450`) | keine | 04 A-21, 07 Q1: Code gilt, Text anpassen | Loki wird beim Setup automatisch ins Rollenset gelegt | Loki ist Pflicht-Beirolle, SL muss sie wählen | keine, solange Loki Pflicht ist | Godot: `requires_roles` (`03:200`) als Validierung oder Auto-Ergänzung | Pflichtpaar-Validierung behalten, Text auf "Benötigt Loki im Spiel" ändern | Ja |
| RM-C-020 | Todeszeitpunkt | "am folgenden Tag" | fehlt | Tod zu Beginn des unmittelbar folgenden Tages, vor allen anderen Morgenauflösungen (`night:192-199`) | keine | 04: "Paar stirbt am Morgen" | Tod am Morgen nach der Wahl | Tod erst am Ende des folgenden Tages / nach Lynch | gering; Morgen-Tod verhindert, dass das Paar am Tag noch abstimmt | Zeitpunkt DAWN vs. Tagesende in der Phasenmaschine | Code (Morgen) übernehmen, EN um "the following morning" ergänzen | Nein |
| RM-C-021 | Zeitwächter-Einfrieren | Zeitwächter: "alle Nachtaktionen dieser Nacht werden abgebrochen" | - | Witwen-Tode laufen vor der Einfrier-Prüfung (`night:192-199` vor `night:323`) | keine | 07 Q1: Zeitwächter "alle Tode dieser Nacht rückgängig" vorgeschlagen | Witwen-Wahl ist Nachtaktion, wird eingefroren | Witwen-Tod ist Tagesereignis, bleibt | mittel; Zeitwächter kontert Witwe nicht | Reihenfolge in DAWN | mit Zeitwächter-Entscheidung Q1 gemeinsam festlegen | Ja |

### `der-weise`

Dossier: [village-1.md](dossiers/village-1.md#der-weise) · Entscheidung: RM-DR-114

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-092 | Anzahl Rettungen | "den ersten Werwolfangriff" | "the first werewolf attack" | 1 (Zufallsverteilung) oder 2 (Popup/React) | immer 2 | 04/07: Bug | genau einmal | – | Weiser deutlich zu stark | Rettung als eigene Schutzregel, kein `flags.protected` | genau einmal | Nein |
| RM-C-093 | Wer verliert Fähigkeiten | "das Dorf ... diese" | "the village ... they" | alle Nicht-WOLF_ROLES_SET-Zeilen inkl. Solo | wie Legacy | 04 B-6: inkl. Solos | nur Dorf-Fraktion | alle Nicht-Wölfe | Solos werden mitbestraft | FactionQuery-Filter | nur Dorf | Ja |
| RM-C-094 | Dauer "Nächte und Tage" | "1–3 Nächte und Tage" | "1–3 nights and days" | nur n Nächte (Nachtzeilen) | wie Legacy | – | Sperre gilt auch für Tagfähigkeiten | nur Nächte | gering bis mittel | Tagesaktionen brauchen Blockprüfung | Nacht und Tag | Ja |
| RM-C-095 | Wer wählt 1-3 | "1–3" | "1–3" | SL wählt | wie Legacy | 04: SL wählt | SL | Zufall | gering | Prompt vs. Rng | SL (wie Code) | Nein |
| RM-C-096 | Durchschlag | "ersten Werwolfangriff" | "first werewolf attack" | Seuchenwolf/Rudelvater töten ohne Verbrauch | wie Legacy | – | Durchschlag tötet | Rettung greift trotzdem | gering | Filter in Protections | wie Code | Ja |
| RM-C-097 | Passive Fähigkeiten im Debuff | "ihre Fähigkeiten" | "their abilities" | nur Nachtzeilen gesperrt | wie Legacy | – | auch passive (Nachtwächter, Kutscher) | nur aktive | mittel | Blockmarker in Reaktionen | PO | Ja |

### `verdammniswaechter`

Dossier: [village-1.md](dossiers/village-1.md#verdammniswaechter) · Entscheidung: RM-DR-115

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-098 | "umgeht alle Schutzfähigkeiten" | alle | all | umgeht Auflösungs-Schutz, nicht `applyKill`-Schilde; Schutzengel verhindert Auslösen | wie Legacy | 04/07 | wirklich alle (auch Schilde, Schutzengel) | nur Schutz gegen das Nachtopfer | mittel | KillPipeline-Option `ignore_protections` + Auslösung auch bei geschütztem Opfer | A (07-Vorschlag) | Ja |
| RM-C-099 | Todeszeitpunkt | nicht genannt ("stirbt") | nicht genannt | sofort | wie Legacy | 07: am Morgen | sofort | Morgen | hoch (Hexe, spätere Rollen) | IMMEDIATE vs. Morgenkill | Morgen (07) | Ja |
| RM-C-100 | Zufallskandidat | "anderer Spieler" | "randomly offered player" | nur Nicht-Wölfe, inkl. Solo und sich selbst | wie Legacy | nicht erwähnt | jeder andere Lebende | nur Nicht-Wölfe | Pool ohne Wölfe schützt das Rudel | Rng-Menge | PO | Ja |
| RM-C-101 | role-abilities-Text | – | – | Satz fehlt (`role-abilities.js:36`) | – | – | – | – | – | Textquelle vereinheitlichen | Satz ergänzen oder Regel ändern | Nein |
| RM-C-102 | Fraktion vs. Phase | Dorf | Dorf | Dorf, aber tier 2.3 in Wolfsphase | wie Legacy | 04: D | Dorfrolle mit eigenem Schritt nach Rudel | Wolfsnahe Rolle | gering | nur Schrittpriorität | Dorf, Priorität nach Rudel | Nein |

### `wahnsinniger-kutscher`

Dossier: [village-1.md](dossiers/village-1.md#wahnsinniger-kutscher) · Entscheidung: RM-DR-116

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-103 | Nachbarbegriff | direkte Nachbarn | living neighbors | direkte Sitze, tote übersprungen | wie Legacy | 07: lebende Nachbarn | direkte Sitze (DE, Code) | nächste Lebende (EN, 07) | B tötet spät im Spiel zuverlässiger zwei | gleiche Sitznachbarschafts-Funktion wie Nachtwächter | PO; Texte angleichen | Ja |
| RM-C-104 | Todesursache Kutscher | "gelyncht" | "lynched" | `BUSDRIVER_LYNCH` | wie Legacy | DECISION-LOG: Hinrichtung immer LYNCH | Kutscher `LYNCH`, Nachbarn eigene Ursache | alle eine Ursache | gering (Reaktionen, die auf LYNCH prüfen) | Ursachenmodell | Kutscher `LYNCH`, Nachbarn `MAD_COACHMAN_NEIGHBOR` | Nein |

### `korrupter-richter`

Dossier: [village-2.md](dossiers/village-2.md#korrupter-richter) · Entscheidung: RM-DR-117

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-105 | +1 Stimme | "mit +1 Stimme nominiert" | "+1 vote" | nur Flag, keine Stimme | nur Flag | 04 fehlend; DECISION-LOG: Stimmen physisch | SL-Hinweis "zählt +1 Stimme" am nominierten Sitz | Rolle verliert "+1 Stimme", Text anpassen | ohne Hinweis wirkungslos, Rolle nahezu leer | A: nur Anzeige in Nomination-Ansicht; B: nur Text | A (Hinweis + Protokoll) | Ja |
| RM-C-106 | Wer ist Nominierender? | nicht genannt | nicht genannt | keine Quelle | – | DECISION-LOG: Nominierende werden gespeichert | Richter ist Nominierender (Spiegelwolf trifft Richter) | anonyme System-Nominierung (Spiegelwolf ohne Ziel) | Spiegelwolf-Gefahr für Richter | Nominations braucht Quelle `system`/`role` | PO klärt | Ja |
| RM-C-107 | Zählt gegen "einmal nominiert werden"? | – | – | kein Limit | – | DECISION-LOG Limit 1 | zählt | zählt nicht | Richter kann reguläre Nominierung blockieren | Nominations-Regeloption | zählt als Nominierung | Ja |

### `maertyrerin`

Dossier: [village-2.md](dossiers/village-2.md#maertyrerin) · Entscheidung: RM-DR-118

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-108 | Rettung vs. Zeitpunkt | rettet das Nachtopfer | opfert sich vor der Ansage, Rettung nicht genannt | Morgen, rettet nur `nightTargets[0]` | wie Legacy | 04 verifiziert | Ersatzopfer für ein Nachtopfer (Code) | Opfer ohne garantierte Rettung (EN wörtlich) | B macht die Rolle fast nutzlos | A: Abfangregel in Morgenauflösung | A, EN-Text angleichen | Ja |
| RM-C-109 | Welches Opfer bei mehreren | "das Nachtopfer" | "the night victim" | nur erstes Ziel | – | 04 "des ersten Opfers" | SL/Märtyrerin wählt eines | nur Rudelopfer | Rudelvater-/Schicksalswolf-Nächte | Auswahlprompt statt fester Index | Auswahl unter Todeskandidaten | Ja |
| RM-C-110 | Einmaligkeit | nicht genannt | nicht genannt | einmal pro Partie, global | – | 04 "Einmal" | einmal (Tod ist ohnehin endgültig) | – | gering | `ability_uses` pro Person statt global | pro Person | Nein |
| RM-C-111 | Blockaden | – | – | ignoriert Albtraum/Schattenhund/Der Weise | – | – | Reaktion ist blockierbar | nicht blockierbar | gering | Blockadeprüfung in Reaktion | PO | Ja |

### `dorfwache`

Dossier: [village-2.md](dossiers/village-2.md#dorfwache) · Entscheidung: RM-DR-119

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-112 | Giftwolf | "Ziel der Werwölfe" | "targeted by werewolves" | Giftwolf tötet (GIFTWOLF_DELAY) | – | 04 nicht erwähnt | Giftwolf ist Werwolf → immun | nur Rudelangriff zählt | Giftwolf-Ladung auf Dorfwache verschwendet oder tödlich | Filter `is_wolf_attack` muss Giftwolf einordnen | PO | Ja |
| RM-C-113 | Seuchenwolf/Rudelvater | keine Ausnahme genannt | keine Ausnahme | beide durchdringen | – | 04 "nicht gegen Pierce/Rudelvater" | Immunität ist "Schutz" → wird durchdrungen | Immunität ist Rolleneigenschaft → hält | selten, aber spielentscheidend | Kennzeichnung "ignoriert Immunität" | Code (Text der Dorfwache ergänzen) | Ja |

### `pestbringerin`

Dossier: [solos-a.md](dossiers/solos-a.md#pestbringerin) · Entscheidung: RM-DR-120

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-044 | Tödlichkeit | „tödliche Seuche" | „lethal plague" | tötet nie | Legende: „stirbt durch das Gift" | 04/07: widersprüchlich | Code: Marker ohne Tod, Sieg bei Totalinfektion | Text: Seuche tötet (Zeitpunkt offen) | A ist ein Siegrennen, B eine Tötungsrolle | A einfach; B braucht verzögerte Tode | A (07-Vorschlag), Text anpassen | Ja |
| RM-C-045 | Häufigkeit | „jede Nacht" | „Each night" | 2 Einsätze insgesamt, 1/Nacht | wie Legacy | 04 bestätigt | Code | Text (jede Nacht neu) | B beschleunigt Sieg stark | Zähler | Code | Ja |
| RM-C-046 | Siegbedingung | keine | keine | alle Lebenden vergiftet, auch sie selbst, auch wenn sie tot ist | Banner | 04: Sieg wenn alle vergiftet | nur lebend | auch tot | B erlaubt „posthumen" Sieg | Kandidat nur bei lebender Pestbringerin | lebend verlangen | Ja |
| RM-C-047 | Ausbreitung | „breitet sich aus" | „keeps spreading" | 1 zufälliger direkter Nachbar je Vergiftetem je Morgen | wie Legacy | 04 nennt Ausbreitung | direkte Sitze | nächste lebende Nachbarn | Tote Nachbarn bremsen A | Sitznachbarschaft + SeededRng | PO | Ja |

### `prophet-des-untergangs`

Dossier: [solos-a.md](dossiers/solos-a.md#prophet-des-untergangs) · Entscheidung: RM-DR-121

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-048 | Einzelsieg | „gewinnt alleine" | „wins alone" | fehlt; Dorf gewinnt bei 0 Wölfen | wie Legacy | 04/07: fehlend | Sieg als letzter Überlebender (bzw. letzte Nicht-Prophet-Person tot) | Sieg, sobald freigeschaltet und X weitere Tote | Ohne Regel ist die Rolle faktisch Dorf-Hilfe | neue Siegbedingung | PO definieren (07 Q4 B: SL-Siegbutton bis dahin) | Ja |
| RM-C-049 | Freischaltung dauerhaft | „Wenn alle tot sind, erhält er die Fähigkeit" | „When all are dead, gains the ability" | Handler prüft bei jedem Aufruf neu; Wiederbelebung sperrt wieder | wie Legacy | – | dauerhaft | solange alle tot | selten | Status speichern | dauerhaft | Ja |
| RM-C-050 | Selbstmarkierung | „drei Spieler" | „three players" | Selbst erlaubt | wie Legacy | – | nur andere | beliebig | Selbstmarkierung macht Freischaltung unmöglich | Filter | nur andere | Ja |

### `daemonischer-wolf`

Dossier: [wolves-b.md](dossiers/wolves-b.md#daemonischer-wolf) · Entscheidung: RM-DR-122

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-022 | Auslöser | "Verflucht Opfer" | "Curses victims" | nur Todesreaktion (`night:285-290,501`) | keine | 04: "Bei eigenem Tod" | Die Opfer des Rudels werden verflucht (dann sind sie aber tot) | Beim eigenen Tod verflucht er ein Opfer seiner Wahl | hoch: laufender Fluch vs. einmaliger Todesfluch | Nachtschritt vs. Todesreaktion | Todesreaktion (Code) übernehmen, Text präzisieren | Ja |
| RM-C-023 | Wirkung des Fluchs | "als Werwölfe gesehen" | "appear as werewolves" | zählt als Wolf in allen `isWolf`-Stellen inkl. Sieg | keine | 04, 07 Q1: Text (nur Erscheinung) | nur `appears_as` (Informationsrollen) | echter Fraktionswechsel für Parität | sehr hoch: Dorf kann ohne echten Wolf nicht gewinnen | Godot `appears_as` vs. `counts_as_wolf` | nur `appears_as` | Ja |
| RM-C-024 | Todespfade | - | - | Fluch nur bei Nachtziel/Brand/Umlenkung und Standard-Lynch | keine | nicht dokumentiert | jeder Tod löst Fluch aus | nur Wolfsangriff und Lynch | mittel | Reaktion an KillPipeline für alle Ursachen | jeder Tod | Ja |

### `schattenhund`

Dossier: [wolves-b.md](dossiers/wolves-b.md#schattenhund) · Entscheidung: RM-DR-123

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-025 | Betroffene Rollen | "alle Dorf-Fähigkeiten" | "all village abilities" | alle Nicht-`WOLF_ROLES_SET`-Rollen inkl. Solo (`ab:93-94`) | keine | 04 A-34, B-6; 07 Q1 "nur Dorf" | nur Fraktion Dorf | alle Nicht-Wölfe | mittel: Solos werden mitblockiert | Filter über Fraktion statt "nicht Wolf" | nur Dorf | Ja |
| RM-C-026 | Nacht 1 | keine Einschränkung | keine Einschränkung | Nacht 1 verweigert (`chunk:706`) | keine | 04, 07: ab Nacht 2 | Einsatz ab Nacht 1 | ab Nacht 2 | gering | Verfügbarkeitsbedingung des Schritts | ab Nacht 2, Text ergänzen | Ja |
| RM-C-027 | Nicht-Nachtschritt-Effekte | "alle Dorf-Fähigkeiten" | "all village abilities" | nur `onOrderClick`, keine Morgen- oder Todesreaktionen | keine | nicht dokumentiert | nur Nachtschritte | auch Reaktionen/passive Effekte dieser Nacht | mittel | Blockade als Schritt-Status oder als globale Regel | nur Nachtschritte, Text präzisieren | Ja |

### `besessener-wolf`

Dossier: [wolves-b.md](dossiers/wolves-b.md#besessener-wolf) · Entscheidung: RM-DR-124

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-028 | Schwelle "≥5 Spieler" | "bei ≥5 Spielern" | "with ≥5 players" | ≥4 Lebende nach seinem Tod, erneut geprüft beim Abarbeiten (`core:178-179`, `night:310-311`) | keine | 04: "≥ 4 Lebenden" | 5 Lebende inkl. ihm im Todesmoment | 5 Spieler bei Spielbeginn | mittel im Endspiel | Prüfzeitpunkt (Tod vs. Abarbeitung) | lebende inkl. ihm im Todesmoment, keine Neuprüfung | Ja |

### `fenrir`

Dossier: [wolves-b.md](dossiers/wolves-b.md#fenrir) · Entscheidung: RM-DR-125

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-029 | Umfang des Überlebens | "überlebt einmalig jeden Tod" | "survives any death once" | nur Lynch (`night:448`) | keine | 04 A-36, 07 Q1 Vorschlag Text | jede Todesursache, einmal | nur Hinrichtung | hoch: Nachtangriffe kann Wolf-Team nicht wählen, aber Witwe/Hexe/Hades sehr wohl | Abfangregel in KillPipeline vs. ExecutionRules | jede Ursache (Text) | Ja |
| RM-C-030 | Zählung | "jeder überlebten Nacht" | "each survived night" | +1 bei Nachtbeginn (`night:136`) | keine | 04: "pro Nachtbeginn" | +1 am Morgen nach überlebter Nacht | +1 bei Nachtbeginn | gering (eine Nacht früher Stufe 3) | Zeitpunkt DAWN vs. NIGHT_START | +1 am Morgen, wenn Fenrir lebt | Ja |
| RM-C-031 | Ritter | nicht erwähnt | nicht erwähnt | ab Stufe 3 dauerhaft immun (`core:421`) | keine | 04 nennt `core:421` ohne Wertung | Teil von "jeder Tod" (einmal) | Sonderimmunität | mittel | Ritter-Zielauswahl | an Einmal-Schutz koppeln | Ja |
| RM-C-032 | Stufe pro Rolle vs. global | "Wird ... mächtiger" (er) | "Grows" | global `state.fenrirStage` | keine | 01:125 nennt Feld | pro Person | global | gering (selten mehrere Fenrir) | Feld am Spieler | pro Person | Nein |

### `kutscher`

Dossier: [village-2.md](dossiers/village-2.md#kutscher) · Entscheidung: RM-DR-126

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-114 | Rollen der Wiederbelebten | "drei Tote wiederbeleben" | "revives 3 dead players" | neue Zufallsrollen, inkl. Solo | – | 04 verifiziert | echte Wiederbelebung, alte Rolle bleibt (außer Wolf) | "Nachbardorf" bringt neue Personen mit neuen Rollen (Code, Dialogtext) | neue Solo-Rollen mitten im Spiel können Sieglage kippen | Rollenpool, Fraktionszuordnung, Siegbedingungen neuer Solos | PO; wenn Code: Pool auf Dorfrollen des Akts begrenzen | Ja |
| RM-C-115 | Wer wählt die Toten | "kann er ... wiederbeleben" | "revives" | Zufall | – | 04 "zufällige" | Kutscher/SL wählt | Zufall (SeededRng) | Wahl macht Rolle stärker | Prompt vs. RNG | PO | Ja |
| RM-C-116 | Optional | "kann" | "revives" | optional | – | – | optional | automatisch bei 10 Toten | gering | Ja/Nein-Prompt | optional (DE, Code) | Nein |
| RM-C-117 | Einmaligkeit | nicht genannt | nicht genannt | einmal, global; nach Rollenerbe erneut | – | 04 "einmal" | einmal pro Partie | einmal pro Person | Rollenerbe verdoppelt Effekt | `ability_uses` pro Person | einmal pro Person, Text ergänzen | Ja |

### `seelentauscher`

Dossier: [village-2.md](dossiers/village-2.md#seelentauscher) · Entscheidung: RM-DR-127

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-118 | Wolfsstatus nach Tausch | Rollen werden getauscht | same | alter Wolfssitz bleibt Wolf (F4) | – | 04/07: Bug | Status folgt Rolle | – | Wolfsverdopplung | RoleTransition leitet Fraktion aus Rolle ab | A (Bugfix) | Nein |
| RM-C-119 | Was wandert mit | nur "Rollen" | "roles" | nur `role`, Zustände bleiben am Sitz | – | – | Rolle inkl. Rollenzustand (Verbrauch, Bindungen) wandert | nur Rollenname, Zustand bleibt | Tausch von verbrauchten Rollen | RoleTransition-Schnappschuss definiert | PO | Ja |
| RM-C-120 | Toter erhält Wolfsrolle | "lebendig oder tot" | same | Toter wird Wolf ohne Wächter-Prüfung | – | – | erlaubt | Wächter-Prüfung auch für Tote | gering (tot), relevant bei Wiederbelebung | Wächter-Regel auf alle Rollenwechsel | Wächter-Prüfung auch bei Wiederbelebung | Ja |
| RM-C-121 | Information der Betroffenen | nicht genannt | nicht genannt | keine | – | – | Betroffene erfahren neue Rolle | geheim | hoch (Spieler kennt eigene Rolle nicht) | InfoRecord an Betroffene | A | Ja |

### `blutpriester`

Dossier: [village-2.md](dossiers/village-2.md#blutpriester) · Entscheidung: RM-DR-128

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-122 | Anzahl 0–3 | "0–3 Werwölfe" | "0–3 werewolves" | SL wählt frei | – | 04 "SL enthüllt" | SL entscheidet | Anzahl aus Regel (z. B. Zufall oder Rolle des Opfers) | SL-Willkür vs. Planbarkeit | Prompt vs. RNG | PO; Legacy (SL wählt) beibehalten ist einfach | Ja |
| RM-C-123 | Wer sieht das Ergebnis | "deckt ... auf" | "reveals" | nur SL-Anzeige | – | – | öffentlich (aufdecken) | nur Blutpriester | groß (öffentliche Wolfsnennung) | Ereignis-Sichtbarkeit public vs. actor | PO | Ja |
| RM-C-124 | Opfer: Pflicht? | "Opfert jemanden" | "Sacrifices someone" | Pick optional | – | – | Opfer Voraussetzung für Aufdeckung (Code) | – | – | – | Code | Nein |

### `traumdeuter`

Dossier: [village-2.md](dossiers/village-2.md#traumdeuter) · Entscheidung: RM-DR-129

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-125 | Inhalt der Vision | "Visionen über Rollen oder Zustände" | "visions about roles or states" | 3 Namen, genau 1 Wolf, zufällig | – | 04 unklar, 07 Q1 offen | Code übernehmen, Text präzisieren | eigene Mechanik (Rollen/Zustände) | Code: starke Info jede Nacht | A: kleiner Aufwand; B: neue Spezifikation | A mit Textanpassung | Ja |
| RM-C-126 | Selbst in der Vision | – | – | möglich | – | – | ausschließen | erlaubt | Selbstnennung ist verschwendete Info | Filter | ausschließen | Ja |
| RM-C-127 | Verfluchte als Wolf | – | – | ja (`cursedWolfAura`) | – | – | Erscheinung zählt (Fehlinformation) | nur echte Wölfe | beeinflusst Dämonischen Wolf | InformationRules.determine | Erscheinung zählt | Ja |

### `henker`

Dossier: [village-2.md](dossiers/village-2.md#henker) · Entscheidung: RM-DR-130

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-128 | Welcher Lynch | "nach Lynchung" | "after the next lynch" | nächster Lynch, Markierung bleibt bis dahin | – | 04 "beim nächsten Lynch" | nächster Lynch (EN, Code) | nur Lynch des folgenden Tages, sonst verfällt | gering | Verfall ja/nein | A | Nein |
| RM-C-129 | Blockierter Lynch (Fenrir/Cerberus) | – | – | kein Zählen, keine Vollstreckung | – | 01 F15 als Bug, 07 Teil 2 | blockierter Lynch zählt als Lynch | zählt nicht (kein Tod) | beeinflusst Aktivierung und Markierten | ExecutionRules-Ergebnis "verhindert" | PO bestätigen, 07 geht von A aus | Ja |
| RM-C-130 | Zählbasis | "drei Lynchungen" | "three lynchings" | Lynch-Vorgänge; i18n sagt "Lynch-Tote" | – | – | Vorgänge | nur Lynch-Tote | Spiegelwolf/Voodoo-Tage | Zähler-Definition | Vorgänge, i18n anpassen | Ja |
| RM-C-131 | Henker tot | – | – | Markierung wirkt weiter | – | – | wirkt weiter | verfällt mit Henker | gering | Bindung Markierung↔Henker | PO | Ja |

### `feuerteufel`

Dossier: [solos-a.md](dossiers/solos-a.md#feuerteufel) · Entscheidung: RM-DR-131

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-051 | Auslöser | „beim Tod des Ziels" | „when the target dies" | beim Wolfsangriff bzw. Lynch, auch ohne Tod; nicht bei anderen Todesursachen | wie Legacy | 04: Bug | jeder tatsächliche Tod, jede Ursache | nur Wolfsangriff und Hinrichtung, aber nur bei Tod | A stärker | Todesreaktion in KillPipeline | A oder B, jeweils nur bei Tod | Ja |
| RM-C-052 | Dauer der Markierung | offen | offen | eine Nacht + folgender Tag | – | – | bis Ziel stirbt | nur diese Nacht | A viel stärker | Statusmarker mit Ablauf | PO | Ja |
| RM-C-053 | Nachbarn | „die Nachbarn" | „neighbors" | direkte Sitze, Tote verfallen | – | 07 Q1 für Wahnsinnigen Kutscher: „lebende Nachbarn" | direkte Sitze | nächste Lebende | B tötet immer 2 | Sitznachbarschaft | analog Wahnsinniger Kutscher | Ja |
| RM-C-054 | Feuerteufel als Nachbar | offen | offen | Nacht: stirbt; Lynch: verschont | – | – | immer verschont | nie verschont | – | Filter | einheitlich | Ja |
| RM-C-055 | Siegbedingung | keine | keine | keine, aber Fraktion solo | – | 04/07: fehlend | Einzelsieg definieren | Fraktion ändern (Dorf-Chaos-Rolle) | – | WinRules | PO | Ja |

### `voodoo-priester`

Dossier: [solos-a.md](dossiers/solos-a.md#voodoo-priester) · Entscheidung: RM-DR-132

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-056 | Ursachen der Umlenkung | „bei seinem Tod" | „If he would die" | nur Wolfsnachtziel, Lynch, Hexen-Gift | wie Legacy | 04: unklar | jede Todesursache | nur Angriffe (Wolf, Hinrichtung, Gift) | A macht ihn sehr robust | Umlenkungsregel mit Ursachenfilter in KillPipeline | PO | Ja |
| RM-C-057 | Abklingzeit | keine | keine | 2 Tage, auch nach normalem Puppentod | wie Legacy | 04 bestätigt | Code übernehmen, Text ergänzen | keine Abklingzeit | ohne Abklingzeit endloser Schutz | Zähler | Code | Ja |
| RM-C-058 | Verzauberung löschen | – | – | `charmed=false` beim Vergeben | – | – | Altlast | gewollt | Rattenfänger-Konter | – | streichen | Ja |
| RM-C-059 | Siegbedingung | keine | keine | keine, Fraktion solo | – | 04/07: fehlend | Einzelsieg definieren | Fraktion ändern | – | WinRules | PO | Ja |
| RM-C-060 | Bezeichnung | Puppe | doll | – | „puppet", „kontrolliert" | – | – | – | – | Content | einheitlich „doll", Legende korrigieren | Nein |

### `albtraumwolf`

Dossier: [wolves-b.md](dossiers/wolves-b.md#albtraumwolf) · Entscheidung: RM-DR-134

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-033 | Ziele | "eines Dorfbewohners" | "one villager" | jeder Nicht-Wolf inkl. Solo (`chunk:301`) | keine | nicht dokumentiert (Bericht behauptet "nur Dorf") | nur Fraktion Dorf | alle Nicht-Wölfe | mittel | Zielfilter | alle Nicht-Wölfe (Solos sind Gegner der Wölfe), Text anpassen | Ja |
| RM-C-034 | Umfang | "die Fähigkeit eines Dorfbewohners" | "the ability of one villager" | ganze Rolle, alle Kopien (`chunk:294-296`, `ab:97`) | keine | 04 B-6 "(Rolle)" | nur die gewählte Person | alle Personen der Rolle | mittel bei Mehrfachrollen | Blockade pro Person vs. pro Rolle | nur die Person | Ja |
| RM-C-035 | Anzahl pro Nacht | "eines" | "one" | beliebig oft klickbar | keine | nicht dokumentiert | genau eine | beliebig | hoch bei Missbrauch | Schritt einmal pro Nacht | genau eine | Nein |
| RM-C-036 | Späte Wirkung | - | - | wirkt nicht auf bereits erledigte Schritte (tier < 2.1) | keine | nicht dokumentiert | Albtraumwolf handelt vor Dorfrollen | Blockade nur für spätere Schritte | mittel: Schutzengel nie blockierbar | Nachtreihenfolge | tier vor Gruppe B verschieben oder Text präzisieren | Ja |

### `cerberus`

Dossier: [wolves-b.md](dossiers/wolves-b.md#cerberus) · Entscheidung: RM-DR-135

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-037 | Wahl oder Automatik | "kann er ... abwehren" | "can block" | automatisch (`night:449`) | keine | 04 A-46 "überlebt" | Cerberus entscheidet (Prompt) | automatisch | mittel: Wahl erlaubt Bluff/Aufsparen | Prompt in ExecutionRules | Prompt an SL "Cerberus wehrt ab?" | Ja |
| RM-C-038 | Hexengift | nur Lynchung | nur lynch | auch Hexen-Todestrank (`help:265`) | keine | 04 A-4/A-46 übernehmen es | nur Lynch | jede Hinrichtung/gezielte Tötung | mittel | zusätzliche Abfangregel | nur Lynch (Text) | Ja |
| RM-C-039 | Aufbau | "Baut Köpfe auf" | "Builds up" | +1 bei Nachtbeginn | keine | 04 "+1 je Nacht" | pro Nachtbeginn | pro überlebter Nacht | gering | Zeitpunkt | wie Fenrir einheitlich festlegen | Nein |

### `ritter`

Dossier: [village-3.md](dossiers/village-3.md#ritter) · Entscheidung: RM-DR-136

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-132 | Welche Nachttode lösen aus | "beim Sterben in der Nacht" (jede Ursache) | "Upon dying at night" | nur 6 Ursachen (`core:431`), nicht Rudelvater-Zweitopfer, Voodoo-Puppe, Kartenschlucker, Verdammniswächter, Prophet, Blutpriester, Ketten-/Liebestod | wie Legacy | 04 C: Liste als Regel übernommen (`triggers_knight`) | jeder Tod in der Nacht löst aus | nur Tode durch feindliche Nachtangriffe (Liste, ggf. erweitert um PACKFATHER_KILL) | A stärkt das Dorf deutlich (auch Kettentode schlagen zurück) | Ursachen-Attribut `triggers_knight` in beiden Fällen nötig, nur Belegung unterscheidet sich | B mit Ergänzung PACKFATHER_KILL und VOODOO_PUPPET, Text präzisieren | Ja |
| RM-C-133 | Verfluchter Dorfbewohner als Ziel | "Werwolf" | "werewolf" | `isWolf` zählt `cursedWolfAura` (`core:18`), Ritter kann Verfluchten töten | wie Legacy | 04 Zeile 32 nennt den Ritter ausdrücklich als betroffen | nur echte Wölfe | alles, was als Wolf zählt | A schützt Verfluchte | Ziel über `counts_as_wolf` statt `appears_as` | hängt an Q1 Dämonischer Wolf; bei "nur Erscheinung" nur echte Wölfe | Ja |
| RM-C-134 | Fenrir ab Stufe 3 | nicht erwähnt | nicht erwähnt | wird übersprungen (`core:421`) | wie Legacy | nicht dokumentiert | Fenrir-Immunität gilt auch gegen Ritter | Ritter trifft Fenrir normal | gering | Sonderregel im Zielfinder | nach Fenrir-Entscheidung (07 Q1 Fenrir-Zeile) ausrichten | Ja |

### `rotkaeppchen`

Dossier: [village-3.md](dossiers/village-3.md#rotkaeppchen) · Entscheidung: RM-DR-137

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-135 | Wölfe als Zuflucht | "einem anderen Spieler" | "another player" | nur Nicht-Wölfe (`ab:24`) | wie Legacy | 04: "Verbindet sich mit Nicht-Wolf" | jede andere lebende Person | nur Nicht-Wölfe | A erlaubt Wolf-Apfel (Doppelkill?) und Wolf-Kette | Zielfilter | B (Code), Text ergänzen | Ja |
| RM-C-136 | Apfel-Wirkung | "nächste Fähigkeit wird doppelt ausgeführt" | "next ability is executed twice" | nur pick/multi-Fähigkeiten, sonst nie verbraucht | wie Legacy | 04 Zeile 48 pauschal, B-12 eingeschränkt | jede nächste Fähigkeit (auch Info) zweimal | nur Zielwahl-Fähigkeiten, sonst verfällt der Apfel | A wertet Info-Rollen stark auf | "repeat step" in StepQueue plus Verfall-Regel | eigene Regel: Apfel verfällt nach der nächsten eigenen Nachtaktion, Info-Rollen erhalten die Info zweimal oder gar nicht (entscheiden) | Ja |
| RM-C-137 | Dauer der Kette | offen | offen | bis zur nächsten angenommenen Zuflucht, übersteht Tage | wie Legacy | nicht dokumentiert | nur diese Nacht | bis zur nächsten gewährten Zuflucht | A schwächt Risiko deutlich | Bindungsobjekt mit Gültigkeit | B (Code) festschreiben | Ja |
| RM-C-138 | Ablehnung | "Gewährt er sie, ..." | "If he grants it, ..." | Nein ändert nichts, alte Kette bleibt | wie Legacy | nicht dokumentiert | Ablehnung löst alte Kette | alte Kette bleibt | gering | Bindung beenden oder nicht | entscheiden | Ja |
| RM-C-139 | Mehrfache Zuflucht beim Selben | "anderen Spieler" | "another player" | erlaubt | wie Legacy | nicht dokumentiert | jede Nacht ein anderer | beliebig | A verhindert Dauer-Apfel beim selben Spieler | Zielhistorie | entscheiden | Ja |

### `selbstmoerder`

Dossier: [solos-a.md](dossiers/solos-a.md#selbstmoerder) · Entscheidung: RM-DR-138

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-061 | Zählbasis | „sobald 5+ Tote sind" | „>=5 players are already dead" | 5 Tote vor dem Lynch | wie Legacy | 04: „vorher ≥ 5 Tote" | vorher (Code/EN) | inklusive eigenem Tod | B einen Tod früher | Zählpunkt | A, DE-Text präzisieren | Ja |
| RM-C-062 | Hinrichtungsarten | „gelyncht" | „lynched" | nur Lynch-Ziel | wie Legacy | – | nur Hauptziel des Lynchs | auch Henker-Hinrichtung | – | ExecutionRules | A | Ja |

### `kopfgeldjaeger`

Dossier: [village-3.md](dossiers/village-3.md#kopfgeldjaeger) · Entscheidung: RM-DR-139

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-140 | Wiederholung | je Lynch ("Sobald ... wird") | ab erstem Lynch ("Once ... has been") | bool je Nacht, mehrere Lynche vor einer Nacht = eine Info | wie Legacy | 04: "nach jedem Wolfs-Lynch" | eine Info pro Wolfs-Lynch (Zähler) | eine Info in der Nacht nach einem Wolfs-Lynch | A minimal stärker | Zähler statt bool | A (Zähler), Texte angleichen | Ja |
| RM-C-141 | Selbst unter den drei | "drei Spieler" | "three names" | Kopfgeldjäger kann sich selbst sehen | wie Legacy | nicht dokumentiert | drei andere Spieler | beliebige lebende | A gibt mehr Info | Filter `id != actor` | A | Ja |
| RM-C-142 | Aktivierung durch Erbe | Auslöser Lynch | Auslöser Lynch | Erbe/Tausch aktiviert sofort (`core:354`) | wie Legacy | 01 Zeile 222 nennt nur die Flag-Inkonsistenz | nur Lynch aktiviert | Erbe startet aktiv | B schenkt Info | Rollenwechsel mit frischen Einsätzen ohne Aktivierung | A | Ja |
| RM-C-143 | Verfluchter als "Werwolf" | "Werwolf" | "werewolf" | `isWolf` inkl. `cursedWolfAura` bei Auslösung und Anzeige | wie Legacy | Q1 Dämonischer Wolf | nur echte Wölfe | Erscheinung zählt | hängt an Q1 | `counts_as_wolf` vs `appears_as` | nach Q1 | Ja |

### `koenig`

Dossier: [village-3.md](dossiers/village-3.md#koenig) · Entscheidung: RM-DR-140

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-144 | Häufigkeit | "Sobald ... in dieser Nacht" | "When ..." | jede Nacht (`night:234`) | wie Legacy | 04 unklar, 07 Q1 Vorschlag Code | einmal im Spiel | jede Nacht, solange Bedingung gilt | B ist in der Endphase sehr stark | Einsatzzähler vs. Nachtbedingung | 07-Vorschlag übernehmen oder A; Texte angleichen | Ja |
| RM-C-145 | Wer wird gezeigt | "einen Dorfbewohner" | "one living villager" | Zufall, rollenbasiert "dorf" | wie Legacy | nicht dokumentiert | SL/Zufall wählt echten Dorf-Angehörigen (Fraktion aktuell) | rollenbasiert (Legacy) | A verhindert Fehlinfo bei Wolfskind | `faction` aktuell statt Katalog | A, Zufall über SeededRng | Ja |
| RM-C-146 | Umfang der Info | "(und dessen Rolle)" | "identity" | Name + Rolle | wie Legacy | nicht dokumentiert | Name + Rolle | nur Name | gering | InfoRecord-Inhalt | DE-Formulierung auch im EN | Nein |

### `dr-victor-frankenstein`

Dossier: [village-3.md](dossiers/village-3.md#dr-victor-frankenstein) · Entscheidung: RM-DR-141

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-147 | Rollenpool | "neue Rolle" | "brand new role" | nur nicht vergebene Rollen, inkl. Wolf/Solo, ohne Dorfbewohner falls vergeben | Dropdown fehlt, erste Rolle | 04: "freie Rolle" | jede Rolle außer der bisherigen | nur nicht im Spiel befindliche Rollen | Wolfsrolle stärkt ggf. Wölfe (Tag `creates-wolf`) | Katalogfilter, `max_copies` | B mit ausdrücklich erlaubtem Dorfbewohner; Wolfsrollen nur nach Entscheidung | Ja |
| RM-C-148 | Zustand des Wiederbelebten | nicht geregelt | nicht geregelt | nur 4 meta-Felder zurückgesetzt, Liebe/Gift/Kette bleiben | wie Legacy | 03 RoleTransition "frische Einsätze" | vollständiger Neustart des Sitzes (wie Kutscher) | Bindungen bleiben | A verhindert Sofort-Tod durch Liebeskummer | Wiederbelebungsmodell mit Reset-Liste | A | Ja |
| RM-C-149 | Einmaligkeit bei Erbe | "einmalig" | "Once" | global, Erbe setzt zurück | wie Legacy | 01 Zeile 222 | einmal pro Person | einmal pro Rolle im Spiel | A erlaubt 2 Wiederbelebungen | `ability_uses` pro Person | A (Godot-Standard) | Ja |
| RM-C-150 | Totenkarten-Aktivierung nach Verbrauch | nicht geregelt | nicht geregelt | lebender Frankenstein hält Wiederbelebungs-Karten aktiv, auch nach Nutzung | wie Legacy | nicht dokumentiert | nur solange Wiederbelebung noch möglich | solange die Rolle lebt | gering bis mittel | Tag-Abfrage mit Verbrauchszustand | A | Ja |

### `nekromant`

Dossier: [solos-b.md](dossiers/solos-b.md#nekromant) · Entscheidung: RM-DR-142

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-066 | Wen schützt der Schild | "nächste Tötung (beliebig)" | "next death of any kind" | jede Person, jede Ursache außer PACKFATHER_KILL (`core:127-133`) | keine Logik | 04: widersprüchlich; 07: Vorschlag nur selbst | globaler Schild für die nächste Tötung irgendwo | Schild nur für den Nekromanten, jede Todesart | global: Nekromant kann Wolfskill auf beliebige Person verhindern (Dorf-nahe Macht), auch Lynch am Tag | global braucht globalen Modifikator in der KillPipeline; selbst passt in Protections | PO entscheidet; Text so oder so präzisieren | Ja |
| RM-C-067 | Umlenkung optional oder Pflicht | "kann ... alternativ" | "may instead" | zwingend bei >=3 freien Toten, kein Ablehnen, Abbruch hängt Auflösung auf (`night:365-379`, `ui:340`) | keine Logik | 04: Pflicht-Umlenkung | optional (Text) | Pflicht (Code) | Pflicht zwingt Nekromanten, einen Mitspieler zu töten | PendingPrompt mit "nicht umlenken" | Text gilt: optional mit Verzicht | Ja |
| RM-C-068 | Ressource der Toten | Schild: "drei Stimmen opfern"; Umlenkung: "drei Tote wählen" | "spend three votes" / "sacrifice three dead players" | zwei getrennte Listen (`deadVoteStripped` vs `TotenratFuehrerSilenced`), gegenseitig nicht ausschließend | zeigt beide Listen, verschieden benannt | nicht dokumentiert | ein gemeinsamer Vorrat "Stimme der Toten" | zwei getrennte Vorräte | getrennt: doppelte Nutzung derselben Toten | Statusmarker pro Toter: ein oder zwei Felder | ein gemeinsamer Marker "geopfert" | Ja |
| RM-C-069 | Siegversuche | "korrekt benennt" | "correctly names" | unbegrenzt, Fehlversuch folgenlos (`gh:547-556`) | keine Logik | 04: "ohne Einschränkung" | beliebig viele Versuche | ein Versuch pro Tag oder pro Spiel, evtl. mit Strafe | unbegrenzt: Solo-Sieg praktisch sicher durch Durchprobieren | Versuchszähler und Tagesaktion | Begrenzung festlegen | Ja |
| RM-C-070 | Übungs-Enthüllung | nicht erwähnt | nicht erwähnt | Button mit Folge "Wölfe wissen, wer du bist" (`gh:531-546`) | Marker "revealed" | nicht in 04 | streichen | als Regel übernehmen und Text ergänzen | unklar, derzeit nur Hinweis | eigener Tagesbefehl | streichen, sofern keine Regelquelle existiert | Ja |

### `kartenschlucker`

Dossier: [solos-b.md](dossiers/solos-b.md#kartenschlucker) · Entscheidung: RM-DR-143

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-071 | Zusatzkräfte Kill/Schild/Ansage | nur Stapel und Sieg | nur Stapel und Sieg | Kill ab 2 jede Nacht, Schild ab 5, Ansage jede 3. Nacht (`chunk:222-237`) | keine | 04: widersprüchlich; 07: offen | reine Sammelrolle (Text) | Sammelrolle mit Eskalationsstufen (Code) | Code macht die Rolle ab 2 Stapeln zum Nachtmörder mit Schneeballeffekt (mehr Tote, mehr Tauschmöglichkeiten) | Code-Variante braucht Kill, Schild, Ansage zusätzlich | PO entscheidet; bei Beibehaltung Text ergänzen | Ja |
| RM-C-072 | Wer darf tauschen | "ein Toter" | "a dead player" | jeder Tote inkl. Wölfe, einmal je Karte, freiwillig (`help:169-184`) | keine | nicht dokumentiert | jeder Tote frei | nur Nicht-Wölfe oder nur einmal pro Person | Wölfe können Solo-Sieg beschleunigen oder bewusst verhindern | Regel im Totenkarten-Assistenten | Text präzisieren | Ja |

### `hades`

Dossier: [solos-b.md](dossiers/solos-b.md#hades) · Entscheidung: RM-DR-144

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-073 | Sieg automatisch oder eingelöst | "gewinnt bei 10 Lichtern" | "wins at 10 lights" | beides: Automatik (`core:210`) und Einlöse-Button, der 10 Lichter kostet (`ab:50-54`) | nur Titel | 04: "auch automatisch" | Sieg sofort bei 10 | Sieg nur durch bewusstes Einlösen (Lichter könnten vorher ausgegeben werden) | Einlösen erlaubt Taktik (Lichter sparen/ausgeben) | eine Siegregel als WinCandidate | Automatik bei 10 mit SL-Bestätigung, Button streichen | Ja |
| RM-C-074 | Zählen eigene Kills | "Sammelt Lebenslichter von Toten" | "from the dead" | jeder Tod inkl. eigener Kills (`core:209-210`) | keine | nicht dokumentiert | jeder Tod zählt | nur Tode durch andere | Kill kostet netto 1 statt 2 | Filter nach Quelle | PO | Ja |
| RM-C-075 | Stimme x3 | nicht erwähnt (nur "Kauft Fähigkeiten") | nicht erwähnt | Flag ohne Wirkung und ohne Anzeige | keine | 04: "Stimmbonus fehlend"; DECISION-LOG: Stimmen physisch | Kauf bleibt, SL wird erinnert | Kauf streichen | Kauf ohne Anzeige ist wertlos | dauerhafter Statusmarker mit Hinweis beim Tag | Marker sichtbar machen | Ja |

### `doktor`

Dossier: [village-3.md](dossiers/village-3.md#doktor) · Entscheidung: RM-DR-145

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-151 | Zwei Solo-Rollen | "demselben Team" | "the same team" | zwei Solos = gleiches Team | wie Legacy | nicht dokumentiert | Solos bilden kein Team (immer "verschieden", auch mit sich selbst) | "Solo" ist ein Team | A verhindert Fehlschluss | Vergleich über Siegpartei statt Fraktionskonstante | A | Ja |
| RM-C-152 | Verwandlung / Fluch | "Team" | "team" | Startrolle zählt (Wolfskind nach Verwandlung = Dorf) | wie Legacy | 04 dokumentiert es als Ist | aktuelle Fraktion | Katalogfraktion (Legacy) | A macht den Doktor zum Verwandlungs-Detektor | `faction` am Player (RoleTransition) statt Katalog | A (Godot hat `faction` am Player) | Ja |

### `faehrtenleser`

Dossier: [village-3.md](dossiers/village-3.md#faehrtenleser) · Entscheidung: RM-DR-146

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-153 | Freiwilligkeit | "darf einmal im Spiel" | "may once per game" | jeder Aufruf verbraucht, SL-Assistent ruft automatisch auf | wie Legacy | 04: "Einmal" | Spieler entscheidet jede Nacht Ja/Nein | automatisch beim ersten Aufruf | A ist deutlich stärker (Zeitpunkt wählbar) | Ja/Nein-Stufe im Prompt, Verbrauch erst bei Ja | A | Nein |
| RM-C-154 | Richtungsdefinition | "links oder rechts" (aus seiner Sicht) | "left or right" | links = höhere Sitznummer | wie Legacy | 04 Zeile 57 | aus Sicht des Spielers am Tisch | aus Sicht des SL-Bildschirms | Fehlinfo bei falscher Deutung | Richtung relativ zu `seat_order` (Uhrzeigersinn) festlegen | am Tisch prüfen und festschreiben | Ja |
| RM-C-155 | Gleichstand | nicht geregelt | nicht geregelt | ein Wolf gegenüber: "links"; zwei gleich weite Wölfe: abhängig von Sitznummer | wie Legacy | 04: "Gleichstand = links" (unvollständig) | fest links | beide Richtungen nennen / SL wählt | gering | Regel im Rechner | entscheiden | Ja |
| RM-C-156 | Fenrir Stufe 3 | nicht geregelt | nicht geregelt | zählt als Wolf (Ritter nicht) | wie Legacy | nicht dokumentiert | gleiche Wolfsdefinition wie Ritter | unterschiedlich | gering | eine gemeinsame Zielfunktion | angleichen | Ja |

### `waldlaeufer`

Dossier: [village-3.md](dossiers/village-3.md#waldlaeufer) · Entscheidung: RM-DR-147

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-157 | Häufigkeit | nicht genannt | nicht genannt | jede Nacht | wie Legacy | 04 ohne Angabe | jede Nacht | einmal (z. B. Nacht 1) | jede Nacht ist stark in Akt IV | Schritt jede Nacht vs. Einmal-Einsatz | entscheiden und in Text aufnehmen | Ja |
| RM-C-158 | Verfluchte zählen | "Werwölfe" | "werewolves" | `cursedWolfAura` zählt | wie Legacy | Q1 Dämonischer Wolf | nur `counts_as_wolf` | auch Erscheinung | hängt an Q1 | Zählung über `counts_as_wolf` | nach Q1 | Ja |

### `schutzgeist`

Dossier: [village-4.md](dossiers/village-4.md#schutzgeist) · Entscheidung: RM-DR-148

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-159 | Dauer/Wirkung des Schilds | "erhält ein Schutzschild" | "receives a shield" | Schutz nur beim Wolfs-Pick, gelöscht bei Nachtbeginn; Schutzgeist agiert nach dem Rudel | Adapter | 04: "einmal einen Spieler schützen"; Alttext: "from the next attack" | Schild hält bis zum nächsten Wolfsangriff (auch spätere Nächte) | Schild gilt nur für die aktuelle Nacht, Schritt muss dann vor dem Rudel liegen | A stärker, B ohne Umordnung wirkungslos | A: dauerhafter Marker; B: Schrittposition vor Rudel | A (deckt Alttext, macht Rolle spielbar) | Ja |
| RM-C-160 | Schutzart | "Schutzschild" | "shield" | nur Rudelangriff (Werwolf, Rachsüchtiger) | Adapter | Godot-Protections nur gegen Rudel-NIGHT_KILL | nur Wolfsangriff | jeder Tod | A schwächer | A nutzt vorhandene Protections | A | Ja |
| RM-C-161 | Zeitpunkt | "in der Nacht nach ihrem Ableben" | "On the night after their death" | ab Setzen des Flags jederzeit, auch dieselbe Nacht | Adapter | – | frühestens nächste Nacht | sobald tot, auch dieselbe Nacht | gering | Schrittfreigabe mit Nachtindex | A (Textwortlaut) | Ja |
| RM-C-162 | Wolf-Meldung | "erfährt das Dorf davon" | "the village is told" | öffentlich ohne Namen; `isWolf` inkl. verfluchter Sitze | Adapter | – | nur Tatsache, ohne Namen, echte Fraktion | mit Namen / nach Erscheinung (`appears_as`) | Name wäre starke Info | InfoRecord public, Quelle Wahrheit oder Erscheinung | A ohne Namen, Wahrheit | Ja |

### `waechter-am-tor`

Dossier: [village-4.md](dossiers/village-4.md#waechter-am-tor) · Entscheidung: RM-DR-149

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-163 | Gilt der Dämonische-Wolf-Fluch als "neu entstehender Werwolf"? | "neu entstehende Werwölfe" | "new werewolves" | nicht abgefangen, aber `isWolf` zählt Verfluchte als Wolf | Adapter | 04:61 Q1: Verfluchter "erscheint" nur | Fluch ist nur Erscheinung, Wächter irrelevant | Fluch erzeugt echten Wolf, Wächter muss abfangen | bei B stärker für Dorf | A: appears_as; B: zusätzlicher Abfangpunkt | A (folgt 07-Vorschlag "nur Erscheinung") | Ja |

### `zeitwaechter`

Dossier: [village-4.md](dossiers/village-4.md#zeitwaechter) · Entscheidung: RM-DR-150

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-164 | Umfang des Abbruchs | "alle Nachtaktionen dieser Nacht werden abgebrochen" | "all night actions are canceled" | nur Morgenopfer und spätere Dorf/Solo-Schritte; Sofort-Tode, Witwe, Giftwolf, Märtyrerin, Zustände bleiben | Adapter | 04/07: nur Wolfstode | Gesamte Nacht wird zurückgerollt (Tode und Zustände) | Nur Tode dieser Nacht entfallen, Zustände bleiben | A sehr stark, B stark | A: Nacht-Transaktion mit Schnappschuss ab Nachtbeginn; B: alle Tode der Nacht aufschieben bis Morgen | A mit Schnappschuss bei Nachtbeginn (RoleTransition-Schnappschuss-Idee) oder B nach 07 | Ja |
| RM-C-165 | Zeitpunkt der Entscheidung | "Kann ... eine Nacht einfrieren" | "may freeze a night" | Schritt ganz am Ende (9.5), nach allen Aktionen | Adapter | – | Entscheidung am Nachtanfang, dann läuft keine Aktion | Entscheidung am Nachtende, alles wird zurückgenommen | A spart Zeit, B gibt Zeitwächter Zusatzwissen (sieht keine Nachtergebnisse, aber SL weiß sie) | A: Schritt vor tier 0.1; B: Rücknahme nötig | A (einfacher, fairer) | Ja |
| RM-C-166 | Zähler | "Die Nacht gilt als nicht stattgefunden" | "treated as though it never happened" | nur nightCount bleibt; MorningCount, Fenrir, Cerberus, Schmied, Cooldowns laufen | Adapter | – | alle nachtabhängigen Zähler zurück | nur Nachtnummer | Todesprediger, Schmied, Fenrir betroffen | Zähler-Liste in Nacht-Transaktion | A | Ja |
| RM-C-167 | Wolfsrollen | "alle Nachtaktionen" | "all night actions" | Wölfe werden nicht blockiert | Adapter | 04 B-6 | auch Wölfe | nur Nicht-Wölfe | gering | Blockadegrund pro Schritt | A | Ja |

### `amalia`

Dossier: [village-4.md](dossiers/village-4.md#amalia) · Entscheidung: RM-DR-151

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-168 | Zeitpunkt | "öffentlich eine Ja-/Nein-Frage" (kein Zeitpunkt) | "publicly ask" | Nachtschritt tier 5.8 | Adapter | 04: Nachtrolle | Tagesaktion (öffentlich, alle wach) | Nachtschritt, Frage wird am Morgen verkündet | A: Frage wirkt sofort in Diskussion | A: Tagesaktionswarteschlange; B: verzögertes Ereignis | A | Ja |
| RM-C-169 | Frage und Antwort | "um öffentlich eine Ja-/Nein-Frage zu stellen" | gleich | Frage wird nicht erfasst; Schlüssel `amaliaPromptQuestion`/`amaliaPublicQuestion` unbenutzt | Adapter | 04: nicht erwähnt | SL beantwortet wahrheitsgemäß, App protokolliert Frage und Antwort | Frage rein mündlich, App nur Opfer | A: nachvollziehbar | A: PendingPrompt mit Freitext + Ja/Nein; InfoRecord | A | Ja |
| RM-C-170 | Schwelle | "mehr als zwei Werwölfe im Spiel" | "more than two werewolves are in play" | `>2` lebende `isWolf` inkl. Verfluchte | Adapter | Alttext tools/create_role_doc.py: "2+" | >2 lebende echte Wölfe | >=2 (Alttext) oder inkl. toter ("im Spiel") | Verfügbarkeit | Zählung über Fraktion, ohne Erscheinung | >2 lebende echte Wölfe | Ja |

### `kriegerin-des-lichts`

Dossier: [village-4.md](dossiers/village-4.md#kriegerin-des-lichts) · Entscheidung: RM-DR-152

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-171 | Stirbt ein getroffener Wolf? | "Greift ... direkt an" | "attacks directly" | Nein, nur Meldung | Adapter | 04: "Wolf → er stirbt" | Angriff tötet den Wolf | Angriff ist nur Test, Wolf wird nur erkannt | A sehr stark (sicherer Wolfskill mit Risiko) | A: KillPipeline-Ursache, Reaktionen | Entscheidung nötig; 04 korrigieren | Ja |
| RM-C-172 | Wahrheitsquelle | "Der Spielleiter sagt" | "moderator reveals" | SL antwortet frei | Adapter | – | App prüft Fraktion automatisch | SL entscheidet (kann Erscheinung berücksichtigen) | A verhindert SL-Fehler | A: Fraktion oder appears_as | A mit Wahrheit, appears_as nur falls gewünscht | Ja |
| RM-C-173 | Öffentlichkeit | "sagt" | "reveals" | SL-Modal | Adapter | – | geheim an Kriegerin | öffentlich | B starke Dorfinfo | Sichtbarkeit actor vs public | nach PO | Ja |

### `detektiv`

Dossier: [village-4.md](dossiers/village-4.md#detektiv) · Entscheidung: RM-DR-153

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-174 | Muss der Detektiv leben? | kein Hinweis | kein Hinweis | ja | Adapter | 04: nicht erwähnt | nur lebend | auch tot | B stärker | Bedingung am Hook | A (Code) | Ja |
| RM-C-175 | Mindestens 2 lebende Wölfe | "Hinweis auf einen anderen Wolf" | "about another wolf" | nach Tod ≥2 lebende Wölfe | Adapter | 04: ≥2 | ≥1 anderer lebender Wolf genügt | ≥2 (Code) | bei A Hinweis auf letzten Wolf, sehr stark | Schwelle | nach PO | Ja |
| RM-C-176 | Hinweisinhalt | "ein Hinweis" | "a clue" | nennt zufälligen lebenden Wolf als Bezug (enttarnt ihn) oder unbelegte Parität | Adapter | 02: "links neben Dora" | Hinweis bezieht sich auf den toten Wolf (Sitz des Toten als Anker) | Hinweis enttarnt Wolf w indirekt (Code) | B deutlich stärker, A moderat | Anker und Richtungsregel | A, und Parität nur wenn wahr | Ja |
| RM-C-177 | Richtung links/rechts | – | – | links = id-1 | Adapter | Fährtenleser: links = höhere Nummer | einheitlich id-1 | einheitlich id+1 | keine | Sitznachbarschaft mit einer Konvention | eine Konvention für alle Rollen | Ja |

### `dorfschmied`

Dossier: [village-4.md](dossiers/village-4.md#dorfschmied) · Entscheidung: RM-DR-154

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-178 | Welche Nächte zählen | "Schmiedet fünf Nächte lang" | "over five nights" | nur Nächte mit lebendem Schmied, Nacht 1 je nach Startweg | Nacht 1 zählt | 04: "Ab 6 Nächten" | globale Nachtnummer 6 | eigene Schmiedenächte | gering | Zähler vs. Nachtnummer | A (einfach, eindeutig) | Ja |
| RM-C-179 | Nur Nacht 6 oder ab Nacht 6 | "In der sechsten Nacht" | "On the sixth night" | ab Nacht 6 jede Nacht | Adapter | 04: "Ab 6" | nur Nacht 6 | ab Nacht 6 | A strenger | Schrittfreigabe | B (Code) | Ja |
| RM-C-180 | Welche Angriffe | "einen Wolfsangriff" | "one wolf attack" | nur Morgenopfer über `targeted`, auch durchbohrende | Adapter | 04 C.1 | alle Wolfsangriffe inkl. durchbohrend | durchbohrende ausgenommen | gering | Filter `is_wolf_attack` | A (Code) | Ja |

### `doppelspion`

Dossier: [solos-a.md](dossiers/solos-a.md#doppelspion) · Entscheidung: RM-DR-155

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-063 | Muss er leben? | „wenn alle Werwölfe tot sind" | „when all werewolves are dead" | nur lebend | wie Legacy | 04: „wenn er lebt" | nur lebend (Code) | auch tot | B macht ihn stärker | WinCandidate | A, Text präzisieren | Ja |
| RM-C-064 | Parität | – | – | zählt als Nicht-Wolf | – | 04 D-2: Solos zählen als Nicht-Wölfe | Nicht-Wolf | neutral (zählt für keine Seite) | A lässt Wölfe schwerer gewinnen | `counts_as_wolf=false` | A | Ja |
| RM-C-065 | Aufwachen | „Wacht gemeinsam mit den Werwölfen auf" | „Wakes up together with the werewolves" | kein App-Schritt | – | – | Hinweis im Rudelschritt | reine Tischregel | – | StepQueue-Hinweis | A | Nein |

### `grabraeuber`

Dossier: [solos-b.md](dossiers/solos-b.md#grabraeuber) · Entscheidung: RM-DR-156

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-076 | Was bedeutet "Fähigkeit stehlen" | "Fähigkeit ... stehlen" | "steal the ability" | nur Notiz, SL setzt um (`chunk:587-589`) | keine | 04: fehlend | Grabräuber erhält dauerhaft die Nachtfähigkeit der toten Rolle (inkl. Nachtschritt) | einmalige Nutzung der Fähigkeit | groß: je nach Zielrolle (z.B. Waldhexe, Hades) stark unterschiedlich | Fähigkeitsübertragung ist ein neues System; Rollenwechsel (RoleTransition) passt nicht, da Rolle/Fraktion bleiben sollen | PO; bis dahin manuell | Ja |
| RM-C-077 | Siegbedingung | "Gewinnt alleine" ohne Bedingung | "Wins alone" | keine | keine | 04/07 Q4: fehlend | erbt die Siegbedingung der bestohlenen Rolle | eigene Bedingung (z.B. letzter Überlebender) | ohne Bedingung ist die Rolle nicht gewinnbar | zusätzliche Siegbedingung | PO legt fest (Q4) | Ja |

### `parasit`

Dossier: [solos-b.md](dossiers/solos-b.md#parasit) · Entscheidung: RM-DR-157

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-078 | "Final 3" und Siegvorrang | "Gewinnt, wenn er die Final 3 erreicht" | "reaches the final three" | genau 3 Lebende, nur wenn weder Dorf- noch Wolfssieg vorliegt (`core:227-237`) | keine | 04: verifiziert | Parasit gewinnt bei <=3 Lebenden immer (ggf. gemeinsam mit anderen) | wie Code, Team-Siege zuerst | Code: Parasit + 2 Dorf ohne Wölfe => Dorfsieg; Parasit + 2 Wölfe => Wolfssieg | Siegpriorität in WinRules (Q4) | PO mit Q4 | Ja |

### `todesprediger`

Dossier: [solos-b.md](dossiers/solos-b.md#todesprediger) · Entscheidung: RM-DR-158

| ID | Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance | Implementierung | Empfehlung | PO |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-C-079 | Öffentlich oder geheim | "Kündigt an" | "Predicts" | geheim, nur SL | keine | nicht dokumentiert | öffentliche Ankündigung | geheime Vorhersage beim SL | öffentlich: Dorf/Wölfe können gezielt töten oder schonen | Ereignis-Sichtbarkeit public vs gm | PO | Ja |
| RM-C-080 | Zeitpunkt der Vorhersage | nicht genannt | nicht genannt | beliebige Nacht, einmal | keine | NIGHT-REPORT: 1. Nacht | nur Nacht 1 | jederzeit einmal | spätes Vorhersagen ist deutlich leichter | Schritt nur Nacht 1 oder dauerhaft | Nacht 1 (sonst trivial) | Ja |
| RM-C-081 | Zählbasis Tag/Nacht | "in welcher Nacht oder an welchem Tag" | "exact night or day" | Nacht = `nightCount`, Tag = `MorningCount`, überschneidend | keine | 04 D-3 unklar | Tag N = Tag nach Nacht N, Morgentode zählen zur Nacht | Tag N wie im Protokoll angezeigt (= nach Nacht N-1) | Überschneidung verdoppelt Trefferchance bei Morgentoden | eindeutige `night_number`/`day_number` und Zuordnung jedes Todes zu genau einer Phase | Tode der Morgenauflösung zählen zur Nacht; Anzeige und Vergleich dieselbe Zahl | Ja |

## 4. Legacy-Bugs

Grundsatz aus dem Decision Log: **Bekannte Bugs werden nicht als Referenzverhalten portiert.** Ein Eintrag gilt hier nur dann als „echter Bug“, wenn ein Codepfad das falsche Verhalten belegt und Text oder Entscheidung das richtige Verhalten festlegen. Alle anderen Abweichungen sind „unklare Regel“ oder „technische Altlast“.

### 4.1 Rollenübergreifende Bugs

| ID | Einstufung | Codepfad | Tatsächliches Verhalten | Erwartet | Risiko | Regressionstest (für Godot) |
|---|---|---|---|---|---|---|
| X-01 (F2) | echter Bug | `js/core/night.js:50-55` (`WOLF_KILL_ROLES`) | Lebt kein `Werwolf` und nur Wölfe außerhalb der Liste (Siegreicher Wolf, Seuchenwolf, Schicksalswolf, Schattenwanderer, Giftwolf, Rudelvater, Schwarze Witwe, Schattenhund), fehlt der Rudelschritt. Selbst geprüft. | Rudelschritt, solange irgendein Wolf lebt (Register G-PH-6) | hoch | Nur Siegreicher Wolf + 4 Dorf → Nachtplan enthält `pack` (in Godot bereits erfüllt, pro neuer Wolfsrolle wiederholen) |
| X-02 | echter Bug | `game.html:512-529` `clearRolesNewRound`, Kopie `app/public/legacy-bridge.js:34-51` | „Neue Runde“ übernimmt `seat.meta` (`loverId`, `shadowSwapPartnerId`, `giftwolfDieOnMorning`, `ritterRetaliated`, `rkLink`, `appleBuff`, `lastKillCause`) und mehrere `once`-Felder (`GiftwolfUses`, `FateWolfExtraIds`, `SchmiedWeaponGiven`, `ChroniclerShown`, `SchutzgeistAwaitingPick`, `TimekeeperFreezeMorning`, `WidowMorningKills`, `_besessenerDraining`, `SchattenhundBlocked`) | neue Runde ohne Altzustand | mittel | `StartGame` erzeugt einen vollständig frischen Zustand; Test: kein rollenbezogenes Feld aus Runde 1 im Zustand von Runde 2 |
| X-03 | echter Bug | `js/ui/ui.js:315,325,340` (`startPick`/`startMulti` ohne `onCancel`) | Abbruch einer Pflichtwahl in der Morgenauflösung (Nekromant-Umlenkung, Dämonischer Wolf, Besessener Wolf) beendet die Auflösung ohne Fortsetzung; beim Besessenen bleibt `_besessenerDraining` dauerhaft gesetzt | Abbruch ist definiert (Verzicht oder erneutes Öffnen), Auflösung läuft weiter | hoch | Reaktion mit offener Wahl: Save/Load und Abbruchversuch → Reaktion bleibt offen, kein Folgeschritt geht verloren (Godot: Reaktionen nicht abbrechbar, bereits getestet für `curse`) |
| X-04 (F7) | echter Bug | `js/ui/core.js:85-100` (`triggerWin` ohne Guard), fünf Siegprüfstellen | Spätere Prüfung überschreibt einen bereits gesetzten Sieger (z. B. Selbstmörder-Zweig `night.js:476`, Hades-Einlösen, Todesprediger, Parasit) | Kandidatenmenge, Spielleiter bestätigt (DR-02, DR-14) | hoch | Je neuer Siegbedingung: gleichzeitige Kandidaten mit Dorf/Wölfen, kein Überschreiben |
| X-05 (F14) | echter Bug | `js/core/night.js:374,394` | `killedTonight` enthält Überlebende; Seuchenwolf-Verbrauch, Voodoo-Abklingzeit, Brand-Nachbarn, Dämonen-Fluch reagieren auf nicht eingetretene Tode | nur tatsächliche Tode | mittel | Pro Todesfolgen-Rolle: abgefangener Angriff löst keine Folge aus |
| X-06 (F6) | echter Bug | `game.html:429` (Tot-Chip) | manueller Tod umgeht `applyKill` und alle Todesfolgen | Tod durch Korrektur mit bewusster Wahl der Folgen | mittel | in Godot erfüllt (`GmCorrection kill` mit `trigger_effects`); pro Rolle mit Todesfolge Test mit und ohne Folgen |
| X-07 | echter Bug | `js/core/abilities.js:107` (`APPLE_RESET_FLAGS`, Schlüssel `"Chronist"`) | Rotkäppchen-Apfel setzt die Dorfchronistin nie zurück | Schlüssel `Dorfchronistin` | niedrig | nur relevant, wenn `rotkaeppchen` und `dorfchronistin` umgesetzt werden |
| X-08 | technische Altlast | `js/ui/audio.js:12` (`queueSfxKey` = No-op) | Rollen, deren einzige Ausgabe ein Sound ist, wirken nicht (Nachtwächter-Alarm) | sichtbare, protokollierte Ausgabe | hoch für `nachtwaechter` | Nachtwächter-Alarm als öffentliches Ereignis |
| X-09 | technische Altlast | `game.html:813-843`, `app/src/roleCard.ts:19-92` (`CARD_MAP_EN`, 71 Einträge) | EN-Karte des Rachsüchtigen Wolfs fehlt im Mapping | 72 Einträge | niedrig (nur Anzeige) | Content-Lint: jede Rollen-ID hat DE- und EN-Kartenbild |
| X-10 | technische Altlast | `js/ui/core.js:8-19`, zahlreiche Handler | Einzigartigkeit per `seats.find(role)`: bei zwei Kopien handelt nur die erste | Handlung je Person | mittel | pro Rolle „mehrere Kopien“ (siehe `07`) |

### 4.2 Bugs je Rolle

Einstufung je Eintrag wie im Auftrag: **echter Bug** (nur mit Codepfad belegt), **unklare Regel**, **technische Altlast**. Jeder Eintrag nennt Codepfad, tatsächliches und erwartetes Verhalten, Risiko und Regressionstest. Die Texte stammen aus der Code-Lektüre der Dossiers und sind unverändert übernommen.

#### `loki`

- B-LOKI-1 (technische Altlast / echter Bug für Schwarze Witwe): `gh:512-518` `clearRolesNewRound` setzt `meta.loverId` nicht zurück (nur `rivalId`). Tatsächlich: nach "Neue Runde" bleibt `loverId` stehen; Schwarze Witwe (`chunk:453`) findet dann ein Paar über veraltetes `loverId`, auch ohne Loki-Nutzung in dieser Runde. Erwartet: neue Runde ohne Bindungen. Risiko mittel (nur mit Witwe). Test: Runde 1 Loki verliebt A,B → Neue Runde → Witwe wählt A → darf kein Paar finden.
- B-LOKI-2 (unklare Regel): Frankenstein-Wiederbelebung eines an Liebeskummer Gestorbenen führt zum erneuten Tod beim nächsten `postDeathHooks` (`chunk:57`, `core:378-383`). Erwartet laut Text offen. Test: A,B verliebt, A stirbt, B stirbt mit; Frankenstein belebt B → nächste Todesverarbeitung: B stirbt erneut (Legacy) vs. Bindung gelöst (Entscheidung).
- B-LOKI-3 (technische Altlast): Kette hängt an globalem `isOnceUsed("Loki")` (`core:367`); der Button "resetOnce" (`gh:558`, `Used={}`) schaltet die Kette mitten im Spiel ab und gibt Loki eine zweite Nutzung. Test: Save mit Liebenden → Once-Reset → Tod A → B muss trotzdem sterben (Godot: Bindung ist Zustand, nicht Einsatzzähler).

#### `nachtwaechter`

- B-NW-1 (technische Altlast mit Funktionsverlust): `night:559` + `audio.js:12`: einzige Ausgabe ist ein stummgeschalteter SFX. Tatsächlich: Rolle hat keine beobachtbare Wirkung. Erwartet: öffentlicher Alarm. Risiko hoch für Spielgefühl. Test: Nachbar ist Wolf, Morgen → Ereignis `night_warden_alarm` mit Sichtbarkeit public.
- B-NW-2 (unklare Regel): Auswertung schon beim Witwen-/Giftwolf-Morgentod (`night:197`, `night:208-210`) vor den Wolfstoden; Ergebnis kann von der Todesreihenfolge abhängen. Test: Witwen-Tod und Wolfstod am selben Morgen, Nachbar stirbt durch Wolf → Alarm ja/nein festlegen.

#### `die-gebundenen`

- B-GEB-1 (technische Altlast): Anzeige-Text "Erste Nacht" (`i18n:302`) bei verspätetem Aufruf falsch. Risiko niedrig. Test: Schritt in Nacht 1 übersprungen → Soll: Schritt entfällt ab Nacht 2 (oder Text korrekt).

#### `rattenfaenger`

1. Echter Bug · Sieg nach Tod nicht erkannt · `core:275-285` wird nur aus `chunk:659,670` aufgerufen. Tatsächlich: Letzter Unverzauberter stirbt, kein Sieg; ggf. nie erkennbar (leere Zielmenge, `ui:340`). Erwartet laut Text („Sobald"): Sieg sofort. Risiko hoch (häufiger Fall, Wölfe töten gezielt Unverzauberte). Regressionstest: 5 Lebende, 3 verzaubert, 1 unverzaubert + Rattenfänger; Wölfe töten den Unverzauberten → Siegkandidat Rattenfänger am Morgen.
2. Echter Bug (Bedienung) · `startMulti` ohne Abbruch bei weniger gültigen Zielen als gewählt (`ui:340`), z. B. „2 Ziele" bei nur 1 Unverzaubertem. Tatsächlich: Pick hängt, SL muss anderen Schritt starten. Erwartet: Abbruch oder Begrenzung. Test: 1 gültiges Ziel, Option „2" → Prompt nicht startbar oder abbrechbar.
3. Technische Altlast · Mehrfachnutzung pro Nacht ohne Guard (`chunk:645-676`). Test: zweite Aktion in derselben Nacht wird abgelehnt.

#### `die-ewigen`

- B-EW-1 (unklare Regel): tote Sitze und Selbstwahl erlaubt (`chunk:253` ohne `allow`). Test: Ewige wählen Toten → Soll festlegen (Legacy: erlaubt).
- B-EW-2 (echter Bug gegenüber Text): Info enthält Rollennamen (`chunk:256`), Text verspricht nur die Prüfung. Risiko mittel (Informationsleck). Test: Ziel Hades → Ergebnis enthält nur `true`.

#### `spuerhund`

- B-SH-1 (echter Bug gemessen an Konvention `CLAUDE.md` "Wolf-Zugehörigkeit NUR über WOLF_ROLES_SET + flags.werewolf"): `chunk:268` nutzt `getFaction(s.role)` statt `isWolf`. Tatsächlich: verwandeltes Wolfskind ergibt ❌. Erwartet: ✅. Risiko mittel. Test: Wolfskind mit totem Vorbild (`flags.werewolf=true`) unter 3 Zielen → true.
- B-SH-2 (unklare Regel): Markierung kann Spürhund selbst, bereits markierte oder echte Wölfe treffen (`chunk:274-276`). Test mit festem Seed: Ergebnis-ID deterministisch und aus erlaubter Menge.
- B-SH-3 (technische Altlast): `Math.random` statt Seed; erneutes Öffnen würfelt neu. Test: Replay bytegleich.

#### `rachsuechtiger-wolf`

- technische Altlast: `chunk:162` Werwolf-Handler setzt bei jedem (erneuten) Klick alle `targeted=false`; wird die Rudelzeile nach dem Rachsüchtigen erneut bedient, verschwindet dessen Ziel still. Erwartet: getrennte Ziellisten. Risiko mittel. Test: Rachsüchtiger wählt Wolf A, danach Rudel erneut → A bleibt Ziel.
- unklare Regel: Rachsüchtiger ignoriert Seuchenwolf-Durchdringung (`chunk:348`), sein `NIGHT_KILL` setzt aber die Seuchenwolf-Durchdringung zurück (`night:338`). Test: Durchdringung aktiv, nur Rachsüchtiger tötet → Flag-Verhalten festlegen.
- unklare Regel: Waldhexe/Verdammniswächter sehen bei zwei Zielen nur das erste nach Sitzreihenfolge (`chunk:209,727`).

#### `koenig-lykaon`

- unklare Regel: Tarnzeile wird auch gesetzt, wenn der Wächter am Tor die Verwandlung in "Dorfbewohner" umlenkt (`chunk:385-388`). Test: Wächter lebt, Lykaon wählt Schutzengel → Sitz ist Dorfbewohner; Tarnzeile ja/nein laut Entscheidung.
- unklare Regel: Wählt Lykaon den Wächter am Tor selbst, wird dieser zum Dorfbewohner (Wächter lebt zum Zeitpunkt der Prüfung, `core:31-33,45`).
- technische Altlast: Verbündeter wird nicht gespeichert (keine Nachvollziehbarkeit im Protokoll).
- technische Altlast: hartkodierte DE-Prompts ohne i18n-Schlüssel.

#### `siegreicher-wolf`

- echter Bug (fremde Rolle, Wirkung hier): F2, `night:50-55`. Lebt nur der Siegreiche Wolf (ohne Werwolf und ohne Rolle aus `WOLF_KILL_ROLES`), gibt es keine Rudel-Tötungszeile. Erwartet: Rudelschritt, solange irgendein Wolf lebt. Risiko hoch (Wölfe können nicht töten). Test: nur Siegreicher Wolf + 4 Dorf → Nachtplan enthält Rudelschritt.

#### `seuchenwolf`

- unklare Regel: Rücksetzung hängt an `lastKillCause` statt an einer Angriffsinstanz (`night:338`). Test: Durchdringung aktiv, Rudelopfer überlebt durch Hexe, Rachsüchtiger-Opfer stirbt → Flag gelöscht, obwohl der Rudelangriff scheiterte.
- technische Altlast: F14 (`night:394`) Überlebende in `killedTonight`. Test: wiederbelebter Sitz mit altem NIGHT_KILL überlebt Angriff per Schild → Flag darf nicht fallen.
- echter Bug (Randfall): ein Boolean für alle Kopien, gleichzeitiger zweiter Seuchenwolf-Tod geht verloren (`core:148` + `night:338`). Risiko niedrig.

#### `schicksalswolf`

- echter Bug (Randfall): `FirstThreeDeadIds` ohne Deduplizierung (`core:150`). Wiederbelebter Sitz, der erneut stirbt, belegt zwei Plätze. Test: A stirbt, wird wiederbelebt, stirbt erneut vor Tod Nr. 3 → Liste enthält A einmal.
- technische Altlast: `FateWolfExtraIds` wird bei "Rollen leeren" nicht zurückgesetzt (`gh:525`); nur relevant, wenn zwischen Wahl und Morgen neu gestartet wird.
- unklare Regel: Zusatzopfer ignorieren Schutzengel (`night:240-244` vs. `chunk:162`).

#### `schattenwanderer`

- echter Bug: `clearRolesNewRound` (`gh:517`, gleich `legacy-bridge.js:39`) behält `meta.shadowSwapPartnerId`. In der neuen Runde lenkt `applyKill` Tode weiter auf den alten Partnersitz um. Erwartet: Link gehört zur Partie. Risiko hoch (falsche Tode in Folgerunde). Test: Link A-B, Rollen leeren, neue Runde, A stirbt → A stirbt, B lebt.
- technische Altlast: Label `SHADOW_SWAP` (`ui:415`) wird nie gesetzt; Tod des Partners trägt die Originalursache (z. B. `NIGHT_KILL`), was Folgeregeln (Rudelvater, Ritter, Seuchenwolf-Verbrauch) wie einen direkten Angriff behandelt.
- unklare Regel: Lynch eines Verknüpften zählt als Hinrichtung (LynchCount, Henker, Log) obwohl der Gelynchte lebt (`night:499-500`).
- technische Altlast: Überlebender in `killedTonight` (F14, `night:394`), z. B. Dämonischer Wolf als Verknüpfter löst Fluch aus, obwohl er lebt (`night:285-289`).

#### `giftwolf`

- echter Bug: `clearRolesNewRound` (`gh:517,520-525`) behält `meta.giftwolfDieOnMorning` und setzt `MorningCount=0`. Jeder in der Vorrunde vergiftete Sitz (auch einer, der am Gift gestorben ist, da das Feld nie gelöscht wird) stirbt in der neuen Runde am Morgen mit derselben Nummer. Risiko hoch. Test: Runde 1 Gift in Nacht 1 (dieOn=2), Rollen leeren, Runde 2 → Morgen 2 stirbt der Sitz nicht.
- echter Bug: `GiftwolfUses` wird bei neuer Runde nicht zurückgesetzt (`gh:525`, `gh:558`) → Giftwolf der Folgerunde hat keine oder nur eine Ladung. Test: Runde 1 zwei Ladungen, Rollen leeren, Runde 2 → zwei Ladungen verfügbar.
- unklare Regel: Gift überlebt Tod und Wiederbelebung des Ziels (`night:204`).
- technische Altlast: `giftwolfPoisoned` gesetzt, nie gelesen; Zeile bleibt nach Verbrauch sichtbar.

#### `rudelvater`

- unklare Regel: Zusatzopfer auch, wenn er den Lynch überlebt (`night:498` vor `applyKill`). Test: Rudelvater mit Schattenwanderer-Link gelyncht, Partner stirbt → Zusatzopfer ja/nein laut Entscheidung.
- echter Bug (niedrig): Prompt erscheint ohne lebende Wölfe bzw. nach feststehendem Sieg (`night:269`). Erwartet: kein Zusatzopfer ohne Rudel. Test: Rudelvater letzter Wolf gelyncht → Dorfsieg, kein Zusatzopfer-Prompt.
- technische Altlast: `PackfatherBlockNextDay` toter Zweig (`night:245-248`).
- technische Altlast: Prompt hartkodiert DE ohne i18n-Schlüssel; EN nur fragmentweise übersetzt (nicht im Browser geprüft).
- technische Altlast: globale Rettung für alle Kopien (`RudelvaterSavedOnce`).

#### `schwarze-witwe`

1. Phantompaar nach "Rollen löschen / neue Runde". Einstufung: echter Bug. Codepfad: `gh:512-517` `clearRolesNewRound` setzt `flags.inlove=false` und `meta.rivalId=null`, aber `meta.loverId` nicht; `chunk:453` prüft `(t.meta&&t.meta.loverId)||t.flags.inlove`. Tatsächlich: In der Folgerunde findet die Witwe über das alte `loverId` einen "Liebenden", obwohl Loki in dieser Runde niemanden verbunden hat, und beide sterben am Morgen. Erwartet: nur in dieser Runde durch Loki verbundene Paare. Risiko: mittel (nur bei Rundenwechsel über `clearRolesNewRound` bzw. `legacy-bridge.js:39`, nicht bei `createState`). Regressionstest: Runde 1 Loki verliebt Sitz 2+3, Rollen löschen, Runde 2 ohne Loki-Liebe, Witwe wählt Sitz 2 → erwartet "kein Paar".
2. `WidowMorningKills` überlebt Rundenwechsel. Einstufung: technische Altlast. Codepfad: `gh:512-528` leert das Feld nicht. Tatsächlich: Witwe wählt, SL beendet die Runde vor Tagesbeginn, in der neuen Runde sterben die Sitz-IDs beim ersten Tagesbeginn. Erwartet: ausstehende Effekte verfallen mit der Runde. Risiko: niedrig. Test: Witwe wählt Paar, `clearRolesNewRound`, neue Runde, Tag starten → niemand stirbt durch `BLACK_WIDOW`.
3. Keine Rudel-Tötungszeile, wenn nur Witwe als Wolf lebt (F2). Einstufung: echter Bug (bereits 01 F2). Codepfad: `night:50-55`. Risiko: hoch in Setups ohne "Werwolf"-Karte. Test: Setup Witwe + Dorf, Nacht 2 → Werwolf-Zeile vorhanden.

#### `der-weise`

- B-WE-1 (echter Bug, F10): `gh:450`, `gh:646`, `legacyAdapter.ts:572,666-667` + `night:145` + `chunk:162` + `night:359-364`. Tatsächlich: zwei überlebte Wolfsangriffe bei Popup-Vergabe und in React immer. Erwartet: genau einer. Risiko hoch. Test: Weiser, zwei Nächte Wolfsziel → Nacht 1 überlebt, Nacht 2 stirbt; unabhängig vom Vergabeweg.
- B-WE-2 (echter Bug gegenüber DR-05): `night:145` `keepP` hält jeden Schutz auf dem Weisen über Nächte und stapelt `protectedCount`. Tatsächlich: Schutzengel-Schutz aus Nacht 1 rettet in Nacht 5. Erwartet: Schutz nur für die Nacht. Risiko mittel. Test: Schutzengel schützt Weisen N1, keine Attacke; N2 Angriff (Rettung schon verbraucht) → stirbt.
- B-WE-3 (unklare Regel): Debuff sperrt Solos und nur Nachtzeilen (`ab:93-96`). Test: Debuff aktiv → Pestbringerin-Schritt nach Entscheidung erlaubt/gesperrt; Tagesaktion nach Entscheidung.
- B-WE-4 (technische Altlast): globales Flag statt pro Person (`night:359-360`). Test: zwei Weise (Erbe) → jeder eigene Rettung (nach Entscheidung).

#### `verdammniswaechter`

- B-VW-1 (technische Altlast): `Math.random` beim Öffnen (`chunk:729`), Neuwürfeln durch erneutes Öffnen. Test: gleicher Seed → gleicher Kandidat; Abbruch verbraucht keinen Rng (wie Lehrling).
- B-VW-2 (unklare Regel / Bug-Risiko): `seats.find(targeted)` wählt bei mehreren Zielen das nach Sitz erste (`chunk:727`). Test: Werwolf-Ziel Sitz 5, Rachsüchtiger-Wolf-Ziel Sitz 2 → Nachtopfer muss das Rudelziel sein.
- B-VW-3 (unklare Regel): Ritter-Vergeltung und Seuchenwolf-Reset ignorieren die Ursache (`core:431`, `night:338`). Test: Ritter als Nachtopfer, b1 → Vergeltung ja/nein festlegen.

#### `wahnsinniger-kutscher`

- B-MK-1 (technische Altlast, sichtbar): Kutscher selbst wird mit `BUSDRIVER_LYNCH` getötet (`night:432`) und im Protokoll als "starb als Nachbar des Wahnsinnigen Kutschers" geführt (`gh:2423`), obwohl `finalizeLynch` das Lynch-Log unterdrückt (`night:436`). Test: Kutscher-Lynch → Kutscher Ursache LYNCH, Nachbarn Nachbar-Ursache, genau ein Lynch-Eintrag.
- B-MK-2 (unklare Regel): Zweig ignoriert Voodoo-Puppe und Kopfgeldjäger-Aktivierung (`night:425-439` vs. `night:499`). Test: Kutscher mit Wolf-Flag gelyncht → Kopfgeldjäger aktiv (festlegen).
- B-MK-3 (unklare Regel): Siegprüfung nach jedem Einzeltod (`core:213`) statt nach der ganzen Hinrichtung (DR-14). Test: Lynch, bei dem erst der Tod beider Nachbarn plus Kutscher die Parität ergibt → genau eine Siegprüfung nach allen Toden und Reaktionen.

#### `korrupter-richter`

- B-KR-1, echter Bug: Codepfad `chunk:722` setzt `flags.nominated` direkt; `gh:429` (einziger Manipulator-Trigger) wird umgangen. Tatsächlich: Manipulator bleibt am Leben und behält Siegchance (`core:234-235`). Erwartet laut Manipulator-Text ("The moment he is nominated, he dies immediately", `roles:280`) und 07 Q1 Teil 2: Tod. Risiko mittel (falscher Einzelsieg). Regressionstest: Richter markiert Manipulator → Manipulator stirbt mit `MANIPULATOR_NOMINATED`, `ever_nominated=true`.
- B-KR-2, technische Altlast: `state.pending.judgeAsk`/`state.ui.judgeAsk` werden geschrieben, nie gelesen (`chunk:722-723`, `state:71-72`). Risiko niedrig. Test: nicht nötig, beim Port weglassen.
- B-KR-3, technische Altlast: hart kodierte DE-Dialogtexte (`chunk:721-722`). Risiko niedrig. Test: EN-Lokalisierung des Richter-Prompts.

#### `maertyrerin`

- B-MA-1, echter Bug: `night:257-265` läuft vor `night:323-330` (Zeitwächter-Einfrieren). Tatsächlich: In einer eingefrorenen Nacht wird der Opferdialog angeboten und die Märtyrerin stirbt real, obwohl danach alle Nachtziele verworfen werden. Erwartet laut Zeitwächter-Text ("That night is treated as though it never happened", `roles:275`): kein Tod. Risiko mittel (unnötiger Tod, selten). Regressionstest: Zeitwächter friert Nacht ein, Wolf zielt auf B, Märtyrerin lebt → kein Opferdialog, niemand stirbt.
- B-MA-2, unklare Regel: angebotenes Opfer kann ohnehin überleben (Der Weise, Schmiedewaffe, Albtraum-F3, Nekromant). Codepfad `night:257` vor `night:334-392`. Erwartet: Dialog nur für Personen, die tatsächlich sterben würden (Interpretation). Risiko niedrig. Test: Wolf zielt auf Der Weise (erster Angriff) → kein Opferangebot.
- B-MA-3, technische Altlast: Nachtorder-Zeile tier 9.0 ohne Handler, zeigt "Keine Fähigkeit" (`roles:58`, `ab:100`). Risiko niedrig (SL-Verwirrung). Test: Nachtplan enthält keinen Märtyrerin-Schritt.
- B-MA-4, unklare Regel: Märtyrerin als eigenes erstes Ziel stirbt mit falscher Ursache `MARTYR_SACRIFICE`. Risiko niedrig. Test: Wolf zielt auf Märtyrerin → kein Opferangebot, Ursache `NIGHT_KILL`.

#### `dorfwache`

- B-DW-1, technische Altlast: `chunk:162` verbraucht `protectedCount` bei Dorfwache-Ziel. Tatsächlich: Schutzengel-Schild geht verloren. Erwartet: Immunität verbraucht keinen fremden Schutz. Risiko niedrig. Test: Schutzengel schützt Dorfwache, Rudel wählt Dorfwache → Schutz bleibt/Verbrauch nach PO, Dorfwache lebt.
- B-DW-2, technische Altlast: bei Dorfwache-Wahl bleibt ein früher gesetztes `targeted` anderer Sitze bestehen (else-Zweig nicht erreicht, `chunk:162`). Risiko niedrig (Fehlklick-Folge). Test: Rudel wählt erst A, dann Dorfwache → Rudelwahl ist die Dorfwache, A stirbt nicht.

#### `pestbringerin`

1. Unklare Regel · Sieg ohne lebende Pestbringerin · `core:264-273`. Tatsächlich: `solo_Pestbringerin` auch nach ihrem Tod. Erwartet: kein Text dazu. Risiko mittel. Test: Pestbringerin tot, übrige Lebende alle vergiftet → Kandidat ja/nein nach PO.
2. Echter Bug · verspätete Prüfung · `checkPestWin` nur `chunk:696`, `night:333`. Tatsächlich: Stirbt der letzte Unvergiftete (Nacht/Lynch), keine Prüfung bis zum nächsten Morgen, Parität kann vorher gewinnen. Erwartet: Prüfung nach jeder Zustandsänderung (DR-14). Risiko mittel. Test: letzter Unvergifteter wird gelyncht → Kandidat Pestbringerin sofort.
3. Technische Altlast · Ausbreitung läuft auch ohne Pestbringerin im Spiel (`night:332`), betrifft manuell per Chip gesetzte Vergiftungen. Test: Chip „vergiftet" ohne Pestbringerin → keine Ausbreitung.
4. Technische Altlast · Namenskonflikt „Plague Bearer" vs. „Plague Bringer" (`i18n.js:534` vs. `roles:159`). Content-Lint.

#### `prophet-des-untergangs`

1. Unklare Regel (fehlende Mechanik) · kein Einzelsieg · gesamte Codebasis. Tatsächlich: Rolle gewinnt nie. Erwartet laut Text: Einzelsieg. Risiko hoch (Rolle in Akt III und IV). Test: nach PO-Regel.
2. Echter Bug (klein) · Wiederbelebung sperrt freigeschaltete Tötung · `chunk:812-816` prüft `deadCnt` vor `ProphetUnlocked`. Erwartet laut Text: Fähigkeit „erhalten". Test: freigeschaltet, Markierter wird wiederbelebt → Tötung weiter möglich.
3. Technische Altlast · `prophetProgressCheck` doppelt und wirkungslos (`gh:2043-2069`), Freischaltung im `save()` (`state:94-110`). Test: Freischaltung nur über Befehlsanwendung, Speichern ändert nichts.

#### `daemonischer-wolf`

1. Fluch trotz Überleben (F14). Einstufung: echter Bug. Codepfad: `night:394` `applyKill(s,killCause); killedTonight.push(s)` ohne Ergebnisprüfung; `night:499-501` Lynch ohne Ergebnisprüfung. Tatsächlich: Dämon überlebt per Schild, Fluch-Pick erscheint trotzdem. Erwartet: Reaktion nur bei echtem Tod. Risiko: mittel. Test: Nekromant-Schild aktiv, Rudel tötet Dämon → kein Fluch-Prompt.
2. Abbruch des Fluch-Picks stoppt die Nachtauflösung. Einstufung: echter Bug. Codepfad: `night:289` `startPick` ohne Abbruch-Callback, `ui:315/325`. Tatsächlich: Nach "Abbrechen" laufen `drainBesessenerWolf`/`afterCurses` nie; `state.dark` bleibt, `nightCount` wird nicht erhöht, `postDeathHooks` der Nacht fehlen. Erwartet: Abbruch = Verzicht, Auflösung läuft weiter (oder Pflicht ohne Abbruch). Risiko: hoch (Knopf ist immer sichtbar). Test: Dämon stirbt nachts, Fluch-Prompt abbrechen → Tag beginnt trotzdem vollständig.
3. Verfluchter blockiert den Dorfsieg. Einstufung: unklare Regel (Code-Kommentar `ab:75` spricht von "nur erscheinen", Siegprüfung nutzt `isWolf`). Codepfad: `core:224-233`. Tatsächlich: alle echten Wölfe tot, ein Verfluchter lebt → kein Dorfsieg; bei Parität gewinnen sogar "Werwölfe". Erwartet laut Text: nur Erscheinung. Risiko: hoch. Test: Wölfe tot, verfluchter Dorfbewohner lebt → Dorfsieg-Kandidat.

#### `schattenhund`

1. Keine Werwolf-Zeile, wenn nur Schattenhund als Wolf lebt (F2). Einstufung: echter Bug. Codepfad `night:50-55`. Test: Schattenhund + Dorf, Nacht 2 → Rudelschritt vorhanden.
2. Nacht-1-Meldung nicht übersetzt. Einstufung: technische Altlast. Codepfad `chunk:706`. Test: EN, Nacht 1, Schattenhund klicken → englischer Hinweis.

#### `besessener-wolf`

1. Rohschlüssel im Prompt (F12). Einstufung: echter Bug. Codepfad `night:312`, `i18n.js:652-655`. Tatsächlich: Pick-Leiste zeigt "besessenerWolfDrag". Erwartet: lokalisierter Text. Risiko: niedrig (funktional), sichtbar bei jedem Einsatz. Test: Content-Lint "alle genutzten Schlüssel existieren".
2. Abbruch sperrt alle künftigen Mitnahmen. Einstufung: echter Bug. Codepfad `night:305` setzt `_besessenerDraining=true`, nur `night:308` löscht es; `ui:325` kein Abbruch-Callback. Tatsächlich: nach "Abbrechen" bleibt die Sperre gesetzt und wird mit gespeichert (`state:111`); jeder spätere Drain kehrt bei `night:303` ohne Callback zurück. Nachts heißt das zusätzlich: `afterCurses` läuft nie (Nachtende fehlt). Erwartet: Abbruch = Verzicht, Sperre gelöst, Auflösung läuft weiter. Risiko: hoch. Test: Besessener stirbt, Prompt abbrechen, später zweiter Besessener stirbt → Prompt erscheint; Nacht endet korrekt.
3. Verzögerte Mitnahme bei Liebeskummer in der Nachtauflösung. Einstufung: echter Bug. Codepfad `night:350` `afterCurses` setzt `_inNightResolution`, `postDeathHooks` tötet den verliebten Besessenen (`core:365-384`), `core:414` überspringt den Drain, danach wird nicht mehr gedraint. Tatsächlich: Mitnahme erscheint erst beim nächsten `postDeathHooks` außerhalb der Nacht (z. B. nächster Lynch) oder nie. Erwartet: am selben Morgen. Risiko: mittel (Loki-Paare). Test: Loki verliebt Besessenen mit Opfer X, Rudel tötet X → Mitnahme-Prompt am selben Morgen.
4. Kollision mit Morgen-Toden vor der Auflösung. Einstufung: echter Bug (aus Code abgeleitet, nicht ausgeführt). Codepfad `night:196-197` bzw. `night:208-209`: Witwen-/Giftwolf-Tod ruft `postDeathHooks` außerhalb `_inNightResolution` → Drain startet sofort (`core:414`), während `onDayStart` synchron weiterläuft. Ein späterer `startPick` (Dämonen-Fluch `night:289`, Nekromant `night:369-373`, Rudelvater `night:270`) ersetzt den offenen Mitnahme-Pick; die Sperre bleibt gesetzt. Stirbt nachts zusätzlich ein Besessener, kehrt `drainBesessenerWolf(afterCurses)` wegen der Sperre ohne Callback zurück → Nachtende fehlt. Risiko: mittel. Test: Witwe tötet verliebten Besessenen am Morgen, gleichzeitig stirbt ein Dämon → beide Prompts nacheinander, Nacht endet.

#### `fenrir`

1. Lynch-Rettung überspringt `finalizeLynch` (F15). Einstufung: echter Bug. Codepfad `night:448`. Tatsächlich: LynchCount bleibt, Henker-markierte sterben nicht, kein Log. Erwartet laut 04 E-3: jeder Hinrichtungszweig bucht. Risiko: mittel (Henker-Freischaltung verzögert). Test: 2 Lynchs, dann Fenrir-Lynch-Rettung → LynchCount 3 (nach Entscheidung), Henker aktiv.
2. Stille Rettung ohne Rückmeldung. Einstufung: technische Altlast. Codepfad `night:448` ohne `center`/Log. Tatsächlich: SL sieht nur, dass nichts passiert. Test: Lynch auf Fenrir Stufe 3 → Ereignis "Fenrir überlebt" (gm).
3. Brand-Ausbreitung trotz abgewehrtem Lynch. Einstufung: unklare Regel. Codepfad `night:444-448` Reihenfolge. Test: brennender Fenrir Stufe 3 gelyncht → Nachbarn sterben ja/nein laut PO.

#### `kutscher`

- B-KU-1, unklare Regel: Rollenpool `ALL_ROLES` (`chunk:846`) enthält Solo- und Akt-fremde Rollen. Tatsächlich: Wiederbelebter kann z. B. Hades oder Pestbringerin werden. Erwartet laut Text: nicht spezifiziert. Risiko mittel (Solo-Sieg durch Zufall). Test: Seed fest, Akt II → neue Rollen nur aus erlaubtem Pool.
- B-KU-2, technische Altlast: Meldung `kutscherRevived` "1 davon Wolf" auch bei Wächter-am-Tor-Blockade (`chunk:860`). Risiko niedrig. Test: Wächter am Tor lebt → Meldung ohne Wolf.
- B-KU-3, unklare Regel: `KutscherUsed` wird beim Rollenerbe gelöscht (`core:358`), bei Blutpriester/Seelentauscher dagegen faktisch nicht (siehe dort). Uneinheitlich. Risiko niedrig. Test: Seelentauscher gibt verbrauchten Kutscher weiter → Verhalten nach PO.
- B-KU-4, technische Altlast: Totenkarten-Eintrag und `FirstThreeDeadIds`/Prophet-Ziele bleiben nach Wiederbelebung unverändert; Wiederbelebung ohne Log. Risiko niedrig. Test: Wiederbelebung erzeugt Ereignis `REVIVE` mit Quelle Kutscher.

#### `seelentauscher`

- B-ST-1, echter Bug (F4): `chunk:778,782-783`. Tatsächlich: Tausch Werwolf↔Dorfbewohner ergibt zwei Wölfe (`isWolf` liest veraltetes `flags.werewolf`). Erwartet: genau ein Wolf. Risiko kritisch (Siegparität). Test S-ROLE-38: Werwolf A ↔ Dorfbewohner B → A zählt nicht als Wolf, B zählt als Wolf.
- B-ST-2, technische Altlast: `resetOnceForInheritedRole` für "Seelentauscher"/"Blutpriester" löscht `…Used`-Schlüssel, die `isOnceUsed` nicht liest (`core:355-356` vs. `night:4-5`). Folge: Verbrauch geerbter Einmalrollen bleibt bestehen, anders als beim Kutscher (`core:358`). Risiko mittel (uneinheitliche Einmaligkeit). Test: Seelentauscher gibt verbrauchten Blutpriester weiter → Verhalten nach PO (pro Person).
- B-ST-3, technische Altlast: Dialogname "Soul Shifter" ≠ Rollenname "Soul Swapper" (`i18n.js:544,623` vs. `roles:168`). Risiko niedrig. Test: EN-Namenskonsistenz.

#### `blutpriester`

- B-BP-1, technische Altlast: `chunk:703` ruft `postDeathHooks()` vor dem Öffnen des eigenen Overlays; `showDeathPopup` (`ui:479-482`) wird dadurch sofort überschrieben (Todes-Popup verschwindet). Risiko niedrig (SL verliert Hinweis). Test: Opfer-Tod erscheint im Protokoll und in der Morgenübersicht.
- B-BP-2, unklare Regel: Verbrauch auch bei abgefangenem Tod (Rudelvater, Schilde). Risiko niedrig. Test: Opfer ist Rudelvater (unverbraucht) → überlebt; Verbrauch nach PO.
- B-BP-3, technische Altlast: verzerrtes Mischen `sort(()=>Math.random()-0.5)`; kein Seed. Risiko niedrig. Test: SeededRng-Auswahl reproduzierbar.

#### `traumdeuter`

- B-TD-1, unklare Regel: Traumdeuter kann sich selbst sehen (`chunk:831`). Risiko niedrig. Test: Vision enthält nie den Traumdeuter (falls PO so entscheidet).
- B-TD-2, technische Altlast: Ergebnis nicht gespeichert, verzerrtes Mischen, kein Seed. Risiko mittel für Replay. Test: InfoRecord gespeichert, gleiche Seeds → gleiche Namen.

#### `henker`

- B-HE-1, unklare Regel (F15): `night:448-449` ohne `finalizeLynch`. Tatsächlich: bei Fenrir/Cerberus-Rettung keine Zählung, keine Henker-Vollstreckung. Erwartet laut 07 Teil 2: Zählung/Vollstreckung; laut Text offen. Risiko mittel. Test: Henker markiert C, Cerberus mit 3 Köpfen wird gelyncht → Ergebnis gemäß PO, `LynchCount` gemäß PO.
- B-HE-2, technische Altlast: `henkerNotActive` "3 Lynch-Tote" vs. Zählung von Lynch-Vorgängen (`i18n.js:227,556`, `night:414`). Risiko niedrig. Test: Spiegelwolf-Lynch zählt als Lynch.
- B-HE-3, technische Altlast: kein Logtext für `HANGMAN_EXECUTION` (`gh:2413-2427`); Chip-Emoji 🪃 vs. Marker 🪓. Risiko niedrig. Test: Protokolleintrag mit Ursache Henker.

#### `feuerteufel`

1. Echter Bug · Brand ohne Tod des Ziels · `night:340-348` (Liste aus `nightTargets`, nicht aus Toten) und `night:444-446` (vor Fenrir/Cerberus/Spiegelwolf). Tatsächlich: Nachbarn sterben, Ziel lebt. Erwartet laut Text: nur „beim Tod des Ziels". Risiko hoch (bis zu 2 falsche Tode). Test: markierter Der Weise wird angegriffen (erster Angriff) → keine Nachbartode.
2. Echter Bug · kein Brand bei anderen Todesursachen · nur zwei Auslösestellen. Tatsächlich: Ziel stirbt durch Waldhexe/Prophet/Hades → keine Nachbartode. Erwartet laut Text: Brand. Risiko mittel. Test: markiertes Ziel stirbt durch Gift → Nachbarn sterben (nach PO).
3. Unklare Regel · Feuerteufel verbrennt sich nachts selbst, beim Lynch nicht (`night:345` vs. `night:445`). Test: Feuerteufel sitzt neben markiertem Opfer → einheitliches Ergebnis.
4. Technische Altlast · `killedTonight.push(nb)` ohne Prüfung des `applyKill`-Ergebnisses (`night:345`, F14). Test: verbrannter Nachbar mit Hades-Barriere zählt nicht als getötet.

#### `voodoo-priester`

1. Echter Bug · Hexen-Gift wird nicht verbraucht, wenn es auf den Priester umgelenkt wird · `help:265`: Umlenkungszweig kehrt vor `state.once.WaldhexeD=true` zurück. Erwartet: Gift verbraucht. Risiko mittel (Waldhexe kann erneut vergiften). Test: Hexe vergiftet Priester mit Puppe → Puppe tot, Gifttrank verbraucht.
2. Echter Bug · Mehrere Priester: Nachtumlenkung nur für den ersten gefundenen (`night:252`). Test: zwei Priester, zweiter angegriffen, Puppe lebt → Umlenkung.
3. Technische Altlast · Abklingzeit auch, wenn die Puppe überlebt (`night:339` mit F14). Test: Puppe mit Schild angegriffen, überlebt → keine Abklingzeit.
4. Unklare Regel · Umlenkung nur bei drei Ursachen (siehe Tabelle).

#### `blutwolf`

1. `showBlutwolfInfo` nie definiert (F13). Einstufung: technische Altlast. Codepfad `night:350`. Tatsächlich: kein Hinweis am Morgen. Erwartet: vermutlich Info zum neuen Gewicht. Risiko: niedrig. Test: Nachbar stirbt nachts → Morgenübersicht nennt neues Blutwolf-Gewicht.
2. Marker auch bei totem Blutwolf. Einstufung: technische Altlast. Codepfad `ui:109`. Test: toter Blutwolf mit totem Nachbarn → kein Stimmgewicht-Marker.

#### `albtraumwolf`

1. Blockade schützt vor Wolfsangriff (F3). Einstufung: echter Bug. Codepfad `night:334`. Tatsächlich: Albtraumwolf blockiert Sitz 5, Rudel wählt Sitz 5 → Sitz 5 lebt am Morgen. Erwartet (04 Akzeptanz, 07 Teil 2): Sitz 5 stirbt. Risiko: hoch. Test S-ROLE-45b.
2. Mehrfachblockade pro Nacht. Einstufung: unklare Regel / technische Altlast (allgemeines Wiederklick-Verhalten der Nachtleiste). Codepfad `chunk:288-303` ohne Sperre. Test: zweiter Klick in derselben Nacht → abgelehnt.

#### `cerberus`

1. Lynch-Abwehr überspringt `finalizeLynch` (F15). Einstufung: echter Bug. Codepfad `night:449`. Test: Cerberus 3 Köpfe gelyncht → LynchCount laut Entscheidung, Henker-Markierte hingerichtet.
2. Hexentrank nicht verbraucht bei Abwehr. Einstufung: unklare Regel (Text nennt Hexe nicht). Codepfad `help:265` Rückkehr vor `WaldhexeD=true`. Tatsächlich: Hexe kann denselben Trank noch einmal einsetzen. Risiko: mittel. Test: Hexe wirft Trank auf Cerberus mit 3 Köpfen → Trank verbraucht (oder Abwehr entfällt laut PO).
3. Stille Abwehr. Einstufung: technische Altlast. Codepfad `night:449`. Test: Ereignis "Cerberus wehrt Lynch ab" (gm/public laut PO).

#### `ritter`

- B-RIT-1 (echter Bug): Codepfad `gh:512-518 clearRolesNewRound`. Tatsächlich: `meta.ritterRetaliated` und `meta.lastKillCause` bleiben nach "Neue Runde" am Sitz. Erwartet: neue Runde beginnt ohne Altzustand. Risiko: mittel (Ritter in Folgerunde wirkungslos, fällt am Tisch kaum auf). Regressionstest: Runde 1 Ritter auf Sitz 3 stirbt nachts und schlägt zurück; "Neue Runde"; Runde 2 Ritter erneut auf Sitz 3, Rudel tötet ihn; erwartet: nächster Wolf stirbt.
- B-RIT-2 (unklare Regel): Verzögerte Vergeltung bei Zeitwächter-Frost (`night:323-331`). Tatsächlich: Ritter-Tod durch Gift/Hades/Witwe in eingefrorener Nacht wird erst eine Nacht später vergolten. Erwartet: laut Text beim Sterben. Risiko: niedrig. Test: Zeitwächter friert Nacht ein, Waldhexe vergiftet Ritter; erwartet (je Entscheidung) Vergeltung am selben Morgen oder keine.
- B-RIT-3 (unklare Regel): Ritter-Opfer nicht in `killedTonight` (`night:349` vs `night:352`), Dämonischer Wolf flucht nicht, wenn der Ritter ihn tötet. Risiko: niedrig. Test: Ritter stirbt nachts, nächster Wolf ist Dämonischer Wolf; erwartet laut Dämonen-Text: Fluch-Auswahl.

#### `rotkaeppchen`

- B-RK-1 (echter Bug): `gh:512-518 clearRolesNewRound` behält `meta.rkLink`/`meta.appleBuff`. Tatsächlich: In der neuen Runde sterben zwei Sitze gemeinsam (Kette aktiv wegen altem `appleBuff`, `core:61-62`) und ein Sitz hat einen Gratis-Apfel. Erwartet: sauberer Start. Risiko: hoch (unerklärlicher Tod in neuer Partie). Test: Runde 1 Zuflucht A→B gewährt; "Neue Runde" ohne Rotkäppchen; Lynch A; erwartet: B lebt.
- B-RK-2 (technische Altlast): Apfel wird bei Fähigkeiten ohne `pick`/`startMulti` nie verbraucht (`ab:113-124`), bleibt dauerhaft. Risiko: mittel (König-Mehrfachnutzung, s. koenig). Test: Apfel an König, zwei Klicks auf König in einer Nacht bei Tote > Lebende; erwartet: höchstens eine bzw. zwei Infos laut Entscheidung, Apfel danach weg.
- B-RK-3 (technische Altlast): Mehrere Rotkäppchen, nur die erste handelt (`ab:8`). Risiko: niedrig (Einzelrolle). Test: zwei Rotkäppchen → zwei Schritte oder `max_copies=1`.

#### `selbstmoerder`

1. Echter Bug · fehlender Guard / Überschreiben · `night:476` setzt `TeamWinner` ohne Prüfung. Tatsächlich: bereits entschiedener Sieg wird überschrieben (z. B. nach Brand-Nachbartod des letzten Wolfs). Erwartet (DR-02/DR-14): Kandidatenmenge, SL wählt. Risiko mittel. Test: gebrannter Selbstmörder, Nachbar ist letzter Wolf, 5 Tote → Kandidaten Dorf und Selbstmörder.
2. Technische Altlast · keine Voodoo-Abklingzeit, wenn der Selbstmörder Puppe ist (`night:474-482` vs. `night:499`). Test nach PO.

#### `kopfgeldjaeger`

- B-KGJ-1 (unklare Regel, wahrscheinlich Versehen): `chunk:9` schließt den Kopfgeldjäger nicht aus. Tatsächlich: er kann als einer der drei erscheinen. Erwartet: drei andere Spieler. Risiko: mittel (Info wertlos). Test: 4 Lebende (KGJ, Wolf, A, B), Seed so, dass KGJ gezogen würde; erwartet: nie KGJ in der Liste.
- B-KGJ-2 (unklare Regel): `core:354` aktiviert bei Erbe. Risiko: niedrig. Test: Lehrling erbt Kopfgeldjäger ohne vorherigen Wolfs-Lynch; erwartet: "inaktiv".
- B-KGJ-3 (technische Altlast): toter Schlüssel `KopfgeldjägerUsed` (`gh:523`, `core:354`), verzerrte Mischung `chunk:22`. Risiko: niedrig. Test: Mischung über SeededRng gleichverteilt (Statistik über viele Seeds).

#### `koenig`

- B-KOE-1 (echter Bug): Apfel-Mehrfachnutzung `ab:104,112` mit `chunk:110,124`. Tatsächlich: Mit Apfel kann der SL den König in derselben Nacht beliebig oft ausführen, Apfel bleibt. Erwartet: höchstens die laut Text vorgesehene(n) Info(s). Risiko: mittel. Test: Apfel an König, Tote > Lebende, zweimal ausführen; erwartet: zweiter Aufruf liefert nichts bzw. nur die eine Zusatzinfo, Apfel verbraucht.
- B-KOE-2 (unklare Regel): Verwandeltes Wolfskind gilt als Dorfbewohner (`chunk:117` rollenbasiert). Risiko: mittel (falsche Info zugunsten der Wölfe). Test: Wolfskind verwandelt, einziger lebender "dorf"-Rollenträger außer König; erwartet laut Entscheidung: nicht zeigbar.
- B-KOE-3 (technische Altlast): stummer Abbruch ohne Meldung (`chunk:110,113,121`), EN-Anzeige mit deutschem Rollennamen (`chunk:126`), falscher Reset-Schlüssel `core:341-342`. Risiko: niedrig. Test: Bedingung nicht erfüllt → Schritt entfällt mit Grund (StepDropped) statt stiller Klick.

#### `dr-victor-frankenstein`

- B-FRK-1 (echter Bug, W06): `chunk:57` vor `chunk:64-92`. Tatsächlich: Wiederbelebung vor Rollenwahl, ohne freie Rollen bleibt ein lebender Sitz mit alter Rolle und unverbrauchter Fähigkeit. Erwartet: atomar (Text "wiederbeleben und ... neue Rolle geben"). Risiko: hoch. Test: alle Rollen vergeben, Frankenstein wählt Toten; erwartet: keine Zustandsänderung, Meldung.
- B-FRK-2 (echter Bug, W05/FK1): `domMirror.ts:53-61` ohne `<select>`. Tatsächlich: React-SL kann die Rolle nicht wählen, erste freie Rolle wird vergeben. Erwartet: bewusste Wahl. Risiko: hoch (P0 laut Analyse). Test: im React-Dialog Rolle "Doktor" wählen; erwartet: Sitz wird Doktor.
- B-FRK-3 (echter Bug): `chunk:90-91` blendet die Erfolgsmeldung sofort aus. Risiko: niedrig bis mittel (SL ohne Bestätigung). Test: nach Vergabe ist eine Bestätigung sichtbar bzw. Ereignis gm-sichtbar.
- B-FRK-4 (echter Bug, Interaktion): unvollständiger Reset `chunk:57-62` mit `core:378-383`. Tatsächlich: wiederbelebter Loki-Liebender mit totem Partner stirbt beim nächsten `postDeathHooks` erneut. Erwartet: Wiederbelebung wirkt. Risiko: mittel. Test: Liebespaar A/B, beide tot, A wiederbelebt, danach beliebiger Tod; erwartet: A lebt.
- B-FRK-5 (echter Bug, nur mit Apfel): `ab:117-118` mit `chunk:31-103`. Tatsächlich: erster Wiederbelebter behält alte Rolle, zweiter erhält neue. Risiko: mittel. Test: Apfel an Frankenstein, zwei Tote; erwartet laut Entscheidung: zwei vollständige Wiederbelebungen oder Apfel wirkungslos.
- B-FRK-6 (technische Altlast): toter `fromGhost`-Pfad (`chunk:31,87`), fehlendes `rebuildOrder` nach Wiederbelebung (`chunk:88`), rohe deutsche Rollennamen im Dropdown (`chunk:75`). Risiko: niedrig. Test: nach Wiederbelebung als Doktor erscheint der Doktor-Schritt in derselben Nacht laut Entscheidung (erscheint/erscheint nicht).

#### `nekromant`

1. Einstufung: echter Bug. Codepfad: `night:368-377` mit `ui:315,340`. Tatsächlich: Abbruch der Pflicht-Mehrfachauswahl (oder des Umlenkziels) beendet `processOne` ohne Fortsetzung; weitere Nachtziele sterben nicht, `afterCurses` läuft nicht (kein `state.dark=false`, kein `nightCount+1`); erneutes "Tag starten" erhöht `MorningCount` ein zweites Mal (`night:191`). Erwartet: Abbruch = "nicht umlenken", Auflösung läuft weiter. Risiko: hoch (Spielstand inkonsistent, Todesprediger/Giftwolf-Zählung verschoben). Regressionstest: Nekromant ist Wolfsziel, 3 Tote vorhanden, zweites Nachtziel vorhanden; Prompt abbrechen => Nekromant stirbt oder Verzicht, zweites Ziel stirbt, Tag beginnt genau einmal.
2. Einstufung: unklare Regel. Codepfad: `night:373-375`. Tatsächlich: Umlenkziel stirbt ohne Der-Weise-, Schmied-, Dorfwache-Prüfung und unabhängig von Schutzengel-Schutz. Erwartet: nicht definiert. Risiko: mittel. Regressionstest: Umlenkung auf geschützte Person/Der Weise; Ergebnis gemäß PO-Regel.
3. Einstufung: technische Altlast. Codepfad: `night:374` (`killedTonight.push` auch wenn `applyKill` false liefert, vgl. F14). Risiko: niedrig. Test: aktiver Schild + Umlenkung => Umlenkziel lebt und erscheint nicht in der Todesliste.
4. Einstufung: unklare Regel/technische Altlast. Codepfad: `chunk:163-207`. Handler ohne Nachtgrenze; Mehrfachaufruf verbraucht weitere Stimmen ohne Zusatznutzen. Risiko: niedrig. Test: zweiter Aufruf in derselben Nacht ist gesperrt oder verbraucht nichts.

#### `kartenschlucker`

1. Einstufung: unklare Regel. Codepfad `chunk:232`. Tatsächlich: Kill-Pick erlaubt den Kartenschlucker selbst. Erwartet: nicht definiert. Risiko: niedrig. Test: Selbstwahl beim Kill abgelehnt oder erlaubt gemäß PO.
2. Einstufung: technische Altlast. Codepfad `chunk:224-235`. Schild-Neuaufbau und Ansage sind an den manuellen Aufruf des Nachtschritts gekoppelt; bei Albtraum-Blockade (`ab:97-99`) oder vergessenem Aufruf fehlen sie. Risiko: mittel. Test: 5 Stapel, Nachtschritt blockiert => Schild-Verhalten gemäß PO (passiv oder nicht).
3. Einstufung: technische Altlast. Codepfad `core:287-335`. Sieg bei >=10 über `checkTeamWin` wird erst nach Team-Siegen geprüft; direkte Aufrufe in `help:180` haben keine Priorität gegenüber gleichzeitigen Team-Siegen (Q4 Siegpriorität). Risiko: niedrig.

#### `hades`

1. Einstufung: echter Bug. Codepfad `ui:18` (unbenutzt), `ab:45-47`. Tatsächlich: gekaufter Stimmbonus verbraucht 5 Lichter und ist nirgends sichtbar. Erwartet: Bonus wirkt oder wird dem SL angezeigt. Risiko: mittel (Spieler zahlt für nichts). Test: Bonus kaufen => Marker/Hinweis am Hades-Sitz am Tag.
2. Einstufung: echter Bug (Randfall). Codepfad `ab:50-52` mit `core:85-100`. Tatsächlich: Einlösen ruft `triggerWin` ohne `TeamWinner`-Guard und überschreibt einen bereits entschiedenen Sieg. Erwartet: kein zweiter Sieger. Risiko: niedrig. Test: `TeamWinner` gesetzt, Lichter >=10, Einlösen => abgelehnt.
3. Einstufung: unklare Regel. Codepfad `ab:37`: Lichter werden auch abgezogen, wenn der Tod durch Schild/Immunität abgefangen wird. Risiko: niedrig. Test gemäß PO.

#### `doktor`

- B-DOK-1 (unklare Regel): `help:276-288` Solos. Risiko: mittel. Test: Rattenfänger + Pestbringerin prüfen; erwartet laut Entscheidung "verschieden".
- B-DOK-2 (unklare Regel): Verwandlung ignoriert. Risiko: mittel. Test: Wolfskind verwandelt, mit Werwolf prüfen; erwartet laut Entscheidung "gleiches Team".
- B-DOK-3 (technische Altlast): unerreichbarer `isWolf`-Zweig `help:285-287`. Risiko: niedrig. Test: nicht nötig, Code entfällt.

#### `faehrtenleser`

- B-FTL-1 (echter Bug): `chunk:470,485` mit `night:664-673`. Tatsächlich: Einsatz wird ohne Entscheidung verbraucht, mit SL-Assistent automatisch in der ersten Nacht. Erwartet: "darf einmal" (freiwillig). Risiko: mittel. Test: Nacht 1 Assistent läuft durch, Fährtenleser verzichtet; erwartet: Einsatz in Nacht 2 noch verfügbar.
- B-FTL-2 (unklare Regel): Richtung "links" = höhere Sitznummer, Ritter-Gleichstand bevorzugt die niedrigere (`core:423-425`). Risiko: mittel. Test: Wolf auf beiden Seiten gleich weit; erwartet: dokumentierte Richtung für beide Rollen konsistent.
- B-FTL-4 (echter Bug): Gleichstand zweier Wölfe `chunk:475-484` (Durchlauf in Indexreihenfolge, `d<minD`). Tatsächlich: Richtung hängt davon ab, welcher Wolf die niedrigere Sitznummer hat, nicht von einer festen Regel (Beispiele oben). Erwartet: deterministische, dokumentierte Regel (z. B. immer links oder "beide Seiten"). Risiko: niedrig bis mittel. Test: Fährtenleser Index 3, Wölfe Index 1 und 5; und Fährtenleser Index 0, Wölfe Index 2 und 6; erwartet: gleiche Regelanwendung in beiden Fällen.
- B-FTL-3 (technische Altlast): Erbe setzt Verbrauch nicht zurück (`core:341-342`), bei Frankenstein/Kopfgeldjäger aber schon; inkonsistent. Risiko: niedrig. Test: Lehrling erbt verbrauchten Fährtenleser; erwartet laut Entscheidung (pro Person frisch).

#### `waldlaeufer`

- B-WLF-1 (technische Altlast): beliebig viele Aufrufe pro Nacht (`chunk:490-493`, kein Verbrauch). Risiko: niedrig (liefert dieselbe Zahl, außer nach sofortigen Toden). Test: Schritt ist pro Nacht genau einmal ausführbar.

#### `schutzgeist`

- B-SG-1, echter Bug: Codepfad night:6/night:58 vor night:91-92. Tatsächlich: toter Schutzgeist erhält keine Nachtzeile, Fähigkeit nie nutzbar. Erwartet: Nachtschritt nach dem Tod. Risiko: hoch (Rolle tot im Akt II). Regressionstest: Schutzgeist stirbt in Nacht 1, Nacht 2 enthält Schritt Schutzgeist.
- B-SG-2, unklare Regel: chunk:494-505 + chunk:162 + night:145. Tatsächlich: Schild wirkt bei korrekter Reihenfolge nie. Erwartet: Schild schützt (Text). Risiko: mittel. Test: Schutzgeist schützt X in Nacht 2, Rudel wählt X (in Nacht 2 bzw. 3 je nach Entscheidung), X überlebt.
- B-SG-3, technische Altlast: gh:512-529 setzt `SchutzgeistAwaitingPick` nicht zurück. Test: neue Runde, Flag ist false.

#### `dorfchronistin`

- B-DC-1, echter Bug (kosmetisch): chunk:506-516 ruft `markOnceUsed` nicht auf, `once:true` in roles:6 wirkungslos. Tatsächlich: Zeile jede Nacht, Klick meldet "Schon genutzt.". Erwartet: Schritt nur einmal. Risiko: niedrig (SL-Verwirrung, SL-Assistent hält an). Test: Nacht 2 enthält keinen Chronistin-Schritt nach Nutzung in Nacht 1.
- B-DC-2, technische Altlast: ab:107 Schlüssel "Chronist". Risiko: niedrig. Test: nicht nötig bei Neuimplementierung.
- B-DC-3, technische Altlast: gh:512-529 setzt `ChroniclerShown` nicht zurück, neue Runde über "Rollen leeren" gibt keine Info mehr. Risiko: mittel im Legacy. Test: neue Runde, Info wieder verfügbar.

#### `waechter-am-tor`

- B-WT-1, echter Bug (Randfall): core:41-55 Probe mit `seat.meta` inkl. `cursedWolfAura`. Tatsächlich: verfluchter, wiederbelebter Sitz wird bei Frankenstein unabhängig von der gewählten Rolle zum Dorfbewohner (mit Wächter) bzw. erhält `werewolf=true` (ohne Wächter). Erwartet: nur Wolfsrollen werden abgefangen. Risiko: niedrig bis mittel. Test: verfluchter Toter wird als Seherin wiederbelebt, bleibt Seherin, kein Wolf.
- B-WT-2, technische Altlast: chunk:860 Kutscher-Meldung nennt Wolf trotz Abfang. Risiko: niedrig (SL-Fehlinformation). Test: Meldung ohne Wolf bei aktivem Wächter.
- B-WT-3, technische Altlast: Abfanglogik ist an sechs Stellen dupliziert (core:41, core:388, core:389, chunk:763-787, chunk:847-853). Risiko: mittel bei Erweiterung. Test: pro Verwandlungsweg ein Szenario.

#### `zeitwaechter`

- B-ZW-1, unklare Regel (siehe Widerspruch): night:176-280 führt Morgeneffekte vor der Einfrierprüfung aus. Risiko: hoch (Tode trotz "eingefrorener" Nacht). Test: Schwarze Witwe markiert in eingefrorener Nacht, am Morgen stirbt niemand.
- B-ZW-2, echter Bug: Märtyrerin-Dialog (night:257-265) erscheint vor der Einfrierprüfung; bei Ja stirbt die Märtyrerin für ein Opfer, das ohnehin nicht stirbt. Erwartet: kein Dialog bei eingefrorener Nacht. Risiko: mittel. Test: Zeitwächter aktiv, Märtyrerin lebt, Rudelopfer gesetzt, kein Opferdialog.
- B-ZW-3, technische Altlast: gh:512-529 setzt `TimekeeperFreezeMorning` nicht zurück. Test: neue Runde, Flag false.
- B-ZW-4, technische Altlast: EN-Laufzeitname "Timekeeper" statt Rollenname "Time Warden" (i18n:564-565, 608). Risiko: niedrig.

#### `amalia`

- B-AM-1, unklare Regel/technische Altlast: chunk:524-553 ohne Fragenerfassung, i18n-Schlüssel verwaist. Risiko: mittel (SL muss improvisieren). Test: Opfer erzeugt öffentliches Ereignis mit Frage und Antwort.
- B-AM-2, technische Altlast: chunk:527 `seats.find` statt handelndem Sitz. Risiko: niedrig (Duplikate selten). Test: zwei Amalias, die gewählte stirbt.

#### `kriegerin-des-lichts`

- B-KL-1, technische Altlast: chunk:564 `seats.find` statt handelnder Sitz. Risiko: niedrig. Test: zwei Kriegerinnen, die handelnde stirbt bei Fehlschlag.
- Kein echter Bug in der Kernlogik belegt; der fehlende Wolfstod ist eine Regelfrage (kein Text sagt ausdrücklich, dass der Wolf stirbt).

#### `detektiv`

- B-DT-1, echter Bug: core:77-79 `window.t` statt `window.tf`. Tatsächlich: Anzeige "Ein anderer Wolf sitzt links neben {name}." Erwartet: Name eingesetzt. Risiko: hoch (Hinweis wertlos). Test: Wolfstod erzeugt Hinweistext ohne Platzhalter.
- B-DT-2, echter Bug: core:79 Paritätshinweis wird ohne Prüfung ausgegeben und nennt (per i18n) keinen Bezug. Tatsächlich: kann falsch sein (alle anderen Wölfe gleiche Parität) und ist ohne Bezug inhaltsleer; bei ungerader Sitzzahl ist Parität im Kreis nicht eindeutig. Erwartet: öffentliche Hinweise sind wahr. Risiko: hoch (öffentliche Falschinformation). Test: Wölfe auf Sitz 2 und 4 nicht benachbart, Hinweis darf keine andere Parität behaupten.
- B-DT-3, technische Altlast: Overlay-Überschreibung bei gleichzeitigen Meldungen (night:386-387, core:76-80). Risiko: mittel. Test: Schmiedewaffe tötet Wolf, Detektiv-Hinweis erscheint im öffentlichen Morgenbericht.
- B-DT-4, unklare Regel: Richtungskonvention abweichend vom Fährtenleser. Test: gemeinsame Sitznachbarschaftsfunktion.

#### `dorfschmied`

- B-DS-1, echter Bug (Randfall): night:384-387 meldet "ein Wolf stirbt", auch wenn `applyKill` false liefert (Rudelvater-Erstrettung, Nekromant-Globalschild). Risiko: niedrig bis mittel (SL-Fehlinformation). Test: Waffe trifft Rudelvater, Meldung "Wolf überlebt".
- B-DS-2, technische Altlast: Waffenopfer nicht in `killedTonight` (night:386), Dämonischer-Wolf-Fluch entfällt. Risiko: niedrig (Akt IV ohne Dämonischen Wolf). Test: Waffe tötet Dämonischen Wolf, Fluchschritt folgt.
- B-DS-3, technische Altlast: `SchmiedWeaponGiven` wird in gh:512-529 nicht zurückgesetzt. Risiko: mittel im Legacy. Test: neue Runde, Waffe erneut vergebbar.
- B-DS-4, unklare Regel: Zählerstart abhängig vom Startweg (setup.html vs. game.html/React). Test: Nacht 6 nach jedem Startweg erlaubt Vergabe.

#### `doppelspion`

keine echten Bugs belegt. Technische Altlast: redundante Doppelspion-Ausschlüsse (`chunk:325,359`, `core:152`); Namensabweichung „Revenge Wolf" (Content-Lint).

#### `grabraeuber`

1. Einstufung: unklare Regel (keine Siegbedingung definiert). Codepfad: fehlt in `core:218-337`. Risiko: hoch für Spielbarkeit. Test: nach PO-Festlegung Sieg-Kandidat.
2. Einstufung: technische Altlast. `GrabrauberStolenRole` geschrieben, nie gelesen, nicht bei neuer Runde zurückgesetzt (`gh:521-525`). Risiko: niedrig.

#### `parasit`

1. Einstufung: echter Bug. Codepfad `night:499-500` + `core:106-110`. Tatsächlich: Lynch eines Parasiten mit lebendem Wirt scheitert still, trotzdem Protokoll "wurde gelyncht", `LynchCount+1`, Henker-Hinrichtungen. Erwartet: Lynch als wirkungslos erkannt (Meldung an SL, kein "gelyncht"-Eintrag). Risiko: mittel (SL glaubt, der Parasit sei tot). Test: Parasit mit Wirt lynchen => lebt, Protokoll "Hinrichtung ohne Wirkung".
2. Einstufung: unklare Regel. Codepfad `core:237` (`alive.length===3`). Sprung von 4 auf 2 verfehlt den Sieg. Risiko: mittel. Test: 4 Lebende, Wirt und Parasit sterben in einer Kette => kein bzw. definierter Sieg.
3. Einstufung: echter Bug (bekannt, F7). Codepfad `core:234-237`. Manipulator- und Parasit-Sieg im selben Aufruf: zweiter `triggerWin` überschreibt. Risiko: niedrig. Test: 3 Lebende mit Manipulator und Parasit => ein definierter Sieger oder Mitsieg.

#### `todesprediger`

1. Einstufung: echter Bug. Codepfad `night:191` (MorningCount vor Auflösung) mit `core:156-157`. Tatsächlich: Ein Tod in der Morgenauflösung nach Nacht N erfüllt "night N" und "day N" gleichzeitig. Erwartet: jeder Tod gehört zu genau einer Phase. Risiko: hoch (falscher Solo-Sieg). Regressionstest: Vorhersage "day 1", Wolfsangriff in Nacht 1 => kein Sieg; Vorhersage "night 1" => Sieg.
2. Einstufung: echter Bug. Codepfad `core:157` vs `js/ui/gamelog.js:21-24` (und `gh:1874-1876`). Tatsächlich: Der erste Tag nach Nacht 1 wird als "Tag 2" gelabelt, der Vergleich nutzt `MorningCount=1`. Erwartet: angezeigte und verglichene Tageszahl identisch. Risiko: hoch (SL gibt angezeigte Zahl ein, Treffer bleibt aus). Test: Protokoll zeigt "Tag N", Vorhersage "day N", Lynch an diesem Tag => Sieg.
3. Einstufung: technische Altlast. Codepfad `chunk:599-644` ohne `markOnceUsed` bei `roles:45` once:true. Schritt bleibt jede Nacht sichtbar. Risiko: niedrig. Test: nach Vorhersage kein Nachtschritt mehr.
4. Einstufung: unklare Regel. Codepfad `chunk:621-628`: vergangene oder aktuelle Zeitpunkte akzeptiert. Risiko: mittel. Test: Vorhersage für bereits vergangene Nacht abgelehnt.

## 5. Abweichungen zur älteren Matrix `godot-migration/04`

Die ältere Matrix [`../godot-migration/04-rules-migration-matrix.md`](../godot-migration/04-rules-migration-matrix.md) Abschnitt A ist nicht falsch zitiert worden, aber in folgenden Einstufungen nach erneuter Code-Lektüre nicht haltbar. Zuordnung der alten Werte: verifiziert → `legacy-verified`, widersprüchlich → `legacy-contradictory`, fehlend → `not-found`, unklar → offen (kein direkter Gegenwert). Die ältere Datei wurde **nicht** geändert.

| ID | alt (`godot-migration/04`) | neu | Kurzbegründung |
|---|---|---|---|
| `nachtwaechter` | fehlend | `legacy-broken` | Die Erkennung existiert, aber die einzige Ausgabe (SFX) ist ein No-op; die Kernfunktion "öffentlicher Alarm" findet nie statt. (Nicht not-found, weil die Mechanik im Code vorhanden … |
| `rattenfaenger` | verifiziert | `legacy-broken` | Die Siegbedingung („Sobald ...") ist die Kernfunktion und wird bei Toden belegbar nicht ausgewertet (Bug … |
| `sensentraeger` | verifiziert (Zeitpunkt unklar) | `legacy-contradictory` | siehe [02](02-implemented-roles-audit.md) |
| `spuerhund` | verifiziert | `legacy-contradictory` | Normalfall setzt den Text um; die Wolf-Definition weicht vom autoritativen `isWolf` ab und die Markierungsregel ist offen (DE/EN … |
| `schutzengel` | widersprüchlich (Zeitpunkt) | `legacy-broken` | siehe [02](02-implemented-roles-audit.md) |
| `seuchenwolf` | verifiziert | `legacy-contradictory` | Kernidee funktioniert, aber der Umfang ("alle Schutzeffekte") und der Verbrauch weichen vom Text ab, und der Code behandelt zwei "ignoriert Schutz"-Regeln (Seuchenwolf, Rudelvater) … |
| `schicksalswolf` | verifiziert | `legacy-contradictory` | "in Nacht 4" vs. "ab Nacht 4"; Schutzbehandlung nicht wie … |
| `giftwolf` | unklar | `legacy-verified` | Text wird umgesetzt; offene Punkte sind Regelpräzisierungen, die Bugs betreffen den … |
| `der-weise` | widersprüchlich (Bug F10) | `legacy-broken` | Ein belegter Codefehler (Doppelschutz über `flags.protected`, in React immer aktiv; dazu Schutz-Persistenz) verfälscht die Kernfunktion "überlebt den ersten … |
| `lehrling` | widersprüchlich (Bug F5) | `legacy-broken` | siehe [02](02-implemented-roles-audit.md) |
| `maertyrerin` | verifiziert | `legacy-contradictory` | Kernfunktion (einmaliges Ersatzopfer am Morgen) funktioniert; DE und EN widersprechen sich, Zeitwächter-Reihenfolge ist fehlerhaft, verfälscht die Kernfunktion aber nur im … |
| `besessener-wolf` | verifiziert | `legacy-broken` | Normalpfad (einzelner Tod ohne Abbruch) ist korrekt, aber belegte Fehler verhindern die Mitnahme dauerhaft nach einem Abbruch, verschieben sie bei Liebeskummer in einen falschen Zeitpunkt und zeigen bei jedem Einsatz einen Rohschlüssel. Ein 1:1-Golden-Test … |
| `kutscher` | verifiziert | `legacy-contradictory` | Code ist funktional (keine Fehlfunktion der Kernmechanik gefunden), weicht aber in Rollenvergabe und Auswahlverfahren vom Text ab; 04 "verifiziert" ist zu … |
| `seelentauscher` | widersprüchlich (Bug F4) | `legacy-broken` | Der belegte Fehler F4 verfälscht die Kernfunktion (Rollentausch mit Wolfsrolle erzeugt einen zusätzlichen … |
| `traumdeuter` | unklar | `legacy-contradictory` | Der Text ist vage, der Code liefert eine konkrete, andere Mechanik (Wolf unter drei); 04 "unklar" ist inhaltlich … |
| `feuerteufel` | fehlend | `legacy-broken` | Die Kernfunktion „beim Tod des Ziels" wird durch belegte Fehler verfälscht (Brand ohne Tod, kein Brand bei Tod durch andere … |
| `voodoo-priester` | fehlend | `legacy-contradictory` | Die Umlenkung funktioniert für die Hauptursachen, widerspricht aber dem allgemeinen Text („bei seinem Tod") und enthält eine undokumentierte Abklingzeit; die belegten Bugs betreffen … |
| `blutwolf` | fehlend | `legacy-verified` | Der Code setzt die Rechenregel des Textes nachvollziehbar als SL-Anzeige um; das Fehlen einer digitalen Abstimmung ist eine globale Produktentscheidung, keine … |
| `albtraumwolf` | widersprüchlich (Bug F3) | `legacy-broken` | F3 verfälscht die Kernwirkung: die Blockade wird zum Schutz gegen das eigene … |
| `cerberus` | verifiziert | `legacy-contradictory` | Kopfaufbau und Lynch-Abwehr funktionieren, aber Wahlfreiheit ("kann"), Zusatzwirkung gegen Hexe und F15 weichen vom Text ab; 04 "verifiziert" ist zu … |
| `ritter` | verifiziert | `legacy-contradictory` | Der Kernfall (Rudel tötet Ritter, nächster Wolf stirbt) ist korrekt umgesetzt, der Text verspricht aber jeden Nachttod, der Code nur eine Whitelist; Zielmenge über `cursedWolfAura` und Fenrir-Ausnahme sind nicht im … |
| `rotkaeppchen` | verifiziert | `legacy-contradictory` | Kette und Zuflucht funktionieren; der Apfel wirkt nur für einen Teil der Rollen, und Zielbeschränkung/Dauer weichen vom Text ab bzw. sind dort nicht … |
| `koenig` | unklar | `legacy-contradictory` | Code (jede Nacht) und Text (DE einmalig "in dieser Nacht") widersprechen sich, 04/07 führen es bereits als offene … |
| `dr-victor-frankenstein` | widersprüchlich (Bug F9) | `legacy-broken` | In der React-Oberfläche verfälscht der fehlende Dropdown die Kernfunktion (Rolle wird nicht gewählt), in `game.html` ist die Aktion nicht atomar (Teilzustand bei fehlenden Rollen) und der Apfel-Pfad verliert die Rollenvergabe. Der Normalfall in `game.html` … |
| `doktor` | verifiziert | `legacy-contradictory` | Mechanik läuft zuverlässig, aber "demselben Team" wird bei Solos und Verwandlungen anders beantwortet, als der Text … |
| `faehrtenleser` | verifiziert | `legacy-contradictory` | Die Richtungsberechnung ist korrekt umgesetzt, aber die freiwillige Einmalnutzung ("darf") ist nicht abgebildet und der Assistent verbraucht sie … |
| `schutzgeist` | fehlend (Bug F1) | `legacy-broken` | Code für die Fähigkeit existiert, aber F1 verhindert die Auslösung vollständig, und die Wirkung wäre wegen Reihenfolge/Reset … |
| `amalia` | verifiziert | `legacy-contradictory` | Das Opfer funktioniert, die öffentliche Frage ist nicht modelliert und als Nachtschritt zeitlich … |
| `kriegerin-des-lichts` | verifiziert | `legacy-contradictory` | Code ist lauffähig; Text ("greift an"), Code (kein Treffer-Tod) und Doku 04 ("er stirbt") widersprechen … |
| `detektiv` | verifiziert (Bug F11) | `legacy-broken` | Der Hinweis wird ausgelöst, ist aber durch den Platzhalterfehler inhaltsleer bzw. beim Paritätsfall möglicherweise … |
| `manipulator` | widersprüchlich (Bug) | `legacy-broken` | siehe [02](02-implemented-roles-audit.md) |
| `todesprediger` | verifiziert | `legacy-broken` | Die Kernfunktion (Sieg bei korrekt vorhergesagtem Todeszeitpunkt) wird für Tagesvorhersagen durch die überlappende Zählung und den Versatz zur angezeigten Tagesnummer verfälscht (Bugs 1 und 2, beide mit Zeilenbeleg). Nachtvorhersagen … |

32 von 72 Einstufungen weichen ab.

## 6. Veraltete oder widersprüchliche Aussagen in bestehenden Dokumenten

Diese Dateien wurden bewusst **nicht** geändert (Auftrag §16). Vorschläge für eine spätere Pflege stehen in [`09`](09-executive-summary.md) §8.

| Dokument | Aussage | Befund |
|---|---|---|
| `ROADMAP.md` (Zeilen 45, 153, 265) | „75+ Rollen“ | nicht belegbar; nachweisbar sind 72 |
| `docs/godot-migration/01-current-system-inventory.md` F7 | „zwei Siegprüfer“ | es sind fünf Stellen, die einen Sieger setzen ([`dossiers/solos-a.md`](dossiers/solos-a.md)) |
| `docs/godot-migration/01-current-system-inventory.md` F2 | Beispiele Siegreicher Wolf, Giftwolf, Wolfskind | betrifft zusätzlich Seuchenwolf, Schicksalswolf, Schattenwanderer, Rudelvater, Schwarze Witwe, Schattenhund |
| `docs/godot-migration/01-current-system-inventory.md` Zeile 290 | `PackfatherBlockNextDay` nie gelesen | wird gelesen, aber nie gesetzt ([`dossiers/wolves-a.md`](dossiers/wolves-a.md)) |
| `docs/godot-migration/04-rules-migration-matrix.md` A-13 | Rachsüchtiger Wolf „3 Nächte Pause“ | zwei gesperrte Nächte, erste Nutzung schon in Nacht 1 |
| `docs/godot-migration/04-rules-migration-matrix.md` A-64 | Kriegerin: „Wolf → er stirbt“ | der Code tötet einen getroffenen Wolf nicht (`abilities-roles-chunk.js:554-570`, selbst geprüft) |
| `docs/godot-migration/04-rules-migration-matrix.md` A-47 / A-57 | Ritter „links vor rechts“, Fährtenleser „links = höhere Sitznummer“ | beide „links“ zeigen in entgegengesetzte Richtungen |
| `docs/godot-migration/04-rules-migration-matrix.md` A-44 | Blutwolf „fehlend“ | Rechenregel existiert als SL-Anzeige „V<n>“; nur die Stimmerfassung fehlt, die bewusst physisch bleibt |
| `docs/godot-migration/04-rules-migration-matrix.md` B-9 | Zeilen `night:339`, `night:194` | heute `night.js:350` bzw. `:191` |
| `docs/godot-migration/07-open-questions.md` Q4 | Priorität „Solo vor Wölfen vor Dorf“ | durch DECISION-LOG (DR-02, Kandidatenmenge ohne Priorität) überholt |
| `docs/godot-migration/07-open-questions.md` Q4 | Feuerteufel und Voodoo-Priester „Siegcode fehlt“ | ihre Texte versprechen keinen Sieg; Lücke entsteht nur durch die Einzelsieg-Fraktion |
| `NIGHT-REPORT-abilities.md` Zeilen 76, 84, 109 | Dämonischer und Besessener Wolf als Nachtaktion; Kartenschlucker „passiv“ | beide Wölfe sind Todesreaktionen; der Kartenschlucker hat einen Nachtschritt |
| `GRIMMHAIN_ANALYSE_2026-06-12.md` L2, L5, L7, L8, L12, L13, E1, E2, E3, A1, A5 | diverse Bugs | im heutigen Code behoben (Nachweise in den Dossiers) |
| `AUDIT.md` Zeile 135 | Totenrat-Buttons tot | behoben, `game.html:532` prüft `"Nekromant"` |
| `godot/README.md` Dateiverantwortung `role_catalog.gd` | nennt 6 Rollen | der Katalog enthält 11 |
| `godot/README.md`, `role_catalog.gd`, `test_waldhexe.gd` | „Forest Witch“ | Legacy und Regelregister: „Witch of the Woods“ |
