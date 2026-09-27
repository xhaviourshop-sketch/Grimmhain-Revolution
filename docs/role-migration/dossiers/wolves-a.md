<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G1 Wölfe A: Legacy-Rollenprüfung (nur gelesen, Stand Repo 2026-09-26)

Konventionen: Pfadkürzel wie im Auftrag (`roles`, `chunk`, `ab`, `help`, `night`, `core`, `ui`, `state`, `gh`). Gedankenstriche aus Originaltexten werden als `(U+2014)` wiedergegeben, weil die Ausgabe keine Em-Dashes enthalten soll; sonst sind die Zitate wörtlich.

Gemeinsame Befunde, die für mehrere Rollen gelten (Details unten und im Schlussabschnitt):
- Alle acht Rollen stehen in `WOLF_ROLES_SET` (`roles:391-396`), keine in `SOLO_ROLES_SET` (`roles:399-403`); `getRoleFaction` (`roles:405-409`) liefert für alle "wolf".
- Blockaden in `onOrderClick` (`ab:71-124`): Schattenhund, Zeitwächter und Der-Weise-Debuff blockieren nur Nicht-Wolfsrollen (`ab:92-95`, `isWolfRole=WOLF_ROLES_SET.has(role)`), also nie diese Rollen. Albtraum blockiert sie trotzdem (`ab:96-98`, `BlockedRolesTonight` bzw. `meta.blockedTonight`).
- F2 bestätigt: `WOLF_KILL_ROLES` (`night:50`) enthält nur Rachsüchtiger Wolf und König Lykaon aus dieser Gruppe. Leben nur Siegreicher Wolf, Seuchenwolf, Schicksalswolf, Schattenwanderer, Giftwolf oder Rudelvater (ohne "Werwolf"), fehlt die Rudel-Tötungszeile (`night:51-55`).
- Kein `Math.random` in den Handlern `chunk:310-448`. Indirekt: `detectiveEmitPublicClue` (`core:66-83`, `Math.random` Z.71) feuert bei jedem Wolfstod (`core:152`), Orakel zeigt für Trugbilderwolf eine Zufallsrolle (`chunk:240-249`).
- Neue Runde über "Rollen leeren" (`gh:512-529` `clearRolesNewRound`, wörtlich kopiert in `app/public/legacy-bridge.js:34-51`) setzt `s.meta` per `Object.assign({},s.meta,{...})` zurück und behält dabei `shadowSwapPartnerId`, `giftwolfDieOnMorning`, `giftwolfPoisoned`; `GiftwolfUses` und `FateWolfExtraIds` werden nicht zurückgesetzt. Der normale Setup-Weg (`setup.html:1127-1160`) erzeugt dagegen frischen Zustand per `createState`.

---

### rachsuechtiger-wolf
- DE-Name / EN-Name: Rachsüchtiger Wolf / Lone Wolf (`roles:150`).
- Aliase/Altnamen: "Weißer Werwolf" (Migration `state:18` `migrateLegacyRoleIds`); interne Schlüssel `WhiteWolfCooldown`, `WhiteWolfUsedTonight`, i18n `whiteWolf*`/`noWhiteWolfActive` (`i18n:201-204`, EN `i18n:530-533`); EN-Kartenbild `assets/cards/en/Vengeful_Wolf.webp` existiert (md5-identisch mit DE-Karte), ist aber weder in `gh:817ff` `CARD_MAP_EN` noch in `app/src/roleCard.ts:19ff` gemappt (EN fällt auf DE-Karte zurück, `roleCard.ts:5-6`). Toter Altpatch `WhiteWolfCharges` entfernt (`gh:2249-2250`).
- Legacy-ID: "Rachsüchtiger Wolf".
- Fraktion: "wolf" (`roles:392`, `roles:405-409`). Nicht in `SOLO_ROLES_SET`. `isWolf` true (`core:8-19`) → zählt zur Wolfsparität in `checkWinConditions` (`core:218-239`) und `checkTeamWin` (`core:287-337`). Kein Einzelsiegcode (bestätigt `01:97`, `04` D-5).
- Akte: akt1, akt2, akt3, akt4 (`akte.js:20,39,60,81`) sowie custom.
- Nachtpriorität: tier 2.2, kein `once` (`roles:18`). Zeile erscheint jede Nacht, solange ein Rachsüchtiger Wolf lebt (`night:89-94` `hasAliveRole`); kein Abklingzeit-Filter in `rebuildOrder`. In `WOLF_KILL_ROLES` (`night:50`): lebt kein "Werwolf", wird eine synthetische Werwolf-Zeile (tier 2.0) erzeugt (`night:51-55`).
- Quelltextstellen:
  - `roles:76` DE-Text, `roles:225` EN-Text, `role-abilities.js:52` DE-Text (identisch).
  - `chunk:310-363` Handler "Rachsüchtiger Wolf": Abklingzeit-Prüfung, Lebend-Prüfung, UsedTonight, Ja/Nein-Dialog, Zielwahl, Schutzverbrauch, `targeted=true`, `WhiteWolfCooldown=3`.
  - `night:140` `onNightStart`: `WhiteWolfCooldown=max(0,cd-1)`; `night:158` `WhiteWolfUsedTonight=false`.
  - `night:322-402` `resolveDayKills`: Ziel stirbt als `NIGHT_KILL` (`night:393-394`).
  - `gh:525` (`clearRolesNewRound`) und `gh:558` (`resetOnce`) setzen Cooldown/UsedTonight zurück.
  - `chunk:162` Werwolf-Handler löscht bei erneutem Klick alle `targeted` (auch das des Rachsüchtigen).
  - `roles:131` Doppelspion-Text: "Der Angriff des Rachsüchtigen Wolfs verpufft an ihm."
- Text DE (wörtlich): "Jedermann ist dein Feind. Du wachst neben den Werwölfen zusätzlich jede dritte Nacht auf und hast die Möglichkeit, einen anderen Werwolf zu reißen. Du willst alleine gewinnen."
- Text EN (wörtlich): "Everyone is your enemy. In addition to the werewolves, you wake up every third night and may kill another werewolf."
- DE/EN-Vergleich: NEIN. EN fehlt der Satz "Du willst alleine gewinnen" (Siegziel fehlt komplett). Rest (jede dritte Nacht, anderer Werwolf, zusätzlich) gleich.
- Weitere Texte: i18n `whiteWolfWait` "Noch {n} Nacht(e) warten." Hartkodierte DE-Dialogtexte "Jetzt töten?", "Nein", "Ja  (U+2014) Ziel wählen" (`chunk:334-341`), über Runtime-Übersetzung `i18n:747,779` abgedeckt. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht als eigene Zeile nach dem Rudel (2.2). Erste Nutzung ist bereits in Nacht 1 möglich (Cooldown startet bei 0, `gh:525`, `chunk:315`).
  2. Abklingzeit: nach Nutzung `WhiteWolfCooldown=3` (`chunk:354`), Abbau bei jedem `onNightStart` (`night:140`). Genutzt in Nacht N → wieder nutzbar in Nacht N+3 (Nächte N+1, N+2 gesperrt, Meldung "Noch 2/1 Nacht(e) warten"). Wird die Fähigkeit nicht genutzt, gibt es keine Sperre; "jede dritte Nacht" ist also "höchstens einmal alle drei Nächte, frei wählbar".
  3. Freiwillig: Dialog "Jetzt töten?" mit Nein (`chunk:331-362`); Nein verbraucht nichts.
  4. Ziele: lebende Sitze mit `isWolf`, außer allen Sitzen mit Rolle "Rachsüchtiger Wolf" und Doppelspion (`chunk:325,359`). `isWolf` schließt `meta.cursedWolfAura` ein (`core:18`) → vom Dämonischen Wolf verfluchte Dorfbewohner sind wählbar. Keine Selbstwahl, keine Toten.
  5. Wirkung: Ist das Ziel `protected` (oder Dorfwache), wird ein Schutzzähler verbraucht und nichts markiert (`chunk:348-350`); sonst `targeted=true` zusätzlich zum Rudelopfer (`chunk:352`, Kommentar Z.347). Cooldown wird auch bei abgewehrtem Angriff gesetzt. Seuchenwolf-Durchdringung wird hier nicht geprüft.
  6. Tod am Morgen über die normale Auflösung als `NIGHT_KILL` (`night:393`), durchläuft Der Weise, Dorfwache-Filter, Märtyrerin (nur `nightTargets[0]`), Voodoo, Schmied, Schilde. Öffentlich sichtbar als Werwolf-Tod (`ui:402` Label "🐺 Werwolf").
  7. Mehrere `targeted`: Waldhexe (`chunk:209`) und Verdammniswächter (`chunk:727`) nehmen `seats.find(targeted)`, also den ersten markierten Sitz nach Sitzreihenfolge, nicht zwingend das Rudelopfer.
  8. Mehrere Kopien: Cooldown und UsedTonight sind global (`state.once`), also eine Nutzung pro Nacht für alle Kopien; Kopien können sich gegenseitig nicht wählen.
  9. Sieg: kein Einzelsieg; zählt als Wolf (Parität). Die Ewigen (Solo-Prüfung `chunk:253-256`) melden ihn als nicht-solo.
  10. Rollenwechsel/Wiederbelebung: keine Sonderbehandlung; Cooldown ist nicht an die Person gebunden.
  11. Zufall: keiner im Handler.
