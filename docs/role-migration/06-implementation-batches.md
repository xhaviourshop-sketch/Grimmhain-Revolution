# 06 · Implementierungs-Chargen

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · **Status:** Planung, nichts implementiert

Alle 61 fehlenden Rollen sind genau einer von 16 Chargen zugeordnet. Die Chargen sind eine technische Planung; welche Rollen tatsächlich umgesetzt werden, entscheidet der Product Owner (Optionen in `05` nicht freigegeben, nächste Einheit RM-DR-017). Eine Charge bündelt Rollen, die dasselbe neue oder erweiterte Kernsystem brauchen. Innerhalb jeder Charge kommen die Rollen der empfohlenen Option B aus [`05`](05-v1-role-options.md) zuerst („1.0-Anteil“); die übrigen Rollen derselben Charge folgen nach 1.0 und nutzen dann das bereits gebaute System.

## 1. Übersicht

| Charge | Name | Rollen | davon 1.0 (Option B) | Größe | Risiko |
|---|---|---:|---|---|---|
| K1 | Sieg- und Zählregeln | 2 (+1 umgesetzt) | `selbstmoerder`, `doppelspion` (umgesetzt: `siegreicher-wolf`) | M bis L | mittel |
| K2 | Informationsmodell | 4 | `waldlaeufer`, `doktor` | M | niedrig |
| K3 | Sitznachbarschaft | 5 | `wahnsinniger-kutscher`, `ritter` | M | mittel |
| K4 | Todes- und Hinrichtungsreaktionen | 4 | `besessener-wolf`, `cerberus` | M | mittel |
| K5 | Abfangregeln und Schutz | 4 | `dorfwache` | L | mittel |
| K6 | Bindungsmodell I | 3 | `loki` | L | hoch |
| K7 | Bedingte und zufallsgestützte Information | 6 | `kopfgeldjaeger` | L | mittel |
| K8 | Rollenblockierung | 3 | `schattenhund` | M | hoch |
| K9 | Marker und Einzelsiege | 5 | `rattenfaenger` | L | hoch |
| K10 | Bindungsmodell II | 3 | – | L | hoch |
| K11 | Wolfsangriff-Modifikation, Durchdringung, verzögerte Tode | 6 | – | XL | hoch |
| K12 | Rollen- und Fraktionswechsel | 4 | – | L | kritisch |
| K13 | Wiederbelebung | 2 | – | L | hoch |
| K14 | Tag, Nominierung, Stimmbezug | 3 | – | M | mittel |
| K15 | Ressourcen und Totenkarten | 5 | – | XL | hoch |
| K16 | Nacht-Transaktion | 1 | – | XL | kritisch |

Größe: S/M/L/XL relativ ([`00`](00-method-and-sources.md) §3.4). Die Größe einer Charge enthält den Aufbau ihres Kernsystems; spätere Rollen derselben Charge sind entsprechend kleiner.

## 2. Kernsysteme

### 2.1 Vorhandene Systeme und ihre Wiederverwendung

| System | Datei | Trägt heute | Wiederverwendbar für | Grenze |
|---|---|---|---|---|
| `KillPipeline` | `godot/core/rules/kill_pipeline.gd` | jeden Tod, Todesfolgen Wolfskind/Lehrling, Reaktion einreihen, vorläufiger Sieg | alle Rollen mit Tod | Abfangstufe fest verdrahtet: nur Schutzengel und Waldhexe gegen Rudel-`NIGHT_KILL` |
| `StepQueue` | `step_queue.gd` | Nachtplan nach Priorität, Snapshot, `StepDropped`, Reaktionsschritte | alle Rollen mit Nachtschritt | Schrittarten und `SKIPPABLE_BY_KIND` fest; keine Verfügbarkeitsbedingung je Rolle außer Wolfskind/Lehrling; tote Handelnde entfallen immer |
| `PendingPrompt` | `pending_prompt.gd` | ein- und mehrstufige, abbrechbare Prompts | Zielwahl, Ja/Nein, Mehrfachwahl | `owner`/`kind` als Konstanten je Rolle |
| Reaktionswarteschlange | `reaction.gd`, `kill_pipeline.gd` | Sensenträger (`KIND_CURSE`) | Besessener Wolf, Dämonischer Wolf, Schutzgeist | nur eine Reaktionsart |
| `RoleTransition` | `role_transition.gd` | Lehrling-Erbe, `set_role` | König Lykaon, Seelentauscher, Frankenstein, Kutscher, Grabräuber | kein Einhängepunkt für Wächter am Tor, kein Doppelwechsel |
| `SeededRng` | `seeded_rng.gd` | Rollenverteilung, Lehrling-Optionen | alle Zufallsrollen (RM-DR-015) | keine |
| `WinRules` / `WinCandidate` | `win_rules.gd`, `win_candidate.gd` | Dorf, Wölfe, Manipulator als Kandidatenmenge | alle Siegbedingungen | Einzelsiege fest im Code, keine Gewichte, keine ereignisbasierten Siege |
| `GmCorrections` | `gm_corrections.gd` | 20 Korrekturarten, `declare_winner`, `revive` | Korrektur jeder neuen Rolle | je Rolle neue Korrekturarten nötig |
| `InformationRules` / `InfoRecord` | `information_rules.gd`, `info_record.gd` | Orakel: Wahrheit, ermittelt, gezeigt | alle Informationsrollen | Ergebnis ist immer eine Rolle; Feld `oracle_id` |
| `Protections` | `protections.gd` | Schutzengel je Nacht | Schutzgeist | nur eine Schutzquelle |
| Erscheinung `appears_as` | `player.gd`, `information_rules.gd` | Trugbilderwolf, verwandeltes Wolfskind | Dämonischer Wolf, König Lykaon | Setzen nur im Setup und per Korrektur |
| Nominierungen | `nomination.gd`, `Player.ever_nominated` | Manipulator, Spiegelwolf | Korrupter Richter, Henker | keine Nominierungsquelle „Rolle“ |
| `ExecutionRules` | `execution_rules.gd` | Hinrichtung, Spiegelung | alle Hinrichtungsreaktionen | nur eine Sonderregel, keine Reihenfolge |
| `StateCodec` / Replay | `state_codec.gd`, `rules_engine.gd` | versionierter Spielstand, Replay-Prüfung | jede Charge | jede neue Zustandsart erhöht das Schema |
| Ereignissichtbarkeit | `visibility.gd`, `game_event.gd` | gm / actor / public | Informations- und Ansagerollen | öffentliche Projektion noch nicht gebaut |

