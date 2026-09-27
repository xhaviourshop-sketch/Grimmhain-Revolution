<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G2 Wölfe B: Legacy-Rollenprüfung

Geprüfte Rollen: schwarze-witwe, daemonischer-wolf, schattenhund, besessener-wolf, fenrir, blutwolf, albtraumwolf, cerberus.
Methode: reine Codelesung (nichts ausgeführt). Pfadkürzel wie im Auftrag: `roles`, `chunk`, `ab`, `help`, `night`, `core` (= js/ui/core.js), `ui` (= js/ui/ui.js), `state`, `gh` (= game.html). Zeilen beziehen sich auf den Stand des Arbeitsbaums am 2026-09-26.

Gemeinsame Grundlagen, die für alle acht Rollen gelten und unten nicht jedes Mal wiederholt werden:

- Wolfszugehörigkeit: `roles:391-396` `WOLF_ROLES_SET` enthält alle acht Rollen. `roles:405-409` `getRoleFaction` liefert daher `"wolf"`. `core:8-19` `isWolf` = Set ODER `flags.werewolf` ODER `meta.cursedWolfAura`. Lokale Duplikate derselben 19-Rollen-Liste in `gh:888` und `gh:1018` (Setup-Chipgruppen), inhaltlich identisch.
- Keine der acht Rollen steht in `state:16-45` `migrateLegacyRoleIds` (keine Altnamen-Migration).
- Synthetische Werwolf-Zeile: `night:50-55` `WOLF_KILL_ROLES` enthält Dämonischer Wolf, Besessener Wolf, Fenrir, Blutwolf, Albtraumwolf, Cerberus, aber NICHT Schwarze Witwe und NICHT Schattenhund (siehe Bug F2 in 01).
- Rudel-Akteure bei fehlendem "Werwolf": `ab:73-77` nimmt alle lebenden `WOLF_ROLES_SET`-Rollen bzw. `flags.werewolf`, ausdrücklich nicht `cursedWolfAura`.
- Blockaden gelten nur für Nicht-Wolfsrollen (`ab:93-96` `isWolfRole=WOLF_ROLES_SET.has(role)`), also nie für diese acht Rollen selbst, außer Albtraumwolf-Blockade (`ab:97-99`), die aber per Zielfilter keine Wölfe treffen kann.
- Pick-Abbruch: `ui:325` `startPick` übergibt kein `onCancel` an `showPickBar`; `ui:315` "Abbrechen" beendet nur den Pick. Jede Callback-Kette, die in einem `startPick` weiterläuft, bleibt bei Abbruch stehen. Relevant für Dämonischer Wolf und Besessener Wolf.
- `window.t` liefert bei fehlendem Schlüssel den Schlüssel selbst zurück (`js/core/i18n.js:652-655`), der `||`-Fallback greift dann nicht.

---

### schwarze-witwe
- DE-Name / EN-Name: Schwarze Witwe / Black Widow (`roles:192` `ROLE_NAMES_EN`).
- Aliase/Altnamen (state.js migrateLegacyRoleIds, i18n, Bilder, sonstige Schreibweisen im Code): keine Migration. Bild DE `assets/cards/de/Schwarze_Witwe.webp` (vorhanden), EN `assets/cards/en/Black_Widow.webp` (vorhanden, Mapping `gh:821`, `app/src/roleCard.ts:39`). Todesursache `BLACK_WIDOW` (`night:196`), Label "🕷️ Schwarze Witwe" (`ui:404`). State-Schlüssel `state.once.WidowMorningKills`. i18n-Schlüssel `blackWidowLokiRequired`, `blackWidowNoPair`, `blackWidowBothDie` (`js/core/i18n.js:274-276` DE, `598-600` EN).
- Legacy-ID (String in ALL_ROLES): "Schwarze Witwe" (`roles:1`).
- Fraktion (getRoleFaction) und weitere Fraktionsbesonderheiten im Code: wolf. Nicht in `WOLF_KILL_ROLES` (`night:50`): lebt als einzige Wolfsrolle nur die Witwe (ohne Werwolf-Rolle), entsteht keine Rudel-Tötungszeile.
- Akte (akte.js): Akt IV (`js/core/akte.js:81`), dort ist Loki ebenfalls enthalten (`js/core/akte.js:79`). Custom: alle.
- Nachtpriorität (ORDER_BASE tier, once) und Bedingungen für den Nachtschritt (night.js): tier 2.8, kein once (`roles:24`). Schritt erscheint jede Nacht (auch Nacht 1), solange eine Witwe lebt (`night:56-58`, `night:86-93` `hasAliveRole`). Keine weitere Bedingung in `rebuildOrder`; die Loki-Prüfung passiert erst im Handler.
- Quelltextstellen (Liste pfad:zeilen Symbol – was dort passiert):
  - `roles:24` ORDER_BASE: tier 2.8.
  - `roles:118` / `roles:268`: Text DE / EN.
  - `chunk:449-460` Handler "Schwarze Witwe": Loki-Prüfung, Pick, Paarsuche, schreibt `state.once.WidowMorningKills`.
  - `night:192-199` `onDayStart`: vor allen anderen Morgenauflösungen `applyKill(s,"BLACK_WIDOW")` für beide IDs, dann `postDeathHooks()`.
  - `core:430-450` `applyRitterRetaliationFromNight`: `BLACK_WIDOW` zählt als Nachtursache für die Ritter-Vergeltung.
  - `setup.html:1111-1117` `distributeAndGo` und `gh:1194-1201` `setupFertig.onclick`: Verteilung wird blockiert, wenn Witwe ohne Loki gewählt ist.
  - `chunk:137-138` Loki: setzt `flags.inlove`/`meta.loverId` bzw. `flags.rival`/`meta.rivalId`.
  - `gh:512-528` `clearRolesNewRound`: setzt `meta.rivalId` zurück, aber nicht `meta.loverId` (Zeile 517); gleiche Kopie in `app/public/legacy-bridge.js:39`.
  - `js/core/role-abilities.js:57`: Fähigkeitstext identisch zu DE.
- Text DE (wörtlich): "Loki wird automatisch gewählt. Wähle jede Nacht einen Spieler. Findest du einen Verliebten oder Verhassten, sterben beide am folgenden Tag."
- Text EN (wörtlich): "Loki is chosen automatically. Each night, choose a player. If you find a lover or rival, both die."
- DE/EN-Vergleich (semantisch gleich JA/NEIN + konkrete Unterschiede): NEIN. EN fehlt der Zeitpunkt "am folgenden Tag" (EN lässt offen, ob sofort oder später gestorben wird). Übrige Teile (automatische Loki-Wahl, jede Nacht ein Spieler, Verliebter oder Verhasster, beide sterben) gleich.
- Weitere Texte (role-abilities.js, i18n.js, Totenkarten-Bezug), falls abweichend: `js/core/role-abilities.js:57` identisch DE. i18n `blackWidowBothDie` DE "sterben am nächsten Tag", EN "die the next day" (EN-Laufzeitmeldung enthält den Zeitpunkt, der EN-Rollentext nicht). `blackWidowLokiRequired`: "Loki muss im Spiel sein." Kein Totenkarten-Bezug (grep in `js/core/cards.js` ohne Treffer).
- Legacy-Codeverhalten:
  1. Setup: Witwe ohne Loki im Pool blockiert die Verteilung mit Warnung (`setup.html:1111-1117`, `gh:1197-1201`). Loki wird NICHT automatisch hinzugefügt oder gewählt.
  2. Zeitpunkt: Nachtschritt tier 2.8, jede Nacht inklusive Nacht 1 (Loki handelt in Nacht 1 bei tier 0.1, Paare existieren also ab Nacht 1).
  3. Vorbedingung im Handler: `seats.some(s=>s.role==="Loki")` (`chunk:450`), Loki darf tot sein; hat der Loki-Sitz seine Rolle gewechselt, bricht der Handler ab, obwohl Paare existieren.
  4. Ziel: ein lebender Spieler (`chunk:459` Filter `!x.flags.dead`), Selbstwahl erlaubt, Wölfe erlaubt.
  5. Paarsuche (`chunk:452-454`): zuerst Liebende (`meta.loverId` oder `flags.inlove`), sonst Rivalen (`meta.rivalId` oder `flags.rival`). Partner muss leben. Ist das Ziel verliebt, aber der Partner tot, wird der Rivalen-Zweig nicht geprüft (else-if).
  6. Kein Paar: Meldung `blackWidowNoPair`, nichts gespeichert; ein früher in derselben Nacht gespeichertes Paar bleibt stehen.
  7. Paar gefunden: `state.once.WidowMorningKills=[ziel,partner]` (überschreibt; mehrere Klicks oder mehrere Witwen: letzte Wahl gilt, nur ein Paar pro Nacht). Meldung an SL `blackWidowBothDie` (geheim, nur SL-Overlay).
  8. Wirkung: in `onDayStart` als allererste Todesauflösung (`night:192-199`), vor Zeitwächter-Einfrieren (`night:323-331`), vor Märtyrerin, Voodoo, Albtraum-Filter und Schutzprüfung. `applyKill(...,"BLACK_WIDOW")` direkt: Schutzengel/Dorfwache wirken nicht (die greifen nur im Werwolf-Handler `chunk:162`). Innerhalb `applyKill` greifen weiter: Parasit-Immunität, Rudelvater-Erstrettung (Ursache nicht in dessen Ausnahmeliste, `core:111-117`), Schattenwanderer-Umlenkung, Nekromant-Schild, Kartenschlucker-Schild, Hades-Barriere.
  9. Todesursache `BLACK_WIDOW`, öffentlich über Tod-Popup/Protokoll. Ritter, der so stirbt, vergilt (`core:431`).
  10. Mehrere Witwen: Handler rollengenerisch, gemeinsames Einzelfeld `WidowMorningKills`.
  11. Zufall: keiner.
  12. Wiederbelebung/Rollenwechsel: keine Sonderbehandlung. Nach `clearRolesNewRound` bleibt `meta.loverId` aus der Vorrunde stehen (`gh:517`), die Witwe erkennt dann ein Phantompaar (siehe Bugs). `WidowMorningKills` wird von `clearRolesNewRound` ebenfalls nicht geleert.
  13. Sieg: keine eigene Bedingung; zählt als Wolf in `checkWinConditions`/`checkTeamWin` (`core:218-337`).
