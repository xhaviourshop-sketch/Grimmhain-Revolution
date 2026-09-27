<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G7 Dorf 3: Legacy-Rollenprüfung (Ritter, Rotkäppchen, Kopfgeldjäger, König, Dr. Victor Frankenstein, Doktor, Fährtenleser, Waldläufer)

Stand: Repository `/home/user/Grimmhain-Revolution`, Commit `4b74bf8`, nur gelesen. Pfad-Kürzel wie im Auftrag (`roles`, `chunk`, `ab`, `help`, `night`, `core`, `ui`, `state`, `gh`).
Hinweis: Wörtliche Zitate (Rollentexte, i18n-Strings) enthalten im Original Gedankenstriche (U+2014). Sie wurden in den Zitaten unverändert übernommen, sonst wird im Dokument kein Gedankenstrich verwendet.

Gemeinsame Grundlagen, die für mehrere Rollen gelten (einmal belegt, unten referenziert):
- Nachtschritt-Aufruf: `ab:71-125 onOrderClick` sucht lebende Rolleninhaber (`ab:72`), blockiert Nicht-Wolf-Rollen bei Schattenhund (`ab:94`), Zeitwächter (`ab:95`), Der-Weise-Debuff (`ab:96`), Albtraum (`ab:97-99`), setzt vor dem Aufruf `snapshot()` (einstufiges Undo). Apfel-Logik: `ab:101-124` (nur wenn genau EIN lebender Rolleninhaber, `actorSeat`), zweite Ausführung nur über `pick`/`startMulti`-Wrapper (`ab:114-121`), `APPLE_RESET_FLAGS` `ab:103-111`.
- Nachtreihenfolge: `night:22-128 rebuildOrder`; Zeile nur bei lebendem Rolleninhaber (`night:93`), `once`-Rollen nach Nutzung weg (`night:60`), passive Rollen ohne Zeile (`night:96-97`).
- SL-Assistent: `night:664-681` ruft beim Knopf "Weiter" für die aktuelle Zeile `onOrderClick(role)` auf, ohne Rückfrage.
- Ergebnisanzeige: `ui:43-53 center` schreibt in `#overlay` (nur SL-Bildschirm). Die React-Version spiegelt `#overlay` als Dialog (`app/src/adapter/legacy/domMirror.ts:53-61`, nur Titel/Text/Buttons, keine `<select>`).
- Wolf-Zugehörigkeit: `core:8-19 isWolf` = `WOLF_ROLES_SET` ODER `flags.werewolf` ODER `meta.cursedWolfAura`; Doppelspion, Manipulator, Parasit, Grabräuber, Todesprediger immer false.
- Fraktion nach Rolle: `roles:405-409 getRoleFaction`, `night:9-11 getFaction` delegiert dorthin (rein rollenbasiert, ignoriert `flags.werewolf`/`cursedWolfAura`).
- Tod: `core:102-216 applyKill`; Rotkäppchen-Kette `core:168-175`; Siegprüfung `core:218-239 checkWinConditions` (in jedem `applyKill`) und `core:287-337 checkTeamWin` (in jedem `save()`, `state:113`).
- Neue Runde im Spiel: `gh:512-530 clearRolesNewRound` setzt Rollen leer, übernimmt aber `s.meta` per `Object.assign` (`gh:517`) und löscht dabei NICHT `rkLink`, `appleBuff`, `ritterRetaliated`, `lastKillCause`, `loverId`, `deathProcessed`.
- Keine der 8 Rollen hat einen Eintrag in `state:15-18 migrateLegacyRoleIds`; keine eigene Migration in `state:48-76 migrateState`.

---

### ritter
- DE-Name / EN-Name: Ritter / Knight (`roles:177`)
- Aliase/Altnamen (state.js migrateLegacyRoleIds, i18n, Bilder, sonstige Schreibweisen im Code): keine Migration (`state:16`). Bilder `assets/cards/de/Ritter.webp`, `assets/cards/en/Knight.webp` (`gh:831`, `app/src/roleCard.ts:65`). Todesursache `RITTER_RETALIATION` (`core:441`, Label `ui:409`, Log `gh:2427`, i18n `logRitter` `i18n:144` DE "wurde vom Ritter erschlagen", `i18n:468` EN "was slain by the Knight"). Veralteter Kommentar `gh:483` behauptet, die Funktion liege in `js/core/night.js`; sie liegt in `core:430`.
- Legacy-ID (String in ALL_ROLES): `"Ritter"` (`roles:1`)
- Fraktion (getRoleFaction) und weitere Fraktionsbesonderheiten im Code: `dorf` (nicht in `WOLF_ROLES_SET` `roles:391-396`, nicht in `SOLO_ROLES_SET` `roles:399-403`). Keine Sonderbehandlung.
- Akte (akte.js): Akt I (`akte.js:17`)
- Nachtpriorität (ORDER_BASE tier, once) und Bedingungen für den Nachtschritt (night.js): kein Eintrag in `ORDER_BASE`; zusätzlich ausdrücklich passiv (`night:96`). Kein Nachtschritt. Wirkung läuft in der Morgenauflösung `night:349`.
- Quelltextstellen (Liste pfad:zeilen Symbol – was dort passiert):
  - `roles:103` / `roles:252` Beschreibung DE/EN.
  - `core:145 applyKill` setzt `meta.lastKillCause` bei jedem Tod.
  - `core:418-428 findNearestWolf` sucht ab Sitz `id` in Abstand d=1..n-1 zuerst `L=(id-1-d)` (niedrigere Sitznummer), dann `R=(id-1+d)`; überspringt tote Sitze, Nicht-Wölfe und Fenrir ab `fenrirStage>=3`.
  - `core:430-450 applyRitterRetaliationFromNight` für jeden toten Ritter ohne `meta.ritterRetaliated`, dessen `lastKillCause` in {NIGHT_KILL, BLACK_WIDOW, GIFTWOLF_DELAY, BURN_SPREAD, HADES_KILL, WITCH_POISON} liegt: Flag setzen, nächsten Wolf mit `applyKill(wolf,"RITTER_RETALIATION")` töten, Log.
  - `night:349 resolveDayKills/runRest` einziger Aufruf, nach Nachtopfern und Brand-Ausbreitung, vor Dämonen-Fluch und Besessener-Wolf-Warteschlange.
  - `night:323-331 resolveDayKills` Zeitwächter-Frost kehrt vor `night:349` zurück.
  - `gh:517 clearRolesNewRound` übernimmt `meta.ritterRetaliated` in die neue Runde.
- Text DE (wörtlich): "Tötet beim Sterben in der Nacht den nächstliegenden Werwolf."
- Text EN (wörtlich): "Upon dying at night, kills the nearest werewolf."
- DE/EN-Vergleich (semantisch gleich JA/NEIN + konkrete Unterschiede): JA. Zeitpunkt (Nacht), Ziel (nächstliegender Werwolf), Häufigkeit (nicht genannt) identisch.
- Weitere Texte (role-abilities.js, i18n.js, Totenkarten-Bezug), falls abweichend: `role-abilities.js:28` identisch mit `roles:103` (per Skript verglichen). Kein Totenkarten-Bezug in `cards.js`.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Ausschließlich in der Morgenauflösung (`night:349`), auch wenn der Ritter mitten in der Nacht starb (Waldhexengift, Hades). Kein eigener Nachtschritt.
  2. Auslöser: Nur die sechs Ursachen aus `core:431`. Nicht ausgelöst bei nächtlichen Toden durch PACKFATHER_KILL (zweites Rudelvater-Opfer, `night:393`), VOODOO_PUPPET (`night:255`), KARTENSCHLUCKER_KILL (`chunk:228`), VERDAMMNISWAECHTER (`chunk:733-734`), PROPHET_KILL (`chunk:823`), BLOODPRIEST_SACRIFICE, RED_RIDING_HOOD_LINK (`core:172`), LOVER_HEARTBREAK (`core:376,382`), BESESSENER_WOLF, HUNTER_SHOT. Nicht ausgelöst beim Lynch (korrekt laut Text) und beim manuellen Tod per Chip "tot" (`gh:429`, setzt `flags.dead` ohne `applyKill`, daher keine `lastKillCause`).
  3. Ziel: automatisch, kein SL-Eingriff. Nächster lebender Sitz mit `isWolf` in Sitzabstand (tote Sitze zählen im Abstand mit); bei Gleichstand gewinnt die niedrigere Sitznummer (`core:424`). `isWolf` schließt verfluchte Dorfbewohner (`cursedWolfAura`) und verwandelte Sitze ein, Doppelspion aus. Fenrir ab Stufe 3 wird übersprungen (`core:421`), der nächste andere Wolf stirbt.
  4. Einmaligkeit: `meta.ritterRetaliated` pro Sitz (`core:438`), auch wenn kein Wolf gefunden wurde. Wird bei Wiederbelebung durch Frankenstein (`chunk:57-62`) nicht zurückgesetzt, durch Kutscher schon (`chunk:849-850` ersetzt `flags` und `meta` komplett).
  5. Wirkung: `applyKill` ohne Schutzprüfung. Schilde in `applyKill` greifen trotzdem (Rudelvater-Ersttod-Rettung `core:111-116` greift, weil RITTER_RETALIATION nicht ausgenommen ist; Kartenschlucker-Schild, Hades-Barriere, Nekromant-Schild). Schattenwanderer-Umlenkung (`core:118-124`) lenkt den Ritter-Schlag auf den Tauschpartner um.
  6. Folgen: Der getötete Wolf wird nicht in `killedTonight` aufgenommen, daher löst ein vom Ritter getöteter Dämonischer Wolf keinen Fluch aus (`night:352` nutzt `killedTonight`). Siegprüfung läuft in `applyKill`.
  7. Sichtbarkeit: öffentliches Ergebnis über Morgen-Todeszusammenfassung (`night:350 showNightDeathSummary`) und Protokoll.
  8. Mehrere Kopien: alle toten Ritter werden per `filter` verarbeitet (`core:432`), je einer ein Schlag.
  9. Zufall: keiner.
  10. Verzögerung: Stirbt der Ritter durch BLACK_WIDOW/GIFTWOLF_DELAY (`night:196,205`) oder nachts durch Gift/Hades in einer vom Zeitwächter eingefrorenen Nacht, kehrt `resolveDayKills` vor `night:349` zurück (`night:323-331`); die Vergeltung erfolgt dann erst in der nächsten regulär aufgelösten Nacht.
  11. Neue Runde über `clearRolesNewRound`: `ritterRetaliated=true` bleibt am Sitz (`gh:517`), ein neuer Ritter auf diesem Sitz schlägt nie zurück.
- React-Version: kein eigenes Verhalten. Nur Bildzuordnung `app/src/roleCard.ts:65` und Textaufteilung der Todesliste `domMirror.ts:28-30`.
- Bisherige Doku (04-Status + Kernaussage, 07-Frage, DECISION-LOG, Berichte) und Prüfergebnis dazu:
  - 04 Zeile 47: "verifiziert", `core:418-450`, "Nachts getötet (Ursachen-Liste `core:431`) → nächster lebender Wolf stirbt (links vor rechts)". Zeilen bestätigt. "links vor rechts" ist nur als Code-Variablenname richtig: `L` ist die niedrigere Sitznummer. Der Fährtenleser nennt die HÖHERE Sitznummer "links" (04 Zeile 57). Beide Regeln bezeichnen damit entgegengesetzte Richtungen; siehe Gruppenübergreifende Beobachtungen.
  - 04 Abschnitt C (Zeile 179): Ursachenliste bestätigt.
  - GRIMMHAIN_ANALYSE_2026-06-12.md L2 (doppelte Funktion, Cause `RITTER_RETALIATE`, feuert nicht bei Witwe/Hades/Giftwolf): widerlegt für den aktuellen Stand, nur noch eine Definition `core:430`, Cause einheitlich `RITTER_RETALIATION`, Witwe/Hades/Giftwolf in der Liste. Recap-Filter enthält jetzt "erschlagen" und "⚔️" (`gamelog.js:19,24`), Befund aus Zeile 186 dort ebenfalls erledigt.
  - 07 und DECISION-LOG: kein Eintrag zum Ritter. 07 Q1 letzte Zeile ("Reaktionen auf Sofort-Tode in der Nacht ... alle Reaktionen am Morgen") betrifft den Ritter mittelbar; Legacy verhält sich bereits so.
  - ROLE-FLOW-REPORT.md:66,75: Normalfall (Wolf tötet Ritter → Vergeltung) im Browser beobachtet; nicht erneut ausgeführt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Welche Nachttode lösen aus | "beim Sterben in der Nacht" (jede Ursache) | "Upon dying at night" | nur 6 Ursachen (`core:431`), nicht Rudelvater-Zweitopfer, Voodoo-Puppe, Kartenschlucker, Verdammniswächter, Prophet, Blutpriester, Ketten-/Liebestod | wie Legacy | 04 C: Liste als Regel übernommen (`triggers_knight`) | jeder Tod in der Nacht löst aus | nur Tode durch feindliche Nachtangriffe (Liste, ggf. erweitert um PACKFATHER_KILL) | A stärkt das Dorf deutlich (auch Kettentode schlagen zurück) | Ursachen-Attribut `triggers_knight` in beiden Fällen nötig, nur Belegung unterscheidet sich | B mit Ergänzung PACKFATHER_KILL und VOODOO_PUPPET, Text präzisieren | Ja |
| Verfluchter Dorfbewohner als Ziel | "Werwolf" | "werewolf" | `isWolf` zählt `cursedWolfAura` (`core:18`), Ritter kann Verfluchten töten | wie Legacy | 04 Zeile 32 nennt den Ritter ausdrücklich als betroffen | nur echte Wölfe | alles, was als Wolf zählt | A schützt Verfluchte | Ziel über `counts_as_wolf` statt `appears_as` | hängt an Q1 Dämonischer Wolf; bei "nur Erscheinung" nur echte Wölfe | Ja (über Q1) |
| Fenrir ab Stufe 3 | nicht erwähnt | nicht erwähnt | wird übersprungen (`core:421`) | wie Legacy | nicht dokumentiert | Fenrir-Immunität gilt auch gegen Ritter | Ritter trifft Fenrir normal | gering | Sonderregel im Zielfinder | nach Fenrir-Entscheidung (07 Q1 Fenrir-Zeile) ausrichten | Ja |

