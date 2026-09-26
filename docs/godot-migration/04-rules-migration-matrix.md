# 04 · Regel-Migrationsmatrix

**Stand:** 2026-09-26 · Kennzeichnung: **[B]** Beobachtung, **[S]** Schlussfolgerung, **[E]** Empfehlung.

## Lesehilfe

**Status**

| Status | Bedeutung |
|---|---|
| **verifiziert** | Code setzt den Rollentext (`ROLE_DESCRIPTIONS`, `roles:63-135`) nachvollziehbar um. Kann 1:1 portiert werden; Golden-Test gegen Legacy möglich |
| **unklar** | Text zu vage oder Verhalten hängt an SL-Handarbeit; Regel muss präzisiert werden, Code liefert keine eindeutige Antwort |
| **widersprüchlich** | Text und Code widersprechen sich, oder der Code enthält einen Fehler, der das Verhalten verfälscht. PO-Entscheidung nötig (Sammelfrage Q1 in `07`) |
| **fehlend** | Text verspricht eine Mechanik, die im Code nicht existiert |

**Godot-Modul:** Rollen immer `core/roles/<role-id>.gd` + `content/roles/<role-id>.tres`; zusätzlich genannte Module sind betroffene Kernteile (`kill_pipeline`, `night_order`, `execution`, `win_rules`, `faction_query`, `role_change`, `phase_machine`).

**Test:** Szenario-ID `S-<bereich>-<nr>` als JSON unter `tests/scenarios/`. „Golden" = Ergebnis wird zusätzlich gegen die Legacy-Web-App verglichen (nur bei *verifiziert*).

Pfadkürzel wie in `01`: `core` = `js/ui/core.js`, `night`, `chunk`, `ab`, `help`, `roles`, `state`, `gh`.

---

## A. Rollen (alle 72, Reihenfolge wie `ALL_ROLES`, `roles:1`)

Fraktion aus `getRoleFaction` (`roles:405-409`): D = Dorf, W = Wolf, S = Solo. Tier = Position in `ORDER_BASE`.