- React-Version: kein eigenes Verhalten. Nur Bildzuordnung `app/src/roleCard.ts:39`; `app/public/legacy-bridge.js:39-47` ist eine Kopie von `clearRolesNewRound` inklusive fehlendem `loverId`-Reset.
- Bisherige Doku (04-Status + Kernaussage, 07-Frage, DECISION-LOG, Berichte) und Prüfergebnis dazu:
  - 04 A-21 (`04:50`): "widersprüchlich", `chunk:449-460`, `night:192-199`, "Text Loki wird automatisch gewählt fehlt; letzte Wahl überschreibt". Bestätigt (Zeilen stimmen; Überschreiben `chunk:456`). Ergänzt: EN-Zeitpunkt fehlt, Witwe fehlt in `WOLF_KILL_ROLES`, Zeitwächter stoppt Witwen-Tode nicht, Phantompaar über veraltetes `loverId`.
  - 07 Q1 Teil 1: "Loki wird automatisch gewählt | nur Setup-Pflicht | Vorschlag: Code, Text anpassen". Bestätigt.
  - 01 §4.2 (`01:151`): Reihenfolge "MorningCount+1 → Witwen-Tode → Giftwolf-Tode" bestätigt (`night:191-211`).
  - `docs/role-migration/02-implemented-roles-audit.md:58`: Witwe als Beispiel für F2 genannt, bestätigt (`night:50`).
  - `FIX_REPORT.md:16` (Fix 9 Setup-Pflicht) bestätigt (`gh:1194-1201`).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:137` "Ritter-Vergeltung feuert NICHT bei Schwarze-Witwe-Toden": veraltet/widerlegt, heute enthält `core:431` `BLACK_WIDOW`.
  - DECISION-LOG: keine rollenspezifische Aussage.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Loki "automatisch gewählt" | "Loki wird automatisch gewählt" | "Loki is chosen automatically" | Setup blockiert nur ohne Loki (`setup.html:1111`, `gh:1197`); Handler bricht ohne Loki ab (`chunk:450`) | keine | 04 A-21, 07 Q1: Code gilt, Text anpassen | Loki wird beim Setup automatisch ins Rollenset gelegt | Loki ist Pflicht-Beirolle, SL muss sie wählen | keine, solange Loki Pflicht ist | Godot: `requires_roles` (`03:200`) als Validierung oder Auto-Ergänzung | Pflichtpaar-Validierung behalten, Text auf "Benötigt Loki im Spiel" ändern | Ja |
| Todeszeitpunkt | "am folgenden Tag" | fehlt | Tod zu Beginn des unmittelbar folgenden Tages, vor allen anderen Morgenauflösungen (`night:192-199`) | keine | 04: "Paar stirbt am Morgen" | Tod am Morgen nach der Wahl | Tod erst am Ende des folgenden Tages / nach Lynch | gering; Morgen-Tod verhindert, dass das Paar am Tag noch abstimmt | Zeitpunkt DAWN vs. Tagesende in der Phasenmaschine | Code (Morgen) übernehmen, EN um "the following morning" ergänzen | Nein (EN-Textkorrektur) |
| Zeitwächter-Einfrieren | Zeitwächter: "alle Nachtaktionen dieser Nacht werden abgebrochen" | - | Witwen-Tode laufen vor der Einfrier-Prüfung (`night:192-199` vor `night:323`) | keine | 07 Q1: Zeitwächter "alle Tode dieser Nacht rückgängig" vorgeschlagen | Witwen-Wahl ist Nachtaktion, wird eingefroren | Witwen-Tod ist Tagesereignis, bleibt | mittel; Zeitwächter kontert Witwe nicht | Reihenfolge in DAWN | mit Zeitwächter-Entscheidung Q1 gemeinsam festlegen | Ja |

- Bugs:
  1. Phantompaar nach "Rollen löschen / neue Runde". Einstufung: echter Bug. Codepfad: `gh:512-517` `clearRolesNewRound` setzt `flags.inlove=false` und `meta.rivalId=null`, aber `meta.loverId` nicht; `chunk:453` prüft `(t.meta&&t.meta.loverId)||t.flags.inlove`. Tatsächlich: In der Folgerunde findet die Witwe über das alte `loverId` einen "Liebenden", obwohl Loki in dieser Runde niemanden verbunden hat, und beide sterben am Morgen. Erwartet: nur in dieser Runde durch Loki verbundene Paare. Risiko: mittel (nur bei Rundenwechsel über `clearRolesNewRound` bzw. `legacy-bridge.js:39`, nicht bei `createState`). Regressionstest: Runde 1 Loki verliebt Sitz 2+3, Rollen löschen, Runde 2 ohne Loki-Liebe, Witwe wählt Sitz 2 → erwartet "kein Paar".
  2. `WidowMorningKills` überlebt Rundenwechsel. Einstufung: technische Altlast. Codepfad: `gh:512-528` leert das Feld nicht. Tatsächlich: Witwe wählt, SL beendet die Runde vor Tagesbeginn, in der neuen Runde sterben die Sitz-IDs beim ersten Tagesbeginn. Erwartet: ausstehende Effekte verfallen mit der Runde. Risiko: niedrig. Test: Witwe wählt Paar, `clearRolesNewRound`, neue Runde, Tag starten → niemand stirbt durch `BLACK_WIDOW`.
  3. Keine Rudel-Tötungszeile, wenn nur Witwe als Wolf lebt (F2). Einstufung: echter Bug (bereits 01 F2). Codepfad: `night:50-55`. Risiko: hoch in Setups ohne "Werwolf"-Karte. Test: Setup Witwe + Dorf, Nacht 2 → Werwolf-Zeile vorhanden.
- Legacy-Status: legacy-contradictory. Kernmechanik (Paar finden, beide sterben am Morgen) ist nachvollziehbar umgesetzt; Text verspricht automatische Loki-Wahl, Code verlangt Pflichtwahl; EN-Text ohne Zeitpunkt. Die Bugs betreffen Randpfade (Rundenwechsel) bzw. die allgemeine Werwolf-Zeile.
- Automationsvorschlag: automatic. Ziel wählt der SL per Prompt, Paarprüfung und Morgen-Tod sind deterministisch.
- Mechanikfamilie primär + sekundär: Tötung + Verknüpfte Personen.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt, KillPipeline (Ursache `BLACK_WIDOW`, zeitlich DAWN), InfoRecord (SL-Info "Paar gefunden/kein Paar"), Ereignis-Sichtbarkeit (gm), Reaktionswarteschlange (Ritter-Vergeltung als Folge), StateCodec, Replay, WinRules.
- Benötigte NEUE Systeme: Liebes-/Bindungsmodell (Loki-Paare Liebe/Rivalen als persistente Bindung, nicht nur Flags); zeitlich verzögerte Effekte (Tod zum nächsten Morgen, persistiert).
- Abhängigkeiten von anderen Rollen: Loki (Pflicht, liefert Paare), Zeitwächter (Reihenfolge), Ritter (Vergeltung bei `BLACK_WIDOW`), Rudelvater/Nekromant/Kartenschlucker/Hades/Schattenwanderer/Parasit (Schilde in `applyKill`), Besessener Wolf (siehe Gruppenbeobachtung zur Morgen-Drain-Kollision).
- Komplexität und Fehlerrisiko: M / mittel. Braucht Bindungsmodell und verzögerten Tod; Reihenfolge im Morgen muss mit Zeitwächter, Märtyrerin, Schutz sauber definiert sein.
- Offene Entscheidungen:
  1. Wird Loki beim Setup automatisch ergänzt oder nur validiert?
  2. Zählen Rivalen weiter als Ziel der Witwe, wenn Loki-Rivalen sonst keine Wirkung haben (07 Q1 Loki-Zeile)?
  3. Friert der Zeitwächter die Witwen-Tode ein?
  4. Darf die Witwe sich selbst oder Wölfe wählen (Code: ja)?
  5. Soll ein zweiter Klick / eine zweite Witwe ein weiteres Paar markieren können oder überschreiben?
- Relevante Testgruppen:
  - Normalfall: Loki verliebt A+B in N1, Witwe wählt A in N1 → Morgen 1 sterben A und B mit Ursache `BLACK_WIDOW`.
  - ungültiges Ziel: Witwe wählt Spieler ohne Bindung → Meldung "kein Paar", kein Tod.
  - tote Person: tote Sitze nicht wählbar; Partner tot → kein Paar.
  - Selbstwahl: Witwe ist selbst verliebt und wählt sich → Witwe und Partner sterben (Legacy).
  - mehrere Kopien: zwei Witwen wählen verschiedene Paare → nur das zuletzt gewählte stirbt (Legacy), Soll laut PO.
  - Wiederbelebung: nicht relevant, weil der Handler Wiederbelebte nicht gesondert behandelt; nur `loverId`-Bestand prüfen.
  - Rollenwechsel: Loki-Sitz wird per Seelentauscher getauscht → Handler bricht mit "Loki muss im Spiel sein" ab (Legacy), Soll klären.
  - Save/Load: Witwe wählt, speichern, laden, Tag starten → Paar stirbt.
  - Replay: gleiche Befehlsfolge ergibt dieselben zwei Tode.
  - SL-Korrektur: SL entfernt die ausstehende Markierung vor dem Morgen → kein Tod.
  - Sichtbarkeit: Wahl und Ergebnis nur gm; Tod am Morgen public.
  - Schutz: Schutzengel schützt A → A stirbt trotzdem (Legacy); Nekromant-Schild aktiv → Schild absorbiert einen Tod.
  - Todesreaktionen: B ist Ritter → Ritter-Vergeltung tötet nächsten Wolf; B ist Besessener Wolf → Mitnahme-Prompt erscheint genau einmal und blockiert die Morgenauflösung nicht.
  - Siegprüfung: Paar-Tod reduziert Dorf auf Parität → Wolfssieg-Kandidat.
  - beschädigter Spielstand: `WidowMorningKills` mit unbekannter ID → wird ignoriert, kein Absturz.
- Belegsicherheit: hoch für Handler, Morgenreihenfolge, Setup-Pflicht, `loverId`-Lücke. Nicht verifiziert: tatsächliches Laufzeitverhalten (nicht ausgeführt); ob Nutzer `clearRolesNewRound` in der Praxis vor einer neuen Runde verwenden.

---

### daemonischer-wolf
- DE-Name / EN-Name: Dämonischer Wolf / Demonic Wolf (`roles:162`).
- Aliase/Altnamen: keine Migration. Bild DE `assets/cards/de/Dämonischer_Wolf.webp`, EN `assets/cards/en/Demonic_Wolf.webp` (`gh:826`, `app/src/roleCard.ts:50`). i18n `demonicWolfCurseOne` (`js/core/i18n.js:258` DE, `582` EN "Demonic Wolf ... curse 1"). Statusfeld `meta.cursedWolfAura`.
- Legacy-ID (String in ALL_ROLES): "Dämonischer Wolf".
- Fraktion (getRoleFaction) und weitere Fraktionsbesonderheiten im Code: wolf; in `WOLF_KILL_ROLES` (`night:50`). Besonderheit: sein Fluch setzt `meta.cursedWolfAura` auf einem anderen Sitz; `isWolf` (`core:18`) wertet diesen Sitz danach vollständig als Wolf.
- Akte (akte.js): Akt II (`js/core/akte.js:39`). Custom: alle.
- Nachtpriorität und Bedingungen für den Nachtschritt: kein ORDER_BASE-Eintrag, kein eigener Nachtschritt. Mechanik ausschließlich als Todesreaktion.
- Quelltextstellen:
  - `roles:88` / `roles:237`: Text DE / EN.
  - `night:285-290` `processDemonCurses(killedList,cb)`: für jeden getöteten Dämon in `killedTonight` nacheinander Pick "verfluche 1" auf lebenden Sitz außer dem Dämon, setzt `t.meta.cursedWolfAura=true`.
  - `night:350-352` `resolveDayKills/runRest`: Reihenfolge Ritter → `processDemonCurses` → `drainBesessenerWolf` → `afterCurses`.
  - `night:374`, `night:394`, `night:345`: Einträge in `killedTonight` (Nekromant-Umlenkung, Nachtziel, Brand-Ausbreitung); `push` erfolgt unabhängig vom Rückgabewert von `applyKill` (F14).
  - `night:499-501` `doLynchFlow`: Standard-Lynch, `finalizeLynch`, dann bei Dämon Fluch-Pick, danach `postDeathHooks`.
  - `core:8-19` `isWolf`: `meta.cursedWolfAura` macht den Sitz zum Wolf.
  - `ab:74-76` `onOrderClick`: Kommentar "cursed villagers only APPEAR as wolves", Verfluchte nehmen nicht am Rudel teil.
  - `core:48`, `chunk:765-776`, `night:526` `resetMarksOnly`, `gh:517`: Stellen, die den Fluch zurücksetzen (Wächter am Tor, Seelentauscher, "Markierungen zurücksetzen", neue Runde).
  - `js/ui/field-viewmodel.js:11`: Verfluchte werden im Spielfeld als Wolf eingefärbt.
  - `js/core/role-abilities.js:48`: identisch DE.
- Text DE (wörtlich): "Verflucht Opfer, sodass sie als Werwölfe gesehen werden."
- Text EN (wörtlich): "Curses victims so they appear as werewolves."
- DE/EN-Vergleich: JA, semantisch gleich (verfluchen, Opfer/victims, erscheinen/gesehen als Werwolf). Nuance: DE "Opfer" ist grammatisch Singular oder Plural, EN "victims" nur Plural; beide nennen keinen Zeitpunkt und keine Häufigkeit.
- Weitere Texte: role-abilities identisch. i18n-Prompt "verfluche 1" / "curse 1". Totenkarten: kein direkter Rollenbezug, aber `js/core/cards.js:642-644`, `cards.js:754` `getKartenText` nutzen `isWolf`, ein toter Verfluchter bekommt den Wolf-Kartentext.
- Legacy-Codeverhalten:
  1. Zeitpunkt: nur beim eigenen Tod, und nur auf zwei Pfaden: (a) Nachtauflösung, wenn der Dämon in `killedTonight` steht (Rudel-/Nachtziel, Rudelvater-Zusatzopfer, Nekromant-Umlenkung, Brand-Ausbreitung), (b) Standard-Lynch (`night:499-501`).
  2. Kein Fluch bei allen anderen Todesarten: Witwe, Giftwolf-Verzögerung, Voodoo-Puppe, Hexengift, Hades, Verdammniswächter, Rachsüchtiger Wolf, Besessener-Mitnahme, Liebeskummer, Sensenträger, Ritter-Vergeltung, Spiegelwolf-Vergeltung, Henker, Wahnsinniger-Kutscher-Nachbar, Brand beim Lynch. Beleg: nur `night:289` und `night:501` setzen `cursedWolfAura=true` (grep).
  3. Ziele: genau ein lebender Sitz außer dem Dämon selbst; Wölfe wählbar (dann ohne Wirkung).
  4. Mehrere Dämonen: `processDemonCurses` arbeitet die Liste rekursiv ab, je Dämon ein Fluch.
  5. Wirkung: `cursedWolfAura=true` dauerhaft bis zu einem Reset. Da `isWolf` den Fluch einschließt, zählt der Verfluchte als Wolf für: Siegparität und Dorfsieg (`core:224-233`, `core:305-312`), Detektiv-Hinweis bei seinem Tod (`core:152`), Detektiv-Zufallsauswahl (`core:69-71`), Ritter-Ziel (`core:420-421`), Schmiede-Waffe-Zufallsopfer (`night:383-385`), Kopfgeldjäger-Aktivierung bei Lynch (`night:499`), Orakel-Ergebnis "Werwolf" (`chunk:250`), Blutpriester-Aufdeckung, Waldläufer-Zählung (`chunk:491`), Doktor-Teamvergleich (`help:285`), Totenkarten-Text. Nicht als Wolf zählt er für die Rudel-Teilnahme (`ab:76`).
  6. Er kann nicht mehr Ziel von Albtraumwolf (`chunk:301`) oder Rotkäppchen (`ab:24`) sein.
  7. Todesursache: der Fluch tötet nicht.
  8. Sichtbarkeit: Pick nur SL; im Spielfeld glüht der Sitz als Wolf (`field-viewmodel:11`).
  9. Zufall: keiner im Fluch selbst; indirekt über Detektiv (`core:71`) und Schmiede-Waffe (`night:385`), die unter allen `isWolf`-Sitzen inkl. Verfluchter zufällig wählen.
  10. F14: überlebt der Dämon (z. B. Nekromant-Schild in `applyKill`), steht er trotzdem in `killedTonight` bzw. läuft der Lynch-Zweig weiter, Fluch wird trotzdem ausgelöst.
  11. Abbruch des Fluch-Picks: Nacht: `afterDrag`/`afterCurses` werden nie aufgerufen (Nacht-Ende, Nachtzähler, `postDeathHooks` bleiben aus). Lynch: `postDeathHooks` bleibt aus.
  12. Wiederbelebung/Rollenwechsel: Seelentauscher löscht Fluch (`chunk:765-776`), Wächter am Tor ebenso bei Rollenzuweisung (`core:48`). Wiederbelebung löscht ihn nicht.
- React-Version: kein eigenes Verhalten, nur Bild (`app/src/roleCard.ts:50`); `legacy-bridge.js:39` setzt `cursedWolfAura` beim Rundenwechsel zurück.
- Bisherige Doku und Prüfergebnis:
  - 04 A-32 (`04:61`): "widersprüchlich", `night:285-290,501`, "Bei eigenem Tod verflucht er 1 Spieler, der als Wolf erscheint. Code: Verfluchter zählt als Wolf (Parität, Ritter, Detektiv)". Bestätigt, Zeilen korrekt. Ergänzt: Fluch nur auf zwei Todespfaden; Text sagt "Opfer", nicht "beim Tod"; weitere `isWolf`-Nutzer (Kopfgeldjäger, Schmied, Orakel, Totenkarten); Abbruch-Stillstand.
  - 07 Q1: "Verfluchter erscheint als Wolf | zählt als Wolf | Text (nur Erscheinung)". Bestätigt.
  - 01 F14 (`01:275`) "killedTonight enthält auch Überlebende (Dämonen-Fluch...)" bestätigt (`night:374,394`).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:31-33`: `checkTeamWin` ohne `cursedWolfAura`: veraltet/widerlegt, `core:295` nutzt jetzt `isWolf`.
  - `docs/role-migration/02-implemented-roles-audit.md:89`: Fluch braucht weitere Reaktionsart. Plausibel, nicht gegen Godot-Code geprüft.
  - `NIGHT-REPORT-abilities.md:76` "1 Ziel (verflucht)" als Nachtaktion: widerlegt, es gibt keinen Nachtschritt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Auslöser | "Verflucht Opfer" | "Curses victims" | nur Todesreaktion (`night:285-290,501`) | keine | 04: "Bei eigenem Tod" | Die Opfer des Rudels werden verflucht (dann sind sie aber tot) | Beim eigenen Tod verflucht er ein Opfer seiner Wahl | hoch: laufender Fluch vs. einmaliger Todesfluch | Nachtschritt vs. Todesreaktion | Todesreaktion (Code) übernehmen, Text präzisieren | Ja |