- Bugs:
  - B-RIT-1 (echter Bug): Codepfad `gh:512-518 clearRolesNewRound`. Tatsächlich: `meta.ritterRetaliated` und `meta.lastKillCause` bleiben nach "Neue Runde" am Sitz. Erwartet: neue Runde beginnt ohne Altzustand. Risiko: mittel (Ritter in Folgerunde wirkungslos, fällt am Tisch kaum auf). Regressionstest: Runde 1 Ritter auf Sitz 3 stirbt nachts und schlägt zurück; "Neue Runde"; Runde 2 Ritter erneut auf Sitz 3, Rudel tötet ihn; erwartet: nächster Wolf stirbt.
  - B-RIT-2 (unklare Regel): Verzögerte Vergeltung bei Zeitwächter-Frost (`night:323-331`). Tatsächlich: Ritter-Tod durch Gift/Hades/Witwe in eingefrorener Nacht wird erst eine Nacht später vergolten. Erwartet: laut Text beim Sterben. Risiko: niedrig. Test: Zeitwächter friert Nacht ein, Waldhexe vergiftet Ritter; erwartet (je Entscheidung) Vergeltung am selben Morgen oder keine.
  - B-RIT-3 (unklare Regel): Ritter-Opfer nicht in `killedTonight` (`night:349` vs `night:352`), Dämonischer Wolf flucht nicht, wenn der Ritter ihn tötet. Risiko: niedrig. Test: Ritter stirbt nachts, nächster Wolf ist Dämonischer Wolf; erwartet laut Dämonen-Text: Fluch-Auswahl.
- Legacy-Status: legacy-contradictory. Der Kernfall (Rudel tötet Ritter, nächster Wolf stirbt) ist korrekt umgesetzt, der Text verspricht aber jeden Nachttod, der Code nur eine Whitelist; Zielmenge über `cursedWolfAura` und Fenrir-Ausnahme sind nicht im Text.
- Automationsvorschlag: automatic. Keine Entscheidung des Spielers, Ziel deterministisch aus Sitzordnung; SL sollte das Ergebnis vor der Veröffentlichung sehen (Vorschau im Morgen).
- Mechanikfamilie primär + sekundär: Todesreaktion + Sitzpositionsmechanik (sekundär Tötung).
- Benötigte vorhandene Godot-Systeme: KillPipeline (Ursache, Quelle), Reaktionswarteschlange (Morgenauflösung), WinRules/WinCandidate, Ereignis-Sichtbarkeit, StateCodec, Replay, GmCorrections (kill mit/ohne `trigger_effects`).
- Benötigte NEUE Systeme: Sitznachbarschaft (Abstands-/Richtungsfunktion über `GameState.seat_order`, das es bereits gibt, `godot/core/model/game_state.gd:22,64`), Ursachen-Attribut `triggers_knight`, einmaliger Verbrauch pro Person (`ability_uses` existiert, Schlüssel neu).
- Abhängigkeiten von anderen Rollen: Dämonischer Wolf (Verfluchte), Fenrir, Rudelvater (Ersttod-Rettung, PACKFATHER_KILL), Schattenwanderer (Umlenkung), Zeitwächter, Waldhexe, Hades, Schwarze Witwe, Giftwolf, Feuerteufel, Kartenschlucker, Nekromant-Schild, Frankenstein/Kutscher (Wiederbelebung), Rotkäppchen/Loki (Kettentode).
- Komplexität und Fehlerrisiko: M / mittel. Automatik ist einfach, aber Ursachenliste, Zielbestimmung (Wolf-Definition, Gleichstand, Richtung) und Reihenfolge in der Morgenauflösung sind fehleranfällig.
- Offene Entscheidungen:
  1. Löst jeder Tod in der Nacht aus oder nur eine Ursachenliste? Gehören PACKFATHER_KILL und VOODOO_PUPPET dazu?
  2. Darf der Ritter einen nur verfluchten Dorfbewohner treffen?
  3. Gleichstand links/rechts: welche Richtung (aus Sicht des Ritters), und soll der SL wählen?
  4. Ist Fenrir ab Stufe 3 gegen den Ritter immun?
  5. Wird die Vergeltung nach Wiederbelebung erneut verfügbar?
  6. Wirkt die Rudelvater-Ersttod-Rettung gegen den Ritter-Schlag?
- Relevante Testgruppen:
  - Normalfall: Sitz 1 Ritter, Sitz 2 Werwolf, Rudel tötet Ritter → Morgen: Sitz 2 stirbt mit RITTER_RETALIATION.
  - ungültiges Ziel: kein lebender Wolf außer Fenrir Stufe 3 → niemand stirbt, Verbrauch trotzdem gesetzt.
  - tote Person: toter Wolf näher als lebender Wolf → lebender, weiter entfernter Wolf stirbt.
  - Selbstwahl: nicht relevant, weil kein Ziel gewählt wird und der Ritter selbst tot ist.
  - mehrere Kopien: zwei Ritter sterben in derselben Nacht → zwei Vergeltungen, jeweils nächster Wolf (ggf. derselbe, dann nur ein Tod).
  - Wiederbelebung: Ritter per Kutscher wiederbelebt und erneut nachts getötet → Vergeltung erneut (Legacy) bzw. laut Entscheidung.
  - Rollenwechsel: Seelentauscher tauscht Ritter weg; der neue Ritter-Sitz schlägt beim Nachttod zurück, der alte nicht.
  - Save/Load: nach Tod vor Morgenauflösung speichern/laden → genau eine Vergeltung.
  - Replay: gleiche Befehlsfolge ergibt dasselbe Opfer (deterministisch).
  - SL-Korrektur: GmCorrection kill ohne `trigger_effects` → keine Vergeltung; mit → Vergeltung.
  - Sichtbarkeit: Vergeltungstod öffentlich, Ursache nur für SL als Detail.
  - Schutz: Schutzengel schützt den Ziel-Wolf → Schlag trifft trotzdem (Schutz nur gegen Rudel).
  - Todesreaktionen: Ritter-Opfer ist Besessener Wolf → dessen Mitreißen wird eingereiht.
  - Siegprüfung: Ritter-Schlag tötet letzten Wolf → Dorf-Siegkandidat.
  - beschädigter Spielstand: `ritterRetaliated` fehlt/ist kein bool → Laden lehnt ab oder normalisiert.
- Belegsicherheit: hoch. Nicht ausgeführt (nur statisch gelesen): tatsächliche Laufzeitreihenfolge von Protokolleinträgen; Wirkung der doppelten Protokollierung (`gh:2408-2433` patcht `applyKill`, `core:445` loggt zusätzlich) nicht geprüft.

---

### rotkaeppchen
- DE-Name / EN-Name: Rotkäppchen / Little Red Riding Hood (`roles:178`)
- Aliase/Altnamen: keine Migration. Bilder `assets/cards/de/Rotkäppchen.webp`, `assets/cards/en/Little_Red_Riding_Hood.webp` (`gh:832`, `app/src/roleCard.ts:66`). i18n-Schlüssel mit Tippfehler-Stamm `rotkppchenPickShelter` (`i18n:319` DE "Rotkäppchen (U+2014) Zuflucht bei anderem Spieler", `i18n:643` EN) und `rotkppchenConfirmShelter` (`i18n:301`, `i18n:625`). Interner Funktionsname `rotkppchenShelterLinkActive` (`core:58`). Todesursache `RED_RIDING_HOOD_LINK` (`core:172`, Label `ui:410` "💔 Rotkäppchen"). Seat-Felder `meta.rkLink`, `meta.appleBuff`. Rollentags `["chain-reaction","dead-interaction"]` (`roles:297`), im Code nirgends ausgewertet.
- Legacy-ID: `"Rotkäppchen"` (`roles:1`)
- Fraktion: `dorf`. Keine Sonderbehandlung.
- Akte: Akt III (`akte.js:57`)
- Nachtpriorität und Bedingungen: tier 7.4, nicht once (`roles:50`). Zeile, solange eine lebende Rotkäppchen existiert (`night:93`). Keine weiteren Bedingungen.
- Quelltextstellen:
  - `roles:104` / `roles:253` Texte.
  - `ab:7-25 abilities["Rotkäppchen"]` erste lebende Rotkäppchen (`find`), Ziel per `pick` aus lebenden Nicht-Wölfen außer ihr selbst (`ab:24`), danach Ja/Nein `startConfirm` "Gewährt Zuflucht?". Bei Ja: alte Verbindung des alten Partners löschen, `target.meta.appleBuff=true`, beidseitig `meta.rkLink`. Bei Nein: nichts (alte Verbindung bleibt).
  - `ab:101-124 onOrderClick` Apfel: vorab `APPLE_RESET_FLAGS` für König/Frankenstein/Dorfschmied/"Chronist"/Pestbringerin/Prophet löschen (`ab:103-112`), zweite Ausführung nur nach `pick`/`startMulti` (`ab:114-121`), nur bei genau einem lebenden Rolleninhaber.
  - `core:58-64 rotkppchenShelterLinkActive` Kette aktiv, wenn einer der beiden die Rolle Rotkäppchen hat oder `appleBuff` trägt.
  - `core:168-175 applyKill` Kette: stirbt ein Sitz mit `rkLink`, und der Partner lebt und verweist zurück, stirbt der Partner mit `RED_RIDING_HOOD_LINK`.
  - `night:529-530 resetMarksOnly` löscht `rkLink`/`appleBuff`.
  - `gh:517 clearRolesNewRound` löscht beide NICHT.
- Text DE (wörtlich): "Jede Nacht sucht sie bei einem anderen Spieler Zuflucht. Gewährt er sie, erhält er einen Apfel: Seine nächste Fähigkeit wird doppelt ausgeführt. Außerdem verbindet beide eine Todeskette (U+2014) stirbt einer, stirbt der andere mit."
- Text EN (wörtlich): "Each night she seeks refuge with another player. If he grants it, he receives an apple: his next ability is executed twice. The two are also bound by a death chain (U+2014) if one dies, the other dies with them."
- DE/EN-Vergleich: JA. Beide lassen gleichermaßen offen, ob die Todeskette nur bei gewährter Zuflucht entsteht ("Außerdem"/"also"), wie lange sie gilt und ob "anderen Spieler" "nicht sie selbst" oder "jede Nacht ein anderer" bedeutet.
- Weitere Texte: `role-abilities.js:29` identisch. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht bei tier 7.4 (nach Rudel, Hexe, den meisten Dorfrollen). Die neue Kette gilt schon für die Opfer derselben Nacht (Auflösung am Morgen).
  2. Ziele: lebend, nicht sie selbst, nicht `isWolf` (`ab:24`); verfluchte Dorfbewohner sind damit auch ausgeschlossen. Wiederholung desselben Ziels in Folgenächten erlaubt.
  3. Zustimmung: SL-Dialog Ja/Nein. Nein: keine Wirkung, die Kette der Vornacht bleibt bestehen.
  4. Wirkung Kette: dauerhaft bis zur nächsten gewährten Zuflucht oder "Marker zurücksetzen". Wirkt bei jeder Todesursache in `applyKill` (Lynch, Gift, Ritter usw.), Tag und Nacht, ohne Schutzprüfung; Schilde in `applyKill` greifen für den Partner (Kartenschlucker, Hades, Nekromant; Parasit überlebt, solange sein Wirt lebt). Manueller Tod per Chip (`gh:429`) löst keine Kette aus.
  5. Wirkung Apfel: `meta.appleBuff` beim Ziel. Verdoppelung nur, wenn das Ziel alleiniger lebender Inhaber seiner Rolle ist und seine Fähigkeit `pick`/`startMulti` nutzt (z. B. Doktor). Bei Fähigkeiten ohne Auswahl (König, Waldläufer, Kopfgeldjäger, Fährtenleser) und bei passiven Rollen wird der Apfel nie verbraucht und nie wirksam. Wölfe können ihn nicht erhalten.
  6. Nebenwirkung Apfel: `ab:112` löscht vor JEDER Ausführung die Flags aus `APPLE_RESET_FLAGS`, solange der Apfel noch da ist; beim König wird der Apfel nie verbraucht, er kann dann in derselben Nacht beliebig oft neu klicken (siehe koenig). Schlüssel `"Chronist"` (`ab:107`) passt zu keiner Rolle (gemeint Dorfchronistin), bekannt aus 04 B-12.
  7. Sichtbarkeit: Zuflucht, Apfel und Kette sind geheim (SL-Dialog). Kettentod erscheint öffentlich als Tod mit Ursache.
  8. Mehrere Kopien: nur die erste lebende Rotkäppchen handelt (`ab:8`), weitere nie. Apfel/Kette sind pro Sitz gespeichert, ein zweites Rotkäppchen würde beim alten Partner der ersten nichts löschen.
  9. Zufall: keiner.
  10. Rollenwechsel: Seelentauscher tauscht die Rolle weg, `rkLink` bleibt am Sitz; Kette bleibt nur aktiv, solange einer noch Rotkäppchen ist oder der Partner `appleBuff` trägt (`core:58-64`).
  11. Neue Runde: `rkLink` und `appleBuff` bleiben über `clearRolesNewRound` erhalten; mit altem `appleBuff` bleibt die Kette in der neuen Runde auch ohne Rotkäppchen aktiv (`core:61-62`).