- React-Version: kein eigenes Verhalten; nur Kartenbild-Mapping (`app/src/roleCard.ts`, Rachsüchtiger Wolf ohne EN-Eintrag).
- Bisherige Doku und Prüfergebnis:
  - `04` Zeile 13 "widersprüchlich", `chunk:310-364`, "Kann einen Wolf reißen, danach 3 Nächte Pause; Text will alleine gewinnen vs. Code gewinnt mit Rudel": Widerspruch bestätigt. Präzisierung: nicht "3 Nächte Pause", sondern 2 gesperrte Nächte, Wiedernutzung in der dritten Nacht; erste Nutzung schon in Nacht 1.
  - `07` Q1 Tabelle: "will alleine gewinnen / gewinnt mit Rudel / Vorschlag Text" bestätigt. `07:81` fehlender Siegcode bestätigt.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:181` L12 (Ziel löscht alle `targeted`, ersetzt Rudelopfer): widerlegt für aktuellen Code (`chunk:347-353` setzt nur zusätzlich).
  - `FIX_REPORT.md:5` EN-Name "Lone Wolf" bestätigt (`i18n:530-533,863`).
  - `NIGHT-REPORT-abilities.md:79` "1 Ziel (jede 3. Nacht)": ungenau (frei wählbar, dann Sperre).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Siegziel | "willst alleine gewinnen" | fehlt | gewinnt mit Rudel (isWolf, Parität) | kein eigenes | 04 widersprüchlich, 07 Q1 "Text" | Einzelsieg: gewinnt nur, wenn er als Letzter (oder mit Bedingung X) übrig ist | Rudelsieg wie Code | A macht ihn zum Verräter im Rudel, B zu einem normalen Wolf mit Zusatzkill | A: neue Siegbedingung, Fraktion "solo" trotz Wolfsrudel, Parität neu definieren | A (Text), EN ergänzen | Ja |
| Rhythmus | "jede dritte Nacht" | "every third night" | ab Nacht 1 frei, danach 2 Nächte Sperre | kein | 04 "3 Nächte Pause" | fester Takt (Nacht 3, 6, 9) | Abklingzeit nach Nutzung | A seltener und vorhersehbar | Nachtschritt-Bedingung nach Nachtnummer vs. Zähler pro Person | Abklingzeit (Code), Text präzisieren | Ja |
| Zeitpunkt der ersten Nutzung | nicht genannt | nicht genannt | Nacht 1 möglich | kein | nicht erwähnt | erst ab Nacht 3 | ab Nacht 1 | früher Rudelverlust in Nacht 1 möglich | Startwert Zähler | festlegen | Ja |

- Bugs:
  - technische Altlast: `chunk:162` Werwolf-Handler setzt bei jedem (erneuten) Klick alle `targeted=false`; wird die Rudelzeile nach dem Rachsüchtigen erneut bedient, verschwindet dessen Ziel still. Erwartet: getrennte Ziellisten. Risiko mittel. Test: Rachsüchtiger wählt Wolf A, danach Rudel erneut → A bleibt Ziel.
  - unklare Regel: Rachsüchtiger ignoriert Seuchenwolf-Durchdringung (`chunk:348`), sein `NIGHT_KILL` setzt aber die Seuchenwolf-Durchdringung zurück (`night:338`). Test: Durchdringung aktiv, nur Rachsüchtiger tötet → Flag-Verhalten festlegen.
  - unklare Regel: Waldhexe/Verdammniswächter sehen bei zwei Zielen nur das erste nach Sitzreihenfolge (`chunk:209,727`).
- Legacy-Status: legacy-contradictory. Mechanik (Zusatzkill mit Abklingzeit) funktioniert, aber Siegziel des Textes fehlt im Code, EN-Text lässt es weg, Rhythmus weicht ab.
- Automationsvorschlag: assisted. Schritt, Zielfilter und Zähler sind automatisierbar; Sieglogik hängt an PO-Entscheidung.
- Mechanikfamilie: primär Tötung; sekundär Einzelsieg (laut Text), Wolfsangriff-Modifikation.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (Ja/Nein + Ziel, abbrechbar), KillPipeline (NIGHT_KILL-artige Ursache mit eigener Quelle), Protections (ob Schutzengel greift: festlegen), WinRules/WinCandidate, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Abklingzeit-Zähler pro Person (Einsatzhistorie mit Nachtnummer); zusätzliche Siegbedingung (Einzelsieg eines Wolfsfraktionsmitglieds), falls Text gilt.
- Abhängigkeiten: Werwolf (Rudel, synthetische Zeile), Doppelspion (Zielausschluss, Textbezug), Dämonischer Wolf (verfluchte Ziele), Schutzengel/Dorfwache, Seuchenwolf, Waldhexe, Verdammniswächter, Die Ewigen, Nachtwächter (Wolf-Erkennung).
- Komplexität / Fehlerrisiko: M / hoch (Siegmodell und Fraktionszugehörigkeit müssen neu definiert werden).
- Offene Entscheidungen: (1) Einzelsieg ja/nein, und wenn ja unter welcher Bedingung (letzter Lebender? letzter Wolf?) und zählt er vorher zur Wolfsparität? (2) Feste Nächte (3, 6, 9) oder Abklingzeit ab erster Nutzung? Erste Nutzung ab Nacht 1? (3) Wirkt Schutzengel-Schutz gegen seinen Angriff? (4) Ist sein Angriff ein "Wolfsangriff" für Seuchenwolf, Rudelvater, Ritter?
- Relevante Testgruppen:
  - Normalfall: Nacht 1 wählt Wolf B, Morgen B tot (NIGHT_KILL), Nacht 2 und 3 gesperrt, Nacht 4 frei.
  - ungültiges Ziel: Dorfbewohner, Doppelspion, sich selbst → abgelehnt.
  - tote Person: toter Wolf nicht wählbar.
  - Selbstwahl: abgelehnt.
  - mehrere Kopien: zwei Rachsüchtige, eine Nutzung pro Nacht gesamt (Legacy) vs. pro Person (festlegen).
  - Wiederbelebung: Opfer per Frankenstein zurück → Abklingzeit bleibt.
  - Rollenwechsel: Lehrling erbt Rolle → Zähler pro Person frisch (DR-11-Muster).
  - Save/Load: Speichern in Nacht N+1 nach Nutzung, Laden → weiterhin gesperrt.
  - Replay: gleiche Befehle → gleiches Opfer, gleicher Zähler.
  - SL-Korrektur: Kill zurücknehmen → Zähler zurücksetzen?
  - Sichtbarkeit: Tod öffentlich als Nachttod, Quelle nur SL.
  - Schutz: Ziel geschützt → nach Entscheidung (Legacy: abgewehrt, Zähler verbraucht).
  - Todesreaktionen: Opfer Sensenträger → Reaktion am Morgen.
  - Siegprüfung: Rachsüchtiger + 1 Dorfbewohner leben → Legacy Wolfssieg; nach Text kein Rudelsieg.
  - beschädigter Spielstand: Cooldown negativ oder nicht numerisch → Laden lehnt ab.
- Belegsicherheit: hoch für Code; nicht im Browser ausgeführt.

### koenig-lykaon
- DE-Name / EN-Name: König Lykaon / King Lycaon (`roles:151`).
- Aliase/Altnamen: "Urwolf" (Migration `state:18`, `state:23` löscht `UrwolfUsed`; `core:346-352` löscht `UrwolfUsed` und `Used["role_Urwolf"]`); i18n `koenigLykaon*` (`i18n:266-267`, EN `590-591`); Bild `König_Lykaon.webp` / `King_Lycaon.webp`; kebab-Beispiel `field-pixi.js:160`.
- Legacy-ID: "König Lykaon".
- Fraktion: "wolf"; in `WOLF_KILL_ROLES` (`night:50`).
- Akte: akt1 (`akte.js:20`), custom.
- Nachtpriorität: tier 2.4, `once:true` (`roles:20`). Zeile verschwindet nach `markOnceUsed` (`night:60`). Keine Nacht-1-Bedingung in `rebuildOrder`; die Beschränkung liegt im Handler.
- Quelltextstellen:
  - `roles:77`, `roles:226`, `role-abilities.js:51`.
  - `chunk:364-394` Handler: once-Prüfung, `nightCount>1` → verbrauchen + Meldung, Verbündeten-Pick, Dorfbewohner-Pick, Verwandlung, `FakeNightRoles`.
  - `core:41-56` `applyRoleOrVillagerIfGatewardenWolf`: Wächter am Tor lebt → Ziel wird "Dorfbewohner".
  - `night:42-47` Tarnzeilen (`FakeNightRoles`), `ab:79-82` Tarnhinweis.
  - `chunk:238-251` Orakel: Trugbilderwolf zeigt zufällige Nicht-Wolf-Rolle lebender Sitze (`Math.random`).
  - `core:339-359` `resetOnceForInheritedRole("König Lykaon")` (Lehrling-Erbe).
  - `cards.js:372-377` Totenkarte "Schicksalswende" (Wolfsseite: "König Lykaon erwacht in dir ...").
- Text DE (wörtlich): "Wähle in der ersten Nacht einen verbündeten Wolf. Gemeinsam entscheidet ihr, welcher Dorfbewohner es wert ist, einer von euch zu werden. Dieser wird dann zu einem Trugbilderwolf."
- Text EN (wörtlich): "In the first night, choose an allied wolf. Together you decide which villager is worthy of becoming one of you. That villager then becomes a Decoy Wolf."
- DE/EN-Vergleich: JA, semantisch gleich (Zeitpunkt erste Nacht, 1 Verbündeter, 1 Dorfbewohner, Ergebnis Trugbilderwolf/Decoy Wolf).
- Weitere Texte: Totenkarte wende_11 (`cards.js:375`, nur DE) verleiht die Fähigkeit einem Wolf; kein Code für diese Karte gefunden (nur Definition), also rein manuell. i18n `koenigLykaonFirstNightOnly`, `koenigLykaonNoAlly`. Pick-Prompts "wähle einen verbündeten Wolf" / "wähle den Dorfbewohner (wird Trugbilderwolf)" hartkodiert DE, nur Fragment "wähle " wird übersetzt (`i18n:1073`).
- Legacy-Codeverhalten:
  1. Zeitpunkt: nur wirksam, wenn `state.nightCount<=1` (`chunk:367-374`). Wird die Zeile erst in Nacht 2+ bedient, wird die Fähigkeit verbraucht und "Nur in der ersten Nacht wirksam" gemeldet.
  2. Voraussetzung: mindestens ein lebender anderer Wolf (`isWolf`, Rolle nicht König Lykaon) (`chunk:375-379`); sonst Meldung ohne Verbrauch (in Nacht 2 dann Verbrauch).
  3. Verbündeter: nur Gate, wird nicht gespeichert und hat keine Wirkung. `isWolf` schließt verfluchte Dorfbewohner ein (`core:18`).
  4. Ziel: lebend und `!isWolf` (`chunk:393`), also auch Solo-Rollen (Doppelspion, Manipulator, Parasit, Grabräuber, Todesprediger sind in `isWolf` explizit false) und der Wächter am Tor selbst. Keine Selbstwahl (er ist Wolf).
  5. Wirkung: Rolle wird "Trugbilderwolf", `flags.werewolf=true` (`core:52-55`); bei lebendem Wächter am Tor stattdessen "Dorfbewohner" (`core:45-50`, Meldung). Alte Rolle (außer Dorfbewohner) bleibt als 🎭-Tarnzeile in der Nachtreihenfolge, solange der Sitz lebt (`chunk:388`, `night:45-47`). Dieser Eintrag wird auch gesetzt, wenn der Wächter die Verwandlung verhindert hat.
  6. Verbrauch: `markOnceUsed` global pro Rollenname (`night:5`), also einmal für alle Kopien.
  7. Sichtbarkeit: keine öffentliche Meldung; Orakel zeigt später eine zufällige lebende Nicht-Wolf-Rolle (`chunk:240-249`), nicht die alte Rolle.
  8. Sieg: verwandelter Sitz zählt sofort als Wolf (Parität, `isWolf` über `WOLF_ROLES_SET`).
  9. Einmal-Nutzungen der alten Rolle werden nicht zurückgesetzt/übertragen; die Person verliert ihre alte Fähigkeit (nur Scheinzeile).
  10. Zufall: keiner im Handler (indirekt beim Orakel).
- React-Version: kein eigenes Verhalten; Kartenmapping `roleCard.ts:32`.
- Bisherige Doku und Prüfergebnis:
  - `04` Zeile 14 "verifiziert", `chunk:364-394`, "Nacht 1: Opfer wird Trugbilderwolf (Wächter → Dorfbewohner); alte Rolle bleibt als Tarnzeile": bestätigt. Ergänzung: Verbündeter ohne Wirkung; Tarnzeile auch bei Wächter-Umleitung; Nacht-2-Klick verbraucht.
  - `04` A-61 Wächter am Tor listet Lykaon: bestätigt (`core:41-56`).
  - DECISION-LOG "Trugbilderwolf" (`DECISION-LOG.md:173-179`): Scheinrolle wird "beim Spielaufbau für jede Instanz ausdrücklich festgelegt". Ein per Lykaon erzeugter Trugbilderwolf existiert beim Aufbau nicht → Lücke. Legacy nutzt stattdessen Zufall beim Orakel (widerspricht DR-08 "SL wählt").
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:219` E3 (EN ohne Trugbilderwolf-Folge): widerlegt, EN ist inzwischen vollständig (`roles:226`).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Scheinrolle des erzeugten Trugbilderwolfs | nicht genannt | nicht genannt | keine gespeichert; Orakel zeigt Zufallsrolle | kein | DECISION-LOG: Scheinrolle nur im Aufbau festgelegt | Scheinrolle = alte Rolle der Person | SL wählt bei Verwandlung | A passt zur Tarnzeile und ist logisch stark | `appears_as` muss bei RoleTransition gesetzt werden | A, mit SL-Korrektur | Ja |
| "Dorfbewohner" | "Dorfbewohner" | "villager" | jede Nicht-Wolf-Rolle inkl. Solos | kein | 04 "Opfer" | nur Dorffraktion | jede Nicht-Wolf-Person | B kann Solo-Rollen neutralisieren | Zielfilter `faction==village` vs `!counts_as_wolf` | festlegen | Ja |