| Wirkung des Fluchs | "als Werwölfe gesehen" | "appear as werewolves" | zählt als Wolf in allen `isWolf`-Stellen inkl. Sieg | keine | 04, 07 Q1: Text (nur Erscheinung) | nur `appears_as` (Informationsrollen) | echter Fraktionswechsel für Parität | sehr hoch: Dorf kann ohne echten Wolf nicht gewinnen | Godot `appears_as` vs. `counts_as_wolf` | nur `appears_as` | Ja |
| Todespfade | - | - | Fluch nur bei Nachtziel/Brand/Umlenkung und Standard-Lynch | keine | nicht dokumentiert | jeder Tod löst Fluch aus | nur Wolfsangriff und Lynch | mittel | Reaktion an KillPipeline für alle Ursachen | jeder Tod | Ja |

- Bugs:
  1. Fluch trotz Überleben (F14). Einstufung: echter Bug. Codepfad: `night:394` `applyKill(s,killCause); killedTonight.push(s)` ohne Ergebnisprüfung; `night:499-501` Lynch ohne Ergebnisprüfung. Tatsächlich: Dämon überlebt per Schild, Fluch-Pick erscheint trotzdem. Erwartet: Reaktion nur bei echtem Tod. Risiko: mittel. Test: Nekromant-Schild aktiv, Rudel tötet Dämon → kein Fluch-Prompt.
  2. Abbruch des Fluch-Picks stoppt die Nachtauflösung. Einstufung: echter Bug. Codepfad: `night:289` `startPick` ohne Abbruch-Callback, `ui:315/325`. Tatsächlich: Nach "Abbrechen" laufen `drainBesessenerWolf`/`afterCurses` nie; `state.dark` bleibt, `nightCount` wird nicht erhöht, `postDeathHooks` der Nacht fehlen. Erwartet: Abbruch = Verzicht, Auflösung läuft weiter (oder Pflicht ohne Abbruch). Risiko: hoch (Knopf ist immer sichtbar). Test: Dämon stirbt nachts, Fluch-Prompt abbrechen → Tag beginnt trotzdem vollständig.
  3. Verfluchter blockiert den Dorfsieg. Einstufung: unklare Regel (Code-Kommentar `ab:75` spricht von "nur erscheinen", Siegprüfung nutzt `isWolf`). Codepfad: `core:224-233`. Tatsächlich: alle echten Wölfe tot, ein Verfluchter lebt → kein Dorfsieg; bei Parität gewinnen sogar "Werwölfe". Erwartet laut Text: nur Erscheinung. Risiko: hoch. Test: Wölfe tot, verfluchter Dorfbewohner lebt → Dorfsieg-Kandidat.
- Legacy-Status: legacy-contradictory. Code ist in sich nachvollziehbar (Todesfluch mit Wolfswertung), widerspricht aber Text (Opfer, nur Erscheinung) und der eigenen Code-Absicht (`ab:75`).
- Automationsvorschlag: automatic (Reaktion mit Pflicht-Prompt), sobald PO Auslöser und Wirkung entschieden hat.
- Mechanikfamilie primär + sekundär: Todesreaktion + Fehlinformation.
- Benötigte vorhandene Godot-Systeme: Reaktionswarteschlange (neue Reaktionsart "curse_appearance"), PendingPrompt, appears_as, KillPipeline (Auslöser nach echtem Tod), InfoRecord (Wahrheit vs. gezeigt), GmCorrections (Fluch entfernen), StateCodec, Replay, WinRules (unverändert, falls nur Erscheinung).
- Benötigte NEUE Systeme: dauerhafte Statusmarker (Fluch als persistenter Marker mit Quelle), falls nicht vollständig über `appears_as` abbildbar.
- Abhängigkeiten von anderen Rollen: Orakel, Blutpriester, Waldläufer, Doktor, Detektiv, Kopfgeldjäger, Ritter, Dorfschmied, Traumdeuter (alle `isWolf`-Leser); Seelentauscher und Wächter am Tor (löschen Fluch); Nekromant (F14-Fall).
- Komplexität und Fehlerrisiko: M / hoch. Reaktion ist einfach, aber die Trennung Erscheinung vs. Zählung berührt alle Informationsrollen und die Siegprüfung.
- Offene Entscheidungen:
  1. Auslöser: eigener Tod (Code) oder laufender Fluch auf Rudelopfer (Textwortlaut)?
  2. Wirkung: nur Erscheinung für Informationsrollen oder echte Wolfszählung?
  3. Löst jede Todesart den Fluch aus oder nur Nachtangriff und Lynch?
  4. Ist der Fluch Pflicht oder darf verzichtet werden?
  5. Welche Rollen sehen den Fluch (Orakel ja; Doktor, Waldläufer, Detektiv, Ritter, Schmied?)?
- Relevante Testgruppen:
  - Normalfall: Rudel tötet Dämon → Prompt, Sitz 4 verflucht → Orakel sieht Sitz 4 als Werwolf.
  - ungültiges Ziel: Dämon selbst oder toter Sitz nicht wählbar.
  - tote Person: Verfluchter stirbt → Totenkarten-Text laut Entscheidung.
  - Selbstwahl: nicht wählbar (`x!==next`).
  - mehrere Kopien: zwei Dämonen sterben in einer Nacht → zwei Prompts nacheinander.
  - Wiederbelebung: verfluchter Toter wird wiederbelebt → Fluch bleibt (Legacy), Soll klären.
  - Rollenwechsel: Seelentauscher tauscht Verfluchten → Fluch entfernt (Legacy).
  - Save/Load: Fluch-Prompt offen, speichern, laden → Prompt weiterhin offen.
  - Replay: gleiche Befehle ergeben denselben Fluch.
  - SL-Korrektur: SL entfernt Fluch → Orakel sieht wieder echte Rolle.
  - Sichtbarkeit: Fluch-Wahl nur gm; kein öffentliches Ereignis.
  - Schutz: Dämon durch Schild gerettet → kein Fluch.
  - Todesreaktionen: Dämon und Besessener sterben gleichzeitig → Reihenfolge Fluch vor Mitnahme (Legacy `night:351-352`).
  - Siegprüfung: alle echten Wölfe tot, Verfluchter lebt → Dorfsieg (bei Entscheidung "nur Erscheinung").
  - beschädigter Spielstand: `cursedWolfAura` auf unbekanntem Sitz → ignoriert.
- Belegsicherheit: hoch für Auslösepfade und `isWolf`-Nutzung. Nicht verifiziert: Laufzeitverhalten des Abbruchs (nur aus Code abgeleitet); Godot-Reaktionsarten (nur Doku gelesen).

---

### schattenhund
- DE-Name / EN-Name: Schattenhund / Shadow Hound (`roles:164`).
- Aliase/Altnamen: keine Migration. Bild DE `Schattenhund.webp`, EN `Shadow_Hound.webp` (`gh:827`, `app/src/roleCard.ts:52`). State `state.once.SchattenhundBlocked`, Einmal-Schlüssel `state.once.Used.role_Schattenhund` (`night:3-5`). i18n `shadowhoundBlocked` (`i18n.js:220` DE, `549` EN), Laufzeitübersetzung `i18n.js:754`, `855`, `859`.
- Legacy-ID (String in ALL_ROLES): "Schattenhund".
- Fraktion: wolf. Nicht in `WOLF_KILL_ROLES` (`night:50`), F2 betrifft auch ihn.
- Akte (akte.js): Akt III (`js/core/akte.js:61`).
- Nachtpriorität und Bedingungen: tier 0.7, once:true (`roles:8`), Gruppe "Einmalige Nacht-1-Rollen" (`roles:4`). Schritt erscheint, solange Schattenhund lebt und `isOnceUsed("Schattenhund")` falsch ist (`night:60`, `night:86-93`). In Nacht 1 erscheint der Schritt, der Handler verweigert aber (`chunk:706`).
- Quelltextstellen:
  - `roles:8`, `roles:90`, `roles:239`.
  - `chunk:704-711` Handler: Einmal-Prüfung, Nacht-1-Sperre (fester DE-Text), Ja/Nein-Overlay, "Ja" setzt `SchattenhundBlocked=true` und `markOnceUsed`.
  - `ab:93-94` `onOrderClick`: blockiert jede Rolle außerhalb `WOLF_ROLES_SET`, solange Flag gesetzt.
  - `night:139` `onNightStart`: Flag auf false.
  - `js/core/role-abilities.js:54`.
