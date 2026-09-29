# 12 · Analyse problematischer Rollenkombinationen (R-07)

**Stand:** 29.09.2026, Paket 3 der Code-Abschluss-Roadmap, Branch `feature/night-ui-expansion`, Schema 14, Regelversion 0.12.
**Umfang:** 71 implementierte Rollen. Der Kartenschlucker und die Totenkarten sind blockiert (RM-DR-013) und nicht Teil dieser Analyse.
**Grenze:** Dieses Dokument analysiert nur. Es verbietet kein Rollenpaar im Setup, ändert keine Balance und erfindet keine Siegbedingung. Setup-Warnungen oder Verbote folgen erst nach einer ausdrücklichen Produktentscheidung (Matrix R-07, offene Entscheidung 9).

## 1. Methode

Keine Paarprüfung aller 71 × 71 Rollen. Geprüft wurden Überschneidungen über gemeinsam genutzte Zustände und Abläufe des Regelkerns:

| Mechanikfamilie | Gemeinsamer Zustand oder Ablauf |
|---|---|
| Schutz gegen Todesursachen | `KillPipeline`, `Protections`, persönliche Schilde, Durchdringung |
| Umlenkung, Immunität, Ketten | Voodoo-Puppe, Schattenwanderer, Nekromant, Verdammniswächter, Märtyrerin, Dorfwache, Parasit |
| Kettentod und Todesreaktionen | Liebeskummer, Rotkäppchen-Kette, Kutscher-Unfall, Brand, Reaktionswarteschlange (DR-09) |
| Wiederbelebung und Einsätze | `RoleTransition.revive`, Kutscher, Frankenstein, Korrektur |
| Rollenwechsel, Erbe, Diebstahl | Lehrling, Seelentauscher, König Lykaon, Wolfskind, Grabräuber, Wächter am Tor |
| Verzögerte Wirkungen | Giftpranke, Todesmarkierungen, Pest, Zeitwächter, Seuchenwolf, Rudelvater |
| Siege | Parität, Einzelsiege, Mitsiege, Kandidatenmenge (DR-02, DR-14) |
| Geheimnisse | Scheinrolle (DI-08), öffentliche Todesansage (DR-04, Entscheidung 29.09.2026), Aktor-Hinweise |
| Spielleiterkorrekturen | automatischer Abbruch offener Prompts (Decision Log Punkt 5) |

Jede Überschneidung wurde entweder einem vorhandenen deterministischen Test zugeordnet (Liste in `11-role-audit-status.md` §4.2) oder, wo keiner existierte, als festes Szenario ergänzt (unten, Kategorie D). Zufallspartien (`test_role_interaction_fuzz`) ergänzen die festen Szenarien, ersetzen sie aber nicht.

**Kategorien:** A technischer Fehler · B Regelkonflikt oder unklare Priorität · C regelkonform, mögliches Balanceproblem · D ungewöhnlich, aber korrekt unterstützt.

## 2. Ergebnis in Kürze

| Kategorie | Anzahl | Kurzfassung |
|---|---|---|
| A | 0 | Kein kombinationsbedingter technischer Fehler gefunden. Ein Bedienfehler ohne Kombinationsbezug (Stimmhinweise) wurde behoben, siehe §7. |
| B | 0 offen | Alle geprüften Prioritätsfragen sind durch vorhandene Entscheidungen geregelt (DR-02, E-36, DI-08, W-02). |
| C | 4 | Kutscher in kleinen Runden, Voodoo-Puppe als Dorfwache, viele gleichzeitige Einzelsiege, späte Schwellen in kleinen Runden. |
| D | 9 | Siehe §6, jeweils mit festem Test. |

Das Ergebnis ist kein Beweis der Fehlerfreiheit aller Kombinationen, sondern der geprüfte Stand für die genannten Mechanikfamilien.

## 3. A · Technische Fehler

Keine kombinationsbedingten technischen Fehler gefunden.

## 4. B · Regelkonflikte oder unklare Prioritäten

Keine offenen. Geprüft und als bereits entschieden eingeordnet:

| Überschneidung | Frage | Regelquelle |
|---|---|---|
| Mehrere Siegbedingungen zugleich | Wer gewinnt, wenn Dorf und mehrere Einzelsiege gleichzeitig erfüllt sind? | DR-02 und Decision Log „Siegkandidaten“: Kandidatenmenge ohne Priorität, die Spielleitung bestätigt genau einen |
| Zeitwächter × Giftwolf | Wirkt eine fällige Giftpranke in einer eingefrorenen Nacht? | E-36: fällige Wirkungen früherer Nächte treten ein (Test `test_lone_wolf_and_time_warden::test_decline_keeps_ability_and_earlier_poison_still_due`) |
| Trugbilderwolf × Lehrling, Seelentauscher, König Lykaon | Wer kennt die Scheinrolle danach? | DI-08: nur die Spielleitung. Aktor-Hinweise nennen nur die Rolle (`bond_steps.gd`, `apprentice_rules.gd`); Rollenkarte zeigt die wahre Rolle (Paket 2) |
| Kutscher × verbrauchte Fähigkeit | Behält eine Wiederbelebte ihre Rolle und ihre Einsätze? | W-02: Rolle bleibt, Einsätze frisch |

## 5. C · Regelkonform, mögliches Balanceproblem

### C-1 · Kutscher in Partien mit 6 bis 12 Personen

- **Rollen und Voraussetzung:** `kutscher` in einer Partie mit höchstens 12 Personen.
- **Ablauf:** Der Kutscher handelt erst ab einer Nacht mit mindestens 10 Toten (W-03, `RoleCatalog.COACH_MIN_DEAD = 10`, `BondSteps.can_revive`). Damit die Partie dann noch läuft, müssen außer ihm mindestens eine weitere Nicht-Wolf-Person und ein Wolf leben (sonst ist die Parität erreicht oder kein Wolf mehr da). Das sind mindestens 13 Personen.
- **Tatsächliches Verhalten:** Unter 13 Personen kann der Kutscher nie handeln. Trotzdem macht er die Partie zur Wiederbelebungsrunde (DI-01, DA-21): Bei jedem Tod wird die Rolle nicht angesagt.
- **Erwartet laut Regeln:** genau so; beide Regeln sind entschieden.
- **Schweregrad:** mittel (verändert die öffentliche Information der ganzen Partie ohne spielbaren Gegenwert).
- **Empfehlung:** Produktentscheidung, ob das Setup bei weniger als 13 Personen einen Hinweis zeigt. Keine Umsetzung in diesem Paket.

### C-2 · Voodoo-Priester mit einer Dorfwache als Puppe

- **Rollen:** `voodoo-priester`, `dorfwache` (als Puppe gewählt).
- **Ablauf:** Das Rudel greift den Priester an. Der Angriff wird mit ursprünglicher Ursache auf die Puppe umgelenkt (E-12, E-20), die Dorfwache ist gegen Rudelangriffe immun (RM-DR-119).
- **Tatsächliches Verhalten:** Niemand stirbt; `KillPrevented` zuerst durch den Priester, dann durch die Dorfwache. Solange die Puppe lebt, kann das Rudel den Priester nicht töten.
- **Nachweis:** `test_role_interactions::test_p3_voodoo_doll_is_guard_nobody_dies`.
- **Schweregrad:** niedrig bis mittel (andere Ursachen wie Hinrichtung, Gift und Hades wirken weiter).
- **Empfehlung:** Beobachten im Pilotbetrieb; keine Regeländerung ohne Produktentscheidung.

### C-3 · Viele gleichzeitige Einzelsiege bei höchstens drei Lebenden

- **Rollen:** `parasit`, `voodoo-priester`, `grabraeuber` (je Alleinsieg bei höchstens drei Lebenden), dazu `manipulator` (genau drei Lebende); Dorf oder Wölfe können zugleich erfüllt sein.
- **Ablauf:** Drei Lebende ohne Wolf: Parasit, Voodoo-Priester, Grabräuber.
- **Tatsächliches Verhalten:** Vier offene Kandidaten ohne Priorität (Dorf, Voodoo, Grabräuber, Parasit); die Spielleitung bestätigt genau einen.
- **Nachweis:** `test_role_interactions::test_p3_simultaneous_solo_wins_form_one_candidate_set`.
- **Schweregrad:** niedrig (regelkonform, DR-02), aber das Ende kann am Tisch willkürlich wirken.
- **Empfehlung:** Bei der Rollenauswahl für Version 1.0 (offene Entscheidung 8) berücksichtigen; keine Setup-Regel ohne Entscheidung.

### C-4 · Späte Schwellen in kleinen Runden

- **Rollen:** `dorfschmied` (ab Nacht 6), `henker` (ab drei Hinrichtungen), `schicksalswolf` (Zusatzopfer nur in Nacht 4), `koenig` (mehr Tote als Lebende), `kopfgeldjaeger` (nach einem Wolfs-Lynch).
- **Tatsächliches Verhalten:** In Partien mit 6 bis 8 Personen endet das Spiel oft, bevor die Schwelle erreicht ist; die Rolle wirkt dann wie eine Dorfbewohnerin. Die Schritte sind erreichbar und bedienbar (feste Szenarien in `test_prompt_coverage` und `test_role_buttons`).
- **Schweregrad:** niedrig.
- **Empfehlung:** Hinweis im Rollenlexikon oder bei der Auswahl für Version 1.0; keine Änderung der Schwellen.