- Bugs:
  - unklare Regel: Tarnzeile wird auch gesetzt, wenn der Wächter am Tor die Verwandlung in "Dorfbewohner" umlenkt (`chunk:385-388`). Test: Wächter lebt, Lykaon wählt Schutzengel → Sitz ist Dorfbewohner; Tarnzeile ja/nein laut Entscheidung.
  - unklare Regel: Wählt Lykaon den Wächter am Tor selbst, wird dieser zum Dorfbewohner (Wächter lebt zum Zeitpunkt der Prüfung, `core:31-33,45`).
  - technische Altlast: Verbündeter wird nicht gespeichert (keine Nachvollziehbarkeit im Protokoll).
  - technische Altlast: hartkodierte DE-Prompts ohne i18n-Schlüssel.
- Legacy-Status: legacy-verified. Der Code setzt Zeitpunkt, Verbündeten-Gate und Verwandlung nachvollziehbar um; Lücken betreffen nicht beschriebene Details (Scheinrolle, Solo-Ziele).
- Automationsvorschlag: automatic (mit PendingPrompt zweistufig), Scheinrolle assisted durch SL-Bestätigung.
- Mechanikfamilie: primär Rollenwechsel; sekundär Fraktionswechsel, Einmalfähigkeit, mehrstufige Nachtfähigkeit.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (mehrstufig, abbrechbar), RoleTransition (mit Schnappschuss), appears_as, InfoRecord (Orakel), GmCorrections, WinRules.
- Benötigte NEUE Systeme: Wächter-am-Tor-Blockade als zentrale Regel in RoleTransition (für alle Verwandlungswege); optional "Scheinschritt" (Tarnzeile für verschwundene Rolle) in der Nachtplanung.
- Abhängigkeiten: Trugbilderwolf, Wächter am Tor, Orakel, Lehrling (Erbe), Werwolf (synthetische Rudelzeile), Totenkarte wende_11.
- Komplexität / Fehlerrisiko: M / mittel (Rollenwechsel plus Erscheinung plus Wächter-Regel).
- Offene Entscheidungen: (1) Welche Scheinrolle erhält der neue Trugbilderwolf? (2) Dürfen Solo-Rollen Ziel sein? (3) Muss der Verbündete gespeichert/angezeigt werden, oder reicht er als Ansage? (4) Verfällt die Fähigkeit, wenn Nacht 1 ohne Nutzung vergeht (Legacy ja)? (5) Tarnzeile der alten Rolle ja/nein, auch bei Wächter-Umleitung?
- Relevante Testgruppen:
  - Normalfall: Nacht 1, Verbündeter Werwolf, Ziel Orakel → Trugbilderwolf, zählt als Wolf.
  - ungültiges Ziel: Wolf als "Dorfbewohner" gewählt → abgelehnt.
  - tote Person: toter Dorfbewohner nicht wählbar.
  - Selbstwahl: Lykaon als Verbündeter nicht wählbar.
  - mehrere Kopien: zwei Lykaon → Legacy nur eine Verwandlung; Soll festlegen.
  - Wiederbelebung: verwandelter Sitz stirbt und wird wiederbelebt → bleibt Trugbilderwolf? (Frankenstein vergibt neue Rolle, `chunk:64ff`).
  - Rollenwechsel: Wächter am Tor lebt → Ziel wird Dorfbewohner, kein Wolf.
  - Save/Load: nach Verwandlung speichern/laden → Rolle, Fraktion, Scheinrolle erhalten.
  - Replay: identische Verwandlung.
  - SL-Korrektur: Verwandlung zurücknehmen per RoleTransition-Schnappschuss.
  - Sichtbarkeit: keine öffentliche Meldung; Orakel sieht Scheinrolle.
  - Schutz: nicht relevant, weil Verwandlung kein Angriff ist (Legacy prüft keinen Schutz).
  - Todesreaktionen: nicht relevant, weil kein Tod entsteht.
  - Siegprüfung: Verwandlung führt sofort zur Wolfsparität → Siegprüfung nach Verwandlung.
  - beschädigter Spielstand: Trugbilderwolf ohne gültige Scheinrolle → Laden lehnt ab (bestehende Godot-Regel).
- Belegsicherheit: hoch; nicht verifiziert: Laufzeitverhalten der hartkodierten Prompts in EN.

### siegreicher-wolf
- DE-Name / EN-Name: Siegreicher Wolf / Victorious Wolf (`roles:186`).
- Aliase/Altnamen: keine Migration; Bild `Siegreicher_Wolf.webp` / `Victorious_Wolf.webp`.
- Legacy-ID: "Siegreicher Wolf".
- Fraktion: "wolf"; nicht in `WOLF_KILL_ROLES`.
- Akte: akt4 (`akte.js:82`), custom.
- Nachtpriorität: kein Eintrag in `ORDER_BASE`; zusätzlich in der Passiv-Liste (`night:96`). Kein Nachtschritt.
- Quelltextstellen:
  - `roles:112`, `roles:262`, `role-abilities.js:59`.
  - `core:21-29` `countLivingWolfPower`: +2 für lebenden Siegreichen Wolf; genutzt in `checkWinConditions` (`core:225,233`).
  - `core:311-312` `checkTeamWin`: eigene Zählung, ebenfalls +2; Wolfssieg bei `wolfPower>=others.length` (`core:330`).
  - `night:50-55` fehlende Rudelzeile, wenn nur er (ohne Werwolf) lebt (F2).
- Text DE (wörtlich): "Solange er lebt, zählt er für die Siegbedingung wie zwei Werwölfe."
- Text EN (wörtlich): "As long as they live, counts as two werewolves toward the win condition."
- DE/EN-Vergleich: JA, semantisch gleich.
- Weitere Texte: keine Abweichung.
- Legacy-Codeverhalten:
  1. Passiv; nur in beiden Siegprüfern wirksam, nur solange lebend (Filter `!dead`).
  2. Wirkt nur auf die Wolfsparität (`wolfPower >= Nicht-Wölfe`), nicht auf "alle Wölfe tot" (dort zählt `trueWolves.length`, `core:226-231`).
  3. Keine Wirkung auf Zählungen anderer Rollen (Waldläufer zählt 1, `chunk:490-493`) und nicht auf Stimmen.
  4. Mehrere Kopien: jede zählt 2.
  5. Rollenwechsel: Doppelzählung hängt an der Rolle, nicht an der Person.
  6. Zufall: keiner.
- React-Version: kein eigenes Verhalten; `roleCard.ts:33`.
- Bisherige Doku und Prüfergebnis: `04` Zeile 15 "verifiziert", `core:21-29`, S-WIN-03 (1 Siegreicher + 2 Dorf → Wolfsieg): bestätigt (2 >= 2). `04` D-2 bestätigt (`core:233,330-334`). `01:193` bestätigt. F2 (`01:263`) bestätigt, betrifft ihn direkt. `docs/specs/vertical-slice/rules-register.md:78` nimmt ihn aus dem Slice aus: konsistent.
- Widersprüche: keine belegten.
- Bugs:
  - echter Bug (fremde Rolle, Wirkung hier): F2, `night:50-55`. Lebt nur der Siegreiche Wolf (ohne Werwolf und ohne Rolle aus `WOLF_KILL_ROLES`), gibt es keine Rudel-Tötungszeile. Erwartet: Rudelschritt, solange irgendein Wolf lebt. Risiko hoch (Wölfe können nicht töten). Test: nur Siegreicher Wolf + 4 Dorf → Nachtplan enthält Rudelschritt.
- Legacy-Status: legacy-verified.
- Automationsvorschlag: automatic.
- Mechanikfamilie: primär sonstige Spezialmechanik (Gewicht in der Siegparität); sekundär globale Regeländerung.
- Benötigte vorhandene Godot-Systeme: WinRules/WinCandidate (Gewicht pro Person), Nachtplan (Rudelschritt nach counts_as_wolf).
- Benötigte NEUE Systeme: keines außer einem Paritätsgewicht in WinRules (kleine Erweiterung).
- Abhängigkeiten: Werwolf (Rudelschritt), alle Siegregeln, Doppelspion (Sieg bei 0 Wölfen).
- Komplexität / Fehlerrisiko: S / niedrig.
- Offene Entscheidungen: Zählt er auch bei anderen Wolfszählungen doppelt (z. B. Waldläufer, Parasit-/Manipulator-Siege mit "exakt drei Lebenden")? Legacy: nein.
- Relevante Testgruppen:
  - Normalfall: Siegreicher + 2 Dorf → Wolfssieg; Siegreicher + 3 Dorf → kein Sieg.
  - ungültiges Ziel: nicht relevant, weil kein Ziel.
  - tote Person: Siegreicher tot → zählt 0.
  - Selbstwahl: nicht relevant, weil keine Wahl.
  - mehrere Kopien: 2 Siegreiche + 4 Dorf → Wolfssieg.
  - Wiederbelebung: wiederbelebt → zählt wieder 2.
  - Rollenwechsel: Lehrling erbt Siegreicher → zählt 2.
  - Save/Load: Siegprüfung nach Laden identisch.
  - Replay: identisches Siegergebnis.
  - SL-Korrektur: Rolle per Korrektur entfernt → Parität neu.
  - Sichtbarkeit: nicht relevant, weil keine Aktion.
  - Schutz: nicht relevant.
  - Todesreaktionen: nicht relevant.
  - Siegprüfung: Kernfall, siehe oben.
  - beschädigter Spielstand: nicht relevant, weil kein eigener Zustand.
- Belegsicherheit: hoch.

### seuchenwolf
- DE-Name / EN-Name: Seuchenwolf / Blight Wolf (`roles:187`).
- Aliase/Altnamen: keine Migration; Schlüssel `SeuchenwolfNextAttackPierces`; Bild `Blight_Wolf.webp`.
- Legacy-ID: "Seuchenwolf".
- Fraktion: "wolf"; nicht in `WOLF_KILL_ROLES`.
- Akte: akt4 (`akte.js:82`), custom.
- Nachtpriorität: kein `ORDER_BASE`-Eintrag; Passiv-Liste (`night:96`).
- Quelltextstellen:
  - `roles:113`, `roles:263`, `role-abilities.js:58`.
  - `core:148` `applyKill`: stirbt ein Seuchenwolf (jede Ursache) → `SeuchenwolfNextAttackPierces=true`.
  - `chunk:162` Werwolf-Handler: bei aktivem Flag wird Schutz (`protected`, Dorfwache) ignoriert und kein Schutzzähler verbraucht.
  - `night:238,251` `onDayStart`: bei aktivem Flag kein Dorfwache-Filter.
  - `night:336,358-364` `resolveDayKills`: `ignoreProtection` hebelt nur Der Weise aus.
  - `night:338` Rücksetzung, wenn ein Sitz in `killedTonight` `lastKillCause==="NIGHT_KILL"` hat.
  - `gh:525` Reset bei neuer Runde.