- Text DE (wörtlich): "Kann einmalig alle Dorf-Fähigkeiten für eine Nacht blockieren."
- Text EN (wörtlich): "Can once block all village abilities for one night."
- DE/EN-Vergleich: JA, semantisch gleich (einmalig/once, alle Dorf-Fähigkeiten/all village abilities, eine Nacht/one night).
- Weitere Texte: Overlay "Dorf-Fähigkeiten 1 Nacht blockieren?" (EN-Laufzeit "Block all village abilities for 1 night?" `i18n.js:754` bzw. "Block village abilities for 1 night?" `i18n.js:859`, zwei Varianten). Nacht-1-Meldung nur DE hartkodiert (`chunk:706`), keine EN-Übersetzung gefunden. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt tier 0.7, also vor allen Dorf-Nachtrollen der Nächte ab 2 (die Rollen mit tier < 0.7 sind once und in Nacht 1 bereits verbraucht).
  2. Nacht 1: Handler verweigert mit Hinweis auf Wolfskind und Lehrling, Einsatz bleibt erhalten.
  3. Ab Nacht 2: Ja/Nein. "Nein" verbraucht nichts. "Ja" setzt globales Flag und markiert die Rolle als verbraucht (global pro Rollenname, alle Kopien teilen einen Einsatz).
  4. Ziele: keine.
  5. Wirkung: `onOrderClick` bricht für jede Rolle ab, die nicht in `WOLF_ROLES_SET` steht, also Dorf UND Solo, auch Werwolf-Zeile nicht betroffen. Nicht betroffen: alles außerhalb `onOrderClick` (Morgenauflösung: Märtyrerin, Voodoo-Umlenkung, Der Weise, Dorfwache, Schmiede-Waffe; Todesreaktionen: Sensenträger, Ritter; Schutzflags aus früheren Nächten). Verwandeltes Wolfskind mit Rollenname "Wolfskind" wird ebenfalls blockiert (nicht im Set).
  6. Flag bleibt bis zum nächsten `onNightStart` gesetzt, auch am Tag.
  7. Sichtbarkeit: blockierte Schritte zeigen "Keine Fähigkeit (Schattenhund)" nur dem SL.
  8. Zufall: keiner.
  9. Mehrere Kopien: ein gemeinsamer Einsatz (`markOnceUsed` nach Rollenname).
  10. Rollenwechsel: Lehrling/Seelentauscher erhält die Rolle, Einsatz bleibt verbraucht (kein Reset in `core:339-359` `resetOnceForInheritedRole` für Schattenhund; der generische Schlüssel `SchattenhundUsed` existiert nicht, benutzt wird `Used.role_Schattenhund`).
  11. Sieg: keine eigene Bedingung.
- React-Version: kein eigenes Verhalten (nur Bild).
- Bisherige Doku und Prüfergebnis:
  - 04 A-34 (`04:63`): "widersprüchlich", `chunk:704-711`, `ab:94`, "nicht in Nacht 1 (steht aber in Gruppe Nacht 1), blockiert auch Solos". Bestätigt.
  - 04 B-6: Blockaden "für Nicht-Wölfe inkl. Solos", Status unklar. Bestätigt.
  - 07 Q1: Vorschlag "Ab Nacht 2, nur Dorf". Offen.
  - `ROLE-FLOW-REPORT.md:57`: Nacht 1 gesperrt, ab Nacht 2 Ja/Nein. Bestätigt.
  - `NIGHT-REPORT-abilities.md:86` "(?)": jetzt geklärt, 0 Ziele, Ja/Nein.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Betroffene Rollen | "alle Dorf-Fähigkeiten" | "all village abilities" | alle Nicht-`WOLF_ROLES_SET`-Rollen inkl. Solo (`ab:93-94`) | keine | 04 A-34, B-6; 07 Q1 "nur Dorf" | nur Fraktion Dorf | alle Nicht-Wölfe | mittel: Solos werden mitblockiert | Filter über Fraktion statt "nicht Wolf" | nur Dorf | Ja |
| Nacht 1 | keine Einschränkung | keine Einschränkung | Nacht 1 verweigert (`chunk:706`) | keine | 04, 07: ab Nacht 2 | Einsatz ab Nacht 1 | ab Nacht 2 | gering | Verfügbarkeitsbedingung des Schritts | ab Nacht 2, Text ergänzen | Ja |
| Nicht-Nachtschritt-Effekte | "alle Dorf-Fähigkeiten" | "all village abilities" | nur `onOrderClick`, keine Morgen- oder Todesreaktionen | keine | nicht dokumentiert | nur Nachtschritte | auch Reaktionen/passive Effekte dieser Nacht | mittel | Blockade als Schritt-Status oder als globale Regel | nur Nachtschritte, Text präzisieren | Ja |

- Bugs:
  1. Keine Werwolf-Zeile, wenn nur Schattenhund als Wolf lebt (F2). Einstufung: echter Bug. Codepfad `night:50-55`. Test: Schattenhund + Dorf, Nacht 2 → Rudelschritt vorhanden.
  2. Nacht-1-Meldung nicht übersetzt. Einstufung: technische Altlast. Codepfad `chunk:706`. Test: EN, Nacht 1, Schattenhund klicken → englischer Hinweis.
- Legacy-Status: legacy-contradictory. Kernfunktion (einmalige Blockade einer Nacht) funktioniert; Zielgruppe (Solo) und Nacht-1-Sperre weichen vom Text ab.
- Automationsvorschlag: automatic.
- Mechanikfamilie primär + sekundär: Einmalfähigkeit + globale Regeländerung.
- Benötigte vorhandene Godot-Systeme: StepQueue (Schritt-Status "blockiert mit Grund", 04 B-6), PendingPrompt (Ja/Nein), `ability_uses`, Ereignis-Sichtbarkeit, StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Rollenblockierung (globaler Nacht-Modifikator mit Fraktionsfilter und Ablauf bei Nachtende).
- Abhängigkeiten von anderen Rollen: alle Dorf-Nachtrollen; Wolfskind und Lehrling (Begründung der Nacht-1-Sperre); Albtraumwolf, Zeitwächter, Der Weise (gleiche Blockadefamilie).
- Komplexität und Fehlerrisiko: S / mittel. Einfache Flag-Logik; Risiko in der genauen Abgrenzung, welche Effekte blockiert sind.
- Offene Entscheidungen:
  1. Nur Dorf oder alle Nicht-Wölfe?
  2. Ab Nacht 1 oder ab Nacht 2?
  3. Werden auch Morgenreaktionen (Märtyrerin, Schmiede-Waffe) und Todesreaktionen in dieser Nacht blockiert?
  4. Teilen mehrere Schattenhunde einen Einsatz?
- Relevante Testgruppen:
  - Normalfall: Nacht 2, Ja → Orakel-Schritt zeigt "blockiert", Werwolf-Schritt normal.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: toter Schattenhund → Schritt fehlt.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Schattenhunde → nach einem Einsatz kein zweiter (Legacy), Soll laut PO.
  - Wiederbelebung: wiederbelebter Schattenhund mit verbrauchtem Einsatz → kein Schritt.
  - Rollenwechsel: Lehrling erbt Schattenhund nach Verbrauch → kein Einsatz (Legacy).
  - Save/Load: Blockade aktiv, speichern, laden → Blockade bleibt bis Nachtende.
  - Replay: identisch.
  - SL-Korrektur: SL hebt Blockade auf → Schritt wieder verfügbar.
  - Sichtbarkeit: Blockadegrund nur gm.
  - Schutz: Schutzengel-Schritt blockiert → kein neuer Schutz in dieser Nacht.
  - Todesreaktionen: Sensenträger stirbt in blockierter Nacht → Reaktion laut PO-Entscheidung.
  - Siegprüfung: nicht relevant, weil keine Siegwirkung.
  - beschädigter Spielstand: Flag gesetzt bei Tagphase → nächster Nachtbeginn setzt zurück.
- Belegsicherheit: hoch.

---

### besessener-wolf
- DE-Name / EN-Name: Besessener Wolf / Possessed Wolf (`roles:165`).
- Aliase/Altnamen: keine Migration. Bild DE `Besessener_Wolf.webp`, EN `Possessed_Wolf.webp` (`gh:827`, `app/src/roleCard.ts:53`). Todesursache `BESESSENER_WOLF` (`night:313`), Log `logPossessedWolf` (`i18n.js:139` DE, `463` EN; `gh:2422`), Label `ui:411`. State `state.once.besessenerWolfPending`, `state.once._besessenerDraining`. Prompt-Schlüssel `besessenerWolfDrag` fehlt in i18n.
- Legacy-ID (String in ALL_ROLES): "Besessener Wolf".
- Fraktion: wolf, in `WOLF_KILL_ROLES`.
- Akte (akte.js): Akt III (`js/core/akte.js:61`).
- Nachtpriorität und Bedingungen: kein ORDER_BASE-Eintrag, kein Nachtschritt; reine Todesreaktion.
- Quelltextstellen:
  - `roles:91`, `roles:240`, `js/core/role-abilities.js:45`.
  - `core:176-189` `applyKill`: nach `dead=true`, wenn Rolle Besessener Wolf und `aliveNow>=4` (Lebende nach seinem Tod), Sitz-ID in `besessenerWolfPending`.
  - `night:292-320` `drainBesessenerWolf(cb)`: Wiedereintrittssperre `_besessenerDraining`, pro ID erneute Prüfung `aliveNow<4` → überspringen, sonst Pick auf lebenden Sitz, `applyKill(s,"BESESSENER_WOLF")`, `postDeathHooks`, nächster Eintrag.
  - `night:351` Nacht: Drain nach Dämonen-Fluch, vor `afterCurses`.
  - `core:410-415` `postDeathHooks`: Drain außerhalb der Nachtauflösung.
  - `night:312` Prompt mit fehlendem Schlüssel.
- Text DE (wörtlich): "Reißt beim Tod (bei ≥5 Spielern) einen weiteren mit in den Tod."
- Text EN (wörtlich): "Upon death (with ≥5 players), drags another player to their death."
- DE/EN-Vergleich: JA, semantisch gleich; beide lassen offen, ob "≥5 Spieler" lebende oder alle Spieler meint.
- Weitere Texte: role-abilities identisch; Laufzeit-Teilübersetzung "reißt 1 mit" → "drags 1 with" (`i18n.js:814`) greift nicht, weil der Rohschlüssel angezeigt wird.
- Legacy-Codeverhalten:
  1. Auslöser: jeder erfolgreiche `applyKill` des Besessenen (alle Ursachen: Nacht, Lynch, Witwe, Gift, Hexe, Liebeskummer usw.).
  2. Bedingung: nach seinem Tod leben mindestens 4 (= mindestens 5 Lebende inkl. ihm vor dem Tod). Beim Abarbeiten erneute Prüfung; sind inzwischen weniger als 4 am Leben, verfällt die Mitnahme ohne Meldung (`night:311`).
  3. Zeitpunkt: nachts nach Ritter und Dämonen-Fluch, vor `afterCurses` (`night:350-352`); tagsüber am Ende von `postDeathHooks` (`core:414`).
  4. Ziel: ein lebender Sitz außer ihm (`x.id!==id`), Wölfe erlaubt. Pflicht laut UI, aber "Abbrechen" möglich.
  5. Wirkung: sofortiger Tod mit Ursache `BESESSENER_WOLF` über `applyKill`, also Schilde (Rudelvater-Erstrettung, Nekromant, Kartenschlucker, Hades, Schattenwanderer-Umlenkung, Parasit-Immunität) greifen; Schutzengel nicht.
  6. Kettenreaktion: stirbt dadurch ein weiterer Besessener, wird er angehängt und in derselben Schleife abgearbeitet.
  7. Mehrere Kopien: Warteschlange pro Sitz-ID.
  8. Sichtbarkeit: Pick nur SL; Tod öffentlich (Log/Tod-Popup).
  9. Zufall: keiner.
  10. Rollenwechsel/Wiederbelebung: keine Sonderbehandlung.