### 2.2 Neue Kernsysteme (nur, wo eine Rolle sie belegt braucht)

| ID | System | Belegt benötigt von | Eingeführt in | Option |
|---|---|---|---|---|
| N-01 | Siegregel-Erweiterung: Paritätsgewicht je Rolle, rollenbezogene Einzelsiegkandidaten als Liste statt Einzelfall, ereignisbasierte Siege (Bedingung zum Todeszeitpunkt gespeichert) | `siegreicher-wolf`, `doppelspion`, `selbstmoerder`, später `rattenfaenger`, `parasit`, `todesprediger`, `hades` | K1 | A |
| N-02 | Allgemeines Informationsmodell: `InfoRecord` mit Ergebnistyp (Rolle, Anzahl, ja/nein, Namensliste, Richtung), handelnder Rolle und derselben Trennung Wahrheit/ermittelt/gezeigt | `waldlaeufer`, `doktor`, später `kopfgeldjaeger`, `koenig`, `faehrtenleser`, `spuerhund`, `traumdeuter`, `die-gebundenen`, `dorfchronistin` | K2 | A |
| N-03 | Abfangregel-Liste in der `KillPipeline` mit fester Priorität, Ursachenfilter und Quellenprotokoll (ersetzt die fest verdrahtete Schutzengel-/Waldhexen-Stufe ohne Verhaltensänderung) | `dorfwache`, später `der-weise`, `maertyrerin`, `dorfschmied`, `parasit`, `voodoo-priester`, `schattenwanderer`, `nekromant`, `hades` | K5 | A |
| N-04 | Ursachen-Attribute am `KillEvent` (`wolf_attack`, `execution`, `pierces`) | `dorfwache`, `ritter`, `rudelvater`, `seuchenwolf` (RM-DR-004, RM-DR-005) | K3/K5 | A |
| N-05 | `SeatNeighbors`: Nachbarn und Richtung über `seat_order` | `wahnsinniger-kutscher`, `ritter`, später `nachtwaechter`, `faehrtenleser`, `detektiv`, `feuerteufel`, `pestbringerin`, `blutwolf` | K3 | A |
| N-06 | Todesfolgen ohne Entscheidung als Liste (wie Wolfskind/Lehrling) und weitere Reaktionsarten | `ritter`, `besessener-wolf`, später `loki`, `daemonischer-wolf`, `schutzgeist`, `feuerteufel`, `detektiv` | K3/K4 | A |
| N-07 | Hinrichtungsregeln als geordnete Liste in `ExecutionRules` (Legacy-Reihenfolge `doLynchFlow`, `js/core/night.js:421-504`) | `wahnsinniger-kutscher`, `cerberus`, `selbstmoerder`, später `fenrir`, `henker`, `der-weise`, `voodoo-priester`, `rudelvater` | K3/K4 | A |
| N-08 | Bindungsmodell (Paar, Wirt, Kette; Typ, Richtung, Status, Verhalten bei Tod und Wiederbelebung) | `loki`, später `schwarze-witwe`, `schattenwanderer`, `parasit`, `rotkaeppchen`, `voodoo-priester` | K6 | B |
| N-09 | Dauerhafte Statusmarker mit Besitzer, Quelle, Sichtbarkeit und Ablauf | `rattenfaenger`, später `spuerhund`, `henker`, `pestbringerin`, `feuerteufel`, `prophet-des-untergangs`, `giftwolf`, `schicksalswolf` | K9 | B |
| N-10 | Zähler und Verfügbarkeitsbedingungen je Person im Nachtplan (verallgemeinert `ABILITY_USE_KEYS` und die Wolfskind/Lehrling-Sonderfälle) | `cerberus` (Köpfe), `kopfgeldjaeger` (Aktivierung), später `koenig`, `henker`, `fenrir`, `dorfschmied`, `rachsuechtiger-wolf` | K4/K7 | B |
| N-11 | Rollenblockierung mit Fraktionsfilter und Ablauf (neuer `StepDropped`-Grund) | `schattenhund`, später `albtraumwolf`, `der-weise`, `zeitwaechter` | K8 | B |
| N-12 | Zeitlich verzögerte Effekte (Termin an Nacht- oder Tageszähler) | `giftwolf`, `schwarze-witwe`, `rudelvater`, `der-weise` (Debuffdauer), `pestbringerin` | K11 | – |
| N-13 | Wiederbelebung als Regel (nicht nur Korrektur) mit Rücksetzliste | `dr-victor-frankenstein`, `kutscher` | K13 | – |
| N-14 | Tagesaktionen mit Prompt am Tag | `amalia`, `nekromant` (Benennung), `korrupter-richter` (falls Tag) | K14 | – |
| N-15 | Totenkarten-Effektmodell (mindestens Ziehen, Tauschen) | `kartenschlucker`, Kartenbedingungen von `kutscher`, `dr-victor-frankenstein` | K15 | – |
| N-16 | Nacht-Transaktion mit Rücknahme | `zeitwaechter` | K16 | – |
| N-17 | Einhängepunkt „neue Wölfe blockiert“ und Scheinrolle bei Rollenwechsel in `RoleTransition`; Doppelwechsel | `waechter-am-tor`, `koenig-lykaon`, `seelentauscher` | K12 | C (Lykaon) |
| N-18 | Öffentliche Ansage-Ereignisse aus Regeln | `nachtwaechter`, `detektiv`, `schutzgeist`, `blutpriester` | K3 (nach 1.0) | C (Nachtwächter) |

Nicht als neues System geplant: Stimmsystem (ausgeschlossen, RM-DR-008), Besuchs- oder Zielhistorie (keine Rolle belegt sie zwingend; `die-ewigen` nur bei einer bestimmten Auslegung von RM-DR-104), Stummschaltung (keine Rolle).