- Text DE (wörtlich): "Nach seinem Ableben durchdringt der nächste Wolfsangriff alle Schutzeffekte."
- Text EN (wörtlich): "After their death, the next wolf attack pierces all protection effects."
- DE/EN-Vergleich: JA, semantisch gleich.
- Weitere Texte: keine.
- Legacy-Codeverhalten:
  1. Auslöser: Tod mit beliebiger Ursache (auch Lynch, Hexe, Sensenträger) über `applyKill` (`core:148`). Manueller Tot-Chip (F6, `gh:429`) umgeht das.
  2. Durchdrungen werden: Schutzengel/Schutzgeist-Schutz (`protected`) und Dorfwache bei der Rudelwahl (`chunk:162`), Dorfwache-Filter am Morgen (`night:251`), Der Weise (`night:359`).
  3. Nicht durchdrungen: Nekromant-Schild, Kartenschlucker-Schild, Hades-Barriere (Ausnahme nur `PACKFATHER_KILL`, `core:126-143`), Schmiede-Waffe (`night:380-391`), Waldhexe-Rettung (`chunk:217`), Märtyrerin, Voodoo-Puppe, Albtraum-Block (`night:334`), Parasit, Schattenwanderer-Umlenkung, Schutz beim Angriff des Rachsüchtigen Wolfs (`chunk:348`).
  4. Verbrauch: erst, wenn in der Morgenauflösung ein Sitz aus `killedTonight` mit Ursache NIGHT_KILL gestorben ist (`night:338`). Scheitert der Angriff (Schild, Hexe, Schmied), bleibt das Flag bis zum nächsten Erfolg. Auch der Kill des Rachsüchtigen oder Schicksalswolf-Zusatzopfer (beide NIGHT_KILL) verbrauchen es.
  5. `pierceActive` wird zu Beginn der Auflösung gelesen (`night:336`); stirbt der Seuchenwolf in derselben Auflösung, bleibt das neue Flag für die nächste Nacht erhalten. War es schon aktiv und stirbt ein zweiter Seuchenwolf in dieser Auflösung, wird es trotzdem gelöscht (ein Boolean für alle Kopien).
  6. F14-Aspekt: `killedTonight` enthält auch Überlebende (`night:394`). Rücksetzung wird dadurch nur falsch ausgelöst, wenn ein Überlebender noch ein altes `lastKillCause==="NIGHT_KILL"` trägt (z. B. nach Frankenstein-Wiederbelebung, `chunk:57-62` löscht es nicht). Umgekehrt: wird ein Rudelkill per Schattenwanderer umgelenkt, steht der Tote nicht in `killedTonight` → kein Verbrauch.
  7. Sichtbarkeit: keine Anzeige/Markierung; SL sieht nichts außer dem Verhalten.
  8. Zufall: keiner.
- React-Version: kein eigenes Verhalten; `roleCard.ts:34`.
- Bisherige Doku und Prüfergebnis:
  - `04` Zeile 16 "verifiziert", `core:148`, `night:238,251,336-338`, "Nach seinem Tod durchbricht der nächste Wolfsangriff Schutz einmal": Zeilen bestätigt. Status zu optimistisch: "alle Schutzeffekte" ist nur teilweise umgesetzt, und der Rudelvater-Durchbruch (`PACKFATHER_KILL`) hebelt mehr aus als der Seuchenwolf.
  - `01:275` F14 "Seuchenwolf-Reset falsch ausgelöst": teilweise bestätigt (nur mit veraltetem `lastKillCause`), ergänzt um den umgekehrten Fall (Umlenkung verhindert Verbrauch).
  - `04` C.1 Dorfwache "nicht gegen Pierce": bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Umfang "alle Schutzeffekte" | alle | all | nur Schutzengel/Schutzgeist, Dorfwache, Der Weise; Schilde, Hexe, Schmied, Märtyrerin nicht | kein | 04 verifiziert, "Schutz" | wirklich alles, was einen Rudelkill verhindert | nur Schutzrollen (Schutzengel, Dorfwache, Der Weise), keine Schilde/Rettungen | A deutlich stärker | Liste der durchdrungenen Abfangregeln in KillPipeline festlegen | Einheitliche Liste mit Rudelvater teilen | Ja |
| Verbrauch | "der nächste Wolfsangriff" | "the next wolf attack" | erst beim nächsten erfolgreichen NIGHT_KILL | kein | 04 "einmal" | nächster Angriff, auch wenn er scheitert | nächster erfolgreiche Kill | A kann durch Hexe verpuffen | Verbrauchszeitpunkt | A (Text) | Ja |
| Welche Angriffe | "Wolfsangriff" | "wolf attack" | nur Rudelwahl nutzt es, Rachsüchtiger nicht; aber dessen Kill verbraucht es | kein | nicht erwähnt | nur Rudelangriff | jeder Wolfskill | gering | Ursachen-Attribut | nur Rudelangriff | Ja |

- Bugs:
  - unklare Regel: Rücksetzung hängt an `lastKillCause` statt an einer Angriffsinstanz (`night:338`). Test: Durchdringung aktiv, Rudelopfer überlebt durch Hexe, Rachsüchtiger-Opfer stirbt → Flag gelöscht, obwohl der Rudelangriff scheiterte.
  - technische Altlast: F14 (`night:394`) Überlebende in `killedTonight`. Test: wiederbelebter Sitz mit altem NIGHT_KILL überlebt Angriff per Schild → Flag darf nicht fallen.
  - echter Bug (Randfall): ein Boolean für alle Kopien, gleichzeitiger zweiter Seuchenwolf-Tod geht verloren (`core:148` + `night:338`). Risiko niedrig.
- Legacy-Status: legacy-contradictory. Kernidee funktioniert, aber der Umfang ("alle Schutzeffekte") und der Verbrauch weichen vom Text ab, und der Code behandelt zwei "ignoriert Schutz"-Regeln (Seuchenwolf, Rudelvater) unterschiedlich.
- Automationsvorschlag: automatic (nach Festlegung der Liste).
- Mechanikfamilie: primär Todesreaktion; sekundär Wolfsangriff-Modifikation, globale Regeländerung.
- Benötigte vorhandene Godot-Systeme: KillPipeline (Abfangstufe mit Filter), Protections (derzeit nur Schutzengel gegen Rudel-NIGHT_KILL), Reaktionswarteschlange nicht nötig (passiver Effekt).
- Benötigte NEUE Systeme: globaler Modifikator "nächster Rudelangriff durchdringt" (persistiert, mit Verbrauchsregel); Attribut `pierces` pro Angriff.
- Abhängigkeiten: Werwolf, Schutzengel, Schutzgeist, Dorfwache, Der Weise, Waldhexe, Nekromant, Kartenschlucker, Hades, Dorfschmied, Märtyrerin, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (gemeinsames Durchdringungskonzept).
- Komplexität / Fehlerrisiko: M / mittel.
- Offene Entscheidungen: (1) Welche Schutzarten durchdringt er (Liste)? (2) Verbraucht ein gescheiterter Angriff die Durchdringung? (3) Nur Rudelangriff oder jeder Wolfskill? (4) Stapeln sich zwei Seuchenwolf-Tode?
- Relevante Testgruppen:
  - Normalfall: Seuchenwolf gelyncht, nächste Nacht Rudel wählt geschützten Sitz → stirbt.
  - ungültiges Ziel: nicht relevant, weil kein Ziel.
  - tote Person: Rudelziel stirbt vorher anderweitig → Verbrauch laut Entscheidung.
  - Selbstwahl: nicht relevant.
  - mehrere Kopien: zwei Seuchenwölfe sterben am selben Tag → ein oder zwei Durchdringungen.
  - Wiederbelebung: Seuchenwolf wiederbelebt und stirbt erneut → neue Durchdringung?
  - Rollenwechsel: Lehrling erbt Seuchenwolf und stirbt → löst aus.
  - Save/Load: Flag über Tag speichern/laden.
  - Replay: gleiche Folge.
  - SL-Korrektur: Tod des Seuchenwolfs per Korrektur ohne Todesfolgen → kein Flag.
  - Sichtbarkeit: Flag nur SL-sichtbar.
  - Schutz: Kernfall je Schutzart (Schutzengel, Dorfwache, Der Weise, Schilde, Hexe).
  - Todesreaktionen: nicht relevant außer Auslösung selbst.
  - Siegprüfung: nicht relevant, weil kein Siegbezug.
  - beschädigter Spielstand: Flag nicht boolesch → Ablehnung.
- Belegsicherheit: hoch.

### schicksalswolf
- DE-Name / EN-Name: Schicksalswolf / Fate Wolf (`roles:188`).
- Aliase/Altnamen: Schlüssel `FateWolfMarked`, `FateWolfNight4Used`, `FateWolfExtraIds`, `FirstThreeDeadIds`; i18n `fateWolf*` (`i18n:268-271`, EN `592-595`); Bild `Fate_Wolf.webp`.
- Legacy-ID: "Schicksalswolf".
- Fraktion: "wolf"; nicht in `WOLF_KILL_ROLES`.
- Akte: akt4 (`akte.js:82`), custom.
- Nachtpriorität: tier 2.5, kein `once` (`roles:21`). Bedingungen `night:62-74`: Nacht 1 nur solange keine 3 Markierungen; Nacht 2-3 nie; ab Nacht 4 nur wenn `FateWolfNight4Used` false und mindestens eine Markierung unter `FirstThreeDeadIds.slice(0,3)`.
- Quelltextstellen:
  - `roles:114`, `roles:264`, `role-abilities.js:56`.
  - `chunk:395-421` Handler (Markieren Nacht 1, Zusatzopfer ab Nacht 4).
  - `core:149-150` `applyKill`: erste drei Tode (jede Ursache) in `FirstThreeDeadIds`.
  - `night:240-244` `onDayStart`: Zusatzziele in `nightTargets`, dann geleert.
  - `ui:340` `startMulti`: verlangt genau `max` Auswahlen.
  - `gh:525` Reset (`FateWolfMarked`, `FirstThreeDeadIds`, `FateWolfNight4Used`; nicht `FateWolfExtraIds`).