- React-Version: kein eigenes Verhalten (nur Bild).
- Bisherige Doku und Prüfergebnis:
  - 04 A-35 (`04:64`): "verifiziert", `core:176-189`, `night:298-320`, "Bei Tod mit ≥ 4 Lebenden: reißt 1 mit". Zeilen bestätigt, Bedingung bestätigt (≥4 Lebende NACH seinem Tod). Status "verifiziert" widerlegt: fehlender i18n-Schlüssel (F12), Abbruch-Blockade, verzögerte Mitnahme bei Liebeskummer, Kollision mit Morgen-Toden (siehe Bugs).
  - 04 G-11 und 01 F12: `besessenerWolfDrag` fehlt. Bestätigt, und schärfer: `window.t` gibt den Schlüssel zurück, der DE-Fallback wird nie gezeigt, in BEIDEN Sprachen steht der Rohschlüssel in der Pick-Leiste.
  - 01 §4.2 (`01:155`) Reihenfolge bestätigt.
  - `docs/godot-migration/02-product-and-ux-spec.md:234-240`: Soll-Prompt "Es leben noch 7" usw. Nur Spezifikation.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Schwelle "≥5 Spieler" | "bei ≥5 Spielern" | "with ≥5 players" | ≥4 Lebende nach seinem Tod, erneut geprüft beim Abarbeiten (`core:178-179`, `night:310-311`) | keine | 04: "≥ 4 Lebenden" | 5 Lebende inkl. ihm im Todesmoment | 5 Spieler bei Spielbeginn | mittel im Endspiel | Prüfzeitpunkt (Tod vs. Abarbeitung) | lebende inkl. ihm im Todesmoment, keine Neuprüfung | Ja |

- Bugs:
  1. Rohschlüssel im Prompt (F12). Einstufung: echter Bug. Codepfad `night:312`, `i18n.js:652-655`. Tatsächlich: Pick-Leiste zeigt "besessenerWolfDrag". Erwartet: lokalisierter Text. Risiko: niedrig (funktional), sichtbar bei jedem Einsatz. Test: Content-Lint "alle genutzten Schlüssel existieren".
  2. Abbruch sperrt alle künftigen Mitnahmen. Einstufung: echter Bug. Codepfad `night:305` setzt `_besessenerDraining=true`, nur `night:308` löscht es; `ui:325` kein Abbruch-Callback. Tatsächlich: nach "Abbrechen" bleibt die Sperre gesetzt und wird mit gespeichert (`state:111`); jeder spätere Drain kehrt bei `night:303` ohne Callback zurück. Nachts heißt das zusätzlich: `afterCurses` läuft nie (Nachtende fehlt). Erwartet: Abbruch = Verzicht, Sperre gelöst, Auflösung läuft weiter. Risiko: hoch. Test: Besessener stirbt, Prompt abbrechen, später zweiter Besessener stirbt → Prompt erscheint; Nacht endet korrekt.
  3. Verzögerte Mitnahme bei Liebeskummer in der Nachtauflösung. Einstufung: echter Bug. Codepfad `night:350` `afterCurses` setzt `_inNightResolution`, `postDeathHooks` tötet den verliebten Besessenen (`core:365-384`), `core:414` überspringt den Drain, danach wird nicht mehr gedraint. Tatsächlich: Mitnahme erscheint erst beim nächsten `postDeathHooks` außerhalb der Nacht (z. B. nächster Lynch) oder nie. Erwartet: am selben Morgen. Risiko: mittel (Loki-Paare). Test: Loki verliebt Besessenen mit Opfer X, Rudel tötet X → Mitnahme-Prompt am selben Morgen.
  4. Kollision mit Morgen-Toden vor der Auflösung. Einstufung: echter Bug (aus Code abgeleitet, nicht ausgeführt). Codepfad `night:196-197` bzw. `night:208-209`: Witwen-/Giftwolf-Tod ruft `postDeathHooks` außerhalb `_inNightResolution` → Drain startet sofort (`core:414`), während `onDayStart` synchron weiterläuft. Ein späterer `startPick` (Dämonen-Fluch `night:289`, Nekromant `night:369-373`, Rudelvater `night:270`) ersetzt den offenen Mitnahme-Pick; die Sperre bleibt gesetzt. Stirbt nachts zusätzlich ein Besessener, kehrt `drainBesessenerWolf(afterCurses)` wegen der Sperre ohne Callback zurück → Nachtende fehlt. Risiko: mittel. Test: Witwe tötet verliebten Besessenen am Morgen, gleichzeitig stirbt ein Dämon → beide Prompts nacheinander, Nacht endet.
- Legacy-Status: legacy-broken. Normalpfad (einzelner Tod ohne Abbruch) ist korrekt, aber belegte Fehler verhindern die Mitnahme dauerhaft nach einem Abbruch, verschieben sie bei Liebeskummer in einen falschen Zeitpunkt und zeigen bei jedem Einsatz einen Rohschlüssel. Ein 1:1-Golden-Test würde Fehler festschreiben.
- Automationsvorschlag: automatic (Reaktion mit Pflicht-Prompt).
- Mechanikfamilie primär + sekundär: Todesreaktion + Tötung.
- Benötigte vorhandene Godot-Systeme: Reaktionswarteschlange (neue Reaktionsart "drag", persistiert, nicht abbrechbar oder mit Verzicht), PendingPrompt, KillPipeline (Ursache `BESESSENER_WOLF`, Schilde), StateCodec (offene Reaktion speichern), Replay, Ereignis-Sichtbarkeit, WinRules.
- Benötigte NEUE Systeme: keine über die Reaktionsart hinaus (Warteschlange existiert).
- Abhängigkeiten von anderen Rollen: Loki (Liebeskummer-Pfad), Schwarze Witwe und Giftwolf (Morgen-Tode), Dämonischer Wolf (Reihenfolge), Rudelvater, Nekromant, Kartenschlucker, Hades, Schattenwanderer, Parasit (Schilde).
- Komplexität und Fehlerrisiko: M / hoch. Mechanik einfach, Legacy zeigt aber, dass Reaktionsreihenfolge und Unterbrechbarkeit fehleranfällig sind.
- Offene Entscheidungen:
  1. Schwelle: 5 Lebende inkl. ihm im Todesmoment oder zum Abarbeitungszeitpunkt?
  2. Ist die Mitnahme Pflicht oder darf verzichtet werden?
  3. Dürfen Wölfe mitgerissen werden (Code: ja)?
  4. Greifen Schilde gegen die Mitnahme (Code: ja)?
- Relevante Testgruppen:
  - Normalfall: 7 Lebende, Besessener gelyncht → Prompt, Sitz 2 stirbt mit `BESESSENER_WOLF`.
  - ungültiges Ziel: toter Sitz nicht wählbar.
  - tote Person: nach seinem Tod leben nur 3 → kein Prompt.
  - Selbstwahl: nicht wählbar.
  - mehrere Kopien: Besessener reißt zweiten Besessenen mit → zweiter Prompt folgt.
  - Wiederbelebung: wiederbelebter Besessener stirbt erneut → erneut Mitnahme.
  - Rollenwechsel: Lehrling erbt Besessenen, stirbt → Mitnahme.
  - Save/Load: Prompt offen, speichern, laden → Prompt offen, keine Sperre.
  - Replay: identische Tode.
  - SL-Korrektur: SL macht Mitnahme rückgängig → Opfer lebt, Reaktionen des Opfers zurückgenommen.
  - Sichtbarkeit: Wahl gm, Tod public.
  - Schutz: Nekromant-Schild aktiv → Mitnahme absorbiert.
  - Todesreaktionen: mitgerissener Sensenträger → Sensenträger-Reaktion folgt; Liebeskummer-Fall am selben Morgen.
  - Siegprüfung: Mitnahme führt zu Parität → Siegkandidat erst nach Abschluss aller Reaktionen.
  - beschädigter Spielstand: `_besessenerDraining` true ohne offene Reaktion → wird beim Laden bereinigt.
- Belegsicherheit: hoch für Bedingung, Reihenfolge, F12. Mittel für Bug 3 und 4 (aus Codefluss abgeleitet, nicht im Browser ausgeführt).

---

### fenrir
- DE-Name / EN-Name: Fenrir / Fenrir (`roles:166`).
- Aliase/Altnamen: keine. Bild DE `Fenrir.webp`, EN `Fenrir.webp` (`gh:827`, `app/src/roleCard.ts:54`). Globale State-Felder `state.fenrirStage`, `state.fenrirSaved` (nicht in `once`, nicht pro Sitz; Default in `createState` `state:10`).
- Legacy-ID (String in ALL_ROLES): "Fenrir".
- Fraktion: wolf, in `WOLF_KILL_ROLES`.
- Akte (akte.js): Akt IV (`js/core/akte.js:81`).
- Nachtpriorität und Bedingungen: kein ORDER_BASE-Eintrag, kein Nachtschritt; passiv.
- Quelltextstellen:
  - `roles:92`, `roles:241`, `js/core/role-abilities.js:49`.
  - `night:136` `onNightStart`: lebt irgendein Fenrir, `fenrirStage=min(3,stage+1)`.
  - `night:448` `doLynchFlow`: Fenrir mit Stufe ≥3 und `!fenrirSaved` → `fenrirSaved=true`, `save`, `draw`, `return` (kein `applyKill`, kein `finalizeLynch`, keine Meldung).
  - `core:418-428` `findNearestWolf`: Fenrir mit Stufe ≥3 ist für die Ritter-Vergeltung unsichtbar.
  - `gh:523`, `gh:558`, `app/public/legacy-bridge.js:45`: Reset auf 0/false beim Rundenwechsel.
- Text DE (wörtlich): "Wird mit jeder überlebten Nacht mächtiger. Ab Stufe 3 überlebt er einmalig jeden Tod."
- Text EN (wörtlich): "Grows more powerful with each survived night. From stage 3, survives any death once."
- DE/EN-Vergleich: JA, semantisch gleich (überlebte Nacht, Stufe 3, einmalig, jeder Tod).
- Weitere Texte: keine i18n-Schlüssel, keine Meldung, kein Marker. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Stufe: global, steigt bei jedem Nachtbeginn um 1, solange irgendein Fenrir lebt; also Stufe 1 in Nacht 1, Stufe 3 ab Beginn von Nacht 3, bevor die Nacht überlebt ist. Kein Schutz gegen Doppelklick auf "Nacht starten" (`gh:508`, `night:130-136` ohne Sperre).
  2. Stufen 1 und 2 haben keine Wirkung.
  3. Stufe ≥3, Lynch: Lynch wird still abgebrochen, einmalig (`fenrirSaved`). Brand-Ausbreitung beim Lynch eines brennenden Fenrir läuft vorher trotzdem (`night:444-446`). LynchCount und Henker-Hinrichtungen entfallen (F15). Kein Log, keine SL-Meldung.
  4. Stufe ≥3, alle anderen Todesarten (Nachtangriff, Witwe, Hexe, Hades, Besessener, Giftwolf, Liebeskummer, Sensenträger, Verdammniswächter, Rachsüchtiger Wolf): kein Schutz, `applyKill` kennt Fenrir nicht (`core:102-216`).
  5. Stufe ≥3, Ritter: dauerhaft immun (auch nach verbrauchtem `fenrirSaved`), Ritter trifft stattdessen den nächsten anderen Wolf.
  6. Mehrere Kopien: gemeinsame Stufe und gemeinsamer Einmal-Schutz.
  7. Stufe bleibt nach Fenrirs Tod stehen; ein späterer Fenrir (Lehrling, Seelentauscher, Frankenstein) startet mit der alten Stufe.
  8. Sichtbarkeit: Stufe wird nirgends angezeigt (`ui:109` `markerList` ohne Fenrir).
  9. Zufall: keiner.