| # | Rolle (ID) | F | Tier | Legacy-Implementierung [B] | Status | Akzeptanzkriterium | Vorgeschlagener Test |
|---|---|---|---|---|---|---|---|
| 1 | Loki (`loki`) | D | 0.1 einmal | `chunk:131-140`; Liebeskette `core:365-386` | widersprüchlich | Einmal 2 Spieler als Liebende ODER Rivalen verbinden; stirbt einer der Liebenden, stirbt der andere (Ursache LOVER). Rivalen: Wirkung laut PO (heute nur für Schwarze Witwe relevant) | S-ROLE-01: Liebende A,B; A stirbt nachts → B stirbt am selben Morgen; Golden |
| 2 | Nachtwächter (`nachtwaechter`) | D | – | `night:535-560` `doBearPing` löst nur SFX aus (No-op) | fehlend | Morgens nach Toten: Öffentlicher Alarm, wenn ein lebender Nachbar Wolf oder Solo ist (Ereignis PUBLIC) | S-ROLE-02: Nachbar Wolf → Alarm-Ereignis; Nachbar Dorf → keins |
| 3 | Die Gebundenen (`die-gebundenen`) | D | 0.5 einmal | `chunk:142-155` | verifiziert | Nacht 1: Alle Gebundenen erwachen und sehen einander; kein Zustandseffekt | S-ROLE-03: Info-Prompt listet alle Gebundenen-Sitze |
| 4 | Waldhexe (`waldhexe`) | D | 3.4 | `chunk:208-221`, `help:264-273` | verifiziert | Sieht Wolfsopfer; einmal retten (entfernt Ziel), einmal vergiften (sofortiger Tod WITCH_POISON); Voodoo/Cerberus wie Legacy | S-ROLE-04a Rettung, 04b Gift, 04c beides verbraucht; Golden |
| 5 | Rattenfänger (`rattenfaenger`) | S | 4.2 | `chunk:645-676`; Sieg `core:275-285` | verifiziert | Jede Nacht 1–2 Spieler verzaubern; Sieg, wenn alle anderen Lebenden verzaubert | S-ROLE-05: letzter Verzauberter → WinDetected solo; Golden |
| 6 | Sensenträger (`sensentraeger`) | D | – | Queue `gh:1926-2042`, `state:84-88` | verifiziert (Zeitpunkt unklar) | Bei eigenem Tod wählt er ein Opfer (HUNTER_SHOT). Zeitpunkt: sofort als Reaktion (heute bei Tageslynch erst nach nächster Nacht, `js/ui/ui.js:470-477`) | S-ROLE-06a Nachttod → Reaktion am Morgen; 06b Lynch → Reaktion sofort |
| 7 | Wolfskind (`wolfskind`) | D | 0.9 einmal | `chunk:712-715`; Verwandlung `core:387-388` | verifiziert | Wählt Vorbild; stirbt Vorbild → zählt als Wolf (Wächter am Tor: wird Dorfbewohner) | S-ROLE-07: Vorbild stirbt → `counts_as_wolf` true; Golden |
| 8 | Das Orakel (`das-orakel`) | D | 4.6 | `chunk:238-252` | verifiziert | Erfährt Rolle eines Spielers; Wölfe erscheinen als „Werwolf"; Trugbilderwolf nach `appears_as` | S-ROLE-08: Ziel Giftwolf → „Werwolf"; Golden |
| 9 | Die Ewigen (`die-ewigen`) | D | 4.8 | `chunk:253-260` (nur Prüfung) | fehlend | Prüft, ob Ziel Solo-Sieg hat; „gewinnen gemeinsam" fehlt → Mitsieg-Regel laut PO | S-ROLE-09: Ziel Solo → Info true; Mitsieg nach Q1 |
| 10 | Spürhund (`spuerhund`) | D | 6.8 | `chunk:262-287` | verifiziert | 3 Spieler; ✅ wenn einer Wolf/Solo/falsche Spur; bei ❌ geheime falsche Spur auf zufälligen Spieler (Seed) | S-ROLE-10a/b; Golden mit festem Seed nicht möglich (Math.random) → nur Regeltest |
| 11 | Schutzengel (`schutzengel`) | D | 1.3 | `chunk:157-161`; Verbrauch `chunk:162` | widersprüchlich (Zeitpunkt) | Schützt 1 (nicht sich) vor dem nächsten Wolfsangriff dieser Nacht; Schutz wird **bei Auflösung** verbraucht, nicht bei Zielwahl (heute bei Zielwahl) | S-ROLE-11a Schutz hält; 11b Fehlklick des Wolfs verbraucht keinen Schutz |
| 12 | Werwolf (`werwolf`) | W | 2.0 | `chunk:162`; Auflösung `night:322-398` | verifiziert (mit Bug F2) | Rudel wählt 1 Opfer; Tod am Morgen (NIGHT_KILL); Tötungsschritt existiert, solange **irgendein** Wolf lebt | S-ROLE-12a Standard; 12b nur Giftwolf lebt → Schritt vorhanden (Legacy: fehlt, `night:50`) |
| 13 | Rachsüchtiger Wolf (`rachsuechtiger-wolf`) | W | 2.2 | `chunk:310-364` | widersprüchlich | Kann einen Wolf reißen, danach 3 Nächte Pause; Text „will alleine gewinnen" vs. Code „gewinnt mit Rudel" | S-ROLE-13: Abklingzeit 3 Nächte; Sieg nach Q1 |
| 14 | König Lykaon (`koenig-lykaon`) | W | 2.4 einmal | `chunk:364-394` | verifiziert | Nacht 1: Opfer wird Trugbilderwolf (Wächter → Dorfbewohner); alte Rolle bleibt als Tarnzeile | S-ROLE-14; Golden |
| 15 | Siegreicher Wolf (`siegreicher-wolf`) | W | – | `core:21-29` | verifiziert | Zählt als 2 bei der Wolf-Parität | S-WIN-03: 1 Siegreicher + 2 Dorf → Wolfsieg |
| 16 | Seuchenwolf (`seuchenwolf`) | W | – | `core:148`, `night:238,251,336-338` | verifiziert | Nach seinem Tod durchbricht der nächste Wolfsangriff Schutz einmal | S-ROLE-16 |
| 17 | Schicksalswolf (`schicksalswolf`) | W | 2.5 | `chunk:395-421`, `night:62-73,240-244` | verifiziert | Nacht 1: 3 markieren; ab Nacht 4 einmal so viele Zusatzopfer, wie Markierte unter den ersten 3 Toten | S-ROLE-17 |
| 18 | Schattenwanderer (`schattenwanderer`) | W | 2.6 einmal | `chunk:422-435`; Umlenkung `core:118-124` | verifiziert | Verknüpft sich mit einem Spieler; Tod eines der beiden trifft den anderen | S-ROLE-18; Golden |
| 19 | Giftwolf (`giftwolf`) | W | 2.7 | `chunk:436-448`, `night:200-211` | unklar | 2 Ladungen; Opfer stirbt am übernächsten Morgen (GIFTWOLF_DELAY). Zwei Ladungen in einer Nacht erlaubt? (Code: ja) | S-ROLE-19 |
| 20 | Rudelvater (`rudelvater`) | W | – | `core:111-117`, `night:498`, `night:269-280` | verifiziert | Überlebt ersten Tod durch Sonderfähigkeit; gelyncht → nächste Nacht Zusatzopfer, das Schutz ignoriert | S-ROLE-20a/b |
| 21 | Schwarze Witwe (`schwarze-witwe`) | W | 2.8 | `chunk:449-460`, `night:192-199` | widersprüchlich | Wählt Verbundenen; Paar stirbt am Morgen. Text „Loki wird automatisch gewählt" fehlt; letzte Wahl überschreibt | S-ROLE-21; Setup-Pflicht Loki |
| 22 | Der Weise (`der-weise`) | D | – | `night:359-364`, Lynch `night:450-473` | widersprüchlich (Bug F10) | Überlebt ersten Wolfsangriff genau einmal; gelyncht → SL wählt 1–3 Tage Fähigkeitsverlust für Nicht-Wölfe | S-ROLE-22a genau ein Überleben; 22b Debuff |
| 23 | Verdammniswächter (`verdammniswaechter`) | D | 2.3 | `chunk:726-736` | widersprüchlich | Wählt zwischen Wolfsopfer und zufälligem anderen; Text „umgeht alle Schutzfähigkeiten" vs. `applyKill`-Schilde; tötet sofort statt am Morgen | S-ROLE-23 nach Q1 |
| 24 | Lehrling (`lehrling`) | D | 1.1 einmal | `chunk:716-719`; Erbe `core:389` | widersprüchlich (Bug F5) | Wählt Mentor (Nicht-Wolf); stirbt Mentor und lebt Lehrling → erbt Rolle | S-ROLE-24a lebend erbt; 24b tot erbt nicht |
| 25 | Wahnsinniger Kutscher (`wahnsinniger-kutscher`) | D | – | `night:425-439` | widersprüchlich | Gelyncht → er und beide Nachbarn sterben. DE: direkte Sitze; EN: „living neighbours" (`roles:230`) | S-EXE-05 nach Q1 |
| 26 | Korrupter Richter (`korrupter-richter`) | D | 1.5 | `chunk:720-725` | fehlend | Markiert nachts einen Spieler als nominiert; „+1 Stimme" nicht umgesetzt (kein Stimmsystem); Manipulator-Effekt fehlt (Bug) | S-ROLE-26; hängt an Q2 |
| 27 | Märtyrerin (`maertyrerin`) | D | 9.0 (Zeile ohne Handler) | `night:257-265` | verifiziert | Einmal: am Morgen statt des ersten Opfers sterben (MARTYR_SACRIFICE) | S-ROLE-27; Nachtzeile entfällt, Reaktion im Morgen |
| 28 | Dorfwache (`dorfwache`) | D | – | `chunk:162,348`, `night:251` | verifiziert | Immun gegen Wolfsangriffe (nicht gegen Pierce/Rudelvater) | S-ROLE-28 |
| 29 | Pestbringerin (`pestbringerin`) | S | 7.2 | `chunk:678-701`, `core:452-455`, Sieg `core:264-273` | widersprüchlich | Text „tödliche Seuche jede Nacht" vs. Code „2 Tränke, Gift tötet nie, breitet sich aus, Sieg wenn alle Lebenden vergiftet (auch sie selbst)" | S-ROLE-29 nach Q1 |
| 30 | Prophet des Untergangs (`prophet-des-untergangs`) | S | 8.6 | `chunk:797-829`, `night:74-82`, `state:94-108` | fehlend | Markiert 3; sterben alle → darf jede Nacht töten; Solo-Sieg fehlt | S-ROLE-30; Sieg nach Q4 |
| 31 | Spiegelwolf (`spiegelwolf`) | W | – | `night:483-497` | verifiziert | Erster Lynch: überlebt, Nominierender stirbt | S-EXE-08 |
| 32 | Dämonischer Wolf (`daemonischer-wolf`) | W | – | `night:285-290,501` | widersprüchlich | Bei eigenem Tod verflucht er 1 Spieler, der als Wolf *erscheint*. Code: Verfluchter *zählt* als Wolf (Parität, Ritter, Detektiv) | S-ROLE-32 nach Q1 |
| 33 | Trugbilderwolf (`trugbilderwolf`) | W | – | `chunk:240-249` | verifiziert | Erscheint Informationsrollen als Dorfrolle (heute im Orakel-Handler) | S-ROLE-33 |
| 34 | Schattenhund (`schattenhund`) | W | 0.7 einmal | `chunk:704-711`, `ab:94` | widersprüchlich | Blockiert einmal Dorf-Fähigkeiten einer Nacht. Code: nicht in Nacht 1 (steht aber in Gruppe „Nacht 1"), blockiert auch Solos | S-ROLE-34 nach Q1 |
| 35 | Besessener Wolf (`besessener-wolf`) | W | – | `core:176-189`, `night:298-320` | verifiziert | Bei Tod mit ≥ 4 Lebenden: reißt 1 mit (Reaktion) | S-ROLE-35; Golden |
| 36 | Fenrir (`fenrir`) | W | – | `night:136,448`, `core:421` | widersprüchlich | Text „überlebt einmalig jeden Tod ab Stufe 3" vs. Code „nur Lynch"; Stufe steigt pro Nachtbeginn | S-ROLE-36 nach Q1 |
| 37 | Kutscher (`kutscher`) | D | 3.8 | `chunk:833-864`, `night:83` | verifiziert | Ab 10 Toten einmal: 3 zufällige Tote zurück, einer wird Werwolf, andere erhalten freie Nicht-Wolf-Rollen (Seed) | S-ROLE-37 |
| 38 | Seelentauscher (`seelentauscher`) | D | 8.0 einmal | `chunk:737-796` | widersprüchlich (Bug F4) | Tauscht Rollen zweier Spieler; Wolfsstatus folgt der neuen Rolle, nicht dem alten Flag | S-ROLE-38: Werwolf↔Dorfbewohner → genau 1 Wolf |
| 39 | Blutpriester (`blutpriester`) | D | 8.2 einmal | `chunk:703` | verifiziert | Opfert einen Spieler (BLOODPRIEST_SACRIFICE), SL enthüllt 0–3 Wölfe (Code: zufällig) | S-ROLE-39 |
| 40 | Traumdeuter (`traumdeuter`) | D | 7.0 | `chunk:831` | unklar | Text „Visionen über Rollen oder Zustände"; Code: 3 Namen, genau 1 Wolf (wie Kopfgeldjäger) | S-ROLE-40 nach Q1 |
| 41 | Henker (`henker`) | D | 7.8 ab 3 Lynchs | `chunk:832`, `night:404-419` | verifiziert | Ab dem 3. Lynch nachts 1 markieren; beim nächsten Lynch stirbt der Markierte mit | S-ROLE-41 |
| 42 | Feuerteufel (`feuerteufel`) | S | 7.6 | `chunk:702`, `night:340-348,444-446` | fehlend | Markierung; stirbt/gelyncht wird das Ziel, sterben Nachbarn; Solo-Sieg fehlt; Nachbarn brennen auch, wenn Ziel überlebt (Bug) | S-ROLE-42 nach Q4 |
| 43 | Voodoo-Priester (`voodoo-priester`) | S | 8.4 | `chunk:304-309`, `night:252-256,440-443` | fehlend | Puppe stirbt statt Priester (Nacht, Lynch, Hexe); 2 Tage Abklingzeit; Solo-Sieg fehlt | S-ROLE-43 nach Q4 |
| 44 | Blutwolf (`blutwolf`) | W | – | `js/ui/ui.js:18,109` | fehlend | Stimmgewicht = 1 + tote Nachbarn; nur Anzeige, `showBlutwolfInfo` undefiniert | S-ROLE-44 nach Q2 |
| 45 | Albtraumwolf (`albtraumwolf`) | W | 2.1 | `chunk:288-303`, `ab:97-99` | widersprüchlich (Bug F3) | Blockiert die Fähigkeit eines Nicht-Wolfs in dieser Nacht; darf das Opfer **nicht** vor Wölfen schützen | S-ROLE-45a Block; 45b blockiert + Wolfsziel → stirbt |
| 46 | Cerberus (`cerberus`) | W | – | `night:148,449`, `help:265` | verifiziert | +1 Kopf je Nacht (max 3); bei 3 Köpfen überlebt er Lynch/Hexengift, Köpfe → 0 | S-ROLE-46 (inkl. LynchCount laut Bug F15) |
| 47 | Ritter (`ritter`) | D | – | `core:418-450` | verifiziert | Nachts getötet (Ursachen-Liste `core:431`) → nächster lebender Wolf stirbt (links vor rechts) | S-ROLE-47; Golden |
| 48 | Rotkäppchen (`rotkaeppchen`) | D | 7.4 | `ab:7-25,101-124`, `core:168-175` | verifiziert | Verbindet sich mit Nicht-Wolf; stirbt einer, stirbt der andere; Apfel: Partner nutzt Fähigkeit doppelt | S-ROLE-48 |
| 49 | Selbstmörder (`selbstmoerder`) | S | – | `night:474-482` | verifiziert | Gewinnt, wenn gelyncht und vorher ≥ 5 Tote | S-WIN-08; Golden |
| 50 | Kopfgeldjäger (`kopfgeldjaeger`) | D | 3.2 | `chunk:3-27` | verifiziert | Nach jedem Wolfs-Lynch einmal: 3 Namen, genau 1 Wolf | S-ROLE-50 |
| 51 | König (`koenig`) | D | 4.4 | `chunk:109-127`, `night:234` | unklar | Solange Tote > Lebende: jede Nacht (Code) oder einmal (Text) einen Dorfbewohner erfahren | S-ROLE-51 nach Q1 |
| 52 | Dr. Victor Frankenstein (`dr-victor-frankenstein`) | D | 3.6 | `chunk:31-103` | widersprüchlich (Bug F9) | Einmal: Toten wählen → freie Rolle wählen → bestätigen → erst dann Wiederbelebung atomar | S-ROLE-52a Erfolg; 52b Abbruch ändert nichts |
| 53 | Nekromant (`nekromant`) | S | 3.0 | `chunk:163-207`, `core:127-133`, `night:365-379`, Sieg `gh:547-556` | widersprüchlich | Schild (3 Totenstimmen) gegen nächsten Tod beliebiger Person?; Pflicht-Umlenkung, wenn angegriffen; Sieg durch Wolfsbenennung ohne Einschränkung | S-ROLE-53 nach Q1 |
| 54 | Kartenschlucker (`kartenschlucker`) | S | 4.0 | `chunk:222-237`, `help:176`, `core:134-138,241-247` | widersprüchlich | Text: Stapel pro Kartentausch, Sieg bei 10. Code zusätzlich: ab 2 Kill pro Nacht, ab 5 Schild jede Nacht, öffentliche Ansage alle 3 Nächte | S-ROLE-54 nach Q1 |
| 55 | Hades (`hades`) | S | 9.9 | `ab:27-58`, `core:139-143,208-211,249-258` | verifiziert (Stimmbonus fehlend) | +1 Licht je Tod; Menü: Kill 2, Barriere 3, Stimme×3 5, Sieg 10 (auch automatisch) | S-ROLE-55 |
| 56 | Doktor (`doktor`) | D | 5.0 | `chunk:461-468`, `help:276-288` | verifiziert | Prüft 2 Spieler auf gleiche Fraktion (nach Rolle, nicht nach Verwandlung) | S-ROLE-56 |
| 57 | Fährtenleser (`faehrtenleser`) | D | 5.2 | `chunk:469-489` | verifiziert | Einmal: Richtung zum nächsten Wolf (links = höhere Sitznummer; Gleichstand = links) | S-ROLE-57 |
| 58 | Waldläufer (`waldlaeufer`) | D | 5.4 | `chunk:490-493` | verifiziert | Erfährt Anzahl lebender Wölfe | S-ROLE-58; Golden |
| 59 | Schutzgeist (`schutzgeist`) | D | 5.6 | `chunk:494-505`, `core:151` | fehlend (Bug F1) | Nach eigenem Tod einmal einen Spieler schützen | S-ROLE-59: toter Schutzgeist erhält Nachtschritt |
| 60 | Dorfchronistin (`dorfchronistin`) | D | 0.3 einmal | `chunk:506-516` | verifiziert (Bug Einmal-Flag) | Einmal Info; danach kein Nachtschritt mehr | S-ROLE-60 |
| 61 | Wächter am Tor (`waechter-am-tor`) | D | – | `core:31-56` | verifiziert | Solange er lebt, werden neue Wölfe stattdessen Dorfbewohner (Lehrling, Wolfskind, Lykaon, Seelentauscher, Frankenstein, Kutscher) | S-ROLE-61 je Verwandlungsweg |
| 62 | Zeitwächter (`zeitwaechter`) | D | 9.5 einmal | `chunk:517-523`, `night:323-331` | widersprüchlich | Text: alle Nachtaktionen dieser Nacht abgebrochen. Code: nur Wolfstode und Nachtzähler; Sofort-Tode bleiben | S-ROLE-62 nach Q1 |
| 63 | Amalia (`amalia`) | D | 5.8 | `chunk:524-553` | verifiziert | Solange > 2 Wölfe leben: darf sich opfern (AMALIA_SACRIFICE) | S-ROLE-63 |
| 64 | Kriegerin des Lichts (`kriegerin-des-lichts`) | D | 6.0 einmal | `chunk:554-570` | verifiziert | Einmal: benennt Spieler; Wolf → er stirbt (SL-Antwort), sonst stirbt sie (WARRIOR_WRONG) | S-ROLE-64 |
| 65 | Detektiv (`detektiv`) | D | – | `core:66-83` | verifiziert (Bug F11) | Bei Wolfstod mit ≥ 2 lebenden Wölfen: öffentlicher Hinweis zur Sitzlage (Seed) | S-ROLE-65 |
| 66 | Dorfschmied (`dorfschmied`) | D | 1.7 | `chunk:571-582`, `night:161-163,381-392` | verifiziert | Ab 6 Nächten einmal Waffe vergeben; Inhaber wehrt einen Wolfsangriff ab, zufälliger Wolf stirbt | S-ROLE-66 |
| 67 | Manipulator (`manipulator`) | S | – | `gh:429`, `core:234-235` | widersprüchlich (Bug) | Stirbt, wenn nominiert (auch durch Richter); Sieg bei 3 Lebenden, wenn nie nominiert | S-ROLE-67a/b |
| 68 | Doppelspion (`doppelspion`) | S | – | `core:13,227-229,314-319` | verifiziert | Kein Wolf; gewinnt statt Dorf, wenn alle Wölfe tot und er lebt | S-WIN-06 |
| 69 | Grabräuber (`grabraeuber`) | S | 6.4 einmal | `chunk:583-591` | fehlend | Stiehlt Rolle eines Toten (heute nur Info); Solo-Sieg fehlt | S-ROLE-69 nach Q4 |
| 70 | Parasit (`parasit`) | S | 6.2 | `chunk:592-598`, `core:106-110,161-167,236-237` | verifiziert | Wählt Wirt; immun solange Wirt lebt; stirbt mit Wirt; Sieg bei 3 Lebenden | S-ROLE-70 |
| 71 | Todesprediger (`todesprediger`) | S | 6.6 einmal | `chunk:599-644`, `core:153-159` | verifiziert | Sagt eigenen Todeszeitpunkt (Nacht N / Tag N) voraus; trifft er → Sieg | S-ROLE-71 (Zählbasis klären, siehe D-3) |
| 72 | Dorfbewohner (`dorfbewohner`) | D | – | – | verifiziert | Keine Fähigkeit | – |

**Zusammenfassung [B]:** verifiziert 41 · unklar 3 · widersprüchlich 19 · fehlend 9. (Einordnung aus Code-Lektüre, nicht aus Laufzeittests.)

---

## B. Nachtablauf und Phasen

| ID | Regel / Funktion | Legacy [B] | Godot-Modul | Status | Akzeptanzkriterium | Test |
|---|---|---|---|---|---|---|
| B-1 | Nachtreihenfolge nach Tier (50 Einträge, 7 Gruppen) | `roles:3-61` | `content/roles/*.tres` `night_tier`, `night_order.gd` | verifiziert | Gleiche Reihenfolge wie Legacy für jedes Setup | S-NIGHT-01 Golden über alle 4 Akte |
| B-2 | Nur lebende Rolleninhaber erhalten Schritt; Ausnahmen (Schutzgeist tot) | `night:58,91-93` | `night_order.gd` + `is_night_step_available` | widersprüchlich (F1) | Schutzgeist-Ausnahme funktioniert | S-NIGHT-02 |
| B-3 | Täuschungszeilen für verwandelte/tote Rollen | `night:42-47` | `NightPlan` mit `decoy`-Schritten | verifiziert | Tarnschritt ohne Wirkung vorhanden, solange verwandelter Sitz lebt | S-NIGHT-03 |
| B-4 | Synthetische Werwolf-Zeile | `night:50-55` | `night_order.gd` | widersprüchlich (F2) | Schritt existiert, wenn irgendein `counts_as_wolf` lebt | S-NIGHT-04 |
| B-5 | Bedingte Schritte: Henker ≥ 3 Lynchs, Kutscher ≥ 10 Tote, Prophet freigeschaltet, Schicksalswolf N1/N≥4, Frankenstein einmal | `night:59-83` | jeweilige `is_night_step_available` | verifiziert | Je Bedingung Schritt an/aus | S-NIGHT-05a–e |
| B-6 | Blockaden: Schattenhund, Zeitwächter, Der-Weise-Debuff (für Nicht-Wölfe inkl. Solos), Albtraumwolf (Rolle) | `ab:94-99` | `night_order.gd` Schritt-Status `blocked(reason)` | unklar | Blockierter Schritt wird angezeigt mit Grund, ohne Wirkung | S-NIGHT-06 |
| B-7 | Nachtbeginn-Rücksetzungen | `night:130-175` | `phase_machine.gd` + `expire_effects(NIGHT_START)` | verifiziert | Liste in 01 §4.2 vollständig abgebildet | S-PHASE-01 |
| B-8 | Morgenauflösung in fester Reihenfolge | `night:177-398` | `phase_machine.gd` DAWN | verifiziert (mit Bugs F3, F14) | Reihenfolge laut 01 §4.2; `killed_tonight` nur echte Tode | S-PHASE-02 Golden |
| B-9 | Nachtzähler erhöht sich erst nach Auflösung; Morgenzähler separat | `night:339`, `night:194` | `night_number`, `day_number` | unklar | Todesprediger- und Giftwolf-Zählung konsistent definiert | S-PHASE-03 |
| B-10 | Sofort-Tode während der Nacht (Hexe, Verdammniswächter, Hades, Kartenschlucker, Prophet, Blutpriester, Amalia, Kriegerin) | diverse | `request_kill` mit `timing=IMMEDIATE` | verifiziert | Tod sofort, Folgen als Reaktion am Morgen oder sofort (PO) | S-PHASE-04 |
| B-11 | SL-Assistent „Weiter" | `night:586-733` | `NightPlan.step_index` persistent | verifiziert | Fortsetzen nach Neustart am gleichen Schritt | S-PHASE-05 |
| B-12 | Rotkäppchen-Apfel verdoppelt Fähigkeit | `ab:101-124` | `rotkaeppchen.gd` + Engine „repeat step" | verifiziert (Schlüsselfehler `"Chronist"` `ab:107`) | Zweite Ausführung nur für pick-basierte Fähigkeiten | S-ROLE-48b |

---

## C. Tötungs-Pipeline und Todesursachen

### C.1 Reihenfolge der Abfangregeln

| Schritt | Legacy [B] | Godot [E] | Status |
|---|---|---|---|
| Ziel bereits tot | `core:103` | Schritt 1 | verifiziert |
| Parasit-Immunität | `core:106-110` | Immunität | verifiziert |
| Rudelvater-Erstrettung (nicht bei NIGHT_KILL, LYNCH, PACKFATHER_KILL, GIFTWOLF_DELAY) | `core:111-117` | Einmal-Schild mit Ursachenfilter | verifiziert |
| Schattenwanderer-Umlenkung | `core:118-124` | Umlenkung | verifiziert |
| Nekromant-Schild (global, jede Person, außer PACKFATHER_KILL) | `core:127-133` | Einmal-Schild global | unklar (Q1) |
| Kartenschlucker-Schild | `core:134-138` | Einmal-Schild | widersprüchlich (A-54) |
| Hades-Barriere | `core:139-143` | Einmal-Schild | verifiziert |
| Schutzengel/Dorfwache (nur Wolfsangriff) | `chunk:162,348` | Schutz-Effekt mit Filter `is_wolf_attack` | widersprüchlich (Zeitpunkt) |
| Der Weise, Nekromant-Umlenkung, Schmied-Waffe (nur Nachtauflösung) | `night:359-392` | Abfangregeln mit Filter `is_wolf_attack` | verifiziert |
| Voodoo-Puppe (Nacht, Lynch, Hexe) | `night:252-256,440-443`, `help:265` | Umlenkung mit Ursachenfilter | unklar (welche Ursachen?) |
| Märtyrerin | `night:257-265` | Reaktion vor Auflösung | verifiziert |
| Cerberus (Lynch, Hexe), Fenrir (Lynch) | `night:448-449`, `help:265` | `on_execution` bzw. Abfangregel | widersprüchlich (A-36) |

**Akzeptanz:** Für jede Regel ein Szenario, das sie allein auslöst, und ein Szenario mit zwei konkurrierenden Regeln, dessen Ergebnis der Reihenfolge oben entspricht (S-KILL-01 bis S-KILL-14).

### C.2 Todesursachen (28)

| Ursache | Auslöser [B] | Attribute [E] |
|---|---|---|
| NIGHT_KILL | `night:393-394`, Nekromant-Umlenkung `night:374` | wolf_attack, night |
| PACKFATHER_KILL | `night:393` | wolf_attack, night, pierces |
| LYNCH | `night:461,477,499` | execution |
| BUSDRIVER_LYNCH | `night:432` | execution_side |
| BURN_SPREAD / BURN_LYNCH_SPREAD | `night:345` / `night:445` | ability |
| VOODOO_PUPPET | `night:255,442`, `help:265` | redirect |
| WITCH_POISON | `help:265` | ability, night |
| HUNTER_SHOT | `gh:2006` | reaction |
| BLACK_WIDOW | `night:196` | wolf_ability, dawn |
| GIFTWOLF_DELAY | `night:205` | wolf_ability, dawn |
| HANGMAN_EXECUTION | `night:417` | execution_side |
| SPIEGELWOLF_RETALIATE | `night:489` | reaction |
| BESESSENER_WOLF | `night:313` | reaction |
| SCHMIED_WEAPON | `night:386` | reaction |
| MARTYR_SACRIFICE | `night:262` | sacrifice |
| RITTER_RETALIATION | `core:441` | reaction |
| PARASITE_HOST | `core:164` | chain |
| RED_RIDING_HOOD_LINK | `core:172` | chain |
| LOVER_HEARTBREAK | `core:376,382` | chain |
| HADES_KILL | `ab:37` | ability, night |
| KARTENSCHLUCKER_KILL | `chunk:228` | ability, night |
| PROPHET_KILL | `chunk:823` | ability, night |
| BLOODPRIEST_SACRIFICE | `chunk:703` | ability, night |
| VERDAMMNISWAECHTER | `chunk:733-734` | ability, night |
| AMALIA_SACRIFICE | `chunk:546` | sacrifice |
| WARRIOR_WRONG | `chunk:566` | ability |
| MANIPULATOR_NOMINATED | `gh:429` | day |

Ritter-Vergeltung greift nur bei: NIGHT_KILL, BLACK_WIDOW, GIFTWOLF_DELAY, BURN_SPREAD, HADES_KILL, WITCH_POISON (`core:431`) [B]. In Godot als Attribut `triggers_knight` pro Ursache.

| ID | Regel | Legacy | Godot | Status | Akzeptanz | Test |
|---|---|---|---|---|---|---|
| C-3 | Folgetode-Fixpunkt (Liebende nur wenn Loki genutzt) | `core:365-386` | `kill_pipeline.gd` Kettenschritt | widersprüchlich (manuell gesetzte Liebende ohne Kette) | Kette immer, wenn Liebes-Effekt existiert | S-KILL-15 |
| C-4 | Manueller Tod durch SL | `gh:429` umgeht Pipeline | `GmCorrection(kill, cause=GM)` über Pipeline mit Option „Folgen auslösen ja/nein" | widersprüchlich (F6) | SL-Tod erzeugt dieselben Folgen oder bewusst keine | S-GM-01 |
| C-5 | `killed_tonight` nur für tatsächlich Gestorbene | `night:374,394` | Pipeline-Ergebnis | widersprüchlich (F14) | Überlebender löst keinen Dämonen-Fluch aus | S-KILL-16 |

---

## D. Siegbedingungen

| ID | Regel | Legacy [B] | Godot | Status | Akzeptanz | Test |
|---|---|---|---|---|---|---|
| D-1 | Dorf gewinnt, wenn kein Wolf lebt (Doppelspion statt Dorf, wenn er lebt) | `core:227-232,314-324` | `win_rules.gd` | verifiziert | – | S-WIN-01, S-WIN-06 Golden |
| D-2 | Wölfe gewinnen bei Wolfsstärke ≥ Nicht-Wölfe (Siegreicher = 2) | `core:233,330-334` | `win_rules.gd` | verifiziert | Solos zählen als Nicht-Wölfe | S-WIN-02/03 Golden |
| D-3 | Todesprediger: Vorhersage trifft | `core:153-159` | `todesprediger.gd` `on_death` | unklar (Zählbasis Nacht/Morgen) | Eindeutige Definition „Nacht N" | S-WIN-07 |
| D-4 | Selbstmörder, Pest, Rattenfänger, Hades, Kartenschlucker, Parasit, Manipulator, Nekromant | siehe A | jeweilige `check_win` | verifiziert bzw. wie A | – | S-WIN-08..15 |
| D-5 | Prophet, Feuerteufel, Voodoo, Grabräuber, Die Ewigen, Rachsüchtiger Wolf | fehlt | nach Q4 | fehlend | – | – |
| D-6 | **Ein** Prüfer, erster Sieg gewinnt, keine Überschreibung, Prüfung nur nach Befehlsanwendung (nicht beim Speichern) | zwei Prüfer, `triggerWin` ohne Guard, `state:118` | `win_rules.gd` | widersprüchlich (F7) | Pro Befehl höchstens ein `WinDetected`; Reihenfolge der Solo-Prüfung dokumentiert | S-WIN-16 |
| D-7 | Keine Siegprüfung ohne vergebene Rollen | nur in `checkTeamWin` | Phase `SETUP` ohne Prüfung | verifiziert | – | S-WIN-17 |
| D-8 | Gleichzeitige Siege (z. B. Pest und Wolfsparität am selben Morgen) | Reihenfolge implizit | Prioritätsliste | unklar | PO legt Priorität fest (Q4) | S-WIN-18 |

---

## E. Tag, Nominierung, Hinrichtung

| ID | Regel / Funktion | Legacy [B] | Godot | Status | Akzeptanz | Test |
|---|---|---|---|---|---|---|
| E-1 | Nominierung als Markierung | `gh:274,429` | `Nominate` → `DayState.nominations` | verifiziert | Nominiert-Liste sichtbar, Manipulator-Folge | S-DAY-01 |
| E-2 | Hinrichtung = SL wählt direkt | `night:421-504` | `DecideExecution(seat)` | verifiziert | Gleiche Sonderzweige in gleicher Reihenfolge (04 §C, Lynch-Liste unten) | S-EXE-01..12 Golden |
| E-3 | Lynch-Sonderzweige: Kutscher → Voodoo → Brand → Fenrir → Cerberus → Der Weise → Selbstmörder → Spiegelwolf → Rudelvater → Standard + Kopfgeldjäger → `finalizeLynch` → Dämon | `night:425-501` | `execution.gd` + `on_execution` | verifiziert (F15) | `finalizeLynch` läuft in jedem Zweig, der eine Hinrichtung darstellt | S-EXE-13 |
| E-4 | Henker-Markierung und LynchCount | `night:404-419` | `execution.gd` | verifiziert | – | S-ROLE-41 |
| E-5 | Stimmabgabe, Stimmgewichte, Gleichstand, Bürgermeister | **existiert nicht**; `voteWeight` nur Marker (`js/ui/ui.js:18`) | nach Q2 | fehlend | – | – |
| E-6 | „Keine Hinrichtung heute" | implizit | `DecideExecution(none)` | fehlend | Expliziter Befehl, protokolliert | S-DAY-02 |
| E-7 | Tages-Timer | `js/ui/audio.js:29-70` | `app/` (kein Regelzustand) | verifiziert | Uhr-basiert, übersteht App-Wechsel | UI-Test |

---

## F. Totenkarten

| ID | Regel / Funktion | Legacy [B] | Godot | Status | Akzeptanz | Test |
|---|---|---|---|---|---|---|
| F-1 | 80 Karten, 6 Kategorien, Texte wolf/dorf/neutral/solo | `js/core/cards.js:2-571` | `content/death_cards/*.tres` + `cards.csv` | verifiziert | Import-Skript übernimmt alle 80, ID-stabil | Content-Lint |
| F-2 | Vergabe: Nicht-Wölfe beim Start, Wölfe beim Tod, neu nach Ausspielen | `help:5-20`, `core:190-207` | `death_card_draw.gd` | unklar (Gewichtung zum falschen Zeitpunkt) | Zeitpunkt der Ziehung laut Q3 | S-CARD-01 |
| F-3 | Gewichtung nach Rückstand; WENDE nur bei 4:1/1:4 | `js/core/cards.js:651-699`, `help:76` | `death_card_draw.gd` (Seed) | unklar | – | S-CARD-02 |
| F-4 | Voraussetzungen (Revive-Tags); Solo-Zweig ignoriert sie | `js/core/cards.js:575-627,651-671` | `death_card_draw.gd` | widersprüchlich | Voraussetzungen gelten für alle Zweige | S-CARD-03 |
| F-5 | Anzeige, Ausspielen, Kartenschlucker-Tausch | `help:100-253` | Totenkarten-Assistent (UI) + `PlayDeathCard`/`ResolveDeathCard` | verifiziert | – | S-CARD-04 |
| F-6 | Karteneffekte | **nicht automatisiert** (0 Referenzen) | manuell mit Checkliste (MVP), Automatisierung nach Q3 | fehlend | – | – |
| F-7 | Doppelter Name „Anarchie" | `js/core/cards.js:169,430` | Umbenennung (Inhalt) | widersprüchlich | Eindeutige Namen | Content-Lint |
| F-8 | EN-Kartentexte | nur 46/80 Namen, Mischtexte | `cards.csv` vollständig | fehlend | 80/80 übersetzt | Content-Lint |

---

## G. Vorbereitung, Persistenz, Undo, i18n, Audio

| ID | Funktion | Legacy [B] | Godot | Status | Akzeptanz | Test |
|---|---|---|---|---|---|---|
| G-1 | Spielerzahl 4–40 | `index.html:348-352` | Setup-Assistent | verifiziert | Grenzen gleich; Layout bis 24 abgenommen, 25–40 Listenansicht | UI-Test |
| G-2 | Akte I–IV + Custom, Inhalte | `js/core/akte.js:7-95` | `content/acts/*.tres` | verifiziert | Gleiche Rollenlisten | Content-Lint |
| G-3 | Rollen-Obergrenzen (5/10/6/1) | `setup.html:793-798` | `RoleDef.max_copies` | verifiziert | – | S-SETUP-01 |
| G-4 | Pflichtpaar Witwe → Loki | `setup.html:1111-1117` | `RoleDef.requires_roles` | verifiziert | – | S-SETUP-02 |
| G-5 | Zufällige/manuelle Verteilung | `setup.html:1103-1162` | Setup + Seed | verifiziert | Gleicher Seed → gleiche Verteilung | S-SETUP-03 |
| G-6 | Namensliste | Komma (`setup.html:783-787`) | Zeilen/Komma/Semikolon | fehlend | – | Unit |
| G-7 | Speichern | `localStorage`, still, mit Nebenwirkungen (`state:76-130`) | `SaveService` (03 §6) | widersprüchlich | Speichern ist rein und atomar; Fehler sichtbar | S-SAVE-01..04 |
| G-8 | Migration alter Rollennamen | `state:16-45` | `ids.gd` Legacy-Map | verifiziert | 13 Altnamen abgebildet | Unit |
| G-9 | Undo | 1 Schritt (`state:133-135`), v2 inert | Befehls-Undo/Redo (03 §6.3) | widersprüchlich | 20 Schritte, über Neustart | S-UNDO-01..03 |
| G-10 | Protokoll | RAM, gefiltert | Ereignisprotokoll im Zustand | fehlend (Persistenz) | Nach Neustart vollständig | S-SAVE-05 |
| G-11 | i18n DE/EN | 322 Schlüssel + Substring-Laufzeitübersetzung | `TranslationServer` CSV | widersprüchlich | Keine Laufzeit-Substring-Ersetzung; alle Schlüssel vorhanden (`besessenerWolfDrag` fehlt heute) | Content-Lint |
| G-12 | Nachtmusik mit Positionsspeicher | `night:149-154,180-188` | `AudioDirector` | verifiziert | – | manuell |
| G-13 | Rollen-SFX | No-op (`js/ui/audio.js:12`) | Cue-System (`05`) | fehlend | – | manuell |

---

## H. Offene Fragen, die der Code nicht beantwortet

Nur hier gesammelt; Entscheidungsvorlagen in `07-open-questions.md`.

| Bezug | Frage | → `07` |
|---|---|---|
| A-1, 9, 13, 21, 23, 25, 29, 32, 34, 36, 40, 51, 53, 54, 62; C.1 Nekromant | Gilt bei Widerspruch der Rollentext oder das Legacy-Verhalten? | Q1 |
| A-26, 44, 55; E-5 | Braucht Grimmhain eine Stimmabgabe mit Gewichten? | Q2 |
| F-2, F-3, F-6 | Totenkarten: Zeitpunkt der Ziehung und Automatisierungsgrad | Q3 |
| A-30, 42, 43, 69, 9, 13; D-5, D-8 | Fehlende Solo-Siege und Siegpriorität | Q4 |
| A-6, B-10 | Wann werden Reaktionen auf Sofort-Tode in der Nacht abgearbeitet (sofort oder am Morgen)? | Q1 (Teilfrage) |
| A-19 | Giftwolf: zwei Ladungen in derselben Nacht erlaubt? | Q1 (Tabelle) |