- Text DE (wörtlich): "Wähle zu Beginn des Spiels drei Spieler. Für jeden von ihnen, der unter den ersten drei Toten ist, erhältst du in Nacht 4 die Möglichkeit, einen zusätzlichen Spieler zu reißen."
- Text EN (wörtlich): "At the start of the game, choose three players. For each of them among the first three dead, you gain a kill ability in night 4."
- DE/EN-Vergleich: NEIN (gering). EN "a kill ability" lässt "zusätzlichen" (additional zum Rudelopfer) weg; Zählung pro Markiertem und Zeitpunkt Nacht 4 gleich.
- Weitere Texte: Pick-Prompts hartkodiert DE ("wähle 3 Spieler (Markierung)", "Extra-Opfer (Nacht 4)"), nur Fragment "wähle " übersetzt. i18n "Keine Extra-Reißer in Nacht 4".
- Legacy-Codeverhalten:
  1. Markieren: nur wenn `nightCount===1` (`chunk:399`), genau 3 lebende Sitze, Selbstwahl und Wölfe erlaubt (`x=>!x.flags.dead`). Wird Nacht 1 verpasst, ist die Fähigkeit dauerhaft verloren (Nacht 2-3 ausgeblendet, ab 4 kein Bonus ohne Markierung).
  2. Zählung: `FirstThreeDeadIds` sammelt die ersten drei `applyKill`-Tode jeder Ursache, ohne Deduplizierung (wiederbelebt und erneut gestorben zählt doppelt), auch Tode vor der Markierung (z. B. Tag-1-Lynch nach "Rollen leeren", `gh:527` setzt "Tag 1"). Manueller Tot-Chip (F6) zählt nicht.
  3. Bonus: Anzahl Markierter unter den (bis zu) ersten drei Toten; sind bis Nacht 4 weniger als drei gestorben, zählt die Teilliste.
  4. Zusatzopfer: "ab Nacht 4", einmalig (`FateWolfNight4Used`), nicht nur in Nacht 4: nicht bediente Nacht 4 oder später steigender Bonus macht Nacht 5+ möglich. Genau `bonus` lebende Sitze, beliebig (auch Wölfe, auch Rudelopfer; Doppelte werden am Morgen entfernt, `night:242`).
  5. Wirkung: Zusatzziele gehen am Morgen in `nightTargets` (`night:240-244`) und sterben als `NIGHT_KILL`. Schutzengel-Schutz wird nie geprüft (Schutz wird nur im Werwolf-Handler verbraucht, `chunk:162`) → Zusatzopfer ignorieren Schutzengel. Dorfwache-Filter, Der Weise, Märtyrerin, Voodoo, Schmied, Schilde greifen. Waldhexe kann sie nicht retten (sie sind nie `targeted`).
  6. Tod des Schicksalswolfs: Zeile verschwindet (`hasAliveRole`), bereits gesetzte Zusatzziele sterben trotzdem.
  7. Mehrere Kopien: ein gemeinsamer Satz Markierungen/Bonus.
  8. Sichtbarkeit: Markierungen nirgends angezeigt (`markerList` `ui:109` kennt sie nicht).
  9. Zufall: keiner.
- React-Version: kein eigenes Verhalten; `roleCard.ts:35`.
- Bisherige Doku und Prüfergebnis:
  - `04` Zeile 17 "verifiziert", `chunk:395-421`, `night:62-73,240-244`, "Nacht 1: 3 markieren; ab Nacht 4 einmal so viele Zusatzopfer ...": Zeilen und Verhalten bestätigt (Bedingung reicht bis `night:74`). Status aber fraglich: Text sagt "in Nacht 4", Code "ab Nacht 4"; Schutzengel wird nicht geprüft.
  - `04` B-5 (Schicksalswolf N1/N≥4) bestätigt.
  - `NIGHT-REPORT-abilities.md:85` "3 Ziele (Start) + bedingt Bonus (Nacht 4)" bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Zeitfenster | "in Nacht 4" | "in night 4" | ab Nacht 4 bis genutzt | kein | 04 "ab Nacht 4" | nur Nacht 4, danach verfallen | ab Nacht 4, einmal | B lässt Wölfe auf Bonus warten | Schrittbedingung | A (Text) | Ja |
| Schutz gegen Zusatzopfer | nicht genannt ("reißen") | "kill" | Schutzengel ignoriert, Dorfwache/Weise wirken | kein | nicht erwähnt | wie Rudelangriff (Schutz wirkt) | eigener Kill ohne Schutz | A schwächer | Ursache/Quelle, Protections-Filter | A | Ja |
| Zählung der ersten drei Toten | "unter den ersten drei Toten" | "among the first three dead" | alle Ursachen, keine Deduplizierung, auch vor Markierung | kein | nicht erwähnt | erste drei verschiedenen Toten der Partie | nur Tode nach Markierung | gering | Todesreihenfolge-Historie | A mit Deduplizierung | Ja |

- Bugs:
  - echter Bug (Randfall): `FirstThreeDeadIds` ohne Deduplizierung (`core:150`). Wiederbelebter Sitz, der erneut stirbt, belegt zwei Plätze. Test: A stirbt, wird wiederbelebt, stirbt erneut vor Tod Nr. 3 → Liste enthält A einmal.
  - technische Altlast: `FateWolfExtraIds` wird bei "Rollen leeren" nicht zurückgesetzt (`gh:525`); nur relevant, wenn zwischen Wahl und Morgen neu gestartet wird.
  - unklare Regel: Zusatzopfer ignorieren Schutzengel (`night:240-244` vs. `chunk:162`).
- Legacy-Status: legacy-contradictory ("in Nacht 4" vs. "ab Nacht 4"; Schutzbehandlung nicht wie Wolfsangriff).
- Automationsvorschlag: automatic (Markieren, Zählen, Bonus-Schritt), mit SL-Korrektur.
- Mechanikfamilie: primär Tötung; sekundär mehrstufige Nachtfähigkeit, Einmalfähigkeit, dauerhafte Markierung (sonstige Spezialmechanik).
- Benötigte vorhandene Godot-Systeme: StepQueue (bedingter Schritt nach Nachtnummer), PendingPrompt (Mehrfachwahl), KillPipeline, Protections, GmCorrections, StateCodec.
- Benötigte NEUE Systeme: dauerhafte Statusmarker (Markierungen, nur SL sichtbar); Todesreihenfolge-Historie (erste drei Tote, persistiert); Zusatzopfer-Liste für die Morgenauflösung.
- Abhängigkeiten: Werwolf (Rudelopfer, Deduplizierung), Schutzengel, Dorfwache, Der Weise, Märtyrerin, Zeitwächter (eingefrorene Nacht zählt nicht, `night:323-331` erhöht `nightCount` nicht), Frankenstein/Kutscher (Wiederbelebung), Seuchenwolf (NIGHT_KILL verbraucht Durchdringung).
- Komplexität / Fehlerrisiko: M / mittel.
- Offene Entscheidungen: (1) Nur Nacht 4 oder ab Nacht 4? (2) Wirkt Schutz gegen Zusatzopfer? (3) Zählen Tode vor der Markierung und doppelte Tode? (4) Darf er sich selbst oder Wölfe markieren? (5) Verfällt die Fähigkeit, wenn Nacht 1 nicht markiert wird?
- Relevante Testgruppen:
  - Normalfall: Markiert A, B, C; A und C unter den ersten drei Toten → Nacht 4 zwei Zusatzopfer.
  - ungültiges Ziel: tote Person als Zusatzopfer → abgelehnt.
  - tote Person: Markierung toter Sitze in Nacht 1 abgelehnt.
  - Selbstwahl: Selbstmarkierung laut Entscheidung.
  - mehrere Kopien: zwei Schicksalswölfe → getrennte Markierungen (Soll) vs. gemeinsam (Legacy).
  - Wiederbelebung: A stirbt, wird wiederbelebt, stirbt erneut → zählt einmal.
  - Rollenwechsel: Lehrling erbt Schicksalswolf nach Nacht 1 → keine Markierung möglich?
  - Save/Load: Markierungen und Todesreihenfolge nach Laden identisch.
  - Replay: identischer Bonus.
  - SL-Korrektur: Tod per Korrektur zurückgenommen → Todesreihenfolge korrigiert.
  - Sichtbarkeit: Markierungen nur SL/Akteur.
  - Schutz: Zusatzopfer geschützt → nach Entscheidung.
  - Todesreaktionen: Zusatzopfer Sensenträger → Reaktion am Morgen.
  - Siegprüfung: mehrere Morgentode → eine Siegprüfung nach Auflösung.
  - beschädigter Spielstand: Markierung mit unbekannter ID → Ablehnung.
- Belegsicherheit: hoch; nicht verifiziert: Laufzeit der `startMulti`-Abbruchpfade.

### schattenwanderer
- DE-Name / EN-Name: Schattenwanderer / Shadowwalker (`roles:189`); i18n-Meldung nutzt "Shadow Wanderer" (`i18n:596`), Kartenbild `Shadowwalker.webp`.
- Aliase/Altnamen: Schlüssel `meta.shadowSwapPartnerId`, Todesursachen-Label `SHADOW_SWAP` (`ui:415`, wird nie als Ursache gesetzt); i18n `shadowWandererChainActive`.
- Legacy-ID: "Schattenwanderer".
- Fraktion: "wolf"; nicht in `WOLF_KILL_ROLES`.
- Akte: akt2 (`akte.js:40`), custom.
- Nachtpriorität: tier 2.6, `once:true` (`roles:22`); keine Nacht-1-Beschränkung, Zeile bis zur Nutzung jede Nacht.
- Quelltextstellen:
  - `roles:115`, `roles:265`, `role-abilities.js:55`.
  - `chunk:422-435` Handler: Partnerwahl, beidseitige Verknüpfung, `markOnceUsed`.
  - `core:118-124` `applyKill`: stirbt ein verknüpfter Sitz und lebt der Partner, stirbt stattdessen der Partner mit derselben Ursache (`_shadowApplying` verhindert Ping-Pong).
  - `night:393-394` Überlebender landet trotzdem in `killedTonight`.
  - `night:499`, `night:404-419` Lynch: `finalizeLynch` protokolliert den Überlebenden als gelyncht.
  - `gh:517` / `legacy-bridge.js:39` Rollen leeren behält `shadowSwapPartnerId`.
- Text DE (wörtlich): "Knüpft eine Todeskette mit einem anderen Spieler. Stirbt einer von euch, stirbt stattdessen der andere (U+2014) und umgekehrt."
- Text EN (wörtlich): "Creates a death link with another player. If one of you dies, the other dies instead (U+2014) and vice versa."
- DE/EN-Vergleich: JA, semantisch gleich.
- Weitere Texte: i18n "Todeskette aktiv (Partner gewählt)"; Begriff "Todeskette" legt "beide sterben" nahe, der Satz danach und der Code sagen "stattdessen". NIGHT-REPORT nennt "1. Nacht", Text nicht.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht bis zur einmaligen Nutzung (global pro Rollenname).
  2. Ziel: jeder lebende Sitz ohne Rolle Schattenwanderer (`chunk:434`), also auch Wölfe und Solos; keine Selbstwahl.
  3. Akteur: `state.seats.find(Schattenwanderer lebend)` (`chunk:425`): bei mehreren Kopien immer die erste; die zweite kann wegen globalem once nicht handeln.
  4. Wirkung: Tod eines der beiden (jede Ursache über `applyKill`) wird auf den lebenden Partner umgelenkt; der ursprüngliche Sitz überlebt. Der Partner durchläuft seine eigenen Prüfungen (Rudelvater-Rettung, Schilde, Parasit), kann also ebenfalls überleben → niemand stirbt.
  5. Reihenfolge: Parasit und Rudelvater-Rettung des Ziels vor der Umlenkung (`core:104-117`), Schilde danach (Nekromant-Schild ist global und greift beim Partner).
  6. Effektiv einmalig: nach dem Tod des Partners zeigt der Link auf einen Toten und ist inaktiv; wird der Partner wiederbelebt (Frankenstein behält `meta`, `chunk:57-62`), ist der Link wieder aktiv. Kutscher-Wiederbelebung setzt `meta` zurück (`chunk:849-850`) → Link nur noch einseitig.
  7. Folgen: Rudel greift den Partner an → der Schattenwanderer (Wolf) stirbt. Lynch des Verknüpften → Partner stirbt mit `LYNCH`; `finalizeLynch` und Log melden den Überlebenden als gelyncht; Kopfgeldjäger-Aktivierung und Rudelvater-Zusatzopfer hängen am Überlebenden (`night:498-499`).
  8. Sichtbarkeit: keine Markierung des Links (`ui:109`); Tod des Partners erscheint mit Originalursache, nicht `SHADOW_SWAP`.
  9. Zufall: keiner.