## 6. D · Ungewöhnlich, aber korrekt unterstützt (mit festem Test)

| Nr. | Kombination | Erwartete Reihenfolge und Ergebnis | Regelquelle | Test |
|---|---|---|---|---|
| D-1 | Zwei Schattenwanderer, gegenseitig verknüpft; Rudel greift einen an | Umlenkung genau einmal, der verknüpfte Partner stirbt, keine Schleife | B-04, B-07 | `test_role_interactions::test_p3_mutual_shadow_links_redirect_once_without_loop` |
| D-2 | Parasit, dessen Wirt ein Voodoo-Priester ist; Rudel greift den Wirt an | Die Puppe stirbt, Wirt und Parasit leben | RM-DR-157, E-12 | `test_role_interactions::test_p3_parasite_host_protected_by_voodoo_doll` |
| D-3 | Voodoo-Puppe ist Dorfwache | Umlenkung, dann Immunität, niemand stirbt (siehe C-2) | E-12, E-20, RM-DR-119 | `test_role_interactions::test_p3_voodoo_doll_is_guard_nobody_dies` |
| D-4 | Dorf und drei Einzelsiege gleichzeitig | Vier Kandidaten, genau einer wird bestätigt (siehe C-3) | DR-02 | `test_role_interactions::test_p3_simultaneous_solo_wins_form_one_candidate_set` |
| D-5 | Trugbilderwolf oder Grabräuber stirbt öffentlich (Runde ohne Wiederbelebung) | Öffentlich die wahre bzw. eigene Rolle, nie Scheinrolle oder gestohlene Fähigkeit | DI-08, DR-04 | `test_role_interactions::test_p3_public_death_names_true_role_not_appearance_or_stolen_ability` |
| D-6 | Loki-Liebende, einer davon Sensenträger; Rudel tötet den anderen | Opfer stirbt, dann Liebeskummer, dann Reaktion des Sensenträgers; Siegprüfung danach; Speichern mit offener Reaktion setzt identisch fort | B-01/B-02, DR-09, DR-14, DA-23 | `test_role_interactions::test_p3_heartbreak_then_reaper_reaction_in_order_with_save_load` |
| D-7 | Kutscher belebt eine Kriegerin, die ihren Angriff verbraucht hat | Kriegerin behält die Rolle, Einsatz frisch, neuer Schritt in der Folgenacht; ein anderer Wiederbelebter wird Werwolf | W-02, W-03 | `test_role_interactions::test_p3_coach_revival_restores_one_shot_ability` |
| D-8 | Zeitwächter friert Nacht 3 ein, Giftpranke fällig in Nacht 3 | Die Vergiftete stirbt trotzdem am Morgen | E-36 | `test_lone_wolf_and_time_warden::test_decline_keeps_ability_and_earlier_poison_still_due` |
| D-9 | Lehrling erbt einen Trugbilderwolf, Seelentausch mit Trugbilderwolf | Scheinrolle geht mit der Rolle über, die Person erfährt nur die Rolle | DI-08, W-02 | Erbe: `test_lehrling` (Scheinrolle übernommen); Seelentausch und Aktor-Hinweise: `test_role_interactions::test_p3_soul_swap_moves_appearance_without_telling_anyone` |

## 7. Nebenbefund ohne Kombinationsbezug (behoben)

Die Stimmhinweise des Regelkerns (`VoteHints`: Blutwolf +1 je totem Nachbarplatz, Korrupter Richter +1 auf seine verdeckte Nominierung, RM-DR-008) wurden berechnet, aber nirgends angezeigt. Damit war die einzige Wirkung des Blutwolfs für die Spielleitung unsichtbar. Behoben im privaten Spielleiterbereich (nie auf öffentlichen Karten). Regressionstests: `test_role_passive_ui::test_blutwolf_vote_bonus_visible_only_in_private_area`, `test_korrupter_richter_vote_bonus_in_private_area`.

## 8. Offene Produktfragen aus dieser Analyse

Keine Regelkonflikte. Für die Balance (Kategorie C) bleibt die bestehende offene Entscheidung 9 der Matrix: ob und in welcher Form das Setup auf ungünstige Kombinationen hinweist. Konkrete Kandidaten dafür: C-1 (Kutscher unter 13 Personen) und C-3 (viele Einzelsiege).