- React-Version: kein eigenes Verhalten (nur `roleCard.ts:66`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 48 "verifiziert", `ab:7-25,101-124`, `core:168-175`: Zeilen bestätigt. Kernaussage "Apfel: Partner nutzt Fähigkeit doppelt" gilt nur für pick-basierte Fähigkeiten eines alleinigen Rolleninhabers; 04 B-12 sagt das richtig, Zeile 48 nicht. Dauer der Kette, Verhalten bei "Nein" und Nicht-Verbrauch des Apfels fehlen in 04.
  - 04 B-12 (`ab:101-124`, Schlüsselfehler `"Chronist"`): bestätigt.
  - 01 Zeile 169 Reihenfolge in `applyKill` (Rotkäppchen-Kette nach Parasit, vor Besessenem Wolf): bestätigt (`core:161-175`).
  - 07, DECISION-LOG: kein Eintrag.
  - NIGHT-REPORT-abilities.md:32 "1 Ziel": unvollständig, es folgt ein Ja/Nein-Dialog.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Wölfe als Zuflucht | "einem anderen Spieler" | "another player" | nur Nicht-Wölfe (`ab:24`) | wie Legacy | 04: "Verbindet sich mit Nicht-Wolf" | jede andere lebende Person | nur Nicht-Wölfe | A erlaubt Wolf-Apfel (Doppelkill?) und Wolf-Kette | Zielfilter | B (Code), Text ergänzen | Ja |
| Apfel-Wirkung | "nächste Fähigkeit wird doppelt ausgeführt" | "next ability is executed twice" | nur pick/multi-Fähigkeiten, sonst nie verbraucht | wie Legacy | 04 Zeile 48 pauschal, B-12 eingeschränkt | jede nächste Fähigkeit (auch Info) zweimal | nur Zielwahl-Fähigkeiten, sonst verfällt der Apfel | A wertet Info-Rollen stark auf | "repeat step" in StepQueue plus Verfall-Regel | eigene Regel: Apfel verfällt nach der nächsten eigenen Nachtaktion, Info-Rollen erhalten die Info zweimal oder gar nicht (entscheiden) | Ja |
| Dauer der Kette | offen | offen | bis zur nächsten angenommenen Zuflucht, übersteht Tage | wie Legacy | nicht dokumentiert | nur diese Nacht | bis zur nächsten gewährten Zuflucht | A schwächt Risiko deutlich | Bindungsobjekt mit Gültigkeit | B (Code) festschreiben | Ja |
| Ablehnung | "Gewährt er sie, ..." | "If he grants it, ..." | Nein ändert nichts, alte Kette bleibt | wie Legacy | nicht dokumentiert | Ablehnung löst alte Kette | alte Kette bleibt | gering | Bindung beenden oder nicht | entscheiden | Ja |
| Mehrfache Zuflucht beim Selben | "anderen Spieler" | "another player" | erlaubt | wie Legacy | nicht dokumentiert | jede Nacht ein anderer | beliebig | A verhindert Dauer-Apfel beim selben Spieler | Zielhistorie | entscheiden | Ja |

- Bugs:
  - B-RK-1 (echter Bug): `gh:512-518 clearRolesNewRound` behält `meta.rkLink`/`meta.appleBuff`. Tatsächlich: In der neuen Runde sterben zwei Sitze gemeinsam (Kette aktiv wegen altem `appleBuff`, `core:61-62`) und ein Sitz hat einen Gratis-Apfel. Erwartet: sauberer Start. Risiko: hoch (unerklärlicher Tod in neuer Partie). Test: Runde 1 Zuflucht A→B gewährt; "Neue Runde" ohne Rotkäppchen; Lynch A; erwartet: B lebt.
  - B-RK-2 (technische Altlast): Apfel wird bei Fähigkeiten ohne `pick`/`startMulti` nie verbraucht (`ab:113-124`), bleibt dauerhaft. Risiko: mittel (König-Mehrfachnutzung, s. koenig). Test: Apfel an König, zwei Klicks auf König in einer Nacht bei Tote > Lebende; erwartet: höchstens eine bzw. zwei Infos laut Entscheidung, Apfel danach weg.
  - B-RK-3 (technische Altlast): Mehrere Rotkäppchen, nur die erste handelt (`ab:8`). Risiko: niedrig (Einzelrolle). Test: zwei Rotkäppchen → zwei Schritte oder `max_copies=1`.
- Legacy-Status: legacy-contradictory. Kette und Zuflucht funktionieren; der Apfel wirkt nur für einen Teil der Rollen, und Zielbeschränkung/Dauer weichen vom Text ab bzw. sind dort nicht geregelt.
- Automationsvorschlag: assisted. Zuflucht und Zustimmung sind Entscheidungen am Tisch (SL tippt), Kette und Apfel-Verfall kann der Kern automatisch führen.
- Mechanikfamilie primär + sekundär: Verknüpfte Personen + Todesreaktion (sekundär mehrstufige Nachtfähigkeit, sonstige Spezialmechanik für den Apfel).
- Benötigte vorhandene Godot-Systeme: PendingPrompt (Ziel → Zustimmung → Bestätigung), StepQueue, KillPipeline (Folgetod mit eigener Ursache, `03` Zeile 230), Reaktionswarteschlange, RoleTransition (Kette bei Rollenwechsel), StateCodec, Replay, Ereignis-Sichtbarkeit, GmCorrections.
- Benötigte NEUE Systeme: Bindungsmodell (Paarbindung mit Gültigkeit, analog Liebespaar), dauerhafter Statusmarker "Apfel" mit Verbrauchsregel, "repeat step"/Doppel-Ausführung in StepQueue, ggf. Zielhistorie.
- Abhängigkeiten von anderen Rollen: alle Rollen mit Nachtfähigkeit (Apfel), König/Frankenstein/Dorfschmied/Pestbringerin/Prophet (`APPLE_RESET_FLAGS`), Seelentauscher, Parasit, Kartenschlucker/Hades/Nekromant (Schilde), Ritter (Kettentod löst keine Vergeltung aus), Loki (zweites Bindungssystem).
- Komplexität und Fehlerrisiko: L / hoch. Zwei gekoppelte Mechaniken (Kette + Apfel), Apfel berührt jede Nachtfähigkeit, Kettenrekursion in der KillPipeline.
- Offene Entscheidungen:
  1. Dürfen Wölfe Zuflucht gewähren?
  2. Wie lange gilt die Todeskette, und endet sie bei Ablehnung?
  3. Entsteht die Kette nur bei gewährter Zuflucht?
  4. Was bedeutet "doppelt" bei Info-Rollen und passiven Rollen, und verfällt ein ungenutzter Apfel?
  5. Darf dieselbe Person mehrmals hintereinander gewählt werden?
  6. Wirkt die Kette auch bei Hinrichtung am Tag (Legacy: ja)?
- Relevante Testgruppen:
  - Normalfall: Zuflucht bei Doktor gewährt, Rudel tötet Doktor → Rotkäppchen stirbt mit RED_RIDING_HOOD_LINK.
  - ungültiges Ziel: Auswahl eines Werwolfs → abgelehnt (`invalid_target`).
  - tote Person: toter Spieler als Ziel → abgelehnt.
  - Selbstwahl: Rotkäppchen wählt sich → abgelehnt.
  - mehrere Kopien: zwei Rotkäppchen → beide erhalten eigenen Schritt oder Setup verhindert Doppelung.
  - Wiederbelebung: Partner stirbt (Kette tötet Rotkäppchen), Partner wird wiederbelebt → Rotkäppchen bleibt tot, Kette ist beendet.
  - Rollenwechsel: Seelentauscher tauscht Rotkäppchen weg → Kette gilt laut Entscheidung weiter oder endet.
  - Save/Load: zwischen Ziel und Zustimmung speichern → Prompt-Stufe wird wiederhergestellt.
  - Replay: Kette und Apfel identisch rekonstruiert.
  - SL-Korrektur: GmCorrection kill mit `trigger_effects=false` → kein Kettentod.
  - Sichtbarkeit: Zuflucht/Apfel nur gm/actor, Kettentod öffentlich.
  - Schutz: Schutzengel schützt Partner vor Rudel → keiner stirbt; Kettentod selbst ignoriert Schutz.
  - Todesreaktionen: Partner ist Sensenträger → Kettentod reiht seine Reaktion ein.
  - Siegprüfung: Kettentod tötet letzten Nicht-Wolf → Wolf-Siegkandidat.
  - beschädigter Spielstand: einseitiger `rkLink` → Laden lehnt ab.
- Belegsicherheit: hoch für Kette und Apfel-Mechanik (statisch belegt). Nicht zur Laufzeit geprüft: Zusammenspiel `startConfirm`-Overlay mit gleichzeitigem `center` anderer Rollen.

---

### kopfgeldjaeger
- DE-Name / EN-Name: Kopfgeldjäger / Bounty Hunter (`roles:180`)
- Aliase/Altnamen: keine Migration. Bilder `Kopfgeldjäger.webp` / `Bounty_Hunter.webp` (`gh:833`, `roleCard.ts:68`). State-Schlüssel `once.BountyHunterActive`; toter Schlüssel `once.KopfgeldjägerUsed` (wird nur gesetzt/gelöscht, nie gelesen: `gh:523`, `core:354`). i18n `bountyHunterInactive` (`i18n:188`, `i18n:512`), `bountyHunterSees` (`i18n:190`, `i18n:514`).
- Legacy-ID: `"Kopfgeldjäger"` (`roles:1`)
- Fraktion: `dorf`. Keine Sonderbehandlung.
- Akte: Akt IV (`akte.js:77`)
- Nachtpriorität und Bedingungen: tier 3.2 (Gruppe D "Post-Wolf Reaktion"), nicht once (`roles:27`). Zeile jede Nacht, solange er lebt; keine Aktivierungsbedingung in `rebuildOrder`, inaktiv wird erst im Handler gemeldet.
- Quelltextstellen:
  - `night:499 doLynchFlow` Standard-Lynch: `if (isWolf(target)) BountyHunterActive = true`.
  - `night:462 doLynchFlow` Der-Weise-Zweig: gleiche Aktivierung.
  - `chunk:3-27 GRIMM_ABILITIES_ROLES["Kopfgeldjäger"]` inaktiv → Meldung; Wölfe = lebend und `isWolf`, Andere = lebend und nicht `isWolf`; bei 0 Wölfen oder < 2 Anderen: Meldung "Nicht genügend Ziele", Flag verbraucht; sonst 1 zufälliger Wolf + 2 zufällige Andere, zufällig gemischt, Namen anzeigen, Flag verbraucht.
  - `core:354 resetOnceForInheritedRole` bei Erbe/Tausch zur Rolle: `BountyHunterActive=true`.
  - `gh:523 clearRolesNewRound` setzt `BountyHunterActive=false`.
- Text DE (wörtlich): "Sobald ein Werwolf gelyncht wird, sieht er drei Spieler (einer davon ist ein Werwolf)."
- Text EN (wörtlich): "Once a werewolf has been lynched, learns three names (U+2014) one of them is a werewolf."
- DE/EN-Vergleich: NEIN (Nuance). DE "Sobald ... gelyncht wird" liest sich als Auslöser je Lynch; EN "Once a werewolf has been lynched" kann auch "ab dem ersten Wolfs-Lynch (danach dauerhaft)" bedeuten. Sonst gleich: drei Spieler/Namen, einer davon Werwolf; beide lassen offen, ob "genau einer".
- Weitere Texte: `role-abilities.js:20` identisch mit DE. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Aktivierung: nur im Standard-Lynch und im Der-Weise-Zweig, wenn der Gelynchte `isWolf` ist (auch verfluchter Dorfbewohner oder verwandelter Sitz). Nicht in den Zweigen Wahnsinniger Kutscher, Voodoo-Umlenkung, Spiegelwolf-Spiegelung, Fenrir/Cerberus-Überleben, Selbstmörder (dort stirbt jeweils kein Wolf durch Lynch oder der Gelynchte ist kein Wolf). Aktivierung unabhängig davon, ob der Kopfgeldjäger lebt.
  2. Zeitpunkt: in der folgenden Nacht bei tier 3.2 (nach dem Rudel), per SL-Klick.
  3. Häufigkeit: bool, nicht zählend. Zwei Wolfs-Lynche vor seiner Nacht ergeben eine Info.
  4. Auswahl: automatisch mit `Math.random` (`chunk:16,19,22`); die zwei "Anderen" schließen den Kopfgeldjäger selbst NICHT aus (`chunk:9`) und können Solo-Rollen und Doppelspion enthalten. Mischung per `sort(() => Math.random() - 0.5)` (verzerrt).
  5. Verbrauch: auch bei "Nicht genügend Ziele" (`chunk:12`). Bei Blockade (Schattenhund, Albtraum, Der Weise, Zeitwächter, `ab:94-99`) nicht verbraucht, Info folgt in einer späteren Nacht.
  6. Sichtbarkeit: geheim, SL-Dialog mit Namen (ohne Rollen).
  7. Mehrere Kopien: globales Flag, Handler läuft einmal pro Klick; zwei Kopfgeldjäger teilen sich eine Info.
  8. Rollenwechsel: Lehrling-Erbe oder Seelentauscher-Tausch zur Rolle Kopfgeldjäger aktiviert sofort (`core:354`), ohne Wolfs-Lynch.
  9. Apfel: Handler nutzt kein `pick`, Apfel wirkungslos und unverbraucht.
- React-Version: kein eigenes Verhalten (`roleCard.ts:68`). Ergebnis läuft über `center` → `#overlay` → Dialog-Spiegel.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 50 "verifiziert", `chunk:3-27`, "Nach jedem Wolfs-Lynch einmal: 3 Namen, genau 1 Wolf": Zeilen bestätigt. "Nach jedem Wolfs-Lynch" ist ungenau (bool, nicht kumulierend). "genau 1 Wolf" bestätigt (die zwei Anderen sind nie `isWolf`). Nicht erwähnt: Selbstanzeige, Aktivierung durch Erbe, Verbrauch bei zu wenigen Zielen.
  - 04 E-3 (Lynch-Sonderzweige, "Standard + Kopfgeldjäger"): bestätigt, zusätzlich Der-Weise-Zweig `night:462`.
  - 04 Zeile 69 Traumdeuter "wie Kopfgeldjäger": `chunk:831` hat dieselbe Auswahlstruktur (nicht Teil dieser Gruppe, nur gesichtet).
  - 07, DECISION-LOG: kein Eintrag. NIGHT-REPORT-abilities.md:60 "bedingt (Wolf-Lynch) → Info (3)": bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Wiederholung | je Lynch ("Sobald ... wird") | ab erstem Lynch ("Once ... has been") | bool je Nacht, mehrere Lynche vor einer Nacht = eine Info | wie Legacy | 04: "nach jedem Wolfs-Lynch" | eine Info pro Wolfs-Lynch (Zähler) | eine Info in der Nacht nach einem Wolfs-Lynch | A minimal stärker | Zähler statt bool | A (Zähler), Texte angleichen | Ja |
| Selbst unter den drei | "drei Spieler" | "three names" | Kopfgeldjäger kann sich selbst sehen | wie Legacy | nicht dokumentiert | drei andere Spieler | beliebige lebende | A gibt mehr Info | Filter `id != actor` | A | Ja |
| Aktivierung durch Erbe | Auslöser Lynch | Auslöser Lynch | Erbe/Tausch aktiviert sofort (`core:354`) | wie Legacy | 01 Zeile 222 nennt nur die Flag-Inkonsistenz | nur Lynch aktiviert | Erbe startet aktiv | B schenkt Info | Rollenwechsel mit frischen Einsätzen ohne Aktivierung | A | Ja |
| Verfluchter als "Werwolf" | "Werwolf" | "werewolf" | `isWolf` inkl. `cursedWolfAura` bei Auslösung und Anzeige | wie Legacy | Q1 Dämonischer Wolf | nur echte Wölfe | Erscheinung zählt | hängt an Q1 | `counts_as_wolf` vs `appears_as` | nach Q1 | Ja (über Q1) |

- Bugs:
  - B-KGJ-1 (unklare Regel, wahrscheinlich Versehen): `chunk:9` schließt den Kopfgeldjäger nicht aus. Tatsächlich: er kann als einer der drei erscheinen. Erwartet: drei andere Spieler. Risiko: mittel (Info wertlos). Test: 4 Lebende (KGJ, Wolf, A, B), Seed so, dass KGJ gezogen würde; erwartet: nie KGJ in der Liste.
  - B-KGJ-2 (unklare Regel): `core:354` aktiviert bei Erbe. Risiko: niedrig. Test: Lehrling erbt Kopfgeldjäger ohne vorherigen Wolfs-Lynch; erwartet: "inaktiv".
  - B-KGJ-3 (technische Altlast): toter Schlüssel `KopfgeldjägerUsed` (`gh:523`, `core:354`), verzerrte Mischung `chunk:22`. Risiko: niedrig. Test: Mischung über SeededRng gleichverteilt (Statistik über viele Seeds).
- Legacy-Status: legacy-verified. Kernfunktion (nach Wolfs-Lynch in der Folgenacht drei Namen, genau ein Wolf) ist nachvollziehbar umgesetzt; Abweichungen betreffen Randfälle (Selbstanzeige, Zähler, Erbe).
- Automationsvorschlag: automatic. Keine Spielerentscheidung; Auswahl über SeededRng, SL sieht das Ergebnis vor dem Zeigen (InfoRecord).
- Mechanikfamilie primär + sekundär: Informationsrolle + Hinrichtungsreaktion (sekundär Zufallsmechanik).
- Benötigte vorhandene Godot-Systeme: ExecutionRules (Auslöser nach Hinrichtung), StepQueue (bedingter Schritt), SeededRng, InfoRecord (Wahrheit/ermittelt/gezeigt), Ereignis-Sichtbarkeit, StateCodec, Replay, RoleTransition.
- Benötigte NEUE Systeme: Aktivierungszähler pro Person/Rolle (Erweiterung `ability_uses` oder Rollenzustand), bedingte Schrittverfügbarkeit ("nur wenn aktiv") in StepQueue; InfoRecord für Namenslisten statt einer Rolle.
- Abhängigkeiten von anderen Rollen: alle Wolfsrollen, Dämonischer Wolf (Verfluchte), Spiegelwolf/Fenrir/Cerberus (kein Tod beim Lynch), Der Weise, Lehrling/Seelentauscher, Schattenhund/Albtraumwolf/Zeitwächter (Blockade), Doppelspion (zählt als Nicht-Wolf).
- Komplexität und Fehlerrisiko: M / mittel. Zufall muss seed-stabil sein, Auslöser hängt an allen Hinrichtungszweigen.
- Offene Entscheidungen:
  1. Eine Info pro Wolfs-Lynch oder eine pro Nacht nach mindestens einem Wolfs-Lynch?
  2. Darf der Kopfgeldjäger sich selbst unter den drei sehen?
  3. Aktiviert ein Rollenerbe/Tausch sofort?
  4. Aktiviert der Lynch eines verfluchten Dorfbewohners?
  5. Verfällt die Info, wenn nicht genug Ziele leben, oder bleibt sie erhalten?
- Relevante Testgruppen:
  - Normalfall: Tag 1 Werwolf gelyncht; Nacht 2 Schritt zeigt 3 Namen, genau einer Werwolf.
  - ungültiges Ziel: nicht relevant, weil der Spieler kein Ziel wählt; stattdessen: nur 1 Nicht-Wolf lebt → Meldung und Verbrauch laut Entscheidung.
  - tote Person: tote Spieler erscheinen nie in der Liste.
  - Selbstwahl: Liste enthält den Kopfgeldjäger nicht (nach Entscheidung A).
  - mehrere Kopien: zwei Kopfgeldjäger nach Wolfs-Lynch → je eigene Info oder gemeinsame laut Entscheidung.
  - Wiederbelebung: toter Kopfgeldjäger wiederbelebt nach Wolfs-Lynch → Info laut Entscheidung.
  - Rollenwechsel: Lehrling erbt Kopfgeldjäger ohne Wolfs-Lynch → inaktiv.
  - Save/Load: aktiv gespeichert, geladen → Info in der Nacht, gleiche Namen bei gleichem Seed.
  - Replay: identische Namensliste aus SeededRng.
  - SL-Korrektur: GmCorrection execute eines Wolfs → aktiviert wie Lynch.
  - Sichtbarkeit: Namen nur actor/gm, nicht öffentlich.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant, weil keine Tötung; Auslöser ist die Hinrichtung.
  - Siegprüfung: Wolfs-Lynch beendet das Spiel → kein Nachtschritt mehr.
  - beschädigter Spielstand: Aktivierungszähler negativ → Laden lehnt ab.
- Belegsicherheit: hoch. Nicht verifiziert: ob der Der-Weise-Zweig praktisch je einen Wolf trifft (nur bei verfluchtem Weisen).

---

### koenig
- DE-Name / EN-Name: König / King (`roles:181`)
- Aliase/Altnamen: keine Migration. Bilder `König.webp` / `King.webp` (`gh:833`, `roleCard.ts:69`). State-Schlüssel `once.KoenigUsed` (mit "oe"); `resetOnceForInheritedRole` löscht stattdessen `"KönigUsed"` (`core:341-342`, wirkungslos). i18n `kingLearns` (`i18n:193`, `i18n:522`). Namensnähe zu "König Lykaon" (Wolfsrolle, eigene ID).
- Legacy-ID: `"König"` (`roles:1`)
- Fraktion: `dorf`.
- Akte: Akt III (`akte.js:57`) und Akt IV (`akte.js:78`), einzige Rolle dieser Gruppe in zwei Akten.
- Nachtpriorität und Bedingungen: tier 4.4, nicht once (`roles:34`). Zeile jede Nacht, solange er lebt; Bedingung Tote > Lebende wird erst im Handler geprüft (still, ohne Meldung).
- Quelltextstellen:
  - `chunk:109-127 GRIMM_ABILITIES_ROLES["König"]` Abbruch ohne Meldung, wenn `KoenigUsed` oder Tote <= Lebende; Kandidaten = lebende Sitze mit `getFaction(role)==="dorf"` außer dem ersten König-Sitz (`seats.find`, auch tot); Zufallsauswahl (`chunk:123`); `KoenigUsed=true`; Anzeige Name + roher deutscher Rollenstring (`chunk:126`).
  - `night:234 onDayStart` setzt `KoenigUsed=false` bei jedem Tagesbeginn.
  - `ab:104` Apfel löscht `KoenigUsed` vor der Ausführung.
  - `gh:523` Reset bei neuer Runde.
- Text DE (wörtlich): "Sobald mehr Tote als Lebende existieren, lernt er in dieser Nacht einen Dorfbewohner (und dessen Rolle) kennen."
- Text EN (wörtlich): "When more players are dead than alive: learns one living villager's identity."
- DE/EN-Vergleich: NEIN. (1) Häufigkeit: DE "Sobald ... in dieser Nacht" legt ein einmaliges Ereignis in der Nacht des Umschlagens nahe; EN "When ..." kann "jedes Mal, wenn" bedeuten. (2) EN sagt ausdrücklich "living", DE nicht. (3) DE "einen Dorfbewohner (und dessen Rolle)" nennt Rolle ausdrücklich; EN "identity" ist unbestimmt (Name, Rolle oder beides). (4) Zeitbezug "in dieser Nacht" fehlt im EN.
- Weitere Texte: `role-abilities.js:19` identisch mit DE. 07 Q1 Zeile 36 fasst den Text als "einmal" zusammen.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht bei tier 4.4, sofern Tote > Lebende (strikt, `chunk:113`).
  2. Häufigkeit: einmal pro Nacht, weil `KoenigUsed` jeden Morgen zurückgesetzt wird (`night:234`). Solange die Bedingung gilt, jede Nacht eine neue Info.
  3. Ziel: automatisch zufällig (`Math.random`, `chunk:123`) aus lebenden Sitzen mit rollenbasierter Fraktion "dorf"; der König wählt nicht. Verwandeltes Wolfskind (Rolle bleibt "Wolfskind") und verfluchte Dorfbewohner gelten als Dorfbewohner und können gezeigt werden; Solo-Rollen und Doppelspion nie. Wiederholungen desselben Sitzes über Nächte möglich (keine Historie).
  4. Selbst: der erste König-Sitz ausgeschlossen; bei zwei Königen kann der zweite gezeigt werden.
  5. Sichtbarkeit: geheim, SL-Dialog; Rolle als deutscher Rohstring, auch in EN (`chunk:126` nutzt `chosen.role`, nicht `getRoleName`).
  6. Kein Feedback: Bei nicht erfüllter Bedingung oder schon genutzt passiert beim Klick nichts (kein `center`).
  7. Apfel: Handler nutzt kein `pick`; Apfel wird nicht verbraucht, löscht aber bei jedem Klick `KoenigUsed` (`ab:112`), dadurch beliebig viele Infos pro Nacht durch erneutes Klicken.
  8. Rollenwechsel: Erbe löscht falschen Schlüssel (`core:342`), praktisch egal wegen Tagesreset.
- React-Version: kein eigenes Verhalten (`roleCard.ts:69`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 51 "unklar", `chunk:109-127`, `night:234`, "jede Nacht (Code) oder einmal (Text)": bestätigt. Ergänzung: Ziel ist zufällig und rollenbasiert (Wolfskind nach Verwandlung zählt als Dorf), Apfel-Mehrfachnutzung, stummer Abbruch.
  - 07 Q1 Zeile 36: "Text: einmal; Code: jede Nacht, solange Tote > Lebende; Vorschlag: einmal pro Nacht, solange Bedingung gilt (Code)": Codebeschreibung bestätigt. Die Einordnung des Textes als "einmal" ist eine Interpretation des DE-Textes; EN ist offener.
  - DECISION-LOG: kein Eintrag. NIGHT-REPORT-abilities.md:117 (Info-Anzeige in React fehlt): betrifft die frühere Spiegelung; `center` nutzt `#overlay`, das `domMirror.ts:53-61` spiegelt. Die Aussage wirkt veraltet, zur Laufzeit nicht geprüft.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Häufigkeit | "Sobald ... in dieser Nacht" | "When ..." | jede Nacht (`night:234`) | wie Legacy | 04 unklar, 07 Q1 Vorschlag Code | einmal im Spiel | jede Nacht, solange Bedingung gilt | B ist in der Endphase sehr stark | Einsatzzähler vs. Nachtbedingung | 07-Vorschlag übernehmen oder A; Texte angleichen | Ja |
| Wer wird gezeigt | "einen Dorfbewohner" | "one living villager" | Zufall, rollenbasiert "dorf" | wie Legacy | nicht dokumentiert | SL/Zufall wählt echten Dorf-Angehörigen (Fraktion aktuell) | rollenbasiert (Legacy) | A verhindert Fehlinfo bei Wolfskind | `faction` aktuell statt Katalog | A, Zufall über SeededRng | Ja |
| Umfang der Info | "(und dessen Rolle)" | "identity" | Name + Rolle | wie Legacy | nicht dokumentiert | Name + Rolle | nur Name | gering | InfoRecord-Inhalt | DE-Formulierung auch im EN | Nein (Textkorrektur) |

- Bugs:
  - B-KOE-1 (echter Bug): Apfel-Mehrfachnutzung `ab:104,112` mit `chunk:110,124`. Tatsächlich: Mit Apfel kann der SL den König in derselben Nacht beliebig oft ausführen, Apfel bleibt. Erwartet: höchstens die laut Text vorgesehene(n) Info(s). Risiko: mittel. Test: Apfel an König, Tote > Lebende, zweimal ausführen; erwartet: zweiter Aufruf liefert nichts bzw. nur die eine Zusatzinfo, Apfel verbraucht.
  - B-KOE-2 (unklare Regel): Verwandeltes Wolfskind gilt als Dorfbewohner (`chunk:117` rollenbasiert). Risiko: mittel (falsche Info zugunsten der Wölfe). Test: Wolfskind verwandelt, einziger lebender "dorf"-Rollenträger außer König; erwartet laut Entscheidung: nicht zeigbar.
  - B-KOE-3 (technische Altlast): stummer Abbruch ohne Meldung (`chunk:110,113,121`), EN-Anzeige mit deutschem Rollennamen (`chunk:126`), falscher Reset-Schlüssel `core:341-342`. Risiko: niedrig. Test: Bedingung nicht erfüllt → Schritt entfällt mit Grund (StepDropped) statt stiller Klick.
- Legacy-Status: legacy-contradictory. Code (jede Nacht) und Text (DE einmalig "in dieser Nacht") widersprechen sich, 04/07 führen es bereits als offene Regel.
- Automationsvorschlag: automatic. Bedingung und Auswahl sind ohne Spielerentscheidung berechenbar (SeededRng), Ergebnis als InfoRecord.
- Mechanikfamilie primär + sekundär: Informationsrolle + Zufallsmechanik (sekundär Einmalfähigkeit, je nach Entscheidung).
- Benötigte vorhandene Godot-Systeme: StepQueue (bedingter Schritt, StepDropped), SeededRng, InfoRecord, Ereignis-Sichtbarkeit, StateCodec, Replay.
- Benötigte NEUE Systeme: bedingte Schrittverfügbarkeit nach Zählbedingung (Tote > Lebende), ggf. Einsatzzähler; InfoRecord-Variante "Person + Rolle".
- Abhängigkeiten von anderen Rollen: Wolfskind, Lehrling, Dämonischer Wolf (Verfluchte), Seelentauscher, Rotkäppchen (Apfel), Frankenstein/Kutscher (Wiederbelebung verändert Tote/Lebende).
- Komplexität und Fehlerrisiko: S / mittel. Einfache Berechnung, aber Fraktionsdefinition und Häufigkeit müssen entschieden sein.
- Offene Entscheidungen:
  1. Einmal im Spiel oder jede Nacht, solange Tote > Lebende?
  2. Wählt der Zufall, der SL oder der König selbst?
  3. Zählt die aktuelle Fraktion (verwandeltes Wolfskind = Wolf) oder die Startrolle?
  4. Zählt ein Unentschieden (Tote = Lebende)? Legacy: nein.
  5. Darf dieselbe Person mehrfach gezeigt werden?
- Relevante Testgruppen:
  - Normalfall: 12 Spieler, 7 tot → König-Schritt zeigt einen lebenden Dorf-Angehörigen mit Rolle.
  - ungültiges Ziel: nicht relevant, weil kein Ziel gewählt wird; stattdessen: kein lebender Dorf-Angehöriger außer König → Schritt entfällt mit Grund.
  - tote Person: Tote werden nie gezeigt.
  - Selbstwahl: König wird nie sich selbst gezeigt.
  - mehrere Kopien: zwei Könige → jeder eigener Schritt, keiner sieht sich selbst.
  - Wiederbelebung: Wiederbelebung macht Tote <= Lebende → Schritt entfällt.
  - Rollenwechsel: Lehrling erbt König nach Nutzung → Einsatz laut Entscheidung frisch oder verbraucht.
  - Save/Load: gleiche Info nach Laden (Seed).
  - Replay: identische Auswahl.
  - SL-Korrektur: GmCorrection revive während Nacht vor König-Schritt → Bedingung neu bewertet.
  - Sichtbarkeit: Info nur actor/gm.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant, weil keine Tötung; nur Zählung der Toten.
  - Siegprüfung: nicht relevant, weil keine Zustandsänderung außer Info.
  - beschädigter Spielstand: Einsatzzähler > erlaubt → Laden lehnt ab.
- Belegsicherheit: hoch.

---

### dr-victor-frankenstein
- DE-Name / EN-Name: Dr. Victor Frankenstein / Dr. Victor Frankenstein (`roles:182`, EN-Name identisch; zusätzlich `i18n:801`).
- Aliase/Altnamen: keine Migration. Bilder `Dr._Victor_Frankenstein.webp` in DE und EN (`gh:834`, `roleCard.ts:70`). Kurzform "Frankenstein" in Meldungen (`chunk:90`, `i18n:192` `frankensteinRevived`, `i18n:521`). State-Schlüssel `once.FrankensteinUsed`. Rollentags `["revive","dead-interaction","creates-wolf"]` (`roles:288`). Fest verdrahtet im Hinweistext `help:133,217` und im Fallback `night:31`.
- Legacy-ID: `"Dr. Victor Frankenstein"` (`roles:1`)
- Fraktion: `dorf`. Besonderheit: Tag `creates-wolf` (kann eine Wolfsrolle vergeben) und `revive` (aktiviert Totenkarten mit Wiederbelebungsbezug, s. u.).
- Akte: Akt II (`akte.js:36`)
- Nachtpriorität und Bedingungen: tier 3.6, nicht `once` (`roles:30`), aber eigene Sperre `night:61` (Zeile weg, sobald `FrankensteinUsed`). Zeile auch ohne Tote; der Handler kehrt dann still zurück (`chunk:33-36`). Lebender Frankenstein aktiviert zusätzlich den Hinweis "Tote halten diese Nacht die Augen geschlossen" (`night:29-39`), auch nach Verbrauch (Tag bleibt, solange er lebt).
- Quelltextstellen:
  - `chunk:31-103 GRIMM_ABILITIES_ROLES["Dr. Victor Frankenstein"]`: Sperre (außer `fromGhost`), Ja/Nein-Dialog (`chunk:38-52`, deutsche Texte, Laufzeitübersetzung `i18n:736,767,883,1058,1067`), `startMulti(... 1, x=>x.flags.dead ...)` (`chunk:54`), sofort `dead=false` und Teil-Reset von `meta` (`chunk:57-62`), dann Rollenliste = `ALL_ROLES` ohne alle an irgendeinem Sitz (auch tot) vergebenen Rollen (`chunk:64`), `<select>` mit rohen deutschen Namen (`chunk:70-77`), Knopf "Rolle vergeben" (`chunk:79-92`): Wächter-am-Tor-Prüfung (`core:41-56`), `FrankensteinUsed=true`, `save(); draw();`, Erfolgsmeldung per `center` und direkt danach `ov.style.display="none"` (`chunk:90-91`).
  - `ab:105` Apfel löscht `FrankensteinUsed` vor der Ausführung; `ab:117-118` Apfel-Wrapper für `startMulti`.
  - `core:357 resetOnceForInheritedRole` setzt `FrankensteinUsed=false` bei Erbe/Tausch.
  - `cards.js:573-622` Totenkarten mit `requiresAnyLivingRoleTag ["revive",...]`: `segen_08` "Zweites Leben" (`cards.js:62`), `wende_04` "Wiedergeburt" (`:326`), `wende_07` "Befreiung" (`:348`), `loki_10` "Phoenix" (`:450`) sind nur aktiv, solange eine Rolle mit diesen Tags lebt.
  - `gh:523` Reset bei neuer Runde.
- Text DE (wörtlich): "Kann einmalig einen Toten wiederbeleben und ihm eine neue Rolle geben."
- Text EN (wörtlich): "Once revives a dead player who receives a brand new role."
- DE/EN-Vergleich: JA mit Nuance. Häufigkeit (einmal), Ziel (ein Toter), Wirkung (neue Rolle) gleich. DE "Kann" macht die Nutzung ausdrücklich freiwillig, EN nicht ausdrücklich. "brand new role" könnte als "Rolle, die noch nicht im Spiel ist" gelesen werden (entspricht zufällig `chunk:64`), DE "neue Rolle" nur als "andere Rolle".
- Weitere Texte: `role-abilities.js:16` identisch. Totenkarten-Bezug über Tag `revive` (siehe oben), in keinem Kartentext namentlich.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht bei tier 3.6, bis zur Nutzung; freiwillig per Ja/Nein, "Nein" verbraucht nichts.
  2. Ziel: genau ein toter Sitz (auch ohne Rolle), keine Lebenden. Frankenstein selbst ist beim Handeln lebend (`ab:72,79`), Selbstwiederbelebung unmöglich.
  3. Reihenfolge (Kernproblem): Wiederbelebung (`dead=false`) passiert SOFORT nach der Auswahl (`chunk:57`), die Rolle erst nach "Rolle vergeben". Gibt es keine freie Rolle, bleibt der Sitz lebendig mit alter Rolle und Frankenstein unverbraucht (`chunk:64-68`). Der Dropdown-Schritt hat keinen Abbrechen-Knopf; wird das Overlay durch eine andere Meldung überschrieben, bleibt derselbe Teilzustand.
  4. Rollenwahl: frei durch den SL aus allen nicht vergebenen Rollen, inkl. Wolfs- und Solorollen; "Dorfbewohner" fehlt, sobald irgendein Sitz Dorfbewohner ist. Die bisherige Rolle des Toten ist nie wählbar (sie hängt ja noch am Sitz). Wolfsrolle → `flags.werewolf=true`, bei lebendem Wächter am Tor stattdessen Dorfbewohner (`core:41-56`).
  5. Zurückgesetzt: nur `deathProcessed`, `killedTonight`, `hunterShot`, `hunterQueued` (`chunk:59-62`). NICHT zurückgesetzt: alle anderen `flags` (verliebt, vergiftet, verzaubert, Puppe, Henker-Mal, Hass, Stimme entzogen) und `meta` (`loverId`, `rkLink`, `appleBuff`, `cursedWolfAura`, `lastKillCause`, `ritterRetaliated`, `parasiteHostId`). Folge: Ein wiederbelebter Loki-Liebender, dessen Partner tot ist, stirbt beim nächsten `postDeathHooks` erneut an LOVER_HEARTBREAK (`core:378-383`). Kutscher setzt dagegen alles zurück (`chunk:849-850`).
  6. Nach der Wiederbelebung wird weder `postDeathHooks` noch `rebuildOrder` aufgerufen (`chunk:88`); eine neue Rolle mit Nachtschritt erscheint erst beim nächsten Neuaufbau der Liste in der Reihenfolge. Die Frankenstein-Zeile bleibt bis dahin sichtbar.
  7. Sichtbarkeit: Die Erfolgsmeldung wird sofort wieder ausgeblendet (`chunk:90` zeigt, `chunk:91` versteckt), der SL sieht keine Bestätigung. Die Wiederbelebung ist öffentlich am Spielfeld sichtbar, die neue Rolle nicht.
  8. Mehrere Kopien: globales Flag `FrankensteinUsed`, eine Nutzung für alle Kopien zusammen.
  9. Zufall: keiner.
  10. Rollenwechsel: Erbe/Tausch zur Rolle setzt `FrankensteinUsed=false` (`core:357`), eine zweite Wiederbelebung wird möglich, auch wenn das Original sie schon genutzt hat.
  11. Apfel (Rotkäppchen): `ab:118` ruft nach der Toten-Auswahl sofort `runAb()` erneut auf; `FrankensteinUsed` ist noch nicht gesetzt, der Handler überschreibt das Overlay mit einem neuen Ja/Nein, der Rollen-Dropdown der ersten Wiederbelebung geht verloren. Ergebnis: erster Sitz lebt mit alter Rolle, zweiter erhält eine neue Rolle.
  12. `fromGhost`-Pfad (`chunk:31`, `state.ui.ghostCasting`, `state.context==="ghost"`): im aktuellen Code setzt keine Stelle `ghostCasting=true` (nur Lese- und Rücksetzstellen, `ui:341`), toter Code.
  13. Sieg: `save()` nach der Rollenvergabe löst `checkTeamWin` aus (`state:113`), eine vergebene Wolfsrolle kann sofort die Parität kippen.
- React-Version: kein eigenes Verhalten, aber Bedienfehler im Adapter: `domMirror.ts:53-61` spiegelt nur Titel, Text und Buttons, kein `<select>`; der Knopf "Rolle vergeben" übernimmt dann den ersten Eintrag des Dropdowns (erste freie Rolle in `ALL_ROLES`-Reihenfolge, meist "Loki"). `legacyAdapter.ts:419-420` erlaubt tote Sitze als Ziel über das Legacy-Prädikat.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 52 "widersprüchlich (Bug F9)", `chunk:31-103`; Kernaussage beschreibt das ZIEL-Verhalten ("erst dann Wiederbelebung atomar"), nicht das Legacy-Verhalten. Zeilen bestätigt.
  - 01 Zeile 34 (W05/W06 bestätigt, `chunk:70,81`, `domMirror.ts:57-59`) und F9 (`chunk:54-103`): bestätigt; die Zeile für `dead=false` ist `chunk:57`, nicht 70/81.
  - 01 Zeile 222 (Einmal-Flags bei Rollenwechsel inkonsistent): bestätigt für Frankenstein (Reset auf false).
  - 04 B-5 (Frankenstein einmal, `night:59-83`): bestätigt (`night:61`).
  - GRIMMHAIN-ANALYSE-UND-ROADMAP-2026-09-15.md W05/W06 (P0): bestätigt.
  - SPECIAL-ROLE-FLOW-REPORT.md:49-67 FK1: bestätigt; "alphabetisch erste verfügbare Rolle" ist ungenau, es ist die erste freie Rolle in `ALL_ROLES`-Reihenfolge (`chunk:64`, `roles:1` beginnt mit "Loki"). Beobachtung "Bestätigung erscheint nicht klar" erklärt sich durch `chunk:91`.
  - GRIMMHAIN_ANALYSE_2026-06-12.md:166 (Frankenstein filtert vergebene Rollen richtig): bestätigt.
  - 03 D5 und Zeile 254 (Prompt-Kette, erst letzte Antwort erzeugt Ereignisse): Ziel-Architektur, deckt W06 ab.
  - 07, DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Rollenpool | "neue Rolle" | "brand new role" | nur nicht vergebene Rollen, inkl. Wolf/Solo, ohne Dorfbewohner falls vergeben | Dropdown fehlt, erste Rolle | 04: "freie Rolle" | jede Rolle außer der bisherigen | nur nicht im Spiel befindliche Rollen | Wolfsrolle stärkt ggf. Wölfe (Tag `creates-wolf`) | Katalogfilter, `max_copies` | B mit ausdrücklich erlaubtem Dorfbewohner; Wolfsrollen nur nach Entscheidung | Ja |
| Zustand des Wiederbelebten | nicht geregelt | nicht geregelt | nur 4 meta-Felder zurückgesetzt, Liebe/Gift/Kette bleiben | wie Legacy | 03 RoleTransition "frische Einsätze" | vollständiger Neustart des Sitzes (wie Kutscher) | Bindungen bleiben | A verhindert Sofort-Tod durch Liebeskummer | Wiederbelebungsmodell mit Reset-Liste | A | Ja |
| Einmaligkeit bei Erbe | "einmalig" | "Once" | global, Erbe setzt zurück | wie Legacy | 01 Zeile 222 | einmal pro Person | einmal pro Rolle im Spiel | A erlaubt 2 Wiederbelebungen | `ability_uses` pro Person | A (Godot-Standard) | Ja |
| Totenkarten-Aktivierung nach Verbrauch | nicht geregelt | nicht geregelt | lebender Frankenstein hält Wiederbelebungs-Karten aktiv, auch nach Nutzung | wie Legacy | nicht dokumentiert | nur solange Wiederbelebung noch möglich | solange die Rolle lebt | gering bis mittel | Tag-Abfrage mit Verbrauchszustand | A | Ja |

- Bugs:
  - B-FRK-1 (echter Bug, W06): `chunk:57` vor `chunk:64-92`. Tatsächlich: Wiederbelebung vor Rollenwahl, ohne freie Rollen bleibt ein lebender Sitz mit alter Rolle und unverbrauchter Fähigkeit. Erwartet: atomar (Text "wiederbeleben und ... neue Rolle geben"). Risiko: hoch. Test: alle Rollen vergeben, Frankenstein wählt Toten; erwartet: keine Zustandsänderung, Meldung.
  - B-FRK-2 (echter Bug, W05/FK1): `domMirror.ts:53-61` ohne `<select>`. Tatsächlich: React-SL kann die Rolle nicht wählen, erste freie Rolle wird vergeben. Erwartet: bewusste Wahl. Risiko: hoch (P0 laut Analyse). Test: im React-Dialog Rolle "Doktor" wählen; erwartet: Sitz wird Doktor.
  - B-FRK-3 (echter Bug): `chunk:90-91` blendet die Erfolgsmeldung sofort aus. Risiko: niedrig bis mittel (SL ohne Bestätigung). Test: nach Vergabe ist eine Bestätigung sichtbar bzw. Ereignis gm-sichtbar.
  - B-FRK-4 (echter Bug, Interaktion): unvollständiger Reset `chunk:57-62` mit `core:378-383`. Tatsächlich: wiederbelebter Loki-Liebender mit totem Partner stirbt beim nächsten `postDeathHooks` erneut. Erwartet: Wiederbelebung wirkt. Risiko: mittel. Test: Liebespaar A/B, beide tot, A wiederbelebt, danach beliebiger Tod; erwartet: A lebt.
  - B-FRK-5 (echter Bug, nur mit Apfel): `ab:117-118` mit `chunk:31-103`. Tatsächlich: erster Wiederbelebter behält alte Rolle, zweiter erhält neue. Risiko: mittel. Test: Apfel an Frankenstein, zwei Tote; erwartet laut Entscheidung: zwei vollständige Wiederbelebungen oder Apfel wirkungslos.
  - B-FRK-6 (technische Altlast): toter `fromGhost`-Pfad (`chunk:31,87`), fehlendes `rebuildOrder` nach Wiederbelebung (`chunk:88`), rohe deutsche Rollennamen im Dropdown (`chunk:75`). Risiko: niedrig. Test: nach Wiederbelebung als Doktor erscheint der Doktor-Schritt in derselben Nacht laut Entscheidung (erscheint/erscheint nicht).
- Legacy-Status: legacy-broken. In der React-Oberfläche verfälscht der fehlende Dropdown die Kernfunktion (Rolle wird nicht gewählt), in `game.html` ist die Aktion nicht atomar (Teilzustand bei fehlenden Rollen) und der Apfel-Pfad verliert die Rollenvergabe. Der Normalfall in `game.html` funktioniert.
- Automationsvorschlag: assisted. Spieler entscheidet (ob, wen, welche Rolle), der Kern führt die Prompt-Kette und wendet atomar an.
- Mechanikfamilie primär + sekundär: Wiederbelebung + Rollenwechsel (sekundär Einmalfähigkeit, mehrstufige Nachtfähigkeit, Totenkarten-Interaktion).
- Benötigte vorhandene Godot-Systeme: PendingPrompt (Ja/Nein → Toter → Rolle → Bestätigung, abbrechbar), RoleTransition (Rolle, Fraktion, `counts_as_wolf`, frische Einsätze, Schnappschuss), StepQueue, WinRules/WinCandidate, GmCorrections (`revive`, `set_role` existieren), StateCodec, Replay, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Wiederbelebungsmodell im Kern (Reset-Liste für Marker/Bindungen, Totenkarten-Status), Totenkarten-Effektmodell (Tag-Aktivierung), Regel "Wächter am Tor blockiert neue Wölfe" als Prüfung in RoleTransition, Neuberechnung des Nachtplans nach Rollenwechsel in der Nacht (Nachtplan ist heute Snapshot, `godot/README.md` Wolfskind-Abschnitt).
- Abhängigkeiten von anderen Rollen: Wächter am Tor, Loki (Liebende), Rotkäppchen (Apfel/Kette), Sensenträger (`hunterShot`/`hunterQueued`), Ritter, Lehrling/Seelentauscher (Erbe), Kutscher (zweite Wiederbelebungsrolle), Totenkarten `segen_08`, `wende_04`, `wende_07`, `loki_10`, Hades (Lichter zählen Tode), alle Rollen als mögliche neue Rolle.
- Komplexität und Fehlerrisiko: L / hoch. Mehrstufiger Prompt, Rollenwechsel mit Fraktionswechsel, Siegprüfung, viele Seiteneffekte auf Bindungen.
- Offene Entscheidungen:
  1. Welche Rollen sind wählbar (nur nicht vergebene, auch Wolfs-/Solorollen, Dorfbewohner immer)?
  2. Welche Marker/Bindungen verliert der Wiederbelebte (Liebe, Gift, Kette, Fluch)?
  3. Einmal pro Person oder pro Rolle im Spiel (Erbe)?
  4. Handelt die neue Rolle schon in derselben Nacht?
  5. Wer erfährt die neue Rolle (nur SL und Wiederbelebter?), wird die Wiederbelebung öffentlich angesagt?
  6. Bleiben Wiederbelebungs-Totenkarten nach Verbrauch aktiv?
  7. Darf ein in dieser Nacht Gestorbener (erst am Morgen tot) Ziel sein? (Legacy: nein, Tode erst am Morgen.)
- Relevante Testgruppen:
  - Normalfall: Toter "Tina" wird als Doktor wiederbelebt, Frankenstein verbraucht, Zeile weg.
  - ungültiges Ziel: lebender Spieler gewählt → `invalid_target`.
  - tote Person: Ziel muss tot sein (positiver Fall).
  - Selbstwahl: nicht relevant, weil Frankenstein zum Handeln leben muss; Test: toter Frankenstein hat keinen Schritt.
  - mehrere Kopien: zwei Frankensteins → je eigener Einsatz (bei Entscheidung "pro Person").
  - Wiederbelebung: Wiederbelebter stirbt erneut → neue Totenkarte, keine doppelte Sensenträger-Reaktion laut Regel.
  - Rollenwechsel: neue Rolle Werwolf bei lebendem Wächter am Tor → Dorfbewohner.
  - Save/Load: zwischen Toten- und Rollenwahl speichern/laden → Prompt-Stufe erhalten, Toter noch tot.
  - Replay: identischer Endzustand.
  - SL-Korrektur: Abbruch nach Rollenwahl vor Bestätigung → fachlicher Hash unverändert.
  - Sichtbarkeit: neue Rolle nur gm/actor, Wiederbelebung öffentlich.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: Wiederbelebter Loki-Liebender mit totem Partner stirbt nicht erneut (nach Entscheidung A).
  - Siegprüfung: neue Wolfsrolle erzeugt Parität → Wolf-Siegkandidat.
  - beschädigter Spielstand: `FrankensteinUsed`-Äquivalent true, aber Schritt offen → Laden lehnt ab.
- Belegsicherheit: hoch für `game.html`-Pfad; React-Verhalten (erste Rolle) aus Code und SPECIAL-ROLE-FLOW-REPORT abgeleitet, nicht selbst ausgeführt.

---

### doktor
- DE-Name / EN-Name: Doktor / Doctor (`roles:193`)
- Aliase/Altnamen: keine Migration. Bilder `Doktor.webp` / `Doctor.webp` (`gh:835`, `roleCard.ts:74`). i18n `doctorSameTeam` / `doctorDifferentTeam` (`i18n:277-278`, `i18n:601-602`).
- Legacy-ID: `"Doktor"` (`roles:1`)
- Fraktion: `dorf`.
- Akte: Akt IV (`akte.js:76`)
- Nachtpriorität und Bedingungen: tier 5.0, nicht once (`roles:37`). Zeile jede Nacht, solange er lebt.
- Quelltextstellen:
  - `chunk:461-468 GRIMM_ABILITIES_ROLES["Doktor"]` `startMulti(..., 2, x=>!x.flags.dead, ...)`, Vergleich `abilityTeamOfSeat(a)===abilityTeamOfSeat(b)`, `flash` ✅/❌ und `center`.
  - `help:276-288 abilityTeamOfSeat` rein rollenbasiert über `getFaction` (wolf/solo/dorf), leere Rolle = dorf; der `isWolf`-Zweig (`help:285`) wird nie erreicht, weil `getFaction` immer existiert (`night:9`).
  - `ui:340 startMulti` verhindert doppelte Auswahl desselben Sitzes (`chosen.includes`).
  - `gh:388 flash` 1,5 s Symbol.
- Text DE (wörtlich): "Nimmt jede Nacht Blutproben von zwei Spielern und erfährt, ob sie demselben Team angehören."
- Text EN (wörtlich): "Each night takes blood samples from two players and learns whether they belong to the same team."
- DE/EN-Vergleich: JA. Zeitpunkt (jede Nacht), Anzahl (zwei), Ergebnis (gleiches Team ja/nein) identisch.
- Weitere Texte: `role-abilities.js:11` identisch. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht bei tier 5.0, SL-Klick.
  2. Ziele: zwei verschiedene lebende Sitze; Selbstwahl erlaubt; tote Sitze nicht wählbar.
  3. Ergebnis: "Gleiches Team" genau dann, wenn beide rollenbasierten Fraktionen gleich sind. Folgen: verwandeltes Wolfskind (Rolle "Wolfskind") und Lehrling vor Erbe gelten als Dorf; verfluchte Dorfbewohner (`cursedWolfAura`) als Dorf; zwei verschiedene Solo-Rollen (z. B. Rattenfänger und Pestbringerin) als "Gleiches Team"; Doppelspion als Solo (nicht Wolf). Seelentauscher-/Lehrling-Wechsel ändert die Rolle, wirkt also.
  4. Sichtbarkeit: geheim, SL-Anzeige.
  5. Mehrere Kopien: ein Handler pro Klick, Apfel nur bei alleinigem Doktor.
  6. Apfel: funktioniert (zweites Paar über `wrapMulti`, `ab:117-118`).
  7. Zufall: keiner. Blockaden `ab:94-99` greifen.
- React-Version: kein eigenes Verhalten (`roleCard.ts:74`). NIGHT-REPORT-abilities.md:40,120 (fehlendes "noch N"-Feedback im Mock) betrifft die UI, nicht die Regel.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 56 "verifiziert", `chunk:461-468`, `help:276-288`, "Prüft 2 Spieler auf gleiche Fraktion (nach Rolle, nicht nach Verwandlung)": bestätigt. Nicht erwähnt: zwei Solos = "gleiches Team", Selbstwahl erlaubt.
  - ROLE-FLOW-REPORT.md:29: gleiche Mehrfachauswahl wie Loki usw., bestätigt.
  - 07, DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Zwei Solo-Rollen | "demselben Team" | "the same team" | zwei Solos = gleiches Team | wie Legacy | nicht dokumentiert | Solos bilden kein Team (immer "verschieden", auch mit sich selbst) | "Solo" ist ein Team | A verhindert Fehlschluss | Vergleich über Siegpartei statt Fraktionskonstante | A | Ja |
| Verwandlung / Fluch | "Team" | "team" | Startrolle zählt (Wolfskind nach Verwandlung = Dorf) | wie Legacy | 04 dokumentiert es als Ist | aktuelle Fraktion | Katalogfraktion (Legacy) | A macht den Doktor zum Verwandlungs-Detektor | `faction` am Player (RoleTransition) statt Katalog | A (Godot hat `faction` am Player) | Ja |

- Bugs:
  - B-DOK-1 (unklare Regel): `help:276-288` Solos. Risiko: mittel. Test: Rattenfänger + Pestbringerin prüfen; erwartet laut Entscheidung "verschieden".
  - B-DOK-2 (unklare Regel): Verwandlung ignoriert. Risiko: mittel. Test: Wolfskind verwandelt, mit Werwolf prüfen; erwartet laut Entscheidung "gleiches Team".
  - B-DOK-3 (technische Altlast): unerreichbarer `isWolf`-Zweig `help:285-287`. Risiko: niedrig. Test: nicht nötig, Code entfällt.
- Legacy-Status: legacy-contradictory. Mechanik läuft zuverlässig, aber "demselben Team" wird bei Solos und Verwandlungen anders beantwortet, als der Text nahelegt.
- Automationsvorschlag: assisted. Spieler wählt zwei Personen (SL tippt), Ergebnis berechnet der Kern.
- Mechanikfamilie primär + sekundär: Informationsrolle + mehrstufige Nachtfähigkeit (zwei Ziele).
- Benötigte vorhandene Godot-Systeme: PendingPrompt (2 Ziele, `min_count=max_count=2`), StepQueue, InfoRecord (Wahrheit/ermittelt/gezeigt, Übersteuerung), Ereignis-Sichtbarkeit, StateCodec, Replay.
- Benötigte NEUE Systeme: Informationsregel "gleiches Team" (Siegpartei-Vergleich) in `information_rules.gd`; InfoRecord-Variante für Paarvergleich.
- Abhängigkeiten von anderen Rollen: Wolfskind, Lehrling, Seelentauscher, Dämonischer Wolf, alle Solo-Rollen, Doppelspion, Trugbilderwolf (Erscheinung vs. Fraktion), Rotkäppchen (Apfel).
- Komplexität und Fehlerrisiko: S / niedrig. Einfache Zweierwahl, nur die Teamdefinition ist zu klären.
- Offene Entscheidungen:
  1. Sind zwei Solo-Spieler "im selben Team"?
  2. Zählt die aktuelle Fraktion (nach Verwandlung/Erbe) oder die Startrolle?
  3. Zählt ein Trugbilderwolf mit seiner Scheinrolle oder als Wolf?
  4. Darf der Doktor sich selbst testen?
- Relevante Testgruppen:
  - Normalfall: Werwolf + Dorfbewohner → "verschieden"; zwei Dorfbewohner → "gleich".
  - ungültiges Ziel: dieselbe Person zweimal → `invalid_target_count` bzw. abgelehnt.
  - tote Person: toter Spieler → abgelehnt.
  - Selbstwahl: Doktor + Werwolf → erlaubt/abgelehnt laut Entscheidung.
  - mehrere Kopien: zwei Doktoren → zwei Schritte.
  - Wiederbelebung: nicht relevant, weil nur Lebende gewählt werden und keine Wiederbelebung ausgelöst wird.
  - Rollenwechsel: Lehrling erbt Wolfsrolle, danach Test gegen Werwolf → laut Entscheidung.
  - Save/Load: zwischen erster und zweiter Wahl speichern → Teilantwort bleibt.
  - Replay: gleiches Ergebnis.
  - SL-Korrektur: OverrideShownRole-Äquivalent für das gezeigte Ergebnis mit Grund.
  - Sichtbarkeit: Ergebnis nur actor/gm.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant, weil keine Tötung.
  - Siegprüfung: nicht relevant, weil keine Zustandsänderung.
  - beschädigter Spielstand: Prompt mit einem toten Teilziel → Laden lehnt ab.
- Belegsicherheit: hoch.

---

### faehrtenleser
- DE-Name / EN-Name: Fährtenleser / Tracker (`roles:194`)
- Aliase/Altnamen: keine Migration. Bilder `Fährtenleser.webp` / `Tracker.webp` (`gh:836`, `roleCard.ts:75`). Einmal-Schlüssel `once.Used["role_Fährtenleser"]` (`night:3-5`). i18n `trackerNearestWolf`, `trackerDirLeft`, `trackerDirRight`, `trackerNoWolf` (`i18n:279-282`, `i18n:603-606`), `alreadyUsed`.
- Legacy-ID: `"Fährtenleser"` (`roles:1`)
- Fraktion: `dorf`.
- Akte: Akt III (`akte.js:56`)
- Nachtpriorität und Bedingungen: tier 5.2, NICHT `once` (`roles:38`), daher Zeile jede Nacht, solange er lebt, auch nach Nutzung (dann Meldung "Schon genutzt").
- Quelltextstellen:
  - `chunk:469-489 GRIMM_ABILITIES_ROLES["Fährtenleser"]`: Abbruch bei `isOnceUsed`; erster lebender Fährtenleser `tr`; für jeden lebenden `isWolf`-Sitz `cw=(wi-ti+n)%n`, `ccw=(ti-wi+n)%n`, Richtung "links" wenn `cw<=ccw`, sonst "rechts", kleinster Abstand gewinnt; bei zwei verschiedenen Wölfen mit gleichem Abstand gewinnt der mit der niedrigeren Sitznummer (Durchlauf in Sitzreihenfolge, strikt `d<minD`), dessen Richtung dann angezeigt wird; `markOnceUsed`; Anzeige.
  - `night:3-5 usedKey/isOnceUsed/markOnceUsed` (unter `ghostCasting` wirkungslos).
  - `night:664-681` SL-Assistent ruft `onOrderClick` für jede Zeile auf.
  - `core:339-342 resetOnceForInheritedRole` löscht `once["FährtenleserUsed"]`, nicht den tatsächlichen Schlüssel.
- Text DE (wörtlich): "Wacht jede Nacht auf und darf einmal im Spiel erfahren, in welche Richtung der nächstliegende Wolf von ihm sitzt: links oder rechts."
- Text EN (wörtlich): "Wakes up every night and may once per game learn in which direction the nearest wolf sits: left or right."
- DE/EN-Vergleich: JA. Weckung (jede Nacht), Optionalität ("darf"/"may"), Häufigkeit (einmal im Spiel), Ergebnis (links/rechts) identisch.
- Weitere Texte: `role-abilities.js:17` identisch. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht bei tier 5.2 aufgerufen.
  2. Optionalität: keine Rückfrage; der erste Klick auf die Zeile verbraucht die Fähigkeit sofort und zeigt das Ergebnis. Der SL-Assistent klickt die Zeile automatisch ("Weiter"), der Einsatz wird also in Nacht 1 verbraucht, wenn der SL den Assistenten nutzt.
  3. Berechnung: Sitzposition = `id-1`; tote Sitze zählen im Abstand; Ziele = lebende `isWolf` (inkl. `cursedWolfAura`, verwandelte Sitze; ohne Doppelspion). Fenrir ab Stufe 3 wird NICHT übersprungen (anders als beim Ritter). "links" = höhere Sitznummer (im Uhrzeigersinn auf dem SL-Bildschirm, `field-pixi.js:544-548`, `ui:184-188`). Gleichstand: Steht EIN Wolf genau gegenüber (`cw==ccw`), heißt es "links" (`chunk:481`). Stehen ZWEI Wölfe gleich weit links und rechts, entscheidet die Sitznummer des Wolfs: Beispiel 8 Sitze, Fährtenleser Index 3, Wölfe Index 1 und 5 → Ergebnis "rechts" (Index 1 zuerst); Fährtenleser Index 0, Wölfe Index 2 und 6 → "links". Das Ergebnis hängt damit von der Sitznummerierung ab, nicht von einer Regel.
  4. Kein Wolf: Meldung "Kein Wolf gefunden", trotzdem verbraucht.
  5. Sichtbarkeit: geheim, SL-Dialog.
  6. Mehrere Kopien: globaler Einmal-Schlüssel und erster lebender Fährtenleser; eine Nutzung für alle.
  7. Zufall: keiner.
  8. Rollenwechsel: Erbe setzt den Verbrauch nicht zurück (falscher Schlüssel `core:342`); Seelentauscher/Lehrling übernehmen den verbrauchten Zustand.
  9. Blockade: bei Schattenhund/Albtraum/Der Weise/Zeitwächter nicht verbraucht (`ab:94-99`).
  10. Apfel: Handler nutzt kein `pick`, Apfel wirkungslos.
- React-Version: kein eigenes Verhalten (`roleCard.ts:75`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 57 "verifiziert", `chunk:469-489`, "Einmal: Richtung zum nächsten Wolf (links = höhere Sitznummer; Gleichstand = links)": "links = höhere Sitznummer" bestätigt. "Gleichstand = links" gilt nur für einen einzelnen genau gegenüber sitzenden Wolf; bei zwei gleich weit entfernten Wölfen hängt das Ergebnis von der Sitznummer ab (teilweise widerlegt). Nicht erwähnt: kein freiwilliges Auslassen, Verbrauch durch SL-Assistenten, Fenrir-Unterschied zum Ritter.
  - 01 Zeile 136 (Sitzposition = ID, Fährtenleser betroffen): bestätigt.
  - ROLE-FLOW-REPORT.md:33 ("Nächster Wolf: rechts"): Normalfall beobachtet.
  - 07, DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Freiwilligkeit | "darf einmal im Spiel" | "may once per game" | jeder Aufruf verbraucht, SL-Assistent ruft automatisch auf | wie Legacy | 04: "Einmal" | Spieler entscheidet jede Nacht Ja/Nein | automatisch beim ersten Aufruf | A ist deutlich stärker (Zeitpunkt wählbar) | Ja/Nein-Stufe im Prompt, Verbrauch erst bei Ja | A | Nein (Text eindeutig) |
| Richtungsdefinition | "links oder rechts" (aus seiner Sicht) | "left or right" | links = höhere Sitznummer | wie Legacy | 04 Zeile 57 | aus Sicht des Spielers am Tisch | aus Sicht des SL-Bildschirms | Fehlinfo bei falscher Deutung | Richtung relativ zu `seat_order` (Uhrzeigersinn) festlegen | am Tisch prüfen und festschreiben | Ja |
| Gleichstand | nicht geregelt | nicht geregelt | ein Wolf gegenüber: "links"; zwei gleich weite Wölfe: abhängig von Sitznummer | wie Legacy | 04: "Gleichstand = links" (unvollständig) | fest links | beide Richtungen nennen / SL wählt | gering | Regel im Rechner | entscheiden | Ja |
| Fenrir Stufe 3 | nicht geregelt | nicht geregelt | zählt als Wolf (Ritter nicht) | wie Legacy | nicht dokumentiert | gleiche Wolfsdefinition wie Ritter | unterschiedlich | gering | eine gemeinsame Zielfunktion | angleichen | Ja |

- Bugs:
  - B-FTL-1 (echter Bug): `chunk:470,485` mit `night:664-673`. Tatsächlich: Einsatz wird ohne Entscheidung verbraucht, mit SL-Assistent automatisch in der ersten Nacht. Erwartet: "darf einmal" (freiwillig). Risiko: mittel. Test: Nacht 1 Assistent läuft durch, Fährtenleser verzichtet; erwartet: Einsatz in Nacht 2 noch verfügbar.
  - B-FTL-2 (unklare Regel): Richtung "links" = höhere Sitznummer, Ritter-Gleichstand bevorzugt die niedrigere (`core:423-425`). Risiko: mittel. Test: Wolf auf beiden Seiten gleich weit; erwartet: dokumentierte Richtung für beide Rollen konsistent.
  - B-FTL-4 (echter Bug): Gleichstand zweier Wölfe `chunk:475-484` (Durchlauf in Indexreihenfolge, `d<minD`). Tatsächlich: Richtung hängt davon ab, welcher Wolf die niedrigere Sitznummer hat, nicht von einer festen Regel (Beispiele oben). Erwartet: deterministische, dokumentierte Regel (z. B. immer links oder "beide Seiten"). Risiko: niedrig bis mittel. Test: Fährtenleser Index 3, Wölfe Index 1 und 5; und Fährtenleser Index 0, Wölfe Index 2 und 6; erwartet: gleiche Regelanwendung in beiden Fällen.
  - B-FTL-3 (technische Altlast): Erbe setzt Verbrauch nicht zurück (`core:341-342`), bei Frankenstein/Kopfgeldjäger aber schon; inkonsistent. Risiko: niedrig. Test: Lehrling erbt verbrauchten Fährtenleser; erwartet laut Entscheidung (pro Person frisch).
- Legacy-Status: legacy-contradictory. Die Richtungsberechnung ist korrekt umgesetzt, aber die freiwillige Einmalnutzung ("darf") ist nicht abgebildet und der Assistent verbraucht sie automatisch.
- Automationsvorschlag: assisted. Spieler entscheidet ob; Richtung berechnet der Kern.
- Mechanikfamilie primär + sekundär: Informationsrolle + Sitzpositionsmechanik (sekundär Einmalfähigkeit).
- Benötigte vorhandene Godot-Systeme: PendingPrompt (Ja/Nein, abbrechbar), StepQueue, InfoRecord, `ability_uses`, StateCodec, Replay, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Sitznachbarschaft (Abstand und Richtung über `GameState.seat_order`), InfoRecord-Variante "Richtung".
- Abhängigkeiten von anderen Rollen: alle Wolfsrollen, Fenrir, Dämonischer Wolf (Verfluchte), Wolfskind/Lehrling (Verwandlung), Doppelspion, Ritter (gemeinsame Richtungsdefinition), Blockaderollen.
- Komplexität und Fehlerrisiko: S / mittel. Berechnung einfach, Richtungsdefinition am Tisch fehleranfällig.
- Offene Entscheidungen:
  1. "Links" aus Sicht des Spielers oder des SL-Bildschirms, und entspricht der Uhrzeigersinn der App dem Tisch?
  2. Gleichstand: fest eine Richtung oder beide nennen?
  3. Zählen tote Sitze im Abstand mit (Legacy: ja)?
  4. Wolfsdefinition: verfluchte Dorfbewohner, Fenrir Stufe 3?
  5. Einsatz pro Person (frisch bei Erbe) oder pro Rolle?
- Relevante Testgruppen:
  - Normalfall: 8 Sitze, Fährtenleser Sitz 1, Wolf Sitz 3 → "links" (bei Uhrzeigersinn-Definition).
  - ungültiges Ziel: nicht relevant, weil kein Ziel gewählt wird.
  - tote Person: toter Wolf näher als lebender → Richtung zum lebenden.
  - Selbstwahl: nicht relevant; Test: verfluchter Fährtenleser zählt sich nicht selbst (`cw===0`).
  - mehrere Kopien: zwei Fährtenleser → je eigener Einsatz (bei "pro Person").
  - Wiederbelebung: wiederbelebter Fährtenleser → Einsatz laut Entscheidung.
  - Rollenwechsel: Lehrling erbt unverbrauchten Fährtenleser → Einsatz verfügbar.
  - Save/Load: Nein in Nacht 1, speichern/laden → Einsatz verfügbar.
  - Replay: gleiche Richtung.
  - SL-Korrektur: Einsatz per Korrektur zurückgeben.
  - Sichtbarkeit: Richtung nur actor/gm.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant, weil keine Tötung.
  - Siegprüfung: nicht relevant, weil keine Zustandsänderung.
  - beschädigter Spielstand: `seat_order` ohne Fährtenleser → Laden lehnt ab.
- Belegsicherheit: hoch für Berechnung; die Zuordnung Bildschirm-Uhrzeigersinn zu "links aus Spielersicht" ist abgeleitet (Winkel `field-pixi.js:544-548`), nicht am Tisch geprüft.

---

### waldlaeufer
- DE-Name / EN-Name: Waldläufer / Ranger (`roles:195`)
- Aliase/Altnamen: keine Migration. Bilder `Waldläufer.webp` / `Ranger.webp` (`gh:836`, `roleCard.ts:76`). i18n `rangerWolves` (`i18n:232` "Lebende Werwölfe (Zählung): {n}", `i18n:561`).
- Legacy-ID: `"Waldläufer"` (`roles:1`)
- Fraktion: `dorf`.
- Akte: Akt IV (`akte.js:77`)
- Nachtpriorität und Bedingungen: tier 5.4, nicht once (`roles:39`). Zeile jede Nacht, solange er lebt.
- Quelltextstellen:
  - `chunk:490-493 GRIMM_ABILITIES_ROLES["Waldläufer"]` zählt lebende `isWolf`-Sitze, Anzeige per `center`.
- Text DE (wörtlich): "Erfährt, wie viele lebende Werwölfe im Spiel sind."
- Text EN (wörtlich): "Learns how many living werewolves are in the game."
- DE/EN-Vergleich: JA. Beide ohne Zeit- und Häufigkeitsangabe, Ergebnis Anzahl lebender Werwölfe.
- Weitere Texte: `role-abilities.js:40` identisch. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt/Häufigkeit: jede Nacht bei tier 5.4 (nach Rudel, Kopfgeldjäger, König, Doktor, Fährtenleser), unbegrenzt, auch mehrfach pro Nacht per erneutem Klick.
  2. Zählung: lebende `isWolf` (inkl. verfluchter Dorfbewohner, verwandelter Sitze; ohne Doppelspion, Manipulator, Parasit, Grabräuber, Todesprediger). Siegreicher Wolf zählt 1 (nicht 2 wie in der Parität `core:26`). Fenrir zählt immer. Tode dieser Nacht sind noch nicht eingetreten (Auflösung am Morgen), Nachtopfer zählen als lebend; sofortige Nachttode (Waldhexengift, Hades vor tier 5.4) sind schon abgezogen.
  3. Kein Ziel, kein Verbrauch, kein Zufall.
  4. Sichtbarkeit: geheim, SL-Dialog.
  5. Mehrere Kopien: ein Aufruf pro Klick, gleiche Zahl.
  6. Apfel: wirkungslos, unverbraucht.
- React-Version: kein eigenes Verhalten (`roleCard.ts:76`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 58 "verifiziert", `chunk:490-493`, "Erfährt Anzahl lebender Wölfe": bestätigt. Präzisierung: Häufigkeit jede Nacht; Zählung hängt an `isWolf` (Q1 Dämonischer Wolf).
  - 07, DECISION-LOG: kein Eintrag. NIGHT-REPORT-abilities.md:54 "Info (Anzahl Wölfe)": bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Häufigkeit | nicht genannt | nicht genannt | jede Nacht | wie Legacy | 04 ohne Angabe | jede Nacht | einmal (z. B. Nacht 1) | jede Nacht ist stark in Akt IV | Schritt jede Nacht vs. Einmal-Einsatz | entscheiden und in Text aufnehmen | Ja |
| Verfluchte zählen | "Werwölfe" | "werewolves" | `cursedWolfAura` zählt | wie Legacy | Q1 Dämonischer Wolf | nur `counts_as_wolf` | auch Erscheinung | hängt an Q1 | Zählung über `counts_as_wolf` | nach Q1 | Ja (über Q1) |

- Bugs:
  - B-WLF-1 (technische Altlast): beliebig viele Aufrufe pro Nacht (`chunk:490-493`, kein Verbrauch). Risiko: niedrig (liefert dieselbe Zahl, außer nach sofortigen Toden). Test: Schritt ist pro Nacht genau einmal ausführbar.
- Legacy-Status: legacy-verified. Code setzt den Text direkt um; offen sind nur die im Text fehlende Häufigkeit und die globale Wolf-Definition.
- Automationsvorschlag: automatic. Keine Eingabe, reine Zählung, Ergebnis als InfoRecord.
- Mechanikfamilie primär + sekundär: Informationsrolle + passive Dorfrolle (keine Wahl).
- Benötigte vorhandene Godot-Systeme: StepQueue, InfoRecord, Ereignis-Sichtbarkeit, StateCodec, Replay.
- Benötigte NEUE Systeme: InfoRecord-Variante "Anzahl" (sonst keine).
- Abhängigkeiten von anderen Rollen: alle Wolfsrollen, Dämonischer Wolf, Wolfskind/Lehrling, Siegreicher Wolf (Zählweise), Doppelspion, Waldhexe/Hades (sofortige Nachttode vor dem Schritt).
- Komplexität und Fehlerrisiko: S / niedrig.
- Offene Entscheidungen:
  1. Jede Nacht oder einmal?
  2. Zählen Verfluchte und verwandelte Sitze?
  3. Zählt der Siegreiche Wolf einfach (Legacy) oder doppelt?
  4. Zählen Nachtopfer, die erst am Morgen sterben, noch als lebend (Legacy: ja)?
- Relevante Testgruppen:
  - Normalfall: 2 lebende Werwölfe → Anzeige 2.
  - ungültiges Ziel: nicht relevant, weil kein Ziel.
  - tote Person: ein Werwolf tot → Anzeige 1.
  - Selbstwahl: nicht relevant, weil kein Ziel.
  - mehrere Kopien: zwei Waldläufer → gleiche Zahl, je eigener InfoRecord.
  - Wiederbelebung: Frankenstein gibt Wolfsrolle → nächste Zählung +1.
  - Rollenwechsel: Wolfskind verwandelt → Zählung laut Entscheidung.
  - Save/Load: Zahl nach Laden identisch.
  - Replay: identisch.
  - SL-Korrektur: Override des gezeigten Werts mit Grund.
  - Sichtbarkeit: nur actor/gm.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant, weil keine Tötung.
  - Siegprüfung: nicht relevant, weil keine Zustandsänderung.
  - beschädigter Spielstand: nicht relevant, weil kein rollenspezifischer Zustand gespeichert wird (nur InfoRecord, der allgemein geprüft wird).
- Belegsicherheit: hoch.

---

## Gruppenübergreifende Beobachtungen

1. Zwei widersprüchliche Richtungsdefinitionen: Der Fährtenleser nennt die höhere Sitznummer "links" (`chunk:478-483`), der Ritter-Zielfinder prüft bei Gleichstand zuerst `L` = niedrigere Sitznummer (`core:423-425`). 04 beschreibt beides als "links" (Zeile 47 "links vor rechts", Zeile 57 "links = höhere Sitznummer"); das ist inhaltlich gegensätzlich. Sitzreihenfolge im Bild ist im Uhrzeigersinn ab oben (`field-pixi.js:544-548`, `ui:184-188`); Godot hat `seat_order` im Uhrzeigersinn (`game_state.gd:22`). Eine gemeinsame Funktion "Nachbarschaft/Richtung" sollte für Ritter, Fährtenleser (und laut 01 Zeile 136 Wahnsinniger Kutscher, Feuerteufel, Detektiv, Blutwolf, Nachtwächter) einmal definiert werden.
2. Wolf-Definition ist uneinheitlich: `isWolf` (Ritter, Fährtenleser, Waldläufer, Kopfgeldjäger, Rotkäppchen-Zielfilter) enthält `cursedWolfAura`; Doktor und König nutzen die rollenbasierte Fraktion (`getFaction`) und ignorieren Verwandlung und Fluch; der Ritter überspringt Fenrir Stufe 3, der Fährtenleser nicht. Alle Entscheidungen hängen an 07 Q1 (Dämonischer Wolf) und am Godot-Modell `counts_as_wolf`/`faction`/`appears_as`.
3. Rotkäppchen-Apfel betrifft die ganze Gruppe: wirksam nur bei `pick`/`startMulti` (Doktor, Frankenstein, Rotkäppchen selbst nicht), wirkungslos und unverbraucht bei König, Kopfgeldjäger, Fährtenleser, Waldläufer; beim König ermöglicht er Mehrfachnutzung (`ab:104,112`), bei Frankenstein zerstört er die erste Rollenvergabe (`ab:117-118`).
4. Neue Runde (`gh:512-518 clearRolesNewRound`) übernimmt Seat-`meta` ungefiltert: betrifft Ritter (`ritterRetaliated`), Rotkäppchen (`rkLink`, `appleBuff`) und darüber hinaus `loverId`, `deathProcessed`, `lastKillCause`. Bisher in keiner Doku erfasst.
5. Einmal-Nutzung bei Rollenwechsel inkonsistent (bestätigt 01 Zeile 222): Frankenstein wird zurückgesetzt (`core:357`), Kopfgeldjäger sogar sofort aktiviert (`core:354`), Fährtenleser und König nicht (falsche Schlüssel `core:341-342`). Godot-Regel "frische Einsätze pro Person" in RoleTransition löst das, braucht aber eine Produktentscheidung je Rolle.
6. Stille Handler ohne Rückmeldung: König (`chunk:110,113,121`) und Frankenstein ohne Tote (`chunk:33-36`) kehren ohne Meldung zurück; Frankenstein blendet seine Erfolgsmeldung sofort aus (`chunk:90-91`). In Godot als `StepDropped` mit Grund bzw. gm-Ereignis abbilden.
7. SL-Assistent (`night:664-673`) führt jede Zeile ohne Rückfrage aus; betrifft alle optionalen Einmalfähigkeiten (hier Fährtenleser, Frankenstein fragt immerhin Ja/Nein).
8. Zufall ohne Seed: Kopfgeldjäger (`chunk:16,19,22`) und König (`chunk:123`) nutzen `Math.random`, Kopfgeldjäger zusätzlich eine verzerrte Mischung. In Godot über SeededRng; Replay-Tests nötig. Ritter, Rotkäppchen, Frankenstein, Doktor, Fährtenleser, Waldläufer sind zufallsfrei.
9. Keine eigene Logik in der React-Version für diese 8 Rollen (nur `roleCard.ts` und Adapter). Einziger React-spezifischer Fehler: fehlende `<select>`-Spiegelung (Frankenstein). NIGHT-REPORT-summary.md:48 ("Toasts `center` werden nicht gespiegelt") wirkt veraltet, weil `center` in `#overlay` schreibt (`ui:43-53`), das `domMirror.ts:53-61` spiegelt; zur Laufzeit nicht geprüft.
10. Korrekturen an bestehender Doku:
    - 04 Zeile 48 (Rotkäppchen) "Apfel: Partner nutzt Fähigkeit doppelt" ist zu pauschal; B-12 ist korrekt.
    - 04 Zeile 50 (Kopfgeldjäger) "Nach jedem Wolfs-Lynch" ist ungenau (bool) und verschweigt Selbstanzeige und Aktivierung durch Erbe; Status "verifiziert" ist für den Kern haltbar.
    - 04 Zeile 56 (Doktor) und 57 (Fährtenleser) "verifiziert" übersehen Solo-Gleichheit bzw. fehlende Freiwilligkeit; hier als legacy-contradictory eingestuft. 04 Zeile 57 "Gleichstand = links" stimmt nur für einen einzelnen gegenüber sitzenden Wolf, nicht für zwei gleich weit entfernte Wölfe.
    - 04 Zeile 47 (Ritter) "verifiziert" übersieht, dass der Text jeden Nachttod meint; hier legacy-contradictory.
    - 01 Zeile 34 verweist für `dead=false` auf `chunk:70,81`; korrekt ist `chunk:57`.
    - SPECIAL-ROLE-FLOW-REPORT.md:59: nicht "alphabetisch", sondern `ALL_ROLES`-Reihenfolge.
    - GRIMMHAIN_ANALYSE_2026-06-12.md L2 (Ritter doppelt definiert, `RITTER_RETALIATE`) ist erledigt; Kommentar `gh:483` nennt noch den falschen Ort.
11. Status-Übersicht dieser Gruppe: ritter legacy-contradictory, rotkaeppchen legacy-contradictory, kopfgeldjaeger legacy-verified, koenig legacy-contradictory, dr-victor-frankenstein legacy-broken, doktor legacy-contradictory, faehrtenleser legacy-contradictory, waldlaeufer legacy-verified.
12. Neue Godot-Systeme, die mehrere Rollen dieser Gruppe brauchen: Sitznachbarschaft/Richtung (Ritter, Fährtenleser), InfoRecord-Varianten für Namensliste/Paarvergleich/Richtung/Anzahl (Kopfgeldjäger, Doktor, Fährtenleser, Waldläufer, König), Bindungsmodell + Apfel-Marker (Rotkäppchen), Wiederbelebungsmodell (Frankenstein), bedingte Schrittverfügbarkeit (Kopfgeldjäger, König), Ursachen-Attribut für Todesreaktionen (Ritter).