- React-Version: kein eigenes Verhalten; `roleCard.ts:36`.
- Bisherige Doku und Prüfergebnis:
  - `04` Zeile 18 "verifiziert", `chunk:422-435`, `core:118-124`, "Tod eines der beiden trifft den anderen": bestätigt; Formulierung präzisieren ("statt", nicht "zusätzlich").
  - `04` C.1 Reihenfolge (nach Rudelvater, vor Nekromant) bestätigt.
  - `NIGHT-REPORT-abilities.md:81` "1. Nacht": widerlegt (keine Nachtbeschränkung).
  - `01:169` Reihenfolge bestätigt.
- Widersprüche: keine harten; Begriff "Todeskette" vs. "stattdessen" nur sprachlich (siehe Offene Entscheidungen).
- Bugs:
  - echter Bug: `clearRolesNewRound` (`gh:517`, gleich `legacy-bridge.js:39`) behält `meta.shadowSwapPartnerId`. In der neuen Runde lenkt `applyKill` Tode weiter auf den alten Partnersitz um. Erwartet: Link gehört zur Partie. Risiko hoch (falsche Tode in Folgerunde). Test: Link A-B, Rollen leeren, neue Runde, A stirbt → A stirbt, B lebt.
  - technische Altlast: Label `SHADOW_SWAP` (`ui:415`) wird nie gesetzt; Tod des Partners trägt die Originalursache (z. B. `NIGHT_KILL`), was Folgeregeln (Rudelvater, Ritter, Seuchenwolf-Verbrauch) wie einen direkten Angriff behandelt.
  - unklare Regel: Lynch eines Verknüpften zählt als Hinrichtung (LynchCount, Henker, Log) obwohl der Gelynchte lebt (`night:499-500`).
  - technische Altlast: Überlebender in `killedTonight` (F14, `night:394`), z. B. Dämonischer Wolf als Verknüpfter löst Fluch aus, obwohl er lebt (`night:285-289`).
- Legacy-Status: legacy-verified (Kernumlenkung entspricht dem Text innerhalb einer Partie; der Rundenwechsel-Bug liegt außerhalb der Partie).
- Automationsvorschlag: automatic.
- Mechanikfamilie: primär Verknüpfte Personen; sekundär Zielumleitung, Einmalfähigkeit.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt, KillPipeline (Umlenkungsstufe vor Schilden), Ereignis-Sichtbarkeit, StateCodec, GmCorrections.
- Benötigte NEUE Systeme: Bindungsmodell (Paar mit Richtung, Aktivstatus, Partie-gebunden); Umlenkungsregel mit eigener Ursache/Quelle.
- Abhängigkeiten: Rudelvater (Reihenfolge), Parasit, Nekromant/Kartenschlucker/Hades (Schilde beim Partner), Werwolf, Lynch/ExecutionRules, Frankenstein/Kutscher (Wiederbelebung), Dämonischer Wolf, Kopfgeldjäger, Henker.
- Komplexität / Fehlerrisiko: M / hoch (greift in jede Todesursache ein).
- Offene Entscheidungen: (1) "stattdessen" (Code) oder "beide sterben" (Begriff Todeskette)? (2) Gilt die Umlenkung für alle Ursachen inkl. Hinrichtung, und zählt eine umgelenkte Hinrichtung als erfolgt? (3) Einmalig oder dauerhaft (auch nach Wiederbelebung)? (4) Mit welcher Ursache/Quelle stirbt der Partner (eigene Ursache oder Original)? (5) Nur Nacht 1 oder jede Nacht bis zur Nutzung?
- Relevante Testgruppen:
  - Normalfall: Link S-A, Rudel tötet A → S stirbt, A lebt.
  - ungültiges Ziel: anderer Schattenwanderer → abgelehnt.
  - tote Person: toter Partner nicht wählbar; Partner tot → keine Umlenkung.
  - Selbstwahl: abgelehnt.
  - mehrere Kopien: zwei Schattenwanderer → je eigener Link (Soll) vs. nur einer (Legacy).
  - Wiederbelebung: Partner wiederbelebt → Link aktiv laut Entscheidung.
  - Rollenwechsel: Schattenwanderer wird per Lehrling vererbt → Link bleibt an Person?
  - Save/Load: Link persistiert; neue Partie ohne Link.
  - Replay: gleiche Umlenkung.
  - SL-Korrektur: Link per Korrektur entfernen.
  - Sichtbarkeit: Link nur SL/Akteur; Umlenkung im öffentlichen Bericht nur als Tod des Partners.
  - Schutz: Partner mit Kartenschlucker-Schild → keiner stirbt.
  - Todesreaktionen: Partner Sensenträger → Reaktion.
  - Siegprüfung: Umlenkung ändert Parität (Wolf stirbt statt Dorf) → Siegprüfung auf Ergebnis.
  - beschädigter Spielstand: Link auf nicht existierende ID → Ablehnung.
- Belegsicherheit: hoch.

### giftwolf
- DE-Name / EN-Name: Giftwolf / Poison Wolf (`roles:190`).
- Aliase/Altnamen: Schlüssel `GiftwolfUses`, `meta.giftwolfDieOnMorning`, `meta.giftwolfPoisoned`; Ursache `GIFTWOLF_DELAY`; i18n `giftwolfInform`, `giftwolfNoCharges`; Bild `Poison_Wolf.webp`.
- Legacy-ID: "Giftwolf".
- Fraktion: "wolf"; nicht in `WOLF_KILL_ROLES`.
- Akte: akt2 (`akte.js:39`), custom.
- Nachtpriorität: tier 2.7, kein `once` (`roles:23`); Zeile jede Nacht solange lebend, auch ohne Ladungen.
- Quelltextstellen:
  - `roles:116`, `roles:266`, `role-abilities.js:50`.
  - `chunk:436-448` Handler: Ladungsprüfung (global, max 2), Ziel, `dieOn=MorningCount+2`, SL-Meldung.
  - `night:190` `MorningCount+1`; `night:200-211` Tod am Morgen `GIFTWOLF_DELAY` vor den Nachtzielen, danach `postDeathHooks`.
  - `core:112` Rudelvater-Rettung greift nicht bei `GIFTWOLF_DELAY`; `core:431` Ritter-Vergeltung auch bei `GIFTWOLF_DELAY`.
  - `gh:525` setzt `GiftwolfUses` nicht zurück.
- Text DE (wörtlich): "Darf zweimal im Spiel ein Ziel mit seinen Giftpranken angreifen. Dieses erfährt davon und stirbt zwei Tage später."
- Text EN (wörtlich): "May twice per game attack a target with poison claws. The target is informed and dies two days later."
- DE/EN-Vergleich: JA, semantisch gleich.
- Weitere Texte: i18n DE "Giftwolf: {name} wurde vergiftet (U+2014) stirbt in 2 Tagen." (Fallback im Code ergänzt "(SL informieren)", `chunk:446`); EN "dies in 2 days". Prompt "Giftpranken" hartkodiert.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht nutzbar, solange `GiftwolfUses<2`; beide Ladungen in derselben Nacht möglich (kein UsedTonight).
  2. Ziel: jeder lebende Sitz (`chunk:447`), auch er selbst, andere Wölfe, bereits vergiftete (überschreibt Termin).
  3. Termin: `dieOn = MorningCount+2`. Nacht N (MorningCount = N-1) → Tod am Morgen nach Nacht N+1 ("Morgen 2 nach dem Gift"). Der Tod fällt vor die Auflösung der Nachtziele.
  4. Wirkung: `applyKill(GIFTWOLF_DELAY)`; kein Schutzengel-/Dorfwache-/Der-Weise-Check; Nekromant-/Kartenschlucker-/Hades-Schilde greifen; Rudelvater wird nicht gerettet; Schattenwanderer-Umlenkung greift; Ritter vergilt.
  5. Gift bleibt bestehen, wenn der Giftwolf stirbt; keine Heilung (weder Waldhexe noch andere Rolle liest `giftwolfDieOnMorning`).
  6. Tote und Wiederbelebung: stirbt das Ziel vorher und wird vor dem Termin wiederbelebt (Frankenstein behält `meta`), stirbt es am Termin trotzdem. `giftwolfDieOnMorning` wird nach dem Tod nicht gelöscht.
  7. "Dieses erfährt davon": keine Automatik; nur SL-Meldung (`center`), SL muss informieren.
  8. Mehrere Kopien: gemeinsamer Zähler, also 2 Ladungen für alle zusammen.
  9. Sichtbarkeit: `giftwolfPoisoned` wird nirgends gelesen (keine Brett-Markierung, `ui:109`).
  10. Zufall: keiner.