## 3. Charge K1 · Sieg- und Zählregeln und die nächste Einheit

**Rollen Charge K1 (0):** –

**Nachtrag Rollenaudit:** `selbstmoerder` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `doppelspion` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit 2026-09-27:** `siegreicher-wolf` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)); die Bewertung unten bleibt als Planungsstand erhalten.

**Konsolidierung 2026-09-27:** Die frühere Fassung dieses Abschnitts nannte K1 als Ganzes die erste Einheit, schätzte „S bis M, Risiko niedrig“, legte die nächste Schemanummer fest und nannte RM-DR-007 und RM-DR-016 als Blocker. Diese Punkte sind korrigiert: RM-DR-007 ist entschieden, RM-DR-016 ist für K1 nicht nötig, eine Schemanummer wird nicht vorab festgelegt, und die Größe ist unten neu begründet. Die Auswahl der Rollen ist eine Produktentscheidung (RM-DR-017) und nicht freigegeben.

### 3.1 Bewertung: K1 zusammen oder eine kleinere Einheit?

| Kriterium | nur `siegreicher-wolf` | `siegreicher-wolf` + `doppelspion` (K1a) | alle drei (K1) |
|---|---|---|---|
| Wiederverwendung vorhandener Systeme | nur `WinRules.evaluate` und `RoleCatalog` | zusätzlich `WinCandidate` mit personenbezogenem Einzelsiegkandidaten nach dem Muster des Manipulators | zusätzlich `ExecutionRules` und ein am Todeszeitpunkt festgehaltener Umstand |
| Neue ungeklärte Regeln (produktentscheidung) | 0 | 3 (RM-DR-155.1, .3, .4) | 6 (zusätzlich RM-DR-138.1, .3, .4) |
| Neues Konzept | Gewicht in der Paritätsprüfung | Ausnahme von „alle erfüllten Siege werden vorgeschlagen“ (nur falls RM-DR-155.3 = A) | zusätzlich Sieg, der an einem vergangenen Ereignis hängt; Verhalten nach Ablehnung neu |
| Wechselwirkungen | Parität, Lehrling-Erbe, Orakel | zusätzlich Dorfkandidat, Manipulator, Kandidatenprüfung beim Laden | zusätzlich Hinrichtung, Spiegelwolf, Sensenträger-Reaktion vor der verbindlichen Prüfung, Wiederbelebung |
| Späterer Nutzen | Gewichtung für spätere Zählungen | Vorlage für jede weitere Einzelsiegrolle mit Zustandsbedingung (Rattenfänger, Parasit) | Vorlage für ereignisabhängige Siege (Todesprediger) |
| Wirkung auf die parallele Oberfläche | eine neue Rolle im Setup (siehe §3.7) | zwei neue Rollen, eine zweite Einzelsiegrolle für die Pflicht „mindestens eine Einzelsiegrolle“ | drei neue Rollen |

**Empfehlung (keine Entscheidung):** K1a, also `siegreicher-wolf` und `doppelspion` als nächste Spezifikationseinheit; `selbstmoerder` als eigene Folgeeinheit K1b. Begründung: Beide Rollen sind zustandsbasiert und nutzen vorhandene Muster. Der Selbstmörder führt als einzige ein neues Siegkonzept ein, dessen Ablehnungsverhalten erst entschieden werden muss (RM-DR-138.4). Falls die Doppelspion-Fragen nicht rechtzeitig beantwortet werden, ist `siegreicher-wolf` allein eine sinnvolle, sehr kleine Einheit.

### 3.2 Rollen und Standardauslegung