- React-Version: kein eigenes Verhalten (nur Bild; Reset in `legacy-bridge.js:45`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-36 (`04:65`): "widersprüchlich", `night:136,448`, `core:421`, "nur Lynch; Stufe steigt pro Nachtbeginn". Bestätigt. Ergänzt: Ritter-Immunität dauerhaft und nicht verbraucht; stiller Abbruch ohne Meldung; globale Stufe; Brand-Ausbreitung trotz Rettung.
  - 04 C (`04:143`) "Fenrir (Lynch) widersprüchlich (A-36)" bestätigt.
  - 01 F15 (`01:276`): überspringt `finalizeLynch`. Bestätigt (`night:448` vor `night:500`).
  - 07 Q1: "nur Lynch | Vorschlag Text". Offen.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:124` (Fenrir bekommt nie Wolf-Flag): heute irrelevant, `isWolf` nutzt das Set.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Umfang des Überlebens | "überlebt einmalig jeden Tod" | "survives any death once" | nur Lynch (`night:448`) | keine | 04 A-36, 07 Q1 Vorschlag Text | jede Todesursache, einmal | nur Hinrichtung | hoch: Nachtangriffe kann Wolf-Team nicht wählen, aber Witwe/Hexe/Hades sehr wohl | Abfangregel in KillPipeline vs. ExecutionRules | jede Ursache (Text) | Ja |
| Zählung | "jeder überlebten Nacht" | "each survived night" | +1 bei Nachtbeginn (`night:136`) | keine | 04: "pro Nachtbeginn" | +1 am Morgen nach überlebter Nacht | +1 bei Nachtbeginn | gering (eine Nacht früher Stufe 3) | Zeitpunkt DAWN vs. NIGHT_START | +1 am Morgen, wenn Fenrir lebt | Ja |
| Ritter | nicht erwähnt | nicht erwähnt | ab Stufe 3 dauerhaft immun (`core:421`) | keine | 04 nennt `core:421` ohne Wertung | Teil von "jeder Tod" (einmal) | Sonderimmunität | mittel | Ritter-Zielauswahl | an Einmal-Schutz koppeln | Ja |
| Stufe pro Rolle vs. global | "Wird ... mächtiger" (er) | "Grows" | global `state.fenrirStage` | keine | 01:125 nennt Feld | pro Person | global | gering (selten mehrere Fenrir) | Feld am Spieler | pro Person | Nein |

- Bugs:
  1. Lynch-Rettung überspringt `finalizeLynch` (F15). Einstufung: echter Bug. Codepfad `night:448`. Tatsächlich: LynchCount bleibt, Henker-markierte sterben nicht, kein Log. Erwartet laut 04 E-3: jeder Hinrichtungszweig bucht. Risiko: mittel (Henker-Freischaltung verzögert). Test: 2 Lynchs, dann Fenrir-Lynch-Rettung → LynchCount 3 (nach Entscheidung), Henker aktiv.
  2. Stille Rettung ohne Rückmeldung. Einstufung: technische Altlast. Codepfad `night:448` ohne `center`/Log. Tatsächlich: SL sieht nur, dass nichts passiert. Test: Lynch auf Fenrir Stufe 3 → Ereignis "Fenrir überlebt" (gm).
  3. Brand-Ausbreitung trotz abgewehrtem Lynch. Einstufung: unklare Regel. Codepfad `night:444-448` Reihenfolge. Test: brennender Fenrir Stufe 3 gelyncht → Nachbarn sterben ja/nein laut PO.
- Legacy-Status: legacy-contradictory. Der Code ist nicht offensichtlich defekt, setzt aber eine deutlich engere Regel um (nur Lynch, Zählung bei Nachtbeginn, zusätzliche Ritter-Immunität); F15 ist ein Nebenfehler.
- Automationsvorschlag: automatic (nach PO-Entscheidung).
- Mechanikfamilie primär + sekundär: Hinrichtungsreaktion (Legacy) bzw. sonstige Spezialmechanik (Text: Extraleben) + Einmalfähigkeit.
- Benötigte vorhandene Godot-Systeme: KillPipeline (Abfangregel mit Verbrauch), ExecutionRules (falls nur Lynch), Reaktionswarteschlange (Ritter-Zielauswahl), InfoRecord/Ereignis (gm), StateCodec, Replay, GmCorrections (Stufe setzen).
- Benötigte NEUE Systeme: mehrere Leben / Einmal-Überleben als persistenter Marker; Nachtzähler pro Person (Stufe).
- Abhängigkeiten von anderen Rollen: Ritter, Henker (LynchCount), Feuerteufel (Brand), Lehrling/Seelentauscher/Frankenstein (Rollenerwerb mit alter Stufe), alle Tötungsrollen.
- Komplexität und Fehlerrisiko: M / mittel. Eine Abfangregel plus Zähler; Risiko in der Reihenfolge mit anderen Schilden.
- Offene Entscheidungen:
  1. Überlebt Fenrir jede Todesursache oder nur Hinrichtung?
  2. Zählt die Stufe bei Nachtbeginn oder nach überlebter Nacht?
  3. Ist Fenrir ab Stufe 3 für den Ritter immun, und wenn ja, dauerhaft oder als Teil des Einmal-Schutzes?
  4. Zählt ein abgewehrter Lynch als Lynch (Henker, Log)?
  5. Soll die Stufe für den SL sichtbar sein?
- Relevante Testgruppen:
  - Normalfall: Nächte 1-3 gestartet, Tag 3 Lynch auf Fenrir → überlebt, zweiter Lynch → stirbt.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: Fenrir tot → Stufe steigt nicht weiter.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Fenrir → je eigene Stufe und eigener Schutz (Soll) vs. gemeinsam (Legacy).
  - Wiederbelebung: wiederbelebter Fenrir → Stufe und Schutz laut Entscheidung.
  - Rollenwechsel: Lehrling wird Fenrir, nachdem der erste Fenrir mit Stufe 3 starb → Stufe startet bei 0 (Soll pro Person).
  - Save/Load: Stufe 2 speichern, laden, Nacht starten → Stufe 3.
  - Replay: identische Stufe.
  - SL-Korrektur: SL setzt Stufe manuell.
  - Sichtbarkeit: Rettung als gm-Ereignis; öffentlich nur "Lynch scheitert".
  - Schutz: Nachtangriff Stufe 3 → überlebt (Text) / stirbt (Legacy).
  - Todesreaktionen: Ritter stirbt nachts, Fenrir ist nächster Wolf, Stufe 3 → Verhalten laut Entscheidung.
  - Siegprüfung: Fenrir überlebt Lynch → keine Siegprüfung ausgelöst.
  - beschädigter Spielstand: `fenrirStage` fehlt → als 0 behandelt.
- Belegsicherheit: hoch.

---

### blutwolf
- DE-Name / EN-Name: Blutwolf / Blood Wolf (`roles:174`).
- Aliase/Altnamen: keine. Bild DE `Blutwolf.webp`, EN `Blood_Wolf.webp` (`gh:830`, `app/src/roleCard.ts:62`). Marker "V<n>".
- Legacy-ID (String in ALL_ROLES): "Blutwolf".
- Fraktion: wolf, in `WOLF_KILL_ROLES`.
- Akte (akte.js): Akt II (`js/core/akte.js:39`).
- Nachtpriorität und Bedingungen: kein Nachtschritt; passiv.
- Quelltextstellen:
  - `roles:100`, `roles:249`, `js/core/role-abilities.js:46`.
  - `ui:18` `voteWeight(seat)`: 1 + tote direkte Sitznachbarn (Index `id-1±1` modulo n).
  - `ui:109` `markerList`: Marker "V"+Gewicht, wenn Gewicht > 1 (auch wenn der Blutwolf selbst tot ist, keine Lebend-Prüfung).
  - `js/ui/field-viewmodel.js:55`, `js/ui/field-pixi.js:433-436`: Marker wird gezeichnet.
  - `night:350` ruft `showBlutwolfInfo` nur, wenn definiert; die Funktion existiert nirgends (grep über js, game.html, app).
- Text DE (wörtlich): "Seine Stimme zählt +1 für jeden direkten toten Nachbarn."
- Text EN (wörtlich): "Their vote counts +1 for each directly adjacent dead neighbor."
- DE/EN-Vergleich: JA, semantisch gleich (+1 je direkt benachbartem Toten).
- Weitere Texte: keine i18n-Schlüssel. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Es gibt keine Stimmabgabe in der App; Lynch = direkte SL-Wahl (`night:421-422`).
  2. Die App berechnet das Gewicht korrekt nach Text (max. 3) und zeigt es als Marker "V2"/"V3" am Sitz. Der SL muss es beim physischen Zählen berücksichtigen.
  3. Nachbarn = feste Sitzindizes, tote Nachbarn werden nicht übersprungen ("direkt").
  4. Mehrere Kopien: pro Sitz berechnet.
  5. Zufall: keiner. Sichtbarkeit: Marker für SL im Spielfeld.
- React-Version: kein eigenes Verhalten; Marker "V<n>" wird als Textmarker durchgereicht (`app/src/components/DomBoard.tsx:53-55,555`, `app/src/adapter/types.ts:17,73`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-44 (`04:73`): "fehlend", `ui:18,109`, "nur Anzeige, `showBlutwolfInfo` undefiniert". Fakten bestätigt. Status "fehlend" teilweise widerlegt: Die im Text beschriebene Rechenregel existiert und wird angezeigt; es fehlt nur die (für alle Rollen fehlende) digitale Stimmzählung.
  - 01 F13 bestätigt (`night:350`).
  - 07 Q2 und DECISION-LOG (`DECISION-LOG.md:9,23`): Stimmen bleiben physisch, keine digitale Speicherung. `docs/specs/vertical-slice/role-selection.md:93` schließt Blutwolf deshalb aus. Bestätigt, Godot hat bewusst kein Stimmfeld (`godot/README.md:54,126`).
- Widersprüche: keine echten zwischen Text und Code (Rechenregel stimmt). Offener Punkt ist nur die Produktentscheidung zur Stimmerfassung (07 Q2), kein Widerspruch.
- Bugs:
  1. `showBlutwolfInfo` nie definiert (F13). Einstufung: technische Altlast. Codepfad `night:350`. Tatsächlich: kein Hinweis am Morgen. Erwartet: vermutlich Info zum neuen Gewicht. Risiko: niedrig. Test: Nachbar stirbt nachts → Morgenübersicht nennt neues Blutwolf-Gewicht.
  2. Marker auch bei totem Blutwolf. Einstufung: technische Altlast. Codepfad `ui:109`. Test: toter Blutwolf mit totem Nachbarn → kein Stimmgewicht-Marker.
- Legacy-Status: legacy-verified. Der Code setzt die Rechenregel des Textes nachvollziehbar als SL-Anzeige um; das Fehlen einer digitalen Abstimmung ist eine globale Produktentscheidung, keine Rollenlücke.
- Automationsvorschlag: assisted (Gewicht anzeigen; Zählen bleibt physisch laut DECISION-LOG).
- Mechanikfamilie primär + sekundär: sonstige Spezialmechanik (Stimmgewicht) + Sitzpositionsmechanik.
- Benötigte vorhandene Godot-Systeme: `seat_order` (Sitzreihenfolge aus `StartGame`), InfoRecord/Ereignis (gm-Hinweis), StateCodec.
- Benötigte NEUE Systeme: Sitznachbarschaft als abgeleitete Abfrage (links/rechts in `seat_order`, auch über Tote); Stimmsystem nur, falls 07 Q2 Option B gewählt wird.
- Abhängigkeiten von anderen Rollen: alle Tötungen neben dem Blutwolf; indirekt Korrupter Richter und Hades (gleiche Stimmfamilie).
- Komplexität und Fehlerrisiko: S / niedrig (als Anzeige); L, falls Stimmsystem.
- Offene Entscheidungen:
  1. Reicht eine SL-Anzeige des Gewichts (ohne Stimmerfassung)?
  2. Zählen tote Nachbarn, auch wenn später wiederbelebt (live berechnet)?
  3. Gilt das Gewicht auch, wenn der Blutwolf tot ist und Tote abstimmen dürfen (Nekromant-Kontext)?
- Relevante Testgruppen:
  - Normalfall: linker Nachbar tot → Anzeige Gewicht 2.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: beide Nachbarn tot → 3.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Blutwölfe nebeneinander, einer tot → der andere hat Gewicht 2.
  - Wiederbelebung: Nachbar wiederbelebt → Gewicht sinkt.
  - Rollenwechsel: Sitz wird Blutwolf → Anzeige erscheint.
  - Save/Load: nicht relevant, weil abgeleiteter Wert ohne eigenen Zustand (nur prüfen, dass nach Laden gleich).
  - Replay: nicht relevant, weil abgeleitet.
  - SL-Korrektur: SL korrigiert Tod des Nachbarn → Gewicht passt sich an.
  - Sichtbarkeit: Gewicht nur gm.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant, weil keine Reaktion.
  - Siegprüfung: nicht relevant, weil keine Siegwirkung.
  - beschädigter Spielstand: Sitzordnung mit Lücke → Nachbarn aus `seat_order`, kein Absturz.
- Belegsicherheit: hoch.

---

### albtraumwolf
- DE-Name / EN-Name: Albtraumwolf / Nightmare Wolf (`roles:175`).
- Aliase/Altnamen: keine Migration. Schreibvariante "Alptraum" in der Laufzeitübersetzung (`i18n.js:918` "Alptraum" → "Nightmare"). Bild DE `Albtraumwolf.webp`, EN `Nightmare_Wolf.webp` (`gh:831`, `app/src/roleCard.ts:63`). State `meta.blockedTonight`, `state.once.BlockedRolesTonight`. i18n `nightmareBlocked` (`i18n.js:222` DE, `551` EN, `856`).
- Legacy-ID (String in ALL_ROLES): "Albtraumwolf".
- Fraktion: wolf, in `WOLF_KILL_ROLES`.
- Akte (akte.js): Akt III (`js/core/akte.js:60`) und Akt IV (`js/core/akte.js:82`).
- Nachtpriorität und Bedingungen: tier 2.1, kein once (`roles:17`); Schritt jede Nacht inkl. Nacht 1, solange ein Albtraumwolf lebt.
- Quelltextstellen:
  - `roles:17`, `roles:101`, `roles:250`, `js/core/role-abilities.js:44`.
  - `chunk:288-303` Handler: Pick auf lebenden Nicht-Wolf (`!isWolf`), setzt `s.meta.blockedTonight=true` und fügt die Rolle zu `BlockedRolesTonight` hinzu.
  - `ab:97-99` `onOrderClick`: blockiert jede Rolle in `BlockedRolesTonight` und jede Rolle mit einem lebenden blockierten Sitz.
  - `night:334` `resolveDayKills`: `nightTargets` ohne Sitze mit `blockedTonight` (F3).
  - `night:145-147` `onNightStart` und `night:508-509` `resetNightState`: Reset.
- Text DE (wörtlich): "Blockiert jede Nacht die Fähigkeit eines Dorfbewohners."
- Text EN (wörtlich): "Each night, blocks the ability of one villager."
- DE/EN-Vergleich: JA, semantisch gleich (jede Nacht, eine Person, Dorfbewohner/villager).
- Weitere Texte: Prompt "Albtraumwolf ... blockiere 1 Dorfbewohner" hartkodiert DE (`chunk:289`), Teilübersetzung "blockiere" → "block" (`i18n.js:887`). Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: tier 2.1, direkt nach dem Rudel. Rollen mit kleinerem tier (Schutzengel 1.3, Korrupter Richter 1.5, Dorfschmied 1.7, Nacht-1-Rollen) haben bereits gehandelt; ihre Blockade wirkt in dieser Nacht nicht mehr.
  2. Ziel: lebender Nicht-Wolf (`!isWolf`), also Dorf UND Solo; Verfluchte (Dämon) nicht wählbar. Selbstwahl unmöglich.
  3. Wirkung: die gesamte Rolle wird für die Nacht blockiert (alle Kopien, z. B. alle "Die Gebundenen"), nicht nur der Sitz.
  4. Nebenwirkung F3: der blockierte Sitz fällt aus `nightTargets` und überlebt damit Rudelangriff, Rudelvater-Zusatzopfer und Schicksalswolf-Zusatzopfer dieser Nacht (`night:239-248`, `night:334`). Sofort-Tode (Hexe, Hades usw.) und Witwe betrifft das nicht.
  5. Mehrfachnutzung: keine Sperre gegen erneutes Klicken, mehrere Rollen pro Nacht blockierbar; `markStarUsed` (`night:578-586`) ist nur optisch.
  6. Verbrauch: keiner, jede Nacht neu.
  7. Sichtbarkeit: Blockade nur SL ("Keine Fähigkeit (Albtraum)").
  8. Mehrere Kopien: ein Schritt pro Rolle, jeder Klick blockiert eine weitere Person.
  9. Zufall: keiner.
  10. Blockaden bleiben tagsüber bestehen bis `onNightStart`.
- React-Version: kein eigenes Verhalten (nur Bild).
- Bisherige Doku und Prüfergebnis:
  - 04 A-45 (`04:74`): "widersprüchlich (Bug F3)", `chunk:288-303`, `ab:97-99`, Akzeptanz "darf das Opfer nicht vor Wölfen schützen". Bestätigt, F3 bei `night:334` bestätigt.
  - 01 F3 und 07 Q1 Teil 2 ("Albtraumwolf rettet Opfer" wird ohne Rückfrage behoben). Bestätigt.
  - 04 B-6 "Albtraumwolf (Rolle)" bestätigt: Blockade nach Rollenname.
  - `ROLE-FLOW-REPORT.md:46` "14 wählbar = nur Dorf": widerlegt als allgemeine Aussage, Filter ist `!isWolf`, Solos sind wählbar (der Bericht hatte vermutlich keine Solos im Test).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ziele | "eines Dorfbewohners" | "one villager" | jeder Nicht-Wolf inkl. Solo (`chunk:301`) | keine | nicht dokumentiert (Bericht behauptet "nur Dorf") | nur Fraktion Dorf | alle Nicht-Wölfe | mittel | Zielfilter | alle Nicht-Wölfe (Solos sind Gegner der Wölfe), Text anpassen | Ja |
| Umfang | "die Fähigkeit eines Dorfbewohners" | "the ability of one villager" | ganze Rolle, alle Kopien (`chunk:294-296`, `ab:97`) | keine | 04 B-6 "(Rolle)" | nur die gewählte Person | alle Personen der Rolle | mittel bei Mehrfachrollen | Blockade pro Person vs. pro Rolle | nur die Person | Ja |
| Anzahl pro Nacht | "eines" | "one" | beliebig oft klickbar | keine | nicht dokumentiert | genau eine | beliebig | hoch bei Missbrauch | Schritt einmal pro Nacht | genau eine | Nein |
| Späte Wirkung | - | - | wirkt nicht auf bereits erledigte Schritte (tier < 2.1) | keine | nicht dokumentiert | Albtraumwolf handelt vor Dorfrollen | Blockade nur für spätere Schritte | mittel: Schutzengel nie blockierbar | Nachtreihenfolge | tier vor Gruppe B verschieben oder Text präzisieren | Ja |

- Bugs:
  1. Blockade schützt vor Wolfsangriff (F3). Einstufung: echter Bug. Codepfad `night:334`. Tatsächlich: Albtraumwolf blockiert Sitz 5, Rudel wählt Sitz 5 → Sitz 5 lebt am Morgen. Erwartet (04 Akzeptanz, 07 Teil 2): Sitz 5 stirbt. Risiko: hoch. Test S-ROLE-45b.
  2. Mehrfachblockade pro Nacht. Einstufung: unklare Regel / technische Altlast (allgemeines Wiederklick-Verhalten der Nachtleiste). Codepfad `chunk:288-303` ohne Sperre. Test: zweiter Klick in derselben Nacht → abgelehnt.
- Legacy-Status: legacy-broken. F3 verfälscht die Kernwirkung: die Blockade wird zum Schutz gegen das eigene Rudel.
- Automationsvorschlag: automatic.
- Mechanikfamilie primär + sekundär: sonstige Spezialmechanik (Einzelblockade) + globale Regeländerung (Blockade bis Nachtende).
- Benötigte vorhandene Godot-Systeme: StepQueue (Schritt-Status `blocked(reason)`), PendingPrompt, Ereignis-Sichtbarkeit, StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Rollenblockierung (pro Person, mit Ablauf zum Nachtende).
- Abhängigkeiten von anderen Rollen: alle Nicht-Wolf-Nachtrollen mit tier > 2.1; Schattenhund/Zeitwächter/Der Weise (gleiche Blockadefamilie); Dämonischer Wolf (Verfluchte nicht wählbar); Rudel (F3).
- Komplexität und Fehlerrisiko: S / mittel.
- Offene Entscheidungen:
  1. Dürfen Solos blockiert werden?
  2. Person oder ganze Rolle?
  3. Soll der Albtraumwolf vor den Dorf-Schutzrollen handeln (tier), damit Schutzengel blockierbar ist?
  4. Wirkt eine Blockade auch auf Morgen- und Todesreaktionen der Person?
- Relevante Testgruppen:
  - Normalfall: blockiert Orakel → Orakel-Schritt blockiert.
  - ungültiges Ziel: Wolf oder Verfluchter nicht wählbar.
  - tote Person: nicht wählbar.
  - Selbstwahl: nicht möglich.
  - mehrere Kopien: zwei Albtraumwölfe → je eine Blockade.
  - Wiederbelebung: nicht relevant, weil Blockade nur eine Nacht gilt.
  - Rollenwechsel: blockierte Person wechselt nachts die Rolle → Blockade bleibt an der Person.
  - Save/Load: Blockade speichern/laden → weiterhin blockiert.
  - Replay: identisch.
  - SL-Korrektur: SL hebt Blockade auf.
  - Sichtbarkeit: nur gm.
  - Schutz: blockierter Sitz ist Rudelziel → stirbt (S-ROLE-45b).
  - Todesreaktionen: blockierter Sensenträger stirbt nachts → Reaktion laut Entscheidung.
  - Siegprüfung: nicht relevant, weil keine Siegwirkung.
  - beschädigter Spielstand: `BlockedRolesTonight` mit unbekannter Rolle → ignoriert.
- Belegsicherheit: hoch.

---

### cerberus
- DE-Name / EN-Name: Cerberus / Cerberus (`roles:176`).
- Aliase/Altnamen: keine. Bild DE `Cerberus.webp`, EN `Cerberus.webp` (`gh:831`, `app/src/roleCard.ts:64`). Feld `meta.cerbHeads` (Default in `state:5`, `state:10`, `index.html:378`, `gh:517`, `gh:579`, `gh:927`, `gh:1004`, `gh:2572`). Marker "×N".
- Legacy-ID (String in ALL_ROLES): "Cerberus".
- Fraktion: wolf, in `WOLF_KILL_ROLES`.
- Akte (akte.js): Akt IV (`js/core/akte.js:81`).
- Nachtpriorität und Bedingungen: kein ORDER_BASE-Eintrag; zusätzlich in der Passiv-Menge `night:96`, also nie ein Schritt.
- Quelltextstellen:
  - `roles:102`, `roles:251`, `js/core/role-abilities.js:47`.
  - `night:148` `onNightStart`: jeder lebende Cerberus +1 Kopf, max. 3.
  - `night:449` `doLynchFlow`: Köpfe ≥3 → Köpfe 0, `return` (kein `applyKill`, kein `finalizeLynch`, keine Meldung).
  - `help:265` `witchDeadlyFatePick`: Köpfe ≥3 → Köpfe 0, `return` vor `WaldhexeD=true`.
  - `ui:109` `markerList`: "×N" bei N>0.
- Text DE (wörtlich): "Baut Köpfe auf (bis zu 3); bei 3 kann er eine Lynchung abwehren."
- Text EN (wörtlich): "Builds up to 3 heads; at 3 heads, can block a lynch."
- DE/EN-Vergleich: JA, semantisch gleich (bis 3 Köpfe, bei 3 eine Lynchung abwehren, "kann"/"can").
- Weitere Texte: keine i18n-Schlüssel. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Aufbau: +1 bei jedem Nachtbeginn, solange er lebt (Nacht 1 → 1, Nacht 3 → 3). Kein Schutz gegen doppeltes "Nacht starten".
  2. Lynch bei 3 Köpfen: automatisch abgewehrt (keine Wahl), Köpfe auf 0; Brand-Ausbreitung eines brennenden Cerberus läuft vorher trotzdem (`night:444-446`); LynchCount/Henker entfallen (F15); keine Meldung/kein Log.
  3. Direkt danach kann der SL erneut lynchen (keine Tagessperre), dann stirbt Cerberus mit 0 Köpfen.
  4. Wiederaufbau: nach drei weiteren Nachtbeginnen erneut 3, also mehrfach nutzbar.
  5. Hexen-Todestrank bei 3 Köpfen: ebenfalls abgewehrt, Köpfe 0, Trank der Hexe NICHT verbraucht (Rückkehr vor `WaldhexeD=true`), Hexe kann erneut wählen.
  6. Alle anderen Todesarten: kein Schutz.
  7. Mehrere Kopien: Köpfe pro Sitz.
  8. Sichtbarkeit: Marker "×N" für SL.
  9. Zufall: keiner.
  10. Rollenwechsel: `cerbHeads` hängt am Sitz; wechselt ein Sitz zu Cerberus, übernimmt er den vorhandenen (meist 0) Wert.
- React-Version: kein eigenes Verhalten; Marker "×N" als Textmarker (`app/src/components/DomBoard.tsx:53-55,555`).
- Bisherige Doku und Prüfergebnis:
  - 04 A-46 (`04:75`): "verifiziert", `night:148,449`, `help:265`, "+1 Kopf je Nacht (max 3); bei 3 Köpfen überlebt er Lynch/Hexengift, Köpfe → 0". Fakten bestätigt. Status "verifiziert" widerlegt: Text nennt nur Lynch und "kann" (Wahl), Code wehrt automatisch ab und zusätzlich das Hexengift; F15 betrifft die Rolle; Hexe verliert ihren Trank nicht.
  - 04 A-4 Waldhexe "Voodoo/Cerberus wie Legacy" und 04 C (`04:143`) "Cerberus (Lynch, Hexe) widersprüchlich (A-36)": in sich widersprüchlich zu A-46 "verifiziert".
  - 01 F15 bestätigt.
  - `NIGHT-REPORT-abilities.md:88` "passiv" bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Wahl oder Automatik | "kann er ... abwehren" | "can block" | automatisch (`night:449`) | keine | 04 A-46 "überlebt" | Cerberus entscheidet (Prompt) | automatisch | mittel: Wahl erlaubt Bluff/Aufsparen | Prompt in ExecutionRules | Prompt an SL "Cerberus wehrt ab?" | Ja |
| Hexengift | nur Lynchung | nur lynch | auch Hexen-Todestrank (`help:265`) | keine | 04 A-4/A-46 übernehmen es | nur Lynch | jede Hinrichtung/gezielte Tötung | mittel | zusätzliche Abfangregel | nur Lynch (Text) | Ja |
| Aufbau | "Baut Köpfe auf" | "Builds up" | +1 bei Nachtbeginn | keine | 04 "+1 je Nacht" | pro Nachtbeginn | pro überlebter Nacht | gering | Zeitpunkt | wie Fenrir einheitlich festlegen | Nein |

- Bugs:
  1. Lynch-Abwehr überspringt `finalizeLynch` (F15). Einstufung: echter Bug. Codepfad `night:449`. Test: Cerberus 3 Köpfe gelyncht → LynchCount laut Entscheidung, Henker-Markierte hingerichtet.
  2. Hexentrank nicht verbraucht bei Abwehr. Einstufung: unklare Regel (Text nennt Hexe nicht). Codepfad `help:265` Rückkehr vor `WaldhexeD=true`. Tatsächlich: Hexe kann denselben Trank noch einmal einsetzen. Risiko: mittel. Test: Hexe wirft Trank auf Cerberus mit 3 Köpfen → Trank verbraucht (oder Abwehr entfällt laut PO).
  3. Stille Abwehr. Einstufung: technische Altlast. Codepfad `night:449`. Test: Ereignis "Cerberus wehrt Lynch ab" (gm/public laut PO).
- Legacy-Status: legacy-contradictory. Kopfaufbau und Lynch-Abwehr funktionieren, aber Wahlfreiheit ("kann"), Zusatzwirkung gegen Hexe und F15 weichen vom Text ab; 04 "verifiziert" ist zu optimistisch.
- Automationsvorschlag: automatic (mit optionalem Bestätigungsprompt, falls "kann" als Wahl gilt).
- Mechanikfamilie primär + sekundär: Hinrichtungsreaktion + sonstige Spezialmechanik (aufladbarer Zähler).
- Benötigte vorhandene Godot-Systeme: ExecutionRules (Abfangregel vor Hinrichtung), Nominations/Execution-Ereignisse, PendingPrompt (falls Wahl), StateCodec, Replay, GmCorrections (Köpfe setzen), Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: dauerhafte Statusmarker bzw. Zähler pro Person (Köpfe, mit Aufladung bei Phasenwechsel).
- Abhängigkeiten von anderen Rollen: Waldhexe (Trank), Henker (LynchCount), Feuerteufel (Brand beim Lynch), Kopfgeldjäger (Lynch eines Wolfs), Spiegelwolf/Voodoo/Der Weise (Reihenfolge der Lynch-Sonderzweige `night:425-501`).
- Komplexität und Fehlerrisiko: S / mittel.
- Offene Entscheidungen:
  1. Automatische Abwehr oder Wahl?
  2. Auch gegen Hexengift oder andere gezielte Tötungen?
  3. Zählt eine abgewehrte Lynchung für Henker/Log als Lynch?
  4. Darf am selben Tag nach einer Abwehr erneut gelyncht werden?
  5. Köpfe pro Nachtbeginn oder pro überlebter Nacht?
- Relevante Testgruppen:
  - Normalfall: 3 Nachtbeginne, Lynch → abgewehrt, Köpfe 0.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: toter Cerberus → Köpfe steigen nicht.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Cerberus mit unterschiedlichen Köpfen.
  - Wiederbelebung: wiederbelebter Cerberus → Köpfe laut Entscheidung (Legacy: alter Wert am Sitz).
  - Rollenwechsel: Sitz wird Cerberus → startet mit 0.
  - Save/Load: Köpfe 2 speichern, laden, Nacht starten → 3.
  - Replay: identisch.
  - SL-Korrektur: SL setzt Köpfe.
  - Sichtbarkeit: Köpfe gm; Abwehr-Ereignis laut PO.
  - Schutz: Nachtangriff bei 3 Köpfen → stirbt.
  - Todesreaktionen: Hexentrank bei 3 Köpfen → Verhalten laut Entscheidung, Trankverbrauch geprüft.
  - Siegprüfung: abgewehrter Lynch löst keine Siegprüfung aus.
  - beschädigter Spielstand: `cerbHeads` > 3 oder fehlt → auf 0..3 begrenzt.
- Belegsicherheit: hoch.

---

## Gruppenübergreifende Beobachtungen

1. **Nur drei der acht Rollen haben einen Nachtschritt** (Schattenhund 0.7 once, Albtraumwolf 2.1, Schwarze Witwe 2.8). Dämonischer Wolf und Besessener Wolf sind reine Todesreaktionen, Fenrir und Cerberus reine Hinrichtungs-Abfangregeln, Blutwolf eine reine Anzeige. `NIGHT-REPORT-abilities.md:76,84` beschreibt Dämon und Besessenen fälschlich als Nachtaktion mit Ziel.
2. **F2 betrifft zwei Rollen dieser Gruppe**: Schwarze Witwe und Schattenhund fehlen in `WOLF_KILL_ROLES` (`night:50`). Leben nur sie als Wölfe, gibt es keine Rudeltötung. 01 F2 nennt als Beispiele nur Siegreicher Wolf, Giftwolf, Wolfskind.
3. **Pick-Abbruch ohne Callback** (`ui:315`, `ui:325`) ist ein gemeinsamer Fehlerpfad für Dämonischer Wolf und Besessener Wolf: Nachtauflösung bleibt stehen; beim Besessenen wird zusätzlich die persistierte Sperre `_besessenerDraining` nie gelöst. In Godot: Reaktionen persistent, nicht abbrechbar oder mit explizitem Verzicht (die Godot-Reaktionswarteschlange ist laut README bereits "nicht überspringbar/abbrechbar").
4. **Reaktionen außerhalb einer Warteschlange**: Dämon (`night:289`, `night:501`), Besessener (`night:312`), Rudelvater (`night:270`), Nekromant (`night:369`) und Märtyrerin (Overlay) öffnen jeweils eigene Picks; synchrone Folgeaufrufe können einen offenen Pick ersetzen. Morgen-Tode (Witwe, Giftwolf) rufen `postDeathHooks` vor der eigentlichen Auflösung auf und starten so den Besessenen-Drain zu früh.
5. **F15 gilt für Fenrir und Cerberus gemeinsam**; beide Abfangregeln sind stumm (keine Meldung, kein Log) und liegen hinter der Brand-Ausbreitung (`night:444-449`). Beide zählen ihren Zustand bei Nachtbeginn hoch (`night:136`, `night:148`), ohne Sperre gegen doppeltes "Nacht starten". Einheitliche Godot-Lösung: ExecutionRules-Abfangschritt mit Ereignis und einheitlichem Zählzeitpunkt.
6. **`isWolf` mit `cursedWolfAura`** (`core:18`) macht den Dämonen-Fluch zu einer echten Fraktionsänderung für über zehn Leser (Siegprüfung, Ritter, Detektiv, Schmied, Kopfgeldjäger, Orakel, Doktor, Waldläufer, Traumdeuter, Totenkarten), während `ab:75` im selben Code das Gegenteil behauptet. Godot trennt bereits `counts_as_wolf` und `appears_as`; die PO-Entscheidung Q1 bestimmt, welches Feld der Fluch setzt.
7. **Blockadefamilie** (Schattenhund, Albtraumwolf, plus Zeitwächter und Der Weise aus anderen Gruppen): alle wirken ausschließlich in `onOrderClick` (`ab:93-99`), also nie auf Morgenauflösung oder Todesreaktionen, und alle filtern über "nicht in `WOLF_ROLES_SET`" statt über Fraktion Dorf. Eine gemeinsame Godot-Komponente "Rollenblockierung" mit Fraktions- und Personenfilter und Ablauf zum Nachtende deckt beide Rollen ab.
8. **Fehler bzw. Ungenauigkeiten in 04**:
   - A-35 Besessener Wolf "verifiziert": widerlegt (F12 zeigt Rohschlüssel in beiden Sprachen, Abbruch-Sperre, Liebeskummer-Verzögerung).
   - A-46 Cerberus "verifiziert": widerlegt (Wahl vs. Automatik, Hexengift nicht im Text, Hexentrank wird nicht verbraucht, F15); zudem inkonsistent zu 04 C (`04:143`), wo Cerberus als widersprüchlich geführt wird.
   - A-44 Blutwolf "fehlend": teilweise widerlegt, die Rechenregel existiert als SL-Anzeige; fehlend ist nur die globale Stimmerfassung, die laut DECISION-LOG bewusst physisch bleibt.
   - A-21 Schwarze Witwe: ergänzen um EN-Zeitpunkt, `loverId`-Phantompaar nach `clearRolesNewRound` und Zeitwächter-Reihenfolge.
   - 01 F12 Formulierung "Rohschlüssel" korrekt, der dort implizit angenommene DE-Fallback wird nie angezeigt.
9. **Rundenwechsel-Reset unvollständig** (`gh:512-528`, Kopie `app/public/legacy-bridge.js:36-47`): `meta.loverId`, `WidowMorningKills`, `besessenerWolfPending`, `_besessenerDraining`, `SchattenhundBlocked` werden nicht zurückgesetzt. Für Godot irrelevant, sofern jede Runde einen frischen Zustand erhält, aber als Testfall "neue Runde übernimmt keine ausstehenden Effekte" aufnehmen.
10. **Math.random**: in keinem Handler dieser acht Rollen. Indirekt betroffen ist nur der Dämonen-Fluch über Zufallsauswahlen anderer Rollen unter allen `isWolf`-Sitzen (Detektiv `core:71`, Schmiede-Waffe `night:385`, Blutpriester `chunk:703`).
11. **React-Version**: für alle acht Rollen nur Bildzuordnung (`app/src/roleCard.ts:39-64`) und Durchreichen der Textmarker "×N"/"V<n>"; kein eigenes Regelverhalten.
12. **Nicht ausgeführt**: Alle Aussagen stammen aus Codelesung. Die Ablaufketten mit Picks (Abbruch, Morgen-Drain-Kollision, Liebeskummer-Verzögerung) sollten vor einer endgültigen Einstufung einmal im Browser nachgestellt werden.