- React-Version: kein eigenes Verhalten; `roleCard.ts:37`.
- Bisherige Doku und Prüfergebnis:
  - `04` Zeile 19 "unklar", `chunk:436-448`, `night:200-211`, "2 Ladungen; Opfer stirbt am übernächsten Morgen; zwei Ladungen in einer Nacht erlaubt? (Code: ja)": bestätigt.
  - `07` Q1 "maximal 1 pro Nacht" (Vorschlag), A-19: offen.
  - `01:137` `GiftwolfUses` nicht zurückgesetzt: bestätigt, ergänzt um Sitz-`meta`-Leck (siehe Bugs).
  - `04` B-9 Morgenzähler: Termin hängt an `MorningCount`, Zeitwächter-Nacht zählt als Morgen (`night:190` vor `resolveDayKills` Einfrieren).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:137` (Ritter feuert nicht bei Giftwolf-Toden): widerlegt für aktuellen Code (`core:430-450` prüft `lastKillCause`, Aufruf `night:344`).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Zwei Ladungen in einer Nacht | "zweimal im Spiel" | "twice per game" | ja | kein | 04 unklar, 07 Vorschlag max 1 | beide sofort erlaubt | max 1 pro Nacht | A erlaubt Doppelschlag | Schrittbedingung | B (07) | Ja |
| "erfährt davon" | Ziel erfährt | informed | nur SL-Hinweis | kein | nicht erwähnt | öffentlich/Ansage an Ziel in der Nacht | SL flüstert am Morgen | Informationsvorteil fürs Ziel | InfoRecord actor=Ziel | A als Actor-Ereignis | Ja |
| Zeitpunkt "zwei Tage später" | zwei Tage später | two days later | Morgen nach der übernächsten Nacht, vor Nachtopfern | kein | 04 "übernächster Morgen" | Morgen von Tag N+1 | Ende von Tag N+1 | gering | Termin in `day_number` | Code | Ja |

- Bugs:
  - echter Bug: `clearRolesNewRound` (`gh:517,520-525`) behält `meta.giftwolfDieOnMorning` und setzt `MorningCount=0`. Jeder in der Vorrunde vergiftete Sitz (auch einer, der am Gift gestorben ist, da das Feld nie gelöscht wird) stirbt in der neuen Runde am Morgen mit derselben Nummer. Risiko hoch. Test: Runde 1 Gift in Nacht 1 (dieOn=2), Rollen leeren, Runde 2 → Morgen 2 stirbt der Sitz nicht.
  - echter Bug: `GiftwolfUses` wird bei neuer Runde nicht zurückgesetzt (`gh:525`, `gh:558`) → Giftwolf der Folgerunde hat keine oder nur eine Ladung. Test: Runde 1 zwei Ladungen, Rollen leeren, Runde 2 → zwei Ladungen verfügbar.
  - unklare Regel: Gift überlebt Tod und Wiederbelebung des Ziels (`night:204`).
  - technische Altlast: `giftwolfPoisoned` gesetzt, nie gelesen; Zeile bleibt nach Verbrauch sichtbar.
- Legacy-Status: legacy-verified (Text wird umgesetzt; offene Punkte sind Regelpräzisierungen, die Bugs betreffen den Rundenwechsel).
- Automationsvorschlag: automatic für Termin und Tod; assisted für "Ziel erfährt davon" (Actor-Information).
- Mechanikfamilie: primär Tötung; sekundär zeitlich verzögerter Effekt (sonstige Spezialmechanik), Einmalfähigkeit (begrenzte Ladungen).
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt, KillPipeline (Ursache mit Attribut wolf_ability, dawn), Ereignis-Sichtbarkeit (actor-Ereignis an Ziel), InfoRecord, StateCodec, Reaktionswarteschlange (Folgen am Morgen).
- Benötigte NEUE Systeme: zeitlich verzögerte Effekte (Termin an Tages-/Morgenzähler, persistiert, partiegebunden); dauerhafte Statusmarker (vergiftet); Ladungszähler pro Person.
- Abhängigkeiten: Rudelvater (keine Rettung), Ritter (Vergeltung), Schattenwanderer, Nekromant/Kartenschlucker/Hades (Schilde), Zeitwächter (Morgenzähler), Frankenstein/Kutscher (Wiederbelebung), Orakel (sieht "Werwolf").
- Komplexität / Fehlerrisiko: M / mittel.
- Offene Entscheidungen: (1) Max 1 Ladung pro Nacht? (2) Wie erfährt das Ziel davon (Zeitpunkt, SL-Ansage)? (3) Endet das Gift bei Tod/Wiederbelebung des Ziels oder bei Heilung durch Waldhexe? (4) Ist das Gift ein "Wolfsangriff" (Rudelvater, Schutzengel, Dorfwache, Seuchenwolf)? (5) Ladungen pro Person oder pro Rolle?
- Relevante Testgruppen:
  - Normalfall: Gift Nacht 1 → Tod am Morgen nach Nacht 2 mit GIFTWOLF_DELAY.
  - ungültiges Ziel: tote Person → abgelehnt.
  - tote Person: Ziel stirbt vorher anders → kein zweiter Tod.
  - Selbstwahl: laut Entscheidung (Legacy erlaubt).
  - mehrere Kopien: zwei Giftwölfe → Ladungen pro Person (Soll).
  - Wiederbelebung: Ziel stirbt, wird vor Termin wiederbelebt → laut Entscheidung.
  - Rollenwechsel: Lehrling erbt Giftwolf → frische Ladungen.
  - Save/Load: Termin über Tag speichern/laden; neue Partie ohne Gift.
  - Replay: gleicher Todesmorgen.
  - SL-Korrektur: Gift entfernen.
  - Sichtbarkeit: Ziel erhält Actor-Info, öffentlich nur der Tod.
  - Schutz: Schutzengel auf Ziel in Todesnacht → wirkt laut Entscheidung nicht.
  - Todesreaktionen: Ziel Ritter → Vergeltung am Morgen; Ziel Sensenträger → Reaktion.
  - Siegprüfung: Gifttod am Morgen vor Nachtopfern → Siegprüfung nach vollständiger Auflösung.
  - beschädigter Spielstand: Termin in der Vergangenheit für Lebenden → Ablehnung oder Korrektur.
- Belegsicherheit: hoch.

### rudelvater
- DE-Name / EN-Name: Rudelvater / Packfather (`roles:191`); i18n-Meldung "Pack Leader" (`i18n:569`), Kartenbild `Pack_Father.webp`.
- Aliase/Altnamen: Schlüssel `RudelvaterSavedOnce`, `PackfatherExtraKillNextNight`, `PackfatherBlockNextDay` (nur zurückgesetzt, nie gesetzt), `meta.packfatherPierce`; Ursache `PACKFATHER_KILL`.
- Legacy-ID: "Rudelvater".
- Fraktion: "wolf"; nicht in `WOLF_KILL_ROLES`.
- Akte: akt2 (`akte.js:40`), custom.
- Nachtpriorität: kein `ORDER_BASE`-Eintrag; Passiv-Liste (`night:96`). Zusatzopfer wird nicht als Nachtschritt, sondern als Pick zu Beginn der Morgenauflösung abgefragt (`night:269-280`).
- Quelltextstellen:
  - `roles:117`, `roles:267`, `role-abilities.js:53` (abweichender Wortlaut).
  - `core:111-117` `applyKill`: einmalige Rettung, außer bei `NIGHT_KILL`, `LYNCH`, `PACKFATHER_KILL`, `GIFTWOLF_DELAY`.
  - `night:498` `doLynchFlow`: Rudelvater gelyncht → `PackfatherExtraKillNextNight=true` (vor `applyKill`).
  - `night:245-248` totes Lesen von `PackfatherBlockNextDay`.
  - `night:269-280` `onDayStart`: Pick "Rudelvater – wähle zweites Opfer (ignoriert Schutz)" (hartkodiert DE), `meta.packfatherPierce=true`.
  - `night:251` Dorfwache-Filter übergangen; `night:358,393` Der Weise übergangen, Ursache `PACKFATHER_KILL`; `core:126-143` Schilde übergangen; `night:146` `packfatherPierce` bei Nachtbeginn gelöscht.
  - `gh:525` Reset.
- Text DE (wörtlich): "Überlebt den ersten Tod, der nicht durch einen Wolfsangriff oder Lynch verursacht wird. Wird er jedoch gelyncht, dürfen die Werwölfe in der folgenden Nacht ein zusätzliches Opfer wählen. Dieser zweite Angriff ignoriert alle Schutzfähigkeiten."
- Text EN (wörtlich): "Survives the first death not caused by a wolf attack or lynch. If lynched, the werewolves receive a second target the following night; this second attack ignores all protection."
- DE/EN-Vergleich: JA, semantisch gleich ("zusätzliches Opfer" = "second target", "alle Schutzfähigkeiten" = "all protection").
- Weitere Texte: `role-abilities.js:53` "... Wird er gelyncht, erhalten die Werwölfe in der nächsten Nacht ein zweites Opfer; dieser zweite Angriff ignoriert allen Schutz." (semantisch gleich). i18n DE "Rudelvater überlebt den ersten Tod durch eine Sonderfähigkeit." / EN "Pack Leader survives ..." (anderer EN-Name).
- Legacy-Codeverhalten:
  1. Rettung: einmal pro Partie global (`RudelvaterSavedOnce`, alle Kopien teilen sie), bei jeder Ursache außer den vier genannten. Gerettet werden also u. a. `HUNTER_SHOT`, `WITCH_POISON`, `BLACK_WIDOW` (Wolfsrolle), `BESESSENER_WOLF` (Wolfsrolle), `SPIEGELWOLF_RETALIATE`, `VERDAMMNISWAECHTER`, `BUSDRIVER_LYNCH`, `BURN_LYNCH_SPREAD`, `HANGMAN_EXECUTION`, `LOVER_HEARTBREAK`, `SCHMIED_WEAPON`, `RITTER_RETALIATION`. Nicht gerettet: Rudelkill, Rachsüchtiger-Kill, Schicksalswolf-Zusatzopfer (alle NIGHT_KILL), Gift, Lynch.
  2. Die Rettung prüft vor der Schattenwanderer-Umlenkung und vor Schilden (`core:111-124`); Meldung an SL (`center`).
  3. Lynch: Flag wird gesetzt, bevor `applyKill(LYNCH)` läuft (`night:498-499`). Überlebt er (Nekromant-Schild, Schattenwanderer-Umlenkung), gibt es trotzdem das Zusatzopfer. Sonderzweige (Voodoo, Brand, Der Weise usw.) betreffen ihn nicht.
  4. Zusatzopfer: nicht im Nachtschritt der Wölfe, sondern der SL wählt zu Beginn der Morgenauflösung nach der folgenden Nacht (`night:269-280`); beliebiger lebender Sitz außer bereits gewählten Nachtzielen, auch Wölfe. Prompt erscheint auch, wenn alle Wölfe tot sind oder bereits ein Sieg feststeht (keine Prüfung).
  5. Durchdringung: ignoriert Dorfwache, Der Weise, Nekromant-, Kartenschlucker-, Hades-Schild; Schutzengel wird ohnehin nicht geprüft; Waldhexe kommt zu spät. Nicht ignoriert: Schmiede-Waffe (`night:380-391`), Voodoo-Umlenkung (`night:252-256`), Märtyrerin (wenn Zusatzopfer `nightTargets[0]` ist), Albtraum-Blockade (`night:334`), Parasit, Schattenwanderer-Umlenkung.
  6. Ursache `PACKFATHER_KILL`, öffentlich als "🐺 Rudelvater" (`ui:402`); Ritter-Vergeltung greift nicht (`core:431` enthält die Ursache nicht).
  7. Mehrere Kopien: globale Rettung und globales Flag.
  8. Zufall: keiner.
- React-Version: kein eigenes Verhalten; `roleCard.ts:38`.
- Bisherige Doku und Prüfergebnis:
  - `04` Zeile 20 "verifiziert", `core:111-117`, `night:498`, `night:269-280`: bestätigt. Ergänzung: Zusatzopfer wird am Morgen vom SL gewählt, nicht im Nachtschritt; Flag auch bei überlebtem Lynch.
  - `04` C.1 Rudelvater-Erstrettung mit Ursachenfilter: bestätigt. `04` C.2 `PACKFATHER_KILL` "pierces": bestätigt, aber nicht gegen Schmied/Voodoo/Märtyrerin/Albtraum.
  - `01:290` `PackfatherBlockNextDay` "nie gelesen": widerlegt; wird in `night:245` gelesen, aber nie auf true gesetzt (nur `gh:525` false) → toter Zweig.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:210` T10 (DE-Text missverständlich): erledigt, DE-Text ist präzisiert. L13 (Märtyrerin rettet alle): widerlegt für aktuellen Code (`night:262`).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Was ist "Wolfsangriff" | Wolfsangriff | wolf attack | NIGHT_KILL, PACKFATHER_KILL, GIFTWOLF_DELAY; nicht Schwarze Witwe, Besessener Wolf, Spiegelwolf | kein | 04 Filter übernommen | jede Tötung durch eine Wolfsrolle | nur Rudel-/Wolfsnachtangriff | A macht ihn verwundbarer | Ursachen-Attribut `wolf_source` | A oder Liste | Ja |