| Rolle | Kernregel laut Legacy (Beleg) | Offene Punkte |
|---|---|---|
| `siegreicher-wolf` | zählt lebend in der Wolfsparität als zwei Wölfe; nicht bei „kein Wolf lebt“, nicht bei Zählungen anderer Rollen (`js/ui/core.js:21-29`, `:311-312`, [Dossier](dossiers/wolves-a.md#siegreicher-wolf)); das Regelregister sieht die Ausnahme bereits vor (G-SIEG-2: „Siegreicher Wolf ist nicht enthalten“) | keine Produktentscheidung |
| `doppelspion` | zählt nie als Wolf; lebt er, wenn kein Wolf mehr lebt, gewinnt er statt des Dorfs (`js/ui/core.js:13`, `:227-230`, `:314-320`, [Dossier](dossiers/solos-a.md#doppelspion)); „wacht mit den Werwölfen auf“ ist eine Tischregel ohne App-Schritt | RM-DR-155.1, .3, .4 |
| `selbstmoerder` | wird er gelyncht, während vorher mindestens 5 Personen tot sind, gewinnt er (`js/core/night.js:421-423`, `:474-482`, [Dossier](dossiers/solos-a.md#selbstmoerder)) | RM-DR-138.1, .3, .4; RM-DR-138.2 nur für den späteren Henker |

### 3.3 Vollständige Abhängigkeitsliste

Legende: **bestehend** = durch eine verbindliche Quelle beantwortet (Quelle genannt); **neu** = Produktentscheidung (ID); **technisch** = folgt aus bestehenden Regeln, die Spezifikation legt nur die Umsetzung fest; **–** = nicht anwendbar.

| Frage | `siegreicher-wolf` | `doppelspion` | `selbstmoerder` |
|---|---|---|---|
| Grundregel mehrerer Siege | bestehend: G-SIEG-3, DR-02 | bestehend: G-SIEG-3, DR-02; Ausnahme für den Dorfkandidaten **neu** RM-DR-155.3 | bestehend: G-SIEG-3, DR-02 |
| Muss die Person leben? | bestehend: Rollentext „solange er lebt“ | **neu** RM-DR-155.1 | – (gewinnt durch seinen Tod) |
| Zählung in der Parität | Gewicht 2, nur Parität: Standardauslegung ohne Widerspruch (G-SIEG-2 sieht sie vor) | bestehend: zählt als Nicht-Wolf (G-SIEG-2) | bestehend: Nicht-Wolf (G-SIEG-2) |
| Bedingung | technisch: aus dem Zustand berechnet | bestehend: „kein Wolf lebt“ = G-SIEG-1 (`counts_as_wolf`) | **neu** RM-DR-138.1 (vor oder einschließlich), RM-DR-138.3 (wer zählt als tot) |
| Welche Hinrichtung zählt? | – | – | bestehend: Hinrichtung `LYNCH`, auch per Spielleiterkorrektur (Korrekturrunde 4); Tod durch Spiegelung zählt nicht (G-TOD-3, RM-DR-138.5); Henker später (RM-DR-138.2) |
| Ablehnung durch den Spielleiter | bestehend: erneutes Angebot nur nach relevanter Zustandsänderung (Umsetzungsentscheidung 3 der README, AS-C04) | bestehend wie links | **neu** RM-DR-138.4: Die heutige Prüfung würde einen am Hinrichtungsmoment hängenden Sieg nach jedem weiteren Tod erneut anbieten |
| Wiederbelebung und erneuter Tod | technisch: tot zählt 0, wiederbelebt wieder 2 (G-SIEG-2 zählt lebende Wölfe) | technisch, abhängig von RM-DR-155.1 | **neu** über RM-DR-138.3 und .4; erneute Hinrichtung nach Wiederbelebung ist ein neues Ereignis |
| Gleichzeitige Kandidaten | bestehend: Wolfskandidat neben Manipulator usw. (G-SIEG-3) | **neu** nur für das Dorf (RM-DR-155.3); Manipulator bleibt bestehend | bestehend: z. B. Wolfsparität durch seinen Tod plus Selbstmörder-Kandidat (G-SIEG-3) |
| Lehrling erbt die Rolle | bestehend: Gewicht sofort (Korrekturrunde Regelkern 2) | bestehend: Fraktion und Siegbedingung sofort | bestehend: Siegbedingung sofort; Erbe beim Tod des Meisters läuft vor der Siegprüfung (DECISION-LOG Lehrling) |
| Mehrere Personen mit der Rolle (Setup oder Erbe) | technisch: jede zählt 2 | technisch: je Person ein Kandidat (Muster G-SIEG-3 „je Manipulator“) | technisch: je Person ein Kandidat |
| Spielleiterkorrekturen | bestehend: `set_role`, `revive`, `kill` stoßen die Siegprüfung an (README Umsetzungsentscheidung 12) | bestehend wie links; `declare_winner` bleibt immer möglich (G-GM-1, DR-02) | bestehend: `execute` zählt als Hinrichtung; `kill` (Ursache `GM_CORRECTION`) ist keine Hinrichtung |
| Speichern und Laden | technisch: Gewicht ist Katalogwissen, wird nicht gespeichert | technisch: neuer Kandidatengrund in Spielstand und Ladeprüfung | technisch: der Umstand zum Hinrichtungszeitpunkt muss gespeichert werden, weil Reaktionen die Totenzahl bis zur verbindlichen Prüfung ändern können |
| Orakel und Waldhexe | bestehend: Orakel sieht `werwolf` (DR-07), Waldhexe die echte Rolle | bestehend: Orakel sieht `doppelspion` (keine besondere Erscheinung, DR-07) | bestehend: echte Rolle |
| Tischablauf | – | **neu** RM-DR-155.4 (was die Wölfe erfahren); technisch: Hinweis im Rudelschritt, keine Teilnahme an der gespeicherten Rudelwahl (Regelregister §2, RM-DR-155.5) | – |
| Obergrenze im Setup | nicht nötig (RM-DR-016) | nicht nötig | nicht nötig |

### 3.4 Benötigte vorhandene Systeme

`WinRules.evaluate`, `record_provisional`, `finalize_if_ready` und `state_is_consistent`; `WinCandidate` (Art, Grund, begünstigte Personen, `REASONS`); `KillPipeline` (Todeszeitpunkt); `ExecutionRules.execute` (nur Selbstmörder); `RoleCatalog`; `InformationRules`; `GmCorrections` (`set_role`, `revive`, `declare_winner`); `StateCodec` und Replay.

### 3.5 Technische Fakten und Schätzung

**Belegte technische Tatsachen (aus dem Code am Basiscommit, `godot/core/` bis `5eb5f2a` unverändert):**
- `WinRules.evaluate` wird nach **jedem** Tod (vorläufiger Status) und bei jeder verbindlichen Prüfung aufgerufen (`win_rules.gd`, `kill_pipeline.gd:46`, `rules_engine.gd:22`). Eine geänderte Paritätsrechnung wirkt damit auf jede Partie mit dieser Rolle und auf die Ereignisse `WinStatusProvisional` und `WinStatusFinal`.
- Die Ereignisargumente `wolves` und `non_wolves` werden in drei Szenarien geprüft (`as-c01`, `as-c03`, `as-c04`). Die Spezifikation muss festlegen, ob diese Zahlen Köpfe oder Gewicht bedeuten, ohne die bestehenden Szenarien umzudeuten.
- `WinCandidate.REASONS` ist eine feste Liste, und `state_is_consistent` prüft offene und bestätigte Manipulator-Kandidaten beim Laden gegen den Zustand. Jeder neue Kandidatengrund braucht eine eigene Ladeprüfung.
- Offene Kandidaten verhindern die nächste Prüfung, und nach `RejectWin` wird erst nach einem weiteren Tod oder einer Korrektur neu geprüft (`finalize_if_ready`, README Umsetzungsentscheidungen 2 und 3). Ein Sieg, der an einem vergangenen Ereignis hängt, würde dabei erneut entstehen, solange nichts anderes festgelegt ist.
- `KillEvent` speichert heute Ursache, Quelle, Ziel, Phase, Nummer und Reihenfolge, aber keine Totenzahl. Für den Selbstmörder ist also eine Änderung gespeicherter Daten nötig, für den Siegreichen Wolf voraussichtlich nicht; für den Doppelspion nur der neue Kandidatengrund.
- Jede Änderung am Regelverhalten erhöht die Regelversion; eine Änderung gespeicherter Felder erhöht zusätzlich die Schemaversion. **Welche Nummer** folgt, ergibt sich erst aus dem dann aktuellen Stand (andere Arbeiten können vorher eine Version belegen) und wird hier nicht festgelegt.
- Die Rollen erscheinen automatisch im Rollen-Setup von Grimmhain-1, sobald sie im `RoleCatalog` stehen (§3.7).

**Schätzung (keine Tatsache):**

| Einheit | Größe | Risiko | Begründung |
|---|---|---|---|
| nur `siegreicher-wolf` | S | niedrig bis mittel | eine Rechenregel, aber in jeder Siegprüfung wirksam; Ereignisargumente und bestehende Szenarien müssen stabil bleiben |
| K1a (`siegreicher-wolf`, `doppelspion`) | M | mittel | zusätzlich ein neuer Kandidatengrund mit Ladeprüfung und, bei RM-DR-155.3 = A, eine Ausnahme in der Kandidatenerzeugung, die Dorf-, Manipulator- und Paritätsfälle berührt |
| K1 gesamt | M bis L | mittel | zusätzlich ein neues Siegkonzept mit gespeichertem Ereignisumstand, eigenem Ablehnungsverhalten und Bezug zu Hinrichtung und Reaktionswarteschlange |

Die frühere Angabe „S bis M, Risiko niedrig“ für K1 gesamt war zu optimistisch: Sie übersah, dass die Paritätsrechnung in jeder Siegprüfung wirkt und dass ein ereignisabhängiger Sieg mit der bestehenden Ablehnungslogik kollidiert.

### 3.6 Reihenfolge

1. `siegreicher-wolf` (prüft die Gewichtung, ohne eine neue Kandidatenart),
2. `doppelspion` (erste zusätzliche zustandsbasierte Einzelsiegregel),
3. später `selbstmoerder` als K1b (erste ereignisabhängige Siegregel).

### 3.7 Übergabe an Grimmhain-1 (nicht umgesetzt)

Auf dem noch nicht gemergten Branch `origin/claude/sleepy-babbage-u2o0i2` (Stand `7837809`) baut Grimmhain-1 ein Rollen-Setup, das Rollen, Fraktion, `counts_as_wolf`, Nachtpriorität und `max_copies` aus dem `RoleCatalog` liest (`docs/ui/role-setup.md` dort). Folgen für jede neue Rolle:

- `godot/tests/ui/test_role_model.gd` prüft dort „exakt elf produktive Rollen“ (`test_catalog_adapter_matches_rule_catalog`). Der Test wird rot, sobald eine Rolle im Katalog hinzukommt. Die Zahl muss dann gemeinsam angepasst oder aus dem Katalog abgeleitet werden.
- Anzeigenamen und Kurztexte brauchen Schlüssel `ui.role.<id>.name` und `ui.role.<id>.short` in `godot/content/i18n/` (Bereich Grimmhain-1).
- `RolePresentation.ROLE_ORDER` legt die Reihenfolge in der Oberfläche fest; ohne Eintrag steht eine neue Rolle am Ende ihrer Gruppe.
- Der Setup-Vorschlag setzt heute genau einen Manipulator als Einzelsiegrolle; ein Doppelspion wäre eine zweite wählbare Einzelsiegrolle.

Historischer Stand: Diese Übergabe bezieht sich auf `7837809`. Dort war die Scheinrolle des Trugbilderwolfs noch vorbelegt; seit `fd25fff` (Branchstand `53a3c7d`) wählt sie ausdrücklich der Spielleiter (DR-08). Der Test auf „exakt elf produktive Rollen“ gilt unverändert.

Keine dieser Dateien gehört zum Bereich von Grimmhain-2. Die Rollenumsetzung sollte deshalb erst nach Abstimmung mit Grimmhain-1 in den Katalog gehen.

### 3.8 Teststrategie

Tests zuerst (rot), dann Umsetzung. Mindestens für jede gewählte Rolle die Zeilen der Tabelle in §3.3, jeweils mit Speichern/Laden und bytegleichem Replay, dazu: Leak-Test (kein Einzelsiegkandidat in öffentlichen Ereignissen vor `ConfirmWin`), keine Kandidaten bei offenem Prompt oder offener Reaktion (G-GM-3), beschädigte Spielstände mit unpassendem Kandidatengrund, alle bestehenden Tests unverändert grün. Weil mehrere Personen derselben Rolle durch Lehrling oder Korrektur immer möglich sind, gehören Tests mit zwei Personen derselben Rolle dazu, unabhängig von einer Setup-Grenze.

### 3.9 Abnahmekriterium

Die gewählten Rollen und die zugehörigen Produktentscheidungen stehen im Decision Log; ein Regelregister mit DE- und EN-Text ist freigegeben; alle neuen und bestehenden headless Tests sind grün; die Abstimmung mit Grimmhain-1 (§3.7) ist erfolgt; `godot/README.md` ist aktualisiert. Headless-Tests belegen dabei nur den Regelkern, keine Bedienung über die Oberfläche.

## 4. Alle Chargen

Format je Charge: Rollen, gemeinsame Mechanik, neue Systeme, wiederverwendbare Systeme, Reihenfolge, Blocker und Entscheidungen, Teststrategie, Größe, Risiko, Abnahmekriterium. Genannte Entscheidungen mit Status „entschieden“ (RM-DR-001, RM-DR-007, RM-DR-009.1 u. a., siehe [`08`](08-decision-request.md)) sind nur noch Verweise auf die geltende Regel, keine Blocker. „1.0“ bezieht sich auf die nicht freigegebene Option B.

### K1 · Sieg- und Zählregeln

Siehe §3.

### K2 · Informationsmodell

**Rollen Charge K2 (0):** –

**Nachtrag Rollenaudit:** `doktor` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `waldlaeufer` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `die-gebundenen` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `dorfchronistin` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Informationen, die eine Person nachts erhält, ohne Zustand zu ändern: Anzahl lebender Wölfe, gleiche Siegseite zweier Personen, Mitglieder der eigenen Gruppe, Anzahl der Einzelsiegrollen.
- **Neue Systeme:** N-02.
- **Wiederverwendbar:** `StepQueue`, `PendingPrompt`, `InformationRules`, Ereignissichtbarkeit, Leak-Tests des Orakels.
- **Reihenfolge:** `waldlaeufer` (1.0) → `doktor` (1.0) → `dorfchronistin` → `die-gebundenen` (mehrere Personen mit dieser Rolle sind ihr Kern).
- **Entscheidungen:** RM-DR-002.3, RM-DR-014, RM-DR-016.1 (nur falls `die-gebundenen` eine Grenze bekommen soll); RM-DR-145 (`doktor`), RM-DR-147 (`waldlaeufer`).
- **Tests:** Ergebnis je Wolfsart (verwandelt, Trugbild), Übersteuerung des gezeigten Ergebnisses, Actor- und Public-Leak, Save/Load mit offenem Prompt, Replay, Tote und Selbstwahl.
- **Größe / Risiko:** M / niedrig.
- **Abnahme:** Orakel-Tests unverändert grün, alle vier Rollen nutzen dasselbe Informationsmodell.

### K3 · Sitznachbarschaft

**Rollen Charge K3 (0):** –

**Nachtrag Rollenaudit:** `detektiv` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `faehrtenleser` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `ritter` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `nachtwaechter` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `wahnsinniger-kutscher` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Wirkungen und Informationen, die von der Sitzlage abhängen.
- **Neue Systeme:** N-05, N-06 (Ritter-Vergeltung als Todesfolge), N-07 (Kutscher-Nebentode), N-04; nach 1.0 N-18 (öffentliche Ansage für Nachtwächter und Detektiv).
- **Wiederverwendbar:** `seat_order`, `KillPipeline`, `ExecutionRules`, `SeededRng` (Detektiv), `InfoRecord` (Fährtenleser).
- **Reihenfolge:** `wahnsinniger-kutscher` (1.0) → `ritter` (1.0) → `nachtwaechter` → `faehrtenleser` → `detektiv`.
- **Entscheidungen:** RM-DR-003, RM-DR-004, RM-DR-009; RM-DR-116, RM-DR-136, RM-DR-102, RM-DR-146, RM-DR-153.
- **Tests:** Sitztausch vor der Wirkung, tote Nachbarn, Gleichstand links/rechts, Nachbar ist Sensenträger (Kette), Kutscher-Hinrichtung mit Spiegelwolf-Nominierung, Replay.
- **Größe / Risiko:** M / mittel.
- **Abnahme:** eine einzige Richtungsfunktion für alle fünf Rollen; Test „Sitztausch ändert Ergebnis“.

### K4 · Todes- und Hinrichtungsreaktionen

**Rollen Charge K4 (0):** –

**Nachtrag Rollenaudit:** `henker` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `cerberus` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `fenrir` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `besessener-wolf` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Wirkung beim eigenen Tod oder bei einer Hinrichtung.
- **Neue Systeme:** N-06 (Reaktionsart „Mitnahme“), N-07 (Abwehr einer Hinrichtung), N-10 (Köpfe, Stufen).
- **Wiederverwendbar:** Reaktionswarteschlange, `ExecutionRules`, `ability_uses`.
- **Reihenfolge:** `besessener-wolf` (1.0) → `cerberus` (1.0) → `fenrir` → `henker`.
- **Entscheidungen:** RM-DR-001, RM-DR-004, RM-DR-009; RM-DR-124, RM-DR-135, RM-DR-125, RM-DR-130.
- **Tests:** Reaktion nachts am Morgen, am Tag sofort, Kette mit Sensenträger, abgewehrte Hinrichtung zählt (Henker), Reaktion überlebt Save/Load, kein Abbruch (Legacy-Bug X-03).
- **Größe / Risiko:** M / mittel.
- **Abnahme:** feste, dokumentierte Reihenfolge aller Hinrichtungsregeln inklusive Spiegelwolf.

### K5 · Abfangregeln und Schutz

**Rollen Charge K5 (0):** –

**Nachtrag Rollenaudit:** `dorfschmied` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `schutzgeist` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `maertyrerin` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `dorfwache` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Regeln, die einen Tod verhindern, ersetzen oder in einen anderen Tod umwandeln.
- **Neue Systeme:** N-03, N-04.
- **Wiederverwendbar:** `Protections`, `KillPrevented`, Waldhexen-Rettung.
- **Reihenfolge:** Umbau der Abfangstufe ohne Verhaltensänderung (alle Schutzengel- und Waldhexen-Tests grün) → `dorfwache` (1.0) → `dorfschmied` → `schutzgeist` (Schritt für eine tote Person) → `maertyrerin`.
- **Entscheidungen:** RM-DR-004, RM-DR-005, RM-DR-015; RM-DR-119, RM-DR-154, RM-DR-148, RM-DR-118.
- **Tests:** Reihenfolge mehrerer Abfangregeln, ein `KillPrevented` mit allen Quellen, Durchdringung (nach K11), Save/Load.
- **Größe / Risiko:** L / mittel.
- **Abnahme:** Abfangregeln als geordnete Liste; bestehende Tests unverändert grün.

### K6 · Bindungsmodell I

**Rollen Charge K6 (0):** –

**Nachtrag Rollenaudit:** `schattenwanderer` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `schwarze-witwe` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `loki` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** zwei Personen, deren Tode gekoppelt sind.
- **Neue Systeme:** N-08, N-06 (Kettentod als Todesfolge).
- **Wiederverwendbar:** `KillPipeline`, `GmCorrections`, `WolfChildBond`/`ApprenticeBond` als Vorbild.
- **Reihenfolge:** `loki` (1.0) → `schwarze-witwe` (setzt Loki voraus) → `schattenwanderer`.
- **Entscheidungen:** RM-DR-009, RM-DR-011, RM-DR-014; RM-DR-101, RM-DR-113, RM-DR-110.
- **Tests:** Kettentod nachts und am Tag, Kette mit Sensenträger und Wolfskind, Wiederbelebung, gleichzeitiger Tod beider, Siegprüfung nach Kette.
- **Größe / Risiko:** L / hoch.
- **Abnahme:** Fixpunkt ohne Endlosschleife, identisches Replay.

### K7 · Bedingte und zufallsgestützte Information

**Rollen Charge K7 (0):** –

**Nachtrag Rollenaudit:** `blutpriester` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `kriegerin-des-lichts` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `koenig` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `kopfgeldjaeger` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `traumdeuter` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `spuerhund` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Informationen, die an eine Bedingung gebunden sind oder zufällig ausgewählt werden; teils mit Tod.
- **Neue Systeme:** N-10 (Verfügbarkeit), Erweiterung N-02 (Namensliste), N-09 (falsche Spur des Spürhunds).
- **Wiederverwendbar:** `SeededRng` mit Übernahme erst bei Bestätigung (wie Lehrling), `OverrideShownRole`-Muster.
- **Reihenfolge:** `kopfgeldjaeger` (1.0) → `koenig` → `traumdeuter` → `kriegerin-des-lichts` → `blutpriester` → `spuerhund`.
- **Entscheidungen:** RM-DR-002, RM-DR-014, RM-DR-015; RM-DR-139, RM-DR-140, RM-DR-129, RM-DR-152, RM-DR-128, RM-DR-105.
- **Tests:** gleicher Seed gleiches Ergebnis, Abbruch verbraucht keinen Zufall, Übersteuerung, Aktivierung durch Erbe.
- **Größe / Risiko:** L / mittel.
- **Abnahme:** kein `Math.random`-Äquivalent, alle Ergebnisse als Informationsdatensatz.

### K8 · Rollenblockierung

**Rollen Charge K8 (0):** –

**Nachtrag Rollenaudit:** `der-weise` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `albtraumwolf` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `schattenhund` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Fähigkeiten anderer entfallen für eine oder mehrere Nächte.
- **Neue Systeme:** N-11; für `der-weise` zusätzlich N-12 (Dauer) und N-03 (Einmalrettung).
- **Wiederverwendbar:** `StepQueue.drop_unactionable`, Nachtplan-Snapshot.
- **Reihenfolge:** `schattenhund` (1.0) → `albtraumwolf` → `der-weise`.
- **Entscheidungen:** RM-DR-010, RM-DR-014; RM-DR-123, RM-DR-134, RM-DR-114.
- **Tests:** blockierter Schritt entfällt mit Grund, keine Rettung durch Blockade (Legacy-Bug F3), Blockade über Save/Load, Lehrling erbt blockierte Rolle.
- **Größe / Risiko:** M / hoch (Der Weise).
- **Abnahme:** Blockade ändert nie den Nachtplan-Snapshot, nur den Status.

### K9 · Marker und Einzelsiege

**Rollen Charge K9 (0):** –

**Nachtrag Rollenaudit:** `feuerteufel` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `prophet-des-untergangs` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `pestbringerin` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `rattenfaenger` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `die-ewigen` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** dauerhafte Markierungen, aus denen Einzelsiege oder Folgetode entstehen.
- **Neue Systeme:** N-09, N-01 (weitere Einzelsiege), N-05 (Nachbarn), N-12 (Ausbreitung).
- **Wiederverwendbar:** `WinCandidate`, `KillPipeline`.
- **Reihenfolge:** `rattenfaenger` (1.0) → `pestbringerin` → `feuerteufel` → `prophet-des-untergangs` → `die-ewigen`.
- **Entscheidungen:** RM-DR-006, RM-DR-003 (Grundregel der Siegkandidaten ist entschieden, RM-DR-007); RM-DR-103, RM-DR-120, RM-DR-131, RM-DR-121, RM-DR-104.
- **Tests:** Sieg auch nach Tod der letzten unmarkierten Person (Legacy-Bug), Marker über Wiederbelebung, gleichzeitige Kandidaten.
- **Größe / Risiko:** L / hoch.
- **Abnahme:** jede Einzelsiegbedingung nach jeder relevanten Änderung geprüft, nicht nur nach eigener Aktion.

### K10 · Bindungsmodell II

**Rollen Charge K10 (0):** –

**Nachtrag Rollenaudit:** `voodoo-priester` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `rotkaeppchen` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `parasit` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Bindungen mit Schutz- oder Umlenkwirkung.
- **Neue Systeme:** keine neuen; N-08 und N-03 werden kombiniert; Rotkäppchen-Apfel braucht eine Wiederholung eines Nachtschritts (Erweiterung `StepQueue`).
- **Reihenfolge:** `parasit` (Option C) → `voodoo-priester` → `rotkaeppchen`.
- **Entscheidungen:** RM-DR-005, RM-DR-006, RM-DR-011; RM-DR-157, RM-DR-132, RM-DR-137.
- **Tests:** Umlenkung bewahrt ursprüngliche Ursache und Quelle (TEST-MATRIX), Ketten, Apfel je Rollentyp.
- **Größe / Risiko:** L / hoch.
- **Abnahme:** keine Umlenkung ohne Protokoll von Original und Ersatz.

### K11 · Wolfsangriff-Modifikation, Durchdringung, verzögerte Tode

**Rollen Charge K11 (2):** `schicksalswolf`, `rachsuechtiger-wolf`

**Nachtrag Rollenaudit:** `verdammniswaechter` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `seuchenwolf` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `rudelvater` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `giftwolf` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** zusätzliche oder veränderte Wolfsangriffe, Durchdringung, Tod zu einem späteren Zeitpunkt.
- **Neue Systeme:** N-12, N-04 (Attribut `pierces` mit fester Liste), zusätzliche Rudelopfer.
- **Reihenfolge:** `giftwolf` → `rudelvater` → `seuchenwolf` → `schicksalswolf` → `rachsuechtiger-wolf` → `verdammniswaechter`.
- **Entscheidungen:** RM-DR-004, RM-DR-005, RM-DR-006, RM-DR-015; RM-DR-111, RM-DR-112, RM-DR-108, RM-DR-109, RM-DR-106, RM-DR-115.
- **Tests:** Kombinationsmatrix Schutz × Durchdringung ([`07`](07-test-strategy.md) §4), verzögerter Tod über Save/Load und Wiederbelebung.
- **Größe / Risiko:** XL / hoch.
- **Abnahme:** jede Abfangregel hat einen Test mit und ohne `pierces`.

### K12 · Rollen- und Fraktionswechsel

**Rollen Charge K12 (0):** –

**Nachtrag Rollenaudit:** `seelentauscher` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `koenig-lykaon` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `daemonischer-wolf` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `waechter-am-tor` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Rolle, Fraktion oder Erscheinung ändern sich während der Partie.
- **Neue Systeme:** N-17.
- **Wiederverwendbar:** `RoleTransition` mit Schnappschuss, `appears_as`, Wolfskind- und Lehrling-Tests als Regressionsbasis.
- **Reihenfolge:** `waechter-am-tor` (Einhängepunkt zuerst) → `koenig-lykaon` (Option C) → `daemonischer-wolf` → `seelentauscher`.
- **Entscheidungen:** RM-DR-001, RM-DR-002, RM-DR-009; RM-DR-149, RM-DR-107, RM-DR-122, RM-DR-127.
- **Tests:** genau ein Wolf nach Tausch Werwolf ↔ Dorfbewohner (Legacy-Bug F4), Wächter blockiert jeden Verwandlungsweg, Rücknahme per Korrektur.
- **Größe / Risiko:** L / kritisch.
- **Abnahme:** alle Rollenwechsel laufen durch `RoleTransition`; Paritäts-Tests nach jedem Wechsel.

### K13 · Wiederbelebung

**Rollen Charge K13 (0):** –

**Nachtrag Rollenaudit:** `dr-victor-frankenstein` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `kutscher` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Tote kehren zurück, teils mit neuer Rolle.
- **Neue Systeme:** N-13; bei Kartenbezug N-15.
- **Reihenfolge:** `dr-victor-frankenstein` → `kutscher`.
- **Entscheidungen:** RM-DR-011, RM-DR-013, RM-DR-015; RM-DR-141, RM-DR-126.
- **Tests:** atomare Prompt-Kette (Abbruch ändert nichts, Legacy-Bug F9), Bindungen nach Wiederbelebung, neue Rolle erst ab folgender Nacht.
- **Größe / Risiko:** L / hoch.
- **Abnahme:** Wiederbelebung durch Rolle und durch Korrektur nutzen dieselbe Regel.

### K14 · Tag, Nominierung, Stimmbezug

**Rollen Charge K14 (0):** –

**Nachtrag Rollenaudit:** `amalia` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `korrupter-richter` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `blutwolf` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Wirkungen am Tag, auf Nominierungen oder als Hinweis zur physischen Abstimmung.
- **Neue Systeme:** N-14; für `blutwolf` N-05.
- **Reihenfolge:** `korrupter-richter` → `amalia` → `blutwolf`.
- **Entscheidungen:** RM-DR-008, RM-DR-012; RM-DR-117, RM-DR-151, RM-DR-133.
- **Tests:** Richter-Nominierung mit Manipulator und Spiegelwolf, kein Stimmfeld in Zustand und Ereignissen (AS-C11).
- **Größe / Risiko:** M / mittel.
- **Abnahme:** AS-C11 bleibt grün.

### K15 · Ressourcen und Totenkarten

**Rollen Charge K15 (1):** `kartenschlucker`

**Nachtrag Rollenaudit:** `hades` und `grabraeuber` sind umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `nekromant` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

**Nachtrag Rollenaudit:** `todesprediger` ist umgesetzt ([`11-role-audit-status.md`](11-role-audit-status.md)).

- **Mechanik:** Ressourcen aus Toden oder Karten, persönliche Schilde, Einzelsiege.
- **Neue Systeme:** N-15, N-14, N-01, N-03.
- **Reihenfolge:** `todesprediger` → `hades` → `nekromant` → `kartenschlucker` (nach Totenkarten-Assistent) → `grabraeuber` (nach Regeldefinition).
- **Entscheidungen:** RM-DR-006, RM-DR-008, RM-DR-013; RM-DR-158, RM-DR-144, RM-DR-142, RM-DR-143, RM-DR-156.
- **Tests:** eindeutige Zählbasis Nacht/Tag (Legacy-Bug Todesprediger), Schild-Reihenfolge, Ressourcen über Save/Load.
- **Größe / Risiko:** XL / hoch.
- **Abnahme:** keine Rolle ohne festgelegte Siegbedingung.

### K16 · Nacht-Transaktion

**Rollen Charge K16 (1):** `zeitwaechter`

- **Mechanik:** eine ganze Nacht gilt als nicht geschehen.
- **Neue Systeme:** N-16 (baut auf Undo/Redo aus Masterplan Phase 3 auf).
- **Entscheidungen:** RM-DR-010; RM-DR-150.
- **Tests:** Rücknahme aller Nachtwirkungen, Zähler, verzögerte Effekte, Replay.
- **Größe / Risiko:** XL / kritisch.
- **Abnahme:** erst nach Undo/Redo (B-12) beginnen.

## 5. Empfohlene Reihenfolge

0. **Nächste Einheit (Empfehlung, RM-DR-017):** K1a (`siegreicher-wolf`, `doppelspion`), danach K1b (`selbstmoerder`).
1. **Falls Option B gewählt wird (nicht freigegeben):** 1.0-Anteile von K1 → K2 → K3 → K4 → K5 → K6 → K7 → K8 → K9. Jede Charge beginnt mit dem Umbau ihres Kernsystems ohne Verhaltensänderung, dann folgen die Rollen. Option C ergänzt danach `nachtwaechter` (K3), `die-gebundenen` (K2), `der-weise` (K8), `koenig-lykaon` (K12, setzt N-17 voraus), `parasit` (K10).
2. **Nach 1.0:** Restrollen von K2 bis K9, dann K10, K12, K11, K14, K13, K15, K16. K13 und K15 hängen an `07` Q3 (Totenkarten), K16 an Undo/Redo.
3. **Nicht vor einer Charge beginnen,** solange ihre Entscheidungen offen sind (Masterplan: „keine neue Charge vor Abnahme“).