| Was ist "Lynch" | Lynch | lynch | nur Ursache LYNCH; Kutscher-Seitentod, Brand-Seitentod, Henker werden gerettet | kein | nicht erwähnt | nur die Hinrichtung selbst | alles, was aus einer Hinrichtung folgt | gering | Ursachen-Attribut execution vs. execution_side | nur Hinrichtung (Code) | Ja |
| "alle Schutzfähigkeiten" | alle | all | Schilde ja, Schmied/Voodoo/Märtyrerin/Albtraum nein | kein | 04 "pierces" | wirklich alle Abfangregeln | nur Schutzrollen und Schilde | gering | gemeinsame Durchdringungsliste mit Seuchenwolf | eine Liste für beide | Ja |
| Wer wählt wann | Werwölfe, folgende Nacht | werewolves, following night | SL am Morgen nach der Nacht | kein | 04 "nächste Nacht" | eigener Rudelschritt in der Nacht | Pick bei Morgenauflösung | kein, aber Ablauf/Ansage | zweiter Rudel-Prompt in StepQueue | A | Ja |

- Bugs:
  - unklare Regel: Zusatzopfer auch, wenn er den Lynch überlebt (`night:498` vor `applyKill`). Test: Rudelvater mit Schattenwanderer-Link gelyncht, Partner stirbt → Zusatzopfer ja/nein laut Entscheidung.
  - echter Bug (niedrig): Prompt erscheint ohne lebende Wölfe bzw. nach feststehendem Sieg (`night:269`). Erwartet: kein Zusatzopfer ohne Rudel. Test: Rudelvater letzter Wolf gelyncht → Dorfsieg, kein Zusatzopfer-Prompt.
  - technische Altlast: `PackfatherBlockNextDay` toter Zweig (`night:245-248`).
  - technische Altlast: Prompt hartkodiert DE ohne i18n-Schlüssel; EN nur fragmentweise übersetzt (nicht im Browser geprüft).
  - technische Altlast: globale Rettung für alle Kopien (`RudelvaterSavedOnce`).
- Legacy-Status: legacy-verified (Rettung mit Ursachenfilter und Zusatzopfer nach Lynch sind umgesetzt; Abweichungen betreffen Ablaufdetails und Begriffsabgrenzung).
- Automationsvorschlag: automatic für Rettung; assisted für Zusatzopfer (Rudel-Prompt mit SL-Bestätigung).
- Mechanikfamilie: primär Hinrichtungsreaktion; sekundär Wolfsangriff-Modifikation, Einmalfähigkeit (Einmal-Schild).
- Benötigte vorhandene Godot-Systeme: KillPipeline (Einmal-Schild mit Ursachenfilter, Durchdringung), ExecutionRules (Hook bei Hinrichtung), StepQueue/PendingPrompt (zweiter Rudelschritt), Protections, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: zeitlich verzögerter Effekt "nächste Nacht zusätzliches Rudelopfer" (persistiert); Ursachen-Taxonomie (wolf_attack, execution) als Attribute; Einmal-Schild pro Person (mehrere Leben light).
- Abhängigkeiten: Werwolf (Rudel), Seuchenwolf (gemeinsame Durchdringung), Giftwolf, Schattenwanderer, Nekromant/Kartenschlucker/Hades, Dorfwache, Der Weise, Dorfschmied, Voodoo-Priester, Märtyrerin, Albtraumwolf, Sensenträger, Ritter.
- Komplexität / Fehlerrisiko: M / mittel.
- Offene Entscheidungen: (1) Was zählt als Wolfsangriff (Schwarze Witwe, Besessener Wolf, Spiegelwolf, Gift)? (2) Zählen Hinrichtungs-Nebentode als Lynch? (3) Zusatzopfer im Nachtschritt der Wölfe oder am Morgen durch den SL? (4) Zusatzopfer auch bei überlebtem Lynch? (5) Welche Abfangregeln ignoriert das Zusatzopfer (Liste gemeinsam mit Seuchenwolf)? (6) Rettung pro Person oder pro Rolle?
- Relevante Testgruppen:
  - Normalfall A: Sensenträger schießt auf Rudelvater → überlebt; zweiter Schuss → stirbt.
  - Normalfall B: Rudelvater gelyncht → nächste Nacht zwei Rudelopfer, zweites trotz Dorfwache tot.
  - ungültiges Ziel: Zusatzopfer = bereits gewähltes Rudelopfer → abgelehnt.
  - tote Person: toter Sitz als Zusatzopfer → abgelehnt.
  - Selbstwahl: nicht relevant, weil Rudelvater tot ist, wenn gewählt wird.
  - mehrere Kopien: zwei Rudelvater, jeder eigene Rettung (Soll) vs. global (Legacy).
  - Wiederbelebung: Rudelvater nach Rettung wiederbelebt → keine zweite Rettung.
  - Rollenwechsel: Lehrling erbt Rudelvater → frische Rettung.
  - Save/Load: Flag Zusatzopfer über Nacht speichern/laden.
  - Replay: gleiche Rettung und Zusatzopfer.
  - SL-Korrektur: Lynch per Korrektur → Zusatzopfer ja.
  - Sichtbarkeit: Rettung nur SL; Zusatzopfer-Tod öffentlich.
  - Schutz: Zusatzopfer mit Schutzengel/Schild → stirbt.
  - Todesreaktionen: Zusatzopfer Sensenträger → Reaktion.
  - Siegprüfung: Lynch des letzten Wolfs → Dorfsieg ohne Zusatzopfer-Prompt.
  - beschädigter Spielstand: Zusatzopfer-Flag ohne vorausgegangenen Lynch → Ablehnung oder Korrektur.
- Belegsicherheit: hoch; nicht verifiziert: EN-Laufzeitdarstellung des hartkodierten Prompts.

---

## Gruppenübergreifende Beobachtungen

1. F2 bestätigt und in Tragweite größer als in `01:263` beschrieben: 6 der 8 Rollen (Siegreicher Wolf, Seuchenwolf, Schicksalswolf, Schattenwanderer, Giftwolf, Rudelvater) fehlen in `WOLF_KILL_ROLES` (`night:50`). Leben nur solche Wölfe, entfällt der Rudelangriff, und damit auch Seuchenwolf-Durchdringung und Rudelvater-Zusatzopfer-Logik im normalen Ablauf. In Godot: Rudelschritt, solange irgendein `counts_as_wolf` lebt.
2. Zwei "ignoriert Schutz"-Mechaniken sind uneinheitlich: Rudelvater (`PACKFATHER_KILL`) durchdringt Nekromant-/Kartenschlucker-/Hades-Schilde (`core:126-143`), Seuchenwolf nicht. Beide durchdringen Schmied, Voodoo, Märtyrerin, Albtraum nicht. Empfehlung: ein gemeinsames Attribut `pierces` mit fester Liste der Abfangregeln.
3. Schutz wird in Legacy nur im Werwolf-Handler (`chunk:162`) bzw. Rachsüchtiger-Handler (`chunk:348`) geprüft, nicht in der Morgenauflösung. Folge: Zusatzopfer von Schicksalswolf und Rudelvater ignorieren Schutzengel; Schutz wird bei Fehlklick verbraucht (bekannt aus 07 Schutzengel). Godot (Schutz in der Abfangstufe am Morgen) ändert damit das Verhalten dieser Rollen; muss bewusst entschieden werden.
4. Ursachen-Taxonomie: Mehrere Rollen hängen an "Wolfsangriff" (Rudelvater-Rettung, Seuchenwolf-Verbrauch, Ritter) und alle Wolfskills außer Gift/Rudelvater laufen als `NIGHT_KILL`. Rachsüchtiger-Kill, Schicksalswolf-Zusatzopfer und umgelenkte Schattenwanderer-Tode sind in Legacy nicht vom Rudelkill unterscheidbar. Godot braucht Quelle plus Attribute pro Tod.
5. Globale Einmal-/Zählerflags pro Rollenname statt pro Person: `Used["role_König_Lykaon"]`, `Used["role_Schattenwanderer"]`, `GiftwolfUses`, `WhiteWolfCooldown`, `RudelvaterSavedOnce`, `SeuchenwolfNextAttackPierces`, `FateWolfMarked`. Mehrere Kopien teilen sich die Fähigkeit. Bestätigt die Empfehlung in `01:222`.
6. Neue-Runde-Leck (neu, echter Bug): `clearRolesNewRound` (`gh:512-529`, identisch `app/public/legacy-bridge.js:34-51`) übernimmt `seat.meta` und damit `shadowSwapPartnerId` und `giftwolfDieOnMorning`; `GiftwolfUses` und `FateWolfExtraIds` werden nicht zurückgesetzt. Folge: Umlenkungen und Gifttode aus der Vorrunde wirken in der neuen Runde. In `01`/`04` nur für `GiftwolfUses` erwähnt.
7. `killedTonight` mit Überlebenden (F14, `night:394`) betrifft diese Gruppe über Seuchenwolf-Verbrauch und Schattenwanderer-Umlenkung; die Seuchenwolf-Fehlauslösung braucht zusätzlich ein veraltetes `lastKillCause` (Frankenstein-Wiederbelebung löscht es nicht).
8. Keine Legacy-Markierungen für Rollenzustände dieser Gruppe (Gift, Schattenlink, Schicksalsmarkierungen, Durchdringung, Rudelvater-Rettung verbraucht): `markerList` (`ui:109`) kennt sie nicht. Für Godot gehören sie in den SL-sichtbaren Zustand.
9. EN-Namen inkonsistent: Rudelvater "Packfather" (Name) vs. "Pack Leader" (i18n) vs. "Pack_Father" (Bild); Schattenwanderer "Shadowwalker" vs. "Shadow Wanderer" (i18n); Rachsüchtiger Wolf "Lone Wolf" vs. Bild "Vengeful_Wolf" (ungemappt). Viele Pick-Prompts dieser Rollen sind hartkodiert DE und nur fragmentweise übersetzt.
10. Korrekturen an bisheriger Doku: `04` Zeile 13 "3 Nächte Pause" → 2 gesperrte Nächte, erste Nutzung ab Nacht 1; `04` Zeile 16 Seuchenwolf "verifiziert" zu optimistisch; `04` Zeile 17 Schicksalswolf "verifiziert" übersieht "in" vs. "ab Nacht 4" und Schutzlücke; `01:290` `PackfatherBlockNextDay` wird gelesen (nie gesetzt); `NIGHT-REPORT-abilities.md:81` Schattenwanderer nicht auf Nacht 1 beschränkt; ältere Befunde L12, L13, E3, T10 und Ritter/Giftwolf aus `GRIMMHAIN_ANALYSE_2026-06-12.md` sind im aktuellen Code behoben.
11. DECISION-LOG-Lücke: Trugbilderwolf-Scheinrolle ist nur für Spielaufbau und Korrektur geregelt; König Lykaon erzeugt Trugbilderwölfe während der Partie (und Totenkarte wende_11 ebenfalls). Legacy würfelt die Orakel-Anzeige (`chunk:240-249`), was DR-08 widerspricht.
12. React-Version: für alle acht Rollen kein eigenes Verhalten oder eigene Regeldaten; nur Kartenbild-Mapping (`app/src/roleCard.ts`) und Durchleitung des Legacy-Zustands (`app/src/adapter/legacy/*`), inklusive des kopierten `clearRolesNewRound` (`app/public/legacy-bridge.js`).
